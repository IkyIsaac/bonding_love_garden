import { createAdminClient } from "../_shared/supabase-clients.ts";
import { assertApproved, isStaffRole, resolveCaller } from "../_shared/auth.ts";
import { corsHeaders, errorResponse, jsonResponse } from "../_shared/cors.ts";
import { HttpError } from "../_shared/http-error.ts";

/**
 * Staff-initiated: redeem N game credits against a wristband at a game
 * station (brief §4.9/§4.10). Deliberately agnostic to how the credits got
 * there — the "earning" side (auto-crediting a wallet from purchased plan/
 * package contents) was explicitly NOT built in the payments work
 * (docs/ARCHITECTURE_PLAN.md §4, process-payment-event.ts) because the
 * conversion rule is genuinely ambiguous in the brief. This function only
 * needs a positive balance to exist, regardless of source (a real 'earned'
 * credit, or a staff 'adjusted' comp) — redeem shouldn't need to know or
 * care which.
 */

interface RedeemRequest {
  wristbandId: string;
  amount: number;
  reason?: string;
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
      throw new HttpError(403, "Only staff or admin can redeem wallet credits");
    }

    const { data: wristband, error: wristbandError } = await admin
      .from("wristbands")
      .select("id, family_id")
      .eq("id", body.wristbandId)
      .single();
    if (wristbandError || !wristband) throw new HttpError(404, "Wristband not found");

    // Known, accepted race: check-then-insert isn't atomic (the JS client
    // can't easily do row-locking/serializable transactions here), so two
    // redemptions against the same wristband within milliseconds of each
    // other could both pass this check. Accepted for now given this is a
    // physical staff action at a scanner — genuinely concurrent redemptions
    // on one wristband are a very different risk profile than, say, two web
    // requests racing on a shared cart. Would need a locking RPC to close
    // properly if it ever turns out to matter in practice.
    const { data: balanceRow } = await admin
      .from("family_credit_balance")
      .select("balance")
      .eq("family_id", wristband.family_id)
      .maybeSingle();
    const currentBalance = balanceRow?.balance ?? 0;

    if (currentBalance < body.amount) {
      throw new HttpError(409, `Insufficient credits: balance is ${currentBalance}, requested ${body.amount}`);
    }

    const { data: ledgerEntry, error: ledgerError } = await admin
      .from("game_credit_ledger")
      .insert({
        family_id: wristband.family_id,
        wristband_id: wristband.id,
        direction: "redeemed",
        amount: body.amount,
        reason: body.reason ?? null,
        created_by: caller.id,
      })
      .select("id, amount, created_at")
      .single();
    if (ledgerError || !ledgerEntry) throw new HttpError(500, `Failed to redeem credits: ${ledgerError?.message}`);

    const { error: auditError } = await admin.from("audit_log").insert({
      actor_profile_id: caller.id,
      action_type: "credit_redeemed",
      target_type: "wristband",
      target_id: wristband.id,
      details: `Redeemed ${body.amount} credit(s)${body.reason ? ` — ${body.reason}` : ""}`,
      status: "success",
    });
    if (auditError) console.error(`Failed to write audit_log for credit redemption: ${auditError.message}`);

    return jsonResponse({
      ledgerEntry,
      newBalance: currentBalance - body.amount,
    }, 201);
  } catch (err) {
    if (err instanceof HttpError) return errorResponse(err.message, err.status);
    console.error("wallet-redeem unhandled error:", err);
    return errorResponse("Internal error", 500);
  }
});

async function parseRequest(req: Request): Promise<RedeemRequest> {
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

  if (typeof b.wristbandId !== "string") throw new HttpError(400, "wristbandId is required");
  if (typeof b.amount !== "number" || !Number.isInteger(b.amount) || b.amount <= 0) {
    throw new HttpError(400, "amount must be a positive integer");
  }

  return {
    wristbandId: b.wristbandId,
    amount: b.amount,
    reason: typeof b.reason === "string" ? b.reason : undefined,
  };
}
