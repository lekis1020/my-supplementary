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
    colorClass: "text-emerald-700",
    tintClass: "bg-emerald-50 border-emerald-200",
    activeFill: "rgb(16 185 129)",
    activeStroke: "rgb(167 243 208)",
  },
  gut_digestive: {
    shortLabel: "장·소화",
    fullLabel: "장 건강, 소화, 배변",
    icon: Stethoscope,
    colorClass: "text-teal-700",
    tintClass: "bg-teal-50 border-teal-200",
    activeFill: "rgb(20 184 166)",
    activeStroke: "rgb(153 246 228)",
  },
  cardiometabolic: {
    shortLabel: "혈행·대사",
    fullLabel: "혈행, 혈당, 체지방, 지질",
    icon: Activity,
    colorClass: "text-rose-700",
    tintClass: "bg-rose-50 border-rose-200",
    activeFill: "rgb(244 63 94)",
    activeStroke: "rgb(254 205 211)",
  },
  bone_joint_mobility: {
    shortLabel: "뼈·관절·운동",
    fullLabel: "뼈, 관절, 연골, 운동 퍼포먼스",
    icon: Bone,
    colorClass: "text-amber-700",
    tintClass: "bg-amber-50 border-amber-200",
    activeFill: "rgb(245 158 11)",
    activeStroke: "rgb(253 230 138)",
  },
  beauty_vision: {
    shortLabel: "피부·눈·미용",
    fullLabel: "피부 보습, 눈 건강, 미용",
    icon: Eye,
    colorClass: "text-fuchsia-700",
    tintClass: "bg-fuchsia-50 border-fuchsia-200",
    activeFill: "rgb(217 70 239)",
    activeStroke: "rgb(245 208 254)",
  },
  liver_cognitive_vitality: {
    shortLabel: "간·인지·활력",
    fullLabel: "간 건강, 기억력, 활력",
    icon: Brain,
    colorClass: "text-violet-700",
    tintClass: "bg-violet-50 border-violet-200",
    activeFill: "rgb(139 92 246)",
    activeStroke: "rgb(221 214 254)",
  },
};

const VERTEX_LAYOUT: Record<
  BenefitCategoryKey,
  { x: number; y: number; labelX: number; labelY: number; labelAlign: string }
