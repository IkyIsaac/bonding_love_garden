-- Fixes a real bug found while testing checkout-create-order: GoTrue's admin
-- createUser (used to provision staff accounts with app_metadata.role) does
-- an INSERT into auth.users followed by a separate UPDATE that attaches
-- app_metadata/user_metadata — confirmed live via created_at != updated_at
-- (~8ms apart) on an admin-created user. handle_new_user only ran on INSERT,
-- so it always saw empty metadata: every admin-provisioned staff account
-- was silently created as a plain 'customer'/'pending' profile regardless of
-- the role passed in app_metadata.
--
-- Fix: also fire on UPDATE OF raw_app_meta_data, and reconcile role/
-- approval_status/full_name when they've drifted from what the (now
-- visible) metadata says. Guarded to be a no-op when nothing actually
-- changed, so this doesn't affect the ordinary customer self-signup path
-- (empty app_metadata -> stays 'customer'/'pending' either way).

create or replace function handle_new_user()
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
  if tg_op = 'INSERT' then
    insert into profiles (id, phone, full_name, role, approval_status)
    values (new.id, new.phone, v_full_name, v_role, v_approval_status)
    returning id into v_profile_id;

    insert into families (owner_profile_id)
    values (v_profile_id);
  else
    -- UPDATE: reconcile role/approval_status now that metadata has arrived.
    -- Bypasses prevent_profile_privilege_escalation via the transaction-
    -- local flag below — safe because this whole trigger only ever runs off
    -- auth.users writes, and that table is never reachable by a client
    -- request (not exposed via PostgREST/RLS at all), only by GoTrue itself
    -- or the service-role admin API. Same trust boundary as the INSERT
    -- branch, just arriving a moment later.
    perform set_config('app.bypass_role_guard', 'true', true);
    update profiles
    set role = v_role,
        approval_status = v_approval_status,
        full_name = case
          when new.raw_user_meta_data ->> 'full_name' is not null then v_full_name
          else full_name
        end
    where id = new.id
      and (role is distinct from v_role or approval_status is distinct from v_approval_status);
  end if;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert or update of raw_app_meta_data on auth.users
  for each row execute function handle_new_user();

create or replace function prevent_profile_privilege_escalation()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if not is_admin()
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
