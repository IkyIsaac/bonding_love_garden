"use client";

import { useActionState } from "react";
import { updateReservationSettings, type FormState } from "./actions";
import { TextField } from "@/components/ui/fields";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import type { Database } from "@/types/database";

type ReservationSettings = Database["public"]["Tables"]["reservation_settings"]["Row"];

export default function ReservationSettingsForm({ settings }: { settings: ReservationSettings }) {
  const [state, formAction, pending] = useActionState<FormState, FormData>(updateReservationSettings, {});

  return (
    <Card>
      <CardHeader>
        <CardTitle>Reservation Rules</CardTitle>
        <CardDescription>How far ahead, how many per day, and the default fee — enforced by reservations-book.</CardDescription>
      </CardHeader>
      <CardContent>
        <form action={formAction} className="flex flex-col gap-4 max-w-xl">
          <div className="grid grid-cols-3 gap-4">
            <TextField
              label="Max advance days"
              name="maxAdvanceDays"
              type="number"
              min={1}
              defaultValue={settings.max_advance_days}
              required
            />
            <TextField
              label="Max per day / family"
              name="maxPerDayPerFamily"
              type="number"
              min={1}
              placeholder="Unlimited"
              defaultValue={settings.max_per_day_per_family ?? ""}
            />
            <TextField
              label="Default fee"
              name="defaultFee"
              type="number"
              min={0}
              step="0.01"
              defaultValue={settings.default_fee}
              required
            />
          </div>

          {state.error && <p className="text-sm text-destructive">{state.error}</p>}
          {state.success && <p className="text-sm text-primary">Saved.</p>}

          <Button type="submit" disabled={pending} className="self-start">
            {pending ? "Saving…" : "Save changes"}
          </Button>
        </form>
      </CardContent>
    </Card>
  );
}
