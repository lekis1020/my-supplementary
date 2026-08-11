import { Card } from "@/components/ui/card";
import { cn } from "@/lib/utils";

// tone keys are kept stable (not renamed) since callers pass these string
// literals; only the underlying colors move to the warm-commerce token set.
const TONE_CLASSES: Record<"emerald" | "amber" | "blue" | "slate", string> = {
  emerald: "border-orange-200 bg-brand-bg text-orange-700",
  amber: "border-amber-200 bg-amber-50 text-amber-800",
  blue: "border-stone-300 bg-stone-100 text-ink",
  slate: "border-stone-200 bg-stone-50 text-ink-muted",
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
  tone: "emerald" | "amber" | "blue" | "slate";
}) {
  const toneClassName = TONE_CLASSES[tone] ?? TONE_CLASSES.slate;

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
