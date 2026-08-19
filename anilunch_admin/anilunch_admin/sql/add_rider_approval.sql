-- ============================================================
-- Anilunch Admin — Rider Approval Migration
-- Run this once in Supabase SQL Editor
-- ============================================================

-- 1. Add is_approved column to riders table
ALTER TABLE public.riders
  ADD COLUMN IF NOT EXISTS is_approved BOOLEAN NOT NULL DEFAULT FALSE;

-- 2. Allow admin (anon key) to read ALL riders
--    Drop existing restrictive policy first if it exists
DROP POLICY IF EXISTS "Rider can read own profile" ON public.riders;
DROP POLICY IF EXISTS "Admin can read all riders" ON public.riders;

CREATE POLICY "Rider can read own profile"
  ON public.riders FOR SELECT
  USING (auth.uid() = id OR auth.uid() IS NULL);

-- 3. Allow admin to update any rider (for approval)
DROP POLICY IF EXISTS "Admin can update all riders" ON public.riders;
CREATE POLICY "Admin can update all riders"
  ON public.riders FOR UPDATE
  USING (true);

-- 4. Allow admin to delete any rider
DROP POLICY IF EXISTS "Admin can delete riders" ON public.riders;
CREATE POLICY "Admin can delete riders"
  ON public.riders FOR DELETE
  USING (true);

-- 5. Make sure realtime is enabled
ALTER PUBLICATION supabase_realtime ADD TABLE public.riders;
