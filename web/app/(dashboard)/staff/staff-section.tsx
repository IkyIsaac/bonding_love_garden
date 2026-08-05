"use client";

import { useActionState, useEffect, useState } from "react";
import { createStaff, updateStaff, type FormState } from "./actions";
import Button from "@/components/ui/button";
import Card from "@/components/ui/card";
import Badge from "@/components/ui/badge";
import Modal from "@/components/ui/modal";
import DataTable, { type Column } from "@/components/ui/data-table";
import { SelectField, TextField } from "@/components/ui/fields";

// Narrower than the full profiles Row type — matches exactly what the page's query selects.
interface Staff {
  id: string;
  phone: string;
  full_name: string;
  role: string;
  approval_status: string;
  created_at: string;
}

const ROLE_TONE: Record<string, "neutral" | "success" | "warning" | "error"> = {
  admin: "warning",
  supervisor: "success",
  attendant: "neutral",
  cashier: "neutral",
};

const STATUS_TONE: Record<string, "neutral" | "success" | "warning" | "error"> = {
  approved: "success",
  pending: "warning",
  suspended: "error",
  rejected: "error",
};

function AddStaffModal({ open, onClose }: { open: boolean; onClose: () => void }) {
  const [state, formAction, pending] = useActionState<FormState, FormData>(createStaff, {});

  useEffect(() => {
    if (state.success) onClose();
  }, [state.success, onClose]);

  return (
    <Modal open={open} onClose={onClose} title="Add staff member">
      <form action={formAction} className="flex flex-col gap-4">
        <TextField label="Full name" name="fullName" required />
        <TextField label="Phone (E.164)" name="phone" placeholder="+255700000000" required />
        <SelectField label="Role" name="role" defaultValue="cashier">
          <option value="cashier">Cashier</option>
          <option value="attendant">Attendant</option>
          <option value="supervisor">Supervisor</option>
          <option value="admin">Admin</option>
        </SelectField>
        <p className="text-xs text-on-surface-variant">
          No password needed — staff sign in with phone + a one-time code, same as customers.
        </p>
        {state.error && <p className="text-sm text-error">{state.error}</p>}
        <div className="flex justify-end gap-2">
          <Button type="button" variant="secondary" onClick={onClose}>Cancel</Button>
          <Button type="submit" disabled={pending}>{pending ? "Creating…" : "Create account"}</Button>
        </div>
      </form>
    </Modal>
  );
}

function EditStaffModal({ staff, onClose }: { staff: Staff | null; onClose: () => void }) {
  const [state, formAction, pending] = useActionState<FormState, FormData>(updateStaff, {});

  useEffect(() => {
    if (state.success) onClose();
  }, [state.success, onClose]);

  return (
    <Modal open={staff !== null} onClose={onClose} title="Edit staff member">
      {staff && (
        <form action={formAction} className="flex flex-col gap-4">
          <input type="hidden" name="id" value={staff.id} />
          <TextField label="Name" defaultValue={staff.full_name} disabled />
          <TextField label="Phone" defaultValue={staff.phone} disabled />
          <SelectField label="Role" name="role" defaultValue={staff.role}>
            <option value="cashier">Cashier</option>
            <option value="attendant">Attendant</option>
            <option value="supervisor">Supervisor</option>
            <option value="admin">Admin</option>
          </SelectField>
          <SelectField label="Approval status" name="approvalStatus" defaultValue={staff.approval_status}>
            <option value="pending">Pending</option>
            <option value="approved">Approved</option>
            <option value="suspended">Suspended</option>
            <option value="rejected">Rejected</option>
          </SelectField>
          {state.error && <p className="text-sm text-error">{state.error}</p>}
          <div className="flex justify-end gap-2">
            <Button type="button" variant="secondary" onClick={onClose}>Cancel</Button>
            <Button type="submit" disabled={pending}>{pending ? "Saving…" : "Save"}</Button>
          </div>
        </form>
      )}
    </Modal>
  );
}

export default function StaffSection({ staff }: { staff: Staff[] }) {
  const [adding, setAdding] = useState(false);
  const [editing, setEditing] = useState<Staff | null>(null);

  const columns: Column<Staff>[] = [
    { header: "Name", render: (r) => <span className="font-medium">{r.full_name || "—"}</span> },
    { header: "Phone", render: (r) => r.phone },
    { header: "Role", render: (r) => <Badge tone={ROLE_TONE[r.role]}>{r.role}</Badge> },
    { header: "Status", render: (r) => <Badge tone={STATUS_TONE[r.approval_status]}>{r.approval_status}</Badge> },
    {
      header: "",
      className: "text-right",
      render: (r) => (
        <Button variant="ghost" onClick={() => setEditing(r)}>Edit</Button>
      ),
    },
  ];

  return (
    <Card>
      <div className="flex items-center justify-between mb-4">
        <h2 className="font-heading font-bold text-on-surface">Staff</h2>
        <Button onClick={() => setAdding(true)}>Add staff</Button>
      </div>
      <DataTable columns={columns} rows={staff} emptyMessage="No staff accounts yet." />

      <AddStaffModal open={adding} onClose={() => setAdding(false)} />
      <EditStaffModal staff={editing} onClose={() => setEditing(null)} />
    </Card>
  );
}
