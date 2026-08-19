-- Replication role for the streaming standby (Phase 12).
-- Mounted into the primary's initdb dir so it exists before pg_basebackup.
-- Idempotent: safe to re-run.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'repl') THEN
        CREATE ROLE repl REPLICATION LOGIN PASSWORD 'replpassword';
    END IF;
END
$$;
