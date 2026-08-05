"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

export interface FormState {
  error?: string;
  success?: boolean;
}

/** admin has direct RLS UPDATE rights on wristbands — no Edge Function needed. */
export async function revokeWristband(id: string): Promise<FormState> {
  const supabase = await createClient();
  const { error } = await supabase.from("wristbands").update({ status: "revoked" }).eq("id", id);
  if (error) return { error: error.message };
  revalidatePath("/wristbands");
  return { success: true };
}
