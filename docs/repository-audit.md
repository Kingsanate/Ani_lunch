# AniLunch / AniMeat — Phase 0 Complete Repository Audit Report
**Date:** 2026-08-18  
**Audit Type:** Complete Read-Only Codebase, Schema, Security, and Architecture Audit  
**Status:** COMPLETE (Read-Only)  
**Target:** Scale from 1 to 100,000+ concurrent active users with local-first, low-latency architecture.

---

## Executive Summary

A comprehensive, read-only audit of the entire `AniMeat` repository was conducted across all four Flutter applications (`anilunch`, `anilunch_rider`, `anilunch_vendor`, `anilunch_admin`), Supabase backend configurations, SQL migrations, Edge Functions, CI/CD pipelines, and local scripts.

The current architecture is a **direct-to-BaaS (Supabase) client-heavy model**, where Flutter clients communicate directly with PostgreSQL via PostgREST, calculate financial totals on device, manage table-wide Realtime subscriptions, and execute sensitive administrative actions via client-side anon keys.

While functional for small-scale development, the existing architecture contains **critical security vulnerabilities (open RLS policies, client-authoritative money calculations, exposed keys)** and **architectural bottlenecks (unscoped Realtime listeners, sequential network fetches, missing local caching, direct polling)** that will fail under load.

Below is the complete 35-point audit inventory required to execute the migration roadmap safely without breaking working production features.

---

## 1. Repository Structure & Workspace Layout

```
AniMeat/
├── .github/
│   └── workflows/
│       ├── admin_app.yml           # CI for anilunch_admin (builds release APK)
│       ├── customer_app.yml        # CI for anilunch (builds release APK)
│       ├── rider_app.yml           # CI for anilunch_rider (builds release APK)
│       └── supabase_deploy.yml     # Edge function deployment + DB push
├── anilunch/
│   └── anilunch/                   # Nested Customer Flutter Application
│       ├── lib/                    # Provider-based state, UI views, services
│       ├── test/                   # Unit & widget tests
│       ├── assets/                 # Static images and .env file
│       └── pubspec.yaml            # Dependencies (Provider, Supabase, etc.)
├── anilunch_rider/                 # Rider Flutter Application
│   ├── lib/                        # Location tracking, order acceptance, dashboard
│   ├── sql/                        # Orphaned SQL scripts (not in supabase/migrations)
│   └── pubspec.yaml                # Dependencies (Google Maps, Geolocator, etc.)
├── anilunch_vendor/                # Vendor Flutter Application
│   ├── lib/                        # Kitchen order status management, stats
│   ├── test_db*.dart               # 8 scratch test scripts with hardcoded anon JWTs
│   └── pubspec.yaml                # Misnamed package 'anilunch_admin'
├── anilunch_admin/
│   ├── anilunch_admin/             # Nested Admin Flutter Web/Mobile Application
│   │   ├── lib/                    # Product CRUD, deals, riders, app settings
│   │   │   └── main.dart.new       # Stray/duplicate source file
│   │   ├── sql/                    # Orphaned SQL scripts
│   │   └── pubspec.yaml
│   └── supabase/                   # Supabase CLI linkage artifacts (.temp)
├── supabase/
│   ├── functions/
│   │   ├── accept-order/index.ts   # Deno Edge Function (accepts order)
│   │   └── create-order/index.ts   # Deno Edge Function (creates order)
│   └── migrations/                 # 7 versioned SQL migrations
└── docs/
    ├── implementation-plan.md      # High-level architecture roadmap
    └── repository-audit.md         # This Phase 0 Audit Document
```

### Structural Hygiene Issues Identified:
1. **Double nesting**: `anilunch/anilunch` and `anilunch_admin/anilunch_admin` contain nested root folders.
2. **Missing CI workflow**: `anilunch_vendor` has no GitHub Actions CI workflow.
3. **Orphaned SQL scripts**: Migration files exist in `anilunch_rider/sql/` and `anilunch_admin/anilunch_admin/sql/` that are absent from `supabase/migrations/`.
4. **Stray files**: `main.dart.new` in admin app; `test_db.dart` through `test_db8.dart` in vendor app.
5. **Committed secrets**: `.env` files are tracked in Git in all 4 apps and bundled into Flutter assets.

---

## 2. Architecture Diagrams

### Current Architecture (Direct BaaS / Thick Client)
```
┌─────────────────┐   ┌──────────────────────┐   ┌──────────────────────┐   ┌────────────────────┐
│  Customer App   │   │      Rider App       │   │      Vendor App      │   │     Admin App      │
│ (Provider + UI) │   │ (Geolocator + Polling│   │ (Unfiltered Streams) │   │ (Anon Key Direct)  │
└────────┬────────┘   └──────────┬───────────┘   └──────────┬───────────┘   └─────────┬──────────┘
         │                       │                          │                         │
         │  Client Money Calc    │ Direct Status Updates    │ Direct Status Updates   │ Direct Schema CRUD
         ▼                       ▼                          ▼                         ▼
┌────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                    SUPABASE CLOUD                                              │
│  ┌──────────────────────┐   ┌────────────────────────┐   ┌──────────────────────────────────┐  │
│  │   PostgREST API      │   │ Realtime (Postgres CDC)│   │ Edge Functions (Deno)            │  │
│  │ (Direct Table CRUD)  │   │ (Table-wide Broadcast) │   │ (create-order, accept-order,     │  │
│  │                      │   │                        │   │  create-payment-link [cloud-only]│  │
│  └──────────┬───────────┘   └───────────┬────────────┘   └────────────────┬─────────────────┘  │
│             │                           │                                 │                    │
│             └───────────────────────────┼─────────────────────────────────┘                    │
│                                         ▼                                                      │
│                                 PostgreSQL Database                                            │
│                     (Conflicting RLS, missing base DDL in repo)                                │
└────────────────────────────────────────────────────────────────────────────────────────────────┘
```

