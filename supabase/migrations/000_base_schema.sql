-- ============================================================================
-- 000_base_schema.sql
-- Complete Idempotent PostgreSQL Baseline Schema for AniLunch / AniMeat
-- Reconstructed from application code, Dart models, Edge functions, and migrations.
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ----------------------------------------------------------------------------
-- 1. USERS PROFILE TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT UNIQUE,
    name TEXT DEFAULT '',
    email TEXT DEFAULT '',
    phone TEXT DEFAULT '',
    address TEXT DEFAULT '',
    avatar_url TEXT DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_user_id ON public.users(user_id);
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);

-- ----------------------------------------------------------------------------
-- 2. VENDORS / RESTAURANTS
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.vendors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    address TEXT DEFAULT '',
    phone TEXT DEFAULT '',
    location_lat DOUBLE PRECISION,
    location_lng DOUBLE PRECISION,
    is_open BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Backwards-compatibility view for legacy 'sellers' references
CREATE OR REPLACE VIEW public.sellers AS 
SELECT id, name, address, phone, is_open, created_at, updated_at 
FROM public.vendors;

-- ----------------------------------------------------------------------------
-- 3. MENUS / CATEGORIES
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.menus (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    menu_title TEXT NOT NULL,
    image_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 4. ITEMS / PRODUCTS CATALOG (Meat, Grocery, General Items)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.items (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    item_title TEXT NOT NULL,
    item_price NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    discount_price NUMERIC(10,2),
    description TEXT DEFAULT '',
    thumbnail_url TEXT,
    category_id BIGINT REFERENCES public.menus(id) ON DELETE SET NULL,
    vendor_id UUID REFERENCES public.vendors(id) ON DELETE SET NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_items_category_id ON public.items(category_id);
CREATE INDEX IF NOT EXISTS idx_items_vendor_id ON public.items(vendor_id);
CREATE INDEX IF NOT EXISTS idx_items_is_active ON public.items(is_active);

-- Backwards-compatibility view for 'products' table references
CREATE OR REPLACE VIEW public.products AS 
SELECT * FROM public.items;

-- ----------------------------------------------------------------------------
-- 5. MEAL PRODUCTS (Daily Lunch / Bento Boxes)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.meal_products (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name TEXT NOT NULL,
    price NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    discount_price NUMERIC(10,2),
    description TEXT DEFAULT '',
    image_url TEXT,
    rice_options TEXT[] DEFAULT ARRAY['White Rice', 'Brown Rice', 'Jadoh', 'No Rice'],
    meat_options TEXT[] DEFAULT ARRAY['Chicken', 'Beef', 'Pork', 'Fish'],
    vendor_id UUID REFERENCES public.vendors(id) ON DELETE SET NULL,
    is_available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_meal_products_available ON public.meal_products(is_available);

-- ----------------------------------------------------------------------------
-- 6. DAILY DEALS / PROMOTIONS
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.daily_deals (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT DEFAULT '',
    discount TEXT DEFAULT '',
    original_price NUMERIC(10,2) DEFAULT 0.00,
    deal_price NUMERIC(10,2) DEFAULT 0.00,
    image_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 7. COUPONS
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.coupons (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code TEXT NOT NULL UNIQUE,
    discount_type TEXT NOT NULL CHECK (discount_type IN ('flat', 'percent')),
    discount_value NUMERIC(10,2) NOT NULL,
    min_order_amount NUMERIC(10,2) DEFAULT 0.00,
    max_discount_amount NUMERIC(10,2),
    is_active BOOLEAN DEFAULT TRUE,
    expiration_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 8. PRODUCT REVIEWS
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.product_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id TEXT NOT NULL,
    user_id TEXT NOT NULL,
    rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review_text TEXT DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_product_reviews_product_id ON public.product_reviews(product_id);

-- ----------------------------------------------------------------------------
-- 9. CMS / STATIC PAGES
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.pages (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    slug TEXT NOT NULL UNIQUE,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 10. RIDERS
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.riders (
    id UUID PRIMARY KEY,
    name TEXT NOT NULL DEFAULT '',
    phone TEXT NOT NULL DEFAULT '',
    email TEXT NOT NULL DEFAULT '',
    is_online BOOLEAN NOT NULL DEFAULT FALSE,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    is_approved BOOLEAN NOT NULL DEFAULT FALSE,
    approval_status TEXT NOT NULL DEFAULT 'pending' CHECK (approval_status IN ('pending', 'approved', 'rejected')),
    rejection_reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_riders_status ON public.riders(is_online, is_approved, approval_status);

-- ----------------------------------------------------------------------------
-- 11. ORDERS
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.orders (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    ordered_by TEXT,
    order_type TEXT DEFAULT 'meat',
    items JSONB NOT NULL DEFAULT '[]'::jsonb,
    product_ids TEXT[],
    subtotal NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    delivery_fee NUMERIC(10,2) NOT NULL DEFAULT 50.00,
    discount_amount NUMERIC(10,2) DEFAULT 0.00,
    coupon_code TEXT,
    total_amount NUMERIC(10,2) NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    payment_method TEXT NOT NULL DEFAULT 'COD',
    address TEXT DEFAULT '',
    customer_lat DOUBLE PRECISION,
    customer_lng DOUBLE PRECISION,
    rider_id TEXT,
    vendor_id UUID REFERENCES public.vendors(id) ON DELETE SET NULL,
    order_time TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_orders_user_id ON public.orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_rider_id ON public.orders(rider_id);
CREATE INDEX IF NOT EXISTS idx_orders_vendor_id ON public.orders(vendor_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_order_time ON public.orders(order_time DESC);
CREATE INDEX IF NOT EXISTS idx_orders_available ON public.orders(status, rider_id) 
    WHERE (rider_id IS NULL OR rider_id = '') AND status IN ('pending', 'ready_for_pickup');

-- ----------------------------------------------------------------------------
-- 12. APP SETTINGS (Branding & Dynamic Configuration)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.app_settings (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    home_video_url TEXT,
    show_hero_banner BOOLEAN DEFAULT TRUE,
    hero_badge_text TEXT DEFAULT '🔥 Fresh Meat Daily',
    hero_title TEXT DEFAULT 'Your Daily Lunch,\nDelivered Fresh & Fast!',
    hero_subtitle TEXT DEFAULT 'Delicious meals, delivered to your door',
    hero_button_text TEXT DEFAULT 'Order Now',
    footer_subtitle TEXT DEFAULT 'Fresh meat, delivered daily.',
    footer_support_links TEXT DEFAULT 'Help Center, Contact Us, FAQs',
    footer_legal_links TEXT DEFAULT 'Privacy Policy, Terms of Use, Refund Policy',
    footer_copyright TEXT DEFAULT '© 2026 Anilunch. All rights reserved.',
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO public.app_settings (id) VALUES (1) ON CONFLICT (id) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 13. ENABLE REALTIME PUBLICATION
-- ----------------------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'orders'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.orders;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'riders'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.riders;
    END IF;
END;
$$;
