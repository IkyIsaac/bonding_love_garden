"use client";

import { useTransition } from "react";
import Button from "./button";

export default function DeleteButton({
  id,
  action,
  label = "Delete",
  confirmMessage = "Are you sure? This cannot be undone.",
}: {
  id: string;
  action: (id: string) => Promise<{ error?: string; success?: boolean }>;
  label?: string;
  confirmMessage?: string;
}) {
  const [pending, startTransition] = useTransition();

  function handleClick() {
    if (!confirm(confirmMessage)) return;
    startTransition(async () => {
      const result = await action(id);
      if (result.error) alert(result.error);
    });
  }

  return (
    <Button variant="ghost" onClick={handleClick} disabled={pending} className="text-error hover:bg-error-container">
      {pending ? "Deleting…" : label}
    </Button>
  );
}
