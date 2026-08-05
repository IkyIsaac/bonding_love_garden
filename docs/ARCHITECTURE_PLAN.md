# Bonding Love Garden — Architecture & Build Plan

Companion to `Bonding_Love_Garden_Project_Brief.md`. This document is the technical plan: repo layout, schema, RLS, Edge Functions, Flutter structure, and build sequencing. No feature code yet — this is what we scaffold from once you sign off.

**Decided up front:** single-tenant per deployment. One Supabase project = one venue. "Reusable/white-label" (brief §1) is achieved by making branding, games, pricing, and rules 100% config-driven data — not by sharing one database across venues. Reuse = fork the repo, stand up a new Supabase project, populate config tables for the new client. This keeps every table and RLS policy simple (no `venue_id` scoping everywhere) and fits a 6–8 week solo build. If true multi-tenant SaaS is ever wanted, the schema below is small enough to retrofit (add `venue_id`, prefix policies) — it's not free, but it's not the constant tax multi-tenant-from-day-one would be during this build.

Design source note: I read all 14 Stitch mockups in `stitch_bonding_love_garden_platform/` plus `botanical_play/DESIGN.md`. They confirm several things beyond the brief text (payment providers named exactly as Selcom/Snippe/Payguard — matches your pluggable-payments requirement; discount rules operate on a *component* model with per-item pricing, not whole-plan pricing; audit log needs actor/action-type/details/location/status columns; "Guest Pass" is a distinct purchase type for non-family visitors). Where mockups conflict with each other (zone names, nav sets) I've treated that as placeholder noise, not spec — flagged inline below.

---

## 1. Scope confirmation

Read in full: Family Accounts, Access Plans (single-visit + membership, owner-configurable), Entry Fee (constant, versioned), Games/Services (motorized flag), Discounts (rules engine, component-based), Subscriptions, Reservations, Packages (time-boxed bundles), Game Credit Wallet (ledger, not a counter), QR Wristbands, Active Sessions (live countdown, Realtime), Payments (provider-agnostic, webhook-driven state), Audit Log, role-based visibility across 5 roles (parent, individual customer, cashier/attendant, supervisor, admin). Understood and reflected in the schema below.

---

## 2. Repo structure — monorepo, recommended

```
bonding-love-garden/
├── backend/                      # Supabase project
│   └── supabase/
│       ├── migrations/           # versioned SQL, one file per change
│       ├── functions/            # Edge Functions (Deno)
│       │   ├── _shared/          # discount engine, payment provider interface, auth helpers
│       │   ├── checkout-create-order/
│       │   ├── payments-initiate/
│       │   ├── payments-webhook-selcom/
│       │   ├── payments-webhook-snippe/
│       │   ├── payments-webhook-payguard/
│       │   ├── wallet-redeem/
│       │   ├── wristband-issue/
│       │   ├── session-scan-admit/
│       │   ├── sessions-manage/
│       │   └── reservations-book/
│       ├── seed.sql               # demo config data for local dev (NOT client branding)
│       └── config.toml
├── mobile/                        # Flutter app (Customer + Staff)
├── web/                           # Next.js admin dashboard
├── docs/
│   ├── Bonding_Love_Garden_Project_Brief.md
│   ├── ARCHITECTURE_PLAN.md       # this file
│   └── design/                    # Stitch mockups + DESIGN.md, moved here
└── .github/workflows/             # CI: migration lint, web build+typecheck, flutter analyze+test
```

**Why monorepo for a solo dev, not separate repos:** most non-trivial changes here are cross-cutting — a new discount rule shape touches a migration, an Edge Function, the admin UI, and the mobile checkout screen in the same sitting. One repo means one PR/commit per feature instead of coordinating three, one CI pipeline, one issue tracker, and no version-skew between a shared TypeScript types package and its consumers. Supabase CLI, Flutter, and Next.js each work fine rooted in a subfolder — nothing about Supabase or Flutter tooling requires its own repo. Split later only if you ever hand off the web dashboard to a separate team with separate access control; that's not this engagement.

