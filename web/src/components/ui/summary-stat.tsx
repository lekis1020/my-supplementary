import { cn } from "@/lib/utils";

type StatAccent = "brand" | "regulatory" | "danger";

const ACCENT_CLASSES: Record<StatAccent, string> = {
  brand: "text-orange-600",
  regulatory: "text-regulatory",
  danger: "text-danger",
};

export function SummaryStat({
  value,
  label,
  accent = "brand",
  className,
}: {
  value: React.ReactNode;
  label: string;
  accent?: StatAccent;
  className?: string;
}) {
  return (
    <div
      className={cn(
        "rounded-xl bg-surface px-3 py-2.5 text-center shadow-card",
        className
      )}
    >
      <div className={cn("text-xl font-extrabold leading-tight", ACCENT_CLASSES[accent])}>
        {value}
      </div>
      <div className="mt-0.5 text-xs text-ink-muted">{label}</div>
    </div>
  );
}
