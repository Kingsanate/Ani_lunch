-- ============================================================
-- Anilunch Rider App — Supabase Setup Script
-- Run this in your Supabase SQL Editor
-- ============================================================

-- 1. Create the riders table
CREATE TABLE IF NOT EXISTS public.riders (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name        TEXT NOT NULL DEFAULT '',
  phone       TEXT NOT NULL DEFAULT '',
  email       TEXT NOT NULL DEFAULT '',
  is_online   BOOLEAN NOT NULL DEFAULT FALSE,
  latitude    DOUBLE PRECISION,
  longitude   DOUBLE PRECISION,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Add rider_id to the orders table (skip if it already exists)
ALTER TABLE public.orders
  ADD COLUMN IF NOT EXISTS rider_id UUID REFERENCES public.riders(id);

-- 3. Make sure 'ready_for_pickup' is a valid status
--    (Extend your existing status column if you use an ENUM)
-- If status is TEXT — nothing extra needed.
-- If you have an enum type called order_status, run:
-- ALTER TYPE order_status ADD VALUE IF NOT EXISTS 'ready_for_pickup';
-- ALTER TYPE order_status ADD VALUE IF NOT EXISTS 'accepted';
-- ALTER TYPE order_status ADD VALUE IF NOT EXISTS 'picked_up';

-- 4. Row Level Security — Riders
ALTER TABLE public.riders ENABLE ROW LEVEL SECURITY;

-- Riders can read and update only their own row
CREATE POLICY "Rider can read own profile"
  ON public.riders FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Rider can update own profile"
  ON public.riders FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Rider can insert own profile"
  ON public.riders FOR INSERT
  WITH CHECK (auth.uid() = id);

-- 5. Row Level Security — Orders (additive to existing policies)

-- Riders can read orders that are available (no rider) or assigned to them
CREATE POLICY "Rider can view available orders"
  ON public.orders FOR SELECT
  USING (
    status = 'ready_for_pickup' AND rider_id IS NULL
    OR rider_id = auth.uid()
  );

-- Riders can accept (update) an order
CREATE POLICY "Rider can accept order"
  ON public.orders FOR UPDATE
  USING (
    rider_id IS NULL  -- only if not yet taken
    OR rider_id = auth.uid()  -- or already theirs
  );

-- 6. Enable Realtime on orders table (run once)
ALTER PUBLICATION supabase_realtime ADD TABLE public.orders;
ALTER PUBLICATION supabase_realtime ADD TABLE public.riders;