### Target Architecture (Tiered, Local-First, High-Performance Monolith)
```
                                 CLOUDFLARE
                       DNS / CDN / WAF / DDoS / Edge Cache
                                     │
                                     ▼
                              LOAD BALANCER
                       (Traefik / Caddy / Managed LB)
                                     │
                 ┌───────────────────┼───────────────────┐
                 ▼                   ▼                   ▼
            Go API #1           Go API #2           Go API #N
         (Stateless Pod)     (Stateless Pod)     (Stateless Pod)
                 │                   │                   │
                 └───────────────────┼───────────────────┘
                                     │
                 ┌───────────────────┼───────────────────┐
                 │                   │                   │
                 ▼                   ▼                   ▼
           Redis Cache          WS Gateway         NATS JetStream
          (Hot Data, TTL,     (Scoped Fan-out,     (Durable Streams,
           Rate Limiting)      Zero DB Queries)     At-Least-Once Bus)
                 │                   │                   │
                 └───────────────────┼───────────────────┘
                                     │
                                     ▼
                            PgBouncer Pooler
                                     │
                 ┌───────────────────┴───────────────────┐
                 ▼                                       ▼
         PostgreSQL Primary                    PostgreSQL Replicas
      (Authoritative Transactions)            (Scale Read Traffic)
                                     │
                                     ▼
                       Cloudflare R2 + Media CDN

Flutter Architecture (All 4 Apps):
   UI ──► Riverpod ──► Repository ──► Drift SQLite (Local-First) ──► Sync Engine ──► Go API / WS Gateway
```

---

## 3. The Four Flutter Applications

| Application | Path | State Mgmt | Local Cache | Primary Responsibilities |
|---|---|---|---|---|
| **AniLunch Customer** | `anilunch/anilunch/` | `provider: ^6.1.5+1` | None (In-memory) | Restaurant & dish browsing, meal customizations, coupon validation, cart, order placement, review submission, address management. |
| **AniLunch Rider** | `anilunch_rider/` | `provider: ^6.0.0` | `shared_preferences` | Onboarding/registration, availability toggle, real-time order broadcast alerts, order acceptance, live navigation, status updates (`picked_up`, `delivered`). |
| **AniLunch Vendor** | `anilunch_vendor/` | `provider: ^6.0.0` | None | Kitchen dashboard, order preparation pipeline (`pending` ➔ `preparing` ➔ `ready_for_pickup`), sales stats, menu overview. |
| **AniLunch Admin** | `anilunch_admin/anilunch_admin/` | `provider: ^6.1.5+1` (via `admin_provider.dart`) | None | Dish & category management, daily deals configuration, rider approval/rejection, hero banner & video settings, legal pages editor. |

---

## 4. Backend Dependencies Inventory

1. **Supabase Auth (GoTrue)**: User signup, login via email/password, session persistence, JWT issuance.
2. **Supabase PostgREST**: Auto-generated REST API directly mapped to PostgreSQL tables (`orders`, `items`, `meal_products`, `riders`, `app_settings`, etc.).
3. **Supabase Realtime**: WebSocket connection streaming Postgres CDC events.
4. **Supabase Storage**: S3-compatible asset store (`assets`, `items`, `users` buckets).
5. **Supabase Edge Functions**: Deno TypeScript functions (`create-order`, `accept-order`, and Cloud-only `create-payment-link`).
6. **External UPI Payment Provider**: Invoked dynamically via Edge Function (exact gateway provider encapsulated in Cloud function).

---

## 5. Supabase API Call Inventory

