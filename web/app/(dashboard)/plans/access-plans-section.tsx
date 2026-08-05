"use client";

import { useActionState, useEffect, useState } from "react";
import { upsertAccessPlan, deleteAccessPlan, type FormState } from "./actions";
import Button from "@/components/ui/button";
import Card from "@/components/ui/card";
import Badge from "@/components/ui/badge";
import Modal from "@/components/ui/modal";
import DataTable, { type Column } from "@/components/ui/data-table";
import DeleteButton from "@/components/ui/delete-button";
import { CheckboxField, SelectField, TextField } from "@/components/ui/fields";
import type { Database } from "@/types/database";

type AccessPlan = Database["public"]["Tables"]["access_plans"]["Row"];
type CatalogItem = Database["public"]["Tables"]["catalog_items"]["Row"];

export default function AccessPlansSection({
  plans,
  catalogItems,
  planItemsByPlanId,
}: {
  plans: AccessPlan[];
  catalogItems: CatalogItem[];
  planItemsByPlanId: Record<string, string[]>;
}) {
  const [editing, setEditing] = useState<AccessPlan | "new" | null>(null);
  const [state, formAction, pending] = useActionState<FormState, FormData>(upsertAccessPlan, {});

  useEffect(() => {
    if (state.success) setEditing(null);
  }, [state.success]);

  const selectedItemIds = editing !== null && editing !== "new" ? planItemsByPlanId[editing.id] ?? [] : [];

  const columns: Column<AccessPlan>[] = [
    { header: "Name", render: (r) => <span className="font-medium">{r.name}</span> },
    {
      header: "Type",
      render: (r) => (
        <Badge tone={r.plan_type === "membership" ? "warning" : "neutral"}>{r.plan_type.replace("_", " ")}</Badge>
      ),
    },
    { header: "Price", render: (r) => r.price },
    { header: "Validity", render: (r) => `${r.validity_value} ${r.validity_unit}` },
    { header: "Visits", render: (r) => r.visit_limit ?? "Unlimited" },
    { header: "Status", render: (r) => <Badge tone={r.is_active ? "success" : "error"}>{r.is_active ? "Active" : "Inactive"}</Badge> },
    {
      header: "",
      className: "text-right",
      render: (r) => (
        <div className="flex gap-2 justify-end">
          <Button variant="ghost" onClick={() => setEditing(r)}>Edit</Button>
          <DeleteButton id={r.id} action={deleteAccessPlan} />
        </div>
      ),
    },
  ];

  return (
    <Card>
      <div className="flex items-center justify-between mb-4">
        <h2 className="font-heading font-bold text-on-surface">Access Plans</h2>
        <Button onClick={() => setEditing("new")}>Add plan</Button>
      </div>
      <DataTable columns={columns} rows={plans} emptyMessage="No access plans configured yet." />

      <Modal open={editing !== null} onClose={() => setEditing(null)} title={editing === "new" ? "Add plan" : "Edit plan"}>
        {editing !== null && (
          <form action={formAction} className="flex flex-col gap-4">
            {editing !== "new" && <input type="hidden" name="id" value={editing.id} />}
            <TextField label="Name" name="name" defaultValue={editing !== "new" ? editing.name : ""} required />
            <div className="grid grid-cols-2 gap-4">
              <SelectField label="Plan type" name="planType" defaultValue={editing !== "new" ? editing.plan_type : "single_visit"}>
                <option value="single_visit">Single Visit</option>
                <option value="membership">Membership</option>
              </SelectField>
              <TextField
                label="Price"
                name="price"
                type="number"
                step="0.01"
                min="0"
                defaultValue={editing !== "new" ? editing.price : ""}
                required
              />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <TextField
                label="Validity value"
                name="validityValue"
                type="number"
                min="1"
                defaultValue={editing !== "new" ? editing.validity_value : ""}
                required
              />
              <SelectField label="Validity unit" name="validityUnit" defaultValue={editing !== "new" ? editing.validity_unit : "days"}>
                <option value="minutes">Minutes</option>
                <option value="hours">Hours</option>
                <option value="days">Days</option>
                <option value="weeks">Weeks</option>
                <option value="months">Months</option>
                <option value="years">Years</option>
              </SelectField>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <TextField
                label="Visit limit (blank = unlimited)"
                name="visitLimit"
                type="number"
                min="1"
                defaultValue={editing !== "new" ? editing.visit_limit ?? "" : ""}
              />
              <TextField
                label="Daily time limit, minutes (blank = none)"
                name="dailyTimeLimit"
                type="number"
                min="1"
                defaultValue={editing !== "new" ? editing.daily_time_limit_minutes ?? "" : ""}
              />
            </div>

            <fieldset className="flex flex-col gap-2">
              <legend className="text-sm font-medium text-on-surface mb-1">Included games/services</legend>
              <div className="grid grid-cols-2 gap-2 max-h-40 overflow-y-auto border border-outline-variant rounded-lg p-3">
                {catalogItems.length === 0 && (
                  <p className="text-sm text-on-surface-variant col-span-2">Add games/services first.</p>
                )}
                {catalogItems.map((item) => (
                  <CheckboxField
                    key={item.id}
                    label={item.name}
                    name="catalogItemIds"
                    value={item.id}
                    defaultChecked={selectedItemIds.includes(item.id)}
                  />
                ))}
              </div>
            </fieldset>

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
