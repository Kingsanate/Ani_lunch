# Phase 13 — HA/DR Runbook

**Goal:** no single point of failure in the production topology, automated
backups with a schedule that meets RPO/RTO, and a practiced restore + failover
drill so a region or instance loss stays invisible to users.

---

## 1. Recovery objectives

| Objective | Target | Meaning |
|---|---|---|
| RPO | ≤ 15 min | at most 15 minutes of order data at risk (WAL archiving + PITR) |
| RTO (API) | ≤ 15 s | lost API replica pulled from LB with zero 5xx (health checks) |
| RTO (DB failover) | ≤ 5 min | standby promoted and replicas repointed, from runbook |
| RTO (full region) | ≤ 60 min | rebuild stack from latest backup + replayed WAL in a second region |

## 2. Topology (no single points of failure)

```
Flutter apps ──► CDN/WAF ──► LB (2×, active/standby or DNS-failover)
                                │
          ┌─────────────────────┼─────────────────────┐
          ▼                     ▼                     ▼
       api1                    api2                  api3     (stateless, N≥2)
          │                     │                     │
          ├────► PgBouncer rw (pair) ──► PG primary ──► PG standby (streaming, WAL archive)
          ├────► PgBouncer ro (pair) ──► PG replica (Phase 12, read-only)
          ├────► Redis (3-node cluster / managed)   ── denylist + rate limit + catalog cache
          └────► NATS (3-node cluster + JetStream)  ── order event fan-out / durable consumers
media: Cloudflare R2 (11×9s durability, CDN-served)  ── no local media storage
```

SPOF audit: every store is replicated or managed; the API layer is stateless
(Phase 11) so instances are interchangeable. Env inputs that must be
identical everywhere: `SUPABASE_JWT_SECRET`, `R2_*`, `RAZORPAY_*`.

## 3. Backups

### 3.1 PostgreSQL

- **Base backups**: nightly `pg_dump -Fc` (or `pg_basebackup` for standby
  bootstrap), retained **7 daily / 4 weekly / 3 monthly** (cron
  `backend/backup-schedule.cron`, offloaded to R2 `backups/`).
- **WAL archiving**: `archive_command` copies WAL segments to R2
  (`backups/wal/`), enabling point-in-time recovery up to the last archived
  segment (RPO ≈ 15 min).
- **Verify**: weekly `pg_restore --list` on the latest archive + quarterly
  full restore drill into a throwaway instance.

### 3.2 Redis / NATS

- Redis is a cache + short-TTL denylist/rate-limit store — **no backups
  needed**; a cold start re-primes from PG and R2.
- NATS JetStream streams (`orders.*`) are durable; on total NATS loss the
  consumers re-sync from PG (streams are a fan-out optimization, not the
  source of truth).

## 4. Failover procedures

### 4.1 API replica loss

```bash
# LB health check pulls the dead instance within ~15s; users keep talking
# to the survivors. Nothing else to do — but alert on:
#   AnimeatReplicaDown
docker kill animeat_api_2        # simulate
docker compose up -d --scale api2=1   # replace
```

### 4.2 PostgreSQL primary failure (promote standby)

```bash
# 1. On the standby: promote (no split-brain — fence old primary first)
ssh standby 'docker exec postgres_standby pg_ctl promote'   # or touch standby.signal away

# 2. Verify it accepts writes
ssh standby 'psql -U postgres -d animeat -c "SELECT 1"'

# 3. Repoint PgBouncer rw pool at the promoted node (DNS or config), restart
docker exec pgbouncer_rw bash -c 'echo "reload;" | psql -p 6432'

# 4. Rebuild the failed old primary as the new standby (pg_basebackup -R),
#    re-archive WAL, confirm replication lag via animeat_replica_lag_seconds
```

RTO ≈ 5 min. Order data is safe to the last archived WAL (RPO ≤ 15 min).

### 4.3 Redis / NATS outage

- **Redis down**: API degrades to in-memory rate limiting (per-instance,
  acceptable) and the denylist fails open (dev policy). Catalog falls back
  to PG. Restart the cluster; nothing needs replay.
- **NATS down**: order lifecycle keeps working (DB is authoritative); WS
  push pauses. Restart cluster — durable consumers resume from their saved
  position (no double-processing, Phase 11).

### 4.4 Full region loss (DR)

1. Boot stack in the DR region from Terraform/Compose (fixed version tags).
2. Restore latest base + replay WAL: `pg_restore` latest archive, then
   `pg_archivecleanup`/PITR to the loss point.
3. Point DNS/CDN + app `API_BASE_URL` at the DR LB.
4. R2 media is region-independent (durable + CDN) — no media restore needed.

RTO ≤ 60 min, RPO ≤ 15 min.

## 5. Restore drill (Phase 13 gate)

Run quarterly, or after any schema/migration change:

```bash
# 1. Spin a throwaway PG container
docker run -d --name dr-drill postgres:16

# 2. Restore latest base
docker exec -i dr-drill pg_restore -U postgres -d postgres < backup/latest.dump

# 3. Replay WAL to a chosen timestamp (PITR)
#    (restore_command from R2; stop at recovery_target_time)

# 4. Verify a known-order invariant exists
docker exec dr-drill psql -U postgres -d postgres -c \
  "SELECT count(*) FROM orders WHERE total_amount_paise >= 0;"

# 5. Promote, run a smoke checkout, then drop the container
```

Checklist:

- [ ] Backups: 7d/4w/3m retention observed; WAL archiving streaming
- [ ] Restore drill completes with a passing smoke check
- [ ] Standby promotion drill ≤ 5 min
- [ ] API replica kill → zero 5xx through LB (Phase 11 §5)
- [ ] WS survives replica replacement (NATS fan-out, Phase 11 §5)
- [ ] Redis/NATS cold start recovers without data loss
- [ ] 3-node NATS + Redis reachable from every API replica (no split brain)

## 6. Deferred

- Managed-service equivalents (AWS RDS Multi-AZ / ElastiCache / Terraform
  IaC for the whole stack) — drop-in once the compose stack is validated.
- Geographic redundancy for NATS/Redis (multi-region topologies).
- 100k-concurrent stress against this HA topology (Phase 14).