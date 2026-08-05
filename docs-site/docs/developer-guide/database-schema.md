---
sidebar_position: 2
---

# Database Schema

The schema lives in `backend/supabase/migrations/`, applied in order. Every table has Row Level Security enabled — there is no table in this schema that relies on application code alone to keep one family's data away from another's.

## Entity groups

| Group | Tables | RLS shape |
|---|---|---|
| Identity & family | `profiles`, `families`, `family_members` | Self/own-family read+write; staff read customer profiles; admin full |
| Venue config | `venue_settings`, `zones`, `catalog_items`, `entry_fee_config` | World-readable (incl. anonymous — the customer app browses pre-login); admin-only writes |
| Plans, discounts, packages | `access_plans`, `access_plan_items`, `discount_rules`, `discount_rule_components`, `packages`, `package_items` | Same as venue config |
| Orders & payments | `subscriptions`, `reservations`, `orders`, `order_items`, `order_discount_applications`, `payment_providers`, `payments`, `payment_webhook_events` | Read scoped to own family; **no client write policy at all** except `reservations` and admin — see below |
| Wallet, wristbands, sessions | `game_credit_ledger`, `wristbands`, `sessions` + 3 live-status views | Same "no client write" pattern; `sessions` UPDATE is the one deliberate supervisor-only exception |
| Notifications & audit | `notifications`, `audit_log` | Own-row only; `audit_log` is read-only even for admin — nobody writes it via the API |

## Why financial tables have no client-writable RLS policy

RLS can't distinguish a trusted Edge Function call from a raw client request — both arrive as the `authenticated` role. The only real guarantee that "orders only get created through `checkout-create-order`" is to not grant the INSERT policy to `authenticated` at all. The service role (which Edge Functions use) bypasses RLS entirely, so it's unaffected. Admin gets full CRUD everywhere for manual dashboard corrections.

`reservations` is the deliberate exception — the brief has customers booking time slots directly, so it gets a real customer-facing INSERT/UPDATE policy, with `reservations-book` adding the lead-time/per-day-cap business-rule validation RLS can't express on top.

## Bugs a straight schema read wouldn't have caught

Every one of these was found by testing against a real Postgres instance, not by reviewing SQL:

- **Views bypass RLS by default.** Postgres views run with the *owner's* privileges unless you set `security_invoker = true`. `session_live_status`, `wristband_live_status`, and `family_credit_balance` all needed it — without it, an unrelated customer could read another family's wallet balance through the view even though the base table correctly blocked them.
- **A NULL value can't sit inside a PRIMARY KEY.** `discount_rule_components` originally tried to use `catalog_item_id = NULL` as an "entry fee" sentinel inside a composite primary key — invalid SQL. Fixed with a surrogate id, an explicit `is_entry_fee` boolean, a CHECK constraint enforcing exactly one target, and partial unique indexes.
- **Supabase's current default doesn't auto-expose new tables** to the `anon`/`authenticated` Data API roles the way older versions did. Every table needed an explicit grant (plus `ALTER DEFAULT PRIVILEGES` so future migrations don't need to repeat it) — without this, RLS was never even being evaluated, the grant check failed first.
- **GoTrue populates `app_metadata` via a separate UPDATE after the initial INSERT** into `auth.users`. The profile-bootstrap trigger only fired on INSERT, so every admin-provisioned staff account was silently created as a plain `customer`. Fixed by also firing on `UPDATE OF raw_app_meta_data`.
- **`entry_fee_config` had no mechanism to close out the previous version.** It's insert-only by design (no UPDATE policy at all, not even for admin), but nothing ever set the old row's `effective_to` when a new one was inserted. Fixed with an `AFTER INSERT` trigger that does it automatically.

## Session status is computed, not stored

"Active / expiring soon / expired" is a function of `now()` vs `planned_end_at` — storing and cron-updating that value invites drift. `session_live_status` computes it live in a view instead, and both clients subscribe to the underlying `sessions` table via Supabase Realtime so any change (extend, end) pushes instantly.
