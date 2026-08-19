# AniLunch — Implementation Plan

**Target:** 100,000+ registered users → 100,000+ concurrent users
**UX bar:** WhatsApp-like (immediate transitions, cache-first, no blocking loading)
**Cost model:** ₹0 start → pay when scale requires it
**Constraint:** Do not rewrite the 4 Flutter apps; evolve infrastructure behind stable API contracts.

---

## 1. Guiding Rules (non-negotiable)

1. **Server is source of truth** for money, orders, payments, roles, states.
2. **Client is never trusted** for price/subtotal/discount/role/status.
3. **Stateless** Go API — no sessions/files/temp state in instance memory or disk.
4. **Cache-first** Flutter — render cached data, refresh in background.
5. **Idempotency** on every critical mutation (order, payment, assignment, transition).
6. **Async by default** — order commit before notifications/events.
7. **No premature microservices, no premature Kubernetes.**
8. **Measure, don't assert** — every claim backed by load test + metric.
9. **Never commit secrets.** No service-role key, DB password, JWT secret, R2 key.

---

## 2. Target Architecture (end state)

```
Flutter (customer / rider / vendor / admin)
   │  local cache (SQLite: Isar or Drift) + sync queue
   │  optimistic UI for safe ops, server-confirm for money
   ▼
Cloudflare (DNS, TLS, WAF, DDoS, rate-limit, CDN, R2 cache)
   ▼
Load Balancer (Caddy/Traefik or managed LB)
   ▼
Go API  (stateless, N replicas — horizontal)
   ├── Redis       (cache, rate-limit, short-lived state, denylist)
   ├── NATS JetStream (durable async events, order/realtime bus)
   ├── PostgreSQL  (authoritative transactional store)
   │      ├── PgBouncer/Supavisor (connection pooling)
   │      └── read replica(s) (scale reads, added only when measured)
   └── R2/CDN     (images, media — never through app server)
```

**Key properties:**
- Any API instance handles any request (no sticky sessions).
- 100k clients never touch PostgreSQL directly — only the Go API via a pool.
- Images never hit the Go API; served via CDN/R2.
- Order events survive crashes via JetStream (durable, at-least-once, replayable).

---

## 3. Phased Roadmap

### PHASE 0 — Full Audit (read-only)
**Goal:** Understand existing system; produce source-of-truth report.
- Investigate all 4 Flutter apps: Supabase calls, tables, RPCs, Storage buckets, Realtime channels, Edge Functions, auth flows.
- Inventory migrations vs. actual DB (mark missing items as UNKNOWN).
- Audit RLS policies, security, leaked credentials.
- Deliverables: architecture diagram, dependency map, DB/table inventory, migration inventory, RPC/function/Edge Function inventory, auth flow, RLS/security/storage/realtime/payment/order-lifecycle audits, bottleneck + round-trip + caching analysis, migration risks, resource estimates, load-test strategy.
- **Output:** `docs/phase0-audit.md`. Gate: approval before any change.

### PHASE 1 — Recover DB source of truth
- Reconstruct missing tables/migrations from live schema (read-only) into versioned migrations.
- Resolve `orders.id` and `riders.id` type inconsistencies.
- Capture storage buckets/policies + `create-payment-link` contract into repo.
- **Output:** complete, reproducible `api/migrations/` or `supabase/migrations/`.

### PHASE 2 — Security / RLS correction
- Narrow broad RLS policies; enforce per-role server checks.
- Move money calc off Flutter; add server-side validation.
- Rotate any leaked anon/service keys; add `*.env` to `.gitignore`.
- Enforce admin/vendor authorization server-side; close rider accept-order bypass.

### PHASE 3 — Infrastructure foundation (self-hosted, free)
- Deploy stateless **Go API** skeleton (modular monolith) + Docker Compose.
- Stand up PostgreSQL + PgBouncer (+ Redis, NATS only if memory allows on free box).
- Cloudflare in front (DNS/TLS/WAF/CDN). R2 for files.
- **Deferred:** load balancer multi-instance (Tier 2).

