import { createClient } from "@/lib/supabase/server";
import AuditLogSection, { type AuditLogRow } from "./audit-log-section";

export default async function AuditLogPage() {
  const supabase = await createClient();

  const [{ data: entries }, { data: actors }] = await Promise.all([
    supabase
      .from("audit_log")
      .select("id, actor_profile_id, action_type, details, location, status, created_at")
      .order("created_at", { ascending: false })
      .limit(200),
    supabase.from("profiles").select("id, full_name"),
  ]);

  const actorNameById = new Map((actors ?? []).map((a) => [a.id, a.full_name]));

  const rows: AuditLogRow[] = (entries ?? []).map((e) => ({
    id: e.id,
    actorName: e.actor_profile_id ? actorNameById.get(e.actor_profile_id) ?? "Unknown" : "System",
    actionType: e.action_type,
    details: e.details,
    location: e.location,
    status: e.status,
    createdAt: e.created_at,
  }));

  return (
    <div>
      <h1 className="font-heading text-2xl font-bold text-foreground mb-1">Audit Log</h1>
      <p className="text-sm text-muted-foreground mb-6">Staff actions across the platform, most recent first.</p>
      <AuditLogSection entries={rows} />
    </div>
  );
}
