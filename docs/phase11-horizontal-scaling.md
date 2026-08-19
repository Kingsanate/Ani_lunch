# Phase 11 — Horizontal API Scaling

**Goal:** N stateless Go API replicas behind a load balancer, with no sticky
sessions, no state loss, and autoscale driven by CPU + request rate +
latency + queue depth (never CPU alone).

---

## 1. Statelessness audit (verified against the code)

| Concern | Where | Verdict |
|---|---|---|
| Package-level mutable state | `grep ^var` — only promauto metric vars (thread-safe), read-only `validTransitions` map, error sentinels | ✅ none |
| HTTP sessions / cookies | no session store anywhere | ✅ none |
| Files/temp state on disk | no `os.WriteFile`/tempdir usage in service code | ✅ none |
| In-memory caches in services | catalog service caches in Redis only; no `sync.Map` in service structs | ✅ none |
| Rate limiting | `middleware/rate_limit.go` — Redis-backed (`ratelimit:` keys, fixed window); in-memory fallback **only** when Redis is unreachable | ✅ shared across replicas when Redis is up; fallback is single-instance only (acceptable degradation) |
| Idempotency | order create/transition guarded by DB (`idempotency_key`, guarded `UPDATE ... AND status = $3`) | ✅ cross-instance safe |
| Realtime hub | `internal/realtime/hub.go` — WS registry is per-instance by design; every instance runs a `orders.>` NATS bridge subscription and fans events out to its **own** local clients | ✅ REST is stateless; WS fan-out works across replicas because each instance consumes the shared NATS stream |
| JetStream consumers | `events/consumer.go` — 3 durable consumers (`notification-writer-group`, `kitchen-dispatch-group`, `rider-broadcast-group`) with shared durable names | ✅ multiple sessions round-robin deliveries against the shared durable position — replicas split the load, no double-processing |
| Graceful shutdown | `main.go` — 10s `server.Shutdown`, signal handling | ✅ rolling restarts drop no in-flight writes |
| Health endpoints | `/health/live` + `/health/ready` (DB ping) | ✅ LB readies + Prometheus |
| Metrics | `/metrics` (promhttp) per instance | ✅ autoscale signals |

**Conclusion:** the API is horizontally scalable as-is. The only caveat is
operational: Redis and NATS must be reachable from every replica (rate
limiter correctness + realtime fan-out), and `SUPABASE_JWT_SECRET` must be
identical on every replica (JWT validation is deterministic HMAC).

---

## 2. Topology

```
Flutter apps (API_BASE_URL = http://lb:8080)
        │
        ▼
   Caddy :8080  (health-checked round_robin, WS passthrough)
        │
   ┌────┼────────────┐
   ▼    ▼            ▼
 api1  api2         api3        (stateless, N replicas)
   │    │            │
   └────┼────────────┼────────► PgBouncer :6432 ──► PostgreSQL
        │            │────────► Redis :6379
        └────────────┘────────► NATS :4222 (core + JetStream)
```

- **LB:** `backend/docker-compose.lb.yml` + `backend/Caddyfile` (3 explicit
  replicas; DNS round-robin mode documented for `--scale api=N`).
- **PgBouncer:** transaction pooling — every replica shares one 40-conn pool
  into PG (max 200 server connections), instead of N pools × pool size.
- **WS:** `/api/v1/ws` upgrades pass through Caddy untouched; a customer's
  socket lands on whichever replica serves the upgrade, and order/rider
  events reach it via that replica's NATS bridge subscription.

## 3. Autoscale signals (`backend/prometheus/autoscale.rules.yml`)

Scale-OUT when **≥2 of 4** are true for 5 min:
1. CPU per instance > 70%
2. Request rate per instance > 2000 rps (5m avg)
3. p95 latency > 300 ms (5m avg)
4. NATS ORDERS stream backlog > 1000 pending

Scale-IN only after 15 min with all signals low (<30% CPU). Alerts:
`AnimeatAPIScaleOut`, `AnimeatReplicaDown`, `AnimeatDBPoolExhausted`,
`AnimeatNATSSlowConsumer`.

## 4. Runbook

```bash
# Build + start 3 replicas behind Caddy (PgBouncer in front of PG)
docker compose -f backend/docker-compose.lb.yml up -d --build

# Verify LB routes round-robin across replicas
for i in 1 2 3 4 5 6; do curl -s http://localhost:8080/api/v1/ ; echo; done

# Health check endpoint (used by Caddy)
curl -s http://localhost:8080/health/ready

# Per-instance metrics (scrape directly, not via LB)
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' animeat_api_1

# Scale out (add replicas in compose + Caddyfile upstreams), or
# DNS mode: single `api` service + --scale
docker compose -f backend/docker-compose.lb.yml up -d --scale api1=1 --scale api2=1 --scale api3=2

# Kill a replica — Caddy health check pulls it within ~15s, no user impact
docker kill animeat_api_2

# Load test against the LB (instead of localhost:8080)
k6 run -e BASE_URL=http://localhost:8080 -e TIER=1k loadtest/scenarios.js
```

## 5. Verification checklist (Phase 11 gate)

- [ ] `go build` / `go vet` / `go test ./...` green (unchanged code path)
- [ ] Caddyfile + compose parse (`docker compose config`, `caddy validate`)
- [ ] 3 replicas serve REST round-robin; killing one triggers health-based
      failover within ~15s with zero 5xx from the LB
- [ ] WS tracking across instances: customer socket on api1 receives events
      produced by a vendor transition served by api2 (NATS bridge fan-out)
- [ ] Rate limits hold per-key across replicas (Redis-backed)
- [ ] Idempotent order creation still dedupes when retried via different
      replicas
- [ ] Prometheus scrape of all 3 `/metrics` endpoints; autoscale rules
      evaluate (`promtool check rules`)

## 6. Deferred (tracked for later phases)

- **Phase 12:** PG read replica when measured read load requires (PgBouncer
  already in place; wire replica via `DATABASE_URL` read pool + application
  read/write split).
- **Phase 13:** HA — DB backup schedule (7d/4w/3m), restore drill, DR
  runbook, no single point of failure (LB, NATS cluster, PgBouncer pair).
- **Phase 14:** 100k+ concurrent stress against this topology.