# AniLunch (AniMeat) — Full Architecture Analysis Report

**Date:** 2026-08-21
**Scope:** Full monorepo — frontend (4 Flutter apps + shared core), backend (Go), Supabase layer, infrastructure, CI/CD, load testing, and known risks.

**Product:** Indian on-demand meat & lunch (thali) delivery platform, based in Shillong (Meghalaya). 4 Flutter apps, 1 shared Dart core, a Go backend, Supabase (auth + legacy data), deployed as a horizontally-scaled cluster with HA/DR.

---

## 1. Repository Layout

| Path | Contents |
|---|---|
| `anilunch/anilunch/` | Customer app (Flutter) |
| `anilunch_admin/anilunch_admin/` | Admin back-office app (Flutter) |
| `anilunch_rider/` | Rider delivery app (Flutter) |
| `anilunch_vendor/` | Vendor/restaurant app (Flutter) |
| `packages/anilunch_core/` | Shared pure-Dart API client (REST + WS + sync), version 0.1.0 |
| `backend/` | Go modular monolith (chi, PG16, Redis 7, NATS JetStream, WebSocket gateway) |
| `supabase/` | 18 migrations + 3 edge functions (Deno) |
| `loadtest/` | k6 load-test suite (tiers 1k → 100k VUs) |
| `docs/` | Phase 0–13 reports + implementation plan |
| `.github/workflows/` | 7 CI/CD workflows |
| `deploy.sh` | "Phase 14 Cluster Deployment" script |

---

## 2. Architecture Overview

```
┌─────────────┬─────────────┬─────────────┬─────────────┐
│ Customer    │ Admin       │ Rider       │ Vendor      │  4 Flutter apps
│ (anilunch)  │ (admin)     │ (rider)     │ (vendor)    │  └─ packages/anilunch_core (Dio REST + WS)
└──────┬──────┴──────┬──────┴──────┬──────┴──────┬──────┘
       │             │             │             │
       │   Supabase Auth (JWT)     │             │
       └─────────────┴─────────────┴─────────────┘
                    │  POST /auth/exchange (Supabase JWT → Go JWT)
                    ▼
            ┌───────────────┐   Caddy LB (health-checked round-robin, WS passthrough)
            │  Go API ×N    │  api1/api2/api3 — stateless
            │  (chi router) │
            └──┬─────┬──────┴─────────────────────────────┐
               │     │                                    │
     PgBouncer rw  PgBouncer ro                 NATS JetStream (ORDERS stream)
        │            │                                    │
   PostgreSQL 16  Streaming standby               Redis 7 (cache, rate-limit,
   (primary)      (read replica)                  token denylist, refresh tokens)
                                                    Cloudflare R2 (media) / Razorpay (payments) / FCM (push)
```

**Core principle (from `docs/implementation-plan.md`):** the server is the source of truth for money/orders/roles/state. Clients never set prices; money is integer **paise**; every critical mutation is idempotent; cache-first Flutter UX; async by default; no premature k8s/microservices; measure, don't assert; never commit secrets.

---

## 3. Backend (Go — module `animeat/backend`, Go 1.25)

### 3.1 Tech stack

`chi/v5` router, `pgx/v5` pools, `go-redis/v9`, `nats.go` JetStream, `gorilla/websocket`, `golang-jwt/v5`, `golang-migrate/v4`, `prometheus/client_golang`, AWS SDK v2 (R2 S3), singleflight (`x/sync`).

### 3.2 Structure

- `cmd/server` (main binary), `cmd/migrate` (CLI -up/-down/-version), `cmd/dbcheck` (runs `supabase/integrity-check.sql` read-only)
- `internal/`:
  - `config` — env-based configuration
  - `database` — `postgres.go`: dual pgx pools (`Pool` primary + `ReadPool` replica), replica-lag monitor (15s ticker → `animeat_replica_lag_seconds`, warning >10s)
  - `cache` — Redis wrapper (Get/Set/Delete/DeletePattern via SCAN+DEL)
  - `events` — NATS JetStream: `nats.go` (durable `ORDERS` stream, `orders.*` subjects, 72h retention, 5-min dedup), `publisher.go`, `consumer.go` (3 durable consumers)
  - `auth` — `tokens.go` (Go HS256 JWT), `denylist.go` (Redis access-token denylist + refresh-token store)
  - `authz` — DB role resolution (customer/vendor/rider/admin, most privileged wins)
  - `middleware` — request_id, logger, CORS, recovery, auth, rate_limit (Redis INCR pipeline, 30/min protected, 60/min admin)
  - `modules` — one folder per domain: health, catalog, orders, payments, users, riders, vendors, admin, auth, media
  - `notifications` — FCM push (HTTP v1 OAuth2 service-account JWT + legacy fallback)
  - `observability` — Prometheus metrics at `/metrics`
  - `platform` — response envelope `{success, data, error{code,message,detail}}`, errors, `Money` (int64 paise)
  - `realtime` — WebSocket hub/client/channel/gateway + NATS bridge
  - `storage` — Cloudflare R2 (S3-compatible) presigned URLs

