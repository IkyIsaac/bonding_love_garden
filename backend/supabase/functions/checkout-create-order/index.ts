import type { SupabaseClient } from "npm:@supabase/supabase-js@2";
import { createAdminClient } from "../_shared/supabase-clients.ts";
import { assertApproved, type Channel, resolveCaller, resolveFamilyId } from "../_shared/auth.ts";
import { corsHeaders, errorResponse, jsonResponse } from "../_shared/cors.ts";
import { HttpError } from "../_shared/http-error.ts";
import { computeCartPricing, parseCartRequest, type ResolvedLine } from "../_shared/cart-pricing.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return errorResponse("Method not allowed", 405);

  const admin = createAdminClient();

  try {
    const body = await parseCartRequest(req);
    const caller = await resolveCaller(req.headers.get("Authorization"), admin);
    assertApproved(caller);

    const familyId = await resolveFamilyId(caller, body.channel, body.familyId, admin);
    const includeEntryFee = body.includeEntryFee ?? true;

    if (body.items.length === 0 && !includeEntryFee) {
      throw new HttpError(400, "Cart is empty");
    }

    const pricing = await computeCartPricing(admin, familyId, body.items, includeEntryFee);

    const { order, items } = await persistOrder(admin, {
      familyId,
      buyerProfileId: caller.id,
      channel: body.channel,
      ...pricing,
    });

    return jsonResponse({ order, items, discountsApplied: pricing.discountApplications }, 201);
  } catch (err) {
    if (err instanceof HttpError) return errorResponse(err.message, err.status);
    console.error("checkout-create-order unhandled error:", err);
    return errorResponse("Internal error", 500);
  }
});

interface PersistOrderInput {
  familyId: string;
  buyerProfileId: string;
  channel: Channel;
  subtotal: number;
  discountTotal: number;
  entryFeeTotal: number;
  totalAmount: number;
  resolvedLines: ResolvedLine[];
  includeEntryFee: boolean;
  entryFeeAmount: number;
  entryFeeConfigId: string | null;
  discountApplications: { discountRuleId: string; amountDeducted: number }[];
}

/**
 * Not wrapped in a single database transaction — the Supabase JS client
 * doesn't support multi-statement transactions, and moving this to a
 * pl/pgsql RPC purely for atomicity felt like more machinery than this
 * first pass warranted given every failure mode below is a rare
 * infra/network blip, not a validation gap (everything's already validated
 * before any write happens). Known, accepted gap: if order_items or
 * order_discount_applications fails to insert after orders succeeds, this
 * does a best-effort compensating delete and logs loudly if even that
 * fails, rather than leaving a silently orphaned pending order. Worth
 * revisiting as an atomic RPC if this ever proves to be a real problem.
 */
async function persistOrder(
  admin: SupabaseClient,
  input: PersistOrderInput,
) {
  const { data: order, error: orderError } = await admin
    .from("orders")
    .insert({
      family_id: input.familyId,
      buyer_profile_id: input.buyerProfileId,
      channel: input.channel,
      subtotal: input.subtotal,
      discount_total: input.discountTotal,
      entry_fee_total: input.entryFeeTotal,
      total_amount: input.totalAmount,
      status: "pending",
    })
    .select("id, family_id, buyer_profile_id, channel, status, subtotal, discount_total, entry_fee_total, total_amount, created_at")
    .single();
  if (orderError || !order) {
    throw new HttpError(500, `Failed to create order: ${orderError?.message}`);
  }

  const orderItemsToInsert: {
    order_id: string;
    item_type: string;
    reference_id: string | null;
    family_member_id: string | null;
    quantity: number;
    unit_price: number;
    line_total: number;
  }[] = input.resolvedLines.map((l) => ({
    order_id: order.id,
    item_type: l.itemType,
    reference_id: l.referenceId,
    family_member_id: l.familyMemberId,
    quantity: l.quantity,
    unit_price: l.unitPrice,
    line_total: l.lineTotal,
  }));

  if (input.includeEntryFee) {
    // reference_id = the entry_fee_config row actually charged — lets a
    // later payment webhook snapshot the exact fee version onto
    // subscriptions.entry_fee_config_id instead of whatever's current by
    // the time payment succeeds.
    orderItemsToInsert.push({
      order_id: order.id,
      item_type: "entry_fee",
      reference_id: input.entryFeeConfigId,
      family_member_id: null,
      quantity: 1,
      unit_price: input.entryFeeAmount,
      line_total: input.entryFeeAmount,
    });
  }

  const { data: items, error: itemsError } = await admin
    .from("order_items")
    .insert(orderItemsToInsert)
    .select("id, item_type, reference_id, family_member_id, quantity, unit_price, line_total");
  if (itemsError) {
    await compensatingDelete(admin, order.id, `order_items insert failed: ${itemsError.message}`);
    throw new HttpError(500, `Failed to create order items: ${itemsError.message}`);
  }

  if (input.discountApplications.length > 0) {
    const { error: discountError } = await admin.from("order_discount_applications").insert(
      input.discountApplications.map((a) => ({
        order_id: order.id,
        discount_rule_id: a.discountRuleId,
        amount_deducted: a.amountDeducted,
      })),
    );
    if (discountError) {
      await compensatingDelete(admin, order.id, `order_discount_applications insert failed: ${discountError.message}`);
      throw new HttpError(500, `Failed to record discount applications: ${discountError.message}`);
    }
  }

  return { order, items };
}

async function compensatingDelete(admin: SupabaseClient, orderId: string, reason: string) {
  const { error } = await admin.from("orders").delete().eq("id", orderId);
  if (error) {
    console.error(
      `ORPHANED PENDING ORDER ${orderId}: compensating cleanup also failed after "${reason}". Manual cleanup needed: ${error.message}`,
    );
  } else {
    console.warn(`Rolled back order ${orderId} after: ${reason}`);
  }
}
