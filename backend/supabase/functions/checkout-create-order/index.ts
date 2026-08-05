import type { SupabaseClient } from "npm:@supabase/supabase-js@2";
import { createAdminClient } from "../_shared/supabase-clients.ts";
import { assertApproved, type Channel, resolveCaller, resolveFamilyId } from "../_shared/auth.ts";
import { corsHeaders, errorResponse, jsonResponse } from "../_shared/cors.ts";
import { HttpError } from "../_shared/http-error.ts";
import {
  buildCartComposition,
  type CartComposition,
  type CartLineForComposition,
  type DiscountRuleComponentRow,
  type DiscountRuleRow,
  evaluateDiscounts,
  round2,
} from "../_shared/discount-engine.ts";

// guest_pass and credit_topup are in order_items.item_type but deliberately
// NOT supported here yet — neither has a canonical price source anywhere in
// the schema (no config table for "guest pass price" or "price per credit"),
// and accepting a client-supplied price for a financial transaction isn't an
// acceptable substitute. Flagging this rather than silently deciding it.
const SUPPORTED_ITEM_TYPES = ["access_plan", "package", "reservation_fee"] as const;
type SupportedItemType = typeof SUPPORTED_ITEM_TYPES[number];

interface RequestItem {
  itemType: string;
  accessPlanId?: string;
  packageId?: string;
  reservationId?: string;
  familyMemberId?: string;
  quantity?: number;
}

interface CheckoutRequest {
  channel: Channel;
  familyId?: string;
  includeEntryFee?: boolean;
  items: RequestItem[];
}

interface ResolvedLine {
  itemType: SupportedItemType;
  referenceId: string;
  familyMemberId: string | null;
  quantity: number;
  unitPrice: number;
  lineTotal: number;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return errorResponse("Method not allowed", 405);

  const admin = createAdminClient();

  try {
    const body = await parseRequest(req);
    const caller = await resolveCaller(req.headers.get("Authorization"), admin);
    assertApproved(caller);

    const familyId = await resolveFamilyId(caller, body.channel, body.familyId, admin);
    const includeEntryFee = body.includeEntryFee ?? true;

    if (body.items.length === 0 && !includeEntryFee) {
      throw new HttpError(400, "Cart is empty");
    }

    const resolvedLines = await resolveCartItems(admin, body.items, familyId);
    const entryFeeAmount = includeEntryFee ? await fetchCurrentEntryFeeAmount(admin) : 0;

    const compositionLines: CartLineForComposition[] = resolvedLines
      .filter((l) => l.itemType === "access_plan" || l.itemType === "package")
      .map((l) => ({
        itemType: l.itemType as "access_plan" | "package",
        referenceId: l.referenceId,
        quantity: l.quantity,
      }));

    const cartComposition = await buildCartComposition(admin, compositionLines, includeEntryFee);
    const { rules, componentsByRule, catalogItemPrices } = await fetchDiscountContext(admin, cartComposition);

    const discountApplications = evaluateDiscounts(
      cartComposition,
      rules,
      componentsByRule,
      catalogItemPrices,
      entryFeeAmount,
      new Date(),
    );

    const subtotal = round2(resolvedLines.reduce((sum, l) => sum + l.lineTotal, 0));
    const rawDiscountTotal = round2(discountApplications.reduce((sum, a) => sum + a.amountDeducted, 0));
    // Clamp: a pathological rule combination should never net the venue owing the customer.
    const discountTotal = Math.min(rawDiscountTotal, subtotal);
    const entryFeeTotal = round2(entryFeeAmount);
    const totalAmount = round2(subtotal - discountTotal + entryFeeTotal);

    const { order, items } = await persistOrder(admin, {
      familyId,
      buyerProfileId: caller.id,
      channel: body.channel,
      subtotal,
      discountTotal,
      entryFeeTotal,
      totalAmount,
      resolvedLines,
      includeEntryFee,
      entryFeeAmount,
      discountApplications,
    });

    return jsonResponse({ order, items, discountsApplied: discountApplications }, 201);
  } catch (err) {
    if (err instanceof HttpError) return errorResponse(err.message, err.status);
    console.error("checkout-create-order unhandled error:", err);
    return errorResponse("Internal error", 500);
  }
});

