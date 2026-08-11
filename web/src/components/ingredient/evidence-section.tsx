// 연구 근거 섹션 for `/ingredients/[slug]`, including the zero-evidence
// guidance card rendered in its place when no studies are attached. Moved
// out of `web/src/app/ingredients/[slug]/page.tsx` (former `{/* 연구 근거 */}`
// Card + the 근거없음 안내 Card that followed it) as part of the
// warm-commerce redesign. Server component, display-only — study merge and
// prioritization stay in `@/lib/data/ingredient-detail`.
import { BookOpen, ExternalLink } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card";
import { CollapsibleSection } from "@/components/ui/collapsible-section";
import { getClaimMeta, type IngredientDetail } from "@/lib/data/ingredient-detail";
import {
  getEffectDirectionBadgeColor,
  getEffectDirectionLabel,
  getStudyDesignLabel,
} from "@/lib/utils";

interface EvidenceSectionProps {
  studies: IngredientDetail["evidenceStudies"];
  highlightedStudies: IngredientDetail["highlightedEvidenceStudies"];
  ingredientId: number;
  relatedIngredientNameMap: Map<number, string>;
  includeFamilyEvidence: boolean;
  isFamilyRootPage: boolean;
}

export function EvidenceSection({
  studies,
  highlightedStudies,
  ingredientId,
  relatedIngredientNameMap,
  includeFamilyEvidence,
  isFamilyRootPage,
}: EvidenceSectionProps) {
  if (studies.length === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>
            <span className="flex items-center gap-2">
              <BookOpen className="h-5 w-5 text-purple-600" />
              연구 근거
            </span>
          </CardTitle>
          <p className="mt-1 text-sm text-ink-muted">
            현재 이 원료에 대해 페이지에 노출 가능한 요약 논문이 충분히 준비되지 않았습니다.
          </p>
        </CardHeader>
        <CardContent>
          <div className="rounded-xl border border-dashed border-purple-200 bg-purple-50/50 p-4">
            <p className="text-sm text-purple-900">
              근거 업데이트가 진행 중입니다. 아래 <strong>근거 출처 · 업데이트 현황</strong> 섹션에서
              현재 연결된 출처를 먼저 확인할 수 있습니다.
            </p>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <CollapsibleSection title="연구 근거" count={studies.length}>
      <p className="text-sm text-ink-muted">PubMed 등록 학술 연구 {studies.length}건</p>
      {highlightedStudies.length > 0 && (
        <p className="mt-1 text-sm text-ink-muted">
          메타분석, 체계적 문헌고찰, RCT 중심으로 우선 정렬했습니다.
        </p>
      )}
      {highlightedStudies.length > 0 && (
        <div className="mb-4 mt-4 flex flex-wrap gap-2 rounded-xl border border-purple-100 bg-purple-50/60 p-3">
          <Badge className="bg-purple-100 text-purple-800">
            고근거 연구 {highlightedStudies.length}건
          </Badge>
          {includeFamilyEvidence && (
            <span className="text-xs text-purple-800">
              {isFamilyRootPage
                ? "하위 균주 연구를 포함합니다."
                : "상위/연관 균주 연구를 포함합니다."}
            </span>
          )}
        </div>
      )}
      <div className={highlightedStudies.length > 0 ? "space-y-4" : "mt-4 space-y-4"}>
        {studies.map((study) => {
          const outcome = study.evidence_outcomes?.[0];
          const outcomeClaimMeta = getClaimMeta(outcome?.claims);
          const pubmedUrl =
            study.external_url ||
            (study.pmid ? `https://pubmed.ncbi.nlm.nih.gov/${study.pmid}/` : null);
          const firstAuthor = study.authors?.split(",")[0]?.trim();
          const hasMultipleAuthors = study.authors?.includes(",");
          const sourceIngredientName = relatedIngredientNameMap.get(study.ingredient_id);
          const isRelatedStrainStudy = study.ingredient_id !== ingredientId && Boolean(sourceIngredientName);

          return (
            <div key={study.id} className="rounded-lg border border-stone-200 p-4">
              {/* 배지 행 */}
              <div className="mb-2 flex flex-wrap items-center gap-2">
                {study.study_design && (
                  <Badge variant="outline">{getStudyDesignLabel(study.study_design)}</Badge>
                )}
                {isRelatedStrainStudy && (
                  <Badge className="bg-violet-50 text-violet-700">
                    연관 원료 {sourceIngredientName}
                  </Badge>
                )}
                {study.publication_year && (
                  <span className="text-xs text-ink-faint">{study.publication_year}</span>
                )}
                {study.sample_size && (
                  <span className="text-xs text-ink-faint">
                    n=
                    {study.sample_size.toLocaleString()}
                  </span>
                )}
                {outcome?.effect_direction && (
                  <Badge className={getEffectDirectionBadgeColor(outcome.effect_direction)}>
                    {getEffectDirectionLabel(outcome.effect_direction)}
                  </Badge>
                )}
              </div>

              {/* 제목 + PubMed 링크 */}
              {pubmedUrl ? (
                <a
                  href={pubmedUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="group flex items-start gap-2"
                >
                  <h4 className="flex-1 text-sm font-medium text-ink line-clamp-2 group-hover:text-blue-600">
                    {study.title}
                  </h4>
                  <ExternalLink className="mt-0.5 h-4 w-4 flex-shrink-0 text-stone-300 group-hover:text-blue-500" />
                </a>
              ) : (
                <h4 className="text-sm font-medium text-ink line-clamp-2">{study.title}</h4>
              )}

              {/* 저널 · 저자 */}
              <p className="mt-1 text-xs text-ink-faint">
                {study.journal_name}
                {firstAuthor && ` · ${firstAuthor}${hasMultipleAuthors ? " et al." : ""}`}
              </p>

              {/* 대상 · 기간 */}
              {(study.population_text || study.duration_text) && (
                <p className="mt-1 text-xs text-ink-faint">
                  {study.population_text}
                  {study.duration_text && study.duration_text !== "-" && ` · ${study.duration_text}`}
                </p>
              )}

              {/* 결과 요약 */}
              {outcome?.conclusion_summary && (
                <div className="mt-3 rounded-md bg-stone-50 p-3">
                  {outcomeClaimMeta?.claim_name_ko && (
                    <p className="mb-1 text-xs font-medium text-purple-600">
                      {outcomeClaimMeta.claim_name_ko}
                    </p>
                  )}
                  <p className="text-sm leading-relaxed text-ink">{outcome.conclusion_summary}</p>
                  {(outcome.effect_size_text || outcome.p_value_text) && (
                    <div className="mt-2 flex flex-wrap gap-x-3 gap-y-1 text-xs text-ink-faint">
                      {outcome.effect_size_text && <span>효과크기: {outcome.effect_size_text}</span>}
                      {outcome.p_value_text && outcome.p_value_text !== "-" && (
                        <span>{outcome.p_value_text}</span>
                      )}
                      {outcome.confidence_interval_text && outcome.confidence_interval_text !== "-" && (
                        <span>CI: {outcome.confidence_interval_text}</span>
                      )}
                    </div>
                  )}
                </div>
              )}
            </div>
          );
        })}
      </div>
    </CollapsibleSection>
  );
}
