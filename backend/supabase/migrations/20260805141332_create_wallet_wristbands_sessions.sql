-- Credit wallet, wristbands, sessions (docs/ARCHITECTURE_PLAN.md §3.5) +
-- their supporting live-status views (§3.7).
--
-- Table order deviates from §3.5's listing: the plan shows
-- game_credit_ledger before wristbands, but game_credit_ledger.wristband_id
-- references wristbands(id) — wristbands has to exist first.

-- =============================================================================
-- Tables
-- =============================================================================

create table wristbands (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references families (id),
  family_member_id uuid references family_members (id), -- null = account owner
  subscription_id uuid references subscriptions (id), -- nullable: e.g. a complimentary staff-issued pass
  qr_code_value text not null unique,
  wristband_number text not null,
  status text not null default 'active' check (status in ('active', 'expired', 'revoked')),
  issued_at timestamptz not null default now(),
  expires_at timestamptz not null,
  last_scanned_at timestamptz,
  issued_by uuid references profiles (id), -- staff profile, if issued in person
  updated_at timestamptz not null default now()
);

comment on table wristbands is 'status only ever needs to be explicitly set to ''revoked'' (a real staff action) or left at the ''active'' default — nothing needs to proactively flip it to ''expired''. Effective validity (incl. expiry) is computed live by wristband_live_status below, same reasoning as sessions in §3.5''s own note: storing and cron-reconciling a status that''s really a function of now() vs expires_at invites drift.';

create table game_credit_ledger (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references families (id),
  family_member_id uuid references family_members (id),
  order_id uuid references orders (id), -- source, if earned via purchase
  wristband_id uuid references wristbands (id), -- destination, if redeemed
  direction text not null check (direction in ('earned', 'redeemed', 'adjusted')),
  amount int not null,
  reason text,
  created_by uuid references profiles (id), -- staff adjustments are attributable
  created_at timestamptz not null default now(),
  constraint game_credit_ledger_amount_sign_check check (
    (direction in ('earned', 'redeemed') and amount > 0)
    or (direction = 'adjusted' and amount <> 0)
  )
);

comment on table game_credit_ledger is 'Append-only — no updated_at, rows are never modified after insert. amount''s sign rule fixes a gap in the plan''s sketch: "amount always positive, direction determines sign" left no way to model a downward correction (e.g. reversing an over-credit). earned/redeemed stay strictly positive (unambiguous real-world meaning); adjusted may be negative, and family_credit_balance below sums it as-is.';

create table sessions (
  id uuid primary key default gen_random_uuid(),
  wristband_id uuid not null references wristbands (id),
  catalog_item_id uuid references catalog_items (id),
  zone_id uuid references zones (id),
  started_at timestamptz not null default now(),
  planned_end_at timestamptz not null,
  ended_at timestamptz, -- set only on explicit staff "End" action
  extended_minutes_total int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint sessions_planned_end_after_start check (planned_end_at > started_at),
  constraint sessions_ended_not_before_start check (ended_at is null or ended_at >= started_at)
);

-- =============================================================================
-- Indexes
-- =============================================================================

create index wristbands_family_id_idx on wristbands (family_id);
create index wristbands_family_member_id_idx on wristbands (family_member_id);
create index wristbands_subscription_id_idx on wristbands (subscription_id);

create index game_credit_ledger_family_id_idx on game_credit_ledger (family_id);
create index game_credit_ledger_family_member_id_idx on game_credit_ledger (family_member_id);
create index game_credit_ledger_order_id_idx on game_credit_ledger (order_id);
create index game_credit_ledger_wristband_id_idx on game_credit_ledger (wristband_id);

create index sessions_wristband_id_idx on sessions (wristband_id);
create index sessions_catalog_item_id_idx on sessions (catalog_item_id);
create index sessions_zone_id_idx on sessions (zone_id);

