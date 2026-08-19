-- ============================================================================
-- 015_security_hardening.sql
-- Phase 2: Security / RLS correction
-- Fixes the critical security breach introduced by 20260727000000_vendor_orders_policy.sql
-- which allowed ANY authenticated user to read/update ALL orders.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. DROP the wide-open policies from 20260727000000_vendor_orders_policy.sql
--    These allowed ANY authenticated user to SELECT/UPDATE ALL orders.
--    The correctly scoped alternatives from 007_secure_rls_policies.sql remain.
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Vendors read orders" ON public.orders;
DROP POLICY IF EXISTS "Vendors update orders" ON public.orders;

-- ----------------------------------------------------------------------------
-- 2. Lock down the SECURITY DEFINER accept_order() function.
--    PG grants EXECUTE on functions to PUBLIC by default; combined with the
--    missing auth check inside the function body, ANY caller could claim ANY
--    order. Revoke from PUBLIC (covers anon + authenticated) and re-grant
--    explicitly to service_role only.
-- ----------------------------------------------------------------------------
REVOKE EXECUTE ON FUNCTION public.accept_order(TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.accept_order(TEXT, TEXT) TO service_role;

-- Drop the legacy UUID-signature variant if it still exists
DROP FUNCTION IF EXISTS public.accept_order(UUID, UUID);

-- ----------------------------------------------------------------------------
-- 3. Sanity check: ensure scoped policies from 007 are in place
-- ----------------------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'orders' 
        AND policyname = 'Vendors read own store orders'
    ) THEN
        RAISE EXCEPTION 'Scoped vendor read policy missing - 007_secure_rls_policies.sql must be applied';
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'orders' 
        AND policyname = 'Vendors update own store orders'
    ) THEN
        RAISE EXCEPTION 'Scoped vendor update policy missing - 007_secure_rls_policies.sql must be applied';
    END IF;
END;
$$;

-- ----------------------------------------------------------------------------
-- 4. Add audit logging for order status transitions
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.order_audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES public.orders(uuid_id) ON DELETE CASCADE,
    actor_id TEXT,
    actor_role TEXT,
    action TEXT NOT NULL,
    old_status TEXT,
    new_status TEXT,
    details JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.order_audit_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Service role can manage audit logs" 
ON public.order_audit_log 
FOR ALL USING (auth.role() = 'service_role');

-- ----------------------------------------------------------------------------
-- 5. Add audit logging for coupon redemptions
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.coupon_audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    coupon_code TEXT NOT NULL,
    user_id TEXT NOT NULL,
    order_id UUID REFERENCES public.orders(uuid_id) ON DELETE CASCADE,
    discount_amount NUMERIC(10,2) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.coupon_audit_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Service role can manage coupon audit logs" 
ON public.coupon_audit_log 
FOR ALL USING (auth.role() = 'service_role');

-- ----------------------------------------------------------------------------
-- 6. Add audit logging for vendor inventory changes
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.inventory_audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    item_id UUID REFERENCES public.items(id) ON DELETE CASCADE,
    vendor_id UUID REFERENCES public.vendors(id),
    action TEXT NOT NULL,
    old_quantity INT,
    new_quantity INT,
    details JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.inventory_audit_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Vendors can view own inventory audit" 
ON public.inventory_audit_log 
FOR SELECT USING (
    vendor_id IN (
        SELECT id FROM public.vendors WHERE name = auth.uid()::text
    )
);

CREATE POLICY "Service role can manage inventory audit logs" 
ON public.inventory_audit_log 
FOR ALL USING (auth.role() = 'service_role');

-- ----------------------------------------------------------------------------
-- 7. Add trigger for order status change audit logging
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION audit_order_status_change()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status IS DISTINCT FROM OLD.status THEN
        INSERT INTO public.order_audit_log (
            order_id, actor_id, actor_role, action, old_status, new_status, details
        ) VALUES (
            NEW.uuid_id, 
            COALESCE(current_setting('app.actor_id', true), 'system'),
            COALESCE(current_setting('app.actor_role', true), 'system'),
            'status_change',
            OLD.status,
            NEW.status,
            jsonb_build_object('updated_at', NOW())
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS order_status_audit_trigger ON public.orders;
CREATE TRIGGER order_status_audit_trigger
    BEFORE UPDATE ON public.orders
    FOR EACH ROW
    EXECUTE FUNCTION audit_order_status_change();

-- ----------------------------------------------------------------------------
-- 8. Fix currency consistency: standardize on paise (integer minor units)
-- ----------------------------------------------------------------------------
ALTER TABLE public.orders 
    DROP COLUMN IF EXISTS total_amount_paise,
    ADD COLUMN IF NOT EXISTS total_amount_paise INTEGER;

-- ----------------------------------------------------------------------------
-- 9. Add missing vendor approval audit trigger
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION audit_vendor_approval()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_approved IS DISTINCT FROM OLD.is_approved THEN
        INSERT INTO public.order_audit_log (
            order_id, actor_id, actor_role, action, old_status, new_status, details
        ) VALUES (
            gen_random_uuid(), 
            COALESCE(current_setting('app.actor_id', true), 'system'),
            COALESCE(current_setting('app.actor_role', true), 'system'),
            'vendor_approval',
            OLD.is_approved::text,
            NEW.is_approved::text,
            jsonb_build_object('vendor_id', NEW.id)
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS vendor_approval_audit_trigger ON public.vendors;
CREATE TRIGGER vendor_approval_audit_trigger
    BEFORE UPDATE ON public.vendors
    FOR EACH ROW
    EXECUTE FUNCTION audit_vendor_approval();

-- ----------------------------------------------------------------------------
-- 10. Add rider approval audit trigger
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION audit_rider_approval()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.approval_status IS DISTINCT FROM OLD.approval_status THEN
        INSERT INTO public.order_audit_log (
            order_id, actor_id, actor_role, action, old_status, new_status, details
        ) VALUES (
            gen_random_uuid(), 
            COALESCE(current_setting('app.actor_id', true), 'system'),
            COALESCE(current_setting('app.actor_role', true), 'system'),
            'rider_approval',
            OLD.approval_status,
            NEW.approval_status,
            jsonb_build_object('rider_id', NEW.id)
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS rider_approval_audit_trigger ON public.riders;
CREATE TRIGGER rider_approval_audit_trigger
    BEFORE UPDATE ON public.riders
    FOR EACH ROW
    EXECUTE FUNCTION audit_rider_approval();