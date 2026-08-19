-- ============================================================================
-- 13_seed_catalog_data.sql
-- Phase 1: Recover DB source of truth
-- Seed baseline data for menus, items, and daily deals
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Seed sample menu categories
-- ----------------------------------------------------------------------------
INSERT INTO public.menus (menu_title, image_url) VALUES
('Main Course', 'https://example.com/main.jpg'),
('Beverages', 'https://example.com/drinks.jpg'),
('Desserts', 'https://example.com/desserts.jpg')
ON CONFLICT DO NOTHING;

-- ----------------------------------------------------------------------------
-- 2. Seed sample items
-- ----------------------------------------------------------------------------
INSERT INTO public.items (item_title, item_price, thumbnail_url, category_id, is_active) VALUES
('Chicken Biryani', 180.00, 'https://example.com/biryani.jpg', 
  (SELECT id FROM public.menus WHERE menu_title = 'Main Course'), true),
('Masala Chai', 80.00, 'https://example.com/chai.jpg',
  (SELECT id FROM public.menus WHERE menu_title = 'Beverages'), true),
('Gulab Jamun', 120.00, 'https://example.com/gulabjamun.jpg',
  (SELECT id FROM public.menus WHERE menu_title = 'Desserts'), true)
ON CONFLICT DO NOTHING;

-- ----------------------------------------------------------------------------
-- 3. Seed sample daily deals
-- ----------------------------------------------------------------------------
INSERT INTO public.daily_deals (title, description, discount, original_price, deal_price, image_url, is_active) VALUES
('Weekend Special', 'Special weekend offer', '20% off', 200.00, 160.00, 'https://example.com/weekend.jpg', true),
('Lunch Combo', 'Combo meal deal', '15% off', 250.00, 212.50, 'https://example.com/combo.jpg', true)
ON CONFLICT DO NOTHING;

-- ----------------------------------------------------------------------------
-- 4. Seed sample coupons
-- ----------------------------------------------------------------------------
INSERT INTO public.coupons (code, discount_type, discount_value, min_order_amount, is_active) VALUES
('WELCOME10', 'percent', 10.00, 100.00, true),
('FREEDELIVERY', 'flat', 50.00, 300.00, true)
ON CONFLICT DO NOTHING;

-- ----------------------------------------------------------------------------
-- 5. Enable realtime for seeded tables
-- ----------------------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND schemaname = 'public' 
        AND tablename = 'coupons'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.coupons;
    END IF;
END;
$$;