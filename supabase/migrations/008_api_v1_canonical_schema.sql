-- ============================================================================
-- 008_api_v1_canonical_schema.sql
-- Expand-only reconciliation: adds the canonical Go API v1 columns alongside
-- the legacy Flutter client columns (Expand → Migrate → Switch → Contract).
-- Nothing is dropped or altered destructively. Backfill + sync triggers keep
-- both column families consistent so legacy clients and the Go API can coexist.
--
-- Money convention:
--   legacy columns  = NUMERIC(10,2) rupees  (written by Flutter apps)
--   canonical       = BIGINT integer paise  (written by Go API, authoritative)
-- Sync triggers convert in both directions.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. ITEMS — canonical columns used by the Go API (integer paise)
-- ----------------------------------------------------------------------------
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS name TEXT DEFAULT '';
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS price BIGINT NOT NULL DEFAULT 0;
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS original_price BIGINT;
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS category TEXT DEFAULT 'General';
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS image_url TEXT;
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS is_available BOOLEAN DEFAULT TRUE;
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS preparation_min INT DEFAULT 20;
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS rating DOUBLE PRECISION DEFAULT 4.5;
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS reviews_count INT DEFAULT 0;

-- Backfill canonical columns from legacy values (paise = rupees * 100)
UPDATE public.items SET
    name            = COALESCE(NULLIF(item_title, ''), name),
    price           = CASE WHEN price = 0 THEN COALESCE(discount_price, item_price, 0) * 100 ELSE price END,
    original_price  = COALESCE(original_price, item_price * 100),
    image_url       = COALESCE(image_url, thumbnail_url),
    is_available    = COALESCE(is_available, is_active)
WHERE TRUE;

-- Sync legacy → canonical whenever admin app writes via legacy columns
CREATE OR REPLACE FUNCTION public.sync_items_legacy_to_canonical()
RETURNS TRIGGER AS $$
BEGIN
    NEW.name            := COALESCE(NULLIF(NEW.item_title, ''), NEW.name);
    NEW.price           := CASE WHEN NEW.price = 0 THEN COALESCE(NEW.discount_price, NEW.item_price, 0) * 100 ELSE NEW.price END;
    NEW.original_price  := COALESCE(NEW.original_price, NEW.item_price * 100);
    NEW.image_url       := COALESCE(NEW.image_url, NEW.thumbnail_url);
    NEW.is_available    := COALESCE(NEW.is_available, NEW.is_active);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_items_legacy_to_canonical ON public.items;
CREATE TRIGGER trg_items_legacy_to_canonical
    BEFORE INSERT OR UPDATE ON public.items
    FOR EACH ROW EXECUTE FUNCTION public.sync_items_legacy_to_canonical();

-- Sync canonical → legacy whenever Go API writes via canonical columns
CREATE OR REPLACE FUNCTION public.sync_items_canonical_to_legacy()
RETURNS TRIGGER AS $$
BEGIN
    NEW.item_title      := COALESCE(NULLIF(NEW.name, ''), NEW.item_title);
    NEW.item_price      := CASE WHEN NEW.item_price = 0 THEN NEW.price / 100.0 ELSE NEW.item_price END;
    NEW.discount_price  := CASE WHEN NEW.price <> NEW.original_price THEN NEW.price / 100.0 ELSE NEW.discount_price END;
    NEW.thumbnail_url   := COALESCE(NEW.image_url, NEW.thumbnail_url);
    NEW.is_active       := COALESCE(NEW.is_available, NEW.is_active);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_items_canonical_to_legacy ON public.items;
CREATE TRIGGER trg_items_canonical_to_legacy
    BEFORE INSERT OR UPDATE ON public.items
    FOR EACH ROW EXECUTE FUNCTION public.sync_items_canonical_to_legacy();

