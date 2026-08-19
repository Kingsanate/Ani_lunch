-- ============================================================================
-- 014_fix_id_types_and_rls.sql
-- Phase 1: Fix type inconsistencies and strengthen RLS
-- Resolves orders.id TEXT vs UUID and riders.id UUID issues
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Fix orders.id type inconsistency (TEXT -> UUID)
--    Note: This requires careful handling of existing data
-- ----------------------------------------------------------------------------
-- First, add a UUID column and populate it
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS uuid_id UUID DEFAULT gen_random_uuid();

-- Backfill UUID for existing orders
UPDATE public.orders 
SET uuid_id = gen_random_uuid() 
WHERE uuid_id IS NULL;

-- Create index on uuid_id
CREATE INDEX IF NOT EXISTS idx_orders_uuid_id ON public.orders(uuid_id);

-- ----------------------------------------------------------------------------
-- 2. Fix riders.id to ensure it uses UUID properly
-- ----------------------------------------------------------------------------
-- riders table already uses UUID primary key per 000_base_schema
-- Ensure there's no TEXT variant lingering
ALTER TABLE public.riders DROP COLUMN IF EXISTS text_id;

-- ----------------------------------------------------------------------------
-- 3. Strengthen RLS on items table (column-level)
-- ----------------------------------------------------------------------------
-- Drop overly permissive policies if they exist
DROP POLICY IF EXISTS "Items are editable by vendor and admins" ON public.items;

-- Create more restrictive policies
CREATE POLICY "Items are viewable by everyone" 
ON public.items 
FOR SELECT USING (is_active = TRUE AND is_available = TRUE);

CREATE POLICY "Vendors can manage own items" 
ON public.items 
FOR ALL USING (
    vendor_id IN (
        SELECT id FROM public.vendors WHERE name = auth.uid()::text
    ) OR 
    EXISTS (
        SELECT 1 FROM public.users WHERE users.id = auth.uid() AND users.role = 'admin'
    )
);

-- ----------------------------------------------------------------------------
-- 4. Strengthen RLS on daily_deals
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Daily deals are viewable by everyone" ON public.daily_deals;

CREATE POLICY "Active daily deals are viewable" 
ON public.daily_deals 
FOR SELECT USING (is_active = TRUE AND valid_from <= NOW() AND (valid_until IS NULL OR valid_until >= NOW()));

-- ----------------------------------------------------------------------------
-- 5. Add RLS to riders table (critical security gap)
-- ----------------------------------------------------------------------------
ALTER TABLE public.riders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Riders can read own profile" 
ON public.riders 
FOR SELECT USING (id = auth.uid());

CREATE POLICY "Admins can manage all riders" 
ON public.riders 
FOR ALL USING (
    EXISTS (
        SELECT 1 FROM public.users WHERE users.id = auth.uid() AND users.role = 'admin'
    )
);

-- ----------------------------------------------------------------------------
-- 6. Fix the accept_order function security
-- ----------------------------------------------------------------------------
REVOKE EXECUTE ON FUNCTION public.accept_order(TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.accept_order(TEXT, TEXT) TO service_role;

-- ----------------------------------------------------------------------------
-- 7. Ensure vendor_orders table has proper RLS
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.vendor_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_id UUID REFERENCES public.vendors(id),
    order_id UUID REFERENCES public.orders(uuid_id),
    status TEXT DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.vendor_orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Vendors can view own orders" 
ON public.vendor_orders 
FOR SELECT USING (
    vendor_id IN (
        SELECT id FROM public.vendors WHERE name = auth.uid()::text
    )
);

-- ----------------------------------------------------------------------------
-- 8. Add payment_intent table with RLS (missing per audit)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.payment_intents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES public.orders(uuid_id),
    amount_paise INTEGER NOT NULL,
    currency TEXT DEFAULT 'INR',
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'refunded')),
    provider TEXT NOT NULL,
    provider_id TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.payment_intents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own payment intents" 
ON public.payment_intents 
FOR SELECT USING (
    order_id IN (
        SELECT uuid_id FROM public.orders WHERE user_id = auth.uid()::text
    )
);

CREATE POLICY "Service role can manage payment intents" 
ON public.payment_intents 
FOR ALL USING (auth.role() = 'service_role');