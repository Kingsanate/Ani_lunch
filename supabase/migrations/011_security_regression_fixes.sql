-- ============================================================================
-- 011_security_regression_fixes.sql
-- Fixes SEC-01/SEC-02 regression introduced by 20260727000000_vendor_orders_policy.sql
-- (re-created wide-open 'authenticated' policies on orders) and locks down the
-- SECURITY DEFINER accept_order() function (SEC-07 residual vector).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. DROP the wide-open policies re-created by 20260727000000_vendor_orders_policy.sql
--    These allowed ANY authenticated user to SELECT/UPDATE ALL orders.
--    The correctly scoped alternatives from 007_secure_rls_policies.sql remain:
--      "Vendors read own store orders"   (vendor_id = auth.uid() OR vendor row match)
--      "Vendors update own store orders" (same scoping)
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Vendors read orders" ON public.orders;
DROP POLICY IF EXISTS "Vendors update orders" ON public.orders;

-- ----------------------------------------------------------------------------
-- 2. Lock down the SECURITY DEFINER accept_order() functions.
--    PG grants EXECUTE on functions to PUBLIC by default; combined with the
--    missing auth check inside the function body, ANY caller could claim ANY
--    order. Revoke from PUBLIC (covers anon + authenticated) and re-grant
--    explicitly to service_role only (used by the Go backend / edge function,
--    which now enforce JWT + server-derived rider identity).
-- ----------------------------------------------------------------------------
REVOKE EXECUTE ON FUNCTION public.accept_order(TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.accept_order(TEXT, TEXT) TO service_role;

-- Drop the legacy UUID-signature variant if it still exists (from 001) and lock it down too
DROP FUNCTION IF EXISTS public.accept_order(UUID, UUID);

-- ----------------------------------------------------------------------------
-- 3. Sanity: keep the scoped policies from 007 in place.
-- ----------------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'orders' AND policyname = 'Vendors read own store orders') THEN
    RAISE EXCEPTION 'Scoped vendor read policy missing - 007_secure_rls_policies.sql must be applied';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'orders' AND policyname = 'Vendors update own store orders') THEN
    RAISE EXCEPTION 'Scoped vendor update policy missing - 007_secure_rls_policies.sql must be applied';
  END IF;
END $$;