| Component / File | Target Table / Object | Operation | Method | Payload / Query Filter |
|---|---|---|---|---|
| `auth_service.dart` (Customer) | `auth.users`, `users` | Auth / Insert | `signUp`, `signInWithPassword`, `insert` | User profile row creation |
| `menu_service.dart` (Customer) | `menus`, `items`, `daily_deals`, `app_settings` | Read | `.select().order(...)` | Full category, items, deals, settings fetch |
| `lunch_service.dart` (Customer) | `meal_products` | Read | `.select()` | Fetch lunch meals |
| `lunch_checkout_sheet.dart` (Customer) | `users`, `coupons`, `orders` | Read / Insert | `.select()`, `.insert()` | Fetches address, checks coupon validity, inserts direct order |
| `payment_service.dart` (Customer) | Edge Function `create-payment-link` | RPC / Invoke | `.functions.invoke(...)` | Passes `orderId`, `amount`, `customerEmail`, etc. |
| `payment_service.dart` (Customer) | `orders` | Read (Polling) | `.select('status').eq('id', ...)` | Polls every 5s for up to 5 mins |
| `order_service.dart` (Customer) | `orders` | Read / Insert / Update | `.select()`, `.insert()`, `.update()` | User order history, order creation, order cancel |
| `review_bottom_sheet.dart` (Customer) | `product_reviews` | Insert | `.insert()` | User rating and feedback |
| `edit_information_page.dart` (Customer) | `users`, Storage `users` | Upsert / Upload | `.update()`, `.uploadBinary()` | Profile data & avatar update |
| `auth_service.dart` (Rider) | `auth.users`, `riders` | Auth / Upsert | `signIn`, `signUp`, `.insert()`, `.update()` | Profile setup; auto-inserts into `riders` table |
| `rider_service.dart` (Rider) | `riders` | Update | `.update({'is_online': ...})`, `.update({'latitude': ..., 'longitude': ...})` | Toggles availability, updates GPS |
| `order_service.dart` (Rider) | `orders` | Read / Update | `.select('*')`, `.update({'rider_id': ..., 'status': 'accepted'})` | Queries available orders; direct status updates |
| `order_accept_service.dart` (Rider) | RPC `accept_order` | RPC | `.rpc('accept_order', ...)` | Executes atomic order claim |
| `supabase_service.dart` (Vendor) | `sellers`, `orders`, `meal_products` | Read / Update / Stream | `.select()`, `.stream()`, `.update()` | Fetches seller profile, streams all platform orders, updates status |
| `admin_provider.dart` (Admin) | `orders`, `riders`, `items`, `daily_deals` | Read / Write / Stream | `.select()`, `.insert()`, `.update()`, `.delete()`, `.channel()` | Full platform management |
| `rider_management_view.dart` (Admin) | `riders`, `orders` | Read / Update / Delete | `.select()`, `.update()`, `.delete()` | Rider approvals, deactivations |
| `app_settings_view.dart` (Admin) | `app_settings`, Storage `assets` | Upsert / Upload | `.update()`, `.insert()`, `.uploadBinary()` | App config & promo video upload |
| `pages_management_view.dart` (Admin) | `pages` | CRUD | `.select()`, `.insert()`, `.update()`, `.delete()` | CMS pages (Terms, Privacy, Refund) |

---

## 6. Database Table Reference Inventory

| Table Name | Referenced In | Primary Keys / Key Columns Observed | Description / Role |
|---|---|---|---|
| `orders` | All 4 Apps, Migrations 001, 002, 004, 005, 006 | `id` (TEXT/UUID mismatch), `user_id`, `rider_id`, `vendor_id`, `items`, `total_amount`, `status`, `order_time` | Core order entity |
| `riders` | Rider, Admin Apps, Migrations 006, `riders_setup.sql` | `id` (UUID), `name`, `phone`, `email`, `is_online`, `is_approved`, `approval_status`, `latitude`, `longitude` | Delivery rider profile |
| `items` | Customer, Admin Apps, Edge Function `create-order` | `id` (UUID/INT), `item_title`, `item_price`, `thumbnail_url`, `category_id`, `is_active` | Meat & grocery product catalog |
| `meal_products` | Customer, Vendor, Admin Apps, `add_options_columns.sql` | `id` (INT/UUID), `name`, `price`, `discount_price`, `rice_options`, `meat_options`, `is_available` | Lunch / bento meal product catalog |
| `menus` | Customer, Admin Apps | `id` (INT/UUID), `menu_title`, `image_url` | Category / menu taxonomy |
| `daily_deals` | Customer, Admin Apps | `id` (INT/UUID), `title`, `discount`, `deal_price`, `original_price`, `image_url`, `is_active` | Featured flash deals / promotions |
| `coupons` | Customer App (`lunch_checkout_sheet.dart`) | `id`, `code`, `discount_type`, `discount_value`, `min_order_amount`, `max_discount_amount`, `is_active`, `expiration_date` | Discount promo codes |
| `product_reviews` | Customer App (`review_bottom_sheet.dart`) | `id` (UUID), `product_id`, `user_id`, `rating`, `review_text`, `created_at` | Customer feedback and ratings |
| `users` | Customer, Admin Apps | `id`, `user_id` (UUID), `name`, `email`, `phone`, `address`, `created_at` | Customer metadata profile |
| `vendors` | Migration 005 (`005_vendor_app_schema.sql`) | `id` (UUID), `name`, `address`, `phone`, `location_lat`, `location_lng`, `is_open` | Vendor restaurant entity (in migration) |
| `sellers` | Vendor App (`supabase_service.dart`) | `id` (UUID), `name`, `email`, `phone`, `store_name` | Vendor restaurant entity (in Dart code) |
| `app_settings` | Customer, Admin Apps, Migration 003 | `id` (BIGINT), `home_video_url`, `show_hero_banner`, `hero_title`, `hero_subtitle`, `footer_copyright` | Dynamic UI branding & configuration |
| `pages` | Customer, Admin Apps | `id`, `slug`, `title`, `content`, `updated_at` | Static CMS pages |
| `store_settings` | Vendor App test script (`test_db7.dart`) | `id`, `is_open`, ... | Store settings table (unverified) |

---

## 7. Complete Migration Inventory

