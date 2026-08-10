import { ShieldCheck } from "lucide-react";
import { cn } from "@/lib/utils";

// Compliance rule: regulator-approved claims render ONLY through this badge —
// blue + official icon + square-ish corners, visually distinct from evidence
// badges regardless of brand palette. Do not restyle per page.
export function RegulatoryBadge({
  countryCode,
  className,
}: {
  countryCode?: string | null;
  className?: string;
}) {
  const label = countryCode === "US" ? "FDA 인정" : "식약처 인정";
  return (
    <span
      className={cn(
        "inline-flex items-center gap-1 rounded-md border border-blue-200 bg-regulatory-bg px-2 py-0.5 text-xs font-bold text-regulatory",
        className
      )}
    >
      <ShieldCheck className="h-3 w-3" aria-hidden />
      {label}
    </span>
  );
}

export type EvidenceGrade = "A" | "B" | "C" | "D" | "I";

const EVIDENCE_CLASSES: Record<EvidenceGrade, string> = {
  A: "bg-evidence-a-bg text-evidence-a",
  B: "bg-evidence-b-bg text-evidence-b",
  C: "bg-evidence-c-bg text-evidence-c",
  D: "bg-evidence-d-bg text-evidence-d",
  I: "bg-evidence-i-bg text-evidence-i",
};

export function evidenceGradeClasses(grade: string | null | undefined): string {
  const key = (grade ?? "").toUpperCase() as EvidenceGrade;
  return EVIDENCE_CLASSES[key] ?? EVIDENCE_CLASSES.I;
}

export function EvidenceGradeBadge({
  grade,
  className,
}: {
  grade: string | null | undefined;
  className?: string;
}) {
  return (
    <span
      className={cn(
        "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold",
        evidenceGradeClasses(grade),
        className
      )}
    >
      근거 {(grade ?? "I").toUpperCase()}
    </span>
  );
}

export type SeverityLevel = "high" | "medium" | "low";

const SEVERITY_CLASSES: Record<SeverityLevel, string> = {
  high: "bg-danger-bg text-danger",
  medium: "bg-evidence-c-bg text-evidence-c",
  low: "bg-stone-100 text-stone-600",
};

const SEVERITY_LABELS: Record<SeverityLevel, string> = {
  high: "주의 높음",
  medium: "주의",
  low: "참고",
};

export function severityClasses(level: string | null | undefined): string {
  return SEVERITY_CLASSES[(level ?? "low") as SeverityLevel] ?? SEVERITY_CLASSES.low;
}

export function SeverityBadge({
  level,
  label,
  className,
}: {
  level: string | null | undefined;
  label?: string;
  className?: string;
}) {
  const key = (level ?? "low") as SeverityLevel;
  return (
    <span
      className={cn(
        "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold",
        severityClasses(level),
        className
      )}
    >
      {label ?? SEVERITY_LABELS[key] ?? SEVERITY_LABELS.low}
    </span>
  );
}