### 3.3 API endpoints (all under `/api/v1`)

**Public:**
| Method | Path | Purpose |
|---|---|---|
| GET | `/metrics` | Prometheus scrape |
| GET | `/health/live`, `/health/ready` | Liveness / readiness (Caddy LB drain signal) |
| GET | `/catalog/items?category=`, `/catalog/deals`, `/catalog/menus` | Cached catalog reads |
| GET | `/ws` | WebSocket gateway (JWT via `?token=` or Bearer) |
| POST | `/auth/exchange` | Swap Supabase JWT → Go tokens |
| POST | `/auth/refresh` | Rotate refresh token |
| POST | `/payments/webhook` | Razorpay webhook (HMAC verified) |

**Protected (JWT + 30 req/min):**
| Method | Path | Purpose |
|---|---|---|
| GET/PUT | `/users/me` | Own profile (upsert on first login) |
| GET | `/users/me/notifications` | Notification inbox (read replica) |
| POST | `/users/me/notifications/read` | Mark all read |
| POST/DELETE | `/users/me/device-tokens` | FCM device token register/unregister |
| POST | `/orders` | Create order (server-authoritative pricing, idempotency key) |
| GET | `/orders` | Customer order history |
| GET | `/orders/{id}` | Get order (visibility enforced) |
| POST | `/orders/{id}/cancel` | Customer cancels pending order |
| POST | `/orders/{id}/transition` | Role-authorized status transition |
| GET/PUT | `/riders/me` | Rider profile |
| PUT | `/riders/me/availability` | Toggle online/offline (approved only) |
| PUT | `/riders/me/location` | Update GPS (fans out to `riders.location` NATS) |
| GET | `/riders/orders/available` | Unassigned `ready_for_pickup` orders (read replica) |
| GET | `/riders/orders/mine` | Assigned active orders (read replica) |
| POST | `/riders/orders/{id}/accept` | Atomically claim an order (guarded UPDATE) |
| GET/PUT | `/vendors/me` | Vendor profile |
| GET | `/vendors/me/orders` | Active kitchen orders (read replica) |
| GET | `/vendors/me/stats` | Daily stats (read replica) |
| POST | `/media/upload-url` | Presigned R2 upload URL (5 min) |
| POST | `/payments/create-intent` | Payment link + UPI intent for an order |
| POST | `/auth/logout` | Revoke access jti + refresh token(s) |

**Admin (JWT + 60 req/min + DB-resolved admin):**
| Method | Path | Purpose |
|---|---|---|
| GET | `/admin/dashboard` | Platform-wide stats + status breakdown |
| GET | `/admin/orders?status=` | All orders |
| GET | `/admin/users` | All customers |
| GET | `/admin/riders?status=` / `/admin/riders/{id}` | All / single rider |
| PUT | `/admin/riders/{id}/approval` | Approve/reject rider |
| GET/PUT | `/admin/settings` | Branding singleton (hero, footer) |
| GET/POST/PUT/DELETE | `/admin/items[/{id}]` | Item CRUD (soft-deactivate) |
| GET/POST/DELETE | `/admin/menus[/{id}]` | Menu management |
| GET/POST/PUT/DELETE | `/admin/deals[/{id}]` | Deal management |
| GET/PUT/DELETE | `/admin/pages[/{slug}|/{id}]` | CMS pages |

**OpenAPI spec** (`backend/api/openapi.yaml`, 759 lines) documents 30 paths (subset — admin orders/users, riders orders/mine, media, device tokens missing). Money as integer paise via `*_paise` fields; legacy rupee fields kept for old clients.

### 3.4 Key mechanisms

