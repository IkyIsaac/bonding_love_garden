# Progress

Living tracker for the Bonding Love Garden build. Updated with every commit. Phases mirror the build order in [`docs/ARCHITECTURE_PLAN.md`](docs/ARCHITECTURE_PLAN.md#7-build-order--mapped-to-brief-9-with-changes-flagged) (§7), reconciled against what's actually shipped rather than the original week-by-week estimate.

**Current focus:** Mobile app (Phase 6) is underway — customer auth, role-gated routing, Home, and Family are live against the real backend. Next: Plans, then Wallet.

**Last updated:** Mobile Family tab — list, add, and edit family members (`family_members`), bottom sheet form matching the `customer_app_my_family` mockup, wired to real inserts/updates. `familyMembersProvider` is now shared between Home and Family so adding a member on one screen instantly reflects on the other. Verified end-to-end via `flutter run -d chrome` (no emulator/simulator set up on this machine yet), including the actual DB rows landing correctly.

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

### Visual rebuild on ReUI (shadcn/ui-based component library)

- [x] Bootstrapped shadcn/ui (`web/components.json`, "base-nova" preset — Base UI primitives, not Radix) and registered the `@reui` registry; free ReUI-branded components (`Badge`, `Alert`) live in `web/components/reui/`, everything else (`Dialog`, `Select`, `Table`, `Sidebar`, `AlertDialog`, `Avatar`, `DropdownMenu`, `Tooltip`, `Sheet`, `Sonner`, `InputOTP`, ...) came from the open shadcn base registry, which shares ReUI's "nova" style system — most of ReUI's own catalog is paid, so this app uses the free tier only, per the owner's choice
- [x] Botanical Play tokens reconciled into shadcn's semantic CSS variables in `globals.css` rather than accepting shadcn's generated neutral palette — `--primary`/`--accent`/`--destructive`/etc. now resolve to the Deep Green / Warm Pink brand palette; `--secondary` deliberately does NOT reuse Botanical's pink "secondary" token (that's `--accent`) since shadcn's `bg-secondary` means the neutral quiet-button role — a real naming collision caught and fixed after browser testing showed pink badges where neutral gray was expected
- [x] New branded sidebar app shell (`(dashboard)/layout.tsx`, `nav-menu.tsx`, `user-menu.tsx`) — deep-green `Sidebar` with pink active-item highlight, lucide icons per nav item, collapsible to icon-only with tooltips, `Avatar`+`DropdownMenu` for sign-out
- [x] Every shared primitive in `web/components/ui/` rebuilt on the new stack: `Modal` wraps `Dialog`, `DataTable` wraps `Table`, `fields.tsx` (`TextField`/`SelectField`/`CheckboxField`/`TextareaField`) wraps `Input`/`Select`/`Checkbox`/`Textarea`+`Label`, `DeleteButton` wraps `AlertDialog` instead of `window.confirm` — all keeping their original prop APIs so most page call sites didn't need to change; `Button`/`Card`/`Badge` call sites were updated directly to the canonical shadcn/ReUI shape instead, since those files are shared internally by every other installed component
- [x] `SelectField` accepts plain `<option>` children (never rendered as DOM, just read for `{value, label}`) so existing call sites didn't need to switch to `<SelectItem>` — Base UI's `Select` natively participates in `FormData` via a `name` prop, so every existing Server Action form kept working unchanged
- [x] Login page restyled onto `Card`/`Input`/`Button`, OTP step upgraded to a real `InputOTP` 6-box entry
- [x] All ten dashboard pages redesigned page-by-page and re-verified live in the browser

