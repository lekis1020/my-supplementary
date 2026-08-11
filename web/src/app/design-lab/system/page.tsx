import {
  Palette,
  Tag,
  LayoutGrid,
  MousePointerClick,
  BarChart3,
  ChevronsUpDown,
} from "lucide-react";
import { Badge } from "@/components/ui/badge";
import {
  RegulatoryBadge,
  EvidenceGradeBadge,
  SeverityBadge,
} from "@/components/ui/domain-badges";
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card";
import { CTAButton } from "@/components/ui/cta-button";
import { SummaryStat } from "@/components/ui/summary-stat";
import { CollapsibleSection } from "@/components/ui/collapsible-section";
import { SectionHeader } from "@/components/ui/section-header";

export const metadata = { title: "디자인 시스템" };

interface ColorSwatch {
  name: string;
  className: string;
}

const COLOR_SWATCHES: ColorSwatch[] = [
  { name: "brand", className: "bg-brand" },
  { name: "brand-soft", className: "bg-brand-soft" },
  { name: "brand-bg", className: "bg-brand-bg" },
  { name: "canvas", className: "bg-canvas" },
  { name: "surface", className: "bg-surface" },
  { name: "ink", className: "bg-ink" },
  { name: "ink-muted", className: "bg-ink-muted" },
  { name: "ink-faint", className: "bg-ink-faint" },
  { name: "regulatory", className: "bg-regulatory" },
  { name: "regulatory-bg", className: "bg-regulatory-bg" },
  { name: "danger", className: "bg-danger" },
  { name: "danger-bg", className: "bg-danger-bg" },
  { name: "evidence-a-bg", className: "bg-evidence-a-bg" },
  { name: "evidence-b-bg", className: "bg-evidence-b-bg" },
  { name: "evidence-c-bg", className: "bg-evidence-c-bg" },
  { name: "evidence-d-bg", className: "bg-evidence-d-bg" },
  { name: "evidence-i-bg", className: "bg-evidence-i-bg" },
];

const EVIDENCE_GRADES = ["A", "B", "C", "D", "I"] as const;

const SEVERITY_LEVELS = ["mild", "moderate", "severe", "critical"] as const;

const CARD_TONES = ["surface", "highlight"] as const;
const CARD_PADDINGS = ["none", "sm", "md"] as const;

