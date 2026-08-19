# AniLunch — Phase 0 Architecture Audit & Gap Analysis

> **Classification key:** `VERIFIED` = directly observed in repo this session · `INFERRED` = strongly implied by evidence but not directly observed · `UNKNOWN` = cannot determine (live DB/runtime absent).
> **Environment at audit time:** Go 1.26.5 ✅, Flutter 3.47.0 ✅. Docker ❌, k6 ❌, psql ❌, redis-cli ❌, nats CLI ❌. Live DB and running infrastructure **not reachable** — anything requiring execution is `UNKNOWN`.

## 1. Executive Summary
The repo is **not** the original "thick-client direct-to-Supabase" app. It has already partially evolved toward the target: a stateless **Go API** (builds + tests green), a shared `anilunch_core` Flutter package, **Drift cache-first** layers in all 4 apps, server-authoritative pricing in Edge Functions + Go, integer-paise money, an order **state machine**, and a Docker stack definition. **However**, the earlier "100k users supported" claim remains **unvalidated** (no load tests runnable here). Material gaps vs target: **order/id type inconsistency unresolved**, **state machine diverges from target lifecycle**, **webhook/payment-confirmation path unclear**, and **load/HA metrics absent**.

## 2. Current Architecture (VERIFIED, from code)
```
Flutter (4 apps) ──┬─► Supabase (auth, some .from(), storage, PostgresChanges)
                   └─► Go API (anilunch_core) ─┬─► PostgreSQL (Supabase)
                                                ├─► Redis (code+compose)
                                                ├─► NATS JetStream (code+compose)
                                                └─► R2 (code; unconfigured→503)
                        + Go WS realtime gateway (NATS-bridged)
```
Two realtime systems **coexist**: Supabase PostgresChanges (customer + admin) AND the Go WS gateway (all 4 apps).

## 3. Target Architecture
Per the Implementation Plan: Flutter → Cloudflare → LB → stateless Go API → (PostgreSQL + PgBouncer, Redis, NATS JetStream, R2). Any instance handles any request; no sticky sessions; media never through API; events durable via JetStream.

## 4. Four Flutter App Inventory
- **Customer** (`anilunch/anilunch`): Heavy Supabase (auth/from/storage/PostgresChanges) **+** Go API (orders/catalog/payment/sync). Drift `animeat_local_db` (items/cart/orders/SyncQueue). Mixed loading (cart/orders local-first; menu/profile spinner). `VERIFIED`.
- **Rider** (`anilunch_rider`): Supabase auth + `riders` + `accept-order` Edge Fn **+** Go API. Drift `animeat_rider_db`. Orders cache-first; profile/earnings spinner. `VERIFIED`.
- **Vendor** (`anilunch_vendor`): Supabase auth + `sellers`/`meal_products`/`orders` fallback **+** Go API. Drift `animeat_vendor_db`. **Strongest cache-first.** `VERIFIED`.
- **Admin** (`anilunch_admin/anilunch_admin`): Heaviest Supabase usage (all entities + storage + PostgresChanges) **+** Go API wrappers. Drift `animeat_admin_db`. Cache-first but spinner-gated. `VERIFIED`.

## 5. Supabase Dependency Map
| Area | Dependency | Status |
|---|---|---|
| Auth | Supabase Auth all 4 apps; bridged to Go JWT | PRESENT |
| DB direct | `.from()` users/items/orders/riders/sellers (cust/vendor/admin) | PRESENT (legacy) |
| Storage | buckets `users`(cust), `assets`+item(admin); **public URLs, no signed** | PRESENT (public) |
| Realtime | PostgresChanges on orders/menu/admin_* | PRESENT |
| Edge Fn | `accept-order`, `create-order`, `create-payment-link` | PRESENT |

## 6. Database Inventory (VERIFIED from migrations 000–011)
Tables: `users, vendors (+sellers view), menus, items (+products view), meal_products, daily_deals, coupons, product_reviews, pages, riders, orders, app_settings`. `VERIFIED` as **migration definitions**; actual live schema `UNKNOWN`.
- **ID type inconsistency — VERIFIED & UNRESOLVED:** `orders.id` = `TEXT` (`000:182`), `riders.id` = `UUID` (`000:162`), `orders.rider_id` = `TEXT` with **no FK** (`000:198`). `users.id`=UUID but `orders.user_id`=TEXT, no FK. Plan Phase 1 required resolving this; **not done**.
- **Money — VERIFIED dual representation:** legacy `NUMERIC(10,2)` rupees **+ canonical `BIGINT` paise** added in `008` (items.price, orders.*_paise, coupons.*_paise, meal_products.price_paise). Server writes paise; bidirectional triggers sync. Authoritative money = integer paise ✅.
- **Indexes:** present on orders(user_id, rider_id, vendor_id, status, order_time, idempotency, partial available). `VERIFIED`.
- **RLS:** `011` dropped wide-open policies and `REVOKE EXECUTE ON accept_order FROM PUBLIC` (granted service_role only); relies on scoped policies from `007`. `VERIFIED` (regression fixed). Full live RLS coverage `UNKNOWN`.