-- ----------------------------------------------------------------------------
-- 2. ORDERS — canonical paise + delivery columns used by the Go API
-- ----------------------------------------------------------------------------
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS subtotal_paise BIGINT NOT NULL DEFAULT 0;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS delivery_fee_paise BIGINT NOT NULL DEFAULT 0;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS discount_paise BIGINT NOT NULL DEFAULT 0;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS total_amount_paise BIGINT NOT NULL DEFAULT 0;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS payment_status TEXT NOT NULL DEFAULT 'pending';
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS idempotency_key TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS delivery_street TEXT DEFAULT '';
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS delivery_city TEXT DEFAULT '';
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS delivery_zip TEXT DEFAULT '';
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS delivery_lat DOUBLE PRECISION;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS delivery_lng DOUBLE PRECISION;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS special_notes TEXT DEFAULT '';

CREATE INDEX IF NOT EXISTS idx_orders_idempotency ON public.orders(user_id, idempotency_key) WHERE idempotency_key IS NOT NULL;

-- Backfill canonical columns from legacy values
UPDATE public.orders SET
    subtotal_paise     = CASE WHEN subtotal_paise = 0 THEN COALESCE(subtotal, 0) * 100 ELSE subtotal_paise END,
    delivery_fee_paise = CASE WHEN delivery_fee_paise = 0 THEN COALESCE(delivery_fee, 0) * 100 ELSE delivery_fee_paise END,
    discount_paise     = COALESCE(NULLIF(discount_paise, 0), discount_amount, 0) * 100,
    total_amount_paise = CASE WHEN total_amount_paise = 0 THEN COALESCE(total_amount, 0) * 100 ELSE total_amount_paise END,
    delivery_street    = COALESCE(NULLIF(delivery_street, ''), address),
    delivery_lat       = COALESCE(delivery_lat, customer_lat),
    delivery_lng       = COALESCE(delivery_lng, customer_lng)
WHERE TRUE;

-- Sync canonical → legacy whenever Go API writes orders (money + address)
CREATE OR REPLACE FUNCTION public.sync_orders_canonical_to_legacy()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.subtotal_paise <> OLD.subtotal_paise OR NEW.subtotal_paise = 0 THEN
        NEW.subtotal       := NEW.subtotal_paise / 100.0;
    END IF;
    IF NEW.delivery_fee_paise <> OLD.delivery_fee_paise OR NEW.delivery_fee_paise = 0 THEN
        NEW.delivery_fee   := NEW.delivery_fee_paise / 100.0;
    END IF;
    IF NEW.discount_paise <> OLD.discount_paise OR NEW.discount_paise = 0 THEN
        NEW.discount_amount := NEW.discount_paise / 100.0;
    END IF;
    IF NEW.total_amount_paise <> OLD.total_amount_paise OR NEW.total_amount_paise = 0 THEN
        NEW.total_amount   := NEW.total_amount_paise / 100.0;
    END IF;
    NEW.address         := COALESCE(NULLIF(NEW.delivery_street, ''), NEW.address);
    NEW.customer_lat    := COALESCE(NEW.delivery_lat, NEW.customer_lat);
    NEW.customer_lng    := COALESCE(NEW.delivery_lng, NEW.customer_lng);
    NEW.updated_at      := COALESCE(NEW.updated_at, NOW());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_orders_canonical_to_legacy ON public.orders;
CREATE TRIGGER trg_orders_canonical_to_legacy
    BEFORE INSERT OR UPDATE ON public.orders
    FOR EACH ROW EXECUTE FUNCTION public.sync_orders_canonical_to_legacy();

-- Sync legacy → canonical whenever legacy Flutter clients write orders
CREATE OR REPLACE FUNCTION public.sync_orders_legacy_to_canonical()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.subtotal_paise = 0 THEN
        NEW.subtotal_paise     := COALESCE(NEW.subtotal, 0) * 100;
    END IF;
    IF NEW.delivery_fee_paise = 0 THEN
        NEW.delivery_fee_paise := COALESCE(NEW.delivery_fee, 0) * 100;
    END IF;
    IF NEW.discount_paise = 0 THEN
        NEW.discount_paise     := COALESCE(NEW.discount_amount, 0) * 100;
    END IF;
    IF NEW.total_amount_paise = 0 THEN
        NEW.total_amount_paise := COALESCE(NEW.total_amount, 0) * 100;
    END IF;
    NEW.delivery_street := COALESCE(NULLIF(NEW.delivery_street, ''), NEW.address);
    NEW.delivery_lat    := COALESCE(NEW.delivery_lat, NEW.customer_lat);
    NEW.delivery_lng    := COALESCE(NEW.delivery_lng, NEW.customer_lng);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_orders_legacy_to_canonical ON public.orders;
