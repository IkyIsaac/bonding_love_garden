import { Badge as ReuiBadge } from "@/components/reui/badge";

type Tone = "neutral" | "success" | "warning" | "error";

const TONE_VARIANT: Record<Tone, "secondary" | "success-light" | "warning-light" | "destructive-light"> = {
  neutral: "secondary",
  success: "success-light",
  warning: "warning-light",
  error: "destructive-light",
};

export default function Badge({
  children,
  tone = "neutral",
}: {
  children: React.ReactNode;
  tone?: Tone;
}) {
  return (
    <ReuiBadge variant={TONE_VARIANT[tone]} radius="full" size="lg">
      {children}
    </ReuiBadge>
  );
}
