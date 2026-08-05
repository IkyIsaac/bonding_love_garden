---
sidebar_position: 3
---

# Edge Functions

All business logic that needs procedural code or external calls lives in `backend/supabase/functions/`. Pure aggregation/reporting uses Postgres views/RPC instead — a SQL round-trip beats a Deno cold start for read-only work.

## Checkout & discounts

- **`checkout-create-order`** — validates a cart (plans/packages/reservation fees/entry fee), resolves pricing, runs the discount engine, and persists `orders`/`order_items`/`order_discount_applications`. Never touches `subscriptions` — those only get created once a payment actually succeeds.
- **`discount-preview`** — read-only twin of checkout, sharing the exact same `_shared/cart-pricing.ts` pipeline. Powers the customer checkout summary before committing to pay. Doesn't require an approved account (browsing a price isn't a transaction).
- **`_shared/discount-engine.ts`** — the actual matching logic. Games/services are never purchased as their own line item, only bundled inside a plan or package, so this expands every purchased plan/package into its included `catalog_items` and matches `discount_rule_components` against that expanded set. Multiple qualifying rules stack.

## Payments

- **`payments-initiate`** — provider-agnostic dispatcher. Resolves a `PaymentProvider` implementation by `payment_providers.code` and calls its `initiate()`.
- **`payments-webhook-selcom` / `-snippe` / `-payguard`** — one thin endpoint per provider (each has its own signature scheme), all delegating to one shared `processPaymentEvent()`.
- **`_shared/payments/`** — the `PaymentProvider` interface, a registry mapping provider code → implementation, and the three provider files. **The three providers are structurally real but not integration-real** — no verified API credentials/docs were available for any of them, so the HTTP calls are clearly-labeled placeholders. Onboarding a real or fourth provider is one new file + one new webhook function + one `payment_providers` row.
- **`processPaymentEvent`** is idempotent (a replayed webhook is a no-op past the first successful call) and, on success, creates a `subscriptions` row + wristband for each purchased `access_plan`. It does **not** auto-credit the wallet or handle package-only/entry-fee-only orders — both are open questions, not silently guessed answers.

## Wristbands & sessions

- **`wristband-issue`** — staff manual/complimentary issuance, sharing `_shared/wristbands.ts` with the payment-success path.
- **`session-scan-admit`** — does both the read (what the scanner screen shows) and the write (start/resume a session) in one call. An expired/revoked wristband is a normal `200` response with `admitted: false`, not an error.
- **`sessions-manage`** — extend/end, supervisor/admin only, mirroring the RLS UPDATE policy already on `sessions`.

## Reservations & wallet

- **`reservations-book`** — entitlement check (same `access_plan_items` join as scan-admit), lead-time and per-day-cap rules sourced from `reservation_settings` (not hardcoded), fee from that same config.
- **`wallet-redeem`** — staff-initiated credit redemption, deliberately agnostic to how credits were earned (the earning side is unbuilt — see the schema doc).

## Auth pattern used throughout

Every function follows the same shape: resolve the caller from their own JWT (`_shared/auth.ts`), check role/approval, then perform all reads/writes with the **service-role admin client** (`_shared/supabase-clients.ts`), since the financial tables have no client-writable RLS policy at all. The authorization check lives in the function code, not in RLS, for exactly those tables.