CREATE TRIGGER trg_orders_legacy_to_canonical
    BEFORE INSERT OR UPDATE ON public.orders
    FOR EACH ROW EXECUTE FUNCTION public.sync_orders_legacy_to_canonical();

-- ----------------------------------------------------------------------------
-- 3. COUPONS — canonical columns used by the Go API
-- ----------------------------------------------------------------------------
ALTER TABLE public.coupons ADD COLUMN IF NOT EXISTS min_order_amount_paise BIGINT NOT NULL DEFAULT 0;
ALTER TABLE public.coupons ADD COLUMN IF NOT EXISTS max_discount_paise BIGINT;
ALTER TABLE public.coupons ADD COLUMN IF NOT EXISTS valid_until TIMESTAMPTZ;

UPDATE public.coupons SET
    min_order_amount_paise = CASE WHEN min_order_amount_paise = 0 THEN COALESCE(min_order_amount, 0) * 100 ELSE min_order_amount_paise END,
    max_discount_paise     = COALESCE(max_discount_paise, max_discount_amount * 100),
    valid_until            = COALESCE(valid_until, expiration_date)
WHERE TRUE;

CREATE OR REPLACE FUNCTION public.sync_coupons_legacy_to_canonical()
RETURNS TRIGGER AS $$
BEGIN
    NEW.min_order_amount_paise := CASE WHEN NEW.min_order_amount_paise = 0 THEN COALESCE(NEW.min_order_amount, 0) * 100 ELSE NEW.min_order_amount_paise END;
    NEW.max_discount_paise     := COALESCE(NEW.max_discount_paise, NEW.max_discount_amount * 100);
    NEW.valid_until            := COALESCE(NEW.valid_until, NEW.expiration_date);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_coupons_legacy_to_canonical ON public.coupons;
CREATE TRIGGER trg_coupons_legacy_to_canonical
    BEFORE INSERT OR UPDATE ON public.coupons
    FOR EACH ROW EXECUTE FUNCTION public.sync_coupons_legacy_to_canonical();

CREATE OR REPLACE FUNCTION public.sync_coupons_canonical_to_legacy()
RETURNS TRIGGER AS $$
BEGIN
    NEW.min_order_amount     := COALESCE(NEW.min_order_amount, NEW.min_order_amount_paise / 100.0);
    NEW.max_discount_amount  := COALESCE(NEW.max_discount_amount, NEW.max_discount_paise / 100.0);
    NEW.expiration_date      := COALESCE(NEW.expiration_date, NEW.valid_until);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_coupons_canonical_to_legacy ON public.coupons;
CREATE TRIGGER trg_coupons_canonical_to_legacy
    BEFORE INSERT OR UPDATE ON public.coupons
    FOR EACH ROW EXECUTE FUNCTION public.sync_coupons_canonical_to_legacy();

-- ----------------------------------------------------------------------------
-- 4. USERS — admin flag
-- ----------------------------------------------------------------------------
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS is_admin BOOLEAN NOT NULL DEFAULT FALSE;

-- ----------------------------------------------------------------------------
-- 5. MEAL PRODUCTS — price paise column
-- ----------------------------------------------------------------------------
ALTER TABLE public.meal_products ADD COLUMN IF NOT EXISTS price_paise BIGINT NOT NULL DEFAULT 0;

UPDATE public.meal_products SET
    price_paise = COALESCE(NULLIF(price_paise, 0), discount_price, price, 0) * 100
WHERE price_paise = 0;