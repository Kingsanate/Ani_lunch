-- ============================================================================
-- 012_users_pages_schema.sql
-- Phase 1: Recover DB source of truth
-- Handles users profile and CMS pages tables
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. App Settings (ensure exists)
-- ----------------------------------------------------------------------------
INSERT INTO public.app_settings (id, home_video_url, show_hero_banner) 
VALUES (1, NULL, TRUE)
ON CONFLICT (id) DO UPDATE SET
    home_video_url = EXCLUDED.home_video_url;

-- ----------------------------------------------------------------------------
-- 2. Users profile table (if not exists)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT UNIQUE,
    name TEXT DEFAULT '',
    email TEXT DEFAULT '',
    phone TEXT DEFAULT '',
    address TEXT DEFAULT '',
    avatar_url TEXT DEFAULT '',
    role TEXT DEFAULT 'customer' CHECK (role IN ('customer', 'vendor', 'admin', 'rider')),
    is_approved BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_user_id ON public.users(user_id);
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);

-- ----------------------------------------------------------------------------
-- 3. Pages / CMS table
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.pages (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    slug TEXT NOT NULL UNIQUE,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    meta_title TEXT,
    meta_description TEXT,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_pages_slug ON public.pages(slug);

-- ----------------------------------------------------------------------------
-- 4. RLS for pages
-- ----------------------------------------------------------------------------
ALTER TABLE public.pages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Pages are viewable by everyone" 
ON public.pages 
FOR SELECT USING (true);

CREATE POLICY "Pages are editable by admins only" 
ON public.pages 
FOR ALL USING (
    EXISTS (
        SELECT 1 FROM public.users 
        WHERE users.id = auth.uid() 
        AND users.role = 'admin'
    )
);

-- ----------------------------------------------------------------------------
-- 5. Sample pages for baseline
-- ----------------------------------------------------------------------------
INSERT INTO public.pages (slug, title, content) VALUES
('about', 'About Us', 'Learn about AniMeat')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO public.pages (slug, title, content) VALUES
('contact', 'Contact Us', 'Get in touch with us')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO public.pages (slug, title, content) VALUES
('terms', 'Terms of Service', 'Terms and conditions')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO public.pages (slug, title, content) VALUES
('privacy', 'Privacy Policy', 'Privacy policy details')
ON CONFLICT (slug) DO NOTHING;