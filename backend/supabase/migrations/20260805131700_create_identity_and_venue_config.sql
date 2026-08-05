-- Identity & family (docs/ARCHITECTURE_PLAN.md §3.1) + venue config (§3.2)
-- + RLS helper functions and policies (§3.8).
--
-- Auth is phone-OTP only via Supabase Auth (brief §3) — no email/password path.

create extension if not exists "pgcrypto";

-- =============================================================================
-- Tables
-- =============================================================================

create table profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  phone text not null unique, -- E.164, source of truth (not email)
  full_name text not null default '',
  role text not null check (role in ('customer', 'cashier', 'attendant', 'supervisor', 'admin')),
  approval_status text not null default 'pending'
    check (approval_status in ('pending', 'approved', 'rejected', 'suspended')),
  photo_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table profiles is '1:1 extension of auth.users. Row is created by the handle_new_user trigger, never inserted directly by clients.';

create table families (
  id uuid primary key default gen_random_uuid(),
  owner_profile_id uuid not null references profiles (id),
  display_name text, -- e.g. "The Chen Family" — optional, reportable unit
  created_at timestamptz not null default now()
);

comment on table families is 'Every profile gets exactly one family row on signup, even individual customers with zero family_members (§3.1) — keeps ownership uniformly family_id everywhere.';

create table family_members (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references families (id) on delete cascade,
  kind text not null check (kind in ('child', 'dependent_adult')),
  full_name text not null,
  age int,
  gender text check (gender in ('male', 'female', 'other')),
  photo_url text,
  allergies_notes text,
  general_notes text,
  is_primary_child boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table venue_settings (
  id uuid primary key default gen_random_uuid(),
  singleton boolean not null default true,
  park_name text not null,
  logo_url text,
  brand_colors jsonb, -- {primary, accent, ...} consumed by both clients at runtime
  timezone text not null default 'Africa/Dar_es_Salaam',
  currency text not null default 'TZS',
  contact_info jsonb,
  updated_at timestamptz not null default now(),
  constraint venue_settings_singleton_true check (singleton),
  constraint venue_settings_only_one_row unique (singleton)
);

comment on table venue_settings is 'Exactly one row, enforced by the singleton unique constraint. Holds venue branding/config so nothing is hardcoded in the codebase (brief §1).';

create table zones (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  capacity int,
  is_active boolean not null default true
);

create table catalog_items (
  id uuid primary key default gen_random_uuid(),
  type text not null check (type in ('game', 'service')),
  name text not null,
  description text,
  is_motorized boolean, -- meaningful only when type='game'; null for services
  price numeric(12, 2) not null,
  pricing_unit text not null default 'flat' check (pricing_unit in ('flat', 'hourly')),
  zone_id uuid references zones (id),
  image_url text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table catalog_items is 'Unifies games and services — both are purchasable/discountable "components" (§3.2). type + is_motorized preserve the brief''s separate games/services distinction.';

create table entry_fee_config (
  id uuid primary key default gen_random_uuid(),
  amount numeric(12, 2) not null,
  effective_from timestamptz not null default now(),
  effective_to timestamptz, -- null = current
  created_by uuid references profiles (id)
);

comment on table entry_fee_config is 'Versioned, insert-only — never mutate a row (no UPDATE policy at all; see RLS section below). Historical orders keep the fee that applied at purchase time.';

-- =============================================================================
-- Indexes (FK columns queried/joined constantly, incl. by the RLS helpers below)
-- =============================================================================

create index families_owner_profile_id_idx on families (owner_profile_id);
create index family_members_family_id_idx on family_members (family_id);
create index catalog_items_zone_id_idx on catalog_items (zone_id);
create index profiles_role_idx on profiles (role);

-- =============================================================================
-- updated_at maintenance
-- =============================================================================

create function set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger set_updated_at before update on profiles
  for each row execute function set_updated_at();

create trigger set_updated_at before update on family_members
  for each row execute function set_updated_at();

create trigger set_updated_at before update on venue_settings
  for each row execute function set_updated_at();

create trigger set_updated_at before update on catalog_items
  for each row execute function set_updated_at();

-- =============================================================================
-- RLS helper functions (§3.8)
--
-- SECURITY DEFINER + a pinned search_path: these read profiles/families on
-- behalf of the caller regardless of the caller's own RLS visibility into
-- those tables, which is what avoids recursive/self-blocking policies when
-- profiles' and families' own RLS policies call these same functions.
-- =============================================================================

create function is_staff()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from profiles
    where id = auth.uid()
      and role in ('cashier', 'attendant', 'supervisor', 'admin')
      and approval_status = 'approved'
  );
$$;

create function is_admin()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from profiles where id = auth.uid() and role = 'admin'
  );
$$;

create function owns_family(fid uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from families where id = fid and owner_profile_id = auth.uid()
  );
$$;

-- =============================================================================
-- New-user bootstrap (profiles + families row on signup)
--
-- role is read from raw_app_meta_data, NOT raw_user_meta_data: app_metadata
-- can only be set via the Supabase service role / admin API, never by the
-- client's own signUp() call, so a self-registering customer cannot pass
-- {"role":"admin"} through signup options and grant themselves staff access.
-- Staff/admin accounts must be provisioned through a trusted, admin-only path
-- that calls supabase.auth.admin.createUser({ app_metadata: { role: ... } }).
-- =============================================================================

