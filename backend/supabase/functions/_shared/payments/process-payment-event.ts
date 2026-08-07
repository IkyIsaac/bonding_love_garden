import type { SupabaseClient } from "npm:@supabase/supabase-js@2";
import type { NormalizedPaymentEvent } from "./types.ts";
import { issueWristband } from "../wristbands.ts";

/**
 * "What happens when a payment succeeds" (docs/ARCHITECTURE_PLAN.md §4) —
 * the one place this logic lives regardless of which of the three
 * providers' webhooks fired. Scope, deliberately: marks the payment/order,
 * creates a subscription + wristband for each purchased access_plan. Two
 * things §4's description also lists ("credits the wallet") are NOT built
 * here — see the note below handlePaymentSucceeded for why.
 */

export interface ProcessResult {
  outcome: "processed" | "duplicate_ignored" | "payment_not_found";
  paymentId?: string;
  orderId?: string;
}

export async function processPaymentEvent(
  admin: SupabaseClient,
  providerId: string,
  event: NormalizedPaymentEvent,
): Promise<ProcessResult> {
  const { data: payment, error: paymentError } = await admin
    .from("payments")
    .select("id, order_id, status")
    .eq("id", event.paymentId)
    .eq("provider_id", providerId)
    .maybeSingle();

  if (paymentError || !payment) {
    return { outcome: "payment_not_found" };
  }

  // Idempotency: payment gateways retry webhooks aggressively. A webhook
  // repeating an already-terminal status is a replay — do nothing further,
  // most importantly don't create a second subscription/wristband for the
  // same purchase.
  if (payment.status === "succeeded" || payment.status === "failed") {
    return { outcome: "duplicate_ignored", paymentId: payment.id, orderId: payment.order_id };
  }

  const { error: updateError } = await admin
    .from("payments")
    .update({
      status: event.status,
      ...(event.providerTransactionReference ? { provider_reference: event.providerTransactionReference } : {}),
    })
    .eq("id", payment.id);
  if (updateError) {
    console.error(`Failed to update payment ${payment.id}: ${updateError.message}`);
    return { outcome: "payment_not_found" };
  }

  if (event.status === "succeeded") {
    await handlePaymentSucceeded(admin, payment.order_id);
  } else if (event.status === "failed") {
    await admin.from("orders").update({ status: "failed" }).eq("id", payment.order_id);
  }
  // "processing": payment status updated above, order stays 'pending' — nothing else to do yet.

  return { outcome: "processed", paymentId: payment.id, orderId: payment.order_id };
}

/**
 * NOT built here, both deliberately deferred rather than guessed:
 *
 * - Wallet crediting. The brief (§4.9) says games/services paid for but not
 *   yet used become wallet credit, but doesn't specify which purchased
 *   components convert to credits, how many, or how that interacts with an
 *   access_plan's own visit_limit/daily_time_limit — auto-crediting the
 *   wallet from every catalog_item bundled into a purchased plan/package
 *   would be inventing a credit-economy rule I'm not confident is right,
 *   for a feature where getting it wrong directly costs the venue money.
 * - Package-only or entry-fee-only orders don't get a subscription/
 *   wristband here — only access_plan order_items map cleanly onto
 *   subscriptions (packages have no validity_value/validity_unit of their
 *   own to compute an expiry from). A cart with no access_plan at all is a
 *   real gap this doesn't resolve.
 */
