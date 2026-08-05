import { createClient } from "@/lib/supabase/server";
import { Card, CardContent } from "@/components/ui/card";
import SessionsTable, { type SessionRow } from "./sessions-table";

export default async function SessionsPage() {
  const supabase = await createClient();

  const [{ data: sessions }, { data: wristbands }, { data: familyMembers }, { data: families }, { data: catalogItems }] =
    await Promise.all([
      supabase.from("session_live_status").select("*").order("started_at", { ascending: false }),
      supabase.from("wristbands").select("id, family_id, family_member_id"),
      supabase.from("family_members").select("id, full_name"),
      supabase.from("families").select("id, owner_profile_id"),
      supabase.from("catalog_items").select("id, name"),
    ]);

  const ownerIds = [...new Set((families ?? []).map((f) => f.owner_profile_id))];
  const { data: owners } = await supabase
    .from("profiles")
    .select("id, full_name")
    .in("id", ownerIds.length > 0 ? ownerIds : ["00000000-0000-0000-0000-000000000000"]);

  const memberNameById = new Map((familyMembers ?? []).map((m) => [m.id, m.full_name]));
  const ownerNameByProfileId = new Map((owners ?? []).map((o) => [o.id, o.full_name]));
  const ownerProfileIdByFamilyId = new Map((families ?? []).map((f) => [f.id, f.owner_profile_id]));
  const wristbandById = new Map((wristbands ?? []).map((w) => [w.id, w]));
  const catalogNameById = new Map((catalogItems ?? []).map((c) => [c.id, c.name]));

  // session_live_status is a view — the generated types mark every column
  // nullable (Postgres/PostgREST can't prove NOT NULL through a view), even
  // though id/wristband_id/started_at/planned_end_at/status are never
  // actually null in practice (they're NOT NULL on the underlying table).
  // Filtering rather than asserting keeps this honest if that ever changes.
  const rows: SessionRow[] = (sessions ?? [])
    .filter(
      (s): s is typeof s & {
        id: string;
        wristband_id: string;
        started_at: string;
        planned_end_at: string;
        status: string;
      } => s.id !== null && s.wristband_id !== null && s.started_at !== null && s.planned_end_at !== null && s.status !== null,
    )
    .map((s) => {
      const wristband = wristbandById.get(s.wristband_id);
      const beneficiaryName = wristband
        ? wristband.family_member_id
          ? memberNameById.get(wristband.family_member_id) ?? "Unknown"
          : ownerNameByProfileId.get(ownerProfileIdByFamilyId.get(wristband.family_id) ?? "") ?? "Unknown"
        : "Unknown";
      return {
        id: s.id,
        beneficiaryName,
        gameName: s.catalog_item_id ? catalogNameById.get(s.catalog_item_id) ?? null : null,
        startedAt: s.started_at,
        plannedEndAt: s.planned_end_at,
        endedAt: s.ended_at,
        status: s.status,
      };
    });

  return (
    <div>
      <h1 className="font-heading text-2xl font-bold text-foreground mb-1">Active Sessions</h1>
      <p className="text-sm text-muted-foreground mb-6">
        Live view — refreshes automatically every 15 seconds and instantly on any change.
      </p>
      <Card>
        <CardContent>
          <SessionsTable sessions={rows} />
        </CardContent>
      </Card>
    </div>
  );
}
