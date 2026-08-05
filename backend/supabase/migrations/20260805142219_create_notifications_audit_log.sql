-- Notifications & audit log (docs/ARCHITECTURE_PLAN.md §3.6) — the last of
-- the core schema migrations.

-- =============================================================================
-- Tables
-- =============================================================================

create table notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_profile_id uuid not null references profiles (id),
  type text not null, -- e.g. 'payment_confirmed' | 'membership_expiring' | 'session_update' — deliberately
                       -- unconstrained, same reasoning as audit_log.action_type below: this list grows as
                       -- more Edge Functions start sending notifications, and a CHECK here would mean a
                       -- migration every time a new one is added.
  title text not null,
  body text,
  payload jsonb,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create table audit_log (
  id uuid primary key default gen_random_uuid(),
  actor_profile_id uuid references profiles (id), -- nullable: some entries may be system-generated
  action_type text not null, -- 'registration' | 'pos_sale' | 'auth' | 'refund' | 'session_extend' | ... —
                              -- unconstrained for the same extensibility reason as notifications.type
  target_type text,
  target_id uuid, -- polymorphic reference, same accepted limitation as order_items.reference_id — this
                   -- table is only ever written by trusted Edge Functions via the service role, never a
                   -- raw client insert, so app-level correctness is an acceptable tradeoff here too
  details text,
  location text, -- zone/station name, matches the audit-log mockup
  status text not null default 'success' check (status in ('success', 'verified', 'failed')),
  created_at timestamptz not null default now()
);

comment on table audit_log is 'Insert-only, service-role only — no update/delete policy at all, not even for admin. Same treatment as payment_webhook_events: a compliance/dispute trail that has to be tamper-proof even from an admin''s own dashboard session, so the write path is exclusively Edge Function code, never the API.';

-- =============================================================================
-- Indexes
-- =============================================================================

create index notifications_recipient_profile_id_idx on notifications (recipient_profile_id);

create index audit_log_actor_profile_id_idx on audit_log (actor_profile_id);
create index audit_log_action_type_idx on audit_log (action_type);
create index audit_log_target_idx on audit_log (target_type, target_id);
create index audit_log_created_at_idx on audit_log (created_at desc);

-- =============================================================================
-- Row Level Security
-- =============================================================================

alter table notifications enable row level security;
alter table audit_log enable row level security;

-- notifications: own rows only, for everyone including staff — these are
-- personal (e.g. a specific supervisor's purchase alerts), not a shared feed.
-- No insert policy: created by Edge Functions/triggers via the service role.
create policy "notifications_select" on notifications for select
  using (recipient_profile_id = auth.uid() or is_admin());
create policy "notifications_update" on notifications for update
  using (recipient_profile_id = auth.uid() or is_admin())
  with check (recipient_profile_id = auth.uid() or is_admin());
create policy "notifications_insert" on notifications for insert with check (is_admin());
create policy "notifications_delete" on notifications for delete using (is_admin());

-- audit_log: admin can SELECT (confirmed: no supervisor visibility); nobody,
-- including admin, can write via the API — service role only.
create policy "audit_log_select" on audit_log for select using (is_admin());

-- =============================================================================
-- Realtime — the brief ties both live session countdowns (§4.11) and
-- instant purchase alerts to supervisors (§4.10) to Realtime specifically
-- rather than client polling. sessions was created in the previous
-- migration without this — adding it here isn't a schema change to that
-- table, just publication membership, so it doesn't need its own migration.
-- =============================================================================

alter publication supabase_realtime add table sessions;
alter publication supabase_realtime add table notifications;
