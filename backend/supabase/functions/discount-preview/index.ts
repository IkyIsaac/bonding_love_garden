import { createAdminClient } from "../_shared/supabase-clients.ts";
import { resolveCaller, resolveFamilyId } from "../_shared/auth.ts";
import { corsHeaders, errorResponse, jsonResponse } from "../_shared/cors.ts";
import { HttpError } from "../_shared/http-error.ts";
import { computeCartPricing, parseCartRequest } from "../_shared/cart-pricing.ts";

/**
 * Read-only twin of checkout-create-order (docs/ARCHITECTURE_PLAN.md §4) —
 * same request shape, same resolve-and-price pipeline via
 * _shared/cart-pricing.ts, but never writes an order. Powers the customer
 * checkout summary before committing to pay (brief §5.5: "price + discount
 * summary"). Deliberately does NOT call assertApproved() — browsing what
 * something would cost isn't a transaction, so a pending account can still
 * preview pricing even before staff approve them.
 *
 * The admin rule-builder's own live preview (Stitch mockup's "Price Impact
 * Preview" while drafting a new, not-yet-saved rule) is intentionally NOT
 * this endpoint — that's a simpler client-side calculation over
 * user-selected components with known prices, no cart or saved-rule
 * matching involved, and the mockup itself shows it computed client-side.
 */
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return errorResponse("Method not allowed", 405);

  const admin = createAdminClient();

  try {
    const body = await parseCartRequest(req);
    const caller = await resolveCaller(req.headers.get("Authorization"), admin);

    const familyId = await resolveFamilyId(caller, body.channel, body.familyId, admin);
    const includeEntryFee = body.includeEntryFee ?? true;

    if (body.items.length === 0 && !includeEntryFee) {
      throw new HttpError(400, "Cart is empty");
    }

    const pricing = await computeCartPricing(admin, familyId, body.items, includeEntryFee);

    return jsonResponse({
      subtotal: pricing.subtotal,
      discountTotal: pricing.discountTotal,
      entryFeeTotal: pricing.entryFeeTotal,
      totalAmount: pricing.totalAmount,
      items: pricing.resolvedLines,
      discountsApplied: pricing.discountApplications,
    });
  } catch (err) {
    if (err instanceof HttpError) return errorResponse(err.message, err.status);
    console.error("discount-preview unhandled error:", err);
    return errorResponse("Internal error", 500);
  }
});
