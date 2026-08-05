import type { SupabaseClient } from "npm:@supabase/supabase-js@2";
import { errorResponse, jsonResponse } from "../cors.ts";
import { getProvider } from "./registry.ts";
import { processPaymentEvent } from "./process-payment-event.ts";
import type { NormalizedPaymentEvent } from "./types.ts";

/**
 * Shared body for all three payments-webhook-* functions — each is a thin
 * wrapper calling this with its own provider code. Can't be one shared URL:
 * each provider has its own signature scheme, so the endpoint has to know
 * up front which provider (and which secret) it's dealing with.
 */
export async function handleProviderWebhook(
  admin: SupabaseClient,
  providerCode: string,
  req: Request,
): Promise<Response> {
  const provider = getProvider(providerCode);
  if (!provider) return errorResponse(`No implementation registered for provider '${providerCode}'`, 500);

  const { data: providerRow, error: providerRowError } = await admin
    .from("payment_providers")
    .select("id")
    .eq("code", providerCode)
    .maybeSingle();
  if (providerRowError || !providerRow) {
    return errorResponse(`Provider '${providerCode}' is not registered in payment_providers`, 500);
  }

  const rawBody = await req.text();
  const signatureVerified = await provider.verifyWebhookSignature(req, rawBody);

  let parsedEvent: NormalizedPaymentEvent | null = null;
  if (signatureVerified) {
    try {
      parsedEvent = provider.parseWebhookPayload(rawBody);
    } catch (err) {
      console.error(`${providerCode} webhook: failed to parse payload: ${err instanceof Error ? err.message : err}`);
    }
  }

  let payloadForLog: unknown;
  try {
    payloadForLog = JSON.parse(rawBody);
  } catch {
    payloadForLog = { raw: rawBody };
  }

  // Log every inbound call regardless of outcome — payment_webhook_events
  // is the replay-safety/audit trail (§3.4), so an invalid-signature or
  // unparseable call still needs a record, not just the ones we act on.
  const { data: loggedEvent } = await admin
    .from("payment_webhook_events")
    .insert({
      provider_id: providerRow.id,
      event_type: parsedEvent?.rawEventType ?? "unknown",
      payload: payloadForLog,
      signature_verified: signatureVerified,
    })
    .select("id")
    .single();

  if (!signatureVerified) {
    console.warn(`${providerCode} webhook: signature verification failed`);
    return errorResponse("Invalid signature", 401);
  }
  if (!parsedEvent) {
    return errorResponse("Unable to parse webhook payload", 400);
  }

  const result = await processPaymentEvent(admin, providerRow.id, parsedEvent);

  if (loggedEvent) {
    await admin
      .from("payment_webhook_events")
      .update({ payment_id: result.paymentId ?? null, processed_at: new Date().toISOString() })
      .eq("id", loggedEvent.id);
  }

  if (result.outcome === "payment_not_found") {
    console.error(`${providerCode} webhook: no matching payment for reference '${parsedEvent.paymentId}'`);
  }

  // 200 regardless of match/duplicate outcome once the signature is valid —
  // an unmatched or replayed event is logged and safely ignored, not
  // something the provider should retry indefinitely over.
  return jsonResponse({ received: true, outcome: result.outcome });
}
