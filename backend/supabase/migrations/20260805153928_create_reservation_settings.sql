-- Fills a real gap found while designing reservations-book: brief §4.7 says
-- reservation rules ("how far ahead, how many per day, fee amount") are
-- owner-configurable, but no config table for that existed anywhere in the
-- schema — reservations.fee is stored per-row (correct, it's a snapshot),
-- but nothing held the *defaults* an owner sets. Same singleton pattern as
-- venue_settings.

create table reservation_settings (
  id uuid primary key default gen_random_uuid(),
  singleton boolean not null default true,
  max_advance_days int not null default 30,
  max_per_day_per_family int, -- null = unlimited
  default_fee numeric(12, 2) not null default 0,
  updated_at timestamptz not null default now(),
  constraint reservation_settings_singleton_true check (singleton),
  constraint reservation_settings_only_one_row unique (singleton)
);

comment on table reservation_settings is 'Exactly one row (singleton constraint, same as venue_settings). Owner-configurable reservation rules per brief §4.7.';

create trigger set_updated_at before update on reservation_settings
  for each row execute function set_updated_at();

alter table reservation_settings enable row level security;

create policy "reservation_settings_select" on reservation_settings for select using (true);
create policy "reservation_settings_update" on reservation_settings for update
  using (is_admin()) with check (is_admin());
-- No insert/delete policy: the single row is seeded below, same reasoning
-- as venue_settings — the singleton constraint blocks a second row and
-- there's deliberately no way to end up with zero rows via the API.

insert into reservation_settings (max_advance_days, max_per_day_per_family, default_fee)
values (30, 3, 0);
