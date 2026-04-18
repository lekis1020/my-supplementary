import type { ReactNode } from "react";
import { cn } from "@/lib/utils";

type StateVariant = "empty" | "error" | "loading";

export interface StateMessageProps {
  variant?: StateVariant;
  title: string;
  description?: ReactNode;
  action?: ReactNode;
  icon?: ReactNode;
  className?: string;
}

const variantStyles: Record<
  StateVariant,
  { container: string; title: string; description: string }
> = {
  empty: {
    container: "border-dashed border-slate-200 bg-slate-50",
    title: "text-slate-900",
    description: "text-slate-500",
  },
  error: {
    container: "border-amber-200 bg-amber-50",
    title: "text-amber-900",
    description: "text-amber-800",
  },
  loading: {
    container: "border-slate-200 bg-white",
    title: "text-slate-900",
    description: "text-slate-500",
  },
};

export function StateMessage({
  variant = "empty",
  title,
  description,
  action,
  icon,
  className,
}: StateMessageProps) {
  const styles = variantStyles[variant];
  const role = variant === "error" ? "alert" : "status";

  return (
    <div
      role={role}
      aria-live={variant === "error" ? "assertive" : "polite"}
      className={cn(
        "rounded-3xl border px-6 py-14 text-center",
        styles.container,
        className,
      )}
    >
      {icon && <div className="mb-3 flex justify-center">{icon}</div>}
      <p className={cn("text-lg font-semibold", styles.title)}>{title}</p>
      {description && (
        <div className={cn("mt-2 text-sm", styles.description)}>
          {description}
        </div>
      )}
      {action && <div className="mt-4 flex justify-center">{action}</div>}
    </div>
  );
}

export function EmptyState(props: Omit<StateMessageProps, "variant">) {
  return <StateMessage variant="empty" {...props} />;
}

export function ErrorState(props: Omit<StateMessageProps, "variant">) {
  return <StateMessage variant="error" {...props} />;
}

export function LoadingState(props: Omit<StateMessageProps, "variant">) {
  return <StateMessage variant="loading" {...props} />;
}
