# Bonding Love Garden — Play Park Management Platform

## Project Brief for Development Planning

This document is the full functional and technical specification for the project. Use it to plan the codebase architecture, data model, and build order before writing code.

---

## 1. Context

Bonding Love Garden is an indoor children's play center serving Goba and the surrounding community (Tanzania). The client needs a system to manage admissions, memberships, payments, and play sessions — replacing manual/ad-hoc tracking with a proper platform.

This is being built as a **reusable Play Park Management Platform** (not hardcoded to one client) so it can later be white-labeled for other indoor play centers, trampoline parks, or family entertainment venues. Avoid hardcoding "Bonding Love Garden" branding, pricing, or game lists into the codebase — these should be configuration data, not code.

**Engagement constraints:** fixed-price project, ~6–8 week build, solo developer (using AI-assisted development). Budget assumes low-cost, low-ops-overhead infrastructure — favor managed services over infrastructure you have to run yourself.

---

## 2. High-Level Architecture

Two client applications share one backend:

1. **Mobile App** (Flutter, Android + iOS) — one codebase, two role-based experiences:
   - **Customer Experience (primary)** — parents/individual customers self-serve: register, manage family, browse/buy Access Plans, view QR wristbands, track credits, make reservations.
   - **Staff Experience (assisted)** — cashiers, attendants, and supervisors use the same app in a staff role to register/sell on behalf of walk-in customers, scan QR wristbands, and manage active sessions.
2. **Web Admin Dashboard** (React/Next.js + Tailwind) — used by the owner/manager to configure everything (plans, pricing, discounts, games, staff) and view reports. Desktop-oriented.

**Suggested backend:** Supabase (Postgres + Auth with phone OTP + Realtime + Storage), with custom business logic (discount engine, credit wallet, Selcom webhook handling) as Edge Functions. Postgres fits the relational data model (families, children, plans, transactions) well, and Realtime channels drive the live session countdowns and instant purchase alerts without building a custom WebSocket server.

**Payments:** Selcom API (Tanzanian mobile money / card gateway) — integrated via a webhook-receiving Edge Function that updates payment/membership status on callback.

**Notifications:** Firebase Cloud Messaging for push notifications (purchase alerts to supervisors, session/membership status to customers).

**QR codes:** generated server-side per child/wristband; scanned client-side in the Staff Experience via a mobile QR scanner package.

---

## 3. User Roles

| Role | Access | Key responsibilities |
|---|---|---|
| Parent | Customer Experience (mobile) | Registers self + children, buys plans, manages family, views wristbands/credits |
| Individual customer (no children) | Customer Experience (mobile) | Same as parent but self-registers without children, buys plans for self |
| Cashier / Attendant | Staff Experience (mobile) | Registers/assists customers, sells plans/packages on their behalf, issues wristbands |
| Supervisor | Staff Experience (mobile) | Scans QR wristbands to admit gamers, receives instant alerts on completed purchases, manages active sessions |
| Owner / Manager | Web Admin Dashboard | Configures everything, manages staff/roles, views reports |

All self-registered customer accounts start in a **pending-approval** state and require admin/staff approval before they can transact. Registration/login is verified via **OTP sent to the customer's phone number** (not email — the client's users primarily transact by phone).

---

## 4. Core Domain Concepts

### 4.1 Family Accounts
- A parent account can hold multiple children, each with their own profile (name, age, photo, allergies/notes).
- At purchase time, the parent selects which child or children a plan applies to. One plan can cover multiple children, or each child can hold a separate plan.
- Adults with no children can self-register as an **individual customer account** and buy Access Plans directly for themselves — the data model should not force every customer to have at least one child.

### 4.2 Access Plans (fully owner-configurable — do not hardcode plan types)
Two categories:
- **Single Visit passes**: 30 minutes, 1 hour, half day, full day (example durations — must be configurable)
- **Recurring Memberships**: weekly, monthly, quarterly, 6-month, annual (example periods — must be configurable)