## 7. Authentication Audit
Supabase Auth → `POST /api/v1/auth/exchange` → Go short-lived JWT + refresh; Redis denylist on logout (`backend/internal/auth`, `denylist.go`). `VERIFIED` (code present; runtime `INFERRED`). Roles: `users.is_admin` column (`008:204`); admin gated server-side `INFERRED`.

## 8. RLS / Security Audit
| Finding | Severity | Evidence | Status |
|---|---|---|---|
| Wide-open orders policies (any auth user R/W all) | High (fixed) | `011:9-16` | RESOLVED in migrations |
| `accept_order` SECURITY DEFINER callable by PUBLIC | High (fixed) | `011:26-30` | RESOLVED (service_role only) |
| Public storage URLs (`users`,`assets`) | Medium | agent report | PRESENT — no signed URLs |
| No secrets hardcoded in `lib/` | Info | grep + agent | VERIFIED clean |
| `.env` / `*.env` in `.gitignore` | Info | `.gitignore:2-4` | PRESENT |
| Webhook signature verification | **UNKNOWN** | not found in `create-payment-link` | UNVERIFIED |
| Not a git repo (cannot prove history/secret-removal) | Medium | `git` absent | VERIFIED-absent |

## 9. Storage Audit
Buckets `users` (customer avatar), `assets` + item bucket (admin). **Public URLs only; no signed URLs.** `VERIFIED`. Risk: public buckets expose objects by URL.

## 10. Realtime Audit
Supabase Realtime publication includes `orders` + `riders` (`000:236-251`). Customer/admin subscribe via PostgresChanges; all apps also use Go WS (`order:`, `rider:`, `vendor:`, `riders.available`, `admin`). `VERIFIED`. Two parallel realtime paths = redundancy/complexity risk.

## 11. Payment Audit
- **Provider:** Razorpay (`create-payment-link/index.ts:92-93,114`). `VERIFIED`.
- **Creation:** Edge Fn verifies JWT, order ownership, **payable state**, and **recomputes expected amount in paise and rejects mismatch** (`create-payment-link:80-89`). Strong anti-tamper. `VERIFIED`.
- **Order pricing:** `create-order` Edge Fn fetches live item price, computes subtotal + delivery fee (₹30 / free ≥₹500) server-side (`create-order:55-80`). Go API computes server-side (money.go int64 paise). `VERIFIED` server-authoritative.
- **Client influence on price/fee/total:** **NONE** on the server path. `VERIFIED`.
- **Payment confirmation / webhook:** `create-payment-link` only sets `payment_status='created'`. **No webhook handler observed**; customer app polls Go API for `paid/confirmed` (`payment_service.dart`). Confirmation path `UNKNOWN`/likely client-poll-dependent → **gap**.
- **Idempotency:** `orders.idempotency_key` column + partial index (`008:80,88`); Go-level guarding `INFERRED` from prior docs, not directly read.

## 12. Order Lifecycle Audit
**Actual Go states** (`state_machine.go`): `pending_payment → pending → confirmed → preparing → ready_for_pickup → accepted → picked_up → delivered`, plus `cancelled`. `VERIFIED`.
**Target lifecycle** (master prompt): `CREATED → PAYMENT_PENDING → CONFIRMED → RESTAURANT_ACCEPTED → PREPARING → READY_FOR_PICKUP → RIDER_ASSIGNED → PICKED_UP → OUT_FOR_DELIVERY → DELIVERED`.
**Gaps:** no `CREATED`/`RESTAURANT_ACCEPTED` label (vendor-accept ≈ `confirmed`); `accepted` conflates rider-assign+accept; **no `RIDER_ASSIGNED` or `OUT_FOR_DELIVERY` state**. `VERIFIED` divergence.
- Transitions validated server-side via `CanTransition`/`ValidateTransition`. `VERIFIED`.
- Two-riders-accept: Go guard `UPDATE … WHERE rider_id IS NULL` claimed in docs, but actual state uses `accepted` not `assigned` → doc/code naming mismatch (`INFERRED`).
- Duplicate orders: idempotency_key present (`VERIFIED` column; enforcement `INFERRED`).
- Client cannot set status (server-only transitions). `VERIFIED` by design.

