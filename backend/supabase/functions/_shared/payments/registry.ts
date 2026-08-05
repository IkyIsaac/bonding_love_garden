import type { PaymentProvider } from "./types.ts";
import { selcomProvider } from "./selcom.ts";
import { snippeProvider } from "./snippe.ts";
import { payguardProvider } from "./payguard.ts";

const PROVIDERS: Record<string, PaymentProvider> = {
  [selcomProvider.code]: selcomProvider,
  [snippeProvider.code]: snippeProvider,
  [payguardProvider.code]: payguardProvider,
};

/** Onboarding a fourth provider: add its file above, one line here, one row in payment_providers. */
export function getProvider(code: string): PaymentProvider | undefined {
  return PROVIDERS[code];
}