- **Order state machine** (`orders/state_machine.go`): `pending_payment → pending → confirmed → preparing → ready_for_pickup → accepted → picked_up → delivered` (+ cancelled from most states). Concurrency-safe via `UPDATE ... WHERE status=$` (409 `INVALID_TRANSITION` on race). Role-authorized: vendor on own orders, rider on assigned, customer may only cancel, admin anything. Every transition publishes `orders.<status>`.
- **Server-authoritative pricing** (`orders/service.go`): all money integer paise; delivery fee ₹30 (3000 paise), free ≥ ₹500 subtotal; coupons percent/flat (cached 60s in Redis); customization pricing parsed server-side ("Meat: 2x Chicken" → +₹20 each); clients can never set prices. Idempotency via `idempotency_key` lookup + NATS Msg-Id dedup.
- **Events (NATS JetStream):** durable `ORDERS` stream, 72h, 5-min dedup. Events: `orders.created`, `orders.paid`, `orders.accepted`, `orders.<status>`; rider GPS on ephemeral core-NATS `riders.location`. 3 durable consumers: **notification-writer** (maps events to notifications via `notificationForEvent`, idempotent insert `ON CONFLICT (source_event_id)`, then FCM push), **kitchen-dispatch** (logs for kitchen displays), **rider-broadcast** (filters `orders.ready`). WS NATS bridge fans out per channel (order:{id}, rider:{id}, vendor:{id}, admin, riders.available) at zero per-client DB cost.
- **Auth:** Supabase JWT → Go HS256 access tokens (15 min TTL) + rotating refresh tokens (7 days, Redis-stored). `RequireAuth` checks Redis denylist for jti; role resolved from DB via `authz.ResolveActor` (riders → vendor → is_admin → customer). Fail-open when Redis is nil (dev).
- **Realtime WS:** channels `order:{id}`, `rider:{id}`, `vendor:{id}`, `riders.available` (broadcast), `admin`. Join-time entitlement checks per channel (ownership/assignment/role). Per-client buffer 64 events, 30s ping/60s pong, slow consumers evicted. Stateless across replicas — shared NATS subscription per process, Caddy passes WS without stickiness.
- **Payments:** Razorpay webhook HMAC-SHA256 verified (accepts nested + flat payloads), idempotent replay-safe, transitions `pending_payment → confirmed`, sets `payment_status=paid` + `payment_intent_id`, publishes `orders.paid`. Create-intent verifies ownership + not-paid, builds payment link (`https://rzp.io/i/animeat-{orderId}`) + UPI intent locally.
- **Read/write split:** `Reader()` routes stale-tolerant reads (catalog via Redis cache-aside, vendor kitchen queue/stats, rider available/assigned lists, notification inbox) to the replica; money/state reads and all writes go to primary. Falls back to primary when `READ_DATABASE_URL` unset. Lag monitor 15s ticker, alert >30s.
- **Caching:** catalog items 5min/deals 15min/menus 10min TTLs with ±10% jitter, singleflight coalescing, hit/miss metrics; coupon cache 60s; catalog invalidated via `DeletePattern("catalog:*")` on admin mutations; rate limiting via atomic INCR pipeline.
- **FCM push:** dual-mode (HTTP v1 with OAuth2 Bearer from service-account JWT assertion, token cached with −60s skew; legacy server-key fallback). Targets `user_device_tokens` table.
- **Media:** `POST /media/upload-url` returns 5-minute presigned PUT to R2 (direct upload, never through API); CDN base `https://cdn.animeat.app`.

### 3.5 Infrastructure

- **Dockerfile:** multi-stage, static build `CGO_ENABLED=0`, `alpine:3.19`, runs as `USER nobody:nobody`.
- **Dev compose (`docker-compose.yml`):** PG16 + PgBouncer (transaction mode, MAX_CLIENT_CONN 1000, pool 25) + Redis 7 (256MB LRU) + NATS 2.10 + API + optional k6. Dev DB auto-applies all `supabase/migrations/` via initdb.
- **Cluster compose (`docker-compose.lb.yml`):** Caddy LB (health-checked `/health/ready` round-robin across api1/2/3, `lb_try_durations 500ms`, WS passthrough, gzip) → 3 stateless API replicas → dual PgBouncers (rw pool 40 → primary, ro pool 40 → standby) → PG primary + streaming standby (`pg_basebackup -R` via `replica-init.sh`), Redis 7, NATS 2.10.
- **Autoscale rules** (`prometheus/autoscale.rules.yml`): scale out on ≥2 of 4 signals sustained 5 min — CPU >70%, request rate >2000 rps, p95 >300 ms, NATS ORDERS backlog >1000. Alerts: `AnimeatAPIScaleOut`, `AnimeatReplicaDown`, `AnimeatDBPoolExhausted`, `AnimeatNATSSlowConsumer`, `AnimeatReplicaLagHigh` (>30s).

---

## 4. Supabase Layer

### 4.1 Migrations (18 files + 1 regression artifact)

