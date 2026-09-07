import { createClient } from "@/lib/supabase/server";
import SubscriptionsSection from "./subscriptions-section";

export default async function SubscriptionsPage() {
  const supabase = await createClient();

  const [{ data: subscriptions }, { data: accessPlans }, { data: planItems }, { data: catalogItems }, { data: familyMembers }, { data: families }] =
    await Promise.all([
      supabase.from("subscriptions").select("*").order("created_at", { ascending: false }),
      supabase.from("access_plans").select("id, name"),
      supabase.from("access_plan_items").select("access_plan_id, catalog_item_id"),
      supabase.from("catalog_items").select("id, name").order("name"),
      supabase.from("family_members").select("id, full_name"),
      supabase.from("families").select("id, owner_profile_id"),
    ]);

  const ownerIds = [...new Set((families ?? []).map((f) => f.owner_profile_id))];
  const { data: owners } = await supabase
    .from("profiles")
    .select("id, full_name")
    .in("id", ownerIds.length > 0 ? ownerIds : ["00000000-0000-0000-0000-000000000000"]);

  const planNameById = new Map((accessPlans ?? []).map((p) => [p.id, p.name]));
  const catalogNameById = new Map((catalogItems ?? []).map((c) => [c.id, c.name]));
  const memberNameById = new Map((familyMembers ?? []).map((m) => [m.id, m.full_name]));
  const ownerNameByProfileId = new Map((owners ?? []).map((o) => [o.id, o.full_name]));
  const ownerProfileIdByFamilyId = new Map((families ?? []).map((f) => [f.id, f.owner_profile_id]));

  const catalogItemIdsByPlanId = new Map<string, string[]>();
  for (const row of planItems ?? []) {
    const list = catalogItemIdsByPlanId.get(row.access_plan_id) ?? [];
    list.push(row.catalog_item_id);
    catalogItemIdsByPlanId.set(row.access_plan_id, list);
  }

  const rows = (subscriptions ?? []).map((s) => {
    const gameIds = catalogItemIdsByPlanId.get(s.access_plan_id) ?? [];
    return {
      id: s.id,
      subscriberName: s.family_member_id
        ? memberNameById.get(s.family_member_id) ?? "Unknown"
        : ownerNameByProfileId.get(ownerProfileIdByFamilyId.get(s.family_id) ?? "") ?? "Unknown",
      planName: planNameById.get(s.access_plan_id) ?? "Unknown plan",
      gameIds,
      gameNames: gameIds.map((id) => catalogNameById.get(id)).filter((n): n is string => !!n),
      status: s.status,
      startsAt: s.starts_at,
      endsAt: s.ends_at,
      visitsRemaining: s.visits_remaining,
    };
  });

  return (
    <div>
      <h1 className="font-heading text-2xl font-bold text-foreground mb-1">Subscriptions</h1>
      <p className="text-sm text-muted-foreground mb-6">
        Every family&apos;s purchased memberships and single-visit passes — filter by game to see who&apos;s subscribed to a
        given plan.
      </p>
      <SubscriptionsSection subscriptions={rows} games={catalogItems ?? []} />
    </div>
  );
}
