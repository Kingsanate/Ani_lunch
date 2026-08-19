-- ============================================================
-- FIX: Rider Order Visibility — RLS Policy Update
-- Run this in your Supabase SQL Editor (Dashboard > SQL Editor)
-- ============================================================

-- DROP the old restrictive policy that only allowed 'ready_for_pickup'
DROP POLICY IF EXISTS "Rider can view available orders" ON public.orders;

-- CREATE a new policy that allows riders to see:
--   1. Unassigned 'pending' orders (newly placed by users)
--   2. Unassigned 'ready_for_pickup' orders
--   3. Orders already assigned to them (any status)
CREATE POLICY "Rider can view available orders"
  ON public.orders FOR SELECT
  USING (
    (rider_id IS NULL AND status IN ('pending', 'ready_for_pickup'))
    OR rider_id = auth.uid()
  );

-- Also fix the UPDATE policy so riders can accept pending orders
DROP POLICY IF EXISTS "Rider can accept order" ON public.orders;

CREATE POLICY "Rider can accept order"
  ON public.orders FOR UPDATE
  USING (
    rider_id IS NULL  -- can claim any unassigned order
    OR rider_id = auth.uid()  -- can update their own orders
  );

-- Verify realtime is enabled on orders table
-- (run only if not already done)
ALTER PUBLICATION supabase_realtime ADD TABLE public.orders;
