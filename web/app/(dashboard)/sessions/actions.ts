"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

export interface FormState {
  error?: string;
  success?: boolean;
}

/** admin is included in sessions' RLS UPDATE policy alongside supervisor — no Edge Function needed. */
export async function extendSession(id: string, minutes: number): Promise<FormState> {
  const supabase = await createClient();

  const { data: session, error: fetchError } = await supabase
    .from("sessions")
    .select("planned_end_at, extended_minutes_total")
    .eq("id", id)
    .single();
  if (fetchError || !session) return { error: fetchError?.message ?? "Session not found" };

  const newPlannedEnd = new Date(session.planned_end_at);
  newPlannedEnd.setMinutes(newPlannedEnd.getMinutes() + minutes);

  const { error } = await supabase
    .from("sessions")
    .update({
      planned_end_at: newPlannedEnd.toISOString(),
      extended_minutes_total: session.extended_minutes_total + minutes,
    })
    .eq("id", id);
  if (error) return { error: error.message };

  revalidatePath("/sessions");
  return { success: true };
}

export async function endSession(id: string): Promise<FormState> {
  const supabase = await createClient();
  const { error } = await supabase.from("sessions").update({ ended_at: new Date().toISOString() }).eq("id", id);
  if (error) return { error: error.message };
  revalidatePath("/sessions");
  return { success: true };
}
