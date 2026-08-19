-- ═══════════════════════════════════════════════════════════════════
-- MIGRATION 006 - Final verified version
-- Orders table columns confirmed from OrderModel:
--   id (text), status (text), rider_id (text), order_time, etc.
--   NO updated_at column exists.
-- ═══════════════════════════════════════════════════════════════════

-- ── STEP 1: Drop all old conflicting policies ──────────────────────
DROP POLICY IF EXISTS "Riders read available orders" ON orders;
DROP POLICY IF EXISTS "Riders accept orders" ON orders;
DROP POLICY IF EXISTS "Riders read own orders" ON orders;
DROP POLICY IF EXISTS "Riders update own order status" ON orders;
DROP POLICY IF EXISTS "Riders see ready_for_pickup orders" ON orders;
DROP POLICY IF EXISTS "Riders read own orders v2" ON orders;
DROP POLICY IF EXISTS "Riders accept ready_for_pickup orders" ON orders;
DROP POLICY IF EXISTS "Riders update own order status v2" ON orders;

-- ── STEP 2: Drop old function (both possible signatures) ───────────
DROP FUNCTION IF EXISTS accept_order(UUID, UUID);
DROP FUNCTION IF EXISTS accept_order(TEXT, TEXT);

-- ── STEP 3: Create new RLS policies ───────────────────────────────

-- All riders can see orders that are ready for pickup (no rider yet)
CREATE POLICY "Riders see ready_for_pickup orders" ON orders
  FOR SELECT USING (
    status = 'ready_for_pickup'
    AND (rider_id IS NULL OR rider_id = '')
  );

-- Riders can see their own orders
CREATE POLICY "Riders read own orders v2" ON orders
  FOR SELECT USING (
    rider_id = auth.uid()::text
  );

-- Riders can accept an unassigned ready_for_pickup order
CREATE POLICY "Riders accept ready_for_pickup orders" ON orders
  FOR UPDATE USING (
    status IN ('ready_for_pickup', 'assigned')
    AND (rider_id IS NULL OR rider_id = '' OR rider_id = auth.uid()::text)
  )
  WITH CHECK (
    rider_id = auth.uid()::text
  );

-- Riders can update status of their own orders (e.g. mark delivered)
CREATE POLICY "Riders update own order status v2" ON orders
  FOR UPDATE USING (
    rider_id = auth.uid()::text
  )
  WITH CHECK (
    rider_id = auth.uid()::text
  );

-- ── STEP 4: Create accept_order function ──────────────────────────
-- Uses TEXT params (orders.id is text, not uuid).
-- NO updated_at — that column does not exist on this table.
-- Atomic: only one rider wins the race condition.
CREATE FUNCTION accept_order(p_order_id TEXT, p_rider_id TEXT)
RETURNS JSONB
LANGUAGE sql
SECURITY DEFINER
AS $$
  UPDATE orders
  SET
    rider_id = p_rider_id,
    status   = 'accepted'
  WHERE id = p_order_id
    AND status IN ('ready_for_pickup', 'assigned')
    AND (rider_id IS NULL OR rider_id = '')
  RETURNING row_to_json(orders.*)::JSONB;
$$;
