import type { InitiateParams, InitiateResult, NormalizedPaymentEvent, PaymentProvider } from "./types.ts";
import { verifyHmacSha256 } from "./hmac.ts";

/**
 * PLACEHOLDER PROVIDER — see selcom.ts for the full caveat; applies doubly
 * here since "Snippe" doesn't appear to be a real, publicly documented
 * payment gateway at all (unlike Selcom). Treat this entirely as a shape
 * to swap real integration code into, not a real integration.
 */

const API_KEY = Deno.env.get("SNIPPE_API_KEY") ?? "";
const WEBHOOK_SECRET = Deno.env.get("SNIPPE_WEBHOOK_SECRET") ?? "";

export const snippeProvider: PaymentProvider = {
  code: "snippe",
  displayName: "Snippe Wallet",

  initiate(params: InitiateParams): Promise<InitiateResult> {
    if (!API_KEY) {
      throw new Error("SNIPPE_API_KEY is not configured");
    }
    return Promise.resolve({
      redirectUrl: `https://pay.snippe.example/checkout?ref=${encodeURIComponent(params.paymentId)}`,
    });
  },

  async verifyWebhookSignature(req: Request, rawBody: string): Promise<boolean> {
    const signature = req.headers.get("x-snippe-signature");
    if (!signature) return false;
    return await verifyHmacSha256(rawBody, signature, WEBHOOK_SECRET);
  },

  parseWebhookPayload(rawBody: string): NormalizedPaymentEvent {
    const payload = JSON.parse(rawBody) as Record<string, unknown>;
    return {
      paymentId: String(payload.reference ?? ""),
      providerTransactionReference: payload.txnId ? String(payload.txnId) : null,
      status: mapStatus(String(payload.state ?? "")),
      rawEventType: String(payload.type ?? "payment_update"),
    };
  },
};

function mapStatus(providerStatus: string): "processing" | "succeeded" | "failed" {
  const s = providerStatus.toLowerCase();
  if (["success", "settled", "confirmed"].includes(s)) return "succeeded";
  if (["failed", "expired", "cancelled"].includes(s)) return "failed";
  return "processing";
}
