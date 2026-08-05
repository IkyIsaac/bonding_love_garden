---
sidebar_position: 2
---

# Admin Dashboard

## Logging in

Go to the dashboard's `/login` page and enter your phone number. You'll receive a text with a 6-digit code — enter it to sign in. There's no password: every account (admin included) uses phone + code, the same way parents and staff sign in on the mobile app.

Only accounts with admin access can use the dashboard. If you sign in successfully but see a "not authorized" message, your account exists but hasn't been granted admin access — ask whoever manages the platform to upgrade it.

## Plan Builder

Everything about what you sell lives here, in three sections:

**Entry Fee** — the constant admission charge applied to every visit. Setting a new amount doesn't overwrite the old one: past receipts keep showing the fee that applied when the purchase was made, only new purchases use the new amount.

**Games & Services** — your catalog. Mark games as motorized or not (this affects staffing/maintenance rules later), set a price and whether it's a flat fee or an hourly rate, and toggle active/inactive without deleting anything you might want to bring back.

**Access Plans** — single-visit passes or recurring memberships. Set the price, how long it's valid for (e.g. "1 day", "30 days"), how many visits it allows (leave blank for unlimited), an optional daily time limit, and which games/services it includes — tick the ones you want bundled in.

## Discount Rules

A rule fires automatically at checkout when a customer's cart contains **every one** of the components you select for that rule — for example, "Entry Fee + Bounce Zone + Lunch" only discounts a cart that has all three, not just one or two of them.

- **Discount type**: percent off, or a flat amount off.
- **Min quantity**: optional — require a minimum combined quantity across the matched items (e.g. "groups of 10+").
- **Valid from/to** and **days of week**: optional time windows — leave blank for an always-on rule.
- **Status**: `draft` while you're setting it up, `enabled` to make it live, `disabled` to pause it without losing the setup, `archived` when you're done with it for good.

Multiple enabled rules can apply to the same order at once — they're not mutually exclusive.

## Packages

A named, fixed-price bundle of games/services — set a quantity per item (0 means it's not included), an optional price, and an optional availability window if it's a limited-time offer.

## Settings

Venue name, logo, contact details, timezone, currency, and the two brand colors used across the mobile app and this dashboard. Nothing here is hardcoded in the app itself — changing it here changes what customers see.
