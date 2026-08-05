type Tone = "neutral" | "success" | "warning" | "error";

const TONE_CLASSES: Record<Tone, string> = {
  neutral: "bg-surface-container text-on-surface-variant",
  success: "bg-primary-container text-on-primary-container",
  warning: "bg-tertiary-container text-on-tertiary-container",
  error: "bg-error-container text-on-error-container",
};

export default function Badge({
  children,
  tone = "neutral",
}: {
  children: React.ReactNode;
  tone?: Tone;
}) {
  return (
    <span className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${TONE_CLASSES[tone]}`}>
      {children}
    </span>
  );
}