create function handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_role text := coalesce(new.raw_app_meta_data ->> 'role', 'customer');
  v_full_name text := coalesce(new.raw_user_meta_data ->> 'full_name', '');
  v_approval_status text := case when v_role = 'customer' then 'pending' else 'approved' end;
  v_profile_id uuid;
begin
  insert into profiles (id, phone, full_name, role, approval_status)
  values (new.id, new.phone, v_full_name, v_role, v_approval_status)
  returning id into v_profile_id;

  insert into families (owner_profile_id)
  values (v_profile_id);

  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

-- =============================================================================
-- Privilege-escalation guard on profiles
--
-- The UPDATE policy below lets a user update their own profile row (to edit
-- full_name/photo_url). Without this trigger that would also let them PATCH
-- their own role/approval_status straight to 'admin'/'approved' — RLS row
-- policies alone don't do column-level restriction, so this closes that gap
-- regardless of who issues the UPDATE.
-- =============================================================================

create function prevent_profile_privilege_escalation()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if not is_admin() and (
    new.role is distinct from old.role
    or new.approval_status is distinct from old.approval_status
  ) then
    raise exception 'Only an admin can change role or approval_status';
  end if;
  return new;
end;
$$;

create trigger prevent_profile_privilege_escalation
  before update on profiles
  for each row execute function prevent_profile_privilege_escalation();

-- =============================================================================
-- Row Level Security (§3.8)
-- =============================================================================

alter table profiles enable row level security;
alter table families enable row level security;
alter table family_members enable row level security;
alter table venue_settings enable row level security;
alter table zones enable row level security;
alter table catalog_items enable row level security;
alter table entry_fee_config enable row level security;

-- profiles: self, staff can view customer profiles, admin has full access.
-- No client-side INSERT policy — rows are created only by handle_new_user().
create policy "profiles_select" on profiles for select
  using (id = auth.uid() or is_admin() or (is_staff() and role = 'customer'));

create policy "profiles_update" on profiles for update
  using (id = auth.uid() or is_admin())
  with check (id = auth.uid() or is_admin());

create policy "profiles_delete" on profiles for delete
  using (is_admin());

-- families: owner, staff (assisted registration), admin.
create policy "families_select" on families for select
  using (owns_family(id) or is_staff() or is_admin());

create policy "families_insert" on families for insert
  with check (owner_profile_id = auth.uid() or is_staff() or is_admin());

create policy "families_update" on families for update
  using (owns_family(id) or is_staff() or is_admin())
  with check (owns_family(id) or is_staff() or is_admin());

create policy "families_delete" on families for delete
  using (is_admin());

-- family_members: same shape as families, scoped via family_id.
create policy "family_members_select" on family_members for select
  using (owns_family(family_id) or is_staff() or is_admin());

create policy "family_members_insert" on family_members for insert
  with check (owns_family(family_id) or is_staff() or is_admin());

create policy "family_members_update" on family_members for update
  using (owns_family(family_id) or is_staff() or is_admin())
  with check (owns_family(family_id) or is_staff() or is_admin());

create policy "family_members_delete" on family_members for delete
  using (is_admin());

-- venue_settings / zones / catalog_items: world-readable (incl. anon — the
-- customer app browses plans/games before login), admin-managed.
create policy "venue_settings_select" on venue_settings for select using (true);
create policy "venue_settings_update" on venue_settings for update
  using (is_admin()) with check (is_admin());
-- No insert/delete policy: the single row is seeded below; the singleton
-- constraint blocks a second row, and there is deliberately no way to end up
-- with zero rows via the API.

create policy "zones_select" on zones for select using (true);
create policy "zones_insert" on zones for insert with check (is_admin());
create policy "zones_update" on zones for update using (is_admin()) with check (is_admin());
create policy "zones_delete" on zones for delete using (is_admin());

create policy "catalog_items_select" on catalog_items for select using (true);
create policy "catalog_items_insert" on catalog_items for insert with check (is_admin());
create policy "catalog_items_update" on catalog_items for update using (is_admin()) with check (is_admin());
create policy "catalog_items_delete" on catalog_items for delete using (is_admin());

-- entry_fee_config: world-readable, admin can INSERT a new version.
-- No UPDATE/DELETE policy at all — enforces "insert a new version, never
-- mutate a row" at the database layer, not just by convention.
create policy "entry_fee_config_select" on entry_fee_config for select using (true);
create policy "entry_fee_config_insert" on entry_fee_config for insert with check (is_admin());

-- =============================================================================
-- Seed the venue_settings singleton
--
-- Not branding — a generic placeholder the admin renames via Settings. The
-- table must always have exactly one row (see comment above), so it can't be
-- left for a manual seed step.
-- =============================================================================

insert into venue_settings (park_name, timezone, currency)
values ('Unnamed Venue', 'Africa/Dar_es_Salaam', 'TZS');
