import type { SupabaseClient } from "npm:@supabase/supabase-js@2";

/**
 * Extracted from process-payment-event.ts now that there's a real second
 * caller (wristband-issue) — same rule as cart-pricing.ts only getting
 * pulled out of checkout-create-order once discount-preview needed it too.
 */

export interface IssueWristbandParams {
  familyId: string;
  familyMemberId: string | null;
  subscriptionId: string | null; // nullable: a complimentary/manual pass has no subscription
  expiresAt: Date;
  issuedBy?: string | null; // staff profile id, if issued in person
}

export interface IssuedWristband {
  id: string;
  qrCodeValue: string;
  wristbandNumber: string;
  expiresAt: string;
}

/** Throws on failure — callers decide whether that should fail the whole request (wristband-issue) or just be logged and swallowed (the payment webhook, mid already-successful payment processing). */
export async function issueWristband(
  admin: SupabaseClient,
  params: IssueWristbandParams,
): Promise<IssuedWristband> {
  const qrCodeValue = `WB-${crypto.randomUUID()}`;
  const wristbandNumber = qrCodeValue.slice(3, 15).toUpperCase();

  const { data, error } = await admin
    .from("wristbands")
    .insert({
      family_id: params.familyId,
      family_member_id: params.familyMemberId,
      subscription_id: params.subscriptionId,
      qr_code_value: qrCodeValue,
      wristband_number: wristbandNumber,
      expires_at: params.expiresAt.toISOString(),
      issued_by: params.issuedBy ?? null,
    })
    .select("id, qr_code_value, wristband_number, expires_at")
    .single();

  if (error || !data) {
    throw new Error(`Failed to issue wristband: ${error?.message}`);
  }

  return {
    id: data.id,
    qrCodeValue: data.qr_code_value,
    wristbandNumber: data.wristband_number,
    expiresAt: data.expires_at,
  };
}