Generate TS types for `web/` from the live schema with `supabase gen types typescript` into `web/types/database.ts`, committed and regenerated after each migration — keeps the admin dashboard honest against the real schema without a hand-maintained shared package.

---

## 3. Postgres schema

UUID PKs (`gen_random_uuid()`), `created_at timestamptz default now()` on everything, `updated_at` + trigger where rows mutate post-insert. Money as `numeric(12,2)`, currency fixed per venue in `venue_settings` (no multi-currency now).

### 3.1 Identity & family

```sql
-- extends auth.users 1:1
profiles (
  id uuid primary key references auth.users(id),
  phone text unique not null,               -- E.164, source of truth (not email)
  full_name text not null,
  role text not null check (role in ('customer','cashier','attendant','supervisor','admin')),
  approval_status text not null default 'pending'
    check (approval_status in ('pending','approved','rejected','suspended')),
  photo_url text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
)

families (
  id uuid primary key default gen_random_uuid(),
  owner_profile_id uuid not null references profiles(id),
  display_name text,                        -- "The Chen Family" — mockups confirm family is a reportable unit
  created_at timestamptz default now()
)
-- every profile gets exactly one family row on signup (individual customers included,
-- with zero family_members) — keeps "who does this order/wristband/wallet belong to"
-- uniformly family_id everywhere instead of branching on customer type.

family_members (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references families(id) on delete cascade,
  kind text not null check (kind in ('child','dependent_adult')),
  full_name text not null,
  age int,
  gender text check (gender in ('male','female','other')),
  photo_url text,
  allergies_notes text,
  general_notes text,
  is_primary_child boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
)
```

`dependent_adult` (confirmed) covers the "Adult Member" checkout role the mockups show alongside "Junior" — e.g. a spouse or adult dependent with no login of their own, who still needs to be selectable at checkout and attached to `order_items`/`wristbands` like any other beneficiary.

Individual customers with no family at all (confirmed as first-class, not an edge case) are handled by the same `families` row every profile gets on signup — `owner_profile_id` set, zero `family_members` rows. Subscriptions/orders/wristbands for them just leave `family_member_id` null (= applies to the account owner). No branching logic anywhere needs to ask "does this customer have a family or not" — there's always exactly one `families` row per profile, sometimes with dependents attached and sometimes without.

