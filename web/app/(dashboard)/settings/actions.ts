"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

export interface FormState {
  error?: string;
  success?: boolean;
}

export async function updateVenueSettings(_prev: FormState, formData: FormData): Promise<FormState> {
  const supabase = await createClient();

  const parkName = String(formData.get("parkName") ?? "").trim();
  const timezone = String(formData.get("timezone") ?? "").trim();
  const currency = String(formData.get("currency") ?? "").trim();
  const logoUrl = String(formData.get("logoUrl") ?? "").trim();
  const contactPhone = String(formData.get("contactPhone") ?? "").trim();
  const contactEmail = String(formData.get("contactEmail") ?? "").trim();
  const brandPrimary = String(formData.get("brandPrimary") ?? "").trim();
  const brandAccent = String(formData.get("brandAccent") ?? "").trim();

  if (!parkName) return { error: "Park name is required" };
  if (!timezone) return { error: "Timezone is required" };
  if (!currency) return { error: "Currency is required" };

  const { error } = await supabase
    .from("venue_settings")
    .update({
      park_name: parkName,
      timezone,
      currency,
      logo_url: logoUrl || null,
      contact_info: { phone: contactPhone || null, email: contactEmail || null },
      brand_colors: { primary: brandPrimary || null, accent: brandAccent || null },
    })
    .eq("singleton", true);

  if (error) return { error: error.message };

  revalidatePath("/settings");
  return { success: true };
}
