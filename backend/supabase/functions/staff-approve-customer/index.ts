import { createAdminClient } from "../_shared/supabase-clients.ts";
import { assertApproved, isStaffRole, resolveCaller } from "../_shared/auth.ts";
import { corsHeaders, errorResponse, jsonResponse } from "../_shared/cors.ts";
import { HttpError } from "../_shared/http-error.ts";

/**
 * The staff "Registration" screen's approval step (docs/ARCHITECTURE_PLAN.md
 * §5's registration/ feature, "approve pending accounts"). Every new
 * customer defaults to approval_status 'pending' (handle_new_user), and
 * assertApproved() rejects them from every money-touching Edge Function
 * until this happens. profiles_update's RLS is `id = auth.uid() or
 * is_admin()` — a staff session has no direct client-side path to change
 * another profile's approval_status at all, so this is a genuinely required
 * server-side operation, not a convenience wrapper around something RLS
 * would already allow.
 *
 * Any staff role (not just supervisor/admin) can call this — matches
 * families/family_members' own "assisted registration" RLS grant, which is
 * is_staff()-wide, not supervisor-gated. Scoped to role='customer' only:
 * staff account approval is a separate, existing web-admin-only flow
 * (web/app/(dashboard)/staff), not this one.
 */

interface ApproveRequest {
  profileId: string;
  decision: "approve" | "reject";
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return errorResponse("Method not allowed", 405);

  const admin = createAdminClient();

  try {
    const body = await parseRequest(req);
    const caller = await resolveCaller(req.headers.get("Authorization"), admin);
    assertApproved(caller);

    if (!isStaffRole(caller.role)) {
      throw new HttpError(403, "Only staff or admin can approve customer accounts");
    }

    const { data: target, error: targetError } = await admin
      .from("profiles")
      .select("id, role, approval_status, full_name, phone")
      .eq("id", body.profileId)
      .single();
    if (targetError || !target) throw new HttpError(404, "Profile not found");
    if (target.role !== "customer") {
      throw new HttpError(400, "This endpoint only approves customer accounts — staff accounts are managed from the web dashboard");
    }
    if (target.approval_status !== "pending") {
      throw new HttpError(409, `Account is already '${target.approval_status}', not pending`);
    }

    const newStatus = body.decision === "approve" ? "approved" : "rejected";

    const { data: updated, error: updateError } = await admin
      .from("profiles")
      .update({ approval_status: newStatus })
      .eq("id", target.id)
      .select("id, phone, full_name, role, approval_status")
      .single();
    if (updateError || !updated) throw new HttpError(500, `Failed to update approval status: ${updateError?.message}`);

    await admin.from("audit_log").insert({
      actor_profile_id: caller.id,
      action_type: "registration",
      target_type: "profile",
      target_id: target.id,
      details: `${newStatus === "approved" ? "Approved" : "Rejected"} customer account for ${target.full_name} (${target.phone})`,
      status: "success",
    });

    return jsonResponse({ profile: updated });
  } catch (err) {
    if (err instanceof HttpError) return errorResponse(err.message, err.status);
    console.error("staff-approve-customer unhandled error:", err);
    return errorResponse("Internal error", 500);
  }
});

async function parseRequest(req: Request): Promise<ApproveRequest> {
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

  if (typeof b.profileId !== "string") throw new HttpError(400, "profileId is required");
  if (b.decision !== "approve" && b.decision !== "reject") {
    throw new HttpError(400, "decision must be 'approve' or 'reject'");
  }

  return { profileId: b.profileId, decision: b.decision };
}
