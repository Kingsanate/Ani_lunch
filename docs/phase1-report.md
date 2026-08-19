# AniLunch — Phase 1 Report: Critical Data & Database Corrections

**Date:** 2026-08-19
**Phase:** 1 of 14 — Critical Data & Database Corrections (Iteration 1)
**Status:** STOP FOR APPROVAL — nothing deployed, no schema touched, no model types changed.

---

## 1. Objective

Resolve the ID/FK inconsistencies (`users.id`/`orders.id`/`riders.id`/vendor IDs: `UUID` vs `TEXT`, missing foreign keys) per the Phase 1 execution plan, without rewriting the backend, without destructive changes, and with every step validated per the master prompt's gates.

## 2. What actually happened (honest summary)

The Phase 0 audit assumed the repo was "migrations 000–011, ID/FK unresolved, no API contract." Verification this session found **the audit's inventory was truncated** and the real state is worse:

- **Migrations 012–016 exist and are broken.** They are a prior, unvalidated attempt at exactly this Phase 1 work. Static verification proves the chain `000→016` **cannot apply cleanly** and is not reproducible on any database.
- The repo was **not a git repository** and had **no commit history** — the master prompt's git/CI baseline requirement was unfulfilled.
- The migration chain is the single biggest risk to the project and is the reason this phase exists.

## 3. Changes made (non-destructive, all on this machine)

| # | Change | Type |
|---|---|---|
| 1 | `git init` + initial baseline commit (814 files). `.gitignore` extended with `.kilo/`; verified no `.env`/`.pem`/`.key`/`.p12` staged | Baseline |
| 2 | `backend/internal/database/migrate/migrate_lint_test.go` — migration-chain lint gate (5 tests) | Verification tooling |
| 3 | `supabase/integrity-check.sql` — read-only staging/live integrity checks | Verification tooling |
| 4 | `docs/phase0-audit.md` — ERRATA §E1–E4 documenting 012–016, duplicate `010`, `openapi.yaml`, and the broken-chain proof | Docs |
| 5 | `docs/phase1-plan.md` — updated status, issue list, migration approach, approval gate | Docs |
| 6 | `docs/phase1-report.md` — this report | Docs |

**Deliberately NOT done:** writing a corrective migration, changing Go/Flutter model types, touching Supabase. Rationale: the master prompt prohibits blind fix-migrations without a staging baseline; the planned `012_identity_canonical.sql` name collides with the existing (broken) `012`.

## 4. Files

- `backend/internal/database/migrate/migrate_lint_test.go` (new)
- `supabase/integrity-check.sql` (new)
- `docs/phase0-audit.md` (errata appended)
- `docs/phase1-plan.md` (updated)
- `docs/phase1-report.md` (this file)
- `.gitignore` (added `.kilo/`)
- git: baseline commit `HEAD` on `master` (initial commit)

## 5. The migration-chain defect (the finding that matters)

| # | Defect | Location | Effect |
|---|---|---|---|
| D1 | Duplicate version `010` (two files) | `010_menus_items_deals_schema.sql`, `010_sellers_vendors_reconciliation.sql` | ambiguous apply order |
| D2 | `CREATE TABLE IF NOT EXISTS` redefines `menus.id`/`items.id`/`daily_deals.id`/`coupons.id` as UUID | `010` | no-op on a DB built from `000` (BIGINT/TEXT); `category_id UUID REFERENCES menus(id)` fails on type mismatch |
| D3 | RLS policies reference `users.role` | `010`, `012`, `014` | `role` is only inside `CREATE TABLE IF NOT EXISTS users` — no-op → policies fail on an existing-DB chain |
| D4 | `orders.uuid_id` backfilled with `gen_random_uuid()` | `014` | random UUIDs unrelated to existing TEXT ids; id mapping destroyed, nothing keeps them in sync |
| D5 | FKs target `orders(uuid_id)` with no unique index | `014`, `015` | Postgres refuses FK to non-unique column → migration fails |
| D6 | Seed writes paise as rupees | `013` | ₹18,000 biryani, ₹8,000 chai, ₹10,000 coupon minimum |
| D7 | `016` references `orders.discount_type` (no such column) + `items->>'price'` key the server never writes | `016` | runtime error on coupon orders; NULL subtotal → order creation breaks |
| D8 | Vendor policy compares `vendors.name = auth.uid()::text` | `010`, `014` | matches nothing — broken vendor authorization by design |

