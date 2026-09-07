"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

export interface FormState {
  error?: string;
  success?: boolean;
}

/** admin has the subscriptions UPDATE RLS grant — no Edge Function needed. */
export async function cancelSubscription(id: string): Promise<FormState> {
  const supabase = await createClient();
  const { error } = await supabase.from("subscriptions").update({ status: "cancelled" }).eq("id", id);
  if (error) return { error: error.message };
  revalidatePath("/subscriptions");
  return { success: true };
}
