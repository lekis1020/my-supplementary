import { ShieldCheck } from "lucide-react";
import { cn } from "@/lib/utils";

const REGULATORY_LABELS: Record<string, string> = {
  KR: "식약처 인정",
  US: "FDA 인정",
};

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
  const label = REGULATORY_LABELS[countryCode ?? ""] ?? "규제기관 인정";
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

const EVIDENCE_CLASSES: Record<string, string> = {
  A: "bg-evidence-a-bg text-evidence-a",
  B: "bg-evidence-b-bg text-evidence-b",
  C: "bg-evidence-c-bg text-evidence-c",
  D: "bg-evidence-d-bg text-evidence-d",
  I: "bg-evidence-i-bg text-evidence-i",
};

export function evidenceGradeClasses(grade: string | null | undefined): string {
  return EVIDENCE_CLASSES[(grade ?? "").toUpperCase()] ?? EVIDENCE_CLASSES.I;
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

export type SeverityLevel = "mild" | "moderate" | "severe" | "critical";

const SEVERITY_CLASSES: Record<string, string> = {
  mild: "bg-stone-100 text-stone-600",
  moderate: "bg-evidence-c-bg text-evidence-c",
  severe: "bg-danger-bg text-danger",
  critical: "bg-danger-bg text-danger border border-red-300",
};

const SEVERITY_LABELS: Record<SeverityLevel, string> = {
  mild: "참고",
  moderate: "주의",
  severe: "주의 높음",
  critical: "위험",
};

// Unknown/null severity must never under-warn, so the fallback is the
// mid-tier "moderate" ("주의") rather than the lowest tier.
export function severityClasses(level: string | null | undefined): string {
  return SEVERITY_CLASSES[level ?? "moderate"] ?? SEVERITY_CLASSES.moderate;
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
  const key = (level ?? "moderate") as SeverityLevel;
  return (
    <span
      className={cn(
        "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold",
        severityClasses(level),
        className
      )}
    >
      {label ?? SEVERITY_LABELS[key] ?? SEVERITY_LABELS.moderate}
    </span>
  );
}
