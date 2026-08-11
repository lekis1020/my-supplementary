// 기능성/효능 섹션 for `/ingredients/[slug]`. Moved out of
// `web/src/app/ingredients/[slug]/page.tsx` (former `{/* 기능성/효능 */}`
// Card block) as part of the warm-commerce redesign. Server component,
// display-only — claim merge logic stays in `@/lib/data/ingredient-detail`.
//
// `claims` is a union: default-path rows (`.select("*, claims(*)")` in
// `ingredient-detail.ts`) and — since Phase 2-2b — the family-merged query
// both carry `is_regulator_approved` / `approval_country_code` on the
// `ingredient_claims` row itself, so verified badges render on strain pages
// too. The `in` guard below stays as a safety net for any future select that
// drops the fields. `claim_scope` (approved_kr / approved_us) is claim
// taxonomy, not per-ingredient approval, and seed data has rows with
// `claim_scope = 'approved_kr'` but `is_regulator_approved = false` — so it
// must never be used to decide the official badge.
import { Badge } from "@/components/ui/badge";
import { CollapsibleSection } from "@/components/ui/collapsible-section";
import { RegulatoryBadge, EvidenceGradeBadge } from "@/components/ui/domain-badges";
import { getClaimMeta, type IngredientDetail } from "@/lib/data/ingredient-detail";
import { getClaimScopeLabel } from "@/lib/utils";

// Both the default select ("*, claims(*)") and the family-merged select carry
// these two columns at runtime (the family select was widened in Phase 2-2b).
// TS still structurally collapses the union down to the narrower shape, so the
// fields aren't visible on `IngredientDetail["claims"][number]`. This local
// optional shape lets the `in` guard below check for — and safely read — them
// without ever assuming they exist, keeping the gate robust if a future select
// drops the columns again.
interface ApprovalFields {
  is_regulator_approved?: boolean;
  approval_country_code?: string | null;
}

interface ClaimsSectionProps {
  claims: IngredientDetail["claims"];
  ingredientId: number;
  relatedIngredientNameMap: Map<number, string>;
  includeFamilyEvidence: boolean;
  isFamilyRootPage: boolean;
}

export function ClaimsSection({
  claims,
  ingredientId,
  relatedIngredientNameMap,
  includeFamilyEvidence,
  isFamilyRootPage,
}: ClaimsSectionProps) {
  return (
    <CollapsibleSection title="기능성 · 효능" count={claims.length} defaultOpen>
      {includeFamilyEvidence && (
        <p className="mb-4 text-sm text-ink-muted">
          {isFamilyRootPage
            ? "프로바이오틱스는 균주별 연구가 많아, 이 페이지에는 하위 균주 근거까지 함께 반영했습니다."
            : "개별 균주 근거가 부족한 경우를 보완하기 위해 상위 프로바이오틱스 및 연관 균주 근거를 함께 반영했습니다."}
        </p>
      )}
      <div className="space-y-4">
        {claims.map((ic) => {
          const claimMeta = getClaimMeta(ic.claims);
          const sourceIngredientName = relatedIngredientNameMap.get(ic.ingredient_id);
          const isRelatedStrainClaim = ic.ingredient_id !== ingredientId && Boolean(sourceIngredientName);
          const claimScope = claimMeta?.claim_scope ?? "";
          const approvalFields = ic as typeof ic & ApprovalFields;
          // Official badge only on verified per-ingredient approval; unknown
          // (field absent, family-merged) or unapproved rows must not
          // display approval. `in` narrows the union so `approval_country_code`
          // is only read once `is_regulator_approved` is known to exist.
          const isVerifiedApproved =
            "is_regulator_approved" in approvalFields && approvalFields.is_regulator_approved === true;

          return (
            <div key={ic.id} className="rounded-lg border border-stone-100 bg-stone-50 p-4">
              <div className="flex items-start justify-between">
                <div>
                  <p className="font-medium text-ink">{claimMeta?.claim_name_ko}</p>
                  <div className="mt-1 flex flex-wrap gap-2">
                    {isVerifiedApproved ? (
                      <RegulatoryBadge countryCode={approvalFields.approval_country_code} />
                    ) : (
                      <Badge variant="neutral">{getClaimScopeLabel(claimScope)}</Badge>
                    )}
                    {isRelatedStrainClaim && (
                      <Badge className="bg-violet-50 text-violet-700">
                        연관 근거: {sourceIngredientName}
                      </Badge>
                    )}
                  </div>
                </div>
                {ic.evidence_grade && <EvidenceGradeBadge grade={ic.evidence_grade} />}
              </div>
              {ic.evidence_summary && (
                <p className="mt-2 text-sm text-ink-muted">{ic.evidence_summary}</p>
              )}
              {ic.allowed_expression && (
                <p className="mt-2 text-xs text-green-700 bg-green-50 rounded px-2 py-1">
                  허용 표현: {ic.allowed_expression}
                </p>
              )}
            </div>
          );
        })}
      </div>
    </CollapsibleSection>
  );
}
