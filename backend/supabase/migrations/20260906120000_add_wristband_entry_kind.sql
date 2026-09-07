-- Distinguishes *why* a wristband has no subscription_id (docs/ARCHITECTURE_PLAN.md
-- §4.9's wallet-credit gap, closed here).
--
-- wristbands.subscription_id being null already meant one thing
-- ("complimentary staff-issued pass" per that column's own comment). Package
-- checkout (Option 2, decided with the product owner: buying a package
-- credits game_credit_ledger rather than creating a subscription) now needs
-- a second, behaviorally different reason for a null subscription_id: a
-- wristband whose holder pays per game out of their wallet balance at
-- scan-time. Overloading "subscription_id is null" to mean both "free,
-- unmetered entry" and "metered, credit-charged entry" would make
-- session-scan-admit's admission logic silently wrong for one of the two —
-- an explicit column is the honest fix, same reasoning discount_rule_components
-- gave for not overloading a nullable catalog_item_id with two meanings.

alter table wristbands
  add column entry_kind text not null default 'subscription'
    check (entry_kind in ('subscription', 'complimentary', 'wallet_credits'));

comment on column wristbands.entry_kind is
  'subscription: subscription_id is set, plan-inclusion gates entry (existing behavior). complimentary: staff-issued free pass, no charge ever. wallet_credits: issued for a package purchase, session-scan-admit charges 1 game_credit_ledger credit per new admission to a specific game.';

-- Backfill: every wristband issued before this column existed with a null
-- subscription_id was, at the time, only ever a complimentary pass (the
-- wallet_credits path didn't exist yet) — the default above already covers
-- subscription-backed rows correctly, this corrects the other case.
update wristbands set entry_kind = 'complimentary' where subscription_id is null;
