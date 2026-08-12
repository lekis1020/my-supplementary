import {
  Activity,
  Bone,
  Brain,
  Eye,
  ShieldPlus,
  Sparkles,
  Stethoscope,
} from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import {
  BENEFIT_CATEGORY_ORDER,
  type BenefitCategoryKey,
  type BenefitClaimDetail,
  type BenefitProfileItem,
} from "@/lib/benefit-profile";
import { cn, getClaimScopeLabel } from "@/lib/utils";

const CATEGORY_META: Record<
  BenefitCategoryKey,
  {
    shortLabel: string;
    fullLabel: string;
    icon: typeof ShieldPlus;
    colorClass: string;
    tintClass: string;
    activeFill: string;
    activeStroke: string;
  }
> = {
  immune_antioxidant: {
    shortLabel: "면역·항산화",
    fullLabel: "면역 기능, 항산화",
    icon: ShieldPlus,
    colorClass: "text-orange-700",
    tintClass: "bg-brand-bg border-orange-200",
    activeFill: "var(--chart-immune-fill)",
    activeStroke: "var(--chart-immune-stroke)",
  },
  gut_digestive: {
    shortLabel: "장·소화",
    fullLabel: "장 건강, 소화, 배변",
    icon: Stethoscope,
    colorClass: "text-teal-700",
    tintClass: "bg-teal-50 border-teal-200",
    activeFill: "var(--chart-gut-fill)",
    activeStroke: "var(--chart-gut-stroke)",
  },
  cardiometabolic: {
    shortLabel: "혈행·대사",
    fullLabel: "혈행, 혈당, 체지방, 지질",
    icon: Activity,
    colorClass: "text-rose-700",
    tintClass: "bg-rose-50 border-rose-200",
    activeFill: "var(--chart-cardio-fill)",
    activeStroke: "var(--chart-cardio-stroke)",
  },
  bone_joint_mobility: {
    shortLabel: "뼈·관절·운동",
    fullLabel: "뼈, 관절, 연골, 운동 퍼포먼스",
    icon: Bone,
    colorClass: "text-amber-700",
    tintClass: "bg-amber-50 border-amber-200",
    activeFill: "var(--chart-bone-fill)",
    activeStroke: "var(--chart-bone-stroke)",
  },
  beauty_vision: {
    shortLabel: "피부·눈·미용",
    fullLabel: "피부 보습, 눈 건강, 미용",
    icon: Eye,
    colorClass: "text-fuchsia-700",
    tintClass: "bg-fuchsia-50 border-fuchsia-200",
    activeFill: "var(--chart-beauty-fill)",
    activeStroke: "var(--chart-beauty-stroke)",
  },
  liver_cognitive_vitality: {
    shortLabel: "간·인지·활력",
    fullLabel: "간 건강, 기억력, 활력",
    icon: Brain,
    colorClass: "text-violet-700",
    tintClass: "bg-violet-50 border-violet-200",
    activeFill: "var(--chart-liver-fill)",
    activeStroke: "var(--chart-liver-stroke)",
  },
};

const VERTEX_LAYOUT: Record<
  BenefitCategoryKey,
  { x: number; y: number; labelX: number; labelY: number; labelAlign: string }
> = {
  immune_antioxidant: {
    x: 128,
    y: 16,
    labelX: 50,
    labelY: -8,
    labelAlign: "left-1/2 -translate-x-1/2",
  },
  gut_digestive: {
    x: 220,
    y: 68,
    labelX: 95,
    labelY: 15,
    labelAlign: "left-full -translate-x-full",
  },
  cardiometabolic: {
    x: 220,
    y: 180,
    labelX: 95,
    labelY: 75,
    labelAlign: "left-full -translate-x-full",
  },
  bone_joint_mobility: {
    x: 128,
    y: 232,
    labelX: 50,
    labelY: 102,
    labelAlign: "left-1/2 -translate-x-1/2",
  },
  beauty_vision: {
    x: 36,
    y: 180,
    labelX: 5,
    labelY: 75,
    labelAlign: "left-0",
  },
  liver_cognitive_vitality: {
    x: 36,
    y: 68,
    labelX: 5,
    labelY: 15,
    labelAlign: "left-0",
  },
};

function getEvidenceLabel(details: BenefitClaimDetail[]): string {
  if (details.some((detail) => detail.isRegulatorApproved)) {
    return "규제 승인";
  }
  if (details.some((detail) => detail.evidenceGrade === "A")) {
    return "근거수준 A";
  }
  if (details.some((detail) => detail.evidenceGrade === "B")) {
    return "근거수준 B";
  }
  if (details.some((detail) => detail.evidenceGrade)) {
    const firstGrade = details.find((detail) => detail.evidenceGrade)?.evidenceGrade;
    return `근거수준 ${firstGrade}`;
  }
  return "근거수준 미기재";
}

