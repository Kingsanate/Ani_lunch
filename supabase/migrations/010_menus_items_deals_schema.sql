-- ============================================================================
-- 010_menus_items_deals_schema.sql
-- Phase 1: Recover DB source of truth
-- Creates the canonical menus, items, and daily_deals tables with proper
-- UUID primary keys, RLS policies, and indexes for production use.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Menus / Categories table
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.menus (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    menu_title TEXT NOT NULL,
    image_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Backwards-compatibility view for legacy BIGINT references
CREATE OR REPLACE VIEW public.menus_legacy AS
SELECT 
    id AS uuid_id,
    menu_title,
    image_url,
    created_at,
    updated_at
FROM public.menus;

-- ----------------------------------------------------------------------------
-- 2. Items / Products table (canonical UUID schema)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    item_title TEXT NOT NULL,
    item_price NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    discount_price NUMERIC(10,2),
    description TEXT DEFAULT '',
    thumbnail_url TEXT,
    thumbnail_url_2 TEXT,
    thumbnail_url_3 TEXT,
    category_id UUID REFERENCES public.menus(id) ON DELETE SET NULL,
    vendor_id UUID REFERENCES public.vendors(id) ON DELETE SET NULL,
    is_active BOOLEAN DEFAULT TRUE,
    is_available BOOLEAN DEFAULT TRUE,
    preparation_min INT DEFAULT 15,
    rating NUMERIC(3,2) DEFAULT 0.00,
    reviews_count INT DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Backwards-compatibility view for legacy TEXT references
CREATE OR REPLACE VIEW public.products_legacy AS
SELECT 
    id AS uuid_id,
    item_title,
    item_price,
    discount_price,
    description,
    thumbnail_url,
    category_id,
    vendor_id,
    is_active,
    is_available,
    preparation_min,
    rating,
    reviews_count,
    created_at,
    updated_at
FROM public.items;

-- ----------------------------------------------------------------------------
-- 3. Daily Deals / Promotions table
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.daily_deals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT DEFAULT '',
    discount TEXT DEFAULT '',
    original_price NUMERIC(10,2) DEFAULT 0.00,
    deal_price NUMERIC(10,2) DEFAULT 0.00,
    image_url TEXT,
    banner_image_url TEXT,
    discount_percent NUMERIC(5,2) DEFAULT 0.00,
    max_discount_amount NUMERIC(10,2),
    valid_from TIMESTAMPTZ DEFAULT NOW(),
    valid_until TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 4. Enable Row Level Security
-- ----------------------------------------------------------------------------
ALTER TABLE public.menus ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_deals ENABLE ROW LEVEL SECURITY;

-- ----------------------------------------------------------------------------
-- 5. Create indexes for performance
-- ----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_items_category_id ON public.items(category_id);
CREATE INDEX IF NOT EXISTS idx_items_vendor_id ON public.items(vendor_id);
CREATE INDEX IF NOT EXISTS idx_items_is_active ON public.items(is_active);
CREATE INDEX IF NOT EXISTS idx_items_is_available ON public.items(is_available);
CREATE INDEX IF NOT EXISTS idx_items_rating ON public.items(rating DESC);
CREATE INDEX IF NOT EXISTS idx_daily_deals_active ON public.daily_deals(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_daily_deals_valid ON public.daily_deals(valid_from, valid_until);

-- ----------------------------------------------------------------------------
-- 6. Basic RLS policies (to be tightened in Phase 2)
-- ----------------------------------------------------------------------------
-- Menus: Public read, vendor/admin write
CREATE POLICY "Menus are viewable by everyone" 
ON public.menus 
FOR SELECT USING (true);

CREATE POLICY "Menus are editable by vendors and admins" 
ON public.menus 
FOR ALL USING (
    EXISTS (
        SELECT 1 FROM public.users 
        WHERE users.id = auth.uid() 
        AND users.role IN ('vendor', 'admin')
    )
);

-- Items: Vendor-scoped write, public read
CREATE POLICY "Items are viewable by everyone" 
ON public.items 
FOR SELECT USING (true);

CREATE POLICY "Items are editable by vendor and admins" 
ON public.items 
FOR ALL USING (
    EXISTS (
        SELECT 1 FROM public.users 
        WHERE users.id = auth.uid() 
        AND users.role IN ('vendor', 'admin')
    )
);

-- Daily Deals: Public read, admin write
CREATE POLICY "Daily deals are viewable by everyone" 
ON public.daily_deals 
FOR SELECT USING (true);

CREATE POLICY "Daily deals are editable by admins only" 
ON public.daily_deals 
FOR ALL USING (
    EXISTS (
        SELECT 1 FROM public.users 
        WHERE users.id = auth.uid() 
        AND users.role = 'admin'
    )
);

-- ----------------------------------------------------------------------------
-- 7. Enable realtime publication for catalog tables
-- ----------------------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND schemaname = 'public' 
        AND tablename = 'menus'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.menus;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND schemaname = 'public' 
        AND tablename = 'items'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.items;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND schemaname = 'public' 
        AND tablename = 'daily_deals'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.daily_deals;
    END IF;
END;
$$;