async function parseRequest(req: Request): Promise<CheckoutRequest> {
  let body: unknown;
  try {
    body = await req.json();
  } catch {
    throw new HttpError(400, "Invalid JSON body");
  }
  if (typeof body !== "object" || body === null) {
    throw new HttpError(400, "Request body must be an object");
  }
  const b = body as Record<string, unknown>;

  if (b.channel !== "customer_app" && b.channel !== "staff_app" && b.channel !== "web_admin") {
    throw new HttpError(400, "channel must be one of customer_app, staff_app, web_admin");
  }
  if (!Array.isArray(b.items)) {
    throw new HttpError(400, "items must be an array");
  }

  return {
    channel: b.channel,
    familyId: typeof b.familyId === "string" ? b.familyId : undefined,
    includeEntryFee: typeof b.includeEntryFee === "boolean" ? b.includeEntryFee : undefined,
    items: b.items as RequestItem[],
  };
}

async function resolveCartItems(
  admin: SupabaseClient,
  items: RequestItem[],
  familyId: string,
): Promise<ResolvedLine[]> {
  const resolved: ResolvedLine[] = [];
  const seenReservationIds = new Set<string>();

  for (const [index, item] of items.entries()) {
    const quantity = item.quantity ?? 1;
    if (!Number.isInteger(quantity) || quantity < 1) {
      throw new HttpError(400, `items[${index}]: quantity must be a positive integer`);
    }

    let familyMemberId: string | null = null;
    if (item.familyMemberId) {
      if (quantity !== 1) {
        throw new HttpError(400, `items[${index}]: familyMemberId can only be set when quantity is 1`);
      }
      const { data: member, error } = await admin
        .from("family_members")
        .select("id")
        .eq("id", item.familyMemberId)
        .eq("family_id", familyId)
        .single();
      if (error || !member) {
        throw new HttpError(400, `items[${index}]: familyMemberId does not belong to this family`);
      }
      familyMemberId = member.id;
    }

    switch (item.itemType) {
      case "access_plan": {
        if (!item.accessPlanId) throw new HttpError(400, `items[${index}]: accessPlanId is required`);
        const { data: plan, error } = await admin
          .from("access_plans")
          .select("id, price, is_active")
          .eq("id", item.accessPlanId)
          .single();
        if (error || !plan) throw new HttpError(404, `items[${index}]: access plan not found`);
        if (!plan.is_active) throw new HttpError(400, `items[${index}]: access plan is not currently available`);
        resolved.push({
          itemType: "access_plan",
          referenceId: plan.id,
          familyMemberId,
          quantity,
          unitPrice: plan.price,
          lineTotal: round2(plan.price * quantity),
        });
        break;
      }

      case "package": {
        if (!item.packageId) throw new HttpError(400, `items[${index}]: packageId is required`);
        const { data: pkg, error } = await admin
          .from("packages")
          .select("id, price, is_active, availability_start, availability_end")
          .eq("id", item.packageId)
          .single();
        if (error || !pkg) throw new HttpError(404, `items[${index}]: package not found`);
        if (!pkg.is_active) throw new HttpError(400, `items[${index}]: package is not currently available`);
        const now = new Date();
        if (pkg.availability_start && now < new Date(pkg.availability_start)) {
          throw new HttpError(400, `items[${index}]: package is not yet available`);
        }
        if (pkg.availability_end && now > new Date(pkg.availability_end)) {
          throw new HttpError(400, `items[${index}]: package availability window has ended`);
        }
        resolved.push({
          itemType: "package",
          referenceId: pkg.id,
          familyMemberId,
          quantity,
          unitPrice: pkg.price,
          lineTotal: round2(pkg.price * quantity),
        });
        break;
      }

      case "reservation_fee": {
        if (!item.reservationId) throw new HttpError(400, `items[${index}]: reservationId is required`);
        if (quantity !== 1) throw new HttpError(400, `items[${index}]: reservation_fee quantity must be 1`);
        if (seenReservationIds.has(item.reservationId)) {
          throw new HttpError(400, `items[${index}]: duplicate reservationId in cart`);
        }
        seenReservationIds.add(item.reservationId);

        const { data: reservation, error } = await admin
          .from("reservations")
          .select("id, fee, subscription_id")
          .eq("id", item.reservationId)
          .single();
        if (error || !reservation) throw new HttpError(404, `items[${index}]: reservation not found`);

        const { data: subscription, error: subError } = await admin
          .from("subscriptions")
          .select("family_id")
          .eq("id", reservation.subscription_id)
          .single();
        if (subError || !subscription) {
          throw new HttpError(500, `items[${index}]: reservation has no valid subscription`);
        }
        if (subscription.family_id !== familyId) {
          throw new HttpError(403, `items[${index}]: reservation does not belong to this family`);
        }

        resolved.push({
          itemType: "reservation_fee",
          referenceId: reservation.id,
          familyMemberId,
          quantity: 1,
          unitPrice: reservation.fee,
          lineTotal: round2(reservation.fee),
        });
        break;
      }

      case "guest_pass":
      case "credit_topup":
        throw new HttpError(
          400,
          `items[${index}]: item_type '${item.itemType}' is not yet supported by checkout-create-order`,
        );

      default:
        throw new HttpError(400, `items[${index}]: unknown item_type '${item.itemType}'`);
    }
  }

  return resolved;
}