## 13. Performance / Static Analysis (NOT load test)
- Redundant dual realtime (Supabase + Go WS) → double event traffic. `INFERRED` cost.
- Admin/vendor keep legacy Supabase `.from()` as primary/fallback → extra round-trips. `VERIFIED`.
- Customer menu/lunch/profile show spinner-before-network (not cache-first). `VERIFIED`.
- No pagination observed on some `.from()`/list calls → unbounded-query risk. `INFERRED`.
- **No k6/Docker → NO load-test numbers. Do not claim scalability.** `UNKNOWN`.

## 14. Flutter UX / Cache Analysis
| App | Cache-first screens | Spinner screens |
|---|---|---|
| Customer | cart, orders (Drift) | menu, lunch, profile |
| Rider | orders (Drift) | profile, earnings, dashboard |
| Vendor | profile, stats, products, orders (Drift) | cold-start only |
| Admin | cache-first but spinner-gated | cold-start |
`VERIFIED` via agent. Migration to full cache-first is **low-risk, non-UI-rewrite** for customer/admin spinner screens.

## 15. API Contract Analysis
Go API modules: auth, users, catalog, orders, payments, riders, vendors, admin, media, health (`backend/internal/modules/*`). REST + WS. Structured errors, Prometheus, rate-limit, JWT+denylist. `VERIFIED` (builds/tests green).

## 16. Target Architecture Gap Analysis
| Component | Status | Evidence |
|---|---|---|
| Cloudflare | UNKNOWN/MISSING in repo | no tf/cloudflare config found |
| Go API | PRESENT | `go build`/`go test` green |
| PostgreSQL | PRESENT | migrations + Supabase |
| PgBouncer | PARTIAL | compose only; Supabase-stage unknown |
| Redis | PRESENT (code+compose) | not verified running |
| NATS JetStream | PRESENT (code+compose) | not verified running |
| R2 | PARTIAL | `r2.go`+media endpoint; unconfigured→503 |
| Realtime gateway | PRESENT | Go WS + NATS bridge |
| Auth | PRESENT | Supabase+Go JWT+denylist |
| Observability | PARTIAL | Prometheus in Go + `backend/prometheus`; Grafana unverified |
| Load balancing | PARTIAL | `docker-compose.lb.yml`+Caddy; not in use |

## 17. Supabase Exit Plan
| Component | Current | Replacement | Difficulty | Priority |
|---|---|---|---|---|
| Auth | Supabase Auth | Go JWT (exchange already exists) | Med | P2 |
| PostgreSQL | Supabase PG | Self-managed PG (compose) | Med | P3 |
| Realtime | Supabase + Go WS | Go WS/NATS (already built) | Low | P2 |
| Storage | Supabase buckets | Cloudflare R2 (code exists) | Low-Med | P2 |
| Edge Fn | create-order/payment/accept | Go API modules | Med | P2–P3 |

