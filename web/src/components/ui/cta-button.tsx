import Link from "next/link";
import { cn } from "@/lib/utils";

type CTAVariant = "primary" | "outline";

const CTA_CLASSES: Record<CTAVariant, string> = {
  // WCAG AA: white text needs ≥4.5:1 — orange-700 passes; brand #f97316 (2.8:1) is reserved for non-text accents
  primary: "bg-orange-700 text-white hover:bg-orange-800 shadow-card",
  outline: "border border-stone-300 text-ink hover:border-brand hover:text-orange-700 bg-surface",
};

interface CTAButtonProps {
  children: React.ReactNode;
  href?: string;
  onClick?: () => void;
  variant?: CTAVariant;
  className?: string;
  // For external hrefs (e.g. outbound sale links) — next/link renders a
  // plain <a> for off-site URLs, so these pass straight through.
  target?: string;
  rel?: string;
}

export function CTAButton({
  children,
  href,
  onClick,
  variant = "primary",
  className,
  target,
  rel,
}: CTAButtonProps) {
  const classes = cn(
    "inline-flex items-center justify-center gap-1.5 rounded-xl px-4 py-2.5 text-sm font-bold transition-colors",
    CTA_CLASSES[variant],
    className
  );
  if (href) {
    return (
      <Link href={href} target={target} rel={rel} className={classes}>
        {children}
      </Link>
    );
  }
  return (
    <button type="button" onClick={onClick} className={classes}>
      {children}
    </button>
  );
}
