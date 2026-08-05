-- Data API role privileges.
--
-- Every RLS policy written so far (docs/ARCHITECTURE_PLAN.md §3.8) assumes
-- anon/authenticated/service_role can reach every table at the SQL-privilege
-- level, with RLS as the actual row-level gate on top. Newer Supabase no
-- longer auto-grants that by default for new tables — see the
-- `auto_expose_new_tables` comment in config.toml, which also notes that
-- flag is deprecated and scheduled for removal 2026-10-30. Relying on it
-- would break mid-project, so this grants explicitly instead: once,
-- retroactively, for every table created so far, and via ALTER DEFAULT
-- PRIVILEGES for every table any future migration creates. Confirmed via a
-- live `set role anon; select ...` test that without this, RLS never even
-- gets evaluated — the grant check fails first.
--
-- RLS remains the real authorization boundary — this only restores base
-- table reachability; it doesn't loosen anything the policies already lock
-- down (an admin-only INSERT policy still blocks anon/authenticated inserts
-- regardless of this grant).

grant usage on schema public to anon, authenticated, service_role;

grant select, insert, update, delete on all tables in schema public
  to anon, authenticated, service_role;

grant usage, select on all sequences in schema public
  to anon, authenticated, service_role;

alter default privileges in schema public
  grant select, insert, update, delete on tables to anon, authenticated, service_role;

alter default privileges in schema public
  grant usage, select on sequences to anon, authenticated, service_role;