| File | Purpose |
|---|---|
| `000_base_schema.sql` | Baseline (12 tables, views, realtime pub) |
| `001_accept_order_function.sql` | Legacy plpgsql `accept_order(UUID,UUID)` |
| `002_rls_policies.sql` | First-gen orders RLS |
| `003_create_app_settings.sql` | `app_settings` + RLS |
| `004_orders_indexes.sql` | Orders indexes |
| `005_vendor_app_schema.sql` | Vendors phase 2, RLS |
| `006_rider_broadcast_and_fixes.sql` | Rider RLS v2 + `accept_order(TEXT,TEXT)` SQL function |
| `007_secure_rls_policies.sql` | Full role-based RLS rewrite (SEC-01..05) |
| `008_api_v1_canonical_schema.sql` | Canonical paise columns + dual-direction sync triggers + `uuid_id` |
| `009_notifications.sql` | Notifications inbox |
| `010_sellers_vendors_reconciliation.sql` | Sellers view reconciliation, vendor email/store_name |
| `011_security_regression_fixes.sql` | Drops wide-open policies, locks `accept_order` (SEC-07) |
| `012_users_pages_schema.sql` | `users.role`/`is_approved`, pages meta, sample pages |
| `013_seed_catalog_data.sql` | Seed menus/items/deals/coupons |
| `014_fix_id_types_and_rls.sql` | `orders.uuid_id`, `vendor_orders`, `payment_intents`, extra RLS |
| `015_security_hardening.sql` | Audit tables + triggers, drops regression policies |
| `016_server_side_money_validation.sql` | Money calc/validation triggers, helpers, `orders_canonical` view |
| `018_user_device_tokens.sql` | FCM/APNs device tokens |
| `20260727000000_vendor_orders_policy.sql` | **Regression artifact** — wide-open `authenticated` policies (removed by 011/015) |

Note: no `017` migration (sequence jumps 016 → 018). Separate read-only `supabase/integrity-check.sql` (13 data-quality checks).

### 4.2 Schema (public schema, extensions uuid-ossp + pgcrypto)

- **`users`** — `id` UUID PK, legacy `user_id` TEXT UNIQUE, name/email/phone/address, `role` (customer/vendor/admin/rider, 012), `is_approved`, `is_admin`, timestamps.
- **`vendors`** — `id` UUID PK (== auth.uid()), name/address/phone/email/store_name, location lat/lng, `is_open`.
- **`riders`** — `id` UUID PK (== auth.uid()), profile fields, `is_online`, lat/lng, `is_approved`, `approval_status` (pending/approved/rejected), `rejection_reason`; partial index on availability status.
- **`orders`** (most-modified) — legacy `id` TEXT PK + canonical `uuid_id` UUID UNIQUE; `user_id` TEXT, `order_type` (meat/lunch), `items` JSONB, `product_ids` TEXT[], money in legacy NUMERIC rupees + canonical `*_paise` BIGINT (total_amount_paise INTEGER after 015); `status`, `payment_method` (COD default), `payment_status` (pending), `payment_intent_id`, `idempotency_key` (partial unique index), `rider_id` TEXT, `vendor_id` UUID FK, delivery address/coords, `discount_type` (016). Indexes: `idx_orders_available` (partial: unassigned pending/ready_for_pickup), `idx_orders_idempotency`, `uq_orders_uuid_id`, rider_status partial, etc.
- **Catalog:** `menus` (categories), `items` (TEXT PK, legacy rupees + canonical paise, `is_active`, `is_available`, `preparation_min`, `rating`, `reviews_count`; FK to menus/vendors), `meal_products` (lunch thalis, rice/meat options arrays), `daily_deals` (discount %, valid_from/until), `coupons` (flat/percent, min_order, max_discount, expiration), `product_reviews`.
- **Supporting:** `pages` (CMS, slug unique, meta columns), `app_settings` (branding singleton), `notifications` (user-scoped, `source_event_id` UNIQUE for idempotent ingestion), `vendor_orders` (join table), `payment_intents` (provider/status/amount), `user_device_tokens` (UNIQUE(user_id, token)), audit tables `order_audit_log` / `coupon_audit_log` / `inventory_audit_log`.
- **Views:** `sellers` (vendors compat, security_invoker, insert/update/delete rules), `products` (items compat), `orders_canonical` (paise projection).

### 4.3 RLS model

Roles: Postgres `anon`/`authenticated`/`service_role` + app-level `users.role` (checked via subqueries). RLS enabled on all tables except `users` (no `ENABLE ROW LEVEL SECURITY` statement).

