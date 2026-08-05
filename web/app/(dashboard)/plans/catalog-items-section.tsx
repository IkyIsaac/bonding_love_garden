"use client";

import { useActionState, useEffect, useState } from "react";
import { upsertCatalogItem, deleteCatalogItem, type FormState } from "./actions";
import Button from "@/components/ui/button";
import Card from "@/components/ui/card";
import Badge from "@/components/ui/badge";
import Modal from "@/components/ui/modal";
import DataTable, { type Column } from "@/components/ui/data-table";
import DeleteButton from "@/components/ui/delete-button";
import { CheckboxField, SelectField, TextareaField, TextField } from "@/components/ui/fields";
import type { Database } from "@/types/database";

type CatalogItem = Database["public"]["Tables"]["catalog_items"]["Row"];

export default function CatalogItemsSection({ items }: { items: CatalogItem[] }) {
  const [editing, setEditing] = useState<CatalogItem | "new" | null>(null);
  const [state, formAction, pending] = useActionState<FormState, FormData>(upsertCatalogItem, {});

  useEffect(() => {
    if (state.success) setEditing(null);
  }, [state.success]);

  const columns: Column<CatalogItem>[] = [
    { header: "Name", render: (r) => <span className="font-medium">{r.name}</span> },
    {
      header: "Type",
      render: (r) => (
        <Badge tone={r.type === "game" ? "success" : "neutral"}>
          {r.type}
          {r.is_motorized ? " · motorized" : ""}
        </Badge>
      ),
    },
    { header: "Price", render: (r) => `${r.price} (${r.pricing_unit})` },
    { header: "Status", render: (r) => <Badge tone={r.is_active ? "success" : "error"}>{r.is_active ? "Active" : "Inactive"}</Badge> },
    {
      header: "",
      className: "text-right",
      render: (r) => (
        <div className="flex gap-2 justify-end">
          <Button variant="ghost" onClick={() => setEditing(r)}>Edit</Button>
          <DeleteButton id={r.id} action={deleteCatalogItem} />
        </div>
      ),
    },
  ];

  return (
    <Card>
      <div className="flex items-center justify-between mb-4">
        <h2 className="font-heading font-bold text-on-surface">Games &amp; Services</h2>
        <Button onClick={() => setEditing("new")}>Add item</Button>
      </div>
      <DataTable columns={columns} rows={items} emptyMessage="No games or services configured yet." />

      <Modal open={editing !== null} onClose={() => setEditing(null)} title={editing === "new" ? "Add item" : "Edit item"}>
        {editing !== null && (
          <form action={formAction} className="flex flex-col gap-4">
            {editing !== "new" && <input type="hidden" name="id" value={editing.id} />}
            <TextField label="Name" name="name" defaultValue={editing !== "new" ? editing.name : ""} required />
            <SelectField label="Type" name="type" defaultValue={editing !== "new" ? editing.type : "game"}>
              <option value="game">Game</option>
              <option value="service">Service</option>
            </SelectField>
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
              <SelectField label="Pricing unit" name="pricingUnit" defaultValue={editing !== "new" ? editing.pricing_unit : "flat"}>
                <option value="flat">Flat</option>
                <option value="hourly">Hourly</option>
              </SelectField>
            </div>
            <CheckboxField
              label="Motorized (games only)"
              name="isMotorized"
              defaultChecked={editing !== "new" ? !!editing.is_motorized : false}
            />
            <CheckboxField label="Active" name="isActive" defaultChecked={editing !== "new" ? editing.is_active : true} />
            {state.error && <p className="text-sm text-error">{state.error}</p>}
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
