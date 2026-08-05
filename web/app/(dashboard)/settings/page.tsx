import { createClient } from "@/lib/supabase/server";
import SettingsForm from "./settings-form";

export default async function SettingsPage() {
  const supabase = await createClient();
  const { data: settings, error } = await supabase.from("venue_settings").select("*").single();

  if (error || !settings) {
    return <p className="text-destructive">Failed to load venue settings: {error?.message}</p>;
  }

  return (
    <div>
      <h1 className="font-heading text-2xl font-bold text-foreground mb-1">Settings</h1>
      <p className="text-sm text-muted-foreground mb-6">Venue branding and configuration.</p>
      <SettingsForm settings={settings} />
    </div>
  );
}