**`orders`** (final state): customers read/insert own (`auth.uid()::text = user_id`); customers cancel own pending (WITH CHECK status='cancelled'); riders see `ready_for_pickup` unassigned; riders read/update own assigned; vendors read/update own store orders (`vendor_id = auth.uid()`); service_role ALL. Order claiming moved off the table into `accept_order()` — SECURITY DEFINER, `REVOKE EXECUTE FROM PUBLIC`, granted to `service_role` only (011/014/015).

Other tables follow the same pattern: public SELECT + service_role ALL for catalog; self-management for riders/vendors/notifications/device-tokens; admin via `users.role='admin'` subquery; audit tables service_role only. Some 014 policies use a fragile heuristic `vendor_id IN (SELECT id FROM vendors WHERE name = auth.uid()::text)`.

### 4.4 Functions / triggers

- `accept_order(TEXT, TEXT)` — SQL SECURITY DEFINER, atomic `UPDATE ... WHERE status IN ('ready_for_pickup','assigned') AND rider_id NULL/'' RETURNING`, service_role only.
- Sync triggers (008): `sync_items/coupons/orders_legacy_to_canonical` + reverse — bidirectional rupees↔paise.
- Audit triggers (015): order status changes, vendor approval, rider approval — actor from GUCs `app.actor_id`/`app.actor_role`, default 'system'.
- Money triggers (016): `validate_order_money()` (rejects negatives, zero-total-with-items, delivery fee >500, discount >99%) and `calculate_order_total()` (recomputes subtotal/discount/total from items JSONB + coupon), `to_paise`/`to_rupees` helpers.
- 36 index statements including partial indexes for rider availability and idempotency.
- Realtime publication (`supabase_realtime`): `orders`, `riders`, `coupons`.

### 4.5 Edge functions (Deno, service-role client, JWT-verified callers)

- **`accept-order`** — verifies caller JWT, derives rider id **server-side** from token, calls `accept_order()` RPC. Only path that can claim orders.
- **`create-order`** — JWT verify, non-empty items, **server-authoritative pricing** (unit price from DB: canonical `price` paise else `item_price*100`; qty clamped ≥1), delivery fee ₹30 / free ≥ ₹500, inserts into `orders` with status `pending_payment` (Online) or `pending` (COD).
- **`create-payment-link`** — JWT verify, ownership check, payability check (status ∈ pending_payment/pending), **exact-amount verification** against DB total, Razorpay `/v1/orders` API, stores `payment_intent_id` + `payment_status='created'`, returns `{orderId, amount, currency, keyId}`.

---

## 5. Frontend — 4 Flutter Apps + Shared Core

### 5.1 Shared `packages/anilunch_core` (pure Dart, dio 5.4 + web_socket_channel 3.0 only)

Hand-written models (no codegen, lenient JSON helpers in `money.dart`): `Item`, `Menu`, `DailyDeal` (catalog.dart); `Order`, `OrderItemSummary`, `CreateOrderRequest` (customizations as `Map<String,String>`, clients never set prices); `User`, `Notification`, `PaymentIntent`; `Rider`, `RiderOrder` (customer name/phone/coords); `Vendor`, `VendorOrder`, `VendorStats`; `Admin*`, `AppSettings`, `Page`, `DashboardStats`; `Money` (integer paise).

- `ApiClient` (dio): `{success, data, error}` envelope unwrapping, Bearer injection, single auto-refresh retry on 401/403, 429 → `RATE_LIMITED`, typed exceptions.
- `TokenManager`: access 15 min + refresh 7 day rotating, persistence delegated to app.
- `AniLunchApi` facade: catalog/orders/users/riders/vendors/payments/admin domain APIs.
- `RealtimeClient` (ws_client.dart): `ws://base/api/v1/ws?token=`, 30s ping, join/leave channels (`order:{id}`, `rider:{id}`, `vendor:{id}`, `riders.available`), control frames (joined/error/pong), typed events (`OrderWsEvent`, `RiderLocationWsEvent`).
- `SyncWorker` (sync_worker.dart): generic sync task abstraction — idempotent replay, max 5 attempts, backoff `[5s, 15s, 1m, 5m]`, 30s idle interval.

**Common bootstrap in every app:** `Supabase.initialize` → `AniApi.ensureInitialized()` → `exchangeForSession()` (swap Supabase JWT for Go tokens) → connect WS → persist tokens in SharedPreferences.

### 5.2 Customer app (`anilunch`)

