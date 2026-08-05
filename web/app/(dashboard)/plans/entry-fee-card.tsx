"use client";

import { useActionState, useEffect, useState } from "react";
import { setEntryFee, type FormState } from "./actions";
import Button from "@/components/ui/button";
import Card from "@/components/ui/card";
import { TextField } from "@/components/ui/fields";

export default function EntryFeeCard({ currentAmount }: { currentAmount: number | null }) {
  const [open, setOpen] = useState(false);
  const [state, formAction, pending] = useActionState<FormState, FormData>(setEntryFee, {});

  useEffect(() => {
    if (state.success) setOpen(false);
  }, [state.success]);

  return (
    <Card>
      <div className="flex items-center justify-between">
        <div>
          <h2 className="font-heading font-bold text-on-surface">Entry Fee</h2>
          <p className="text-sm text-on-surface-variant mt-1">
            {currentAmount !== null ? `Current: ${currentAmount}` : "Not yet configured"}
          </p>
        </div>
        <Button variant="secondary" onClick={() => setOpen((v) => !v)}>
          {open ? "Cancel" : "Set new fee"}
        </Button>
      </div>
      {open && (
        <form action={formAction} className="flex items-end gap-3 mt-4">
          <TextField label="New amount" name="amount" type="number" step="0.01" min="0" required />
          <Button type="submit" disabled={pending}>{pending ? "Saving…" : "Save"}</Button>
        </form>
      )}
      {state.error && <p className="text-sm text-error mt-2">{state.error}</p>}
      <p className="text-xs text-on-surface-variant mt-3">
        Setting a new fee doesn&apos;t overwrite history — past orders keep the fee that applied when they were placed.
      </p>
    </Card>
  );
}
