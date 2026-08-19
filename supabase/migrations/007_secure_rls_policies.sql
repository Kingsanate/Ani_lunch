-- ============================================================================
-- 007_secure_rls_policies.sql
-- Security Hardening & Precise Role-Based RLS Policies
-- Fixes SEC-01 through SEC-05 (closes wide-open auth.role() = 'authenticated' holes)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. HARDEN ORDERS TABLE RLS
-- ----------------------------------------------------------------------------
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

-- Drop all legacy and insecure policies
DROP POLICY IF EXISTS "Vendors read orders" ON public.orders;
DROP POLICY IF EXISTS "Vendors update orders" ON public.orders;
DROP POLICY IF EXISTS "Rider can view available orders" ON public.orders;
DROP POLICY IF EXISTS "Rider can accept order" ON public.orders;
DROP POLICY IF EXISTS "Riders read available orders" ON public.orders;
DROP POLICY IF EXISTS "Riders accept orders" ON public.orders;
DROP POLICY IF EXISTS "Riders read own orders" ON public.orders;
DROP POLICY IF EXISTS "Riders read own orders v2" ON orders;
DROP POLICY IF EXISTS "Riders update own order status" ON public.orders;
DROP POLICY IF EXISTS "Riders update own order status v2" ON orders;
DROP POLICY IF EXISTS "Riders see ready_for_pickup orders" ON orders;
DROP POLICY IF EXISTS "Riders accept ready_for_pickup orders" ON orders;
DROP POLICY IF EXISTS "Customers read own orders" ON public.orders;
DROP POLICY IF EXISTS "Customers insert own orders" ON public.orders;
DROP POLICY IF EXISTS "Customers cancel own pending orders" ON public.orders;
DROP POLICY IF EXISTS "Admins read all orders" ON public.orders;
DROP POLICY IF EXISTS "Admins update any order" ON public.orders;
DROP POLICY IF EXISTS "Service role full access on orders" ON public.orders;

-- CUSTOMER: Read own orders
CREATE POLICY "Customers read own orders" ON public.orders
    FOR SELECT USING (auth.uid()::text = user_id);

-- CUSTOMER: Insert own orders
CREATE POLICY "Customers insert own orders" ON public.orders
    FOR INSERT WITH CHECK (auth.uid()::text = user_id);

-- CUSTOMER: Cancel own pending orders
CREATE POLICY "Customers cancel own pending orders" ON public.orders
    FOR UPDATE USING (
        auth.uid()::text = user_id 
        AND status IN ('pending', 'pending_payment')
    )
    WITH CHECK (status = 'cancelled');

-- RIDER: See orders ready for pickup that have no assigned rider
CREATE POLICY "Riders see ready_for_pickup orders" ON public.orders
    FOR SELECT USING (
        status = 'ready_for_pickup' 
        AND (rider_id IS NULL OR rider_id = '')
    );

-- RIDER: See orders assigned to self
CREATE POLICY "Riders read own orders" ON public.orders
    FOR SELECT USING (rider_id = auth.uid()::text);

-- RIDER: Update status of own assigned orders (picked_up, delivered)
CREATE POLICY "Riders update own order status" ON public.orders
    FOR UPDATE USING (rider_id = auth.uid()::text)
    WITH CHECK (rider_id = auth.uid()::text);

-- VENDOR: Read orders belonging to vendor
CREATE POLICY "Vendors read own store orders" ON public.orders
    FOR SELECT USING (
        vendor_id IS NOT NULL AND (
            vendor_id = auth.uid() 
            OR vendor_id IN (SELECT id FROM public.vendors WHERE auth.uid() = id)
        )
    );

-- VENDOR: Update status of own store orders (preparing, ready_for_pickup)
CREATE POLICY "Vendors update own store orders" ON public.orders
    FOR UPDATE USING (
        vendor_id IS NOT NULL AND (
            vendor_id = auth.uid() 
            OR vendor_id IN (SELECT id FROM public.vendors WHERE auth.uid() = id)
        )
    );

-- SERVICE ROLE / ADMIN: Full backend access
CREATE POLICY "Service role full access on orders" ON public.orders
    FOR ALL USING (auth.role() = 'service_role');


-- ----------------------------------------------------------------------------
-- 2. HARDEN RIDERS TABLE RLS
-- ----------------------------------------------------------------------------
ALTER TABLE public.riders ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admin can read all riders" ON public.riders;
DROP POLICY IF EXISTS "Admin can update any rider" ON public.riders;
DROP POLICY IF EXISTS "Admin can update all riders" ON public.riders;
DROP POLICY IF EXISTS "Admin can delete rider" ON public.riders;
DROP POLICY IF EXISTS "Admin can delete riders" ON public.riders;
DROP POLICY IF EXISTS "Rider can read own profile" ON public.riders;
DROP POLICY IF EXISTS "Rider can update own profile" ON public.riders;
DROP POLICY IF EXISTS "Rider can insert own profile" ON public.riders;
DROP POLICY IF EXISTS "Service role full access on riders" ON public.riders;