- **Purpose/screens:** auth, home (responsive web: desktop nav >900px, mobile bottom nav), cart, orders, profile, edit information, lunch product details, checkout sheet, order success (confetti), review bottom sheet.
- **State:** dual — Provider 6 (ChangeNotifier: Auth/Menu/Cart/Lunch/Order providers) + Riverpod 2.5.1 (Drift-backed reactive streams: catalog, cart items, cart total paise, cart controller).
- **Deps:** supabase_flutter 2.16, flutter_riverpod 2.5.1, provider 6.1.5, drift 2.16 + drift_flutter, geolocator 13, permission_handler 11, image_picker, cached_network_image, uuid, url_launcher, video_player, confetti, google_fonts, flutter_dotenv, http, shared_preferences; dev: mockito, build_runner, drift_dev.
- **Connectivity:** Supabase (auth, direct reads of users/orders/meal_products/product_reviews, legacy order insert + Postgres-changes subscriptions); Go API (orders create/list/get/transition/cancel, catalog, payments create-intent); WS `order:{id}` (OrderProvider refetch; PaymentService races WS event vs 5s poll, 60 attempts).
- **Offline-first:** Drift tables (items, cart_items, orders, sync_queue); `SyncEngine` 30s periodic — pull catalog LWW upsert, drain outbound queue with exponential backoff capped 60s; `SecureOrderService.placeOrder` writes idempotent CreateOrderRequest; on network failure persists local draft + enqueues sync task (delivery fee rule mirrored locally: ₹30, free ≥₹500).
- **Features:** email/password auth, catalog + daily deals, item customization (spice/portion/notes), local-first cart (client UUIDs, zero latency), COD / Razorpay web checkout (JS interop) / UPI intent, real-time tracking, offline order drafts, reviews, guest mode.

### 5.3 Admin app (`anilunch_admin`)

- **Purpose/screens:** 6-view shell (drawer + bottom nav over IndexedStack): overview dashboard, menu management, order management, daily deals management, app settings, rider approvals, CMS pages, profile.
- **State:** Provider 6, single `AdminProvider` ChangeNotifier; no Riverpod.
- **Deps:** supabase_flutter 2.12, provider 6, drift 2.16, http, shared_preferences, image_picker, flutter_dotenv.
- **Connectivity:** Go-first with **Supabase-fallback** for every domain (dashboard/orders/users/riders/approval/items/menus/deals/settings/pages), then Drift cache. Supabase Realtime channels: `public:admin_orders`, `admin_riders`, `admin_menu`, `admin_deals` (all events → refetch).
- **Cache:** `AdminCache.fetchCacheFirst` — serve Drift instantly, refresh in background (stale-while-revalidate).

### 5.4 Rider app (`anilunch_rider`)

- **Purpose/screens:** login/signup (approval-gated via PendingApprovalPage), 3-tab shell (Requests/Deliveries/Earnings), dashboard (pulsing online button), active order page (Google Maps + polyline), new-order popup overlay (deduped, single popup at a time), profile, earnings. Dark theme (0xFF0A0A0A, orange seed 0xFFFF9100).
- **State:** Provider 6, `RiderStateProvider` ChangeNotifier.
- **Deps:** supabase_flutter 2.3, provider 6, drift 2.16, geolocator 13, google_maps_flutter 2.17, flutter_polyline_points, permission_handler 12, url_launcher, google_fonts 8, lucide_icons, intl, http, shared_preferences, flutter_dotenv.
- **Connectivity:** Go API (RidersApi: me/updateProfile/setAvailability/updateLocation/availableOrders/myOrders/acceptOrder; transitionOrder); WS `riders.available` (broadcast when any order ready_for_pickup) + `rider:{id}`; events carry status summaries only → full payload refetch before callbacks; Supabase fallback for legacy status updates.
- **Sync:** `RiderSyncEngine` 30s — pull assigned+available+active orders + profile into Drift OrderCache, drain SyncQueue (update_online/update_location) with backoff. `LocationTracker`: adaptive cadence 10s active / 30s idle, decoupled from order writes.
- **Features:** online/offline toggle, first-to-accept-wins, live GPS, deliveries history, earnings.

### 5.5 Vendor app (`anilunch_vendor`)