Each plan is configured by the owner with:
- Price
- Validity period
- Number of visits — unlimited or limited
- Which games are included
- Daily play time allowed (if applicable)

### 4.3 Entry Fee
A **constant admission fee** applies to every visit, separate from and in addition to any games or services selected. It is configurable (amount set by the owner) and is applied automatically to every purchase. It can participate in combo discounts (e.g., entry fee + one paid game + lunch qualifying for a bundle discount).

### 4.4 Games & Services Configuration
- Games are classified as **motorized** (require electric power) or **non-motorized** — this is a configurable attribute per game, not just a label; it may affect operational rules (e.g., staffing, maintenance) later.
- Non-game **services** (e.g., lunch, snacks) can also be configured and sold, standalone or combined with games.

### 4.5 Discounts & Combo Pricing
An **owner-configurable discount engine**: when a customer buys more than one game/service together (e.g., entry fee + one paid game + lunch), a discount can apply. The rule definitions — what combination qualifies, and how much is deducted (fixed amount or %) — must be data the owner sets in the admin dashboard, not logic hardcoded in the app. Design this as a rules table the discount engine evaluates at checkout.

### 4.6 Subscriptions
A **subscription** is the customer's held instance of a Recurring Membership (Access Plan) for a defined length of time (e.g., one week) covering a specific game or set of games. This is the "container" that Reservations (4.7) attach to.

### 4.7 Reservations & Time-Slot Booking
Within an active subscription, a customer can reserve a **specific time slot** for a game. Reservations can carry their own separate fee. Reservation rules (how far ahead, how many per day, fee amount) are configurable by the owner.

### 4.8 Packages & Limited-Time Offers
The owner can bundle multiple games and/or services into a **Package** sold at a discount, optionally with a **limited-time availability window** (start/end date) that the owner sets when creating the offer. Packages are distinct from ad-hoc Discounts (4.5) — a Package is a pre-defined, named bundle; a Discount is a rule applied dynamically at checkout.

### 4.9 Game Credit Wallet
Games/services a customer has paid for but not yet used are retained in their account as **credit** (e.g., "5 unused game credits") rather than being lost, and can be redeemed on a future visit. This needs its own ledger (credits earned vs. redeemed) per customer, not just a decrementing counter, so history is auditable.

### 4.10 QR Wristbands & Scanning
- Each active plan/session generates a QR wristband: child/customer name, package, wristband number, expiry — with a print option.
- Supervisors scan wristbands in a full-screen scanner view. On scan: show photo, membership/package, allowed games, remaining time, and a clear **valid (green) / expired (red)** status.
- Supervisors receive an **instant push alert** whenever a purchase is completed, so they know a new gamer is ready to be scanned in.

### 4.11 Active Session Management
- Live countdown timers per child/customer: current game, time remaining, contact info.
- Extend session / end session actions (staff-initiated).
- Visual status: sessions nearing expiry turn **orange**, expired sessions turn **red**. This needs a scheduled/reactive mechanism (not just client-side polling) so state stays accurate across devices — Realtime subscriptions are a good fit.

### 4.12 Payments
Selcom integration covering: pending, successful, and failed payment states; retry flow; receipt generation. Payment status changes should come from Selcom's webhook, not be assumed client-side.

---

## 5. Mobile App — Customer Experience (Primary) Screens

1. **Sign up / Login** — self-registration verified via phone OTP; shows pending-approval status until admin/staff approve
2. **Home** — family overview, active sessions, notifications, quick "Buy Access Plan"
3. **My Family** — add/edit children, allergies/notes, choose who a plan applies to
4. **Access Plans** — browse/compare plans as pricing cards, purchase directly
5. **Checkout** — select children, one or more plans, pay via Selcom, price + discount summary
6. **My QR Wristbands** — view active QR codes/passes for each child
7. **Game Credit Wallet** — view unused game/service credits carried forward
8. **Memberships** — view active/expiring/expired plans; renew
9. **Reservations** — book a specific time slot for a game
10. **Packages & Offers** — browse limited-time bundles
11. **Notifications** — payment confirmations, membership status, session updates