-- RIDER: Read own profile
CREATE POLICY "Rider read own profile" ON public.riders
    FOR SELECT USING (auth.uid() = id);

-- RIDER: Update own profile & GPS location (cannot change approval status)
CREATE POLICY "Rider update own profile" ON public.riders
    FOR UPDATE USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- RIDER: Self registration
CREATE POLICY "Rider insert own profile" ON public.riders
    FOR INSERT WITH CHECK (auth.uid() = id);

-- SERVICE ROLE / ADMIN: Manage riders (approve, reject, delete)
CREATE POLICY "Service role full access on riders" ON public.riders
    FOR ALL USING (auth.role() = 'service_role');


-- ----------------------------------------------------------------------------
-- 3. HARDEN VENDORS TABLE RLS
-- ----------------------------------------------------------------------------
ALTER TABLE public.vendors ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public read access to vendors" ON public.vendors;
DROP POLICY IF EXISTS "Allow authenticated full access to vendors" ON public.vendors;
DROP POLICY IF EXISTS "Service role full access on vendors" ON public.vendors;

-- PUBLIC: Read open/available vendors
CREATE POLICY "Public read vendors" ON public.vendors
    FOR SELECT USING (true);

-- VENDOR: Update own profile
CREATE POLICY "Vendor update own profile" ON public.vendors
    FOR UPDATE USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- SERVICE ROLE / ADMIN: Full access
CREATE POLICY "Service role full access on vendors" ON public.vendors
    FOR ALL USING (auth.role() = 'service_role');


-- ----------------------------------------------------------------------------
-- 4. HARDEN PUBLIC CATALOG TABLES (items, menus, deals, app_settings, pages)
-- ----------------------------------------------------------------------------
ALTER TABLE public.items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menus ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meal_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_deals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coupons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;

-- Public Select
DROP POLICY IF EXISTS "Public read items" ON public.items;
CREATE POLICY "Public read items" ON public.items FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public read menus" ON public.menus;
CREATE POLICY "Public read menus" ON public.menus FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public read meal_products" ON public.meal_products;
CREATE POLICY "Public read meal_products" ON public.meal_products FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public read daily_deals" ON public.daily_deals;
CREATE POLICY "Public read daily_deals" ON public.daily_deals FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public read active coupons" ON public.coupons;
CREATE POLICY "Public read active coupons" ON public.coupons FOR SELECT USING (is_active = true);

DROP POLICY IF EXISTS "Public read product_reviews" ON public.product_reviews;
CREATE POLICY "Public read product_reviews" ON public.product_reviews FOR SELECT USING (true);

DROP POLICY IF EXISTS "Customer insert product_reviews" ON public.product_reviews;
CREATE POLICY "Customer insert product_reviews" ON public.product_reviews 
    FOR INSERT WITH CHECK (auth.uid()::text = user_id);

DROP POLICY IF EXISTS "Public read pages" ON public.pages;
CREATE POLICY "Public read pages" ON public.pages FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public read app_settings" ON public.app_settings;
CREATE POLICY "Public read app_settings" ON public.app_settings FOR SELECT USING (true);

-- Service Role Full Access on Catalog
DROP POLICY IF EXISTS "Service role items" ON public.items;
CREATE POLICY "Service role items" ON public.items FOR ALL USING (auth.role() = 'service_role');

DROP POLICY IF EXISTS "Service role menus" ON public.menus;
CREATE POLICY "Service role menus" ON public.menus FOR ALL USING (auth.role() = 'service_role');

DROP POLICY IF EXISTS "Service role meal_products" ON public.meal_products;
CREATE POLICY "Service role meal_products" ON public.meal_products FOR ALL USING (auth.role() = 'service_role');

DROP POLICY IF EXISTS "Service role daily_deals" ON public.daily_deals;
CREATE POLICY "Service role daily_deals" ON public.daily_deals FOR ALL USING (auth.role() = 'service_role');

DROP POLICY IF EXISTS "Service role coupons" ON public.coupons;
CREATE POLICY "Service role coupons" ON public.coupons FOR ALL USING (auth.role() = 'service_role');

DROP POLICY IF EXISTS "Service role pages" ON public.pages;
CREATE POLICY "Service role pages" ON public.pages FOR ALL USING (auth.role() = 'service_role');

DROP POLICY IF EXISTS "Service role app_settings" ON public.app_settings;
CREATE POLICY "Service role app_settings" ON public.app_settings FOR ALL USING (auth.role() = 'service_role');
