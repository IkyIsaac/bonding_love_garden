"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

export interface FormState {
  error?: string;
  success?: boolean;
}

export async function upsertCatalogItem(_prev: FormState, formData: FormData): Promise<FormState> {
  const supabase = await createClient();

  const id = formData.get("id") ? String(formData.get("id")) : undefined;
  const type = String(formData.get("type"));
  const name = String(formData.get("name") ?? "").trim();
  const description = String(formData.get("description") ?? "").trim();
  const price = Number(formData.get("price"));
  const pricingUnit = String(formData.get("pricingUnit") ?? "flat");
  const isMotorized = formData.get("isMotorized") === "on";
  const isActive = formData.get("isActive") === "on";

  if (!name) return { error: "Name is required" };
  if (type !== "game" && type !== "service") return { error: "Invalid type" };
  if (Number.isNaN(price) || price < 0) return { error: "Price must be a non-negative number" };

  const payload = {
    type,
    name,
    description: description || null,
    price,
    pricing_unit: pricingUnit,
    is_motorized: type === "game" ? isMotorized : null,
    is_active: isActive,
  };

  const { error } = id
    ? await supabase.from("catalog_items").update(payload).eq("id", id)
    : await supabase.from("catalog_items").insert(payload);

  if (error) return { error: error.message };
  revalidatePath("/plans");
  return { success: true };
}

export async function deleteCatalogItem(id: string): Promise<FormState> {
  const supabase = await createClient();
  const { error } = await supabase.from("catalog_items").delete().eq("id", id);
  if (error) return { error: error.message };
  revalidatePath("/plans");
  return { success: true };
}

export async function upsertAccessPlan(_prev: FormState, formData: FormData): Promise<FormState> {
  const supabase = await createClient();

  const id = formData.get("id") ? String(formData.get("id")) : undefined;
  const name = String(formData.get("name") ?? "").trim();
  const planType = String(formData.get("planType"));
  const price = Number(formData.get("price"));
  const validityValue = Number(formData.get("validityValue"));
  const validityUnit = String(formData.get("validityUnit"));
  const visitLimitRaw = String(formData.get("visitLimit") ?? "").trim();
  const dailyTimeLimitRaw = String(formData.get("dailyTimeLimit") ?? "").trim();
  const isActive = formData.get("isActive") === "on";
  const catalogItemIds = formData.getAll("catalogItemIds").map(String);

  if (!name) return { error: "Name is required" };
  if (planType !== "single_visit" && planType !== "membership") return { error: "Invalid plan type" };
  if (Number.isNaN(price) || price < 0) return { error: "Price must be non-negative" };
  if (Number.isNaN(validityValue) || validityValue <= 0) return { error: "Validity value must be positive" };

  const payload = {
    name,
    plan_type: planType,
    price,
    validity_value: validityValue,
    validity_unit: validityUnit,
    visit_limit: visitLimitRaw ? Number(visitLimitRaw) : null,
    daily_time_limit_minutes: dailyTimeLimitRaw ? Number(dailyTimeLimitRaw) : null,
    is_active: isActive,
  };

  let planId = id;
  if (id) {
    const { error } = await supabase.from("access_plans").update(payload).eq("id", id);
    if (error) return { error: error.message };
  } else {
    const { data, error } = await supabase.from("access_plans").insert(payload).select("id").single();
    if (error || !data) return { error: error?.message ?? "Failed to create plan" };
    planId = data.id;
  }

  // Replace the plan's included items wholesale rather than diffing — simplest correct approach for a small join table.
  const { error: deleteError } = await supabase.from("access_plan_items").delete().eq("access_plan_id", planId!);
  if (deleteError) return { error: deleteError.message };

  if (catalogItemIds.length > 0) {
    const { error: insertError } = await supabase
      .from("access_plan_items")
      .insert(catalogItemIds.map((catalogItemId) => ({ access_plan_id: planId!, catalog_item_id: catalogItemId })));
    if (insertError) return { error: insertError.message };
  }

  revalidatePath("/plans");
  return { success: true };
}

export async function deleteAccessPlan(id: string): Promise<FormState> {
  const supabase = await createClient();
  const { error } = await supabase.from("access_plans").delete().eq("id", id);
  if (error) return { error: error.message };
  revalidatePath("/plans");
  return { success: true };
}

/**
 * Only ever inserts — entry_fee_config has no UPDATE policy at all (see
 * migrations), by design ("insert a new version, never mutate a row"). The
 * close_previous_entry_fee_config trigger automatically closes out the
 * previous row's effective_to; this action doesn't need to (and can't).
 */
export async function setEntryFee(_prev: FormState, formData: FormData): Promise<FormState> {
  const supabase = await createClient();

  const amount = Number(formData.get("amount"));
  if (Number.isNaN(amount) || amount < 0) return { error: "Amount must be non-negative" };

  const { data: { user } } = await supabase.auth.getUser();

  const { error } = await supabase.from("entry_fee_config").insert({
    amount,
    created_by: user?.id ?? null,
  });
  if (error) return { error: error.message };

  revalidatePath("/plans");
  return { success: true };
}
