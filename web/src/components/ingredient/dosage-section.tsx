// 권장 용량 섹션 for `/ingredients/[slug]`. Moved out of
// `web/src/app/ingredients/[slug]/page.tsx` (former `{/* 권장 용량 */}` Card
// block) as part of the warm-commerce redesign. Server component,
// display-only — dosage guideline fetch stays in `@/lib/data/ingredient-detail`.
import { Badge } from "@/components/ui/badge";
import { CollapsibleSection } from "@/components/ui/collapsible-section";
import type { IngredientDetail } from "@/lib/data/ingredient-detail";

interface DosageSectionProps {
  dosageGuidelines: IngredientDetail["dosageGuidelines"];
}

export function DosageSection({ dosageGuidelines }: DosageSectionProps) {
  return (
    <CollapsibleSection title="권장 용량">
      <div className="overflow-x-auto">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b text-left text-ink-faint">
              <th className="pb-2 pr-4">대상</th>
              <th className="pb-2 pr-4">용량</th>
              <th className="pb-2 pr-4">빈도</th>
              <th className="pb-2 pr-4">유형</th>
              <th className="pb-2">비고</th>
            </tr>
          </thead>
          <tbody className="text-ink-muted">
            {dosageGuidelines.map((dg) => (
              <tr key={dg.id} className="border-b border-stone-100">
                <td className="py-2 pr-4 font-medium">{dg.population_group}</td>
                <td className="py-2 pr-4">
                  {dg.dose_min}
                  {dg.dose_max ? `~${dg.dose_max}` : ""} {dg.dose_unit}
                </td>
                <td className="py-2 pr-4">{dg.frequency_text}</td>
                <td className="py-2 pr-4">
                  <Badge variant="neutral">{dg.recommendation_type}</Badge>
                </td>
                <td className="py-2 text-xs text-ink-faint">{dg.notes}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </CollapsibleSection>
  );
}
