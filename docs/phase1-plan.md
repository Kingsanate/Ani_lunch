# AniLunch — Phase 1 Execution Plan: Critical Data & Database Corrections

**Status:** PLAN ONLY — no destructive changes executed. STOP FOR APPROVAL at end.
**Based on:** `docs/phase0-audit.md` (VERIFIED findings).
**Scope (per master prompt §5):** resolve the `users.id` / `orders.id` / `riders.id` / vendor ID type & FK inconsistencies. Do NOT cast/hide mismatches; pick a canonical type; align PostgreSQL + Go + API contract + Flutter models; gate any destructive migration behind backup → staging → integrity checks → endpoint tests → 4-app tests → rollback → approval.

---

## A. What must be fixed first (prioritized issue list)

1. **ID/FK inconsistency (P1 critical)** — `orders.id` is `TEXT`; `orders.user_id`/`orders.rider_id` are `TEXT` with **no foreign keys**; `users.id`, `vendors.id`, `riders.id` are `UUID`. `VERIFIED`. This breaks referential integrity (a typo'd `rider_id` is never rejected) and complicates the Go/Flutter models.
2. **`items.id` is `TEXT`** (`gen_random_uuid()::text`) while sibling tables use `UUID`. Broader, lower-priority; include in the same canonical decision but as a separate, later migration to limit blast radius.
3. **Canonical order state machine** (P2, but decisions here affect IDs/events) — current Go states diverge from target lifecycle (no `RIDER_ASSIGNED`/`OUT_FOR_DELIVERY`/`RESTAURANT_ACCEPTED`). Tracked, not fixed in P1.
4. **Payment confirmation/webhook path** (P3) — out of P1 scope; noted so ID work doesn't preempt it.

---

## B. Canonical identifier strategy (recommendation — decision pending live inspection)

**Recommendation: standardize on `UUID` for all entity identity** (users/vendors/riders are already `UUID`; make `orders.id` + `orders.user_id`/`rider_id` `UUID` with real FKs). Rationale: Postgres-native, matches 3 of 4 tables, no custom parsing in Go/Flutter.

**Honest caveat (do NOT assume):** converting `orders.id TEXT → UUID` is only safe if **every existing `orders.id` value is a valid UUID** (many apps generate UUID-shaped strings, but this is `UNKNOWN` without the live DB). If live values are non-UUID custom strings, the safe canonical becomes **`TEXT` everywhere** (convert `riders.id`/`users.id` references to `TEXT` + FK). The binding decision requires inspecting live data on the remote/Supabase environment first.

**Plan therefore has two paths; remote inspection picks one:**
- **Path A (preferred):** `orders.id UUID PK`; add `FK (user_id → users.id)`, `FK (rider_id → riders.id)`, keep `vendor_id UUID FK` (already present). `items.id` → `UUID` in a follow-up migration.
- **Path B (fallback if ids aren't UUID-shaped):** keep `TEXT` ids but add proper `FK` constraints and standardize all Go/Flutter model types to `String` consistently.

Either way: **add the missing FKs** (the actual integrity bug) and **make Go + Flutter model types consistent** with the chosen canonical.

---

## C. What can be done on the CURRENT machine (Go 1.26.5 + Flutter 3.47.0)

Non-destructive, compilable, testable here:
1. Write the Phase 1 migration SQL files (`supabase/migrations/012_identity_canonical.sql`) — **additive + FK additions only**; no `DROP`/data loss. (Applied later on staging, not here.)
2. Align **Go model types** (`backend/internal/modules/orders/models.go`, `riders/models.go`, `users/models.go`) to the canonical type; ensure `go build` + `go test ./...` stay green.
3. Align **Flutter model types** in `anilunch_core/lib/src/models/*` and the 4 apps; ensure `flutter analyze` stays green.
4. Add a **migration dry-run / integrity-check test** (parse SQL, assert FK presence) — pure-Go, runs here.
5. Write `docs/phase1-plan.md` (this file) + update issue list.
6. (On approval) `git init`, initial commit, and add CI YAML (`.github/workflows/*` already partially exist) — non-destructive baseline.

**Cannot be validated here:** applying the migration, endpoint/4-app E2E, integrity checks against real data, backups.

---

## D. What requires a REMOTE Linux environment (not the laptop)

Per master prompt §7/§11/§22/§25 — Docker/Postgres/Redis/NATS stay on a remote VM; laptop only runs Flutter/Go/VS Code/Git.
1. Inspect **live Supabase schema + actual `orders.id` values** (decides Path A vs B).
2. Apply `012_identity_canonical.sql` on a **staging/dev Postgres** (not prod).
3. Run integrity checks: zero orphan `rider_id`/`user_id`; all `orders.id` valid per canonical type.
4. Run endpoint tests (order create with invalid `rider_id` **must fail**); run all 4 Flutter apps against staging.
5. Backup + restore drill; document rollback.
6. (Later phases) load tests, failover, R2, Cloudflare.

---

## E. Credentials / access required from the owner

| Need | When | Scope |
|---|---|---|
| Supabase **read** access (DB connection string / project ref) | Phase 1 remote inspection | read-only |
| Remote Linux VM (Docker, Postgres, Redis, NATS, PgBouncer) | Phase 1+ infra | staging |
| Razorpay **test** keys (sandbox) | Phase 3 | dev/staging only |
| Scoped **Cloudflare API Token** (not master key) | Phase 10 (Cloudflare) | scoped |
| R2 credentials (scoped) | Phase 4/8 | staging |
| Production secrets | NEVER on laptop; owner-retained | prod isolated |

No production payment/DB/R2/master keys are requested now.

---

## F. What can remain on Supabase temporarily

- **Auth** — until Go JWT path is proven end-to-end.
- **PostgreSQL (Supabase)** — through the transition stage (Go API → Supabase PG).
- **Storage** — until R2 verified + media migrated + URLs updated + apps tested.
- **Realtime (Supabase)** — until Go WS/NATS chosen as the single canonical path.
- **Edge Functions** — until Go API modules reach parity.

---

## G. What will eventually be removed from Supabase (only after verified replacement + approval)

1. Supabase Realtime → Go WS/NATS (Phase 9).
2. Supabase Storage buckets → Cloudflare R2 (Phase 4/8).
3. Edge Functions (`create-order`/`create-payment-link`/`accept-order`) → Go API modules (Phase 3/6).
4. Supabase Auth → self-managed Go JWT (Phase 2/6).
5. Supabase PostgreSQL → self-managed PG behind PgBouncer (Phase 3/12) — final.

---

## H. Tests that prove Phase 1 is complete

- `go test ./...` green after model alignment.
- `flutter analyze` green on all 4 apps.
- Migration `012` applies cleanly to a fresh DB **and** to a copy of staging data.
- Integrity check script: `SELECT count(*) FROM orders WHERE rider_id IS NOT NULL AND rider_id NOT IN (SELECT id FROM riders)` → **0**; same for `user_id`.
- Negative API test: `POST /api/v1/orders` with a non-existent `rider_id` → **rejected by FK** (not silently stored).
- Backward-compat: existing orders (pre-migration) still readable; legacy Flutter clients unaffected (expand-only migration, no column drops).
- Rollback verified: `012` is reversible (drop-added-constraints script) and restore from backup succeeds.

---

## I. Migration approach (safe, reversible, gated)

1. New migration `012_identity_canonical.sql` = **ADD** canonical columns/FKs only; never `DROP` legacy columns (expand-only, matches the `008` pattern).
2. Backfill only if Path A (UUID) and values are UUID-shaped.
3. Apply to **staging**; run integrity + endpoint + 4-app tests.
4. Document rollback (`DROP CONSTRAINT` statements).
5. **STOP — await owner approval before any production apply.**

---

## J. Verification Status (this plan)

**VERIFIED:** ID/FK mismatch exists (migrations 000/008); Go + Flutter build/analyze currently green; missing FKs are the defect.
**INFERRED:** UUID is the preferable canonical; Path A is safe if live order ids are UUID-shaped.
**UNKNOWN:** live `orders.id` value shapes; live RLS enforcement; whether any app hard-codes UUID vs TEXT assumptions in a way that breaks on conversion.

---

## Approval Gate

**STOP HERE — WAIT FOR USER APPROVAL** before: applying any migration, changing Go/Flutter model types, `git init`, or touching Supabase/prod. Confirm which path (A/B) after remote inspection, or authorize the remote inspection step first.
