import { createAdminClient } from "../_shared/supabase-clients.ts";
import { assertApproved, isStaffRole, resolveCaller } from "../_shared/auth.ts";
import { corsHeaders, errorResponse, jsonResponse } from "../_shared/cors.ts";
import { HttpError } from "../_shared/http-error.ts";
import { issueWristband } from "../_shared/wristbands.ts";

/**
 * Staff-facing manual/cash issuance (docs/ARCHITECTURE_PLAN.md §4) — the
 * payment-driven path (checkout -> paid webhook) issues its own wristbands
 * automatically via the same _shared/wristbands.ts helper; this is for
 * walk-ins staff sell for cash outside that flow, or a complimentary pass
 * (matches the Stitch mockup's "Issue Pass — Grant complimentary visit").
 *
 * Two mutually exclusive modes:
 * - subscriptionId: an existing active subscription needs its wristband
 *   (e.g. a cash sale where staff created the subscription some other way).
 *   Expiry is the subscription's own ends_at.
 * - expiresAt: no subscription at all — a complimentary/manual pass.
 *   Granting free access is a real operator decision, so this path is
 *   staff/admin only same as the other, no different trust level.
 */

interface IssueRequest {
  familyId: string;
  familyMemberId?: string;
  subscriptionId?: string;
  expiresAt?: string;
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
      throw new HttpError(403, "Only staff or admin can issue wristbands");
    }

    const { data: family, error: familyError } = await admin
      .from("families")
      .select("id")
      .eq("id", body.familyId)
      .single();
    if (familyError || !family) throw new HttpError(404, "familyId not found");

    let familyMemberId: string | null = null;
    if (body.familyMemberId) {
      const { data: member, error: memberError } = await admin
        .from("family_members")
        .select("id")
        .eq("id", body.familyMemberId)
        .eq("family_id", body.familyId)
        .single();
      if (memberError || !member) throw new HttpError(400, "familyMemberId does not belong to this family");
      familyMemberId = member.id;
    }

    let subscriptionId: string | null = null;
    let expiresAt: Date;

    if (body.subscriptionId) {
      const { data: subscription, error: subError } = await admin
        .from("subscriptions")
        .select("id, family_id, status, ends_at")
        .eq("id", body.subscriptionId)
        .single();
      if (subError || !subscription) throw new HttpError(404, "subscriptionId not found");
      if (subscription.family_id !== body.familyId) {
        throw new HttpError(403, "subscriptionId does not belong to this family");
      }
      if (subscription.status !== "active") {
        throw new HttpError(409, `Subscription status is '${subscription.status}', not active`);
      }
      subscriptionId = subscription.id;
      expiresAt = new Date(subscription.ends_at);
    } else {
      // Complimentary/manual pass — expiresAt is required and validated below.
      expiresAt = new Date(body.expiresAt!);
    }

    const wristband = await issueWristband(admin, {
      familyId: body.familyId,
      familyMemberId,
      subscriptionId,
      expiresAt,
      issuedBy: caller.id,
    });

    await admin.from("audit_log").insert({
      actor_profile_id: caller.id,
      action_type: "wristband_issued",
      target_type: "wristband",
      target_id: wristband.id,
      details: subscriptionId
        ? `Wristband issued for subscription ${subscriptionId}`
        : `Complimentary wristband issued, expires ${expiresAt.toISOString()}`,
      status: "success",
    });

    return jsonResponse({ wristband }, 201);
  } catch (err) {
    if (err instanceof HttpError) return errorResponse(err.message, err.status);
    console.error("wristband-issue unhandled error:", err);
    return errorResponse("Internal error", 500);
  }
});

async function parseRequest(req: Request): Promise<IssueRequest> {
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

  if (typeof b.familyId !== "string") throw new HttpError(400, "familyId is required");

  const hasSubscription = typeof b.subscriptionId === "string";
  const hasExpiresAt = typeof b.expiresAt === "string";
  if (hasSubscription === hasExpiresAt) {
    throw new HttpError(400, "Provide exactly one of subscriptionId or expiresAt");
  }
  if (hasExpiresAt && isNaN(Date.parse(b.expiresAt as string))) {
    throw new HttpError(400, "expiresAt must be a valid date");
  }
  if (hasExpiresAt && new Date(b.expiresAt as string) <= new Date()) {
    throw new HttpError(400, "expiresAt must be in the future");
  }

  return {
    familyId: b.familyId,
    familyMemberId: typeof b.familyMemberId === "string" ? b.familyMemberId : undefined,
    subscriptionId: hasSubscription ? (b.subscriptionId as string) : undefined,
    expiresAt: hasExpiresAt ? (b.expiresAt as string) : undefined,
  };
}
