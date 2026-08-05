# Progress

Living tracker for the Bonding Love Garden build. Updated with every commit. Phases mirror the build order in [`docs/ARCHITECTURE_PLAN.md`](docs/ARCHITECTURE_PLAN.md#7-build-order--mapped-to-brief-9-with-changes-flagged) (§7), reconciled against what's actually shipped rather than the original week-by-week estimate.

**Current focus:** Web admin config CRUD done; next up is either the remaining §6 admin modules (staff management, session/wristband monitoring, reports, audit log viewer) or starting the mobile app.

**Last updated:** web admin config CRUD (Settings, Plan Builder, Discounts, Packages) + auth + Docusaurus documentation site scaffolded with initial Developer/User Guide content.

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
- [ ] Staff management, wristband/session monitoring, reports, audit log viewer — not started (remaining §6 modules)

All four CRUD pages verified end-to-end against a real local stack: real OTP login, every mutation exercised through the exact authenticated REST path the Server Actions use (not simulated), RLS negative case confirmed (non-admin blocked with a real 403), middleware redirect behavior confirmed. Literal click-through browser verification (screenshots, visual QA) wasn't possible this session — the Chrome automation extension wasn't connected — so visual/UX review of these pages is still outstanding.

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