| Migration File | Contents & Scope | Anomalies / Risks |
|---|---|---|
| `001_accept_order_function.sql` | Defines `accept_order(UUID, UUID)` with `FOR UPDATE` lock and updates `orders.updated_at`. | Dropped and replaced in 006 because `orders.id` is `TEXT` and `updated_at` column did not exist. |
| `002_rls_policies.sql` | Basic RLS for customers, riders, admins on `orders`. | Overwritten by subsequent migrations; contains broad rider update rules. |
| `003_create_app_settings.sql` | Creates `app_settings` table and default row (id=1). | RLS allows public read; write restricted to `service_role`. |
| `004_orders_indexes.sql` | Indexes on `orders(user_id)`, `orders(rider_id)`, `orders(status)`, `orders(order_time DESC)`. | Helpful partial index on unassigned orders (`rider_id IS NULL`). |
| `005_vendor_app_schema.sql` | Creates `vendors` table, adds `vendor_id` to `products` and `orders`. | Uses table name `vendors` whereas Flutter Vendor app queries `sellers`. |
| `006_rider_broadcast_and_fixes.sql` | Redefines `accept_order(TEXT, TEXT)` and RLS policies on `orders` for riders. | Documents that `orders.id` is `TEXT` and `orders.updated_at` column does not exist. |
| `20260727000000_vendor_orders_policy.sql` | Adds vendor RLS policy on `orders`. | **CRITICAL FLAW:** `CREATE POLICY "Vendors read orders" ON public.orders FOR SELECT USING (auth.role() = 'authenticated');` allows ANY authenticated user to read all orders! |

---

## 8. Missing Database Objects (Repo vs. Reality)

The following database objects are referenced in application code but **have no DDL creation statements in `supabase/migrations/`**:

1. **`public.items` / `public.products`**: No table creation script in migrations (only an `ALTER TABLE products` in 005).
2. **`public.menus`**: No table creation script in migrations.
3. **`public.meal_products`**: No table creation script in migrations (only `ALTER TABLE` in `anilunch_admin/anilunch_admin/sql/add_options_columns.sql`).
4. **`public.daily_deals`**: No table creation script in migrations.
5. **`public.coupons`**: No table creation script in migrations.
6. **`public.product_reviews`**: No table creation script in migrations.
7. **`public.users`**: No table creation script in migrations.
8. **`public.pages`**: No table creation script in migrations.
9. **`public.sellers`**: Queried by Vendor app (`supabase_service.dart`), completely absent from migrations.
10. **Storage Buckets (`items`, `users`, `assets`)**: No bucket creation or bucket RLS scripts in migrations.
11. **Edge Function `create-payment-link`**: Missing from `supabase/functions/` (exists only in Supabase Cloud).

*Note: All missing items marked as **UNKNOWN — REQUIRES VERIFICATION** until exported directly from live PostgreSQL schema.*

---

## 9. RPC / Database Functions Inventory

1. **`accept_order(p_order_id TEXT, p_rider_id TEXT) -> JSONB`**:
   - **Defined in**: `006_rider_broadcast_and_fixes.sql`
   - **Language**: SQL (`SECURITY DEFINER`)
   - **Logic**: Atomically updates `orders` setting `rider_id = p_rider_id` and `status = 'accepted'` where `id = p_order_id`, `status IN ('ready_for_pickup', 'assigned')`, and `rider_id IS NULL OR rider_id = ''`.
   - **Usage**: Used in `supabase/functions/accept-order/index.ts` and `anilunch_rider/lib/services/order_accept_service.dart`.
2. **`get_schema`**:
   - **Referenced in**: `anilunch_vendor/test_db5.dart`
   - **Status**: UNKNOWN — REQUIRES VERIFICATION (likely a development debugging helper in Supabase Cloud).

---

## 10. Edge Functions Inventory

1. **`accept-order`** (`supabase/functions/accept-order/index.ts`):
   - Accepts `{ orderId, riderId }` JSON body.
   - Invokes `supabase.rpc('accept_order', ...)` using `SUPABASE_SERVICE_ROLE_KEY`.
   - Flaw: Does not verify caller auth token before executing.
2. **`create-order`** (`supabase/functions/create-order/index.ts`):
   - Accepts `{ userId, items, address, paymentMethod, customerLat, customerLng }`.
   - Reads item prices from `items` table, calculates subtotal, hardcodes `deliveryFee = 50`, sets `total_amount = subtotal + 50`.
   - Inserts order using `SUPABASE_SERVICE_ROLE_KEY`.
   - Flaws: Does not authenticate the caller; client can pass arbitrary `userId`. Floating point math used.
3. **`create-payment-link`**:
   - **Status**: MISSING FROM REPO (Cloud-only).
   - Contract deduced from `payment_service.dart`:
     - Input: `{ orderId, amount, customerName, customerEmail, customerPhone }`
     - Output: `{ url: 'https://...' }`

---

## 11. Payment Flow Audit

```
[Flutter Checkout Sheet]
   │
   ├─► 1. Calculates subtotal, delivery_fee (₹50), discount_amount, total_amount on device
   ├─► 2. Directly inserts order into `orders` table (status: 'pending_payment')
   ├─► 3. Calls `create-payment-link` passing client-computed `amount`
   ├─► 4. Launches returned URL in browser / UPI app
   └─► 5. Executes 5-second interval polling loop on `orders.status` for up to 5 minutes
```

