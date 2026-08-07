# Progress

Living tracker for the Bonding Love Garden build. Updated with every commit. Phases mirror the build order in [`docs/ARCHITECTURE_PLAN.md`](docs/ARCHITECTURE_PLAN.md#7-build-order--mapped-to-brief-9-with-changes-flagged) (§7), reconciled against what's actually shipped rather than the original week-by-week estimate.

**Current focus:** The mobile customer experience is feature-complete except notifications. The staff experience now covers the whole front-desk loop: scan-and-admit, session management, customer registration/approval, customer lookup, and staff-assisted selling all work end to end against the real backend. Only Reports remains a placeholder.

**Last updated:** Mobile staff experience, batch 2 — Registration, Customer Lookup, Sell. Registration (`features/staff/registration/`) lists pending customer accounts and approves/rejects them via a new Edge Function, `staff-approve-customer` — closing the gap flagged in batch 1 (there was no UI path to approve a customer at all). Customer Lookup (`features/staff/customers/`) searches customers by phone and shows one family's members/memberships/wristbands read-only — this doubles as the "staff Memberships" capability and as Sell's entry point (staff need to identify who they're selling to first). Sell (`features/staff/sell/`) reuses the exact customer-checkout pipeline (`discount-preview` -> `checkout-create-order` -> `payments-initiate`, `channel: 'staff_app'`) rather than inventing a cash-settlement path — the customer still pays with their own phone at the counter, per an explicit choice made with the user before building this (the alternative, a synchronous 'cash' payment provider, would have meant touching the shared `PaymentProvider` interface and `processPaymentEvent`, the core of an already-proven pipeline, for no clear win). Packages remain out of scope for Sell, same as customer checkout's own package gap.

Verified end-to-end exactly like plan checkout: booked a real reservation (Laser Tag, 3000 fee) against the Full Day Pass subscription, confirmed the resulting `reservations`/`payments` rows via SQL, then played Selcom again with a signed webhook POST — the app flipped to "Payment successful" automatically via Realtime, and "My Reservations" showed the booked slot. `reservation_settings.default_fee` was seeded at 0 (untested path); bumped to 3000 via direct SQL so the fee-payment flow was actually exercised, the same kind of demo-data correction as the entry_fee_config fix earlier in this project.

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
- [x] Role-gated router (`core/routing/app_router.dart`) — customer -> `CustomerShell`, staff roles -> `StaffShell`, admin -> "use the web dashboard" screen
- [x] `CustomerShell` bottom nav (Home / Family / Plans / Wallet) via `StatefulShellRoute.indexedStack`, each tab keeping its own nav stack
- [x] Customer Home screen — welcome card (name + membership tier), family summary, live session card (countdown ticks client-side off `planned_end_at`, no polling), quick actions, recent activity from `notifications`; matches the `customer_app_home_dashboard` Stitch mockup
- [x] `google_fonts` added for real Montserrat/Inter (previously fell back to the platform default) — same two families the web admin pulls via `next/font/google`
- [x] Venue name/logo fetched from `venue_settings` at runtime for the login screen rather than hardcoded — `venue_settings_select` is intentionally world-readable (incl. anon) for exactly this
- [x] Family tab (`features/customer/family/`) — list, add, edit `family_members`; matches the `customer_app_my_family` mockup. No delete: `family_members_delete` is admin-only by RLS design, so the customer app was never going to offer it — a real constraint discovered while building, not an oversight.
- [x] Plans tab (`features/customer/plans/`) — browsing `access_plans` (Single Visit / Memberships segmented filter, included-item counts, entry-fee note) and `packages`; matches the `customer_app_access_plans_offers` mockup minus its fabricated marketing badges ("Most Popular" etc. aren't backed by any schema field, so they were dropped rather than hardcoded). "Select Plan" opens a "coming soon" dialog — checkout is real money and payment-provider integration, deliberately a separate pass.
- [x] Wallet tab (`features/customer/wallet/`) — read-only game credit balance (`family_credit_balance`) + history (`game_credit_ledger`, direction/amount/reason/date). No redeem action: `wallet-redeem` is staff-only (403s for `customer` role) by design — redemption happens at a physical game station, not in the app.
- [x] Checkout (`features/customer/checkout/`) — discount-preview for the price summary, checkout-create-order + payments-initiate to start a real payment, a Realtime-driven waiting screen, success/failure states. Scoped to access_plans only for this pass: packages checkout is a known backend gap already (handlePaymentSucceeded only creates a subscription/wristband for access_plan order_items, not packages), so package "Select" still shows the "coming soon" dialog rather than paying for something that produces no visible entitlement.
- [x] Wristbands (`features/customer/wristbands/`) — real scannable QR codes (`qr_flutter`) per family member, matching the `customer_app_wristbands_wallet` mockup.
- [x] Memberships (`features/customer/memberships/`) — the family's own subscriptions (distinct from Plans' browsable catalog), with per-subscription "Reserve a Game".
- [x] Reservations — `reservations-book` (game limited to what the subscription's plan includes; date/time limited by `reservation_settings`), fee paid inline via the same checkout pipeline as plans. A reservation fee is a genuine extra charge on top of the membership, not included in the plan price — confirmed from `reservations-book`'s own logic (`fee: settings.default_fee`, unrelated to which plan was purchased) rather than assumed.
- [ ] Notifications
- [x] `StaffShell` bottom nav (Home / Scanner / Sessions / Reports) — a clean IA choice, not a copy of the mockups' inconsistent staff bottom nav
- [x] Staff Home (`features/staff/home/`) — park-wide active-visitor/expiring-soon stats, recent-admissions feed, "Scan QR Code" quick action
- [x] Scanner (`features/staff/scanner/`) — `mobile_scanner` camera view + manual code entry, optional game picker, calls `session-scan-admit`
- [x] Sessions (`features/staff/sessions/`) — every open session park-wide with live countdowns; Extend/End (`sessions-manage`) gated to supervisor/admin
- [x] Registration (`features/staff/registration/`) — lists pending customer accounts, approves/rejects via the new `staff-approve-customer` Edge Function
- [x] Customer Lookup (`features/staff/customers/`) — search by phone, read-only view of a family's members/memberships/wristbands; also the entry point into Sell
- [x] Sell (`features/staff/sell/`) — staff-assisted checkout on behalf of a family, `channel: 'staff_app'`, same real payment pipeline as customer checkout
- [ ] Reports (staff-level reporting; currently a placeholder tab)

Verified against the real local Supabase instance: a fresh phone number (`255700000099`, local test-OTP allowlist) signs up through the actual `handle_new_user` trigger — new `auth.users` row, `profiles` row (`role: customer`, `approval_status: pending`), `families` row — then lands on a correctly-empty-state Home screen. Adding "Leo Jenkins" through the Family tab's form produced a real `family_members` row (verified via direct SQL) and instantly appeared in Home's family summary card, since both screens share `familyMembersProvider`. Plans/Packages render real seeded data (Full Day Pass, Half Day Pass, Monthly Explorer, Birthday Bash Bundle, Twilight Special) with correct filtering and counts. A seeded `game_credit_ledger` row (+5, "Welcome bonus") rendered correctly in Wallet's balance and history, inserted directly via SQL since neither the earning path nor customer-initiated redemption exist yet. Checkout was run twice for real (Full Day Pass, Half Day Pass), each producing a real paid order + active subscription + issued wristband, confirmed via direct SQL — see below for how the payment-gateway side of this was tested without a real Selcom account. No emulator/simulator configured on this machine yet, so verification used Flutter's Chrome (web) target rather than a real device — worth a pass on an actual emulator once one's set up, since Flutter's web renderer isn't pixel-identical to mobile.

**Testing checkout without a real Selcom sandbox.** The app-side flow (price preview, order creation, payment initiation, the waiting screen) is entirely real — it calls the actual Edge Functions and gets back an actual pending order and payment row. What doesn't exist is a real Selcom account to redirect to. Rather than fake that inside the app, the "Selcom" half was played from outside it: after `payments-initiate` returned a real `paymentId`, a shell script (`scratchpad/simulate_selcom_webhook.sh` from that session, not checked in) built the exact payload `backend/supabase/functions/_shared/payments/selcom.ts` expects (`{reference, transaction_id, result, event_type}`), signed it HMAC-SHA256 with the local `SELCOM_WEBHOOK_SECRET`, and POSTed it straight to `payments-webhook-selcom` — the same request Selcom's server would make. The app never knew the difference: its Realtime subscription on the order picked up the `pending -> paid` transition and flipped to the success screen with no app-side involvement in that half of the flow at all. This is a testing technique, not a feature — there's no "simulate payment" button anywhere in the app.

Two real things found and fixed along the way, both discovered by testing rather than by inspection:
- **Customer accounts require admin approval before transacting.** `assertApproved()` (shared by every money-touching Edge Function) rejects anyone whose `profiles.approval_status` isn't `'approved'` — and `handle_new_user` defaults every new customer to `'pending'`. There's currently no UI for approving a customer (that's the not-yet-built staff "registration" screen), so the test account was approved directly via SQL, through the same `app.bypass_role_guard` transaction-local flag the web admin work discovered earlier for exactly this kind of guarded column.
- **Home's "Welcome back" card doesn't know a purchase just happened.** `activeSubscriptionProvider` was fetched before the checkout started, and Riverpod doesn't refetch it just because the underlying row changed elsewhere. Fixed by invalidating it (and `liveSessionProvider`) when "Back to Home" is tapped from the success screen — otherwise a customer who just paid would see "No active membership" until a manual pull-to-refresh.

Two more, found while building Wristbands/Memberships/Reservations:
- **`ScaffoldMessenger` inside a shell branch strikes again.** The "reserved, no fee due" confirmation was originally a `SnackBar`; same nested-`Scaffold`-inside-`StatefulShellRoute` clipping bug as Plans' "coming soon" notice. Used a `Dialog` from the start this time instead of rediscovering the same bug.
- **Reservation fees aren't discounted.** `computeCartPricing`'s composition step only feeds `access_plan`/`package` lines into `evaluateDiscounts` — a `reservation_fee` line is charged at face value, no `discount-preview` call needed before booking. Confirmed by reading `cart-pricing.ts` rather than assuming reservation checkout needed the same preview step plan checkout does.

One real bug found and fixed: `ScaffoldMessenger.of(context)` inside a `StatefulShellRoute` branch screen bubbles up to the outer shell's `Scaffold` (the one with `bottomNavigationBar`), so a `SnackBar` shown from a branch screen renders clipped behind the bottom nav — a known nested-`Scaffold` snag. Sidestepped by using a `showDialog` instead for Plans' "coming soon" notice rather than fighting `ScaffoldMessenger` positioning; worth revisiting with a per-branch `ScaffoldMessenger` if a future screen genuinely needs snackbar-style ephemeral feedback. Separately: `flutter run -d chrome`'s dev server doesn't get refetched on a hash-only route change (`/#/foo` -> `/#/bar` is same-document navigation in the browser) — testing against a rebuilt app requires a genuine full reload (a cache-busted URL or a hard refresh), not just re-navigating the existing tab to a new hash route.

**Staff experience, batch 1 — verification.** Logged in as both a cashier (`255700000021`, Juma Cashier) and a supervisor (`255700000023`, Baraka Supervisor); neither was in the local test-OTP allowlist yet, so `backend/supabase/config.toml`'s `[auth.sms.test_otp]` got the two numbers added and the local stack was restarted (`supabase stop` / `supabase start`, not `db reset` — seeded data confirmed intact after) to pick up the config change. Scanned a real seeded wristband (`WB-DEMO-MICHAEL`, via the manual-entry fallback since this environment has no camera) and got a real `session-scan-admit` admission, confirmed via direct SQL — a genuine new `sessions` row, `last_scanned_at` touched, `audit_log` entry written. As supervisor, "Extend +15m" moved a session's `planned_end_at` by exactly 15 minutes and "End" set `ended_at`, both confirmed via direct SQL; as cashier, neither button rendered at all (role gate working). One real bug found and fixed before it shipped: the staff Home "Recent Activity" feed was first built against `audit_log`, but that table's `audit_log_select` RLS policy is deliberately admin-only (its migration comment reads "confirmed: no supervisor visibility") — a cashier/supervisor session silently got an empty array back, no error. Rather than weaken that RLS policy (a deliberate decision, not an oversight), the feed was rebuilt from `sessions` instead (staff-readable via `sessions_select`), since every successful admission already produces exactly one session row — a faithful proxy for "recent check-ins" with no RLS change needed.

**Staff experience, batch 2 — verification, and a real trigger bug.** Created a fresh pending customer via the GoTrue admin API (`255700000077`, "Walk-in Test Customer" — the same underlying mechanism `handle_new_user` reacts to for real signups) and approved it through the Registration screen: `staff-approve-customer` failed on the first attempt with `Only an admin can change role or approval_status` even though it uses the service-role admin client. Root cause: `createAdminClient()` bypasses RLS but not table triggers, and `prevent_profile_privilege_escalation` only recognized `is_admin()` (a real admin caller) or the narrow `app.bypass_role_guard` flag (scoped to `handle_new_user`'s own reconciliation branch) — it had no concept of "the caller is already fully trusted because it's the service role." Fixed with a new migration (`20260807072300_allow_service_role_profile_privilege_change.sql`) adding an `auth.role() = 'service_role'` check to the trigger, applied via `migration up`. Confirmed fixed: approval persisted (`approval_status: 'approved'`) and wrote a real `audit_log` entry (`action_type: 'registration'`). Then searched for that same customer via Customer Lookup (phone `255700000077`), opened their detail screen (correctly empty: no family members/memberships/wristbands yet), and sold them a Half Day Pass through Sell — `checkout-create-order`/`payments-initiate` with `channel: 'staff_app'` behaved identically to the customer app's own checkout, and the same Selcom-webhook-simulation technique flipped it to "Payment successful" via Realtime. Returning to the customer's detail screen (a double `context.pop()` back through Sell's two pushed routes) showed the real new subscription and wristband, confirming the invalidated providers refetched correctly.

## Phase 7 — Integration, UAT, deploy (§7 weeks 7-8)

Not started.

---

## How this file gets updated

Each commit that changes what's done should update the relevant checkbox(es) here and the "Current focus" / "Last updated" lines at the top — part of the commit, not a separate step.
