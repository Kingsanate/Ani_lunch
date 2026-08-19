-- ============================================================================
-- AniMeat load-test seed data
-- Run:  docker compose exec postgres psql -U postgres -d animeat -f /seed.sql
--       (or: docker compose -f backend/docker-compose.yml exec postgres psql ... )
--
-- Idempotent: safe to re-run before every load tier.
-- ============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. Vendors (8) — id == vendor auth user id (single-store identity model)
-- ---------------------------------------------------------------------------
INSERT INTO public.vendors (id, name, address, phone, location_lat, location_lng, is_open)
SELECT v.id, 'Vendor ' || n, 'Shillong ' || n, '555-000' || n, 25.57 + n * 0.001, 91.88 + n * 0.001, TRUE
FROM (VALUES
  ('00000000-0000-0000-0000-000000000001', 1),
  ('00000000-0000-0000-0000-000000000002', 2),
  ('00000000-0000-0000-0000-000000000003', 3),
  ('00000000-0000-0000-0000-000000000004', 4),
  ('00000000-0000-0000-0000-000000000005', 5),
  ('00000000-0000-0000-0000-000000000006', 6),
  ('00000000-0000-0000-0000-000000000007', 7),
  ('00000000-0000-0000-0000-000000000008', 8)
) AS v(id, n)
ON CONFLICT (id) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 2. Riders (24) — approved, some online
-- ---------------------------------------------------------------------------
INSERT INTO public.riders (id, name, phone, email, is_online, latitude, longitude, is_approved, approval_status)
SELECT r.id, 'Rider ' || n, '666-00' || n, 'rider' || n || '@animeat.test', n % 3 = 0,
       25.57 + n * 0.002, 91.88 + n * 0.002, TRUE, 'approved'
FROM (VALUES
  ('10000000-0000-0000-0000-000000000001', 1),
  ('10000000-0000-0000-0000-000000000002', 2),
  ('10000000-0000-0000-0000-000000000003', 3),
  ('10000000-0000-0000-0000-000000000004', 4),
  ('10000000-0000-0000-0000-000000000005', 5),
  ('10000000-0000-0000-0000-000000000006', 6),
  ('10000000-0000-0000-0000-000000000007', 7),
  ('10000000-0000-0000-0000-000000000008', 8),
  ('10000000-0000-0000-0000-000000000009', 9),
  ('10000000-0000-0000-0000-000000000010', 10),
  ('10000000-0000-0000-0000-000000000011', 11),
  ('10000000-0000-0000-0000-000000000012', 12),
  ('10000000-0000-0000-0000-000000000013', 13),
  ('10000000-0000-0000-0000-000000000014', 14),
  ('10000000-0000-0000-0000-000000000015', 15),
  ('10000000-0000-0000-0000-000000000016', 16),
  ('10000000-0000-0000-0000-000000000017', 17),
  ('10000000-0000-0000-0000-000000000018', 18),
  ('10000000-0000-0000-0000-000000000019', 19),
  ('10000000-0000-0000-0000-000000000020', 20),
  ('10000000-0000-0000-0000-000000000021', 21),
  ('10000000-0000-0000-0000-000000000022', 22),
  ('10000000-0000-0000-0000-000000000023', 23),
  ('10000000-0000-0000-0000-000000000024', 24)
) AS r(id, n)
ON CONFLICT (id) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 3. Menus / categories (8)
-- ---------------------------------------------------------------------------
INSERT INTO public.menus (menu_title, description, is_active)
SELECT 'Category ' || n, 'Load-test category ' || n, TRUE
FROM generate_series(1, 8) AS n
ON CONFLICT DO NOTHING;

-- ---------------------------------------------------------------------------
-- 4. Items (400) — canonical price in paise, legacy columns for parity
-- ---------------------------------------------------------------------------
INSERT INTO public.items (item_title, item_price, discount_price, description, thumbnail_url, category_id, vendor_id, is_active, name, price, is_available)
SELECT
  'Item ' || n,
  (300 + (n % 40) * 25)::numeric(10,2),                    -- ₹300–₹1275
  CASE WHEN n % 5 = 0 THEN ((300 + (n % 40) * 25) * 0.9)::numeric(10,2) END,
  'Load-test item ' || n,
  'https://images.animeat.test/items/' || n || '.jpg',
  (n % 8) + 1,
  ('00000000-0000-0000-0000-00000000000' || lpad(((n % 8) + 1)::text, 1, '0'))::uuid,
  TRUE,
  'Item ' || n,
  (300 + (n % 40) * 25) * 100,                              -- paise
  TRUE
FROM generate_series(1, 400) AS n
ON CONFLICT DO NOTHING;

-- ---------------------------------------------------------------------------
-- 5. Meal products (40) — lunch catalog, canonical price_paise
-- ---------------------------------------------------------------------------
INSERT INTO public.meal_products (name, price, discount_price, description, image_url, vendor_id, is_available, price_paise)
SELECT
  'Lunch ' || n,
  (150 + (n % 20) * 20)::numeric(10,2),
  CASE WHEN n % 4 = 0 THEN ((150 + (n % 20) * 20) * 0.85)::numeric(10,2) END,
  'Load-test lunch combo ' || n,
  'https://images.animeat.test/lunch/' || n || '.jpg',
  ('00000000-0000-0000-0000-00000000000' || lpad(((n % 8) + 1)::text, 1, '0'))::uuid,
  TRUE,
  (150 + (n % 20) * 20) * 100
FROM generate_series(1, 40) AS n
ON CONFLICT DO NOTHING;

-- ---------------------------------------------------------------------------
-- 6. Coupons (legacy columns; canonical columns auto-synced by triggers)
-- ---------------------------------------------------------------------------
INSERT INTO public.coupons (code, discount_type, discount_value, min_order_amount, max_discount_amount, is_active)
VALUES
  ('LT10',   'percent',  10.00, 200.00,  50.00,  TRUE),
  ('LTFLAT', 'flat',     50.00, 300.00,  NULL,   TRUE)
ON CONFLICT (code) DO NOTHING;

COMMIT;