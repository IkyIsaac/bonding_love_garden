-- Fixes a real bug found while testing staff-approve-customer: that
-- function uses createAdminClient() (the service-role key), which bypasses
-- RLS but NOT table triggers — prevent_profile_privilege_escalation still
-- fired and rejected the approval_status change, since it only recognized
-- is_admin() (a real profiles.role='admin' caller) and the narrow
-- app.bypass_role_guard flag (scoped to handle_new_user's own auth.users
-- reconciliation branch, per its own comment).
--
-- Every Edge Function's actual authorization already happens in its own
-- application code (e.g. staff-approve-customer's isStaffRole(caller.role)
-- check) before it ever touches the admin client — by the time a query
-- reaches Postgres as service_role, that's the same trust boundary RLS
-- already grants a full bypass to. The trigger not recognizing that
-- boundary was the bug, not staff-approve-customer needing a workaround.

create or replace function prevent_profile_privilege_escalation()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if not is_admin()
     and auth.role() <> 'service_role'
     and coalesce(current_setting('app.bypass_role_guard', true), 'false') <> 'true'
     and (
       new.role is distinct from old.role
       or new.approval_status is distinct from old.approval_status
     )
  then
    raise exception 'Only an admin can change role or approval_status';
  end if;
  return new;
end;
$$;
