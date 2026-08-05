import { createAdminClient } from "../_shared/supabase-clients.ts";
import { assertApproved, type Channel, resolveCaller, resolveFamilyId } from "../_shared/auth.ts";
import { corsHeaders, errorResponse, jsonResponse } from "../_shared/cors.ts";
import { HttpError } from "../_shared/http-error.ts";

/**
 * Books a time slot within an already-active subscription (brief §4.7).
 * reservations itself has a direct customer-facing RLS INSERT policy
 * (§3.8) — this function adds the business-rule validation RLS can't
 * express cleanly (lead time, per-day cap), it isn't the only way a
 * reservation row can be created, same relationship as sessions'
 * supervisor RLS grant alongside sessions-manage.
 *
 * NOT handled here (flagged, not guessed): time-slot capacity/overlap
 * conflicts — nothing in the schema models "this game can only host N
 * concurrent reservations", so this only checks the caller's own
 * entitlement/lead-time/per-day rules, not whether the slot itself is
 * already full.
 */

interface BookRequest {
  channel: Channel;
  familyId?: string;
  subscriptionId: string;
  catalogItemId: string;
  slotStart: string;
  slotEnd: string;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return errorResponse("Method not allowed", 405);

  const admin = createAdminClient();

  try {
    const body = await parseRequest(req);
    const caller = await resolveCaller(req.headers.get("Authorization"), admin);
    assertApproved(caller);

    const familyId = await resolveFamilyId(caller, body.channel, body.familyId, admin);

    const { data: subscription, error: subError } = await admin
      .from("subscriptions")
      .select("id, family_id, access_plan_id, status")
      .eq("id", body.subscriptionId)
      .single();
    if (subError || !subscription) throw new HttpError(404, "subscriptionId not found");
    if (subscription.family_id !== familyId) throw new HttpError(403, "subscription does not belong to this family");
    if (subscription.status !== "active") {
      throw new HttpError(409, `Subscription status is '${subscription.status}', not active`);
    }

    const { data: planItem } = await admin
      .from("access_plan_items")
      .select("access_plan_id")
      .eq("access_plan_id", subscription.access_plan_id)
      .eq("catalog_item_id", body.catalogItemId)
      .maybeSingle();
    if (!planItem) throw new HttpError(403, "This subscription's plan does not include the selected game");

    const slotStart = new Date(body.slotStart);
    const slotEnd = new Date(body.slotEnd);
    const now = new Date();
    if (slotEnd <= slotStart) throw new HttpError(400, "slotEnd must be after slotStart");
    if (slotStart <= now) throw new HttpError(400, "slotStart must be in the future");

    const { data: settings, error: settingsError } = await admin
      .from("reservation_settings")
      .select("max_advance_days, max_per_day_per_family, default_fee")
      .single();
    if (settingsError || !settings) throw new HttpError(500, "Reservation settings are not configured");

    const maxAdvanceMs = settings.max_advance_days * 24 * 60 * 60 * 1000;
    if (slotStart.getTime() - now.getTime() > maxAdvanceMs) {
      throw new HttpError(400, `Reservations can only be booked up to ${settings.max_advance_days} days in advance`);
    }

    if (settings.max_per_day_per_family != null) {
      const dayStart = new Date(slotStart);
      dayStart.setHours(0, 0, 0, 0);
      const dayEnd = new Date(dayStart);
      dayEnd.setDate(dayEnd.getDate() + 1);

      const { data: familySubscriptions } = await admin
        .from("subscriptions")
        .select("id")
        .eq("family_id", familyId);
      const subscriptionIds = (familySubscriptions ?? []).map((s) => s.id);

      const { count, error: countError } = await admin
        .from("reservations")
        .select("id", { count: "exact", head: true })
        .in("subscription_id", subscriptionIds)
        .in("status", ["booked", "checked_in"])
        .gte("slot_start", dayStart.toISOString())
        .lt("slot_start", dayEnd.toISOString());
      if (countError) throw new HttpError(500, `Failed to check daily reservation count: ${countError.message}`);

      if ((count ?? 0) >= settings.max_per_day_per_family) {
        throw new HttpError(409, `This family has reached the limit of ${settings.max_per_day_per_family} reservations for that day`);
      }
    }

    const { data: reservation, error: insertError } = await admin
      .from("reservations")
      .insert({
        subscription_id: body.subscriptionId,
        catalog_item_id: body.catalogItemId,
        slot_start: slotStart.toISOString(),
        slot_end: slotEnd.toISOString(),
        fee: settings.default_fee,
        status: "booked",
      })
      .select("id, subscription_id, catalog_item_id, slot_start, slot_end, fee, status")
      .single();
    if (insertError || !reservation) throw new HttpError(500, `Failed to create reservation: ${insertError?.message}`);

    return jsonResponse({ reservation }, 201);
  } catch (err) {
    if (err instanceof HttpError) return errorResponse(err.message, err.status);
    console.error("reservations-book unhandled error:", err);
    return errorResponse("Internal error", 500);
  }
});

async function parseRequest(req: Request): Promise<BookRequest> {
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

  if (b.channel !== "customer_app" && b.channel !== "staff_app" && b.channel !== "web_admin") {
    throw new HttpError(400, "channel must be one of customer_app, staff_app, web_admin");
  }
  if (typeof b.subscriptionId !== "string") throw new HttpError(400, "subscriptionId is required");
  if (typeof b.catalogItemId !== "string") throw new HttpError(400, "catalogItemId is required");
  if (typeof b.slotStart !== "string" || isNaN(Date.parse(b.slotStart))) {
    throw new HttpError(400, "slotStart must be a valid date");
  }
  if (typeof b.slotEnd !== "string" || isNaN(Date.parse(b.slotEnd))) {
    throw new HttpError(400, "slotEnd must be a valid date");
  }

  return {
    channel: b.channel,
    familyId: typeof b.familyId === "string" ? b.familyId : undefined,
    subscriptionId: b.subscriptionId,
    catalogItemId: b.catalogItemId,
    slotStart: b.slotStart,
    slotEnd: b.slotEnd,
  };
}
