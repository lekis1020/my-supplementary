import { cn } from "@/lib/utils";
import { Badge } from "@/components/ui/badge";

export function SectionHeader({
  icon,
  title,
  count,
  description,
  className,
}: {
  icon?: React.ReactNode;
  title: string;
  count?: number;
  description?: string;
  className?: string;
}) {
  return (
    <div className={cn("mb-4", className)}>
      <div className="flex items-center gap-2">
        {icon && <span className="text-orange-500">{icon}</span>}
        <h2 className="text-lg font-bold text-ink">{title}</h2>
        {typeof count === "number" && <Badge variant="tag">{count}</Badge>}
      </div>
      {description && <p className="mt-1 text-sm text-ink-muted">{description}</p>}
    </div>
  );
}