> = {
  immune_antioxidant: { x: 128, y: 16, labelX: 50, labelY: 3, labelAlign: "left-1/2 -translate-x-1/2" },
  gut_digestive: { x: 220, y: 68, labelX: 86, labelY: 24, labelAlign: "left-1/2 -translate-x-1/2" },
  cardiometabolic: { x: 220, y: 180, labelX: 86, labelY: 70, labelAlign: "left-1/2 -translate-x-1/2" },
  bone_joint_mobility: { x: 128, y: 232, labelX: 50, labelY: 91, labelAlign: "left-1/2 -translate-x-1/2" },
  beauty_vision: { x: 36, y: 180, labelX: 14, labelY: 70, labelAlign: "left-1/2 -translate-x-1/2" },
  liver_cognitive_vitality: { x: 36, y: 68, labelX: 14, labelY: 24, labelAlign: "left-1/2 -translate-x-1/2" },
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
}: {
  title: string;
  description: string;
  profile: BenefitProfileItem[];
  claimDetails?: BenefitClaimDetail[];
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

  const textBenefitLines = activeItems.flatMap((item) => {
    const details = groupedClaimDetails[item.key];
    if (details.length === 0) {
      return [CATEGORY_META[item.key].fullLabel];
    }
    return details.map((detail) => detail.claimNameKo);
  });

  return (
    <Card className="overflow-hidden border-slate-200 shadow-sm">
      <CardHeader className="border-b border-slate-100 bg-gradient-to-br from-white via-slate-50 to-emerald-50/40">
        <CardTitle className="flex items-center gap-2 text-slate-900">
          <Sparkles className="h-5 w-5 text-emerald-600" />
          {title}
        </CardTitle>
        <p className="text-sm leading-6 text-slate-500">{description}</p>
      </CardHeader>
      <CardContent className="grid gap-8 px-5 py-6 lg:grid-cols-[280px_minmax(0,1fr)] lg:items-start">
        <div className="mx-auto w-full max-w-[280px] space-y-4">
          <div className="relative aspect-square rounded-[2rem] border border-slate-200 bg-white/90 shadow-[0_24px_60px_-40px_rgba(15,23,42,0.55)]">
            <svg
              viewBox="0 0 256 248"
              aria-hidden="true"
              className="absolute inset-4 h-[calc(100%-2rem)] w-[calc(100%-2rem)]"
            >
              <polygon
                points="128,16 220,68 220,180 128,232 36,180 36,68"
                fill="none"
                stroke="rgb(203 213 225)"
                strokeWidth="2"
              />
              <circle cx="128" cy="124" r="26" fill="rgb(248 250 252)" stroke="rgb(226 232 240)" />
              <text
                x="128"
                y="118"
                textAnchor="middle"
                className="fill-slate-600 text-[10px] font-semibold"
              >
                효능 범위
              </text>
              <text
                x="128"
                y="132"
                textAnchor="middle"
                className="fill-slate-400 text-[8px]"
              >
                강도 비교 아님
              </text>
              {items.map((item) => {
                const layout = VERTEX_LAYOUT[item.key];
                const isActive = item.state === "active";
                const isPossible = item.state === "possible";
                const meta = CATEGORY_META[item.key];

                return (
                  <g key={item.key}>
                    <line
                      x1="128"
                      y1="124"
                      x2={layout.x}
                      y2={layout.y}
                      stroke={isActive ? "rgb(16 185 129 / 0.28)" : isPossible ? "rgb(148 163 184 / 0.45)" : "rgb(226 232 240)"}
                      strokeDasharray={isPossible ? "4 4" : undefined}
                    />
                    <circle
                      cx={layout.x}
                      cy={layout.y}
                      r={isActive ? "10" : "8"}
                      fill={isActive ? meta.activeFill : isPossible ? "white" : "rgb(241 245 249)"}
                      stroke={isActive ? meta.activeStroke : isPossible ? "rgb(148 163 184)" : "rgb(226 232 240)"}
                      strokeWidth="3"
                    />
                  </g>
                );
              })}
            </svg>

            {items.map((item) => {
              const meta = CATEGORY_META[item.key];
              const Icon = meta.icon;
              const layout = VERTEX_LAYOUT[item.key];

              return (
                <div
                  key={item.key}
                  className={cn(
                    "absolute flex items-center gap-2 rounded-full border px-2.5 py-1.5 text-[11px] font-semibold shadow-sm backdrop-blur",
                    layout.labelAlign,
                    meta.colorClass,
                    item.state === "active"
                      ? `${meta.tintClass} bg-white`
                      : item.state === "possible"
                        ? "border-slate-200 bg-white text-slate-600"
                        : "border-slate-100 bg-slate-50 text-slate-400",
                  )}
                  style={{
                    top: `${layout.labelY}%`,
                    left: `${layout.labelX}%`,
                  }}
                >
                  <Icon className="h-3.5 w-3.5" />
                  <span>{meta.shortLabel}</span>
                </div>
              );
            })}
          </div>

          <div className="rounded-2xl border border-slate-200 bg-slate-50/70 px-4 py-3">
            <p className="text-xs font-semibold text-slate-600">텍스트 효능 요약</p>
            {textBenefitLines.length > 0 ? (
              <div className="mt-2 space-y-1 text-xs leading-5 text-slate-700">
                {textBenefitLines.map((benefitText, index) => (
                  <p key={`${benefitText}-${index}`}>{benefitText}</p>
                ))}
              </div>
            ) : (
              <p className="mt-2 text-xs leading-5 text-slate-500">
                텍스트로 표시할 수 있는 효능 정보가 아직 충분하지 않습니다.
              </p>
            )}
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
                        : "border-slate-200 bg-white text-slate-600",
                    )}
                  >
                    {meta.shortLabel}
                  </span>
                );
              })
            ) : (
              <span className="inline-flex rounded-full border border-slate-200 bg-white px-3 py-1 text-xs font-medium text-slate-500">
                아직 정리된 효능 축 정보가 충분하지 않습니다.
              </span>
            )}
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
                        ? "border-slate-200 bg-white"
                        : "border-slate-100 bg-slate-50",
                  )}
                >
                  <div className="flex items-center justify-between gap-3">
                    <p className={cn("text-sm font-semibold", item.state === "inactive" ? "text-slate-400" : meta.colorClass)}>
                      {meta.shortLabel}
                    </p>
                    <span
                      className={cn(
                        "rounded-full px-2 py-0.5 text-[10px] font-bold",
                        item.state === "active"
                          ? "bg-white/80 text-slate-700"
                          : item.state === "possible"
                            ? "bg-slate-100 text-slate-600"
                            : "bg-white text-slate-400",
                      )}
                    >
                      {item.state === "active" ? "해당" : item.state === "possible" ? "가능성" : "없음"}
                    </span>
                  </div>
                  <p className="mt-2 text-xs leading-5 text-slate-500">{meta.fullLabel}</p>
                  <p className="mt-2 text-[11px] font-semibold text-slate-600">
                    근거: {details.length > 0 ? getEvidenceLabel(details) : "근거 없음"}
                  </p>
                  {detailPreview.length > 0 ? (
                    <div className="mt-1 space-y-1">
                      {detailPreview.map((detail, idx) => (
                        <p key={`${detail.claimNameKo}-${idx}`} className="text-[11px] leading-4 text-slate-600">
                          · {detail.claimNameKo}
                          {detail.claimScope ? ` (${getClaimScopeLabel(detail.claimScope)})` : ""}
                        </p>
                      ))}
                      {details.length > detailPreview.length && (
                        <p className="text-[11px] text-slate-400">외 {details.length - detailPreview.length}건</p>
                      )}
                    </div>
                  ) : (
                    <p className="mt-1 text-[11px] text-slate-400">구체 효능 데이터 없음</p>
                  )}
                </div>
              );
            })}
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