- **Purpose/screens:** 4-tab shell (dashboard/wallet/orders/profile) — today's sales + order count, active vs history order streams, wallet, store open/close toggle.
- **State:** **no state-management package** — StatefulWidgets + singleton services; live orders via ref-counted broadcast StreamControllers in `SupabaseService`.
- **Deps:** supabase_flutter 2.12, drift 2.16, image_picker, flutter_dotenv, http, shared_preferences, google_fonts 8 (dev has stray `supabase: any`).
- **Connectivity:** `VendorsApi` (me/updateProfile/orders/stats), `CatalogApi.items`, `OrdersApi.transition` (Go-first with Supabase fallback); WS `vendor:{id}` — cache-through stream: cached Drift rows instantly, refetch `/vendors/me/orders` on each OrderWsEvent, 30s safety-net poll, ref-counted (single WS join per vendor).
- **Features:** server-authoritative status transitions, new-order snackbars, cache-first cold start.

### 5.6 Platform targets & CI

All 4 apps target android, ios, web, windows, linux, macos.

| Workflow | Scope | Steps |
|---|---|---|
| `ci-cd.yml` | Full monorepo | Go 1.24: `go mod tidy` check, `go test -v -race ./...`, compose config validation; Flutter: analyze core + all 4 apps |
| `backend.yml` | backend/** | golangci-lint, tests vs PG16/Redis7/NATS 2.10 service containers, static binary build, Trivy SARIF scan → CodeQL, GHCR image push on main |
| `customer_app.yml` / `admin_app.yml` / `rider_app.yml` | per app | Gitleaks (full history), analyze, test + coverage (Codecov), release APK artifact |
| `vendor_app.yml` | vendor app | Gitleaks, analyze, APK build (**no test step**) |
| `supabase_deploy.yml` | supabase/** | Gitleaks, deploy 3 edge functions + `supabase db push` |

Go API deployment is manual via `deploy.sh` (GitHub Actions only builds the image).

---

## 6. Load Testing (k6)

- **Tool:** k6 ≥0.51 (local or `grafana/k6` container via compose profile).
- **Seed (`loadtest/seed.sql`):** idempotent — 8 vendors (id == auth user id), 24 approved riders, 8 categories, 400 meat items (₹300–₹1275), 40 lunch meal-products, 2 coupons (`LT10` percent, `LTFLAT` flat).
- **Auth:** JWTs minted in-script with shared HMAC secret (`loadtest/lib/helpers.js`) — no Supabase dependency; roles from seeded DB rows.
- **Scenarios (`scenarios.js`):** 7 traffic classes at real-world proportions — ≈50% browse / 25% menu / 10% search / 8% checkout / 4% tracking / 1.5% vendor / 1.5% rider — at tiers 1k/5k/10k/100k VUs. Checkout uses unique idempotency keys; some VUs cancel, some use coupon; tracking opens WS on `order:{id}`; vendor advances pending→preparing→ready_for_pickup; rider pushes GPS/availability/accepts/picks up/delivers.
- **Per-class scripts:** `browse.js`, `menu.js`, `search.js` (no dedicated search endpoint yet — repeated catalog reads), `cart_flow.js` (optional Razorpay create-intent with `CREATE_INTENT=1`), `tracking.js` (WS, p95 <1s, session ≥2s), `vendor_ops.js`, `rider_ops.js` (accept races → 409 tracked as check).
- **Pass criteria:** error rate <1%; reads p95 <250–300ms / p99 <500–600ms; writes p95 <400ms / p99 <800ms; WS connect+join p95 <1s, no slow-consumer evictions.
- **Status:** concurrency guards verified in code; **load tiers 1k–100k NOT yet executed** (checkboxes in `phase10-results.md` unchecked) — pending Docker stack + k6 run.

---

## 7. Evolution History — Phases 0–14

| Phase | Doc | What it did |
|---|---|---|
| **0** | `docs/repository-audit.md`, `docs/phase0-audit.md` (+ERRATA) | Full read-only audit: found client-authoritative money, open RLS, exposed keys, no local caching, unscoped realtime (SEC-01..10). Errata: migrations 012–016 broken (duplicate 010, FK-to-non-unique, `gen_random_uuid()` backfill, paise-in-rupees seeds, missing `discount_type`). |
| **1** | `docs/phase1-plan.md`, `phase1-report.md` | `git init` + baseline commit; migration lint gate (`migrate_lint_test.go`, 5 failing tests proving the broken chain); `supabase/integrity-check.sql`. |
| **2–9** | (no separate docs) | Security/RLS correction; self-hosted infra (Go API + compose + PgBouncer); Flutter cache-first (Drift) + sync; server-authoritative orders/payments (paise, state machine, idempotency); modular monolith modules; Redis caching; NATS JetStream events; realtime scoped subscriptions + WS gateway. |
| **10** | `phase10-results.md`, `loadtest/` | All 4 apps migrated to Go API; k6 suite delivered; R2 presigned uploads; concurrency guards verified in code; tiers not yet run. |
| **11** | `phase11-horizontal-scaling.md` | Statelessness audit; Caddy LB + 3 replicas; PgBouncer transaction pooling; WS-over-NATS cross-instance fan-out; autoscale rules (2-of-4 signals). |
| **12** | `phase12-read-replicas.md` | Application-level read/write split (`Pool` vs `Reader()`); standby bootstrap (`replica-init.sh`); lag monitoring. |
| **13** | `phase13-ha-dr-runbook.md` | RPO ≤15 min / RTO API ≤15s / RTO DB ≤5 min / RTO region ≤60 min; backup schedule 7d/4w/3m + WAL to R2 + PITR; failover procedures. |
| **14** | (no doc yet) | `deploy.sh` ("Phase 14 Cluster Deployment"), E2E tests, `ci-cd.yml`; post-13 commits: FCM push (018, internal/notifications), Razorpay checkout bridge, order history fixes, strict per-user order isolation (`19defec`). |

---

## 8. Known Issues / Risks

1. **Rider-broadcast consumer mis-wired:** JetStream consumer filters `orders.ready` (backend/internal/events/consumer.go:230) but transitions publish `orders.ready_for_pickup` (transitions.go:96) — NATS token matching means they never match. The WS bridge covers real fan-out, but the durable consumer is effectively dead for its purpose.
2. **Dead notification mappings:** `orders.out_for_delivery` / `orders.completed` referenced in `notificationForEvent` (consumer.go:35) are never published by any emitter.
3. **Migration history was broken:** duplicate `010`, FK-to-non-unique `orders(uuid_id)`, `gen_random_uuid()` backfill destroying id mapping, paise-in-rupees seeds (₹18,000 biryani), `016` referencing non-existent `discount_type`. Partially repaired in commit `4ae91fd` (2026-08-19); lint gate keeps it green; live-data mapping correctness still unproven. Regression file `20260727000000_vendor_orders_policy.sql` (wide-open `authenticated` policies) documented but removed by 011/015.
4. **RLS neutralization:** `USING (true)` public-read policies on `items`/`daily_deals` (007) OR-accumulate with stricter 014 filters — the strict filters have no effect.
5. **Fragile vendor identity heuristic:** policies on `vendor_orders`, `items`, `inventory_audit_log` match `vendors.name = auth.uid()::text` — essentially never matches real rows; only `orders.vendor_id = auth.uid()` is reliable.
6. **`audit_vendor_approval()` trigger** (015) reads `NEW.is_approved` but `vendors` has no such column → runtime error on any vendor UPDATE.
7. **`inventory_audit_log.item_id`** declared UUID FK to `items(id)` which is TEXT — type mismatch, FK unenforced.
8. **`users` table has no `ENABLE ROW LEVEL SECURITY`** in any migration.
9. **Dev fallbacks can mask outages:** services return in-memory fake orders/data when PG/Redis/NATS are down (orders/service.go:151–170, catalog default seeds); `RequireAuth` fail-open without Redis — risky in prod.
10. **WS auth skips the denylist:** gateway uses `ParseToken` only (gateway.go:57) — revoked access tokens can open sockets up to 15 min.
11. **Supabase dev fallback** parses unverified JWT claims when the HMAC secret doesn't match (tokens.go:100–105) — forgery risk if shipped.
12. **Dual money designs conflict:** 008 BIGINT paise columns + 015 INTEGER `total_amount_paise` + 016 trigger recompute + edge-function computed totals can disagree; correctness depends on trigger ordering.
13. **OpenAPI drift:** spec covers a subset of routes and mixes legacy rupee fields with paise convention.
14. **Docs drift:** no Phase 14 doc; `phase10-results.md` load tiers unchecked ("100k" claim unproven); no server-side deployment automation beyond `deploy.sh` (single-host compose; 3-node Redis/NATS, 2× LB, multi-region still deferred).
15. **Unused bits:** `create-payment-link` accepts `customerName/Email/Phone` but never uses them; doesn't write `payment_intents` table; vendor app has stray `supabase: any` dep; two sync generations coexist (generic core `SyncWorker` vs bespoke per-app `SyncEngine`).

---

## 9. Bottom Line

A well-architected food-delivery monorepo mid-migration from a thick-client/Supabase-first design to a server-authoritative Go API, with cache-first Flutter apps, idempotency, integer-paise money, NATS-bridged realtime, and a horizontal-scaling/HA story (Phases 11–14) — but with residual data-layer inconsistencies, a few dead/mis-wired event paths, fragile RLS heuristics, and unproven 100k load claims.