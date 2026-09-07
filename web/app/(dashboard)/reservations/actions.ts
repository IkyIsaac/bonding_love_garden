"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

export interface FormState {
  error?: string;
  success?: boolean;
}

/** admin has the reservations UPDATE RLS grant — no Edge Function needed. */
export async function cancelReservation(id: string): Promise<FormState> {
  const supabase = await createClient();
  const { error } = await supabase.from("reservations").update({ status: "cancelled" }).eq("id", id);
  if (error) return { error: error.message };
  revalidatePath("/reservations");
  return { success: true };
}

export async function updateReservationSettings(_prev: FormState, formData: FormData): Promise<FormState> {
  const supabase = await createClient();

  const maxAdvanceDays = Number(formData.get("maxAdvanceDays"));
  const maxPerDayRaw = String(formData.get("maxPerDayPerFamily") ?? "").trim();
  const defaultFee = Number(formData.get("defaultFee"));

  if (!Number.isInteger(maxAdvanceDays) || maxAdvanceDays < 1) {
    return { error: "Max advance days must be a whole number of at least 1" };
  }
  if (Number.isNaN(defaultFee) || defaultFee < 0) {
    return { error: "Default fee must be a non-negative number" };
  }
  let maxPerDayPerFamily: number | null = null;
  if (maxPerDayRaw !== "") {
    maxPerDayPerFamily = Number(maxPerDayRaw);
    if (!Number.isInteger(maxPerDayPerFamily) || maxPerDayPerFamily < 1) {
      return { error: "Max reservations per day must be blank (unlimited) or a whole number of at least 1" };
    }
  }

  const { error } = await supabase
    .from("reservation_settings")
    .update({
      max_advance_days: maxAdvanceDays,
      max_per_day_per_family: maxPerDayPerFamily,
      default_fee: defaultFee,
    })
    .eq("singleton", true);

  if (error) return { error: error.message };

  revalidatePath("/reservations");
  return { success: true };
}
