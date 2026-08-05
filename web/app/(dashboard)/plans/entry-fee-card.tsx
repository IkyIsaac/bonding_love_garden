"use client";

import { useActionState, useEffect, useState } from "react";
import { setEntryFee, type FormState } from "./actions";
import { Button } from "@/components/ui/button";
import { Card, CardAction, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { TextField } from "@/components/ui/fields";

export default function EntryFeeCard({ currentAmount }: { currentAmount: number | null }) {
  const [open, setOpen] = useState(false);
  const [state, formAction, pending] = useActionState<FormState, FormData>(setEntryFee, {});

  useEffect(() => {
    if (state.success) setOpen(false);
  }, [state.success]);

  return (
    <Card>
      <CardHeader>
        <CardTitle>Entry Fee</CardTitle>
        <CardDescription>
          {currentAmount !== null ? `Current: ${currentAmount}` : "Not yet configured"}
        </CardDescription>
        <CardAction>
          <Button variant="secondary" onClick={() => setOpen((v) => !v)}>
            {open ? "Cancel" : "Set new fee"}
          </Button>
        </CardAction>
      </CardHeader>
      <CardContent>
        {open && (
          <form action={formAction} className="flex items-end gap-3">
            <TextField label="New amount" name="amount" type="number" step="0.01" min="0" required />
            <Button type="submit" disabled={pending}>{pending ? "Saving…" : "Save"}</Button>
          </form>
        )}
        {state.error && <p className="text-sm text-destructive mt-2">{state.error}</p>}
        <p className="text-xs text-muted-foreground mt-3">
          Setting a new fee doesn&apos;t overwrite history — past orders keep the fee that applied when they were placed.
        </p>
      </CardContent>
    </Card>
  );
}
