-- ============================================================================
-- 021_native_auth_passwords.sql
-- Add native password authentication columns to users table
-- ============================================================================

ALTER TABLE public.users ADD COLUMN IF NOT EXISTS password_hash TEXT DEFAULT '';
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'customer';
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT FALSE;
