-- ============================================================================
-- 018_user_device_tokens.sql
-- Stores mobile push notification tokens (FCM / APNs) for customer, rider,
-- vendor, and admin devices.
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.user_device_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL,
    token TEXT NOT NULL,
    platform TEXT NOT NULL DEFAULT 'android', -- 'android', 'ios', 'web'
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, token)
);

CREATE INDEX IF NOT EXISTS idx_user_device_tokens_user ON public.user_device_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_user_device_tokens_token ON public.user_device_tokens(token);

ALTER TABLE public.user_device_tokens ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users manage own device tokens" ON public.user_device_tokens;
CREATE POLICY "Users manage own device tokens" ON public.user_device_tokens
    FOR ALL USING (auth.uid()::text = user_id);

DROP POLICY IF EXISTS "Service role manages all device tokens" ON public.user_device_tokens;
CREATE POLICY "Service role manages all device tokens" ON public.user_device_tokens
    FOR ALL USING (auth.role() = 'service_role');
