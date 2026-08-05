import type { SupabaseClient } from "npm:@supabase/supabase-js@2";
import type { Channel } from "./auth.ts";
import { HttpError } from "./http-error.ts";
import {
  buildCartComposition,
  type CartComposition,
  type CartLineForComposition,
  type DiscountApplication,
  type DiscountRuleComponentRow,
  type DiscountRuleRow,
  evaluateDiscounts,
  round2,
} from "./discount-engine.ts";

/**
 * Shared by checkout-create-order and discount-preview — the plan
 * (docs/ARCHITECTURE_PLAN.md §4) is explicit that discount-preview reuses
 * "the same discount-engine module" as checkout. Pulling the whole
 * resolve-cart-and-price pipeline in here (not just evaluateDiscounts)
 * means preview and actual checkout can never silently diverge — they're
 * always the exact same code path up to the point checkout persists rows.
 */

// guest_pass and credit_topup are in order_items.item_type but deliberately
// NOT supported here yet — neither has a canonical price source anywhere in
// the schema (no config table for "guest pass price" or "price per credit"),
// and accepting a client-supplied price for a financial transaction isn't an
// acceptable substitute. Flagging this rather than silently deciding it.
const SUPPORTED_ITEM_TYPES = ["access_plan", "package", "reservation_fee"] as const;
export type SupportedItemType = typeof SUPPORTED_ITEM_TYPES[number];

export interface RequestItem {
  itemType: string;
  accessPlanId?: string;
  packageId?: string;
  reservationId?: string;
  familyMemberId?: string;
  quantity?: number;
}

export interface CartRequest {
  channel: Channel;
  familyId?: string;
  includeEntryFee?: boolean;
  items: RequestItem[];
}

export interface ResolvedLine {
  itemType: SupportedItemType;
  referenceId: string;
  familyMemberId: string | null;
  quantity: number;
  unitPrice: number;
  lineTotal: number;
}

export interface CartPricingResult {
  subtotal: number;
  discountTotal: number;
  entryFeeTotal: number;
  totalAmount: number;
  entryFeeAmount: number;
  includeEntryFee: boolean;
  resolvedLines: ResolvedLine[];
  discountApplications: DiscountApplication[];
}

export async function parseCartRequest(req: Request): Promise<CartRequest> {
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

export async function resolveCartItems(
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
          `items[${index}]: item_type '${item.itemType}' is not yet supported`,
        );

      default:
        throw new HttpError(400, `items[${index}]: unknown item_type '${item.itemType}'`);
    }
  }

  return resolved;
}

export async function fetchCurrentEntryFeeAmount(admin: SupabaseClient): Promise<number> {
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

/** The full pipeline: resolve items -> price them -> evaluate discounts -> totals. No writes. */
export async function computeCartPricing(
  admin: SupabaseClient,
  familyId: string,
  items: RequestItem[],
  includeEntryFee: boolean,
): Promise<CartPricingResult> {
  const resolvedLines = await resolveCartItems(admin, items, familyId);
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

  return {
    subtotal,
    discountTotal,
    entryFeeTotal,
    totalAmount,
    entryFeeAmount,
    includeEntryFee,
    resolvedLines,
    discountApplications,
  };
}
