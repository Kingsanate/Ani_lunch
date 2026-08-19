# AniLunch — Phase 1 Execution Plan: Critical Data & Database Corrections

**Status:** IN EXECUTION (2026-08-19 session) — verification tooling + audit corrections delivered; **no migration has been written or applied** (the existing `012–016` chain is broken — see `docs/phase0-audit.md` §E2 — and writing new SQL before staging validation is prohibited by the master prompt). STOP FOR APPROVAL at end.
**Based on:** `docs/phase0-audit.md` (VERIFIED findings) + its ERRATA §E1–E4 (migrations 012–016 discovered after the audit; chain 000→016 proven non-reproducible).
**Scope (per master prompt §5):** resolve the `users.id` / `orders.id` / `riders.id` / vendor ID type & FK inconsistencies. Do NOT cast/hide mismatches; pick a canonical type; align PostgreSQL + Go + API contract + Flutter models; gate any destructive migration behind backup → staging → integrity checks → endpoint tests → 4-app tests → rollback → approval.

---

## A. What must be fixed first (prioritized issue list)

1. **ID/FK inconsistency (P1 critical)** — `orders.id` is `TEXT`; `orders.user_id`/`orders.rider_id` are `TEXT` with **no foreign keys**; `users.id`, `vendors.id`, `riders.id` are `UUID`. `VERIFIED`. This breaks referential integrity (a typo'd `rider_id` is never rejected) and complicates the Go/Flutter models.
2. **`items.id` is `TEXT`** (`gen_random_uuid()::text`) while sibling tables use `UUID`. Broader, lower-priority; include in the same canonical decision but as a separate, later migration to limit blast radius.
3. **Migrations 010–016 are broken (P1 critical — NEW finding, VERIFIED)** — duplicate version `010`; `CREATE TABLE IF NOT EXISTS` type redefinitions that no-op on an existing DB; FKs to non-unique `orders(uuid_id)` (fails in Postgres); `uuid_id` random backfill destroys id mapping; `users.role` referenced but never guaranteed; `013` seeds paise into rupee columns (₹18,000 biryani); `016` references non-existent `orders.discount_type` and a `'price'` JSONB key the server never writes. Prior "ID fix" work is invalid and must be superseded.
4. **Canonical order state machine** (P2, but decisions here affect IDs/events) — current Go states diverge from target lifecycle (no `RIDER_ASSIGNED`/`OUT_FOR_DELIVERY`/`RESTAURANT_ACCEPTED`). Tracked, not fixed in P1.
5. **Payment confirmation/webhook path** (P3) — out of P1 scope; noted so ID work doesn't preempt it.

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
1. ~~Write the Phase 1 migration SQL files~~ **SUSPENDED** — the planned `012_identity_canonical.sql` name collides with the existing (broken) `012_users_pages_schema.sql`; a corrective migration would need the next free version and a valid staging baseline to test against. The master prompt prohibits writing untested fix migrations blind. A design (guarded, additive, `try_cast_uuid` backfill, unique-idempotency-index) is documented in the Phase 1 report but **not written** pending staging access.
2. **Migration lint/validation test** (DONE — `backend/internal/database/migrate/migrate_lint_test.go`): statically detects duplicate versions, FK-to-non-unique targets, references to columns never guaranteed to exist, paise-in-rupees seed values, and the 000-vs-010 `items.id` type conflict. Currently FAILING by design — it is the proof that the chain is broken and the CI gate that must turn green once `010–016` are corrected.
3. **Integrity-check script** (DONE — `supabase/integrity-check.sql`): read-only staging/live checks for orphaned `user_id`/`rider_id`, non-UUID `orders.id`, duplicate idempotency keys, money mismatches, PK types, RLS coverage, and the paise-in-rupees seed rows.
4. Align **Go model types** (`backend/internal/modules/orders/models.go`, `riders/models.go`, `users/models.go`) to the canonical type — NOT done yet; requires the Path A/B decision from live inspection.
5. Align **Flutter model types** in `anilunch_core/lib/src/models/*` and the 4 apps — NOT done yet; same dependency.
6. `git init` + initial commit (DONE — repo was not a git repo; `.gitignore` covers `.env`, build/, `.dart_tool/`, plus `.kilo/`; baseline committed, no secrets staged).
7. Write `docs/phase1-plan.md` (this file) + `docs/phase1-report.md` + audit errata (DONE).

**Cannot be validated here:** applying the migration, endpoint/4-app E2E, integrity checks against real data, backups.

---

## D. What requires a REMOTE Linux environment (not the laptop)

Per master prompt §7/§11/§22/§25 — Docker/Postgres/Redis/NATS stay on a remote VM; laptop only runs Flutter/Go/VS Code/Git.
1. Inspect **live Supabase schema + actual `orders.id` values** (decides Path A vs B) — run `supabase/integrity-check.sql` first.
2. Resolve the **broken 010–016 chain**: establish which chain the live DB was actually built from, then write + test the corrective migration (renumbered, e.g. `017_identity_canonical.sql`) on **staging/dev Postgres** (not prod).
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

- `go test ./...` green **except** the 5 migration-lint tests, which must turn green only after the `010–016` chain is corrected (they are the regression gate — see `migrate_lint_test.go`).
- `flutter analyze` green on all 4 apps (currently: customer 75 / rider 4 / vendor 11 / admin 11 — info-level only, no regressions).
- Corrective migration (e.g. `017`) applies cleanly to a fresh DB **and** to a copy of staging data.
- Integrity check script (`supabase/integrity-check.sql`): orphan `rider_id`/`user_id` → **0**; non-UUID `orders.id` sample recorded; duplicate idempotency keys → **0**; paise-in-rupees seed rows → **0**.
- Negative API test: `POST /api/v1/orders` with a non-existent `rider_id` → **rejected by FK** (not silently stored).
- Backward-compat: existing orders (pre-migration) still readable; legacy Flutter clients unaffected (expand-only migration, no column drops).
- Rollback verified: corrective migration is reversible (drop-added-constraints script) and restore from backup succeeds.

---

## I. Migration approach (safe, reversible, gated)

1. **First** establish the live DB's actual shape (`supabase/integrity-check.sql` on staging/Supabase read-only access) — decides Path A (UUID) vs Path B (TEXT) **and** whether `010–016` were applied.
2. New corrective migration (next free version, e.g. `017_identity_canonical.sql`) = **ADD** canonical columns/FKs only; never `DROP` legacy columns (expand-only, matches the `008` pattern); every risky step guarded by `DO`-block existence checks that skip instead of fail.
3. Backfill only if Path A (UUID) and values are UUID-shaped; use a `try_cast_uuid` helper + sync trigger, NOT `gen_random_uuid()` (that is the defect in `014`).
4. Apply to **staging**; run integrity + endpoint + 4-app tests; migration-lint tests must turn green.
5. Document rollback (`DROP CONSTRAINT` statements).
6. **STOP — await owner approval before any production apply.**

## J. Verification Status (this plan, 2026-08-19)

**VERIFIED:** ID/FK mismatch exists (migrations 000/008); migrations 010–016 are internally contradictory and non-reproducible (5-file evidence via `migrate_lint_test.go`, all failing); `users.role`/`valid_from`/`valid_until` are not guaranteed to exist; `013` seed prices are paise-in-rupees; `014`'s `uuid_id` backfill destroys id mapping; FKs target a non-unique column; `016` references `orders.discount_type`; Go builds clean, all non-lint Go tests pass; 4-app `flutter analyze` matches baseline.
**INFERRED:** UUID (Path A) is the preferable canonical if live ids are UUID-shaped; the broken `010–016` were probably written against a schema nobody could reproduce.
**UNKNOWN:** live `orders.id` value shapes; which migration chain the live DB was built from; whether `010–016` partially applied (dirty state); live RLS enforcement; actual orphan counts.

## Approval Gate

**STOP HERE — WAIT FOR USER APPROVAL.** This session delivered: git baseline (committed), migration-lint gate, integrity-check script, audit errata, plan + report updates. **Nothing was migrated or deployed; no Go/Flutter model types were changed.** Next steps require one of: (a) Supabase read access for `integrity-check.sql`, (b) a staging Postgres to validate the corrective migration, or (c) explicit approval to change Go/Flutter model types now.
