import { createClient } from "@/lib/supabase/server";
import DiscountRulesSection from "./discount-rules-section";

export default async function DiscountsPage() {
  const supabase = await createClient();

  const [{ data: rules }, { data: catalogItems }, { data: components }] = await Promise.all([
    supabase.from("discount_rules").select("*").order("name"),
    supabase.from("catalog_items").select("*").eq("is_active", true).order("name"),
    supabase.from("discount_rule_components").select("discount_rule_id, catalog_item_id, is_entry_fee"),
  ]);

  const componentsByRuleId: Record<string, string[]> = {};
  for (const c of components ?? []) {
    const value = c.is_entry_fee ? "entry_fee" : c.catalog_item_id!;
    (componentsByRuleId[c.discount_rule_id] ??= []).push(value);
  }

  return (
    <div>
      <h1 className="font-heading text-2xl font-bold text-on-surface mb-1">Discount Rules</h1>
      <p className="text-sm text-on-surface-variant mb-6">
        A rule fires when every one of its selected components is in the cart. Multiple rules can stack on the same order.
      </p>
      <DiscountRulesSection rules={rules ?? []} catalogItems={catalogItems ?? []} componentsByRuleId={componentsByRuleId} />
    </div>
  );
}
