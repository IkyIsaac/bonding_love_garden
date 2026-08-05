# Progress

Living tracker for the Bonding Love Garden build. Updated with every commit. Phases mirror the build order in [`docs/ARCHITECTURE_PLAN.md`](docs/ARCHITECTURE_PLAN.md#7-build-order--mapped-to-brief-9-with-changes-flagged) (§7), reconciled against what's actually shipped rather than the original week-by-week estimate.

**Current focus:** Web admin dashboard is feature-complete for §6 (all 10 sidebar modules working against real data). Next up: mobile app, or UAT/polish on the web admin (real click-through visual QA is still lighter than the rest — see Phase 4).

**Last updated:** remaining §6 admin modules — Dashboard, Staff Management, Wristbands, Active Sessions (live), Reports, Audit Log — all built and verified against real, live-flow-generated demo data, in an actual browser.

---

## Phase 1 — Repo scaffold

- [x] Monorepo skeleton: `backend/` (Supabase), `web/` (Next.js), `mobile/` (Flutter), `docs/` (planning artifacts)
- [x] CI stubs for all three (`.github/workflows/`)
- [x] Botanical Play design tokens ported into Flutter (`mobile/lib/core/theme/app_theme.dart`)

## Phase 2 — Core Postgres schema (§3 of the architecture plan)

All 8 migrations applied and `db reset`-tested together; every table has RLS.

- [x] Identity & venue config — `profiles`, `families`, `family_members`, `venue_settings`, `zones`, `catalog_items`, `entry_fee_config` + RLS helpers (`is_staff`, `is_admin`, `owns_family`)
- [x] Plans, discounts, packages — `access_plans`, `access_plan_items`, `discount_rules`, `discount_rule_components`, `packages`, `package_items`
- [x] Data API grants fix (Supabase's newer default no longer auto-exposes tables to `anon`/`authenticated`)
- [x] Subscriptions, reservations, orders, payments — `subscriptions`, `reservations`, `orders`, `order_items`, `order_discount_applications`, `payment_providers`, `payments`, `payment_webhook_events`
- [x] Wallet, wristbands, sessions — `game_credit_ledger`, `wristbands`, `sessions` + `session_live_status` / `wristband_live_status` / `family_credit_balance` views (fixed a critical view RLS-bypass bug — views run as owner by default, needed `security_invoker = true`)
- [x] Notifications & audit log — `notifications`, `audit_log` (audit_log: admin can read, nobody incl. admin can write via the API)
- [x] `handle_new_user` metadata-timing fix (GoTrue does INSERT then a separate UPDATE for `app_metadata` — the bootstrap trigger now handles both)
- [x] `reservation_settings` (found missing while building `reservations-book` — brief §4.7 calls reservation rules owner-configurable, no config table existed for it)
- [x] `entry_fee_config` auto-close trigger (found missing while building the admin Plan Builder page — the table had no UPDATE policy at all by design, but nothing ever closed out the previous version's `effective_to` either; now automatic on insert)

## Phase 3 — Supabase Edge Functions (§4)

All of §4's function list is built and live-tested against a real local stack (not mocks).

- [x] `checkout-create-order` + shared discount engine (`_shared/discount-engine.ts`, `_shared/cart-pricing.ts`)
- [x] `discount-preview` (read-only twin, shares the same pricing pipeline)
- [x] `payments-initiate` + pluggable provider abstraction (`_shared/payments/`)
- [x] `payments-webhook-selcom` / `-snippe` / `-payguard` (provider implementations are labeled placeholders — no real API credentials/docs available yet, see code comments)
- [x] `processPaymentEvent` (idempotent; creates subscription + wristband on success)
- [x] `wristband-issue` (staff manual/complimentary issuance)
- [x] `session-scan-admit` (scan + admit/resume in one call)
- [x] `sessions-manage` (extend/end, supervisor/admin only)
- [x] `reservations-book` (entitlement + lead-time + per-day-cap validation)
- [x] `wallet-redeem` (credit redemption; wallet *earning* side is an open question — see below)
- [x] `notify-purchase-complete` — implemented inline in `processPaymentEvent` (creates the notification row; Realtime delivery works via the publication, actual FCM push is not built)
- [x] `admin-create-staff` (added for the web admin's Staff Management page — creates a real `auth.users` row via the GoTrue admin API, app_metadata-trusted role, same pattern as every other Edge Function)

### Known open gaps (flagged in code, not silently resolved)

- **Wallet crediting.** No rule exists yet for which purchased catalog items convert to how many wallet credits — brief §4.9 doesn't specify it precisely enough to implement without guessing at something that's effectively real money.
- **Package-only / entry-fee-only orders** don't get a subscription or wristband — only `access_plan` order_items map cleanly onto a subscription (packages have no validity period of their own).
- **`guest_pass` / `credit_topup`** checkout item types are rejected — neither has a canonical price source in the schema.
- **Payment providers are structurally real, not integration-real.** Selcom/Snippe/Payguard implement the same interface and the whole flow (initiate → webhook → processPaymentEvent) is proven end-to-end with a real HMAC-signed request, but the actual HTTP calls/field names are placeholders pending real API docs/credentials.
- **Reservation time-slot capacity** isn't modeled — nothing enforces "this game can only host N concurrent reservations."

## Phase 4 — Web admin dashboard (§6)

- [x] Botanical Play design tokens ported into web Tailwind config (`web/app/globals.css`, Tailwind v4 `@theme`)
- [x] Auth: phone OTP login (`/login`) + session middleware (`web/proxy.ts`) + admin-role gate in the `(dashboard)` layout
- [x] Shared CRUD UI components (`web/components/ui/`: Button, Card, Badge, Modal, DataTable, form fields, DeleteButton)
- [x] Settings page (`venue_settings`)
- [x] Plan Builder page (`catalog_items`, `access_plans` + included-items picker, `entry_fee_config`)
- [x] Discounts page (`discount_rules` + `discount_rule_components`, matching the discount engine's actual matching semantics)
- [x] Packages page (`packages` + `package_items` with per-item quantities)
- [x] Dashboard overview (guests in park now, revenue/plans sold today, memberships expiring within 7 days)
- [x] Staff Management (list + edit role/approval via direct Server Action; **creating** a new staff account needs a new Edge Function, `admin-create-staff` — the one write in this whole dashboard that can't go through a normal RLS-respecting client call, since it requires a real `auth.users` row via the GoTrue admin API)
- [x] Wristbands monitoring (`wristband_live_status`, search, admin revoke)
- [x] Active Sessions — live view: a client-side interval (catches pure time-based active→expiring_soon→expired transitions, which have no DB row change at all) plus a Realtime subscription on `sessions` (catches actual changes instantly) both just call `router.refresh()` rather than duplicating the status-computation logic client-side; extend/end via direct Server Action (admin is already included in `sessions`' RLS UPDATE policy alongside supervisor)
- [x] Reports (revenue/sessions today+this week, top plans by revenue, most popular games — aggregated in JS for now, not a SQL view/RPC; a deliberate, noted shortcut given how little data volume exists right now, not a reversal of the "aggregation belongs in SQL" principle)
- [x] Audit Log (filterable by action type + search, admin-only per RLS)

All ten pages verified in an actual browser this time (the Chrome extension connected mid-session) against demo data produced by **real system flows**, not just hand-inserted rows: two full checkout → payments-initiate → signed-webhook → session-scan-admit runs produced real orders/subscriptions/wristbands/sessions/audit_log entries; bulk variety (expiring-soon/expired/ended sessions, a declined order) was backfilled via direct SQL for speed. Live-tested interactions: extending a session from the Active Sessions page correctly flipped its status from "expiring soon" back to "active" in real time; creating a staff member through the UI correctly round-tripped through the new Edge Function and produced a real audit_log entry.

Two real bugs found via this pass, both fixed: entry_fee_config had picked up a stray 400x-too-large row at some point earlier in the session (root cause unclear — corrected via the proper insert-a-new-version path, which is itself real evidence the versioning design works); and `session-scan-admit` never actually updated `wristbands.last_scanned_at` despite the column existing for exactly that (brief §4.10 lists it explicitly) — caught because the Wristbands page showed "Never" for a wristband that had just been scanned twice.

## Phase 5 — Documentation site

- [x] Docusaurus app scaffolded (`docs-site/`), default tutorial/blog content removed, Botonical branding/nav set up
- [x] Developer Guide: overview, database schema (incl. every bug found by testing), Edge Functions, web admin
- [x] User Guide: overview, admin dashboard usage
- [ ] Mobile app sections (Customer/Staff experience) — not written yet, nothing to document until those screens exist

Content gets filled in incrementally as features ship, not written all at once retroactively. What's there now is real reference content, not placeholder stubs.

## Phase 6 — Mobile app (§5)

- [ ] Customer experience screens (auth, family, plans, checkout, wristbands, wallet, memberships, reservations, packages, notifications)
- [ ] Staff experience screens (auth, home, registration, sell, scanner, sessions, memberships, reports)

Scaffold exists (`mobile/lib/core/` + `mobile/lib/features/`), no screens built yet.

## Phase 7 — Integration, UAT, deploy (§7 weeks 7-8)

Not started.

---

## How this file gets updated

Each commit that changes what's done should update the relevant checkbox(es) here and the "Current focus" / "Last updated" lines at the top — part of the commit, not a separate step.
