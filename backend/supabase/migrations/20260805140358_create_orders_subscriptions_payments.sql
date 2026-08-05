-- Subscriptions, reservations, orders, payments (docs/ARCHITECTURE_PLAN.md §3.4).
--
-- Financial writes (subscriptions, orders, order_items,
-- order_discount_applications, payments) deliberately get NO insert/update
-- policy for anon/authenticated at all — only admin (dashboard corrections)
-- and service_role (Edge Functions, which bypass RLS entirely) can write
-- them. This is stronger than trying to encode "must go through
-- checkout-create-order" as an RLS rule — RLS can't distinguish a trusted
-- Edge Function call from a raw client request when both present the same
-- authenticated role, so the only real guarantee is not granting the write
-- policy at all. reservations is the one exception: the brief has customers
-- booking time slots directly, so it gets a real customer-facing INSERT/
-- UPDATE policy (reservations-book, §4, adds business-rule validation like
-- lead time/day caps on top of this, but the row-level grant itself is
-- customer-owned).

-- =============================================================================
-- Tables
-- =============================================================================

create table subscriptions (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references families (id),
  family_member_id uuid references family_members (id), -- null = applies to the account owner
  access_plan_id uuid not null references access_plans (id),
  entry_fee_config_id uuid references entry_fee_config (id), -- fee snapshot at purchase
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  visits_remaining int,
  status text not null default 'pending_payment'
    check (status in ('pending_payment', 'active', 'expired', 'cancelled', 'suspended')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table reservations (
  id uuid primary key default gen_random_uuid(),
  subscription_id uuid not null references subscriptions (id),
  catalog_item_id uuid not null references catalog_items (id),
  slot_start timestamptz not null,
  slot_end timestamptz not null,
  fee numeric(12, 2) not null default 0,
  status text not null default 'booked'
    check (status in ('booked', 'checked_in', 'cancelled', 'no_show')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table orders (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references families (id),
  buyer_profile_id uuid not null references profiles (id), -- customer, or staff acting on their behalf
  channel text not null check (channel in ('customer_app', 'staff_app', 'web_admin')),
  subtotal numeric(12, 2) not null,
  discount_total numeric(12, 2) not null default 0,
  entry_fee_total numeric(12, 2) not null default 0,
  total_amount numeric(12, 2) not null,
  status text not null default 'pending'
    check (status in ('pending', 'paid', 'failed', 'refunded', 'cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references orders (id) on delete cascade,
  item_type text not null check (item_type in
    ('access_plan', 'package', 'reservation_fee', 'entry_fee', 'guest_pass', 'credit_topup')),
  reference_id uuid, -- FK target depends on item_type (access_plan_id / package_id / reservation_id); not
                      -- enforceable as a real FK since it's polymorphic — left as an app-level invariant,
                      -- acceptable because this table is only ever written by the trusted
                      -- checkout-create-order Edge Function (service role), never a raw client insert.
  family_member_id uuid references family_members (id), -- who this line item is for; null = account owner
  guest_name text, -- populated only for item_type='guest_pass'
  quantity int not null default 1,
  unit_price numeric(12, 2) not null,
  line_total numeric(12, 2) not null,
  created_at timestamptz not null default now(),
  constraint order_items_guest_name_matches_type check (
    (item_type = 'guest_pass') = (guest_name is not null)
  )
);

create table order_discount_applications (
  order_id uuid not null references orders (id) on delete cascade,
  discount_rule_id uuid not null references discount_rules (id),
  amount_deducted numeric(12, 2) not null,
  primary key (order_id, discount_rule_id)
);

comment on table order_discount_applications is 'Audit trail: exactly which rule(s) fired on an order and for how much. Independent of discount_rules'' current state, so changing/archiving a rule later never rewrites past orders.';

create table payment_providers (
  id uuid primary key default gen_random_uuid(),
  code text not null unique, -- 'selcom' | 'snippe' | 'payguard' | ... — pluggable: add a row, not a migration
  display_name text not null,
  is_active boolean not null default true,
  public_config jsonb, -- non-secret display config only; real credentials live in Edge Function env vars
  sort_order int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table payments (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references orders (id),
  provider_id uuid not null references payment_providers (id),
  provider_reference text, -- provider's transaction id
  amount numeric(12, 2) not null,
  status text not null default 'pending'
    check (status in ('pending', 'processing', 'succeeded', 'failed', 'refunded')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table payment_webhook_events (
  id uuid primary key default gen_random_uuid(),
  provider_id uuid references payment_providers (id),
  payment_id uuid references payments (id),
  event_type text,
  payload jsonb not null,
  signature_verified boolean not null,
  processed_at timestamptz,
  created_at timestamptz not null default now()
);

comment on table payment_webhook_events is 'Raw inbound log, service-role only. No update/delete policy at all — not even for admin — matching §3.8: even admin is read-only here via the dashboard, never edits it.';

-- =============================================================================
-- Indexes
-- =============================================================================

create index subscriptions_family_id_idx on subscriptions (family_id);
create index subscriptions_family_member_id_idx on subscriptions (family_member_id);
create index subscriptions_access_plan_id_idx on subscriptions (access_plan_id);

create index reservations_subscription_id_idx on reservations (subscription_id);
create index reservations_catalog_item_id_idx on reservations (catalog_item_id);

create index orders_family_id_idx on orders (family_id);
create index orders_buyer_profile_id_idx on orders (buyer_profile_id);

create index order_items_order_id_idx on order_items (order_id);
create index order_items_family_member_id_idx on order_items (family_member_id);

create index payments_order_id_idx on payments (order_id);
create index payments_provider_id_idx on payments (provider_id);

-- Idempotency: a given provider transaction should map to exactly one
-- payments row (the webhook handler updates this row's status in place
-- rather than inserting a new one on each callback).
create unique index payments_provider_reference_uniq
  on payments (provider_id, provider_reference)
  where provider_reference is not null;

create index payment_webhook_events_provider_id_idx on payment_webhook_events (provider_id);
create index payment_webhook_events_payment_id_idx on payment_webhook_events (payment_id);

-- =============================================================================
-- RLS helper functions (build on is_admin/is_staff/owns_family from the
-- identity migration)
-- =============================================================================

create function owns_subscription(sid uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from subscriptions s where s.id = sid and owns_family(s.family_id)
  );
$$;

create function owns_order(oid uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from orders o where o.id = oid and owns_family(o.family_id)
  );
$$;

-- =============================================================================
-- updated_at maintenance
-- =============================================================================

create trigger set_updated_at before update on subscriptions
  for each row execute function set_updated_at();

create trigger set_updated_at before update on reservations
  for each row execute function set_updated_at();

create trigger set_updated_at before update on orders
  for each row execute function set_updated_at();

create trigger set_updated_at before update on payment_providers
  for each row execute function set_updated_at();

create trigger set_updated_at before update on payments
  for each row execute function set_updated_at();

-- =============================================================================
-- Row Level Security
-- =============================================================================

alter table subscriptions enable row level security;
alter table reservations enable row level security;
alter table orders enable row level security;
alter table order_items enable row level security;
alter table order_discount_applications enable row level security;
alter table payment_providers enable row level security;
alter table payments enable row level security;
alter table payment_webhook_events enable row level security;

-- subscriptions: read-scoped to own family + staff/admin; writes admin-only
-- (created via checkout-create-order using the service role, which bypasses
-- RLS — see the file header).
create policy "subscriptions_select" on subscriptions for select
  using (owns_family(family_id) or is_staff() or is_admin());
create policy "subscriptions_insert" on subscriptions for insert with check (is_admin());
create policy "subscriptions_update" on subscriptions for update using (is_admin()) with check (is_admin());
create policy "subscriptions_delete" on subscriptions for delete using (is_admin());

-- reservations: the one customer-writable table in this migration.
create policy "reservations_select" on reservations for select
  using (owns_subscription(subscription_id) or is_staff() or is_admin());
create policy "reservations_insert" on reservations for insert
  with check (owns_subscription(subscription_id) or is_staff() or is_admin());
create policy "reservations_update" on reservations for update
  using (owns_subscription(subscription_id) or is_staff() or is_admin())
  with check (owns_subscription(subscription_id) or is_staff() or is_admin());
create policy "reservations_delete" on reservations for delete using (is_admin());

-- orders / order_items / order_discount_applications: read-scoped, admin-only writes.
create policy "orders_select" on orders for select
  using (owns_family(family_id) or is_staff() or is_admin());
create policy "orders_insert" on orders for insert with check (is_admin());
create policy "orders_update" on orders for update using (is_admin()) with check (is_admin());
create policy "orders_delete" on orders for delete using (is_admin());

create policy "order_items_select" on order_items for select
  using (owns_order(order_id) or is_staff() or is_admin());
create policy "order_items_insert" on order_items for insert with check (is_admin());
create policy "order_items_update" on order_items for update using (is_admin()) with check (is_admin());
create policy "order_items_delete" on order_items for delete using (is_admin());

create policy "order_discount_applications_select" on order_discount_applications for select
  using (owns_order(order_id) or is_staff() or is_admin());
create policy "order_discount_applications_insert" on order_discount_applications for insert
  with check (is_admin());
create policy "order_discount_applications_update" on order_discount_applications for update
  using (is_admin()) with check (is_admin());
create policy "order_discount_applications_delete" on order_discount_applications for delete
  using (is_admin());

-- payment_providers: customer sees active rows only; staff sees all; admin manages.
create policy "payment_providers_select" on payment_providers for select
  using (is_active or is_staff() or is_admin());
create policy "payment_providers_insert" on payment_providers for insert with check (is_admin());
create policy "payment_providers_update" on payment_providers for update using (is_admin()) with check (is_admin());
create policy "payment_providers_delete" on payment_providers for delete using (is_admin());

-- payments: read-scoped, admin-only writes.
create policy "payments_select" on payments for select
  using (owns_order(order_id) or is_staff() or is_admin());
create policy "payments_insert" on payments for insert with check (is_admin());
create policy "payments_update" on payments for update using (is_admin()) with check (is_admin());
create policy "payments_delete" on payments for delete using (is_admin());

-- payment_webhook_events: admin can SELECT for troubleshooting; nobody
-- (including admin) can write via the API — only the service role, from the
-- webhook Edge Functions.
create policy "payment_webhook_events_select" on payment_webhook_events for select
  using (is_admin());
