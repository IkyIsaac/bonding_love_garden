"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

export interface FormState {
  error?: string;
  success?: boolean;
}

export async function upsertPackage(_prev: FormState, formData: FormData): Promise<FormState> {
  const supabase = await createClient();

  const id = formData.get("id") ? String(formData.get("id")) : undefined;
  const name = String(formData.get("name") ?? "").trim();
  const description = String(formData.get("description") ?? "").trim();
  const price = Number(formData.get("price"));
  const availabilityStartRaw = String(formData.get("availabilityStart") ?? "").trim();
  const availabilityEndRaw = String(formData.get("availabilityEnd") ?? "").trim();
  const imageUrl = String(formData.get("imageUrl") ?? "").trim();
  const isActive = formData.get("isActive") === "on";

  if (!name) return { error: "Name is required" };
  if (Number.isNaN(price) || price < 0) return { error: "Price must be non-negative" };

  const payload = {
    name,
    description: description || null,
    price,
    availability_start: availabilityStartRaw ? new Date(availabilityStartRaw).toISOString() : null,
    availability_end: availabilityEndRaw ? new Date(availabilityEndRaw).toISOString() : null,
    image_url: imageUrl || null,
    is_active: isActive,
  };

  let packageId = id;
  if (id) {
    const { error } = await supabase.from("packages").update(payload).eq("id", id);
    if (error) return { error: error.message };
  } else {
    const { data, error } = await supabase.from("packages").insert(payload).select("id").single();
    if (error || !data) return { error: error?.message ?? "Failed to create package" };
    packageId = data.id;
  }

  const { error: deleteError } = await supabase.from("package_items").delete().eq("package_id", packageId!);
  if (deleteError) return { error: deleteError.message };

  // Quantity inputs are named "quantity__<catalogItemId>"; only positive quantities get bundled in.
  const itemsToInsert: { package_id: string; catalog_item_id: string; quantity: number }[] = [];
  for (const [key, value] of formData.entries()) {
    if (!key.startsWith("quantity__")) continue;
    const catalogItemId = key.slice("quantity__".length);
    const quantity = Number(value);
    if (quantity > 0) itemsToInsert.push({ package_id: packageId!, catalog_item_id: catalogItemId, quantity });
  }

  if (itemsToInsert.length === 0) return { error: "Bundle at least one item with a quantity above 0" };

  const { error: insertError } = await supabase.from("package_items").insert(itemsToInsert);
  if (insertError) return { error: insertError.message };

  revalidatePath("/packages");
  return { success: true };
}

export async function deletePackage(id: string): Promise<FormState> {
  const supabase = await createClient();
  const { error } = await supabase.from("packages").delete().eq("id", id);
  if (error) return { error: error.message };
  revalidatePath("/packages");
  return { success: true };
}
