import type { InputHTMLAttributes, ReactNode, SelectHTMLAttributes, TextareaHTMLAttributes } from "react";

const inputClasses =
  "rounded-lg border border-outline-variant px-3 py-2 font-normal focus:border-primary focus:outline-none disabled:bg-surface-container disabled:text-on-surface-variant";

export function TextField({
  label,
  ...props
}: { label: string } & InputHTMLAttributes<HTMLInputElement>) {
  return (
    <label className="flex flex-col gap-1 text-sm font-medium text-on-surface">
      {label}
      <input className={inputClasses} {...props} />
    </label>
  );
}

export function TextareaField({
  label,
  ...props
}: { label: string } & TextareaHTMLAttributes<HTMLTextAreaElement>) {
  return (
    <label className="flex flex-col gap-1 text-sm font-medium text-on-surface">
      {label}
      <textarea className={inputClasses} {...props} />
    </label>
  );
}

export function SelectField({
  label,
  children,
  ...props
}: { label: string; children: ReactNode } & SelectHTMLAttributes<HTMLSelectElement>) {
  return (
    <label className="flex flex-col gap-1 text-sm font-medium text-on-surface">
      {label}
      <select className={inputClasses} {...props}>
        {children}
      </select>
    </label>
  );
}

export function CheckboxField({
  label,
  ...props
}: { label: string } & InputHTMLAttributes<HTMLInputElement>) {
  return (
    <label className="flex items-center gap-2 text-sm font-medium text-on-surface">
      <input type="checkbox" className="rounded border-outline-variant text-primary focus:ring-primary" {...props} />
      {label}
    </label>
  );
}