### Critical Payment Vulnerabilities:
1. **Client-Dictated Price**: The client tells the payment link function what amount to charge. An attacker can modify client code to pay ₹1 for a ₹1,000 order.
2. **No Webhook Signature Verification in Repo**: Webhook handling is entirely in Supabase Cloud with no version-controlled code or idempotent signature checking.
3. **Direct Database Polling**: 10,000 concurrent checkout users polling every 5s will generate 2,000 queries/second against PostgreSQL directly.
4. **No Paired Idempotency**: Payment creation lacks idempotency keys; retrying can spawn multiple payment sessions for a single order.

---

## 12. Authentication & Session Flow

1. **Provider**: Supabase Auth (GoTrue).
2. **Mechanism**: Email + Password authentication (`signInWithPassword`, `signUp`).
3. **Storage**: JWT access token + refresh token persisted in device storage via `SharedPreferences`.
4. **Role Enforcement**:
   - **Customer App**: Uses `auth.currentUser`.
   - **Rider App**: Signs in via `AuthService.signInWithEmail`. If rider record is missing, auto-inserts an unapproved row into `riders`.
   - **Vendor App**: Signs in with `signInWithPassword`. Navigates directly to `MobileVendorShell` without verifying if the user is a vendor.
   - **Admin App**: Signs in with `signInWithPassword`. Navigates directly to `AdminShell` without verifying if the user has an admin role.
5. **Vulnerability**: Any registered customer can log into the Admin or Vendor apps and execute privileged queries.

---

## 13. RLS & Security Vulnerability Audit

| Vulnerability ID | Severity | File / Object | Description |
|---|---|---|---|
| **SEC-01** | **CRITICAL** | `20260727000000_vendor_orders_policy.sql` | `CREATE POLICY "Vendors read orders" ON public.orders FOR SELECT USING (auth.role() = 'authenticated');` allows any logged-in customer/rider to read all customer orders across the platform. |
| **SEC-02** | **CRITICAL** | `20260727000000_vendor_orders_policy.sql` | `CREATE POLICY "Vendors update orders" ON public.orders FOR UPDATE USING (auth.role() = 'authenticated');` allows any logged-in customer/rider to modify order status or details. |
| **SEC-03** | **CRITICAL** | `rider_approval_migration.sql` / `add_rider_approval.sql` | `CREATE POLICY "Admin can update any rider" ON public.riders FOR UPDATE USING (true);` allows ANY user to approve themselves as a rider or modify any rider row. |
| **SEC-04** | **CRITICAL** | `rider_approval_migration.sql` / `add_rider_approval.sql` | `CREATE POLICY "Admin can delete rider" ON public.riders FOR DELETE USING (true);` allows ANY user to delete any rider row. |
| **SEC-05** | **HIGH** | `005_vendor_app_schema.sql` | `CREATE POLICY "Allow authenticated full access to vendors" ON public.vendors FOR ALL USING (auth.role() = 'authenticated');` gives all users full write access to vendor records. |
| **SEC-06** | **HIGH** | `supabase/functions/create-order/index.ts` | Service role client executes without checking caller JWT or matching `userId` against `auth.uid()`. |
| **SEC-07** | **HIGH** | `supabase/functions/accept-order/index.ts` | Service role client executes without checking caller JWT or confirming caller is the claimed `riderId`. |
| **SEC-08** | **HIGH** | `.env` files in all 4 apps | Supabase Project URL and Anon JWT keys committed to version control and packaged into client app assets. |
| **SEC-09** | **MEDIUM** | `anilunch_admin/supabase/.temp/pooler-url` | Direct PostgreSQL pooler connection URL committed to repo. |
| **SEC-10** | **MEDIUM** | `anilunch_vendor/test_db*.dart` | 8 test scripts committed with active Supabase anon JWTs. |

---

## 14. Storage Bucket Audit

1. **`items`**: Stores dish photos and product catalog images. Public read. Uploads performed by Admin app.
2. **`users`**: Stores customer and rider profile avatars. Public read. Uploads performed by Customer app (`edit_information_page.dart`).
3. **`assets`**: Stores app video (`home_video_url`) and banner media. Public read. Uploads performed by Admin app.
4. **Bucket Policies**: UNKNOWN in version-controlled migrations — configured only in Supabase Cloud Dashboard.

---

## 15. Storage Policy Audit

- **Status**: UNKNOWN — REQUIRES VERIFICATION from live Supabase instance.
- **Risk**: Without explicit RLS policies defined in migrations, storage uploads could either fail on new environments or permit unrestricted file overwrites.

---

## 16. Realtime Subscription Audit

| App | Channel Name | Filter | Scalability Risk |
|---|---|---|---|
| **Vendor** | `public:orders` | None (all table events) | **Catastrophic**: Receives every order change on the platform. |
| **Vendor** | `orders` stream (`orders_tab.dart`) | None | **Catastrophic**: Streams whole table and filters client-side in Dart. |
| **Rider** | `ready_for_pickup_broadcast_$riderId` | None (`status == ready_for_pickup` checked in Dart) | **High**: Every online rider gets a WebSocket payload for every order update. |
| **Admin** | `public:admin_orders` | None | **Medium**: Table-wide order change listener. |
| **Admin** | `public:admin_riders` | None | **Medium**: Table-wide rider change listener. |
| **Admin** | `public:items_menu` | None | **Medium**: Table-wide items listener. |
| **Admin** | `public:admin_deals` | None | **Medium**: Table-wide deals listener. |
| **Customer** | `public:user_orders_$userId` | `user_id = $userId` | **Acceptable**: Scoped to user. |
| **Customer** | `public:menu_provider` | None | **High**: Every customer browsing menu subscribes to items table. |
| **Customer** | `public:lunch_provider` | None | **High**: Every customer browsing lunch subscribes to meal_products table. |