### PHASE 4 — Performance-first Flutter data architecture
- Introduce local cache layer (Isar or Drift) + sync queue.
- Cache-first rendering; optimistic UI for safe ops.
- Remove blocking spinners on cached/navigable screens.
- Background refresh + reconciliation (LWW + server merge documented).

### PHASE 5 — Secure order/payment architecture
- Server-authoritative `create_order` (prices/subtotal/fee/discount/total computed server-side).
- Explicit order state machine; reject invalid transitions.
- Idempotency keys; integer-minor-unit money (paise).
- Payment provider integration (Razorpay/Cashfree UPI) — contract via `create-payment-link`.

### PHASE 6 — Go API modular monolith (business logic ported)
- Port core modules: auth/users/restaurants/menus/products/cart/orders/payments/riders/delivery/notifications/vendors/admin.
- Structured errors, request IDs, pagination, validation, rate limits.
- Observability: structured logs + Prometheus metrics.

### PHASE 7 — Redis caching
- Hot data (menu, restaurant, config), rate-limit counters, short-lived state.
- TTL + jitter, invalidation on vendor change, request coalescing.
- Measure cache hit rate.

### PHASE 8 — NATS JetStream async events
- Order lifecycle events (`OrderCreated` → vendor/rider/customer/payments/analytics).
- Durable, idempotent, retryable consumers.
- Measure queue latency + throughput.

### PHASE 9 — Realtime optimization
- Scoped subscriptions: `order:{id}`, `rider:{id}`, `vendor:{id}`.
- Shared WS gateway → one shared NATS subscription per channel (fan-out, no DB query per client).
- Rider GPS: adaptive frequency (10–30s normal, 5–10s active), location updated separately from order writes.

### PHASE 10 — Load testing
- k6/vegeta scripts for browsing, menu, search, cart, login, order create, tracking, vendor/rider ops.
- Progressive tiers: 1k → 5k → 10k → 100k.
- Measure p50/p95/p99, errors, CPU, RAM, DB conns, Redis, NATS, throughput.

### PHASE 11 — Horizontal API scaling
- Multiple stateless Go instances behind LB; verify no sticky sessions/state loss.
- Autoscale by CPU + request rate + latency + queue depth (not CPU alone).

### PHASE 12 — PostgreSQL read replicas
- Introduce when measured read load requires; monitor replication lag.

### PHASE 13 — High availability
- No single-instance dependency; DB backup (7 daily / 4 weekly / 3 monthly) + tested restore.
- Disaster recovery runbook (rebuild from Git + secrets + DB backup + R2).

### PHASE 14 — 100k+ concurrent stress test
- Validate end-state ceiling; flash-event scenario test (not all users ordering at once).

---

## 4. Key Decisions to Lock Now

| # | Decision | Recommendation | Phase |
|---|---|---|---|
| A | Flutter local cache/sync engine | Isar or Drift (SQLite) + sync queue + Riverpod | 4 |
| B | Event bus durability | NATS **JetStream** (not core NATS) | 8 |
| C | Money storage | integer minor units (paise), never float | 5 |
| D | Payment provider (India) | Razorpay / Cashfree UPI | 5 |
| E | Auth | Preserve Supabase Auth short-term; JWT validation in Go; short-lived JWT + refresh; Redis denylist | 3–5 |
| F | Observability | Prometheus + Grafana (self-hosted) + structured logs | 6 |

---

## 5. Phase Gating

After EACH phase: run tests → validate functionality → validate security → validate performance → document → report → **STOP for approval** before destructive/major changes.

Never jump straight to Phase 14. Never deploy blindly (CI tests → build → security checks → migration validation → backup → deploy → health check → rollback path).

---

## 6. Cost Progression

| Stage | Infrastructure | Cost |
|---|---|---|
| TIER 0 Dev | Supabase Cloud + Cloudflare + R2 | ₹0 |
| TIER 1 Early prod | Oracle Always Free VM + Go + PG + Redis + NATS (slim) | ₹0 |
| TIER 2 Growth | Paid VPS: multi Go API + PG primary+replica | ~₹1,500–3,000/mo |
| TIER 3 Scale | Cloudflare + LB + Go cluster + Redis/NATS cluster + PG primary+replicas + R2 | pay-as-you-grow |

Flutter apps remain unchanged across all tiers (stable API contract).
