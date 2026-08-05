"use client";

import { useTransition } from "react";
import { extendSession, endSession } from "./actions";
import Button from "@/components/ui/button";

export default function SessionActions({ id, ended }: { id: string; ended: boolean }) {
  const [pending, startTransition] = useTransition();

  function handleExtend() {
    startTransition(async () => {
      const result = await extendSession(id, 15);
      if (result.error) alert(result.error);
    });
  }

  function handleEnd() {
    if (!confirm("End this session now?")) return;
    startTransition(async () => {
      const result = await endSession(id);
      if (result.error) alert(result.error);
    });
  }

  if (ended) return null;

  return (
    <div className="flex gap-2 justify-end">
      <Button variant="secondary" onClick={handleExtend} disabled={pending}>+15 min</Button>
      <Button variant="ghost" onClick={handleEnd} disabled={pending} className="text-error hover:bg-error-container">
        End
      </Button>
    </div>
  );
}