export default function DesignSystemShowcasePage() {
  return (
    <div className="min-h-screen bg-canvas pb-24">
      <div className="border-b border-stone-200 bg-surface px-6 py-12">
        <div className="mx-auto max-w-5xl">
          <Badge variant="promo" className="mb-3">
            Design Lab
          </Badge>
          <h1 className="text-3xl font-black tracking-tight text-ink">
            디자인 시스템 — 웜 커머스
          </h1>
          <p className="mt-2 max-w-2xl text-sm leading-relaxed text-ink-muted">
            토큰과 프리미티브 컴포넌트를 한 페이지에 모아 시각적으로 검증하기 위한
            페이지입니다. 실 데이터를 사용하지 않으며, 스크린샷·QA 용도로만
            사용합니다.
          </p>
        </div>
      </div>

      <main className="mx-auto max-w-5xl space-y-14 px-6 py-10">
        {/* 1. 컬러 스와치 */}
        <section>
          <SectionHeader
            icon={<Palette className="h-5 w-5" />}
            title="컬러 토큰"
            count={COLOR_SWATCHES.length}
            description="brand / canvas / ink / regulatory / danger / evidence a–i"
          />
          <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5">
            {COLOR_SWATCHES.map((swatch) => (
              <div key={swatch.name} className="flex flex-col gap-2">
                <div
                  className={`h-16 rounded-xl border border-stone-200 shadow-card ${swatch.className}`}
                  aria-hidden
                />
                <span className="text-xs font-medium text-ink-muted">
                  {swatch.name}
                </span>
              </div>
            ))}
          </div>
        </section>

        {/* 2. 뱃지 */}
        <section>
          <SectionHeader
            icon={<Tag className="h-5 w-5" />}
            title="뱃지"
            description="Badge 4종, RegulatoryBadge, EvidenceGradeBadge, SeverityBadge"
          />
          <div className="space-y-6">
            <div>
              <p className="mb-2 text-xs font-semibold text-ink-faint">
                Badge — variant
              </p>
              <div className="flex flex-wrap gap-2">
                <Badge variant="neutral">neutral</Badge>
                <Badge variant="tag">tag</Badge>
                <Badge variant="promo">promo</Badge>
                <Badge variant="outline">outline</Badge>
              </div>
            </div>
            <div>
              <p className="mb-2 text-xs font-semibold text-ink-faint">
                RegulatoryBadge — countryCode
              </p>
              <div className="flex flex-wrap gap-2">
                <RegulatoryBadge countryCode="KR" />
                <RegulatoryBadge countryCode="US" />
                <RegulatoryBadge />
              </div>
            </div>
            <div>
              <p className="mb-2 text-xs font-semibold text-ink-faint">
                EvidenceGradeBadge — grade
              </p>
              <div className="flex flex-wrap gap-2">
                {EVIDENCE_GRADES.map((grade) => (
                  <EvidenceGradeBadge key={grade} grade={grade} />
                ))}
              </div>
            </div>
            <div>
              <p className="mb-2 text-xs font-semibold text-ink-faint">
                SeverityBadge — level
              </p>
              <div className="flex flex-wrap gap-2">
                {SEVERITY_LEVELS.map((level) => (
                  <SeverityBadge key={level} level={level} />
                ))}
              </div>
            </div>
          </div>
        </section>

        {/* 3. 카드 */}
        <section>
          <SectionHeader
            icon={<LayoutGrid className="h-5 w-5" />}
            title="카드"
            description="tone 2종 × padding 3종"
          />
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {CARD_TONES.flatMap((tone) =>
              CARD_PADDINGS.map((padding) => (
                <Card key={`${tone}-${padding}`} tone={tone} padding={padding}>
                  <CardHeader className={padding === "none" ? "px-4 pt-4" : undefined}>
                    <CardTitle>
                      {tone} / {padding}
                    </CardTitle>
                  </CardHeader>
                  <CardContent className={padding === "none" ? "px-4 pb-4" : undefined}>
                    <p className="text-sm text-ink-muted">
                      Card tone=&quot;{tone}&quot; padding=&quot;{padding}&quot;
                    </p>
                  </CardContent>
                </Card>
              ))
            )}
          </div>
        </section>

        {/* 4. CTA 버튼 */}
        <section>
          <SectionHeader
            icon={<MousePointerClick className="h-5 w-5" />}
            title="CTA 버튼"
            description="primary / outline (href 형태)"
          />
          <div className="flex flex-wrap gap-3">
            <CTAButton href="/design-lab/system" variant="primary">
              비교하기
            </CTAButton>
            <CTAButton href="/design-lab/system" variant="outline">
              자세히 보기
            </CTAButton>
          </div>
        </section>

        {/* 5. 요약 통계 */}
        <section>
          <SectionHeader
            icon={<BarChart3 className="h-5 w-5" />}
            title="요약 통계"
            description="accent 3종"
          />
          <div className="grid grid-cols-3 gap-3 sm:max-w-md">
            <SummaryStat value="128" label="비교 성분" accent="brand" />
            <SummaryStat value="42" label="식약처 인정" accent="regulatory" />
            <SummaryStat value="3" label="주의 성분" accent="danger" />
          </div>
        </section>

        {/* 6. 접이식 섹션 */}
        <section>
          <SectionHeader
            icon={<ChevronsUpDown className="h-5 w-5" />}
            title="접이식 섹션"
            description="defaultOpen true / false"
          />
          <div className="space-y-3">
            <CollapsibleSection title="기본 열림" count={3} defaultOpen>
              <p className="text-sm text-ink-muted">
                defaultOpen=true로 렌더된 CollapsibleSection 내용입니다.
              </p>
            </CollapsibleSection>
            <CollapsibleSection title="기본 닫힘" count={5}>
              <p className="text-sm text-ink-muted">
                defaultOpen을 생략하면 기본값(false)으로 닫힌 상태로 렌더됩니다.
              </p>
            </CollapsibleSection>
          </div>
        </section>
      </main>
    </div>
  );
}