Real bugs found via this pass (Turbopack dev treats the whole route graph as one build, so nothing was even renderable in-browser until every page compiled — the bugs below only surfaced once that was true and pages could actually be clicked through):
- The `--color-secondary` naming collision above (pink badges instead of neutral)
- ReUI's Badge `-light`/`-outline` variants pair their status colors (`--success-foreground` etc.) with a *pale/translucent* background, not a solid one — these tokens needed to be a readable colored text, not white; the CLI's own generated `.dark` block for these tokens hinted at the correct pattern in hindsight
- `CardContent` is an unconstrained flex item of `Card` (`flex flex-col`) — a wide `DataTable` inside it inflated the whole card (and `SidebarInset`, and the page) past the viewport instead of scrolling internally; fixed with `min-w-0` at both levels, a classic flexbox gotcha
- `AlertDialogAction` is already a `<Button>` wrapper (accepts `variant` directly), not a `render`-polymorphic Base UI primitive like `AlertDialogTrigger` — passing `render={<Button variant="destructive" />}` was silently ignored, leaving delete-confirm buttons in the default (non-destructive) style

## Phase 5 — Documentation site

- [x] Docusaurus app scaffolded (`docs-site/`), default tutorial/blog content removed, Botonical branding/nav set up
- [x] Developer Guide: overview, database schema (incl. every bug found by testing), Edge Functions, web admin
- [x] User Guide: overview, admin dashboard usage
- [ ] Mobile app sections (Customer/Staff experience) — not written yet, nothing to document until those screens exist

Content gets filled in incrementally as features ship, not written all at once retroactively. What's there now is real reference content, not placeholder stubs.

## Phase 6 — Mobile app (§5)

- [x] Auth: phone OTP (`core/auth/`) — same mechanism as the web admin, no password/email anywhere
- [x] Role-gated router (`core/routing/app_router.dart`) — customer -> `CustomerShell`, staff roles -> placeholder, admin -> "use the web dashboard" screen
- [x] `CustomerShell` bottom nav (Home / Family / Plans / Wallet) via `StatefulShellRoute.indexedStack`, each tab keeping its own nav stack
- [x] Customer Home screen — welcome card (name + membership tier), family summary, live session card (countdown ticks client-side off `planned_end_at`, no polling), quick actions, recent activity from `notifications`; matches the `customer_app_home_dashboard` Stitch mockup
- [x] `google_fonts` added for real Montserrat/Inter (previously fell back to the platform default) — same two families the web admin pulls via `next/font/google`
- [x] Venue name/logo fetched from `venue_settings` at runtime for the login screen rather than hardcoded — `venue_settings_select` is intentionally world-readable (incl. anon) for exactly this
- [x] Family tab (`features/customer/family/`) — list, add, edit `family_members`; matches the `customer_app_my_family` mockup. No delete: `family_members_delete` is admin-only by RLS design, so the customer app was never going to offer it — a real constraint discovered while building, not an oversight.
- [ ] Plans, Wallet tabs (currently placeholder screens behind real nav)
- [ ] Checkout, wristbands (detail screen), memberships, reservations, packages, notifications
- [ ] Staff experience screens (auth, home, registration, sell, scanner, sessions, memberships, reports)

Verified against the real local Supabase instance: a fresh phone number (`255700000099`, local test-OTP allowlist) signs up through the actual `handle_new_user` trigger — new `auth.users` row, `profiles` row (`role: customer`, `approval_status: pending`), `families` row — then lands on a correctly-empty-state Home screen. Adding "Leo Jenkins" through the Family tab's form produced a real `family_members` row (verified via direct SQL) and instantly appeared in Home's family summary card, since both screens share `familyMembersProvider`. No emulator/simulator configured on this machine yet, so verification used Flutter's Chrome (web) target rather than a real device — worth a pass on an actual emulator once one's set up, since Flutter's web renderer isn't pixel-identical to mobile.

## Phase 7 — Integration, UAT, deploy (§7 weeks 7-8)

Not started.

---

## How this file gets updated

Each commit that changes what's done should update the relevant checkbox(es) here and the "Current focus" / "Last updated" lines at the top — part of the commit, not a separate step.
