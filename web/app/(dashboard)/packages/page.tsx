import { createClient } from "@/lib/supabase/server";
import PackagesSection from "./packages-section";

export default async function PackagesPage() {
  const supabase = await createClient();

  const [{ data: packages }, { data: catalogItems }, { data: packageItems }] = await Promise.all([
    supabase.from("packages").select("*").order("name"),
    supabase.from("catalog_items").select("*").eq("is_active", true).order("name"),
    supabase.from("package_items").select("package_id, catalog_item_id, quantity"),
  ]);

  const itemsByPackageId: Record<string, Record<string, number>> = {};
  for (const row of packageItems ?? []) {
    (itemsByPackageId[row.package_id] ??= {})[row.catalog_item_id] = row.quantity;
  }

  return (
    <div>
      <h1 className="font-heading text-2xl font-bold text-on-surface mb-1">Packages</h1>
      <p className="text-sm text-on-surface-variant mb-6">Named bundles sold at a fixed price, optionally time-limited.</p>
      <PackagesSection packages={packages ?? []} catalogItems={catalogItems ?? []} itemsByPackageId={itemsByPackageId} />
    </div>
  );
}