---

## 17. Order Lifecycle Analysis

### Status Flow Found in Codebase:
```
[Placed: COD / Online] 
   │
   ├─► 'pending_payment' ──(Payment Success)──► 'pending' / 'placed'
   │                                                 │
   ├─► 'pending' ──────────────────────────────► 'preparing' (Vendor accepts)
   │                                                 │
   └─► 'cancelled' (Customer/Admin)                  ▼
                                            'ready_for_pickup' (Food ready)
                                                     │
                                                     ▼
                                            'assigned' / 'accepted' (Rider claims)
                                                     │
                                                     ▼
                                            'picked_up' (Rider collects food)
                                                     │
                                                     ▼
                                            'out_for_delivery'
                                                     │
                                                     ▼
                                            'completed' / 'delivered'
```

### Inconsistencies & Flaws:
- Both `'delivered'` and `'completed'` are used interchangeably across apps.
- No database constraint or server-side state machine validates transitions (e.g. an order can jump from `pending` directly to `delivered`).
- Any client can update order status directly via PostgREST update.

---

## 18. Rider Lifecycle Analysis

1. **Signup**: Rider registers via app; creates row in `riders` with `is_approved = false`, `approval_status = 'pending'`.
2. **Approval**: Admin approves in admin app (`is_approved = true`, `approval_status = 'approved'`).
3. **Availability**: Rider toggles `is_online = true`.
4. **Discovery & Claiming**:
   - `ready_for_pickup` broadcast received.
   - Rider taps "Accept" -> invokes `accept_order` RPC or direct SQL update.
5. **Execution**: Rider marks `picked_up` -> `delivered`.
6. **Location Updates**: `RiderService.updateLocation` pushes latitude/longitude directly to `riders` table.

---

## 19. Vendor Lifecycle Analysis

1. **Authentication**: Logs in with email/password.
2. **Dashboard**: Loads stats (`getDashboardStats`) by querying all orders since midnight.
3. **Kitchen Queue**: Streams `orders` where status is `pending`, `preparing`, `ready_for_pickup`, `assigned`, `accepted`.
4. **Action**: Changes status to `preparing` or `ready_for_pickup`.
5. **Flaw**: Vendor queries `sellers` table, but migration created `vendors`. Dashboard queries sum platform-wide orders rather than vendor-specific orders.

---

## 20. Admin Lifecycle Analysis

1. **Authentication**: Logs in with email/password (no role verification).
2. **Dashboard**: Queries all orders and riders.
3. **Menu Management**: Creates, edits, deletes `items`, `menus`, `meal_products`, `daily_deals`.
4. **Rider Approvals**: Approves/rejects riders in `riders` table.
5. **Content & Settings**: Edits `app_settings` and CMS `pages`.
6. **Flaw**: Operates via client-side Supabase anon key relying on wide-open RLS policies.

---

## 21. Network Request Analysis

1. **Cold Start Waterfall**:
   - On customer app launch: `app_settings` + `menus` + `items` + `daily_deals` + `meal_products` + user address fetch sequentially.
   - Result: 6 separate HTTP roundtrips before home screen renders if cache is missing.
2. **Payment Polling**:
   - Single customer creates 60 HTTP requests (1 request every 5s for 5 mins).
   - 1,000 concurrent checkouts = 12,000 HTTP requests/min purely on status polling.
3. **Realtime Reconnect Storms**:
   - If mobile connection drops and reconnects, 3–6 Realtime channels per device resubscribe simultaneously.

---

## 22. Existing Caching Audit

1. **Image Caching**: `cached_network_image: ^3.4.1` used on product cards and checkout items.
2. **Session Caching**: Supabase Auth session cached in `SharedPreferences`.
3. **Data Caching**: **ZERO local database caching**.
   - No SQLite / Drift / Isar database exists in any of the 4 Flutter apps.
   - All models live only in ephemeral Dart memory inside Provider state.
   - App start or page refresh triggers full network fetch with loading spinners.

---

## 23. Performance Bottlenecks

1. **`SELECT *` in Production Endpoints**: Used in `OrderService.fetchAvailableOrders`, `AdminProvider.fetchAllOrders`, `menu_management_view`, etc.
2. **In-Memory Filtering on Mobile**: Vendor app streams all orders and filters statuses in Dart; Rider app receives all updates and filters in Dart.
3. **Direct Database Aggregations on Client**: Admin overview and Vendor dashboard fetch raw order rows and calculate daily revenue in Dart loops.
4. **High-Frequency GPS Writes to Main DB**: Rider location updates write directly to the `riders` PostgreSQL table.

---

## 24. Duplicate & Unsafe Implementations

1. **Rider Order Acceptance**:
   - `anilunch_rider/lib/services/order_service.dart` line 72: Executes direct SQL `.update()`.
   - `anilunch_rider/lib/services/order_accept_service.dart` line 7: Executes RPC `.rpc('accept_order')`.
   - Different screens in the same rider app use different acceptance logic!
