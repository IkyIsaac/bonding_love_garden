import { createClient } from "@/lib/supabase/server";
import ReservationSettingsForm from "./reservation-settings-form";
import ReservationsSection from "./reservations-section";

export default async function ReservationsPage() {
  const supabase = await createClient();

  const [
    { data: reservations },
    { data: settings, error: settingsError },
    { data: catalogItems },
    { data: subscriptions },
    { data: accessPlans },
    { data: familyMembers },
    { data: families },
  ] = await Promise.all([
    supabase.from("reservations").select("*").order("slot_start", { ascending: false }),
    supabase.from("reservation_settings").select("*").single(),
    supabase.from("catalog_items").select("id, name").order("name"),
    supabase.from("subscriptions").select("id, family_id, family_member_id, access_plan_id"),
    supabase.from("access_plans").select("id, name"),
    supabase.from("family_members").select("id, full_name"),
    supabase.from("families").select("id, owner_profile_id"),
  ]);

  const ownerIds = [...new Set((families ?? []).map((f) => f.owner_profile_id))];
  const { data: owners } = await supabase
    .from("profiles")
    .select("id, full_name")
    .in("id", ownerIds.length > 0 ? ownerIds : ["00000000-0000-0000-0000-000000000000"]);

  const catalogNameById = new Map((catalogItems ?? []).map((c) => [c.id, c.name]));
  const planNameById = new Map((accessPlans ?? []).map((p) => [p.id, p.name]));
  const memberNameById = new Map((familyMembers ?? []).map((m) => [m.id, m.full_name]));
  const ownerNameByProfileId = new Map((owners ?? []).map((o) => [o.id, o.full_name]));
  const ownerProfileIdByFamilyId = new Map((families ?? []).map((f) => [f.id, f.owner_profile_id]));
  const subscriptionById = new Map((subscriptions ?? []).map((s) => [s.id, s]));

  const rows = (reservations ?? []).map((r) => {
    const subscription = subscriptionById.get(r.subscription_id);
    const subscriberName = subscription
      ? subscription.family_member_id
        ? memberNameById.get(subscription.family_member_id) ?? "Unknown"
        : ownerNameByProfileId.get(ownerProfileIdByFamilyId.get(subscription.family_id) ?? "") ?? "Unknown"
      : "Unknown";
    return {
      id: r.id,
      subscriberName,
      planName: subscription ? planNameById.get(subscription.access_plan_id) ?? "Unknown plan" : "Unknown plan",
      gameId: r.catalog_item_id,
      gameName: catalogNameById.get(r.catalog_item_id) ?? "Unknown game",
      slotStart: r.slot_start,
      slotEnd: r.slot_end,
      fee: r.fee,
      status: r.status,
    };
  });

  return (
    <div className="flex flex-col gap-6">
      <div>
        <h1 className="font-heading text-2xl font-bold text-foreground mb-1">Reservations</h1>
        <p className="text-sm text-muted-foreground">
          Time slots booked against active memberships, and the rules that govern them. Slot capacity/overlap isn&apos;t
          enforced yet — two families can currently book the same game at the same time.
        </p>
      </div>
      {settingsError || !settings ? (
        <p className="text-destructive">Failed to load reservation settings: {settingsError?.message}</p>
      ) : (
        <ReservationSettingsForm settings={settings} />
      )}
      <ReservationsSection reservations={rows} games={catalogItems ?? []} />
    </div>
  );
}
