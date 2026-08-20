-- ============================================================================
-- 020_user_profile_columns_alignment.sql
-- Ensure both canonical and legacy column names are present on public.users
-- ============================================================================

ALTER TABLE public.users ADD COLUMN IF NOT EXISTS avatar_url TEXT DEFAULT '';
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS profile_image_url TEXT DEFAULT '';
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS phone TEXT DEFAULT '';
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS phone_number TEXT DEFAULT '';
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS pin_code TEXT DEFAULT '';
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS address TEXT DEFAULT '';
