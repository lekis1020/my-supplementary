import { cn } from "@/lib/utils";

export type BadgeVariant = "neutral" | "tag" | "promo" | "outline";

const VARIANT_CLASSES: Record<BadgeVariant, string> = {
  neutral: "bg-stone-100 text-stone-600",
  tag: "bg-stone-100 text-stone-600",
  promo: "bg-brand-bg text-orange-700",
  outline: "border border-stone-200 text-ink-muted",
};

export function badgeVariantClasses(variant?: BadgeVariant): string {
  return variant ? VARIANT_CLASSES[variant] : "";
}

interface BadgeProps {
  children: React.ReactNode;
  className?: string;
  variant?: BadgeVariant;
}

export function Badge({ children, className, variant }: BadgeProps) {
  return (
    <span
      className={cn(
        "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium",
        badgeVariantClasses(variant),
        className
      )}
    >
      {children}
    </span>
  );
}
