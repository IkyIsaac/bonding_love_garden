import type { InitiateParams, InitiateResult, NormalizedPaymentEvent, PaymentProvider } from "./types.ts";
import { verifyHmacSha256 } from "./hmac.ts";

/**
 * PLACEHOLDER PROVIDER — structurally correct (implements PaymentProvider,
 * so payments-initiate and payments-webhook-selcom are real and testable
 * end-to-end), but the HTTP call and field names below are NOT verified
 * against Selcom's actual merchant API. Selcom is a real Tanzanian mobile
 * money/card gateway (the brief names it explicitly), but this file doesn't
 * have their current API docs to work from. Confirm the real checkout
 * endpoint, the exact signature header/algorithm, and the real webhook
 * payload shape before this goes anywhere near a live transaction — do not
 * assume the shape below matches production Selcom.
 *
 * The pattern used (redirect-based checkout, HMAC-SHA256 over the raw
 * webhook body, a merchant-supplied reference echoed back) is the common
 * shape most mobile-money/card gateways in this space use, which is why
 * it's the placeholder shape here rather than something invented at
 * random — but "common shape" isn't "verified shape."
 */

const API_KEY = Deno.env.get("SELCOM_API_KEY") ?? "";
const API_SECRET = Deno.env.get("SELCOM_API_SECRET") ?? "";
const WEBHOOK_SECRET = Deno.env.get("SELCOM_WEBHOOK_SECRET") ?? "";

export const selcomProvider: PaymentProvider = {
  code: "selcom",
  displayName: "Selcom Pay",

  initiate(params: InitiateParams): Promise<InitiateResult> {
    if (!API_KEY || !API_SECRET) {
      throw new Error("SELCOM_API_KEY / SELCOM_API_SECRET are not configured");
    }
    // TODO: real Selcom checkout API call. Placeholder returns a redirect
    // shape only so the end-to-end flow (initiate -> client redirect ->
    // webhook -> processPaymentEvent) is real and testable now.
    return Promise.resolve({
      redirectUrl: `https://checkout.selcom.example/pay?ref=${encodeURIComponent(params.paymentId)}`,
    });
  },

  async verifyWebhookSignature(req: Request, rawBody: string): Promise<boolean> {
    const signature = req.headers.get("x-selcom-signature");
    if (!signature) return false;
    return await verifyHmacSha256(rawBody, signature, WEBHOOK_SECRET);
  },

  parseWebhookPayload(rawBody: string): NormalizedPaymentEvent {
    // TODO: confirm actual field names against a real Selcom webhook payload.
    const payload = JSON.parse(rawBody) as Record<string, unknown>;
    return {
      paymentId: String(payload.reference ?? payload.merchant_reference ?? ""),
      providerTransactionReference: payload.transaction_id ? String(payload.transaction_id) : null,
      status: mapStatus(String(payload.result ?? payload.status ?? "")),
      rawEventType: String(payload.event_type ?? "payment_update"),
    };
  },
};

function mapStatus(providerStatus: string): "processing" | "succeeded" | "failed" {
  const s = providerStatus.toLowerCase();
  if (["success", "successful", "completed", "paid"].includes(s)) return "succeeded";
  if (["failed", "declined", "cancelled", "canceled", "rejected"].includes(s)) return "failed";
  return "processing";
}
