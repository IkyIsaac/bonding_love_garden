import type { SupabaseClient } from "npm:@supabase/supabase-js@2";

/**
 * What a discount rule actually matches against.
 *
 * Games/services (catalog_items) are never purchased as their own order_item
 * — they only ever enter a cart bundled inside an access_plan or package (via
 * access_plan_items/package_items). So "is the qualifying combination in the
 * cart" means: expand every purchased plan/package into the catalog_items it
 * includes, sum quantities, and match discount_rule_components against that
 * expanded set (plus whether the entry fee is being charged this order).
 */
export interface CartComposition {
  catalogItemQuantities: Map<string, number>;
  includesEntryFee: boolean;
}

export interface CartLineForComposition {
  itemType: "access_plan" | "package";
  referenceId: string;
  quantity: number;
}

export async function buildCartComposition(
  admin: SupabaseClient,
  lines: CartLineForComposition[],
  includeEntryFee: boolean,
): Promise<CartComposition> {
  const catalogItemQuantities = new Map<string, number>();

  const accessPlanLines = lines.filter((l) => l.itemType === "access_plan");
  const packageLines = lines.filter((l) => l.itemType === "package");

  if (accessPlanLines.length > 0) {
    const { data, error } = await admin
      .from("access_plan_items")
      .select("access_plan_id, catalog_item_id")
      .in("access_plan_id", accessPlanLines.map((l) => l.referenceId));
    if (error) throw error;
    for (const line of accessPlanLines) {
      for (const row of data ?? []) {
        if (row.access_plan_id !== line.referenceId) continue;
        catalogItemQuantities.set(
          row.catalog_item_id,
          (catalogItemQuantities.get(row.catalog_item_id) ?? 0) + line.quantity,
        );
      }
    }
  }

  if (packageLines.length > 0) {
    const { data, error } = await admin
      .from("package_items")
      .select("package_id, catalog_item_id, quantity")
      .in("package_id", packageLines.map((l) => l.referenceId));
    if (error) throw error;
    for (const line of packageLines) {
      for (const row of data ?? []) {
        if (row.package_id !== line.referenceId) continue;
        const total = row.quantity * line.quantity;
        catalogItemQuantities.set(
          row.catalog_item_id,
          (catalogItemQuantities.get(row.catalog_item_id) ?? 0) + total,
        );
      }
    }
  }

  return { catalogItemQuantities, includesEntryFee: includeEntryFee };
}

export interface DiscountRuleRow {
  id: string;
  name: string;
  discount_type: "percent" | "flat";
  discount_value: number;
  min_quantity: number | null;
  valid_from: string | null;
  valid_to: string | null;
  days_of_week: number[] | null;
  status: "draft" | "enabled" | "disabled" | "archived";
}

export interface DiscountRuleComponentRow {
  discount_rule_id: string;
  catalog_item_id: string | null;
  is_entry_fee: boolean;
}

export interface DiscountApplication {
  discountRuleId: string;
  name: string;
  amountDeducted: number;
}

/**
 * Pure (given `now` and prices as inputs, not read internally) so it's
 * testable without a database and reusable by discount-preview later.
 *
 * A rule qualifies when every one of its components is present in the cart
 * in sufficient quantity. Deduction is computed against the qualifying
 * components' own reference prices (catalog_items.price / entryFeeAmount),
 * not against the whole cart or the plan/package's bundled price — there's
 * no principled way to prorate a bundled price down to one included item,
 * and this matches how the admin rule-builder mockup shows "Qualifying
 * Components" each carrying their own base price for the live calc preview.
 * Multiple qualifying rules stack (order_discount_applications has no
 * uniqueness restricting an order to one rule, so the schema already assumes
 * this); there's no "best rule only" logic.
 */
export function evaluateDiscounts(
  cart: CartComposition,
  rules: DiscountRuleRow[],
  componentsByRule: Map<string, DiscountRuleComponentRow[]>,
  catalogItemPrices: Map<string, number>,
  entryFeeAmount: number,
  now: Date,
): DiscountApplication[] {
  const applications: DiscountApplication[] = [];

  for (const rule of rules) {
    if (rule.status !== "enabled") continue;
    if (rule.valid_from && now < new Date(rule.valid_from)) continue;
    if (rule.valid_to && now > new Date(rule.valid_to)) continue;
    if (rule.days_of_week && rule.days_of_week.length > 0) {
      const dayOfWeek = now.getUTCDay(); // 0=Sunday..6=Saturday — matches Postgres EXTRACT(DOW) and the plan's own {6,0} Sat/Sun example
      if (!rule.days_of_week.includes(dayOfWeek)) continue;
    }

    const components = componentsByRule.get(rule.id) ?? [];
    if (components.length === 0) continue;

    let matchedBasis = 0;
    let matchedQuantity = 0;
    let allComponentsPresent = true;

    for (const component of components) {
      if (component.is_entry_fee) {
        if (!cart.includesEntryFee) {
          allComponentsPresent = false;
          break;
        }
        matchedBasis += entryFeeAmount;
        matchedQuantity += 1;
        continue;
      }

      const catalogItemId = component.catalog_item_id!;
      const quantityInCart = cart.catalogItemQuantities.get(catalogItemId) ?? 0;
      if (quantityInCart <= 0) {
        allComponentsPresent = false;
        break;
      }
      const price = catalogItemPrices.get(catalogItemId) ?? 0;
      matchedBasis += price * quantityInCart;
      matchedQuantity += quantityInCart;
    }

    if (!allComponentsPresent) continue;
    if (rule.min_quantity && matchedQuantity < rule.min_quantity) continue;

    const amountDeducted = rule.discount_type === "percent"
      ? round2(matchedBasis * (rule.discount_value / 100))
      : round2(rule.discount_value);

    if (amountDeducted > 0) {
      applications.push({ discountRuleId: rule.id, name: rule.name, amountDeducted });
    }
  }

  return applications;
}

export function round2(n: number): number {
  return Math.round(n * 100) / 100;
}