2. **Theme & Login Duplication**:
   - `anilunch_vendor/lib/admin_theme.dart` is a copy-pasted duplicate of `anilunch_admin/admin_theme.dart`.
   - `anilunch_vendor/lib/views/login_view.dart` displays "AniLunch Admin" text and defaults to "admin@example.com".
3. **Model Fragmentation**:
   - `Order` in `anilunch/models/order.dart` vs `OrderModel` in `anilunch_rider/models/order.dart`.

---

## 25. Hard-Coded Business Rules

1. **Delivery Fee**: Hardcoded to `50` (₹50) in:
   - `anilunch/anilunch/lib/views/lunch_checkout_sheet.dart` (`final int _deliveryFee = 50;`)
   - `anilunch/anilunch/lib/models/order.dart` (`'delivery_fee': 50`)
   - `supabase/functions/create-order/index.ts` (`const deliveryFee = 50`)
2. **Payment Polling Limits**: Hardcoded to `60` attempts with `5` second delay in `payment_service.dart`.
3. **Hero & Footer Defaults**: Hardcoded defaults in SQL migration 003 (`'🔥 Fresh Meat Daily'`, `'© 2026 Anilunch'`).

---

## 26. Client-Side Financial Calculations

In `anilunch/anilunch/lib/views/lunch_checkout_sheet.dart`:
```dart
// Subtotal computed on client:
subtotal += (price as num).toInt() * quantity;

// Coupon discount computed on client:
if (type == 'flat') {
  calculatedDiscount = value.toInt();
} else if (type == 'percent') {
  calculatedDiscount = (subtotal * (value / 100)).toInt();
  if (maxDiscount != null && calculatedDiscount > maxDiscount) {
    calculatedDiscount = maxDiscount;
  }
}

// Final total computed on client:
final total = subtotal + _deliveryFee - _discountAmount;

// Inserted directly into PostgreSQL:
await Supabase.instance.client.from('orders').insert({
  'subtotal': subtotal,
  'delivery_fee': _deliveryFee,
  'discount_amount': _discountAmount,
  'total_amount': total,
  ...
});
```
**Risk**: Complete financial compromise. Client possesses full authority over order amount.

---

## 27. Secret & Credential Exposure Inventory

| Location | Item Exposed | Exposure Type | Action Required |
|---|---|---|---|
| `anilunch/anilunch/.env` | Supabase URL + Publishable Key | Committed to Git & bundled in assets | Remove from Git, rotate key |
| `anilunch_rider/.env` | Supabase URL + Anon Key | Committed to Git & bundled in assets | Remove from Git, rotate key |
| `anilunch_vendor/.env` | Supabase URL + Anon Key (JWT) | Committed to Git | Remove from Git, rotate key |
| `anilunch_admin/anilunch_admin/.env` | Supabase URL + Anon Key (JWT) | Committed to Git | Remove from Git, rotate key |
| `anilunch_vendor/test_db*.dart` | Supabase URL + Anon Key (JWT) | Committed to Git (8 files) | Delete scratch files, rotate key |
| `anilunch_admin/supabase/.temp/pooler-url` | Supabase Postgres Pooler URL | Committed to Git | Add `.temp` to `.gitignore` |

---

## 28. Type Inconsistencies Inventory

1. **`orders.id`**:
   - `001_accept_order_function.sql`: Declared as `UUID`.
   - `005_vendor_app_schema.sql`: References `orders.id` as `UUID`.
   - `006_rider_broadcast_and_fixes.sql`: Declares `orders.id` as `TEXT` ("Orders table columns confirmed: id (text)").
   - `OrderModel` in Dart: Parsed as `String`.
2. **`riders.id`**:
   - `riders_setup.sql`: `UUID PRIMARY KEY REFERENCES auth.users(id)`.
   - `OrderModel.riderId`: `String?`.
3. **Monetary Units**:
   - Stored as integers in some Dart code (`int total`), floating-point doubles in Edge functions (`product.item_price * qty`), and numeric/double in payment service (`double amount`). Must be unified to **integer paise**.

---

## 29. Database Schema Problems

1. **Missing Initial DDL**: No baseline schema script in version control.
2. **Conflicting Entity Names**: `vendors` (migration 005) vs `sellers` (vendor app code).
3. **Catalog Entity Ambiguity**: `items` (customer & admin apps, edge function) vs `products` (migration 005, test script).
4. **Missing Updated Timestamps**: `orders` table lacks `updated_at` column (explicitly noted in migration 006).
5. **Unconstrained Order Status**: `status` is a plain `TEXT` column without check constraints or enum enforcement.

---

## 30. Migration Risks & Guardrails

1. **Live Data Risk**: Altering `orders.id` or RLS policies in production could immediately disrupt active orders.
2. **Auth Token Invalidation**: Moving auth away from Supabase prematurely would log out all existing mobile users.
3. **Orphaned Edge Function Risk**: `create-payment-link` exists only in Supabase Cloud. Overwriting Cloud functions without capturing its code first would break online payments.
4. **Zero-Downtime Rule**: All schema migrations must follow the **Expand ➔ Migrate ➔ Switch ➔ Contract** pattern.

