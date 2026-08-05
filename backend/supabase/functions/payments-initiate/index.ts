import type { SupabaseClient } from "npm:@supabase/supabase-js@2";
import { createAdminClient } from "../_shared/supabase-clients.ts";
import { assertApproved, isStaffRole, resolveCaller } from "../_shared/auth.ts";
import { corsHeaders, errorResponse, jsonResponse } from "../_shared/cors.ts";
import { HttpError } from "../_shared/http-error.ts";
import { getProvider } from "../_shared/payments/registry.ts";

interface InitiateRequest {
  orderId: string;
  providerCode: string;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return errorResponse("Method not allowed", 405);

  const admin = createAdminClient();

  try {
    const body = await parseRequest(req);
    const caller = await resolveCaller(req.headers.get("Authorization"), admin);
    assertApproved(caller);

    const { data: order, error: orderError } = await admin
      .from("orders")
      .select("id, family_id, total_amount, status")
      .eq("id", body.orderId)
      .single();
    if (orderError || !order) throw new HttpError(404, "Order not found");
    if (order.status !== "pending") {
      throw new HttpError(409, `Order is '${order.status}', not payable`);
    }

    if (!isStaffRole(caller.role)) {
      const { data: family } = await admin
        .from("families")
        .select("owner_profile_id")
        .eq("id", order.family_id)
        .single();
      if (family?.owner_profile_id !== caller.id) {
        throw new HttpError(403, "This order does not belong to you");
      }
    }

    const { data: providerRow, error: providerError } = await admin
      .from("payment_providers")
      .select("id, code, is_active")
      .eq("code", body.providerCode)
      .single();
    if (providerError || !providerRow) {
      throw new HttpError(404, `Unknown payment provider '${body.providerCode}'`);
    }
    if (!providerRow.is_active) {
      throw new HttpError(400, `Payment provider '${body.providerCode}' is not currently available`);
    }

    const provider = getProvider(providerRow.code);
    if (!provider) throw new HttpError(500, `No implementation registered for provider '${providerRow.code}'`);

    // Reuse an existing pending/processing payment for this order+provider
    // rather than creating a new row every time the client calls initiate
    // (e.g. the customer backs out of the payment page and retries) —
    // keeps payments_provider_reference_uniq meaningful and avoids
    // orphaned payment rows piling up per retry.
    const { data: existingPayment } = await admin
      .from("payments")
      .select("id, status")
      .eq("order_id", order.id)
      .eq("provider_id", providerRow.id)
      .in("status", ["pending", "processing"])
      .maybeSingle();

    const payment = existingPayment ?? await createPayment(admin, order.id, providerRow.id, order.total_amount);

    const currency = await resolveVenueCurrency(admin);

    const initiateResult = await provider.initiate({
      paymentId: payment.id,
      orderId: order.id,
      amount: order.total_amount,
      currency,
    });

    if (initiateResult.providerTransactionReference) {
      await admin
        .from("payments")
        .update({ provider_reference: initiateResult.providerTransactionReference })
        .eq("id", payment.id);
    }

    return jsonResponse({
      paymentId: payment.id,
      provider: providerRow.code,
      ...initiateResult,
    });
  } catch (err) {
    if (err instanceof HttpError) return errorResponse(err.message, err.status);
    console.error("payments-initiate unhandled error:", err);
    return errorResponse("Internal error", 500);
  }
});

async function parseRequest(req: Request): Promise<InitiateRequest> {
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
  if (typeof b.orderId !== "string") throw new HttpError(400, "orderId is required");
  if (typeof b.providerCode !== "string") throw new HttpError(400, "providerCode is required");
  return { orderId: b.orderId, providerCode: b.providerCode };
}

async function createPayment(admin: SupabaseClient, orderId: string, providerId: string, amount: number) {
  const { data, error } = await admin
    .from("payments")
    .insert({ order_id: orderId, provider_id: providerId, amount, status: "pending" })
    .select("id, status")
    .single();
  if (error || !data) throw new HttpError(500, `Failed to create payment: ${error?.message}`);
  return data;
}

async function resolveVenueCurrency(admin: SupabaseClient): Promise<string> {
  const { data } = await admin.from("venue_settings").select("currency").single();
  return data?.currency ?? "TZS";
}
