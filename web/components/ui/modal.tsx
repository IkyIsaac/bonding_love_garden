"use client";

import { useEffect, useRef } from "react";

export default function Modal({
  open,
  onClose,
  title,
  children,
}: {
  open: boolean;
  onClose: () => void;
  title: string;
  children: React.ReactNode;
}) {
  const ref = useRef<HTMLDialogElement>(null);

  useEffect(() => {
    const dialog = ref.current;
    if (!dialog) return;
    if (open && !dialog.open) dialog.showModal();
    if (!open && dialog.open) dialog.close();
  }, [open]);

  return (
    <dialog
      ref={ref}
      onClose={onClose}
      onCancel={onClose}
      className="rounded-xl p-0 backdrop:bg-on-surface/40 w-full max-w-lg m-auto"
    >
      <div className="p-6">
        <div className="flex items-center justify-between mb-4">
          <h2 className="font-heading text-lg font-bold text-on-surface">{title}</h2>
          <button
            onClick={onClose}
            className="text-on-surface-variant hover:text-on-surface"
            aria-label="Close"
            type="button"
          >
            ✕
          </button>
        </div>
        {children}
      </div>
    </dialog>
  );
}
