-- ============================================================================
-- integrity-check.sql — AniLunch Phase 1 read-only integrity checks
-- Run against a STAGING or live database before applying any fix migration:
--   psql "$DATABASE_URL" -f supabase/integrity-check.sql
-- Everything here is SELECT-only. No writes, no locks (no FOR UPDATE).
-- Any row returned in a "CHECKS:" section is a defect to fix first.
-- ============================================================================

\echo '=== 1. Orphaned order.user_id (TEXT) not present in users.id (UUID) ==='
SELECT count(*) AS orphan_user_ids
FROM public.orders o
LEFT JOIN public.users u ON u.id = o.user_id::uuid
WHERE o.user_id IS NOT NULL AND o.user_id <> '' AND u.id IS NULL;

\echo '=== 2. Orphaned order.rider_id (TEXT) not present in riders.id (UUID) ==='
SELECT count(*) AS orphan_rider_ids
FROM public.orders o
LEFT JOIN public.riders r ON r.id = o.rider_id::uuid
WHERE o.rider_id IS NOT NULL AND o.rider_id <> '' AND r.id IS NULL;

\echo '=== 3. orders.id values that are NOT valid UUIDs (blocks TEXT->UUID) ==='
SELECT count(*) AS non_uuid_order_ids
FROM public.orders
WHERE id !~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$';

\echo '=== 4. Sample of orders.id shapes (first 20 distinct) ==='
SELECT DISTINCT left(id, 8) || '...' AS id_prefix
FROM public.orders LIMIT 20;

\echo '=== 5. Duplicate idempotency keys (would block UNIQUE index) ==='
SELECT user_id, idempotency_key, count(*) AS dupes
FROM public.orders
WHERE idempotency_key IS NOT NULL
GROUP BY user_id, idempotency_key
HAVING count(*) > 1;

\echo '=== 6. Negative / implausible money in canonical paise columns ==='
SELECT count(*) AS bad_money_rows
FROM public.orders
WHERE subtotal_paise < 0 OR delivery_fee_paise < 0 OR total_amount_paise < 0;

\echo '=== 7. Money rows where canonical paise disagrees with legacy rupees (x100) ==='
SELECT count(*) AS money_mismatch_rows
FROM public.orders
WHERE subtotal_paise <> 0
  AND subtotal_paise <> round(subtotal * 100);

\echo '=== 8. items.id type (expect TEXT per 000; UUID per 010 — one is wrong) ==='
SELECT data_type
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'items' AND column_name = 'id';

\echo '=== 9. menus/daily_deals/coupons PK types (expect BIGINT per 000, UUID per 010) ==='
SELECT table_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND column_name = 'id'
  AND table_name IN ('menus', 'daily_deals', 'coupons', 'orders', 'riders')
ORDER BY table_name;

\echo '=== 10. orders.uuid_id uniqueness (FK targets must be unique) ==='
SELECT count(*) AS uuid_id_dupes
FROM (
    SELECT uuid_id FROM public.orders WHERE uuid_id IS NOT NULL
    GROUP BY uuid_id HAVING count(*) > 1
) d;

\echo '=== 11. users.role / daily_deals.valid_from presence (010-016 dependencies) ==='
SELECT
  EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='users' AND column_name='role')        AS users_role_exists,
  EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='daily_deals' AND column_name='valid_from') AS daily_deals_valid_from_exists,
  EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='orders' AND column_name='discount_type')   AS orders_discount_type_exists;

\echo '=== 12. RLS enabled per table ==='
SELECT relname AS table_name, relrowsecurity AS rls_enabled
FROM pg_class
WHERE relnamespace = 'public'::regnamespace
  AND relkind = 'r'
  AND relname IN ('orders', 'riders', 'users', 'items', 'menus', 'daily_deals', 'coupons', 'vendors', 'pages')
ORDER BY relname;

\echo '=== 13. Seed sanity: items priced above 10,000 rupees (paise-in-rupees) ==='
SELECT id, item_title, item_price
FROM public.items
WHERE item_price >= 10000
LIMIT 20;

\echo '=== DONE. All checks are read-only. ==='