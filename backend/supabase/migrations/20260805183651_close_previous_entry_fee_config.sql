-- Real gap found while building the admin Plan Builder page: entry_fee_config
-- was designed insert-only/versioned ("never mutate a row") with deliberately
-- no UPDATE policy at all, not even for admin — but nothing ever actually
-- closed out the previous "current" row (effective_to) when a new one was
-- inserted. There was no way to do that from the client at all (no UPDATE
-- policy to use), and no trigger did it automatically either. Fixes it with
-- an AFTER INSERT trigger: closing the previous row is now fully automatic,
-- so admin only ever needs to INSERT (which they already can), matching the
-- "insert-only from the client's perspective" design intent instead of
-- silently being broken.

create function close_previous_entry_fee_config()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update entry_fee_config
  set effective_to = new.effective_from
  where effective_to is null
    and id <> new.id;
  return new;
end;
$$;

create trigger close_previous_entry_fee_config
  after insert on entry_fee_config
  for each row execute function close_previous_entry_fee_config();