---

## 31. Recommended Migration Sequence

```
PHASE 0: Read-Only Repository Audit [COMPLETED]
   │
   ▼
PHASE 1: Database Source-of-Truth Recovery
   ├── Export complete live schema DDL from PostgreSQL (tables, columns, triggers, constraints)
   ├── Standardize tables into reproducible versioned migrations (resolve items vs products, sellers vs vendors)
   └── Capture `create-payment-link` Edge Function contract into Git
   │
   ▼
PHASE 2: Security, RLS & Code Hygiene
   ├── Patch open RLS policies (narrow vendor/admin order and rider policies)
   ├── Rotate exposed Supabase Anon keys; add `.env` and `.temp` to `.gitignore`
   ├── Remove test scratch scripts (`test_db*.dart`) and dead files (`main.dart.new`)
   └── Enforce basic server-side role validation
   │
   ▼
PHASE 3: Backend Foundation (Stateless Go Modular Monolith)
   ├── Scaffold Go backend structure (`cmd/server`, `internal/*`, `migrations`)
   ├── Configure Docker Compose (Go API + PostgreSQL + PgBouncer)
   └── Implement health check endpoints (`/health/live`, `/health/ready`)
   │
   ▼
PHASE 4: Flutter Local-First Architecture (Drift SQLite + Riverpod)
   ├── Add Drift SQLite local database to Flutter apps
   ├── Implement Riverpod reactive streams (UI observes Drift)
   └── Build background Sync Engine with mutation queue & idempotency keys
   │
   ▼
PHASE 5: Secure Server-Authoritative Orders & Payments
   ├── Implement server-side order creation in Go (integer paise, server price verification)
   ├── Implement strict order state machine
   └── Integrate payment gateway with idempotent webhook processing
   │
   ▼
PHASE 6: Redis Caching & Observability
   ├── Cache menus, products, and categories in Redis with TTL & stampede protection
   └── Integrate Prometheus metrics, Grafana dashboards, and structured JSON logs
   │
   ▼
PHASE 7: NATS JetStream Asynchronous Event Bus
   ├── Set up NATS JetStream durable streams for order lifecycle events
   └── Implement idempotent consumers for notifications, analytics, and dispatch
   │
   ▼
PHASE 8: WebSocket Realtime Architecture
   ├── Build Go WebSocket gateway for scoped client subscriptions (`order:{id}`, `rider:{id}`)
   └── Replace database polling and table-wide listeners with gateway event fan-out
   │
   ▼
PHASE 9: Cloudflare R2 Media & CDN Optimization
   ├── Migrate storage from Supabase Storage to Cloudflare R2
   └── Serve responsive WebP/AVIF images via CDN
   │
   ▼
PHASES 10–14: Performance Optimization, Load Testing & Concurrency Validation
   ├── Write k6 / Vegeta load test suites (1k ➔ 10k ➔ 100k users)
   ├── Benchmark p50, p95, p99 latencies, connection pools, and queue depths
   └── Validate horizontal failover and disaster recovery
```

---

## 32. What Can Be Migrated Immediately

- **Catalog Read Endpoints**: Read operations for `menus`, `items`, `meal_products`, `daily_deals`, `app_settings`, and `pages` can be served immediately by Go + Redis.
- **Flutter Local Caching**: Drift database tables can be added to Flutter to cache menus and dishes immediately without backend changes.
- **Repository Hygiene**: Deleting scratch scripts, removing committed `.env` files from Git history, and fixing `.gitignore`.

---

## 33. What Should Remain on Supabase Temporarily

- **Supabase Auth (GoTrue)**: Keep user login/signup on Supabase Auth in the short term while Go backend validates Supabase JWTs.
- **Supabase Storage**: Keep existing image URLs working while setting up R2 mirroring.
- **Legacy Order Read-Through**: Maintain read compatibility on the `orders` table during phased transition.

---

## 34. What Should Move to Go First

1. **`create_order` API**: Eliminate client-side money calculations immediately.
2. **`create_payment_link` & Payment Webhooks**: Move payment link generation and gateway callbacks to Go with integer paise and signature verification.
3. **`accept_order` & Status Transitions**: Replace direct PostgREST updates with authoritative Go endpoints enforcing state machine validation.

---

## 35. What Must NOT Be Changed Yet

1. **Do NOT drop or alter existing PostgreSQL columns on the live database** until Go API and Flutter clients are updated.
2. **Do NOT disable Supabase Realtime** before the Go WebSocket gateway and Flutter client subscription layer are deployed.
3. **Do NOT force a forced auth migration** that would invalidate active customer mobile app refresh tokens.
4. **Do NOT perform destructive schema refactors** without full database backups and rollback scripts.

---

## Phase 0 Gating Summary

- **Files Created**: `docs/repository-audit.md`
- **Files Modified**: None (Read-only audit)
- **Tests Executed**: Read-only codebase inspection, grep pattern matching, schema cross-reference.
- **Security Implications**: Identified 5 critical RLS vulnerabilities, hardcoded secrets, and client-authoritative financial calculation risks.
- **Performance Implications**: Identified unscoped Realtime subscriptions, 5-second polling loops, unindexed queries, and lack of local caching.
- **Next Phase**: **PHASE 1 — Database Source-of-Truth Recovery**.
