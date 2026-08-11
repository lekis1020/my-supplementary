import { cn } from "@/lib/utils";

type CardTone = "surface" | "highlight";
type CardPadding = "none" | "sm" | "md";

const TONE_CLASSES: Record<CardTone, string> = {
  surface: "border border-stone-200 bg-surface shadow-card",
  highlight: "border border-orange-100 bg-gradient-to-br from-brand-bg to-surface shadow-card",
};

const PADDING_CLASSES: Record<CardPadding, string> = {
  none: "",
  sm: "p-4",
  md: "p-6",
};

interface CardProps {
  children: React.ReactNode;
  className?: string;
}

export function Card({
  children,
  className,
  tone = "surface",
  padding = "md",
}: CardProps & { tone?: CardTone; padding?: CardPadding }) {
  return (
    <div className={cn("rounded-2xl", TONE_CLASSES[tone], PADDING_CLASSES[padding], className)}>
      {children}
    </div>
  );
}

export function CardHeader({ children, className }: CardProps) {
  return <div className={cn("mb-4", className)}>{children}</div>;
}

export function CardTitle({ children, className }: CardProps) {
  return (
    <h3 className={cn("text-lg font-semibold text-ink", className)}>{children}</h3>
  );
}

export function CardContent({ children, className }: CardProps) {
  return <div className={cn(className)}>{children}</div>;
}
