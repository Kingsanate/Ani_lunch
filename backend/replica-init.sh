#!/bin/sh
# Streaming standby bootstrap (Phase 12). Replaces the container's entrypoint:
# waits for the primary, takes a pg_basebackup (with -R: standby.signal +
# primary_conninfo), then hands off to the official entrypoint which starts
# PostgreSQL in standby mode and applies WAL continuously.
set -e

echo "[replica] waiting for primary..."
until pg_isready -h postgres -p 5432 -U postgres -d animeat >/dev/null 2>&1; do
    sleep 2
done

echo "[replica] taking base backup from postgres..."
rm -rf /var/lib/postgresql/data
PGPASSWORD="${REPLICATION_PASSWORD:-replpassword}" \
    pg_basebackup -h postgres -p 5432 -U repl -D /var/lib/postgresql/data -X stream -R

echo "[replica] fixing permissions..."
chown -R postgres:postgres /var/lib/postgresql/data

echo "[replica] starting standby..."
exec /usr/local/bin/docker-entrypoint.sh postgres