## 18. Critical Risks
1. **Unvalidated capacity** — no load tests; "100k" unproven (Rule #29 risk). `UNKNOWN`.
2. **Order/id FK inconsistency** — TEXT order ids, no FK to UUID riders/users. `VERIFIED`.
3. **State machine ≠ target** — missing RIDER_ASSIGNED/OUT_FOR_DELIVERY/RESTAURANT_ACCEPTED. `VERIFIED`.
4. **Payment confirmation/webhook unclear** — relies on client poll; no verified webhook. `UNKNOWN`.
5. **Public storage buckets** (no signed URLs). `VERIFIED`.
6. **Dual realtime** complexity. `INFERRED`.
7. **Not a git repo** — no history/rollback/secret-audit trail. `VERIFIED-absent`.

## 19. Recommended Migration Order
P0: init git + confirm no secrets; resolve order/id FK types. → P1: unify state machine to target lifecycle. → P2: retire Supabase Realtime→Go WS; R2 signed URLs; webhook verification. → P3: load-test Tier 1k/5k (needs remote Docker+k6); then PgBouncer/HA.

## 20. Environment / Tooling Limitations
**Can do now:** source audit, Flutter analysis, dependency map, schema review (migrations), security static analysis, order/payment/lifecycle analysis, gap analysis, test-script creation. ✅
**Cannot validate here:** real PG/Redis/NATS perf, multi-node scaling, 100k load, failover, restore drill, stress test. ❌ (no Docker/k6/psql).

## 21. Items Requiring Docker/Cloud/CI Validation
Tier 1k–100k load tests; failover drill; restore drill; Redis/NATS throughput; PgBouncer behavior; Grafana alerts; R2 end-to-end.

## 22. Unknown / Unverified
Live DB schema & RLS enforcement; webhook handler; running Redis/NATS; actual latency/throughput; production secrets posture; Cloudflare config; payment finalization flow.

---
*Phase 0 gate: STOP. No backend rewrite, no Supabase deletion, no schema changes, no Redis/NATS introduction, no auth/payment changes were made.*

---

# ERRATA — Post-audit verification (Phase 1, 2026-08-19)

The original audit inventory was based on a truncated directory listing. Full
verification during Phase 1 found **additional migrations (012–016), a second
`010` file, and `backend/api/openapi.yaml`** that the audit missed. Their
contents materially change the findings:

## E1. Migration inventory correction (VERIFIED)
Beyond `000–011` the repo contains: `012_users_pages_schema.sql`,
`013_seed_catalog_data.sql`, `014_fix_id_types_and_rls.sql`,
`015_security_hardening.sql`, `016_server_side_money_validation.sql`, and a
**duplicate version `010`** (`010_menus_items_deals_schema.sql` AND
`010_sellers_vendors_reconciliation.sql`). An API contract already exists:
`backend/api/openapi.yaml` (audit §15 "generate/document an API contract" is
therefore PARTIAL, not missing).

## E2. The migration chain 000→016 is internally contradictory (VERIFIED, static)
| Defect | Evidence | Consequence |
|---|---|---|
| Duplicate version `010` | two `010_*.sql` files | ambiguous apply order |
| `010` redefines `menus.id`/`items.id`/`daily_deals.id`/`coupons.id` as UUID via `CREATE TABLE IF NOT EXISTS` | `010_menus_items_deals_schema.sql:12,33,76` | no-op on a DB built from `000` (BIGINT/TEXT); `items.category_id UUID REFERENCES menus(id)` then fails on type mismatch |
| `010`/`012`/`014` RLS uses `users.role` | `010:125,140,155`; `012:26`; `014:47,73` | `012` only declares `role` inside `CREATE TABLE IF NOT EXISTS` (no-op) → column not guaranteed → policies fail |
| `014` backfills `orders.uuid_id` with `gen_random_uuid()` | `014:12-17` | random UUIDs unrelated to existing TEXT `orders.id` → referential mapping destroyed, nothing syncs them |
| FKs target non-unique `orders(uuid_id)` | `014:89,109`; `015:58,81` | Postgres requires a unique constraint on FK targets → `CREATE TABLE`/FK fails |
| `013` writes paise as rupees | `013:20-25,32-33,40-41` | ₹18,000 biryani, ₹8,000 chai, ₹10,000 coupon minimum |
| `016` references `orders.discount_type` (no such column) and recomputes totals from `items->>'price'` | `016:98,102` | runtime error on coupon orders; NULL subtotal if items JSONB lacks `price` key → order creation breaks |
| `016`/`014` `items` vendor policy compares `vendors.name = auth.uid()::text` | `014:44`; `010:137` | policy matches nothing meaningful; broken vendor authorization by design |

**Verdict:** whoever produced `010–016` did so without validating against `000` or
the live schema. If the live database was built from `000–009`, then `010–016`
**cannot apply cleanly** (several statements fail outright). If the live
database was built fresh from `010` alone, it diverges from `000` and from the
Go API contracts. Either way the chain is **not reproducible** — this is the
single most important Phase 1 finding and it supersedes the audit's earlier
assumption that the ID/FK issue was merely "unresolved" (it was *attempted*
and botched).

## E3. Corrected gap-table status
- API contract: PARTIAL → PRESENT (`backend/api/openapi.yaml`) but its accuracy
  against the broken chain is UNKNOWN.
- Order/id consistency: VERIFIED BROKEN (attempted by `014`, ineffective/breaking).
- Money: legacy rupees + canonical paise columns remain; `016`'s trigger-based
  recalculation is itself defective.

## E4. Verification status of this errata
**VERIFIED:** all E2 defects by static reading of the migration files (and by
`backend/internal/database/migrate/migrate_lint_test.go`, which fails on all of
them). **UNKNOWN:** the actual live database's shape and which migration chain
was applied there — requires remote/Supabase inspection via
`supabase/integrity-check.sql`.
