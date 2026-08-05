"use client";

import { useActionState, useEffect, useState } from "react";
import { Plus } from "lucide-react";
import { upsertDiscountRule, deleteDiscountRule, type FormState } from "./actions";
import { Button } from "@/components/ui/button";
import { Card, CardAction, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import Badge from "@/components/ui/badge";
import Modal from "@/components/ui/modal";
import DataTable, { type Column } from "@/components/ui/data-table";
import DeleteButton from "@/components/ui/delete-button";
import { CheckboxField, SelectField, TextareaField, TextField } from "@/components/ui/fields";
import type { Database } from "@/types/database";

type DiscountRule = Database["public"]["Tables"]["discount_rules"]["Row"];
type CatalogItem = Database["public"]["Tables"]["catalog_items"]["Row"];

const DAYS = [
  { value: 0, label: "Sun" },
  { value: 1, label: "Mon" },
  { value: 2, label: "Tue" },
  { value: 3, label: "Wed" },
  { value: 4, label: "Thu" },
  { value: 5, label: "Fri" },
  { value: 6, label: "Sat" },
];

const STATUS_TONE: Record<string, "neutral" | "success" | "warning" | "error"> = {
  draft: "neutral",
  enabled: "success",
  disabled: "warning",
  archived: "error",
};

function toDateInputValue(iso: string | null): string {
  if (!iso) return "";
  return iso.slice(0, 10);
}

export default function DiscountRulesSection({
  rules,
  catalogItems,
  componentsByRuleId,
}: {
  rules: DiscountRule[];
  catalogItems: CatalogItem[];
  componentsByRuleId: Record<string, string[]>;
}) {
  const [editing, setEditing] = useState<DiscountRule | "new" | null>(null);
  const [state, formAction, pending] = useActionState<FormState, FormData>(upsertDiscountRule, {});

  useEffect(() => {
    if (state.success) setEditing(null);
  }, [state.success]);

  const selectedComponents = editing !== null && editing !== "new" ? componentsByRuleId[editing.id] ?? [] : [];
  const selectedDays = editing !== null && editing !== "new" ? editing.days_of_week ?? [] : [];

  const columns: Column<DiscountRule>[] = [
    { header: "Name", render: (r) => <span className="font-medium">{r.name}</span> },
    { header: "Discount", render: (r) => (r.discount_type === "percent" ? `${r.discount_value}%` : r.discount_value) },
    { header: "Min qty", render: (r) => r.min_quantity ?? "—" },
    { header: "Status", render: (r) => <Badge tone={STATUS_TONE[r.status]}>{r.status}</Badge> },
    {
      header: "",
      className: "text-right",
      render: (r) => (
        <div className="flex gap-2 justify-end">
          <Button variant="ghost" size="sm" onClick={() => setEditing(r)}>Edit</Button>
          <DeleteButton id={r.id} action={deleteDiscountRule} />
        </div>
      ),
    },
  ];

  return (
    <Card>
      <CardHeader>
        <CardTitle>Rules</CardTitle>
        <CardAction>
          <Button onClick={() => setEditing("new")}>
            <Plus /> Add rule
          </Button>
        </CardAction>
      </CardHeader>
      <CardContent>
        <DataTable columns={columns} rows={rules} emptyMessage="No discount rules configured yet." />
      </CardContent>

      <Modal open={editing !== null} onClose={() => setEditing(null)} title={editing === "new" ? "Add rule" : "Edit rule"}>
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
              <SelectField label="Discount type" name="discountType" defaultValue={editing !== "new" ? editing.discount_type : "percent"}>
                <option value="percent">Percent</option>
                <option value="flat">Flat amount</option>
              </SelectField>
              <TextField
                label="Discount value"
                name="discountValue"
                type="number"
                step="0.01"
                min="0"
                defaultValue={editing !== "new" ? editing.discount_value : ""}
                required
              />
            </div>

            <TextField
              label="Min quantity (blank = any)"
              name="minQuantity"
              type="number"
              min="1"
              defaultValue={editing !== "new" ? editing.min_quantity ?? "" : ""}
            />

            <div className="grid grid-cols-2 gap-4">
              <TextField
                label="Valid from (blank = always)"
                name="validFrom"
                type="date"
                defaultValue={editing !== "new" ? toDateInputValue(editing.valid_from) : ""}
              />
              <TextField
                label="Valid to (blank = always)"
                name="validTo"
                type="date"
                defaultValue={editing !== "new" ? toDateInputValue(editing.valid_to) : ""}
              />
            </div>

            <fieldset className="flex flex-col gap-2">
              <legend className="text-sm font-medium text-foreground mb-1">Days of week (blank = every day)</legend>
              <div className="flex flex-wrap gap-3">
                {DAYS.map((day) => (
                  <CheckboxField
                    key={day.value}
                    label={day.label}
                    name="daysOfWeek"
                    value={String(day.value)}
                    defaultChecked={selectedDays.includes(day.value)}
                  />
                ))}
              </div>
            </fieldset>

            <fieldset className="flex flex-col gap-2">
              <legend className="text-sm font-medium text-foreground mb-1">
                Qualifying components (cart must include all of these)
              </legend>
              <div className="grid grid-cols-2 gap-2 max-h-40 overflow-y-auto border border-border rounded-lg p-3">
                <CheckboxField
                  label="Entry Fee"
                  name="components"
                  value="entry_fee"
                  defaultChecked={selectedComponents.includes("entry_fee")}
                />
                {catalogItems.map((item) => (
                  <CheckboxField
                    key={item.id}
                    label={item.name}
                    name="components"
                    value={item.id}
                    defaultChecked={selectedComponents.includes(item.id)}
                  />
                ))}
              </div>
            </fieldset>

            <SelectField label="Status" name="status" defaultValue={editing !== "new" ? editing.status : "draft"}>
              <option value="draft">Draft</option>
              <option value="enabled">Enabled</option>
              <option value="disabled">Disabled</option>
              <option value="archived">Archived</option>
            </SelectField>

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
