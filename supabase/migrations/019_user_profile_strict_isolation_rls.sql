-- ============================================================================
-- 019_user_profile_strict_isolation_rls.sql
-- Strict Row-Level Security for public.users profile table
-- Guarantees complete data privacy across individual user accounts
-- ============================================================================

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Drop any previous or overly permissive policies
DROP POLICY IF EXISTS "Public read users" ON public.users;
DROP POLICY IF EXISTS "Allow authenticated full access to users" ON public.users;
DROP POLICY IF EXISTS "Users can read own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.users;
DROP POLICY IF EXISTS "Service role full access on users" ON public.users;

-- 1. CUSTOMER: Read strictly own profile
CREATE POLICY "Users can read own profile" ON public.users
    FOR SELECT USING (
        auth.uid()::text = user_id 
        OR auth.uid() = id
    );

-- 2. CUSTOMER: Update strictly own profile
CREATE POLICY "Users can update own profile" ON public.users
    FOR UPDATE USING (
        auth.uid()::text = user_id 
        OR auth.uid() = id
    )
    WITH CHECK (
        auth.uid()::text = user_id 
        OR auth.uid() = id
    );

-- 3. CUSTOMER: Insert strictly own profile upon sign up
CREATE POLICY "Users can insert own profile" ON public.users
    FOR INSERT WITH CHECK (
        auth.uid()::text = user_id 
        OR auth.uid() = id
    );

-- 4. SERVICE ROLE / ADMIN: Backend access
CREATE POLICY "Service role full access on users" ON public.users
    FOR ALL USING (auth.role() = 'service_role');
