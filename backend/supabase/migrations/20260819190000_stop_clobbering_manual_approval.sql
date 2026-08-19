-- Fixes a real, recurring bug found via live client testing: an already-
-- approved customer's approval_status kept silently reverting to 'pending'
-- after a later login.
--
-- Root cause: handle_new_user's UPDATE branch (fires on any auth.users
-- update touching raw_app_meta_data, which GoTrue does on ordinary
-- sign-ins too, not just the admin-provisioning case it was written for)
-- unconditionally recomputed approval_status from role and overwrote
-- whatever staff had actually set it to. Its own "no-op guard" WHERE
-- clause (`approval_status is distinct from v_approval_status`) was the
-- bug, not a safety net — for any customer staff had approved, that's
-- always true (approved <> pending), so the update fired and clobbered
-- the approval on every single subsequent metadata touch.
--
-- Fix: only ever touch approval_status here when role is actually
-- changing (the real scenario this trigger exists for — an admin-created
-- staff account whose app_metadata.role arrives on a follow-up UPDATE).
-- A customer whose role never changes keeps whatever approval_status
-- staff set, indefinitely.

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
    perform set_config('app.bypass_role_guard', 'true', true);
    update profiles
    set role = v_role,
        approval_status = case
          when role is distinct from v_role then v_approval_status
          else approval_status
        end,
        full_name = case
          when new.raw_user_meta_data ->> 'full_name' is not null then v_full_name
          else full_name
        end
    where id = new.id
      and (
        role is distinct from v_role
        or (
          new.raw_user_meta_data ->> 'full_name' is not null
          and full_name is distinct from v_full_name
        )
      );
  end if;

  return new;
end;
$$;
