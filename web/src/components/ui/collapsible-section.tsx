import { ChevronDown } from "lucide-react";
import { cn } from "@/lib/utils";
import { Badge } from "@/components/ui/badge";

// Server-component-safe accordion: native <details>, zero client JS.
export function CollapsibleSection({
  title,
  count,
  defaultOpen = false,
  children,
  className,
}: {
  title: string;
  count?: number;
  defaultOpen?: boolean;
  children: React.ReactNode;
  className?: string;
}) {
  return (
    <details
      open={defaultOpen}
      className={cn(
        "group rounded-2xl border border-stone-200 bg-surface shadow-card",
        className
      )}
    >
      <summary className="flex cursor-pointer list-none items-center justify-between gap-2 px-5 py-4 [&::-webkit-details-marker]:hidden">
        <span className="flex items-center gap-2 text-base font-bold text-ink">
          {title}
          {typeof count === "number" && <Badge variant="tag">{count}</Badge>}
        </span>
        <ChevronDown
          className="h-4 w-4 text-ink-faint transition-transform group-open:rotate-180"
          aria-hidden
        />
      </summary>
      <div className="border-t border-stone-100 px-5 py-4">{children}</div>
    </details>
  );
}