## 6. Mobile App — Staff Experience (Assisted Operations) Screens

1. **Login**
2. **Home dashboard** — active children inside, today's revenue, memberships expiring today, quick actions
3. **Register or assist a parent/customer** — including approving self-registered accounts
4. **Sell an Access Plan or package** on behalf of a customer
5. **QR wristband issuing and printing**
6. **QR scanner** (supervisors) — admit gamers, real-time purchase alerts
7. **Active session management** — extend/end session
8. **Membership management** — active, expiring soon, expired, renew, suspend, cancel
9. **Mobile reports** — today's revenue, active children, sales, popular games, revenue trend

## 7. Web Admin Dashboard — Modules

1. Dashboard overview with charts
2. Parent, child, and staff management
3. Game and play-area management (incl. motorized/non-motorized flag)
4. Pricing & Access Plan configuration, Entry Fee, discounts, packages and offers
5. Membership management, ticket sales, payment records
6. Wristband management & QR scanner monitoring
7. Active play sessions overview
8. Revenue, customer, and attendance reports
9. Settings, notifications, and user roles & permissions

---

## 8. Suggested Data Entities (starting point for schema design)

- `users` (auth, phone, OTP status, role: customer/cashier/attendant/supervisor/admin, approval status)
- `families` / `parents` — profile, linked `children`
- `children` — profile, age, notes/allergies, linked parent
- `access_plans` — type (single-visit/recurring), duration/validity, price, visit limit, games included, daily time limit
- `entry_fee_config` — constant fee amount (owner-configurable, versioned so historical purchases keep the fee that applied at the time)
- `games` — name, motorized flag, price, availability
- `services` — name, price (non-game, e.g. lunch)
- `discount_rules` — qualifying combination, discount type/amount
- `subscriptions` — customer, access_plan, start/end, status
- `reservations` — subscription, game, time slot, fee
- `packages` — bundled games/services, discount, availability window (start/end)
- `game_credits` (ledger) — customer, credit source, earned/redeemed, balance
- `wristbands` — QR code, linked child/customer, plan, expiry, status
- `sessions` — active play session, child/customer, game, start/end, status (active/expiring/expired)
- `payments` — Selcom transaction ref, amount, status, linked purchase
- `notifications` — recipient (customer or supervisor), type, payload, read status

---

## 9. Suggested Build Order (mirrors the agreed 6–8 week timeline)

1. **Week 1** — Discovery & planning: finalize data model for Access Plans, Entry Fee, Subscriptions, discount rules; wireframes
2. **Weeks 1–3** — Core backend: accounts + phone OTP verification, Access Plans, Subscriptions, Reservations, discount engine, credit wallet
3. **Weeks 2–5** — Mobile app: Customer Experience + Staff Experience, QR wristbands/scanning, active sessions
4. **Weeks 4–6** — Web admin dashboard: configuration, staff & roles, reports
5. **Weeks 5–7** — Payments (Selcom), packages & offers, integration testing
6. **Weeks 7–8** — UAT with client, bug fixes, deployment & handover

---

## 10. Explicit Non-Goals / Assumptions

- Android is the primary mobile target; iOS can follow the same Flutter codebase but isn't required for launch.
- Client provides branding assets, initial game list, and pricing structure as configuration input — none of this should be hardcoded.
- Physical hardware for printing/scanning wristbands is out of scope (software only).
- Post-launch: 12 months of support — first 3 months bug-fixing, remaining 9 months technical support only. New feature requests are out of scope for this support window (handled as change requests).
- Source code is for the client's operational use; IP remains with the developer. Don't build in assumptions that the client will redistribute or resell the software.

---

## 11. Design Direction (for reference)

Clean, friendly, colorful, professional. Rounded cards, soft shadows, large touch-friendly buttons, playful accent colors (blue, orange, yellow, green), plenty of white space — modern SaaS dashboard feel combined with family-friendly brand energy (think indoor trampoline park / kids' brand polish, not a bare-bones POS).
