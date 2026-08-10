import Link from "next/link";
import { cn } from "@/lib/utils";

type CTAVariant = "primary" | "outline";

const CTA_CLASSES: Record<CTAVariant, string> = {
  primary: "bg-brand text-white hover:bg-orange-600 shadow-card",
  outline: "border border-stone-300 text-ink hover:border-brand hover:text-orange-700 bg-surface",
};

interface CTAButtonProps {
  children: React.ReactNode;
  href?: string;
  onClick?: () => void;
  variant?: CTAVariant;
  className?: string;
}

export function CTAButton({
  children,
  href,
  onClick,
  variant = "primary",
  className,
}: CTAButtonProps) {
  const classes = cn(
    "inline-flex items-center justify-center gap-1.5 rounded-xl px-4 py-2.5 text-sm font-bold transition-colors",
    CTA_CLASSES[variant],
    className
  );
  if (href) {
    return (
      <Link href={href} className={classes}>
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
