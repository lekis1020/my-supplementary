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
  type BenefitProfileItem,
} from "@/lib/benefit-profile";
import { cn } from "@/lib/utils";

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
  immune_antioxidant: { x: 128, y: 16, labelX: 50, labelY: -8, labelAlign: "left-1/2 -translate-x-1/2" },
  gut_digestive: { x: 220, y: 68, labelX: 95, labelY: 15, labelAlign: "left-full -translate-x-full" },
  cardiometabolic: { x: 220, y: 180, labelX: 95, labelY: 75, labelAlign: "left-full -translate-x-full" },
  bone_joint_mobility: { x: 128, y: 232, labelX: 50, labelY: 102, labelAlign: "left-1/2 -translate-x-1/2" },
  beauty_vision: { x: 36, y: 180, labelX: 5, labelY: 75, labelAlign: "left-0" },
  liver_cognitive_vitality: { x: 36, y: 68, labelX: 5, labelY: 15, labelAlign: "left-0" },
};

export function BenefitHexagon({
  title,
  description,
  profile,
  className,
}: {
  title: string;
  description: string;
  profile: BenefitProfileItem[];
  className?: string;
}) {
  const items = BENEFIT_CATEGORY_ORDER.map((key) => {
    const item = profile.find((entry) => entry.key === key);
    return item ?? { key, state: "inactive" as const, strength: 0 as const };
  });
  const activeItems = items.filter((item) => item.state !== "inactive");

  return (
    <Card className={cn("overflow-hidden border-slate-200 shadow-md bg-white/50 backdrop-blur-sm", className)}>
      <CardHeader className="border-b border-slate-100 bg-slate-50/50 p-5">
        <CardTitle className="flex items-center gap-2 text-lg font-black text-slate-900">
          <Sparkles className="h-5 w-5 text-emerald-500 fill-emerald-100" />
          {title}
        </CardTitle>
        <p className="text-xs font-medium leading-relaxed text-slate-500">{description}</p>
      </CardHeader>
      <CardContent className="p-0">
        <div className="flex flex-col items-center justify-center p-8 pb-12">
          <div className="relative h-[320px] w-full max-w-[320px]">
            {/* SVG Hexagon Core */}
            <svg
              viewBox="0 0 256 248"
              aria-hidden="true"
              className="absolute inset-0 h-full w-full drop-shadow-sm"
            >
              <defs>
                <filter id="glow" x="-20%" y="-20%" width="140%" height="140%">
                  <feGaussianBlur stdDeviation="3" result="blur" />
                  <feComposite in="SourceGraphic" in2="blur" operator="over" />
                </filter>
              </defs>
              {/* Outer boundary */}
              <polygon
                points="128,16 220,68 220,180 128,232 36,180 36,68"
                fill="none"
                stroke="rgb(226 232 240)"
                strokeWidth="1.5"
                strokeDasharray="4 4"
              />
              {/* Inner connecting lines */}
              {items.map((item) => {
                const layout = VERTEX_LAYOUT[item.key];
                return (
                  <line
                    key={`line-${item.key}`}
                    x1="128"
                    y1="124"
                    x2={layout.x}
                    y2={layout.y}
                    stroke="rgb(226 232 240)"
                    strokeWidth="1"
                  />
                );
              })}
              
              {/* Active Area Filling */}
              <polygon
                points={items.map((item) => {
                  const layout = VERTEX_LAYOUT[item.key];
                  const factor = item.state === "active" ? 1 : item.state === "possible" ? 0.6 : 0.2;
                  const targetX = 128 + (layout.x - 128) * factor;
                  const targetY = 124 + (layout.y - 124) * factor;
                  return `${targetX},${targetY}`;
                }).join(" ")}
                fill="rgba(16, 185, 129, 0.15)"
                stroke="rgb(16 185 129)"
                strokeWidth="2.5"
                strokeLinejoin="round"
              />

              {/* Central Core */}
              <circle cx="128" cy="124" r="28" fill="white" stroke="rgb(226 232 240)" strokeWidth="1" />
              <text
                x="128"
                y="128"
                textAnchor="middle"
                className="fill-slate-900 text-[10px] font-black tracking-tight"
              >
                BENEFITS
              </text>
            </svg>

            {/* Labels (Vertices) */}
            {items.map((item) => {
              const meta = CATEGORY_META[item.key];
              const Icon = meta.icon;
              const layout = VERTEX_LAYOUT[item.key];
              const isActive = item.state === "active";

              return (
                <div
                  key={item.key}
                  className={cn(
                    "absolute flex flex-col items-center gap-1.5 transition-all duration-500",
                    layout.labelAlign,
                    isActive ? "scale-110 z-10" : "scale-90 opacity-80"
                  )}
                  style={{
                    top: `${layout.labelY}%`,
                    left: `${layout.labelX}%`,
                  }}
                >
                  <div className={cn(
                    "flex h-9 w-9 items-center justify-center rounded-2xl border-2 shadow-lg transition-transform hover:scale-110",
                    isActive 
                      ? `${meta.tintClass} ${meta.colorClass} border-current ring-4 ring-white` 
                      : "border-slate-100 bg-white text-slate-400"
                  )}>
                    <Icon className="h-5 w-5" />
                  </div>
                  <span className={cn(
                    "whitespace-nowrap rounded-lg border px-2.5 py-1 text-[11px] font-black shadow-sm transition-all",
                    isActive
                      ? `${meta.tintClass} ${meta.colorClass} border-current`
                      : "border-slate-100 bg-white text-slate-500"
                  )}>
                    {meta.shortLabel}
                  </span>
                </div>
              );
            })}
          </div>
        </div>

        {/* Legend / Descriptions */}
        <div className="border-t border-slate-100 bg-slate-50/30 p-6">
          <div className="grid gap-3 sm:grid-cols-2">
            {activeItems.map((item) => {
              const meta = CATEGORY_META[item.key];
              return (
                <div
                  key={item.key}
                  className={cn(
                    "flex items-start gap-3 rounded-2xl border bg-white p-4 shadow-sm",
                    meta.tintClass
                  )}
                >
                  <div className={cn("mt-0.5 rounded-lg p-1.5", meta.tintClass)}>
                    <meta.icon className={cn("h-4 w-4", meta.colorClass)} />
                  </div>
                  <div>
                    <h4 className={cn("text-xs font-black uppercase tracking-wider", meta.colorClass)}>
                      {meta.shortLabel}
                    </h4>
                    <p className="mt-1 text-xs font-medium leading-relaxed text-slate-600">
                      {meta.fullLabel}
                    </p>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
