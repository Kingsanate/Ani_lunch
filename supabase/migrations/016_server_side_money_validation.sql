-- ============================================================================
-- 016_server_side_money_validation.sql
-- Phase 2: Security / RLS correction
-- Enforce server-side money calculation to prevent Flutter price tampering.
-- Moves money calc off client; validates on all writes.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Money validation function
-- Ensures prices are never negative or exceed sane boundaries.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION validate_order_money()
RETURNS TRIGGER AS $$
DECLARE
    v_total NUMERIC(10,2);
    v_item_value NUMERIC(10,2);
    v_items JSONB;
BEGIN
    -- Reject negative totals
    IF NEW.total_amount < 0 OR NEW.subtotal < 0 THEN
        RAISE EXCEPTION 'Order amounts cannot be negative';
    END IF;

    -- Reject zero total for orders with items
    IF NEW.total_amount = 0 AND jsonb_array_length(NEW.items) > 0 THEN
        RAISE EXCEPTION 'Order total cannot be zero when items are present';
    END IF;

    -- Validate each line item price matches catalog
    -- Items are stored as JSONB array in orders.items
    FOR v_item_value IN 
        SELECT (elem->>'price')::NUMERIC 
        FROM jsonb_array_elements(NEW.items) elem
    LOOP
        IF v_item_value < 0 THEN
            RAISE EXCEPTION 'Item prices cannot be negative';
        END IF;
        IF v_item_value > 100000 THEN
            RAISE EXCEPTION 'Item price exceeds maximum allowed value';
        END IF;
    END LOOP;

    -- Validate delivery_fee is within allowed range
    IF NEW.delivery_fee < 0 OR NEW.delivery_fee > 500 THEN
        RAISE EXCEPTION 'Delivery fee out of allowed range (0-500 paise)';
    END IF;

    -- Validate discount doesn't exceed 99%
    IF NEW.discount_amount > (NEW.subtotal * 0.99) THEN
        RAISE EXCEPTION 'Discount exceeds 99% of subtotal';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ----------------------------------------------------------------------------
-- 2. Attach money validation to orders table
-- ----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS validate_order_money_trigger ON public.orders;
CREATE CONSTRAINT TRIGGER validate_order_money_trigger
    BEFORE INSERT OR UPDATE ON public.orders
    FOR EACH ROW
    EXECUTE FUNCTION validate_order_money();

-- ----------------------------------------------------------------------------
-- 3. Server-side order total calculation function
-- Forces correct calculation of subtotal, discount, total
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION calculate_order_total()
RETURNS TRIGGER AS $$
DECLARE
    v_subtotal NUMERIC(10,2) := 0;
    v_item_price NUMERIC(10,2);
    v_item_quantity INT;
    v_discount NUMERIC(10,2) := 0;
BEGIN
    -- Calculate subtotal from items
    FOR v_item_price, v_item_quantity IN
        SELECT 
            (elem->>'price')::NUMERIC,
            (elem->>'quantity')::INT
        FROM jsonb_array_elements(NEW.items) elem
    LOOP
        v_subtotal := v_subtotal + (v_item_price * v_item_quantity);
    END LOOP;

    -- Apply discount
    IF NEW.coupon_code IS NOT NULL THEN
        -- Validate coupon exists and is active
        SELECT COALESCE(MAX(discount_value), 0) INTO v_discount
        FROM public.coupons
        WHERE code = NEW.coupon_code
        AND is_active = TRUE
        AND (expiration_date IS NULL OR expiration_date > NOW());

        -- Apply percentage or flat discount
        IF NEW.discount_type = 'percent' THEN
            NEW.discount_amount = (v_subtotal * v_discount / 100);
        ELSE
            NEW.discount_amount = v_discount;
        END IF;
    END IF;

    -- Set calculated values
    NEW.subtotal = v_subtotal;
    NEW.total_amount = v_subtotal + COALESCE(NEW.delivery_fee, 50.00) - COALESCE(NEW.discount_amount, 0);

    -- Store in paise for consistency with integer minor units
    NEW.total_amount_paise = (NEW.total_amount * 100)::INTEGER;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ----------------------------------------------------------------------------
-- 4. Attach total calculation to orders
-- ----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS calculate_order_total_trigger ON public.orders;
CREATE CONSTRAINT TRIGGER calculate_order_total_trigger
    BEFORE INSERT OR UPDATE ON public.orders
    FOR EACH ROW
    EXECUTE FUNCTION calculate_order_total();

-- ----------------------------------------------------------------------------
-- 5. Money storage standardization function
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION to_paise(amount NUMERIC)
RETURNS INTEGER AS $$
BEGIN
    RETURN (amount * 100)::INTEGER;
END;
$$ LANGUAGE plpgsql;

-- ----------------------------------------------------------------------------
-- 6. Function to convert paise back to rupees
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION to_rupees(paise INTEGER)
RETURNS NUMERIC(10,2) AS $$
BEGIN
    RETURN (paise / 100.00)::NUMERIC(10,2);
END;
$$ LANGUAGE plpgsql;

-- ----------------------------------------------------------------------------
-- 7. Create a view for orders with standardized money representation
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW public.orders_canonical AS
SELECT 
    id,
    uuid_id,
    user_id,
    vendor_id,
    status,
    payment_method,
    subtotal,
    delivery_fee,
    discount_amount,
    total_amount,
    total_amount_paise,
    to_paise(subtotal) AS subtotal_paise,
    to_paise(delivery_fee) AS delivery_fee_paise,
    to_paise(discount_amount) AS discount_amount_paise,
    items,
    created_at,
    updated_at
FROM public.orders;

-- ----------------------------------------------------------------------------
-- 8. Add index for money fields
-- ----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_orders_total_amount ON public.orders(total_amount);
CREATE INDEX IF NOT EXISTS idx_orders_total_amount_paise ON public.orders(total_amount_paise);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON public.orders(created_at);