async function fetchCurrentEntryFeeAmount(admin: SupabaseClient): Promise<number> {
  const { data, error } = await admin
    .from("entry_fee_config")
    .select("amount")
    .is("effective_to", null)
    .order("effective_from", { ascending: false })
    .limit(1)
    .maybeSingle();
  if (error) throw new HttpError(500, `Failed to look up entry fee: ${error.message}`);
  if (!data) throw new HttpError(500, "No entry fee is currently configured for this venue");
  return data.amount;
}

async function fetchDiscountContext(
  admin: SupabaseClient,
  cart: CartComposition,
): Promise<{
  rules: DiscountRuleRow[];
  componentsByRule: Map<string, DiscountRuleComponentRow[]>;
  catalogItemPrices: Map<string, number>;
}> {
  const { data: rules, error: rulesError } = await admin
    .from("discount_rules")
    .select("id, name, discount_type, discount_value, min_quantity, valid_from, valid_to, days_of_week, status")
    .eq("status", "enabled");
  if (rulesError) throw new HttpError(500, `Failed to load discount rules: ${rulesError.message}`);

  const ruleIds = (rules ?? []).map((r) => r.id);
  const componentsByRule = new Map<string, DiscountRuleComponentRow[]>();
  if (ruleIds.length > 0) {
    const { data: components, error: componentsError } = await admin
      .from("discount_rule_components")
      .select("discount_rule_id, catalog_item_id, is_entry_fee")
      .in("discount_rule_id", ruleIds);
    if (componentsError) {
      throw new HttpError(500, `Failed to load discount rule components: ${componentsError.message}`);
    }
    for (const c of components ?? []) {
      const list = componentsByRule.get(c.discount_rule_id) ?? [];
      list.push(c);
      componentsByRule.set(c.discount_rule_id, list);
    }
  }

  const catalogItemIds = [...cart.catalogItemQuantities.keys()];
  const catalogItemPrices = new Map<string, number>();
  if (catalogItemIds.length > 0) {
    const { data: catalogItems, error: catalogError } = await admin
      .from("catalog_items")
      .select("id, price")
      .in("id", catalogItemIds);
    if (catalogError) throw new HttpError(500, `Failed to load catalog item prices: ${catalogError.message}`);
    for (const ci of catalogItems ?? []) catalogItemPrices.set(ci.id, ci.price);
  }

  return { rules: rules ?? [], componentsByRule, catalogItemPrices };
}

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
    orderItemsToInsert.push({
      order_id: order.id,
      item_type: "entry_fee",
      reference_id: null,
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