-- =============================================================================
-- Supporting views (§3.7) — computed live, never stored, so nothing needs a
-- cron job to keep them accurate.
--
-- security_invoker = true on every one of these: Postgres views run with the
-- OWNER's privileges by default (postgres, which bypasses RLS), not the
-- querying user's — without this, every view here would silently leak every
-- family's rows to any authenticated user regardless of the RLS policies on
-- the underlying tables. Confirmed live before adding this: an unrelated
-- customer saw 0 rows querying game_credit_ledger directly (RLS working) but
-- 1 row querying family_credit_balance (RLS bypassed via the view). Postgres
-- 15+ feature, available here (local Postgres is 17).
-- =============================================================================

create view session_live_status
with (security_invoker = true)
as
select s.*,
  case
    when s.ended_at is not null then 'ended'
    when now() > s.planned_end_at then 'expired'
    when s.planned_end_at - now() < interval '10 minutes' then 'expiring_soon'
    else 'active'
  end as status
from sessions s;

create view wristband_live_status
with (security_invoker = true)
as
select w.*,
  case
    when w.status = 'revoked' then 'revoked'
    when now() > w.expires_at then 'expired'
    else 'active'
  end as live_status
from wristbands w;

create view family_credit_balance
with (security_invoker = true)
as
select family_id,
  sum(case when direction = 'earned' then amount
           when direction = 'redeemed' then -amount
           else amount end) as balance
from game_credit_ledger
group by family_id;

-- =============================================================================
-- RLS helper functions
-- =============================================================================

create function owns_wristband(wid uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from wristbands w where w.id = wid and owns_family(w.family_id)
  );
$$;

create function is_supervisor()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from profiles
    where id = auth.uid() and role = 'supervisor' and approval_status = 'approved'
  );
$$;

-- =============================================================================
-- updated_at maintenance
-- =============================================================================

create trigger set_updated_at before update on wristbands
  for each row execute function set_updated_at();

create trigger set_updated_at before update on sessions
  for each row execute function set_updated_at();

-- =============================================================================
-- Row Level Security
--
-- wristbands and game_credit_ledger follow the same "no non-admin write
-- policy at all" principle as orders/payments/subscriptions in the previous
-- migration — wristband-issue and wallet-redeem (§4) write these using the
-- service role. sessions gets a deliberate, narrower exception: §3.8
-- explicitly grants supervisors a direct UPDATE (extend/end) via RLS on top
-- of session-scan-admit/sessions-manage (§4) — the two aren't mutually
-- exclusive, this is defense in depth, same pattern as reservations getting
-- both a direct RLS grant and an Edge Function that adds business-rule
-- validation on top.
-- =============================================================================

alter table wristbands enable row level security;
alter table game_credit_ledger enable row level security;
alter table sessions enable row level security;

create policy "wristbands_select" on wristbands for select
  using (owns_family(family_id) or is_staff() or is_admin());
create policy "wristbands_insert" on wristbands for insert with check (is_admin());
create policy "wristbands_update" on wristbands for update using (is_admin()) with check (is_admin());
create policy "wristbands_delete" on wristbands for delete using (is_admin());

create policy "game_credit_ledger_select" on game_credit_ledger for select
  using (owns_family(family_id) or is_staff() or is_admin());
create policy "game_credit_ledger_insert" on game_credit_ledger for insert with check (is_admin());
create policy "game_credit_ledger_update" on game_credit_ledger for update
  using (is_admin()) with check (is_admin());
create policy "game_credit_ledger_delete" on game_credit_ledger for delete using (is_admin());

create policy "sessions_select" on sessions for select
  using (owns_wristband(wristband_id) or is_staff() or is_admin());
create policy "sessions_insert" on sessions for insert with check (is_admin());
create policy "sessions_update" on sessions for update
  using (is_supervisor() or is_admin())
  with check (is_supervisor() or is_admin());
create policy "sessions_delete" on sessions for delete using (is_admin());
