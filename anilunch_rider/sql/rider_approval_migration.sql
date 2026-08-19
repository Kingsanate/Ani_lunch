-- ============================================================
-- Anilunch Rider Approval Workflow — Migration Script
-- Run this in your Supabase SQL Editor (Dashboard > SQL Editor)
-- ============================================================

-- 1. Add is_approved column (defaults FALSE so new riders need admin approval)
ALTER TABLE public.riders
  ADD COLUMN IF NOT EXISTS is_approved BOOLEAN NOT NULL DEFAULT FALSE;

-- 2. Add approval_status for richer state ('pending' | 'approved' | 'rejected')
ALTER TABLE public.riders
  ADD COLUMN IF NOT EXISTS approval_status TEXT NOT NULL DEFAULT 'pending';

-- 3. Add rejection_reason for optional admin message
ALTER TABLE public.riders
  ADD COLUMN IF NOT EXISTS rejection_reason TEXT;

-- 4. Backfill any existing riders so they stay approved
--    (existing riders were working before — don't break them)
UPDATE public.riders
  SET is_approved = TRUE, approval_status = 'approved'
  WHERE is_approved = FALSE;

-- 5. RLS: Allow ALL authenticated users to read the riders table
--    (needed so the admin web app using the anon key can list all riders)
--    The existing "Rider can read own profile" policy is preserved.
DROP POLICY IF EXISTS "Admin can read all riders" ON public.riders;
CREATE POLICY "Admin can read all riders"
  ON public.riders FOR SELECT
  USING (true);  -- any authenticated session can read rider rows

-- 6. RLS: Allow any authenticated user to UPDATE riders
--    (admin approves/rejects by setting is_approved / approval_status)
--    The rider-specific update policy remains for self-updates.
DROP POLICY IF EXISTS "Admin can update any rider" ON public.riders;
CREATE POLICY "Admin can update any rider"
  ON public.riders FOR UPDATE
  USING (true);

-- 7. RLS: Allow admin to DELETE riders (for rejection/removal)
DROP POLICY IF EXISTS "Admin can delete rider" ON public.riders;
CREATE POLICY "Admin can delete rider"
  ON public.riders FOR DELETE
  USING (true);

-- 8. Make sure realtime is enabled on riders table
ALTER PUBLICATION supabase_realtime ADD TABLE public.riders;

-- Done! Verify with:
-- SELECT id, name, is_approved, approval_status FROM public.riders;
