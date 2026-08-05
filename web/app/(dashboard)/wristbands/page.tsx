import { createClient } from "@/lib/supabase/server";
import WristbandsSection from "./wristbands-section";

export default async function WristbandsPage() {
  const supabase = await createClient();

  const [{ data: wristbands }, { data: familyMembers }, { data: families }] = await Promise.all([
    supabase.from("wristband_live_status").select("*").order("issued_at", { ascending: false }),
    supabase.from("family_members").select("id, full_name"),
    supabase.from("families").select("id, owner_profile_id"),
  ]);

  const ownerIds = [...new Set((families ?? []).map((f) => f.owner_profile_id))];
  const { data: owners } = await supabase
    .from("profiles")
    .select("id, full_name")
    .in("id", ownerIds.length > 0 ? ownerIds : ["00000000-0000-0000-0000-000000000000"]);

  const memberNameById = new Map((familyMembers ?? []).map((m) => [m.id, m.full_name]));
  const ownerNameByProfileId = new Map((owners ?? []).map((o) => [o.id, o.full_name]));
  const ownerProfileIdByFamilyId = new Map((families ?? []).map((f) => [f.id, f.owner_profile_id]));

  // wristband_live_status is a view — generated types mark every column
  // nullable even though id/family_id/wristband_number/qr_code_value/
  // expires_at/live_status are NOT NULL on the underlying table.
  const rows = (wristbands ?? [])
    .filter(
      (w): w is typeof w & {
        id: string;
        family_id: string;
        wristband_number: string;
        qr_code_value: string;
        expires_at: string;
        live_status: string;
      } =>
        w.id !== null &&
        w.family_id !== null &&
        w.wristband_number !== null &&
        w.qr_code_value !== null &&
        w.expires_at !== null &&
        w.live_status !== null,
    )
    .map((w) => ({
      id: w.id,
      wristband_number: w.wristband_number,
      qr_code_value: w.qr_code_value,
      live_status: w.live_status,
      expires_at: w.expires_at,
      last_scanned_at: w.last_scanned_at,
      beneficiaryName: w.family_member_id
        ? memberNameById.get(w.family_member_id) ?? "Unknown"
        : ownerNameByProfileId.get(ownerProfileIdByFamilyId.get(w.family_id) ?? "") ?? "Unknown",
    }));

  return (
    <div>
      <h1 className="font-heading text-2xl font-bold text-on-surface mb-1">Wristbands</h1>
      <p className="text-sm text-on-surface-variant mb-6">All issued wristbands and their live status.</p>
      <WristbandsSection wristbands={rows} />
    </div>
  );
}