Non-family guest passes (grandparent/friend, per the wallet mockup's "Guest Passes" upsell) are **not** a roster table — they're purchase-time data (see `order_items.guest_name` below), because they're per-visit, not persistent relationships.

**Not building:** pets as session subjects (one mockup shows "Buddy (Retriever)" on a session card — that's Stitch placeholder embellishment, not in the brief; `sessions` below has no beneficiary-type branching for it, easy to add a `kind` later if the client actually asks).

### 3.2 Venue config (the "no hardcoded branding/pricing" home)

```sql
venue_settings (          -- single row
  id uuid primary key default gen_random_uuid(),
  park_name text not null,
  logo_url text,
  brand_colors jsonb,      -- {primary, accent, ...} consumed by both clients at runtime
  timezone text not null default 'Africa/Dar_es_Salaam',
  currency text not null default 'TZS',
  contact_info jsonb,
  updated_at timestamptz default now()
)

zones (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  capacity int,
  is_active boolean default true
)

catalog_items (            -- unifies "games" and "services" — both are purchasable/discountable components
  id uuid primary key default gen_random_uuid(),
  type text not null check (type in ('game','service')),
  name text not null,
  description text,
  is_motorized boolean,     -- meaningful only when type='game'; null for services
  price numeric(12,2) not null,
  pricing_unit text not null default 'flat' check (pricing_unit in ('flat','hourly')),
  zone_id uuid references zones(id),
  image_url text,
  is_active boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
)

entry_fee_config (          -- versioned: never mutate a row, insert a new one
  id uuid primary key default gen_random_uuid(),
  amount numeric(12,2) not null,
  effective_from timestamptz not null default now(),
  effective_to timestamptz,          -- null = current
  created_by uuid references profiles(id)
)
```

Why `catalog_items` instead of separate `games`/`services` tables as the brief's entity list literally names them: the Stitch discount-rule builder and package builder both operate on a flat list of "components" (Entry, Games, Lunch, Merch, Photo Ops) with a per-item price used for live discount math — modeling games and services as the same shape means `discount_rule_components` and `package_items` each need one FK type, not two. `type` and `is_motorized` preserve everything the brief's separate entities asked for.

### 3.3 Plans, discounts, packages

```sql
access_plans (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  plan_type text not null check (plan_type in ('single_visit','membership')),
  price numeric(12,2) not null,
  validity_value int not null,
  validity_unit text not null check (validity_unit in ('minutes','hours','days','weeks','months','years')),
  visit_limit int,                 -- null = unlimited
  daily_time_limit_minutes int,
  is_active boolean default true,
  description text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
)

access_plan_items (          -- which games/services a plan includes
  access_plan_id uuid references access_plans(id) on delete cascade,
  catalog_item_id uuid references catalog_items(id),
  primary key (access_plan_id, catalog_item_id)
)

discount_rules (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  discount_type text not null check (discount_type in ('percent','flat')),
  discount_value numeric(12,2) not null,
  min_quantity int,                  -- e.g. "groups of 10+"
  valid_from timestamptz,
  valid_to timestamptz,
  days_of_week int[],                -- e.g. {6,0} for Sat/Sun-only rules
  status text not null default 'draft' check (status in ('draft','enabled','disabled','archived')),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
)

discount_rule_components (    -- qualifying cart composition; a special catalog_item_id=NULL row means "entry fee"
  discount_rule_id uuid references discount_rules(id) on delete cascade,
  catalog_item_id uuid references catalog_items(id),   -- null = entry fee component
  primary key (discount_rule_id, catalog_item_id)
)

packages (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  price numeric(12,2) not null,
  availability_start timestamptz,
  availability_end timestamptz,
  image_url text,
  is_active boolean default true,
  created_at timestamptz default now()
)

package_items (
  package_id uuid references packages(id) on delete cascade,
  catalog_item_id uuid references catalog_items(id),
  quantity int not null default 1,
  primary key (package_id, catalog_item_id)
)
```

Discount rules don't need their own versioning table — the price actually charged is snapshotted onto `order_items` at purchase time (§3.4), so changing a rule later never rewrites history.

### 3.4 Subscriptions, reservations, orders, payments

```sql
subscriptions (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references families(id),
  family_member_id uuid references family_members(id),  -- null = applies to the account owner
  access_plan_id uuid not null references access_plans(id),
  entry_fee_config_id uuid references entry_fee_config(id),  -- fee snapshot at purchase
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  visits_remaining int,
  status text not null default 'pending_payment'
    check (status in ('pending_payment','active','expired','cancelled','suspended')),
  created_at timestamptz default now()
)

reservations (
  id uuid primary key default gen_random_uuid(),
  subscription_id uuid not null references subscriptions(id),
  catalog_item_id uuid not null references catalog_items(id),
  slot_start timestamptz not null,
  slot_end timestamptz not null,
  fee numeric(12,2) not null default 0,
  status text not null default 'booked'
    check (status in ('booked','checked_in','cancelled','no_show')),
  created_at timestamptz default now()
)

orders (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references families(id),
  buyer_profile_id uuid not null references profiles(id),   -- customer, or staff acting on their behalf
  channel text not null check (channel in ('customer_app','staff_app','web_admin')),
  subtotal numeric(12,2) not null,
  discount_total numeric(12,2) not null default 0,
  entry_fee_total numeric(12,2) not null default 0,
  total_amount numeric(12,2) not null,
  status text not null default 'pending'
    check (status in ('pending','paid','failed','refunded','cancelled')),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
)

order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references orders(id) on delete cascade,
  item_type text not null check (item_type in
    ('access_plan','package','reservation_fee','entry_fee','guest_pass','credit_topup')),
  reference_id uuid,                 -- FK target depends on item_type (access_plan_id / package_id / reservation_id)
  family_member_id uuid references family_members(id),   -- who this line item is for; null = account owner
  guest_name text,                   -- populated only for item_type='guest_pass'
  quantity int not null default 1,
  unit_price numeric(12,2) not null,
  line_total numeric(12,2) not null,
  created_at timestamptz default now()
)

order_discount_applications (   -- audit trail: exactly which rule(s) fired and for how much
  order_id uuid references orders(id) on delete cascade,
  discount_rule_id uuid references discount_rules(id),
  amount_deducted numeric(12,2) not null,
  primary key (order_id, discount_rule_id)
)

payment_providers (            -- pluggable, not an enum — add a row, not a migration, to onboard a provider
  id uuid primary key default gen_random_uuid(),
  code text unique not null,       -- 'selcom' | 'snippe' | 'payguard' | ...
  display_name text not null,
  is_active boolean default true,
  public_config jsonb,             -- non-secret display config only; real credentials live in Edge Function env vars
  sort_order int default 0
)

payments (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references orders(id),
  provider_id uuid not null references payment_providers(id),
  provider_reference text,          -- provider's transaction id
  amount numeric(12,2) not null,
  status text not null default 'pending'
    check (status in ('pending','processing','succeeded','failed','refunded')),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
)

payment_webhook_events (        -- raw inbound log, service-role only — idempotency + replay safety
  id uuid primary key default gen_random_uuid(),
  provider_id uuid references payment_providers(id),
  payment_id uuid references payments(id),
  event_type text,
  payload jsonb not null,
  signature_verified boolean not null,
  processed_at timestamptz,
  created_at timestamptz default now()
)
```

### 3.5 Credit wallet, wristbands, sessions

```sql
game_credit_ledger (        -- append-only; balance is derived, never stored mutable
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references families(id),
  family_member_id uuid references family_members(id),
  order_id uuid references orders(id),       -- source, if earned via purchase
  wristband_id uuid references wristbands(id),  -- destination, if redeemed
  direction text not null check (direction in ('earned','redeemed','adjusted')),
  amount int not null,               -- always positive; direction determines sign in balance calc
  reason text,
  created_by uuid references profiles(id),   -- staff adjustments are attributable
  created_at timestamptz default now()
)
-- balance per family: sum(earned) - sum(redeemed) +/- adjusted, exposed via a view (see §3.7)

wristbands (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references families(id),
  family_member_id uuid references family_members(id),   -- null = account owner
  subscription_id uuid references subscriptions(id),
  qr_code_value text unique not null,
  wristband_number text not null,
  status text not null default 'active' check (status in ('active','expired','revoked')),
  issued_at timestamptz default now(),
  expires_at timestamptz not null,
  last_scanned_at timestamptz,
  issued_by uuid references profiles(id)     -- staff profile, if issued in person
)

sessions (
  id uuid primary key default gen_random_uuid(),
  wristband_id uuid not null references wristbands(id),
  catalog_item_id uuid references catalog_items(id),
  zone_id uuid references zones(id),
  started_at timestamptz not null default now(),
  planned_end_at timestamptz not null,
  ended_at timestamptz,               -- set only on explicit staff "End" action
  extended_minutes_total int not null default 0,
  created_at timestamptz default now()
)
```

**Session status is deliberately not a stored column.** "Active / expiring soon / expired" (brief §4.11) is a function of `now()` vs `planned_end_at`, which changes every second — storing and cron-updating it invites drift. Instead: a view computes it live (§3.7), and both clients subscribe to the `sessions` table via Supabase Realtime so any row change (extend, end) pushes instantly; the orange/red threshold is a pure client-side (and view-side) comparison against `planned_end_at`, no polling needed.

### 3.6 Notifications & audit

```sql
notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_profile_id uuid not null references profiles(id),
  type text not null,
  title text not null,
  body text,
  payload jsonb,
  is_read boolean default false,
  created_at timestamptz default now()
)

audit_log (
  id uuid primary key default gen_random_uuid(),
  actor_profile_id uuid references profiles(id),
  action_type text not null,          -- 'registration' | 'pos_sale' | 'auth' | 'refund' | 'session_extend' | ...
  target_type text,
  target_id uuid,
  details text,
  location text,                      -- zone/station name, matches audit-log mockup
  status text not null default 'success' check (status in ('success','verified','failed')),
  created_at timestamptz default now()
)
```

`audit_log` is insert-only from Edge Functions using the service role — no client ever writes it directly, so it can't be tampered with client-side, which matters given it's your compliance/dispute trail.

### 3.7 Supporting views (not tables)

```sql
-- live session status, computed, never stored
create view session_live_status as
select s.*,
  case
    when s.ended_at is not null then 'ended'
    when now() > s.planned_end_at then 'expired'
    when s.planned_end_at - now() < interval '10 minutes' then 'expiring_soon'
    else 'active'
  end as status
from sessions s;

-- family wallet balance, derived from the ledger
create view family_credit_balance as
select family_id,
  sum(case when direction = 'earned' then amount
           when direction = 'redeemed' then -amount
           else amount end) as balance
from game_credit_ledger
group by family_id;
```

### 3.8 Row Level Security

Two helper functions used throughout:

```sql
create function is_staff() returns boolean as $$
  select exists (select 1 from profiles where id = auth.uid()
                 and role in ('cashier','attendant','supervisor','admin')
                 and approval_status = 'approved')
$$ language sql security definer stable;

create function is_admin() returns boolean as $$
  select exists (select 1 from profiles where id = auth.uid() and role = 'admin')
$$ language sql security definer stable;

create function owns_family(fid uuid) returns boolean as $$
  select exists (select 1 from families where id = fid and owner_profile_id = auth.uid())
$$ language sql security definer stable;
```

| Table group | Customer (own data) | Staff (cashier/attendant/supervisor) | Admin |
|---|---|---|---|
| `profiles` | SELECT/UPDATE own row | SELECT customer profiles (for service); own row UPDATE | full |
| `families`, `family_members` | SELECT/UPDATE/INSERT own family only (`owns_family`) | SELECT/INSERT/UPDATE any (assisted registration) | full |
| `venue_settings`, `zones`, `catalog_items`, `access_plans`, `access_plan_items`, `entry_fee_config`, `discount_rules`, `discount_rule_components`, `packages`, `package_items` | SELECT only (incl. **anon** — customer app must browse plans pre-login) | SELECT only | full (INSERT/UPDATE/DELETE) |
| `subscriptions`, `reservations`, `wristbands`, `game_credit_ledger` | SELECT own family only; INSERT reservations for own family | SELECT all (operational need); INSERT/UPDATE per role — e.g. only supervisor/attendant can adjust ledger | full |
| `orders`, `order_items`, `order_discount_applications`, `payments` | SELECT own family only; no direct client INSERT — always via `checkout-create-order` (service role) | SELECT all; no direct INSERT — same function, `channel='staff_app'` | full |
| `payment_providers` | SELECT active rows only (to render payment method list) | SELECT | full |
| `payment_webhook_events` | none | none | SELECT (service role writes; even admin arguably read-only via dashboard, not edit) |
| `sessions` | SELECT own family's, via `wristbands` join | SELECT all; UPDATE (extend/end) restricted to supervisor role | full |
| `notifications` | SELECT/UPDATE (mark read) own rows only | SELECT own rows only | full |
| `audit_log` | none | none — admin-only, confirmed | SELECT |

Financial writes (orders, payments, wristband issuance, ledger entries) never happen via a client-side INSERT under RLS — they go through Edge Functions running with the service role, so the actual authorization check lives in application code (verify `auth.uid()`'s role via the JWT before acting) rather than relying on RLS to arbitrate business rules like "only a paid order gets a wristband." RLS's job here is narrower: guarantee customers can never read another family's rows, and guarantee staff-only tables reject direct customer writes.

---

## 4. Supabase Edge Functions

Business logic that needs procedural code, external calls, or cross-table invariants lives here. Pure aggregation (dashboard metrics, reports) is **Postgres views/RPC functions**, not Edge Functions — a SQL round-trip beats a Deno cold start for read-only reporting, and Supabase exposes RPC over PostgREST for free.

| Function | Responsibility |
|---|---|
| `checkout-create-order` | Validates cart (plans/packages/reservations/guest passes), runs the discount engine (shared module) against `discount_rules`, snapshots current entry fee + item prices onto `order_items`, creates `orders` row (`pending`), returns amount payable. Called by both customer app and staff app (`channel` differs). |
| `discount-preview` | Same discount-engine module as above, read-only — powers the admin rule builder's live "Price Impact Preview" and the customer checkout summary before the customer commits to paying. |
| `payments-initiate` | Provider-agnostic dispatcher: given `order_id` + `provider_code`, resolves the provider via `_shared/payments/registry.ts` and calls its `initiate()`. Returns whatever the provider needs client-side (redirect URL, USSD prompt, instructions). |
| `payments-webhook-selcom`, `payments-webhook-snippe`, `payments-webhook-payguard` | One thin endpoint per provider (each has a distinct signature scheme and payload shape — can't share a URL safely). Each verifies signature, logs to `payment_webhook_events`, normalizes the payload, then calls one shared `processPaymentEvent()` — which updates `payments.status`, and on success: marks the order paid, activates the subscription, issues the wristband, credits the wallet, and triggers `notify-purchase-complete`. This keeps "what happens when a payment succeeds" in exactly one place regardless of which of the three providers fired. |
| `wallet-redeem` | Staff/supervisor-initiated: redeem N credits against a wristband at a game station. Validates sufficient balance from `family_credit_balance`, inserts a `redeemed` ledger row. |
| `wristband-issue` | Generates the QR payload + `wristbands` row. Called internally by the payment webhook on success, and directly by staff for cash/manual issuance. |
| `session-scan-admit` | Staff scans a QR: validates wristband status/expiry/entitlement, starts or resumes a `sessions` row, writes an `audit_log` entry. |
| `sessions-manage` | Extend or end an active session (supervisor-only per RLS/role check inside the function). |
| `reservations-book` | Validates reservation rules (lead time, per-day cap — brief §4.7's configurable constraints are numeric enough to live as `venue_settings`-style config, but the *validation logic* needs a function since RLS can't express "no more than N reservations per subscription per day" cleanly). |
| `notify-purchase-complete` | Sends FCM push to on-duty supervisors. Simple enough to alternatively be a DB trigger + `pg_net` call instead of a full Edge Function — start with a trigger, promote to a function only if FCM payload logic grows non-trivial. |

**Not building as Edge Functions:** OTP send/verify — Supabase Auth's native phone-OTP flow handles this through the client SDK directly (`signInWithOtp`/`verifyOtp`), no custom function needed. **SMS provider left unconfigured for now** (per your call — you'll provide the real provider's details later). This is deliberately a zero-code decision point, not a deferred engineering task: which SMS backend sends the actual OTP text is a setting in the Supabase Dashboard (Authentication → Phone Auth → provider), completely decoupled from application code — the client always just calls `signInWithOtp`/`verifyOtp` regardless of what's behind it. For dev/UAT before you hand over provider credentials, use Supabase's built-in **test phone numbers** (Auth settings → allow a fixed list of numbers with a static OTP, e.g. `+255700000000` / `123456`) so the full OTP UI flow can be built and tested with zero real SMS sent. Swapping in the real provider later is: paste credentials into the Dashboard (or, if the provider needs custom request/response shaping, a small Auth "Send SMS" Hook) — never a schema or client-code change. New-profile bootstrap (`profiles` + `families` row creation on signup) is a Postgres trigger on `auth.users` insert, not a function — more reliable than hoping the client calls something after signup.

**Payment provider abstraction** (`backend/supabase/functions/_shared/payments/`):

```ts
interface PaymentProvider {
  code: string;
  initiate(order: Order, params: unknown): Promise<InitiateResult>;
  verifyWebhookSignature(req: Request): Promise<boolean>;
  parseWebhookPayload(payload: unknown): NormalizedPaymentEvent;
}
```

`selcom.ts`, `snippe.ts`, `payguard.ts` each implement this; a `registry.ts` maps `payment_providers.code` → implementation. Adding a fourth provider later is: one new file + one new webhook function + one new `payment_providers` row — never a schema change, never touching `processPaymentEvent()`.

---

## 5. Flutter app structure

Feature-first, with a shared `core/` so Customer and Staff experiences don't duplicate auth, models, or the API client. Recommend **Riverpod** for state management — plays well with Supabase's Realtime streams (session countdowns, purchase alerts) and is straightforward to test solo.

```
mobile/lib/
├── core/
│   ├── config/          # env, Supabase client init
│   ├── theme/            # Botanical Play tokens ported from DESIGN.md — colors, type scale, radii, spacing
│   ├── auth/              # phone OTP flow, session state, role resolution (AuthController)
│   ├── api/                # repositories: FamilyRepository, PlansRepository, OrdersRepository,
│   │                        #   WristbandRepository, SessionRepository — thin wrappers over
│   │                        #   supabase_flutter + calls into Edge Functions/RPC
│   ├── models/             # Dart classes mirroring DB tables (freezed + json_serializable)
│   ├── widgets/            # shared design-system components (buttons, cards, status chips)
│   └── routing/            # go_router; picks CustomerShell vs StaffShell post-login by profile.role
├── features/
│   ├── shared/             # literally shared screens, e.g. QR wristband display used by
│   │                        #   both "My Wristbands" (customer) and issuing/reprint (staff)
│   ├── customer/
│   │   ├── auth/            # login/OTP/pending-approval
│   │   ├── home/
│   │   ├── family/
│   │   ├── plans/
│   │   ├── checkout/
│   │   ├── wristbands/
│   │   ├── wallet/
│   │   ├── memberships/
│   │   ├── reservations/
│   │   ├── packages/
│   │   └── notifications/
│   └── staff/
│       ├── auth/
│       ├── home/
│       ├── registration/    # register/assist + approve pending accounts
│       ├── sell/
│       ├── scanner/
│       ├── sessions/
│       ├── memberships/
│       └── reports/
└── main.dart
```

Role gate: after OTP verification, fetch `profiles.role`. `customer` → `CustomerShell` (bottom nav: Home / Family / Plans / Wallet, matching every customer mockup consistently). `cashier`/`attendant`/`supervisor` → `StaffShell` (Home / Scanner / Sessions / Reports — the staff mockups' bottom nav was inconsistent/templated, so this is a clean IA choice rather than a mockup copy). `admin` isn't expected to authenticate in the mobile app at all — redirect to "use the web dashboard" if it happens.

## 6. Web admin structure (Next.js)

```
web/app/(dashboard)/
├── dashboard/       # overview, bento metrics, real-time sessions table
├── staff/           # staff management, roles, approvals
├── plans/           # "Plan Builder": access plans, entry fee, catalog items (games/services)
├── discounts/        # discount rule builder + list, with live price-impact preview
├── packages/
├── wristbands/
├── sessions/          # active session monitoring
├── reports/           # guest analytics + operational reports (two tabs, per mockup)
├── audit-log/
└── settings/           # venue_settings, branding
```

Sidebar consolidates the mockups' two overlapping labels ("Guest Analytics" vs "Reports & Logs") into one `reports/` section with tabs, since nothing in the brief or mockups justifies two separate surfaces for what's functionally one reporting area.

---

## 7. Build order — mapped to brief §9, with changes flagged

| Brief's week | What happens | Change from brief |
|---|---|---|
| Week 1 | Repo scaffold, Supabase project, migrations for identity/venue-config tables (§3.1–3.2), RLS helpers, Flutter/Next theme setup from `DESIGN.md` tokens. Auth wired against Supabase's **test phone numbers** (no real SMS provider needed yet — see §4) so OTP UI/flow work isn't blocked on you sourcing provider credentials. | Brief allots week 1 to wireframes — **skip most of that**: Stitch mockups already cover nearly every core screen. Redirect the saved time to RLS policy writing and discount-rule modeling, the two areas with the most hidden complexity. |
| Weeks 1–2 | Core backend part 1: auth bootstrap trigger, `access_plans`, `catalog_items`, `entry_fee_config`, discount tables, packages. | — |
| Weeks 2–3 | Core backend part 2: `orders`/`order_items`, discount engine + preview function, `subscriptions`, `reservations`, `game_credit_ledger`, `wristbands`, `sessions` (+ live-status view), `audit_log`. **Wire one real payment provider (Selcom) end-to-end here**, with Snippe/Payguard stubbed behind the same interface. | Brief defers all payments to weeks 5–7. Validating the pluggable-provider abstraction against one real integration early is lower-risk than building two abstract interfaces and only proving the pattern works at the end. |
| Weeks 2–5 | Mobile: Customer experience first (primary, per brief), Staff experience second. Scanner/session screens sequenced after their backend functions land (~week 3–4). | — |
| **Weeks 2–4 (new, parallel)** | Minimal admin CRUD for config tables — plans, catalog items, discounts, entry fee — built early, even before the polished dashboard/reports. | **Added.** The brief sequences web admin to weeks 4–6, but the mobile app needs *real* config data to develop and demo against, not just seed SQL. Without this, mobile dev either stalls on fixtures or the client can't see real data until week 4+. |
| Weeks 4–6 | Web admin: full dashboard, reports, audit log, staff/roles. | Config CRUD (above) already done; this is now polish + reporting, lower risk. |
| Weeks 5–7 | Remaining 2 of 3 payment providers, packages/offers UI, reservations UI, wallet redeem, cross-app integration testing. | — |
| **From week 2 onward (new)** | Deploy web admin to a staging Supabase + Vercel environment continuously, not just at week 8. Let the owner start entering real games/pricing/branding as soon as config CRUD exists. | **Added.** Turns UAT into a running process instead of a single week-8 event, and de-risks "client has no real data on launch day." |
| Weeks 7–8 | UAT, bug fixes, deploy, handover. | Unchanged, but should be lighter since staging has been live and used since week ~2. |
| **Whenever you send SMS provider details (new)** | Swap Supabase Auth's phone provider from test numbers to the real one (Dashboard config, or a small Auth Hook — see §4). Not tied to any particular week; drops in independently whenever you're ready. | **Added**, per your call to leave SMS unimplemented for now. |

---

## 8. Decisions confirmed

1. **`audit_log` RLS** — admin-only. No supervisor visibility into the audit trail.
2. **SMS/OTP provider** — left unconfigured for now; you'll provide details later. Dev/UAT proceeds on Supabase's test phone numbers in the meantime (§4); switching to the real provider afterward is a config change, not a code change, so nothing about the build is blocked on this.
3. **`dependent_adult`** family member kind — included, as designed. Individual customers with no family at all are equally first-class (§3.1) — every profile gets exactly one `families` row regardless, sometimes with zero dependents attached, so "just subscribes for themselves" needs no special-case logic anywhere in the schema.

Next step: scaffolding the monorepo skeleton and the first migration (§3.1–3.2 tables + RLS helpers).
