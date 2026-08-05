import type { SupabaseClient } from "npm:@supabase/supabase-js@2";
import { createAdminClient } from "../_shared/supabase-clients.ts";
import { assertApproved, isStaffRole, resolveCaller } from "../_shared/auth.ts";
import { corsHeaders, errorResponse, jsonResponse } from "../_shared/cors.ts";
import { HttpError } from "../_shared/http-error.ts";

/**
 * The staff QR scanner (brief §4.10/§4.11): scan a wristband, show its live
 * validity + who/what it covers, and if valid, admit into a session
 * (starting a new one, or resuming an already-active one). "Admit" is in
 * the function's name deliberately — this does both the read (what the
 * scanner screen displays) and the write (starting the session) in one
 * call, not two separate endpoints.
 *
 * An invalid wristband (expired/revoked) is a normal, expected scan
 * outcome the UI needs to render (red X), not a server error — this
 * returns 200 with admitted:false rather than throwing for that case.
 */

interface ScanRequest {
  qrCodeValue: string;
  catalogItemId?: string;
  zoneId?: string;
  location?: string;
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
      throw new HttpError(403, "Only staff or admin can scan wristbands");
    }

    const { data: wristband, error: wristbandError } = await admin
      .from("wristband_live_status")
      .select("id, family_id, family_member_id, subscription_id, wristband_number, expires_at, live_status")
      .eq("qr_code_value", body.qrCodeValue)
      .maybeSingle();
    if (wristbandError) throw new HttpError(500, `Failed to look up wristband: ${wristbandError.message}`);
    if (!wristband) throw new HttpError(404, "No wristband found for this QR code");

    // Every scan attempt updates this, valid or not — it's a scan-activity
    // timestamp, not an admission-success one (found missing entirely while
    // reviewing the Wristbands admin page against real scan data: every
    // wristband showed "Last scanned: Never" despite having been scanned).
    const { error: touchError } = await admin
      .from("wristbands")
      .update({ last_scanned_at: new Date().toISOString() })
      .eq("id", wristband.id);
    if (touchError) console.error(`Failed to update last_scanned_at for wristband ${wristband.id}: ${touchError.message}`);

    const beneficiary = await resolveBeneficiaryDisplay(admin, wristband.family_id, wristband.family_member_id);
    const plan = wristband.subscription_id ? await resolvePlanDisplay(admin, wristband.subscription_id) : null;

    if (wristband.live_status !== "active") {
      await logScan(admin, caller.id, wristband.id, body.location, "failed", `Scan rejected — wristband is ${wristband.live_status}`);
      return jsonResponse({
        admitted: false,
        wristband: {
          id: wristband.id,
          wristbandNumber: wristband.wristband_number,
          status: wristband.live_status,
          expiresAt: wristband.expires_at,
        },
        beneficiary,
        plan,
        session: null,
      });
    }

    if (body.catalogItemId && wristband.subscription_id) {
      const entitled = await checkEntitlement(admin, wristband.subscription_id, body.catalogItemId);
      if (!entitled) {
        throw new HttpError(403, "This wristband's plan does not include the selected game");
      }
    }

    const existingSession = await findResumableSession(admin, wristband.id);
    const session = existingSession ?? await admitNewSession(admin, {
      wristbandId: wristband.id,
      catalogItemId: body.catalogItemId ?? null,
      zoneId: body.zoneId ?? null,
      subscriptionId: wristband.subscription_id,
      wristbandExpiresAt: wristband.expires_at,
    });

    await logScan(
      admin,
      caller.id,
      wristband.id,
      body.location,
      "success",
      existingSession ? `Resumed session for ${beneficiary.name ?? "guest"}` : `Admitted ${beneficiary.name ?? "guest"}`,
    );

    return jsonResponse({
      admitted: true,
      wristband: {
        id: wristband.id,
        wristbandNumber: wristband.wristband_number,
        status: wristband.live_status,
        expiresAt: wristband.expires_at,
      },
      beneficiary,
      plan,
      session,
    });
  } catch (err) {
    if (err instanceof HttpError) return errorResponse(err.message, err.status);
    console.error("session-scan-admit unhandled error:", err);
    return errorResponse("Internal error", 500);
  }
});

async function parseRequest(req: Request): Promise<ScanRequest> {
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
  if (typeof b.qrCodeValue !== "string" || b.qrCodeValue.length === 0) {
    throw new HttpError(400, "qrCodeValue is required");
  }
  return {
    qrCodeValue: b.qrCodeValue,
    catalogItemId: typeof b.catalogItemId === "string" ? b.catalogItemId : undefined,
    zoneId: typeof b.zoneId === "string" ? b.zoneId : undefined,
    location: typeof b.location === "string" ? b.location : undefined,
  };
}

