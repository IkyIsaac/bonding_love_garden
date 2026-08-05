"use client";

import { useActionState } from "react";
import { updateVenueSettings, type FormState } from "./actions";
import { TextField } from "@/components/ui/fields";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import type { Database } from "@/types/database";

type VenueSettings = Database["public"]["Tables"]["venue_settings"]["Row"];

export default function SettingsForm({ settings }: { settings: VenueSettings }) {
  const contactInfo = (settings.contact_info ?? {}) as { phone?: string; email?: string };
  const brandColors = (settings.brand_colors ?? {}) as { primary?: string; accent?: string };

  const [state, formAction, pending] = useActionState<FormState, FormData>(updateVenueSettings, {});

  return (
    <form action={formAction} className="flex flex-col gap-6 max-w-2xl">
      <Card>
        <CardHeader>
          <CardTitle>Venue</CardTitle>
        </CardHeader>
        <CardContent className="grid grid-cols-2 gap-4">
          <TextField label="Park name" name="parkName" defaultValue={settings.park_name} required />
          <TextField label="Logo URL" name="logoUrl" defaultValue={settings.logo_url ?? ""} />
          <TextField label="Timezone" name="timezone" defaultValue={settings.timezone} required />
          <TextField label="Currency" name="currency" defaultValue={settings.currency} required maxLength={3} />
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Contact</CardTitle>
        </CardHeader>
        <CardContent className="grid grid-cols-2 gap-4">
          <TextField label="Contact phone" name="contactPhone" defaultValue={contactInfo.phone ?? ""} />
          <TextField label="Contact email" name="contactEmail" type="email" defaultValue={contactInfo.email ?? ""} />
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Brand colors</CardTitle>
          <CardDescription>
            Consumed by the mobile app and this dashboard at runtime — not hardcoded anywhere in the codebase.
          </CardDescription>
        </CardHeader>
        <CardContent className="grid grid-cols-2 gap-4">
          <TextField label="Primary (hex)" name="brandPrimary" defaultValue={brandColors.primary ?? ""} placeholder="#00361a" />
          <TextField label="Accent (hex)" name="brandAccent" defaultValue={brandColors.accent ?? ""} placeholder="#b80049" />
        </CardContent>
      </Card>

      {state.error && <p className="text-sm text-destructive">{state.error}</p>}
      {state.success && <p className="text-sm text-primary">Saved.</p>}

      <Button type="submit" disabled={pending} className="self-start">
        {pending ? "Saving…" : "Save changes"}
      </Button>
    </form>
  );
}
