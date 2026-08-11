import { Card } from "@/components/ui/card";
import { cn } from "@/lib/utils";

type SummaryTone = "brand" | "amber" | "neutral" | "muted";

const TONE_CLASSES: Record<SummaryTone, string> = {
  brand: "border-orange-200 bg-brand-bg text-orange-700",
  amber: "border-amber-200 bg-amber-50 text-amber-800",
  neutral: "border-stone-300 bg-stone-100 text-ink",
  muted: "border-stone-200 bg-stone-50 text-ink-muted",
};

export function SummaryCard({
  label,
  value,
  description,
  tone,
}: {
  label: string;
  value: number;
  description: string;
  tone: SummaryTone;
}) {
  const toneClassName = TONE_CLASSES[tone] ?? TONE_CLASSES.muted;

  return (
    <Card className="p-5">
      <div className={cn("inline-flex rounded-full border px-3 py-1 text-xs font-semibold", toneClassName)}>
        {label}
      </div>
      <div className="mt-4 text-3xl font-black tracking-tight text-ink">
        {value.toLocaleString()}
      </div>
      <p className="mt-2 text-sm leading-6 text-ink-muted">{description}</p>
    </Card>
  );
}
