-- ============================================================================
-- 010_sellers_vendors_reconciliation.sql
-- Reconcile 'sellers' (used by Vendor Flutter app) with 'vendors' (canonical table)
-- This is an EXPAND-only migration - adds compatibility without breaking changes.
-- ============================================================================

-- The 'vendors' table is the canonical source (created in 000_base_schema.sql).
-- The Vendor Flutter app queries 'sellers' table.
-- Create a view 'sellers' that mirrors 'vendors' for backwards compatibility.
-- Note: 000_base_schema.sql already has this view, but ensure it exists and is complete.

CREATE OR REPLACE VIEW public.sellers AS 
SELECT 
    id,
    name,
    address,
    phone,
    location_lat,
    location_lng,
    is_open,
    created_at,
    updated_at
FROM public.vendors;

-- Grant select on the view to authenticated and anon roles
GRANT SELECT ON public.sellers TO anon, authenticated, service_role;

-- Add RLS policy on the view (inherits from underlying table, but explicit is safer)
ALTER VIEW public.sellers SET (security_invoker = true);

-- ----------------------------------------------------------------------------
-- 2. Ensure vendors table has all columns needed by Vendor app
-- ----------------------------------------------------------------------------
-- The Vendor app's supabase_service.dart queries 'sellers' with columns:
-- id, name, email, phone, store_name
-- We need to add 'email' and 'store_name' columns to vendors if missing.

ALTER TABLE public.vendors ADD COLUMN IF NOT EXISTS email TEXT DEFAULT '';
ALTER TABLE public.vendors ADD COLUMN IF NOT EXISTS store_name TEXT DEFAULT '';

-- Backfill store_name from name
UPDATE public.vendors 
SET store_name = COALESCE(NULLIF(store_name, ''), name)
WHERE store_name = '' OR store_name IS NULL;

-- ----------------------------------------------------------------------------
-- 3. Create/update rules to keep sellers view compatible with Vendor app queries
-- ----------------------------------------------------------------------------
-- The Vendor app may try to insert/update into 'sellers' (though it shouldn't).
-- Create rules to redirect writes to vendors table.

CREATE OR REPLACE RULE sellers_insert AS
ON INSERT TO public.sellers
DO INSTEAD
INSERT INTO public.vendors (id, name, address, phone, location_lat, location_lng, is_open, email, store_name)
VALUES (NEW.id, NEW.name, NEW.address, NEW.phone, NEW.location_lat, NEW.location_lng, NEW.is_open, NEW.email, NEW.store_name);

CREATE OR REPLACE RULE sellers_update AS
ON UPDATE TO public.sellers
DO INSTEAD
UPDATE public.vendors
SET name = NEW.name,
    address = NEW.address,
    phone = NEW.phone,
    location_lat = NEW.location_lat,
    location_lng = NEW.location_lng,
    is_open = NEW.is_open,
    email = NEW.email,
    store_name = NEW.store_name,
    updated_at = NOW()
WHERE id = OLD.id;

CREATE OR REPLACE RULE sellers_delete AS
ON DELETE TO public.sellers
DO INSTEAD
DELETE FROM public.vendors WHERE id = OLD.id;

-- ----------------------------------------------------------------------------
-- 4. Ensure items table has vendor_id (for vendor-specific catalog)
-- ----------------------------------------------------------------------------
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS vendor_id UUID REFERENCES public.vendors(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_items_vendor_id ON public.items(vendor_id);

-- ----------------------------------------------------------------------------
-- 5. Ensure meal_products has vendor_id (for vendor-specific meals)
-- ----------------------------------------------------------------------------
ALTER TABLE public.meal_products ADD COLUMN IF NOT EXISTS vendor_id UUID REFERENCES public.vendors(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_meal_products_vendor_id ON public.meal_products(vendor_id);

-- ----------------------------------------------------------------------------
-- 6. Add updated_at trigger for vendors (if not exists)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_vendors_updated_at ON public.vendors;
CREATE TRIGGER trg_vendors_updated_at
    BEFORE UPDATE ON public.vendors
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ----------------------------------------------------------------------------
-- 7. RLS policies on vendors table
-- ----------------------------------------------------------------------------
ALTER TABLE public.vendors ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read vendors" ON public.vendors;
CREATE POLICY "Public read vendors" ON public.vendors
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Vendor update own profile" ON public.vendors;
CREATE POLICY "Vendor update own profile" ON public.vendors
    FOR UPDATE USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Service role full access on vendors" ON public.vendors;
CREATE POLICY "Service role full access on vendors" ON public.vendors
    FOR ALL USING (auth.role() = 'service_role');