export function BenefitHexagon({
  title,
  description,
  profile,
  claimDetails = [],
  className,
}: {
  title: string;
  description: string;
  profile: BenefitProfileItem[];
  claimDetails?: BenefitClaimDetail[];
  className?: string;
}) {
  const items = BENEFIT_CATEGORY_ORDER.map((key) => {
    const item = profile.find((entry) => entry.key === key);
    return item ?? { key, state: "inactive" as const, strength: 0 as const };
  });
  const activeItems = items.filter((item) => item.state !== "inactive");
  const groupedClaimDetails = BENEFIT_CATEGORY_ORDER.reduce<Record<BenefitCategoryKey, BenefitClaimDetail[]>>(
    (acc, key) => {
      acc[key] = claimDetails.filter((detail) => detail.key === key);
      return acc;
    },
    {
      immune_antioxidant: [],
      gut_digestive: [],
      cardiometabolic: [],
      bone_joint_mobility: [],
      beauty_vision: [],
      liver_cognitive_vitality: [],
    },
  );
  const textBenefitLines = Array.from(
    new Set(
      activeItems.flatMap((item) => {
        const details = groupedClaimDetails[item.key];
        if (details.length === 0) {
          return [CATEGORY_META[item.key].fullLabel];
        }
        return details.map((detail) => detail.claimNameKo);
      }),
    ),
  );

  return (
    <Card
      className={cn(
        "overflow-hidden border-stone-200 bg-white/70 shadow-md backdrop-blur-sm",
        className,
      )}
    >
      <CardHeader className="border-b border-stone-100 bg-stone-50/60 p-5">
        <CardTitle className="flex items-center gap-2 text-lg font-black text-ink">
          <Sparkles className="h-5 w-5 fill-orange-100 text-orange-700" />
          {title}
        </CardTitle>
        <p className="text-xs font-medium leading-relaxed text-ink-muted">{description}</p>
      </CardHeader>
      <CardContent className="space-y-6 p-5">
        <div className="grid gap-6 lg:grid-cols-[320px_minmax(0,1fr)] lg:items-start">
          <div className="mx-auto flex w-full max-w-[320px] flex-col items-center">
            <div className="relative h-[320px] w-full">
              <svg
                viewBox="0 0 256 248"
                aria-hidden="true"
                className="absolute inset-0 h-full w-full drop-shadow-sm"
              >
                <polygon
                  points="128,16 220,68 220,180 128,232 36,180 36,68"
                  fill="none"
                  stroke="var(--chart-grid)"
                  strokeWidth="1.5"
                  strokeDasharray="4 4"
                />
                {items.map((item) => {
                  const layout = VERTEX_LAYOUT[item.key];
                  return (
                    <line
                      key={`line-${item.key}`}
                      x1="128"
                      y1="124"
                      x2={layout.x}
                      y2={layout.y}
                      stroke="var(--chart-grid)"
                      strokeWidth="1"
                    />
                  );
                })}
                <polygon
                  points={items
                    .map((item) => {
                      const layout = VERTEX_LAYOUT[item.key];
                      const factor =
                        item.state === "active" ? 1 : item.state === "possible" ? 0.6 : 0.2;
                      const targetX = 128 + (layout.x - 128) * factor;
                      const targetY = 124 + (layout.y - 124) * factor;
                      return `${targetX},${targetY}`;
                    })
                    .join(" ")}
                  fill="var(--chart-active-fill)"
                  stroke="var(--chart-active-stroke)"
                  strokeWidth="2.5"
                  strokeLinejoin="round"
                />
                <circle
                  cx="128"
                  cy="124"
                  r="28"
                  fill="white"
                  stroke="var(--chart-grid)"
                  strokeWidth="1"
                />
                <text
                  x="128"
                  y="120"
                  textAnchor="middle"
                  className={cn(
                    "text-[10px] font-black tracking-tight",
                    activeItems.length > 0 ? "fill-ink" : "fill-orange-700"
                  )}
                >
                  {activeItems.length > 0 ? "BENEFITS" : "PREPARING"}
                </text>
                <text
                  x="128"
                  y="134"
                  textAnchor="middle"
                  className="fill-ink-faint text-[8px]"
                >
                  {activeItems.length > 0 ? "강도 비교 아님" : "데이터 분석 중"}
                </text>
              </svg>

              {items.map((item) => {
                const meta = CATEGORY_META[item.key];
                const Icon = meta.icon;
                const layout = VERTEX_LAYOUT[item.key];
                const isActive = item.state === "active";
                const isPossible = item.state === "possible";

                return (
                  <div
                    key={item.key}
                    className={cn(
                      "absolute flex flex-col items-center gap-1.5 transition-all duration-500",
                      layout.labelAlign,
                      isActive ? "z-10 scale-110" : isPossible ? "scale-100" : "scale-90 opacity-40",
                    )}
                    style={{
                      top: `${layout.labelY}%`,
                      left: `${layout.labelX}%`,
                    }}
                  >
                    <div
                      className={cn(
                        "flex h-9 w-9 items-center justify-center rounded-2xl border-2 shadow-lg transition-transform hover:scale-110",
                        isActive
                          ? `${meta.tintClass} ${meta.colorClass} border-current ring-4 ring-white`
                          : isPossible
                            ? "border-stone-200 bg-white text-ink-muted"
                            : "border-stone-100 bg-stone-50 text-stone-300",
                      )}
                    >
                      <Icon className="h-5 w-5" />
                    </div>
                    <span
                      className={cn(
                        "whitespace-nowrap rounded-lg border px-2.5 py-1 text-[11px] font-black shadow-sm",
                        isActive
                          ? `${meta.tintClass} ${meta.colorClass} border-current`
                          : isPossible
                            ? "border-stone-200 bg-white text-ink-muted"
                            : "border-stone-50 bg-stone-50 text-ink-faint",
                      )}
                    >
                      {meta.shortLabel}
                    </span>
                  </div>
                );
              })}
            </div>
          </div>

          <div className="space-y-4">
            <div className="flex flex-wrap gap-2">
              {activeItems.length > 0 ? (
                activeItems.map((item) => {
                  const meta = CATEGORY_META[item.key];
                  return (
                    <span
                      key={item.key}
                      className={cn(
                        "inline-flex items-center rounded-full border px-3 py-1 text-xs font-semibold",
                        item.state === "active"
                          ? `${meta.tintClass} ${meta.colorClass}`
                          : "border-stone-200 bg-white text-ink-muted",
                      )}
                    >
                      {meta.shortLabel}
                    </span>
                  );
                })
              ) : (
                <span className="inline-flex items-center gap-1.5 rounded-full border border-orange-100 bg-brand-bg/50 px-3 py-1 text-xs font-bold text-orange-700">
                  <span className="relative flex h-2 w-2">
                    <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-orange-400 opacity-75"></span>
                    <span className="relative inline-flex h-2 w-2 rounded-full bg-orange-500"></span>
                  </span>
                  전문가 데이터 검수 대기 중
                </span>
              )}
            </div>

            <div className="rounded-2xl border border-stone-200 bg-stone-50/70 px-4 py-3">
              <p className="text-xs font-semibold text-ink-muted">텍스트 효능 요약</p>
              {textBenefitLines.length > 0 ? (
                <div className="mt-2 space-y-1 text-xs leading-5 text-ink-muted">
                  {textBenefitLines.map((benefitText, index) => (
                    <p key={`${benefitText}-${index}`}>{benefitText}</p>
                  ))}
                </div>
              ) : (
                <p className="mt-2 text-xs leading-6 font-medium text-ink-muted">
                  이 제품의 성분-기능성 매핑 데이터가 수집 및 검수 과정에 있습니다. 완료 시 텍스트 요약이 자동으로 생성됩니다.
                </p>
              )}
            </div>
          </div>

        </div>

        <div className="grid gap-3 sm:grid-cols-2">
          {items.map((item) => {
            const meta = CATEGORY_META[item.key];
            const details = groupedClaimDetails[item.key];
            const detailPreview = details.slice(0, 2);

            return (
              <div
                key={item.key}
                className={cn(
                  "rounded-2xl border px-4 py-3",
                  item.state === "active"
                    ? meta.tintClass
                    : item.state === "possible"
                      ? "border-stone-200 bg-white"
                      : "border-stone-100 bg-stone-50",
                )}
              >
                <div className="flex items-center justify-between gap-3">
                  <p
                    className={cn(
                      "text-sm font-semibold",
                      item.state === "inactive" ? "text-ink-faint" : meta.colorClass,
                    )}
                  >
                    {meta.shortLabel}
                  </p>
                  <span
                    className={cn(
                      "rounded-full px-2 py-0.5 text-[10px] font-bold",
                      item.state === "active"
                        ? "bg-white/80 text-ink-muted"
                        : item.state === "possible"
                          ? "bg-stone-100 text-ink-muted"
                          : "bg-white text-ink-faint",
                    )}
                  >
                    {item.state === "active" ? "해당" : item.state === "possible" ? "가능성" : "없음"}
                  </span>
                </div>
                <p className="mt-2 text-xs leading-5 text-ink-muted">{meta.fullLabel}</p>
                <p className="mt-2 text-[11px] font-semibold text-ink-muted">
                  근거: {details.length > 0 ? getEvidenceLabel(details) : "근거 없음"}
                </p>
                {detailPreview.length > 0 ? (
                  <div className="mt-1 space-y-1">
                    {detailPreview.map((detail, idx) => (
                      <p key={`${detail.claimNameKo}-${idx}`} className="text-[11px] leading-4 text-ink-muted">
                        · {detail.claimNameKo}
                        {detail.claimScope ? ` (${getClaimScopeLabel(detail.claimScope)})` : ""}
                      </p>
                    ))}
                    {details.length > detailPreview.length && (
                      <p className="text-[11px] text-ink-faint">외 {details.length - detailPreview.length}건</p>
                    )}
                  </div>
                ) : (
                  <p className="mt-1 text-[11px] text-ink-faint">구체 효능 데이터 없음</p>
                )}
              </div>
            );
          })}
        </div>
      </CardContent>
    </Card>
  );
}
