/**
 * The pluggable-provider contract (docs/ARCHITECTURE_PLAN.md §4): Selcom,
 * Snippe, and Payguard each implement this once; onboarding a fourth
 * provider is one new file + one new payments-webhook-* function + one new
 * payment_providers row — never touching processPaymentEvent.
 */

export interface InitiateParams {
  /** Our payments.id — passed to the provider as "your merchant reference" so the webhook can look the row up without trusting the provider's own reference format. */
  paymentId: string;
  orderId: string;
  amount: number;
  currency: string;
}

export interface InitiateResult {
  redirectUrl?: string;
  ussdCode?: string;
  instructions?: string;
  /** Only if the provider hands back an immediate transaction id at initiate time — not all do. */
  providerTransactionReference?: string;
}

export type PaymentEventStatus = "processing" | "succeeded" | "failed";

export interface NormalizedPaymentEvent {
  /** Resolved from whatever field the provider echoes our merchant reference back in. */
  paymentId: string;
  providerTransactionReference: string | null;
  status: PaymentEventStatus;
  rawEventType: string;
}

export interface PaymentProvider {
  code: string;
  displayName: string;
  initiate(params: InitiateParams): Promise<InitiateResult>;
  verifyWebhookSignature(req: Request, rawBody: string): Promise<boolean>;
  parseWebhookPayload(rawBody: string): NormalizedPaymentEvent;
}
