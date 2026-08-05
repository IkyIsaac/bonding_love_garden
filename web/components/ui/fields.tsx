import { Children, isValidElement, type ReactElement, type ReactNode } from "react";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Checkbox } from "@/components/ui/checkbox";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import type { ComponentProps } from "react";

export function TextField({
  label,
  id,
  name,
  className,
  ...props
}: { label: string } & ComponentProps<typeof Input>) {
  const fieldId = id ?? name;
  return (
    <div className="flex flex-col gap-1.5">
      <Label htmlFor={fieldId}>{label}</Label>
      <Input id={fieldId} name={name} className={className} {...props} />
    </div>
  );
}

export function TextareaField({
  label,
  id,
  name,
  className,
  ...props
}: { label: string } & ComponentProps<typeof Textarea>) {
  const fieldId = id ?? name;
  return (
    <div className="flex flex-col gap-1.5">
      <Label htmlFor={fieldId}>{label}</Label>
      <Textarea id={fieldId} name={name} className={className} {...props} />
    </div>
  );
}

/**
 * Accepts plain <option value="..."> children (never rendered as DOM — just
 * read for {value, label}) so every existing call site stays untouched while
 * the actual control underneath is Base UI's Select, not a native <select>.
 */
export function SelectField({
  label,
  name,
  defaultValue,
  disabled,
  required,
  children,
}: {
  label: string;
  name?: string;
  defaultValue?: string;
  disabled?: boolean;
  required?: boolean;
  children: ReactNode;
}) {
  const options = Children.toArray(children).filter(isValidElement) as ReactElement<{
    value?: string;
    children?: ReactNode;
  }>[];
  return (
    <div className="flex flex-col gap-1.5">
      <Label>{label}</Label>
      <Select name={name} defaultValue={defaultValue} disabled={disabled} required={required}>
        <SelectTrigger className="w-full">
          <SelectValue placeholder={label} />
        </SelectTrigger>
        <SelectContent>
          {options.map((opt) => (
            <SelectItem key={String(opt.props.value)} value={String(opt.props.value)}>
              {opt.props.children}
            </SelectItem>
          ))}
        </SelectContent>
      </Select>
    </div>
  );
}

export function CheckboxField({
  label,
  ...props
}: { label: string } & ComponentProps<typeof Checkbox>) {
  return (
    <Label className="font-normal">
      <Checkbox {...props} />
      {label}
    </Label>
  );
}
