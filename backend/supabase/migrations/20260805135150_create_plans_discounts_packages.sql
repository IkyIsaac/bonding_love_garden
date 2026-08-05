-- Plans, discounts, packages (docs/ARCHITECTURE_PLAN.md §3.3).
--
-- All world-readable / admin-managed, same shape as the venue config tables
-- from the previous migration — the customer app must be able to browse
-- plans, discounts (for checkout preview), and packages before login.

-- =============================================================================
-- Tables
-- =============================================================================

create table access_plans (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  plan_type text not null check (plan_type in ('single_visit', 'membership')),
  price numeric(12, 2) not null,
  validity_value int not null,
  validity_unit text not null
    check (validity_unit in ('minutes', 'hours', 'days', 'weeks', 'months', 'years')),
  visit_limit int, -- null = unlimited
  daily_time_limit_minutes int,
  is_active boolean not null default true,
  description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table access_plan_items (
  access_plan_id uuid not null references access_plans (id) on delete cascade,
  catalog_item_id uuid not null references catalog_items (id),
  primary key (access_plan_id, catalog_item_id)
);

comment on table access_plan_items is 'Which games/services a plan includes.';

create table discount_rules (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  discount_type text not null check (discount_type in ('percent', 'flat')),
  discount_value numeric(12, 2) not null,
  min_quantity int, -- e.g. "groups of 10+"
  valid_from timestamptz,
  valid_to timestamptz,
  days_of_week int[], -- e.g. {6,0} for Sat/Sun-only rules
  status text not null default 'draft' check (status in ('draft', 'enabled', 'disabled', 'archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table discount_rule_components (
  id uuid primary key default gen_random_uuid(),
  discount_rule_id uuid not null references discount_rules (id) on delete cascade,
  catalog_item_id uuid references catalog_items (id),
  is_entry_fee boolean not null default false,
  constraint discount_rule_components_target_check check (
    (catalog_item_id is not null and not is_entry_fee)
    or (catalog_item_id is null and is_entry_fee)
  )
);

comment on table discount_rule_components is 'Qualifying cart composition for a rule. A row targets exactly one of: a specific catalog_item, or the entry fee (is_entry_fee=true, catalog_item_id null). §3.3''s "catalog_item_id=NULL means entry fee" sketch can''t be a bare composite primary key as written — a NULL column value is disallowed in a PRIMARY KEY — so this uses a surrogate id + is_entry_fee flag + partial unique indexes below instead.';

create table packages (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  price numeric(12, 2) not null,
  availability_start timestamptz,
  availability_end timestamptz,
  image_url text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table package_items (
  package_id uuid not null references packages (id) on delete cascade,
  catalog_item_id uuid not null references catalog_items (id),
  quantity int not null default 1,
  primary key (package_id, catalog_item_id)
);

-- =============================================================================
-- Indexes
-- =============================================================================

-- Reverse lookups ("which plans/rules/packages reference this catalog item")
-- matter to the discount engine and admin catalog UI; the join tables' PKs
-- lead with the other column, so these aren't covered without a second index.
create index access_plan_items_catalog_item_id_idx on access_plan_items (catalog_item_id);
create index discount_rule_components_catalog_item_id_idx on discount_rule_components (catalog_item_id);
create index package_items_catalog_item_id_idx on package_items (catalog_item_id);
create index discount_rule_components_discount_rule_id_idx on discount_rule_components (discount_rule_id);

-- Uniqueness for discount_rule_components: at most one row per specific
-- catalog item per rule, and at most one entry-fee row per rule. Partial
-- indexes because catalog_item_id is nullable (see table comment above).
create unique index discount_rule_components_item_uniq
  on discount_rule_components (discount_rule_id, catalog_item_id)
  where catalog_item_id is not null;

create unique index discount_rule_components_entry_fee_uniq
  on discount_rule_components (discount_rule_id)
  where is_entry_fee;

-- =============================================================================
-- updated_at maintenance (set_updated_at() defined in the previous migration)
-- =============================================================================

create trigger set_updated_at before update on access_plans
  for each row execute function set_updated_at();

create trigger set_updated_at before update on discount_rules
  for each row execute function set_updated_at();

create trigger set_updated_at before update on packages
  for each row execute function set_updated_at();

-- =============================================================================
-- Row Level Security — same pattern as venue_settings/zones/catalog_items:
-- world-readable (incl. anon, for pre-login browsing), admin-managed.
-- =============================================================================

alter table access_plans enable row level security;
alter table access_plan_items enable row level security;
alter table discount_rules enable row level security;
alter table discount_rule_components enable row level security;
alter table packages enable row level security;
alter table package_items enable row level security;

create policy "access_plans_select" on access_plans for select using (true);
create policy "access_plans_insert" on access_plans for insert with check (is_admin());
create policy "access_plans_update" on access_plans for update using (is_admin()) with check (is_admin());
create policy "access_plans_delete" on access_plans for delete using (is_admin());

create policy "access_plan_items_select" on access_plan_items for select using (true);
create policy "access_plan_items_insert" on access_plan_items for insert with check (is_admin());
create policy "access_plan_items_update" on access_plan_items for update using (is_admin()) with check (is_admin());
create policy "access_plan_items_delete" on access_plan_items for delete using (is_admin());

create policy "discount_rules_select" on discount_rules for select using (true);
create policy "discount_rules_insert" on discount_rules for insert with check (is_admin());
create policy "discount_rules_update" on discount_rules for update using (is_admin()) with check (is_admin());
create policy "discount_rules_delete" on discount_rules for delete using (is_admin());

create policy "discount_rule_components_select" on discount_rule_components for select using (true);
create policy "discount_rule_components_insert" on discount_rule_components for insert with check (is_admin());
create policy "discount_rule_components_update" on discount_rule_components for update using (is_admin()) with check (is_admin());
create policy "discount_rule_components_delete" on discount_rule_components for delete using (is_admin());

create policy "packages_select" on packages for select using (true);
create policy "packages_insert" on packages for insert with check (is_admin());
create policy "packages_update" on packages for update using (is_admin()) with check (is_admin());
create policy "packages_delete" on packages for delete using (is_admin());

create policy "package_items_select" on package_items for select using (true);
create policy "package_items_insert" on package_items for insert with check (is_admin());
create policy "package_items_update" on package_items for update using (is_admin()) with check (is_admin());
create policy "package_items_delete" on package_items for delete using (is_admin());
