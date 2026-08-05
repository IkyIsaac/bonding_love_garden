"use client";

import { useActionState } from "react";
import { updateVenueSettings, type FormState } from "./actions";
import { TextField } from "@/components/ui/fields";
import Button from "@/components/ui/button";
import Card from "@/components/ui/card";
import type { Database } from "@/types/database";

type VenueSettings = Database["public"]["Tables"]["venue_settings"]["Row"];

export default function SettingsForm({ settings }: { settings: VenueSettings }) {
  const contactInfo = (settings.contact_info ?? {}) as { phone?: string; email?: string };
  const brandColors = (settings.brand_colors ?? {}) as { primary?: string; accent?: string };

  const [state, formAction, pending] = useActionState<FormState, FormData>(updateVenueSettings, {});

  return (
    <form action={formAction} className="flex flex-col gap-6 max-w-2xl">
      <Card>
        <h2 className="font-heading font-bold text-on-surface mb-4">Venue</h2>
        <div className="grid grid-cols-2 gap-4">
          <TextField label="Park name" name="parkName" defaultValue={settings.park_name} required />
          <TextField label="Logo URL" name="logoUrl" defaultValue={settings.logo_url ?? ""} />
          <TextField label="Timezone" name="timezone" defaultValue={settings.timezone} required />
          <TextField label="Currency" name="currency" defaultValue={settings.currency} required maxLength={3} />
        </div>
      </Card>

      <Card>
        <h2 className="font-heading font-bold text-on-surface mb-4">Contact</h2>
        <div className="grid grid-cols-2 gap-4">
          <TextField label="Contact phone" name="contactPhone" defaultValue={contactInfo.phone ?? ""} />
          <TextField label="Contact email" name="contactEmail" type="email" defaultValue={contactInfo.email ?? ""} />
        </div>
      </Card>

      <Card>
        <h2 className="font-heading font-bold text-on-surface mb-4">Brand colors</h2>
        <p className="text-sm text-on-surface-variant mb-4">
          Consumed by the mobile app and this dashboard at runtime — not hardcoded anywhere in the codebase.
        </p>
        <div className="grid grid-cols-2 gap-4">
          <TextField label="Primary (hex)" name="brandPrimary" defaultValue={brandColors.primary ?? ""} placeholder="#00361a" />
          <TextField label="Accent (hex)" name="brandAccent" defaultValue={brandColors.accent ?? ""} placeholder="#b80049" />
        </div>
      </Card>

      {state.error && <p className="text-sm text-error">{state.error}</p>}
      {state.success && <p className="text-sm text-primary">Saved.</p>}

      <Button type="submit" disabled={pending} className="self-start">
        {pending ? "Saving…" : "Save changes"}
      </Button>
    </form>
  );
}
