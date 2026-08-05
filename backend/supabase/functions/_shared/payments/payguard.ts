import type { InitiateParams, InitiateResult, NormalizedPaymentEvent, PaymentProvider } from "./types.ts";
import { verifyHmacSha256 } from "./hmac.ts";

/**
 * PLACEHOLDER PROVIDER — see selcom.ts for the full caveat; applies doubly
 * here since "Payguard" doesn't appear to be a real, publicly documented
 * payment gateway at all (unlike Selcom). Treat this entirely as a shape
 * to swap real integration code into, not a real integration.
 */

const API_KEY = Deno.env.get("PAYGUARD_API_KEY") ?? "";
const WEBHOOK_SECRET = Deno.env.get("PAYGUARD_WEBHOOK_SECRET") ?? "";

export const payguardProvider: PaymentProvider = {
  code: "payguard",
  displayName: "Payguard Pro",

  initiate(params: InitiateParams): Promise<InitiateResult> {
    if (!API_KEY) {
      throw new Error("PAYGUARD_API_KEY is not configured");
    }
    return Promise.resolve({
      redirectUrl: `https://secure.payguard.example/checkout?ref=${encodeURIComponent(params.paymentId)}`,
    });
  },

  async verifyWebhookSignature(req: Request, rawBody: string): Promise<boolean> {
    const signature = req.headers.get("x-payguard-signature");
    if (!signature) return false;
    return await verifyHmacSha256(rawBody, signature, WEBHOOK_SECRET);
  },

  parseWebhookPayload(rawBody: string): NormalizedPaymentEvent {
    const payload = JSON.parse(rawBody) as Record<string, unknown>;
    return {
      paymentId: String(payload.merchantRef ?? ""),
      providerTransactionReference: payload.paymentId ? String(payload.paymentId) : null,
      status: mapStatus(String(payload.status ?? "")),
      rawEventType: String(payload.eventType ?? "payment_update"),
    };
  },
};

function mapStatus(providerStatus: string): "processing" | "succeeded" | "failed" {
  const s = providerStatus.toLowerCase();
  if (["approved", "captured", "success"].includes(s)) return "succeeded";
  if (["declined", "failed", "voided"].includes(s)) return "failed";
  return "processing";
}
