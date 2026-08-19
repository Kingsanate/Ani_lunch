# AniMeat Load Testing Runbook (Phase 10)

## 1. Prerequisites

| Tool | Version | Notes |
|------|---------|-------|
| Docker Desktop | 4.x | stack (PG 16, Redis 7, NATS 2.10, API) |
| k6 | >= 0.51 | `winget install k6` or `choco install k6` |
| jq (optional) | any | result parsing |

The Go API image is built from `backend/Dockerfile` by compose.

## 2. Bring up the stack

```bash
docker compose -f backend/docker-compose.yml up -d --build
```

Services (from `backend/docker-compose.yml`):
- `postgres` — animeat DB, auto-applies migrations `000`, `007`, `008`, `009`
- `redis` — cache (256MB LRU)
- `nats` — core + JetStream, monitoring on :8222
- `api` — Go API on :8080 (default dev JWT secret in compose)

Health: `curl http://localhost:8080/api/v1/catalog/items?category=1`

## 3. Seed test data

```bash
docker compose -f backend/docker-compose.yml exec -T postgres psql -U postgres -d animeat -f - < loadtest/seed.sql
```

Seeds (idempotent):
- 8 vendors (`00000000-…-0001..0008` — id == auth user id)
- 24 approved riders (`10000000-…-0001..0024`)
- 8 categories, 400 meat items, 40 lunch meal-products
- 2 coupons (`LT10`, `LTFLAT`)

## 4. Sanity run (single VU)

```bash
k6 run -e VUS=1 -e ITER=1 loadtest/browse.js
k6 run -e VUS=1 -e ITER=1 loadtest/cart_flow.js
k6 run -e VUS=1 -e ITER=1 loadtest/tracking.js
k6 run -e VUS=1 -e ITER=1 loadtest/vendor_ops.js
k6 run -e VUS=1 -e ITER=1 loadtest/rider_ops.js
```

## 5. Progressive tiers (the Phase 10 profile)

Run `loadtest/scenarios.js` — all traffic classes simultaneously with
real-world proportions (≈50% browse / 25% menu / 10% search / 8% checkout /
4% tracking / 1.5% vendor / 1.5% rider).

```bash
# Tier 1 — smoke + soak (also the CI gate)
k6 run -e TIER=1k  -e DURATION=5m  loadtest/scenarios.js

# Tier 2
k6 run -e TIER=5k  -e DURATION=5m  loadtest/scenarios.js

# Tier 3 — sprint goal: 10k concurrent
k6 run -e TIER=10k -e DURATION=10m loadtest/scenarios.js

# Tier 4 — stretch: 100k concurrent
# Single-node k6 can sustain ~30–60k VUs on a 32–64GB box (raises default
# OS limits); beyond that distribute with k6 cloud / k6-operator.
k6 run -e TIER=100k -e DURATION=15m --max-vus 100000 loadtest/scenarios.js
```

Pass criteria (thresholds enforced in `scenarios.js`):
- error rate < 1%
- reads (browse/menu/search): p95 < 250–300ms, p99 < 500–600ms
- writes (checkout/vendor/rider): p95 < 400ms, p99 < 800ms
- WS sessions (track): connect+join p95 < 1s, no slow-consumer evictions

Per-class isolation runs (debugging a specific class):

```bash
k6 run -e VUS=1000 loadtest/browse.js       # catalog read path
k6 run -e VUS=200 loadtest/cart_flow.js     # order creation + idempotency
k6 run -e VUS=100 loadtest/tracking.js      # WS hub + bridge
k6 run -e VUS=50 loadtest/vendor_ops.js     # vendor queue + transitions
k6 run -e VUS=50 loadtest/rider_ops.js      # rider GPS + accept + delivery
```

## 6. What to measure (server side)

While a tier runs, watch:

- `api`: container CPU/mem (`docker stats animeat_api`), `pprof` if enabled
- `postgres`: `pg_stat_activity` — active conns, wait events, lock waits;
  the app is PgBouncer-ready (`DATABASE_URL` can point at PgBouncer 6432)
- `redis`: `INFO stats` — hits/misses, evictions (256MB LRU budget)
- `nats`: `http://localhost:8222` — sub count per subject, slow consumers,
  JetStream storage (`orders.*` stream)

Expectation per sprint goal (10k tier): p95 < 400ms writes, p99 < 800ms,
error rate < 1% with default pool sizing. If p95 degrades, check PG query
plans on `orders` / `catalog` reads, NATS backlog, and Redis hit rate.

## 7. Notes & known gaps

- **Online payments**: `create-intent` calls Razorpay at request time. Local
  runs use COD only (`CREATE_INTENT=1` exercises the path only when Razorpay
  sandbox keys are set and reachable). Load-testing the webhook/ledger paths
  is out of scope for Phase 10.
- **Search**: the apps search client-side over the cached catalog; the API
  has no dedicated search endpoint yet (server-authoritative search is a
  Phase 12 topic). `search.js` models repeated filtered catalog reads.
- **Admin panel**: no admin traffic class (admin usage is human-scale).
- **Auth**: JWTs are minted in-script against the shared HMAC secret
  (`loadtest/lib/helpers.js`); `authz.ResolveActor` is DB-driven, so the
  seeded vendor/rider rows are what grant roles.
- **Idempotency**: every checkout uses a unique idempotency key — retries
  are safe and the dedup path is exercised naturally.
- **Fresh DB per tier** recommended: `docker compose exec postgres psql
  -c 'TRUNCATE orders RESTART IDENTITY CASCADE'` between tiers, then re-seed.