**Proof:** `go test ./internal/database/migrate/` fails all 5 lint tests with these exact findings (see §7).

## 6. Database

- **No DDL was executed anywhere** (no local Postgres exists; nothing was applied remotely).
- Existing schema on paper: `000` (BIGINT/TEXT ids, no order FKs), `010–016` (contradictory UUID attempt). Live DB shape: UNKNOWN.
- Integrity-check SQL is ready to run on staging/Supabase read access: orphans, UUID-shape, idempotency duplicates, money mismatches, PK types, RLS coverage, seed corruption.

## 7. Tests

| Test | Result |
|---|---|
| `go build ./...` | PASS (clean) |
| `go test ./...` (all packages except migrate-lint) | PASS (11 packages) |
| `go test ./internal/database/migrate/` (lint gate, 5 tests) | **FAIL BY DESIGN** — proves D1, D5, D3, D6, D2 with file:line evidence; must turn green only after the chain is corrected |
| `flutter analyze` customer / rider / vendor / admin | 75 / 4 / 11 / 11 issues — identical to baseline, no regressions |

## 8. Performance / Load

Not tested — no DB exists locally; k6/Docker absent on this machine. Load testing is scheduled for a remote Linux/CI environment (per master prompt §25), not the laptop.

## 9. Security

- Staged files verified: **no secrets** (`.env` files contain only public keys: `SUPABASE_URL`, anon/publishable key, `API_BASE_URL`).
- `.gitignore` covers `.env`, build artifacts, `.dart_tool/`, `.kilo/`.
- D8 (broken vendor authz policy) is a security defect in the chain — documented, not exploitable before the chain is fixed.
- No credentials were requested or introduced.

## 10. Risks

| Risk | Severity | Mitigation |
|---|---|---|
| Live DB is in a dirty/partially-applied state from 010–016 | HIGH | `integrity-check.sql` first; never apply anything without a backup |
| Corrective migration written blind fails like 010–016 did | HIGH | No migration is written until staging access; guarded `DO`-block pattern mandated in plan §I |
| Path A (UUID) chosen but live ids aren't UUID-shaped | MEDIUM | Decision gated on live inspection; Path B (TEXT) is the fallback |
| Owner unaware of the broken chain (audit said "unresolved", truth is "attempted and botched") | MEDIUM | This report + audit errata |

## 11. Rollback

Nothing was deployed, so no rollback is needed. Future corrective migration will ship with explicit `DROP CONSTRAINT`/reverse statements + backup-before-apply, per plan §I.5.

## 12. Remaining (gated on remote access / approval)

1. Run `supabase/integrity-check.sql` against live/staging DB (needs Supabase **read** access) → decides Path A/B and reveals whether 010–016 partially applied.
2. Renumber `010_sellers_vendors_reconciliation.sql` (or merge) to eliminate D1.
3. Write corrective migration (`017_identity_canonical.sql` or similar): additive, guarded, `try_cast_uuid` backfill + sync trigger (fixing D4), unique index on `uuid_id` (fixing D5), `ALTER TABLE ... ADD COLUMN IF NOT EXISTS role/valid_from/valid_until` (fixing D3), correct seed prices (fixing D6), rewrite `016` (fixing D7), fix vendor policy (fixing D8).
4. Apply on staging → re-run lint gate (must go green) → endpoint negative tests → 4-app E2E → backup/restore drill.
5. Align Go + Flutter model types to the chosen canonical.
6. **STOP for approval before production apply.**

## 13. VERIFIED / INFERRED / UNKNOWN

- **VERIFIED:** git baseline absent (now committed); migrations 012–016 exist and break the chain (D1–D8, evidence-backed by failing lint tests); Go builds clean; all non-lint Go tests pass; 4-app `flutter analyze` at baseline; no secrets in staged files.
- **INFERRED:** `010–016` were written against an imagined schema, never validated; live DB likely matches either `000`-chain or `010`-chain, not both.
- **UNKNOWN:** live `orders.id` shapes (Path A vs B); which chain the live DB was built from; partial-application/dirty state; real orphan counts; actual RLS state.

## 14. Approval Gate

**STOP — awaiting owner decision.** Requested to proceed:
1. **Supabase read access** (DB connection string or project ref) to run `supabase/integrity-check.sql` — read-only, this is the cheapest way to unblock the entire phase, or
2. a **staging Postgres** (e.g. the remote Linux VM) to validate the corrective migration, or
3. explicit approval to change Go/Flutter model types now (Path decision without live data — NOT recommended).