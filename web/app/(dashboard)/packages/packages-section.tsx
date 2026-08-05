"use client";

import { useActionState, useEffect, useState } from "react";
import { Plus } from "lucide-react";
import { upsertPackage, deletePackage, type FormState } from "./actions";
import { Button } from "@/components/ui/button";
import { Card, CardAction, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import Badge from "@/components/ui/badge";
import Modal from "@/components/ui/modal";
import DataTable, { type Column } from "@/components/ui/data-table";
import DeleteButton from "@/components/ui/delete-button";
import { CheckboxField, TextareaField, TextField } from "@/components/ui/fields";
import type { Database } from "@/types/database";

type Package = Database["public"]["Tables"]["packages"]["Row"];
type CatalogItem = Database["public"]["Tables"]["catalog_items"]["Row"];

function toDateInputValue(iso: string | null): string {
  if (!iso) return "";
  return iso.slice(0, 10);
}

export default function PackagesSection({
  packages,
  catalogItems,
  itemsByPackageId,
}: {
  packages: Package[];
  catalogItems: CatalogItem[];
  itemsByPackageId: Record<string, Record<string, number>>;
}) {
  const [editing, setEditing] = useState<Package | "new" | null>(null);
  const [state, formAction, pending] = useActionState<FormState, FormData>(upsertPackage, {});

  useEffect(() => {
    if (state.success) setEditing(null);
  }, [state.success]);

  const selectedQuantities = editing !== null && editing !== "new" ? itemsByPackageId[editing.id] ?? {} : {};

  const columns: Column<Package>[] = [
    { header: "Name", render: (r) => <span className="font-medium">{r.name}</span> },
    { header: "Price", render: (r) => r.price },
    {
      header: "Availability",
      render: (r) =>
        r.availability_start || r.availability_end
          ? `${r.availability_start ? toDateInputValue(r.availability_start) : "…"} → ${r.availability_end ? toDateInputValue(r.availability_end) : "…"}`
          : "Always",
    },
    { header: "Status", render: (r) => <Badge tone={r.is_active ? "success" : "error"}>{r.is_active ? "Active" : "Inactive"}</Badge> },
    {
      header: "",
      className: "text-right",
      render: (r) => (
        <div className="flex gap-2 justify-end">
          <Button variant="ghost" size="sm" onClick={() => setEditing(r)}>Edit</Button>
          <DeleteButton id={r.id} action={deletePackage} />
        </div>
      ),
    },
  ];

  return (
    <Card>
      <CardHeader>
        <CardTitle>Packages</CardTitle>
        <CardAction>
          <Button onClick={() => setEditing("new")}>
            <Plus /> Add package
          </Button>
        </CardAction>
      </CardHeader>
      <CardContent>
        <DataTable columns={columns} rows={packages} emptyMessage="No packages configured yet." />
      </CardContent>

      <Modal open={editing !== null} onClose={() => setEditing(null)} title={editing === "new" ? "Add package" : "Edit package"}>
        {editing !== null && (
          <form action={formAction} className="flex flex-col gap-4">
            {editing !== "new" && <input type="hidden" name="id" value={editing.id} />}
            <TextField label="Name" name="name" defaultValue={editing !== "new" ? editing.name : ""} required />
            <TextareaField
              label="Description"
              name="description"
              defaultValue={editing !== "new" ? editing.description ?? "" : ""}
              rows={2}
            />
            <div className="grid grid-cols-2 gap-4">
              <TextField
                label="Price"
                name="price"
                type="number"
                step="0.01"
                min="0"
                defaultValue={editing !== "new" ? editing.price : ""}
                required
              />
              <TextField label="Image URL" name="imageUrl" defaultValue={editing !== "new" ? editing.image_url ?? "" : ""} />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <TextField
                label="Available from (blank = always)"
                name="availabilityStart"
                type="date"
                defaultValue={editing !== "new" ? toDateInputValue(editing.availability_start) : ""}
              />
              <TextField
                label="Available until (blank = always)"
                name="availabilityEnd"
                type="date"
                defaultValue={editing !== "new" ? toDateInputValue(editing.availability_end) : ""}
              />
            </div>

            <fieldset className="flex flex-col gap-2">
              <legend className="text-sm font-medium text-foreground mb-1">Bundled items (quantity 0 = not included)</legend>
              <div className="grid grid-cols-2 gap-3 max-h-48 overflow-y-auto border border-border rounded-lg p-3">
                {catalogItems.length === 0 && (
                  <p className="text-sm text-muted-foreground col-span-2">Add games/services first.</p>
                )}
                {catalogItems.map((item) => (
                  <label key={item.id} className="flex items-center justify-between gap-2 text-sm text-foreground">
                    <span>{item.name}</span>
                    <Input
                      type="number"
                      name={`quantity__${item.id}`}
                      min={0}
                      defaultValue={selectedQuantities[item.id] ?? 0}
                      className="w-16 text-right"
                    />
                  </label>
                ))}
              </div>
            </fieldset>

            <CheckboxField label="Active" name="isActive" defaultChecked={editing !== "new" ? editing.is_active : true} />
            {state.error && <p className="text-sm text-destructive">{state.error}</p>}
            <div className="flex justify-end gap-2">
              <Button type="button" variant="secondary" onClick={() => setEditing(null)}>Cancel</Button>
              <Button type="submit" disabled={pending}>{pending ? "Saving…" : "Save"}</Button>
            </div>
          </form>
        )}
      </Modal>
    </Card>
  );
}
