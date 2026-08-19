# Phase 12 — PostgreSQL Read Replicas

**Goal:** scale read load by serving stale-tolerant reads from a streaming
standby, with measured replication lag and a strict routing policy that
keeps money/state paths on the primary.

---

## 1. Routing policy (the contract)

`database.Postgres` now owns two pools:

- **`Pool` (primary)** — every write and every money/state read:
  orders (create/get/transition/cancel, idempotency), payments, admin,
  riders `AcceptOrder`/`GetOrder`, profile reads that follow a write
  (`GetProfile` on users/vendors/riders), all `Exec`/`Begin` calls.
- **`Reader()` (replica when configured)** — stale-tolerant reads only:
  - `catalog` — items/menus/deals (Redis-cached first; PG fallback)
  - `users.ListNotifications`
  - `vendors.ListOrders`, `vendors.GetStats`
  - `riders.ListAvailableOrders`, `riders.ListAssignedOrders`

**Why these are safe:** every decision the UI can take from a stale list is
re-validated on the primary by a guarded, atomic write:
- rider accept → `UPDATE ... WHERE status IN ('ready_for_pickup','assigned')
  AND rider_id IS NULL` (double-assignment impossible)
- vendor transition → `WHERE id = $1 AND status = $3` (double-advance
  impossible)
- order reads after create (the customer's own confirmation) stay on the
  primary — no read-your-own-write staleness.

**Write-then-read chains** (e.g. `SetAvailability` → `GetProfile`) are kept
on the primary so the app immediately sees its own update.

**Fallback:** when `READ_DATABASE_URL` is unset, `Reader()` returns the
primary pool — single-node deployments behave exactly as before (dev
compose unchanged).

## 2. Topology

```
api1/2/3 ── DATABASE_URL ──────► PgBouncer (rw, :6432) ──► postgres (primary)
api1/2/3 ── READ_DATABASE_URL ─► PgBouncer (ro, :6432) ──► postgres_replica (standby)
```

- Standby bootstraps via `pg_basebackup -R` (`backend/replica-init.sh`) —
  `-R` writes `standby.signal` + `primary_conninfo`, then continuous WAL
  apply (`wal_level=replica`, the PG16 default; `repl` role created by
  `backend/pg-init-replication.sql`).
- Two PgBouncers (transaction mode) keep per-pool connection counts small.
- Replica data lives in its own `repldata` volume.

## 3. Lag monitoring

Every API instance with a read pool runs `StartReplicaLagMonitor` (15s
ticker) and exposes **`animeat_replica_lag_seconds`**:

```sql
SELECT COALESCE(EXTRACT(EPOCH FROM (NOW() - pg_last_xact_replay_timestamp())), 0);
```

- Warnings in logs above 10 s.
- Prometheus alert `AnimeatReplicaLagHigh` (>30 s for 2 m) in
  `backend/prometheus/autoscale.rules.yml`.
- Unknown state is reported as `-1` so false zeros never mask a broken
  replica.

## 4. Runbook

```bash
# Full topology: primary + standby + rw/ro pools + 3 API replicas + Caddy
docker compose -f backend/docker-compose.lb.yml up -d --build

# Verify replication is streaming
docker compose -f backend/docker-compose.lb.yml exec postgres_replica \
  psql -U postgres -d animeat -c "SELECT pg_is_in_recovery(), pg_last_wal_receive_lsn() IS NOT NULL AS receiving;"

# Verify lag metric from any API replica
curl -s localhost:8080/metrics | grep animeat_replica_lag_seconds

# Failover drill (Phase 13 will formalize): promote standby manually
docker compose -f backend/docker-compose.lb.yml exec postgres_replica \
  psql -U postgres -c "SELECT pg_promote();"
# NOTE: with this topology the primary keeps serving writes until DNS/env
# is repointed — promotion here is a drill only.

# Load-test the read path against the replica pool
k6 run -e VUS=2000 -e DURATION=5m -e TIER=1k loadtest/scenarios.js
# then compare animeat_replica_lag_seconds and read-path p95 vs Phase 10
```

## 5. Verification checklist (Phase 12 gate)

- [ ] `go build` / `go vet` / `go test ./...` green (new `database`
      pool-routing tests + `config` READ_DATABASE_URL tests)
- [ ] Single-node: unset `READ_DATABASE_URL` → `Reader()` == primary,
      dev compose behaviour unchanged
- [ ] Standby receives WAL (`pg_is_in_recovery()` = t, receiving = t)
- [ ] Read paths hit the replica (check PgBouncer-ro `SHOW POOLS`), write
      paths hit the primary
- [ ] `animeat_replica_lag_seconds` present, < 1 s under 1k tier load
- [ ] Stale-listing safety: accept/transition races still yield exactly one
      winner (guarded UPDATE on primary)
- [ ] `promtool check rules` on autoscale.rules.yml

## 6. Notes & limits

- Read/write split is **application-level** (service chooses `Reader()`),
  not a transparent proxy — deliberate: only known-stale-tolerant queries
  are routed, keeping correctness reviewable.
- The replica is a passive standby; failover (promotion + repoint) is
  manual and formalized in Phase 13 (HA + DR runbook).
- PgBouncer-ro uses the same credentials as rw; production should use
  separate read-only roles (documented here as a deployment setting).