async function handlePaymentSucceeded(admin: SupabaseClient, orderId: string) {
  await admin.from("orders").update({ status: "paid" }).eq("id", orderId);

  const { data: order, error: orderError } = await admin
    .from("orders")
    .select("family_id")
    .eq("id", orderId)
    .single();
  if (orderError || !order) {
    console.error(`handlePaymentSucceeded: order ${orderId} not found after marking paid`);
    return;
  }

  const { data: planItems, error: planItemsError } = await admin
    .from("order_items")
    .select("id, reference_id, family_member_id, quantity")
    .eq("order_id", orderId)
    .eq("item_type", "access_plan");
  if (planItemsError) {
    console.error(`handlePaymentSucceeded: failed to load access_plan order_items for order ${orderId}: ${planItemsError.message}`);
    return;
  }

  const { data: entryFeeItem } = await admin
    .from("order_items")
    .select("reference_id")
    .eq("order_id", orderId)
    .eq("item_type", "entry_fee")
    .maybeSingle();
  const entryFeeConfigId: string | null = entryFeeItem?.reference_id ?? null;

  for (const item of planItems ?? []) {
    const { data: plan, error: planError } = await admin
      .from("access_plans")
      .select("validity_value, validity_unit, visit_limit")
      .eq("id", item.reference_id)
      .single();
    if (planError || !plan) {
      console.error(`handlePaymentSucceeded: access_plan ${item.reference_id} not found for order_item ${item.id}`);
      continue;
    }

    // quantity>1 with no family_member_id ("3x Adult Day Pass", not yet
    // assigned to specific people) becomes N separate subscriptions/
    // wristbands, each family_member_id=null — an interpretation, not
    // something the schema states outright. Physical assignment to a named
    // person happens later at wristband issuing/printing (a staff screen
    // per the brief, not built yet).
    for (let i = 0; i < item.quantity; i++) {
      const startsAt = new Date();
      const endsAt = addInterval(startsAt, plan.validity_value, plan.validity_unit);

      const { data: subscription, error: subError } = await admin
        .from("subscriptions")
        .insert({
          family_id: order.family_id,
          family_member_id: item.family_member_id,
          access_plan_id: item.reference_id,
          entry_fee_config_id: entryFeeConfigId,
          starts_at: startsAt.toISOString(),
          ends_at: endsAt.toISOString(),
          visits_remaining: plan.visit_limit,
          status: "active",
        })
        .select("id")
        .single();
      if (subError || !subscription) {
        console.error(`handlePaymentSucceeded: failed to create subscription for order_item ${item.id}: ${subError?.message}`);
        continue;
      }

      try {
        await issueWristband(admin, {
          familyId: order.family_id,
          familyMemberId: item.family_member_id,
          subscriptionId: subscription.id,
          expiresAt: endsAt,
        });
      } catch (err) {
        // Payment already succeeded and the subscription already exists —
        // don't fail the whole webhook over a wristband hiccup, just log it
        // loudly so it can be issued manually.
        console.error(
          `Failed to issue wristband for subscription ${subscription.id}: ${err instanceof Error ? err.message : err}`,
        );
      }
    }
  }

  await notifySupervisorsOfPurchase(admin, orderId);
  await notifyCustomerOfPurchase(admin, orderId, order.family_id);
}

function addInterval(date: Date, value: number, unit: string): Date {
  const result = new Date(date);
  switch (unit) {
    case "minutes":
      result.setMinutes(result.getMinutes() + value);
      break;
    case "hours":
      result.setHours(result.getHours() + value);
      break;
    case "days":
      result.setDate(result.getDate() + value);
      break;
    case "weeks":
      result.setDate(result.getDate() + value * 7);
      break;
    case "months":
      result.setMonth(result.getMonth() + value);
      break;
    case "years":
      result.setFullYear(result.getFullYear() + value);
      break;
  }
  return result;
}

/**
 * Creates the notification row(s) only — real-time delivery to a
 * supervisor's app comes for free from `notifications` already being in
 * the Realtime publication (see the notifications/audit_log migration).
 * Actual FCM push (§2's stated mechanism for background/killed-app
 * delivery) is a separate, not-yet-built concern.
 */
async function notifySupervisorsOfPurchase(admin: SupabaseClient, orderId: string) {
  const { data: supervisors, error } = await admin
    .from("profiles")
    .select("id")
    .eq("role", "supervisor")
    .eq("approval_status", "approved");
  if (error) {
    console.error(`notifySupervisorsOfPurchase: failed to list supervisors: ${error.message}`);
    return;
  }
  if (!supervisors || supervisors.length === 0) return;

  const { error: insertError } = await admin.from("notifications").insert(
    supervisors.map((s) => ({
      recipient_profile_id: s.id,
      type: "purchase_completed",
      title: "New purchase completed",
      body: "A new order has been paid — a wristband is ready to be admitted.",
      payload: { orderId },
    })),
  );
  if (insertError) {
    console.error(`notifySupervisorsOfPurchase: failed to insert notifications for order ${orderId}: ${insertError.message}`);
  }
}

/**
 * The customer-facing twin of notifySupervisorsOfPurchase — 'payment_confirmed'
 * is one of the example notification.type values named in this table's own
 * migration comment, but until now nothing actually wrote one. Recipient is
 * the family's owner_profile_id, not orders.buyer_profile_id: for a
 * customer_app order those are the same person, but for a staff_app sale
 * (Sell) buyer_profile_id is the staff member who rang it up — the family
 * owner is the one who actually needs to know their purchase went through.
 */
async function notifyCustomerOfPurchase(admin: SupabaseClient, orderId: string, familyId: string) {
  const { data: family, error: familyError } = await admin
    .from("families")
    .select("owner_profile_id")
    .eq("id", familyId)
    .maybeSingle();
  if (familyError || !family) {
    console.error(`notifyCustomerOfPurchase: failed to look up family ${familyId}: ${familyError?.message}`);
    return;
  }

  const { error: insertError } = await admin.from("notifications").insert({
    recipient_profile_id: family.owner_profile_id,
    type: "payment_confirmed",
    title: "Payment confirmed",
    body: "Your payment went through — your wristband is ready.",
    payload: { orderId },
  });
  if (insertError) {
    console.error(`notifyCustomerOfPurchase: failed to insert notification for order ${orderId}: ${insertError.message}`);
  }
}
