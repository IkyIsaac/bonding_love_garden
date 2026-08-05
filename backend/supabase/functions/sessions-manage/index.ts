import { createAdminClient } from "../_shared/supabase-clients.ts";
import { assertApproved, resolveCaller } from "../_shared/auth.ts";
import { corsHeaders, errorResponse, jsonResponse } from "../_shared/cors.ts";
import { HttpError } from "../_shared/http-error.ts";

/**
 * Extend or end an active session — supervisor/admin only, mirroring the
 * RLS UPDATE policy on `sessions` itself (§3.8): that policy already lets a
 * supervisor extend/end directly via a client-side update, this function is
 * the alternative trusted path (e.g. from a staff-app action that also
 * wants an audit_log entry, which a raw RLS-gated client update wouldn't
 * produce on its own).
 */

interface ManageRequest {
  sessionId: string;
  action: "extend" | "end";
  extendMinutes?: number;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return errorResponse("Method not allowed", 405);

  const admin = createAdminClient();

  try {
    const body = await parseRequest(req);
    const caller = await resolveCaller(req.headers.get("Authorization"), admin);
    assertApproved(caller);

    if (caller.role !== "supervisor" && caller.role !== "admin") {
      throw new HttpError(403, "Only a supervisor or admin can extend or end a session");
    }

    const { data: session, error: sessionError } = await admin
      .from("sessions")
      .select("id, started_at, planned_end_at, ended_at, extended_minutes_total")
      .eq("id", body.sessionId)
      .single();
    if (sessionError || !session) throw new HttpError(404, "Session not found");
    if (session.ended_at) throw new HttpError(409, "Session has already ended");

    if (body.action === "extend") {
      const newPlannedEndAt = new Date(session.planned_end_at);
      newPlannedEndAt.setMinutes(newPlannedEndAt.getMinutes() + body.extendMinutes!);

      const { data: updated, error: updateError } = await admin
        .from("sessions")
        .update({
          planned_end_at: newPlannedEndAt.toISOString(),
          extended_minutes_total: session.extended_minutes_total + body.extendMinutes!,
        })
        .eq("id", session.id)
        .select("id, planned_end_at, extended_minutes_total")
        .single();
      if (updateError || !updated) throw new HttpError(500, `Failed to extend session: ${updateError?.message}`);

      await logAction(admin, caller.id, session.id, "session_extended", `Extended by ${body.extendMinutes} minutes`);
      return jsonResponse({ session: updated });
    }

    // action === "end"
    const { data: updated, error: updateError } = await admin
      .from("sessions")
      .update({ ended_at: new Date().toISOString() })
      .eq("id", session.id)
      .select("id, ended_at")
      .single();
    if (updateError || !updated) throw new HttpError(500, `Failed to end session: ${updateError?.message}`);

    await logAction(admin, caller.id, session.id, "session_ended", "Session ended by staff");
    return jsonResponse({ session: updated });
  } catch (err) {
    if (err instanceof HttpError) return errorResponse(err.message, err.status);
    console.error("sessions-manage unhandled error:", err);
    return errorResponse("Internal error", 500);
  }
});

async function parseRequest(req: Request): Promise<ManageRequest> {
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

  if (typeof b.sessionId !== "string") throw new HttpError(400, "sessionId is required");
  if (b.action !== "extend" && b.action !== "end") throw new HttpError(400, "action must be 'extend' or 'end'");
  if (b.action === "extend") {
    if (typeof b.extendMinutes !== "number" || !Number.isInteger(b.extendMinutes) || b.extendMinutes <= 0) {
      throw new HttpError(400, "extendMinutes must be a positive integer for action 'extend'");
    }
  }

  return {
    sessionId: b.sessionId,
    action: b.action,
    extendMinutes: typeof b.extendMinutes === "number" ? b.extendMinutes : undefined,
  };
}

async function logAction(
  admin: ReturnType<typeof createAdminClient>,
  actorProfileId: string,
  sessionId: string,
  actionType: string,
  details: string,
) {
  const { error } = await admin.from("audit_log").insert({
    actor_profile_id: actorProfileId,
    action_type: actionType,
    target_type: "session",
    target_id: sessionId,
    details,
    status: "success",
  });
  if (error) console.error(`Failed to write audit_log for ${actionType} on session ${sessionId}: ${error.message}`);
}
