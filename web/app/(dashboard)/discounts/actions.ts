"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

export interface FormState {
  error?: string;
  success?: boolean;
}

export async function upsertDiscountRule(_prev: FormState, formData: FormData): Promise<FormState> {
  const supabase = await createClient();

  const id = formData.get("id") ? String(formData.get("id")) : undefined;
  const name = String(formData.get("name") ?? "").trim();
  const description = String(formData.get("description") ?? "").trim();
  const discountType = String(formData.get("discountType"));
  const discountValue = Number(formData.get("discountValue"));
  const minQuantityRaw = String(formData.get("minQuantity") ?? "").trim();
  const validFromRaw = String(formData.get("validFrom") ?? "").trim();
  const validToRaw = String(formData.get("validTo") ?? "").trim();
  const daysOfWeek = formData.getAll("daysOfWeek").map(Number);
  const status = String(formData.get("status"));
  // Values are either "entry_fee" or a catalog_item_id — matches
  // discount_rule_components' target check (exactly one of the two).
  const componentValues = formData.getAll("components").map(String);

  if (!name) return { error: "Name is required" };
  if (discountType !== "percent" && discountType !== "flat") return { error: "Invalid discount type" };
  if (Number.isNaN(discountValue) || discountValue <= 0) return { error: "Discount value must be positive" };
  if (!["draft", "enabled", "disabled", "archived"].includes(status)) return { error: "Invalid status" };
  if (componentValues.length === 0) return { error: "Select at least one qualifying component" };

  const payload = {
    name,
    description: description || null,
    discount_type: discountType,
    discount_value: discountValue,
    min_quantity: minQuantityRaw ? Number(minQuantityRaw) : null,
    valid_from: validFromRaw ? new Date(validFromRaw).toISOString() : null,
    valid_to: validToRaw ? new Date(validToRaw).toISOString() : null,
    days_of_week: daysOfWeek.length > 0 ? daysOfWeek : null,
    status,
  };

  let ruleId = id;
  if (id) {
    const { error } = await supabase.from("discount_rules").update(payload).eq("id", id);
    if (error) return { error: error.message };
  } else {
    const { data, error } = await supabase.from("discount_rules").insert(payload).select("id").single();
    if (error || !data) return { error: error?.message ?? "Failed to create rule" };
    ruleId = data.id;
  }

  const { error: deleteError } = await supabase.from("discount_rule_components").delete().eq("discount_rule_id", ruleId!);
  if (deleteError) return { error: deleteError.message };

  const componentsToInsert = componentValues.map((value) =>
    value === "entry_fee"
      ? { discount_rule_id: ruleId!, catalog_item_id: null, is_entry_fee: true }
      : { discount_rule_id: ruleId!, catalog_item_id: value, is_entry_fee: false }
  );
  const { error: insertError } = await supabase.from("discount_rule_components").insert(componentsToInsert);
  if (insertError) return { error: insertError.message };

  revalidatePath("/discounts");
  return { success: true };
}

export async function deleteDiscountRule(id: string): Promise<FormState> {
  const supabase = await createClient();
  const { error } = await supabase.from("discount_rules").delete().eq("id", id);
  if (error) return { error: error.message };
  revalidatePath("/discounts");
  return { success: true };
}
