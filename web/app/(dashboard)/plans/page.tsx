import { createClient } from "@/lib/supabase/server";
import CatalogItemsSection from "./catalog-items-section";
import AccessPlansSection from "./access-plans-section";
import EntryFeeCard from "./entry-fee-card";

export default async function PlansPage() {
  const supabase = await createClient();

  const [{ data: catalogItems }, { data: accessPlans }, { data: planItems }, { data: currentFee }] = await Promise.all([
    supabase.from("catalog_items").select("*").order("name"),
    supabase.from("access_plans").select("*").order("name"),
    supabase.from("access_plan_items").select("access_plan_id, catalog_item_id"),
    supabase.from("entry_fee_config").select("amount").is("effective_to", null).maybeSingle(),
  ]);

  const planItemsByPlanId: Record<string, string[]> = {};
  for (const row of planItems ?? []) {
    (planItemsByPlanId[row.access_plan_id] ??= []).push(row.catalog_item_id);
  }

  return (
    <div className="flex flex-col gap-6">
      <div>
        <h1 className="font-heading text-2xl font-bold text-on-surface mb-1">Plan Builder</h1>
        <p className="text-sm text-on-surface-variant">Games, services, access plans, and the venue entry fee.</p>
      </div>
      <EntryFeeCard currentAmount={currentFee?.amount ?? null} />
      <CatalogItemsSection items={catalogItems ?? []} />
      <AccessPlansSection plans={accessPlans ?? []} catalogItems={catalogItems ?? []} planItemsByPlanId={planItemsByPlanId} />
    </div>
  );
}
