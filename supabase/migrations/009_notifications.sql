-- ============================================================================
-- 009_notifications.sql
-- Notification inbox table written by the durable NATS JetStream consumer.
-- source_event_id is UNIQUE so at-least-once event replays never duplicate.
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL DEFAULT '',
    notification_type TEXT NOT NULL DEFAULT 'order',
    entity_type TEXT DEFAULT '',
    entity_id TEXT DEFAULT '',
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    source_event_id TEXT UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user ON public.notifications(user_id, is_read, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON public.notifications(user_id) WHERE is_read = FALSE;

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users read own notifications" ON public.notifications;
CREATE POLICY "Users read own notifications" ON public.notifications
    FOR SELECT USING (auth.uid()::text = user_id);

DROP POLICY IF EXISTS "Service role notifications" ON public.notifications;
CREATE POLICY "Service role notifications" ON public.notifications
    FOR ALL USING (auth.role() = 'service_role');