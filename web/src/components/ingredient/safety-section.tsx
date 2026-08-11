// 안전성 · 상호작용 섹션 for `/ingredients/[slug]`. Moved out of
// `web/src/app/ingredients/[slug]/page.tsx` (former separate `{/* 안전성 */}`
// and `{/* 약물 상호작용 */}` Card blocks) as part of the warm-commerce
// redesign, merged into a single collapsible cluster with two subheadings.
// Server component, display-only — safety item / interaction fetch stays in
// `@/lib/data/ingredient-detail`.
import { CollapsibleSection } from "@/components/ui/collapsible-section";
import { SeverityBadge } from "@/components/ui/domain-badges";
import type { IngredientDetail } from "@/lib/data/ingredient-detail";

interface SafetySectionProps {
  safetyItems: IngredientDetail["safetyItems"];
  drugInteractions: IngredientDetail["drugInteractions"];
  vitaminSideEffectInfos: IngredientDetail["vitaminSideEffectInfos"];
}

export function SafetySection({
  safetyItems,
  drugInteractions,
  vitaminSideEffectInfos,
}: SafetySectionProps) {
  return (
    <CollapsibleSection
      title="안전성 · 상호작용"
      count={safetyItems.length + drugInteractions.length + vitaminSideEffectInfos.length}
    >
      <div className="space-y-6">
        {/* 안전성 */}
        {(safetyItems.length > 0 || vitaminSideEffectInfos.length > 0) && (
          <div>
            <h4 className="text-sm font-semibold text-ink">안전성 · 주의사항</h4>
            <div className="mt-3 space-y-4">
              {safetyItems.map((si) => (
                <div key={si.id} className="rounded-lg border border-stone-100 p-4">
                  <div className="flex items-start justify-between">
                    <p className="font-medium text-ink">{si.title}</p>
                    {si.severity_level && <SeverityBadge level={si.severity_level} />}
                  </div>
                  <p className="mt-2 text-sm text-ink-muted">{si.description}</p>
                  {si.applies_to_population && (
                    <p className="mt-1 text-xs text-ink-faint">
                      대상: {si.applies_to_population}
                    </p>
                  )}
                  {si.management_advice && (
                    <p className="mt-1 text-xs text-blue-600">
                      관리: {si.management_advice}
                    </p>
                  )}
                </div>
              ))}

              {vitaminSideEffectInfos.map((info) => (
                <div key={info.subgroup} className="rounded-lg border border-amber-200 bg-amber-50 p-4">
                  <p className="font-medium text-amber-900">{info.subgroup} 부작용 참고</p>
                  <p className="mt-2 text-sm text-amber-900">{info.summary}</p>
                  <p className="mt-1 text-xs text-amber-700">주의: {info.caution}</p>
                  <a
                    href={info.referenceUrl}
                    target="_blank"
                    rel="noreferrer"
                    className="mt-2 inline-block text-xs font-medium text-amber-800 underline decoration-amber-400 underline-offset-2"
                  >
                    NIH ODS 근거 보기
                  </a>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* 약물 상호작용 */}
        {drugInteractions.length > 0 && (
          <div>
            <h4 className="text-sm font-semibold text-ink">약물 상호작용</h4>
            <div className="mt-3 space-y-3">
              {drugInteractions.map((di) => (
                <div key={di.id} className="rounded-lg border border-stone-100 p-4">
                  <div className="flex items-center justify-between">
                    <p className="font-medium text-ink">{di.drug_name}</p>
                    {di.severity_level && <SeverityBadge level={di.severity_level} />}
                  </div>
                  {di.clinical_effect && (
                    <p className="mt-1 text-sm text-ink-muted">{di.clinical_effect}</p>
                  )}
                  {di.recommendation && (
                    <p className="mt-1 text-xs text-blue-600">{di.recommendation}</p>
                  )}
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    </CollapsibleSection>
  );
}