async function resolveBeneficiaryDisplay(
  admin: SupabaseClient,
  familyId: string,
  familyMemberId: string | null,
): Promise<{ name: string | null; photoUrl: string | null }> {
  if (familyMemberId) {
    const { data } = await admin
      .from("family_members")
      .select("full_name, photo_url")
      .eq("id", familyMemberId)
      .maybeSingle();
    return { name: data?.full_name ?? null, photoUrl: data?.photo_url ?? null };
  }
  const { data: family } = await admin.from("families").select("owner_profile_id").eq("id", familyId).maybeSingle();
  if (!family) return { name: null, photoUrl: null };
  const { data: profile } = await admin
    .from("profiles")
    .select("full_name, photo_url")
    .eq("id", family.owner_profile_id)
    .maybeSingle();
  return { name: profile?.full_name ?? null, photoUrl: profile?.photo_url ?? null };
}

async function resolvePlanDisplay(
  admin: SupabaseClient,
  subscriptionId: string,
): Promise<{ name: string; dailyTimeLimitMinutes: number | null } | null> {
  const { data: subscription } = await admin
    .from("subscriptions")
    .select("access_plan_id")
    .eq("id", subscriptionId)
    .maybeSingle();
  if (!subscription) return null;
  const { data: plan } = await admin
    .from("access_plans")
    .select("name, daily_time_limit_minutes")
    .eq("id", subscription.access_plan_id)
    .maybeSingle();
  if (!plan) return null;
  return { name: plan.name, dailyTimeLimitMinutes: plan.daily_time_limit_minutes };
}

async function checkEntitlement(admin: SupabaseClient, subscriptionId: string, catalogItemId: string): Promise<boolean> {
  const { data: subscription } = await admin
    .from("subscriptions")
    .select("access_plan_id")
    .eq("id", subscriptionId)
    .maybeSingle();
  if (!subscription) return false;
  const { data: planItem } = await admin
    .from("access_plan_items")
    .select("access_plan_id")
    .eq("access_plan_id", subscription.access_plan_id)
    .eq("catalog_item_id", catalogItemId)
    .maybeSingle();
  return !!planItem;
}

/** Only 'active'/'expiring_soon' sessions are resumable — an 'expired' one means their time ran out; scanning again is a fresh admission, not a resume. */
async function findResumableSession(admin: SupabaseClient, wristbandId: string) {
  const { data } = await admin
    .from("session_live_status")
    .select("id, catalog_item_id, zone_id, started_at, planned_end_at, status")
    .eq("wristband_id", wristbandId)
    .in("status", ["active", "expiring_soon"])
    .order("started_at", { ascending: false })
    .limit(1)
    .maybeSingle();
  if (!data) return null;
  return {
    id: data.id,
    catalogItemId: data.catalog_item_id,
    zoneId: data.zone_id,
    startedAt: data.started_at,
    plannedEndAt: data.planned_end_at,
    status: data.status,
  };
}

async function admitNewSession(admin: SupabaseClient, params: {
  wristbandId: string;
  catalogItemId: string | null;
  zoneId: string | null;
  subscriptionId: string | null;
  wristbandExpiresAt: string;
}) {
  let plannedEndAt = new Date(params.wristbandExpiresAt);

  if (params.subscriptionId) {
    const { data: subscription } = await admin
      .from("subscriptions")
      .select("access_plan_id")
      .eq("id", params.subscriptionId)
      .maybeSingle();
    if (subscription) {
      const { data: plan } = await admin
        .from("access_plans")
        .select("daily_time_limit_minutes")
        .eq("id", subscription.access_plan_id)
        .maybeSingle();
      if (plan?.daily_time_limit_minutes) {
        const limited = new Date();
        limited.setMinutes(limited.getMinutes() + plan.daily_time_limit_minutes);
        // Never let a daily time limit extend a session past the wristband's own expiry.
        if (limited < plannedEndAt) plannedEndAt = limited;
      }
    }
  }

  const { data: session, error } = await admin
    .from("sessions")
    .insert({
      wristband_id: params.wristbandId,
      catalog_item_id: params.catalogItemId,
      zone_id: params.zoneId,
      planned_end_at: plannedEndAt.toISOString(),
    })
    .select("id, catalog_item_id, zone_id, started_at, planned_end_at")
    .single();
  if (error || !session) throw new HttpError(500, `Failed to start session: ${error?.message}`);

  return {
    id: session.id,
    catalogItemId: session.catalog_item_id,
    zoneId: session.zone_id,
    startedAt: session.started_at,
    plannedEndAt: session.planned_end_at,
    status: "active" as const,
  };
}

async function logScan(
  admin: SupabaseClient,
  actorProfileId: string,
  wristbandId: string,
  location: string | undefined,
  status: "success" | "failed",
  details: string,
) {
  const { error } = await admin.from("audit_log").insert({
    actor_profile_id: actorProfileId,
    action_type: "check_in",
    target_type: "wristband",
    target_id: wristbandId,
    details,
    location: location ?? null,
    status,
  });
  if (error) console.error(`Failed to write audit_log for scan of wristband ${wristbandId}: ${error.message}`);
}
