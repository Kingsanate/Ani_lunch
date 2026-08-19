# Phase 10 — Load Testing, Concurrency & Failover Validation

**Goal:** move every Flutter app from direct Supabase SDK calls onto the
stateless Go API, then prove the system holds under concurrent load with
horizontal failover. This doc records what was delivered and the validation
gate (runbook: `loadtest/README.md`).

---

## 1. Deliverables

### 1.1 Applications migrated to the Go API (M1–M5)

All four Flutter apps now call the Go backend through one shared package
(`packages/anilunch_core`), keeping Supabase only for Auth and a handful of
legacy tables:

| App | Supabase SDK calls replaced with | Notes |
|---|---|---|
| customer (`anilunch/anilunch`) | menu/order/payment services, providers, sync engine | catalog cached in Redis via Go; local-first flow preserved |
| rider (`anilunch_rider`) | api/auth/order services, state provider, sync engine | `riders.me()`, accept/transition via Go, WS join |
| vendor (`anilunch_vendor`) | `supabase_service.dart` rewritten | profile/stats/orders via Go, WS `vendor:{id}` + 30s poll fallback |
| admin (`anilunch_admin/anilunch_admin`) | all CRUD wrappers in `services/api_client.dart` | `AdminApi.orders()/users()`, WS `admin` channel, R2-aware item images |

Auth (Decision E): apps keep Supabase Auth → `POST /api/v1/auth/exchange`
→ Go-issued short-lived access token (15 min) + rotated refresh (7-day);
Go `RequireAuth` now also rejects **revoked** access tokens (Redis denylist,
`internal/auth/denylist.go`), and logout revokes the current jti.

### 1.2 Realtime fan-out

- Scoped WS channels: `order:{id}`, `rider:{id}`, `vendor:{id}`,
  `riders.available`, plus unscoped `admin` (order lifecycle events, gated
  on `users.is_admin`).
- One shared NATS subscription per instance fans events out to that
  instance's local sockets (`internal/realtime`), so WS works across N API
  replicas without sticky sessions (Phase 11).

### 1.3 Media pipeline (R2 presigned uploads)

`POST /api/v1/media/upload-url` is now mounted (protected + rate-limited).
Images/videos never pass through the API — clients PUT directly to Cloudflare
R2 with a 5-minute presigned URL (`internal/modules/media`, `storage/r2.go`).
Unconfigured in dev → 503 `STORAGE_UNCONFIGURED`.

### 1.4 Load test suite (`loadtest/`)

- Scenarios: `scenarios.js` (mixed real-world proportions ≈50% browse /
  25% menu / 10% search / 8% checkout / 4% tracking / 1.5% vendor /
  1.5% rider) plus per-class scripts `browse.js`, `cart_flow.js`,
  `tracking.js`, `vendor_ops.js`, `rider_ops.js`, `search.js`.
- Tier profile: **1k / 5k / 10k / 100k** concurrent (1k = CI gate).
- Idempotent seed: 8 vendors, 24 riders, 8 categories, 400 items,
  40 meal-products, 2 coupons (`loadtest/seed.sql`).
- Every checkout uses a unique idempotency key, so retries/dedup are
  exercised naturally.

---

## 2. Concurrency validation (code-level, verified)

| Concern | Guard | Where |
|---|---|---|
| Rider double-assign | `UPDATE ... WHERE status IN ('ready_for_pickup','assigned') AND rider_id IS NULL` | `modules/riders/service.go` |
| Vendor double-advance | `UPDATE ... WHERE id = $1 AND status = $3` | `modules/vendors/service.go` |
| Order idempotency | `idempotency_key` on create + transition | `modules/orders` |
| Money integrity | integer paise; server re-prices; legacy rupee maps for display only | `packages/anilunch_core` |
| Stateless API | no package-level mutable state, no sessions, Redis-backed rate limit | Phase 11 audit |
| Token revocation | Redis denylist checked in `RequireAuth` | `internal/middleware/auth.go` |

`go build` / `go vet` / `go test ./...` green across backend; `flutter
analyze` green in all four apps; core package tests green.

---

## 3. Load validation (run this against a Docker stack)

Full numbers require the stack: `docker compose -f backend/docker-compose.yml
up -d --build`, seed, then `k6 run -e TIER=<tier> -e DURATION=5m
loadtest/scenarios.js` (see `loadtest/README.md` §2–§6).

Pass criteria (thresholds enforced in `scenarios.js`):

- error rate < 1%
- reads (browse/menu/search): p95 < 250–300 ms, p99 < 500–600 ms
- writes (checkout/vendor/rider): p95 < 400 ms, p99 < 800 ms
- WS sessions: connect+join p95 < 1 s, no slow-consumer evictions

Validation status:

- [x] Backend unit/integration tests green (`go test ./...`)
- [ ] Tier 1k smoke + soak (CI gate) — needs Docker stack
- [ ] Tier 5k — needs Docker stack
- [ ] Tier 10k sprint goal — needs Docker stack
- [ ] Tier 100k stretch — needs distributed k6 (`--max-vus`, k6 cloud)
- [ ] Horizontal failover drill (kill a replica, zero 5xx) — `phase11-horizontal-scaling.md` §4
- [ ] WS cross-instance fan-out verified — same doc, checklist
- [ ] Restore drill — `phase13-ha-dr-runbook.md` §5

---

## 4. Known gaps (out of scope for Phase 10)

- **Online payments**: `create-intent` calls Razorpay at request time; load
  tests use COD. Webhook/ledger paths load-tested separately.
- **Search**: apps search client-side over the cached catalog; no dedicated
  search endpoint yet (Phase 12 topic).
- **Admin panel**: no traffic class (human-scale usage).
- **Auth**: JWTs minted in-script against the shared HMAC secret; roles come
  from the seeded DB rows.

---

## 5. Pointers

- Horizontal scaling: `docs/phase11-horizontal-scaling.md`
- Read replicas / replication lag: `docs/phase12-read-replicas.md`
- HA/DR runbook (backups, failover, restore drill): `docs/phase13-ha-dr-runbook.md`