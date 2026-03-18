import { notFound } from "next/navigation";
import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import { Badge } from "@/components/ui/badge";
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card";
import { BenefitHexagon } from "@/components/benefit/benefit-hexagon";
import { buildBenefitClaimDetails, buildBenefitProfile } from "@/lib/benefit-profile";
import {
  getIngredientCategory,
  getIngredientCategoryLabel,
  getIngredientTypeLabel,
  getEvidenceGradeColor,
  getSeverityColor,
  getClaimScopeLabel,
  getStudyDesignLabel,
  getStudyDesignColor,
  getEffectDirectionLabel,
  getEffectDirectionBadgeColor,
} from "@/lib/utils";
import {
  ArrowLeft, AlertTriangle, Pill, FlaskConical, Scale, BookOpen, ExternalLink,
} from "lucide-react";
import type { Metadata } from "next";

export const dynamic = "force-dynamic";

interface Props {
  params: Promise<{ slug: string }>;
}

interface RelatedIngredientRow {
  id: number;
  canonical_name_ko: string;
  canonical_name_en: string | null;
  scientific_name: string | null;
}

interface ClaimMetaRow {
  claim_name_ko?: string | null;
  claim_scope?: string | null;
}

interface IngredientClaimRow {
  id: number;
  ingredient_id: number;
  evidence_grade: string | null;
  evidence_summary: string | null;
  allowed_expression: string | null;
  claims: ClaimMetaRow | ClaimMetaRow[] | null;
}

interface EvidenceOutcomeRow {
  id: number;
  effect_direction: string | null;
  effect_size_text: string | null;
  p_value_text: string | null;
  confidence_interval_text: string | null;
  conclusion_summary: string | null;
  claims?: {
    claim_code?: string | null;
    claim_name_ko?: string | null;
  } | null;
}

interface EvidenceStudyRow {
  id: number;
  ingredient_id: number;
  title: string;
  authors: string | null;
  journal_name: string | null;
  publication_year: number | null;
  pmid: string | null;
  external_url: string | null;
  study_design: string | null;
  population_text: string | null;
  sample_size: number | null;
  duration_text: string | null;
  evidence_outcomes?: EvidenceOutcomeRow[] | null;
}

function getClaimMeta(input: ClaimMetaRow | ClaimMetaRow[] | null | undefined) {
  return Array.isArray(input) ? input[0] ?? null : input ?? null;
}

function getStudyPriority(design: string | null): number {
  switch (design) {
    case "meta_analysis":
      return 5;
    case "systematic_review":
      return 4;
    case "guideline":
      return 4;
    case "rct":
      return 3;
    case "cohort":
      return 2;
    case "case_control":
      return 1;
    default:
      return 0;
  }
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { slug } = await params;
  const supabase = await createClient();
  const numericId = Number(slug);
  let query = supabase
    .from("ingredients")
    .select("canonical_name_ko, canonical_name_en, description")
    .eq("slug", slug);

  if (Number.isInteger(numericId) && numericId > 0) {
    query = supabase
      .from("ingredients")
      .select("canonical_name_ko, canonical_name_en, description")
      .eq("id", numericId);
  }

  const { data } = await query.single();

  if (!data) return { title: "원료를 찾을 수 없습니다" };

  return {
    title: `${data.canonical_name_ko} (${data.canonical_name_en ?? ""})`,
    description: data.description ?? undefined,
  };
}

export default async function IngredientDetailPage({ params }: Props) {
  const { slug } = await params;
  const supabase = await createClient();
  const numericId = Number(slug);

  // 원료 기본 정보
  let ingredientQuery = supabase
    .from("ingredients")
    .select("*")
    .eq("slug", slug)
    .eq("is_published", true);

  if (Number.isInteger(numericId) && numericId > 0) {
    ingredientQuery = supabase
      .from("ingredients")
      .select("*")
      .eq("id", numericId)
      .eq("is_published", true);
  }

  const { data: ingredient } = await ingredientQuery.single();

  if (!ingredient) notFound();

  // 병렬 쿼리: 기능성, 안전성, 약물상호작용, 용량, 포함 제품
  const [claimsRes, safetyRes, drugRes, dosageRes, productsRes, evidenceRes] = await Promise.all([
    supabase
      .from("ingredient_claims")
      .select("*, claims(*)")
      .eq("ingredient_id", ingredient.id),
    supabase
      .from("safety_items")
      .select("*")
      .eq("ingredient_id", ingredient.id)
      .order("severity_level"),
    supabase
      .from("ingredient_drug_interactions")
      .select("*")
      .eq("ingredient_id", ingredient.id),
    supabase
      .from("dosage_guidelines")
      .select("*")
      .eq("ingredient_id", ingredient.id),
    supabase
      .from("product_ingredients")
      .select("id, amount_per_serving, amount_unit, products!inner(id, product_name, brand_name)", {
        count: "exact",
      })
      .eq("ingredient_id", ingredient.id)
      .limit(3),
    supabase
      .from("evidence_studies")
      .select("*, evidence_outcomes(*, claims(claim_code, claim_name_ko))")
      .eq("ingredient_id", ingredient.id)
      .eq("included_in_summary", true)
      .order("publication_year", { ascending: false }),
  ]);

  const ingredientClaims = claimsRes.data ?? [];
  const safetyItems = safetyRes.data ?? [];
  const drugInteractions = drugRes.data ?? [];
  const dosageGuidelines = dosageRes.data ?? [];
  const evidenceStudies = evidenceRes.data ?? [];
  const productLinks = productsRes.data ?? [];
  const productCount = productsRes.count ?? productLinks.length;
  const category = getIngredientCategory(ingredient.ingredient_type);
  const relatedIngredients = category === "probiotics"
    ? (
        (
          await supabase
            .from("ingredients")
            .select("id, canonical_name_ko, canonical_name_en, scientific_name")
            .eq("parent_ingredient_id", ingredient.id)
            .eq("is_published", true)
            .order("canonical_name_ko")
        ).data ?? []
      )
    : [];
  const relatedIngredientIds = [ingredient.id, ...relatedIngredients.map((item) => item.id)];
  const relatedIngredientNameMap = new Map<number, string>([
    [ingredient.id, ingredient.canonical_name_ko],
    ...relatedIngredients.map((item) => [item.id, item.canonical_name_ko] as const),
  ]);

  const [relatedClaimsRes, relatedEvidenceRes] = relatedIngredientIds.length > 1
    ? await Promise.all([
        supabase
          .from("ingredient_claims")
          .select("id, ingredient_id, evidence_grade, evidence_summary, allowed_expression, claims(claim_name_ko, claim_scope)")
          .in("ingredient_id", relatedIngredientIds),
        supabase
          .from("evidence_studies")
          .select("id, ingredient_id, title, authors, journal_name, publication_year, pmid, external_url, study_design, population_text, sample_size, duration_text, evidence_outcomes(id, effect_direction, effect_size_text, p_value_text, confidence_interval_text, conclusion_summary, claims(claim_code, claim_name_ko))")
          .in("ingredient_id", relatedIngredientIds)
          .eq("included_in_summary", true),
      ])
    : [null, null];

  const mergedIngredientClaims = (
    relatedClaimsRes?.data?.length ? relatedClaimsRes.data : ingredientClaims
  ) as IngredientClaimRow[];
  const mergedEvidenceStudies = (
    relatedEvidenceRes?.data?.length ? relatedEvidenceRes.data : evidenceStudies
  ) as EvidenceStudyRow[];
  const prioritizedEvidenceStudies = [...mergedEvidenceStudies].sort((left, right) => {
    const studyPriorityDiff = getStudyPriority(right.study_design) - getStudyPriority(left.study_design);
    if (studyPriorityDiff !== 0) {
      return studyPriorityDiff;
    }

    return (right.publication_year ?? 0) - (left.publication_year ?? 0);
  });
  const highlightedEvidenceStudies = prioritizedEvidenceStudies.filter(
    (study) => getStudyPriority(study.study_design) >= 3,
  );
  const benefitProfile = buildBenefitProfile(mergedIngredientClaims);
  const benefitClaimDetails = buildBenefitClaimDetails(mergedIngredientClaims);

  return (
    <div className="mx-auto max-w-4xl px-4 py-12">
      {/* Breadcrumb */}
      <div className="mb-6 flex flex-wrap items-center gap-2 text-sm text-gray-500">
        <Link href="/ingredients" className="inline-flex items-center gap-1 hover:text-green-600">
          <ArrowLeft className="h-4 w-4" />
          원료 사전
        </Link>
        <span>/</span>
        <Link
          href={`/ingredients/category/${category}`}
          className="hover:text-green-600"
        >
          {getIngredientCategoryLabel(category)}
        </Link>
        <span>/</span>
        <span className="font-medium text-gray-700">{ingredient.canonical_name_ko}</span>
      </div>

      {/* Header */}
      <div className="mb-8">
        <div className="flex items-center gap-3">
          <h1 className="text-3xl font-bold text-gray-900">
            {ingredient.canonical_name_ko}
          </h1>
          <Badge className="bg-gray-100 text-gray-600">
            {getIngredientTypeLabel(ingredient.ingredient_type)}
          </Badge>
        </div>
        {ingredient.canonical_name_en && (
          <p className="mt-1 text-lg text-gray-400">{ingredient.canonical_name_en}</p>
        )}
        {ingredient.scientific_name && (
          <p className="text-sm italic text-gray-400">{ingredient.scientific_name}</p>
        )}
        {ingredient.description && (
          <p className="mt-4 text-gray-600">{ingredient.description}</p>
        )}
        {ingredient.form_description && (
          <p className="mt-2 text-sm text-gray-500">
            <strong>주요 형태:</strong> {ingredient.form_description}
          </p>
        )}
        {ingredient.standardization_info && (
          <p className="text-sm text-gray-500">
            <strong>표준화:</strong> {ingredient.standardization_info}
          </p>
        )}
      </div>

      <div className="space-y-8">
        <BenefitHexagon
          title="효능 육각형"
          description="강도 비교가 아니라, 이 원료가 어떤 효능 축에 관련되는지를 빠르게 읽기 위한 요약입니다."
          profile={benefitProfile}
          claimDetails={benefitClaimDetails}
        />

        {/* 기능성/효능 */}
        {mergedIngredientClaims.length > 0 && (
          <Card>
            <CardHeader>
              <CardTitle>
                <span className="flex items-center gap-2">
                  <FlaskConical className="h-5 w-5 text-green-600" />
                  기능성 · 효능
                </span>
              </CardTitle>
              {relatedIngredients.length > 0 && (
                <p className="mt-1 text-sm text-gray-500">
                  프로바이오틱스는 균주별 연구가 많아, 이 페이지에는 하위 균주 근거까지 함께 반영했습니다.
                </p>
              )}
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {mergedIngredientClaims.map((ic) => {
                  const claimMeta = getClaimMeta(ic.claims);
                  const sourceIngredientName = relatedIngredientNameMap.get(ic.ingredient_id);
                  const isRelatedStrainClaim = ic.ingredient_id !== ingredient.id && Boolean(sourceIngredientName);

                  return (
                  <div key={ic.id} className="rounded-lg border border-gray-100 bg-gray-50 p-4">
                    <div className="flex items-start justify-between">
                      <div>
                        <p className="font-medium text-gray-900">
                          {claimMeta?.claim_name_ko}
                        </p>
                        <div className="mt-1 flex flex-wrap gap-2">
                          <Badge className="bg-blue-50 text-blue-700">
                            {getClaimScopeLabel(claimMeta?.claim_scope ?? "")}
                          </Badge>
                          {isRelatedStrainClaim && (
                            <Badge className="bg-violet-50 text-violet-700">
                              균주 근거: {sourceIngredientName}
                            </Badge>
                          )}
                        </div>
                      </div>
                      {ic.evidence_grade && (
                        <Badge className={getEvidenceGradeColor(ic.evidence_grade)}>
                          근거 {ic.evidence_grade}
                        </Badge>
                      )}
                    </div>
                    {ic.evidence_summary && (
                      <p className="mt-2 text-sm text-gray-500">{ic.evidence_summary}</p>
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
            </CardContent>
          </Card>
        )}

        {/* 연구 근거 */}
        {prioritizedEvidenceStudies.length > 0 && (
          <Card>
            <CardHeader>
              <CardTitle>
                <span className="flex items-center gap-2">
                  <BookOpen className="h-5 w-5 text-purple-600" />
                  연구 근거
                </span>
              </CardTitle>
              <p className="mt-1 text-sm text-gray-500">
                PubMed 등록 학술 연구 {prioritizedEvidenceStudies.length}건
              </p>
              {highlightedEvidenceStudies.length > 0 && (
                <p className="mt-1 text-sm text-gray-500">
                  메타분석, 체계적 문헌고찰, RCT 중심으로 우선 정렬했습니다.
                </p>
              )}
            </CardHeader>
            <CardContent>
              {highlightedEvidenceStudies.length > 0 && (
                <div className="mb-4 flex flex-wrap gap-2 rounded-xl border border-purple-100 bg-purple-50/60 p-3">
                  <Badge className="bg-purple-100 text-purple-800">
                    고근거 연구 {highlightedEvidenceStudies.length}건
                  </Badge>
                  {relatedIngredients.length > 0 && (
                    <span className="text-xs text-purple-800">
                      하위 균주 연구를 포함합니다.
                    </span>
                  )}
                </div>
              )}
              <div className="space-y-4">
                {prioritizedEvidenceStudies.map((study) => {
                  const outcome = study.evidence_outcomes?.[0];
                  const pubmedUrl =
                    study.external_url ||
                    (study.pmid
                      ? `https://pubmed.ncbi.nlm.nih.gov/${study.pmid}/`
                      : null);
                  const firstAuthor = study.authors
                    ?.split(",")[0]
                    ?.trim();
                  const hasMultipleAuthors =
                    study.authors?.includes(",");
                  const sourceIngredientName = relatedIngredientNameMap.get(study.ingredient_id);
                  const isRelatedStrainStudy = study.ingredient_id !== ingredient.id && Boolean(sourceIngredientName);

                  return (
                    <div
                      key={study.id}
                      className="rounded-lg border border-gray-200 p-4"
                    >
                      {/* 배지 행 */}
                      <div className="mb-2 flex flex-wrap items-center gap-2">
                        {study.study_design && (
                          <Badge
                            className={getStudyDesignColor(
                              study.study_design,
                            )}
                          >
                            {getStudyDesignLabel(study.study_design)}
                          </Badge>
                        )}
                        {isRelatedStrainStudy && (
                          <Badge className="bg-violet-50 text-violet-700">
                            균주 {sourceIngredientName}
                          </Badge>
                        )}
                        {study.publication_year && (
                          <span className="text-xs text-gray-400">
                            {study.publication_year}
                          </span>
                        )}
                        {study.sample_size && (
                          <span className="text-xs text-gray-400">
                            n=
                            {study.sample_size.toLocaleString()}
                          </span>
                        )}
                        {outcome?.effect_direction && (
                          <Badge
                            className={getEffectDirectionBadgeColor(
                              outcome.effect_direction,
                            )}
                          >
                            {getEffectDirectionLabel(
                              outcome.effect_direction,
                            )}
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
                          <h4 className="flex-1 text-sm font-medium text-gray-900 line-clamp-2 group-hover:text-blue-600">
                            {study.title}
                          </h4>
                          <ExternalLink className="mt-0.5 h-4 w-4 flex-shrink-0 text-gray-300 group-hover:text-blue-500" />
                        </a>
                      ) : (
                        <h4 className="text-sm font-medium text-gray-900 line-clamp-2">
                          {study.title}
                        </h4>
                      )}

                      {/* 저널 · 저자 */}
                      <p className="mt-1 text-xs text-gray-400">
                        {study.journal_name}
                        {firstAuthor &&
                          ` · ${firstAuthor}${hasMultipleAuthors ? " et al." : ""}`}
                      </p>

                      {/* 대상 · 기간 */}
                      {(study.population_text ||
                        study.duration_text) && (
                        <p className="mt-1 text-xs text-gray-400">
                          {study.population_text}
                          {study.duration_text &&
                            study.duration_text !== "-" &&
                            ` · ${study.duration_text}`}
                        </p>
                      )}

                      {/* 결과 요약 */}
                      {outcome?.conclusion_summary && (
                        <div className="mt-3 rounded-md bg-gray-50 p-3">
                          {outcome.claims?.claim_name_ko && (
                            <p className="mb-1 text-xs font-medium text-purple-600">
                              {outcome.claims.claim_name_ko}
                            </p>
                          )}
                          <p className="text-sm leading-relaxed text-gray-700">
                            {outcome.conclusion_summary}
                          </p>
                          {(outcome.effect_size_text ||
                            outcome.p_value_text) && (
                            <div className="mt-2 flex flex-wrap gap-x-3 gap-y-1 text-xs text-gray-400">
                              {outcome.effect_size_text && (
                                <span>
                                  효과크기:{" "}
                                  {outcome.effect_size_text}
                                </span>
                              )}
                              {outcome.p_value_text &&
                                outcome.p_value_text !== "-" && (
                                  <span>
                                    {outcome.p_value_text}
                                  </span>
                                )}
                              {outcome.confidence_interval_text &&
                                outcome.confidence_interval_text !==
                                  "-" && (
                                  <span>
                                    CI:{" "}
                                    {
                                      outcome.confidence_interval_text
                                    }
                                  </span>
                                )}
                            </div>
                          )}
                        </div>
                      )}
                    </div>
                  );
                })}
              </div>
            </CardContent>
          </Card>
        )}

        {/* 안전성 */}
        {safetyItems.length > 0 && (
          <Card>
            <CardHeader>
              <CardTitle>
                <span className="flex items-center gap-2">
                  <AlertTriangle className="h-5 w-5 text-orange-500" />
                  안전성 · 주의사항
                </span>
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {safetyItems.map((si: any) => (
                  <div key={si.id} className="rounded-lg border border-gray-100 p-4">
                    <div className="flex items-start justify-between">
                      <p className="font-medium text-gray-900">{si.title}</p>
                      {si.severity_level && (
                        <Badge className={getSeverityColor(si.severity_level)}>
                          {si.severity_level}
                        </Badge>
                      )}
                    </div>
                    <p className="mt-2 text-sm text-gray-600">{si.description}</p>
                    {si.applies_to_population && (
                      <p className="mt-1 text-xs text-gray-400">
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
              </div>
            </CardContent>
          </Card>
        )}

        {/* 약물 상호작용 */}
        {drugInteractions.length > 0 && (
          <Card>
            <CardHeader>
              <CardTitle>
                <span className="flex items-center gap-2">
                  <Pill className="h-5 w-5 text-red-500" />
                  약물 상호작용
                </span>
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-3">
                {drugInteractions.map((di: any) => (
                  <div key={di.id} className="rounded-lg border border-gray-100 p-4">
                    <div className="flex items-center justify-between">
                      <p className="font-medium text-gray-900">{di.drug_name}</p>
                      {di.severity_level && (
                        <Badge className={getSeverityColor(di.severity_level)}>
                          {di.severity_level}
                        </Badge>
                      )}
                    </div>
                    {di.clinical_effect && (
                      <p className="mt-1 text-sm text-gray-600">{di.clinical_effect}</p>
                    )}
                    {di.recommendation && (
                      <p className="mt-1 text-xs text-blue-600">{di.recommendation}</p>
                    )}
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        )}

        {/* 권장 용량 */}
        {dosageGuidelines.length > 0 && (
          <Card>
            <CardHeader>
              <CardTitle>
                <span className="flex items-center gap-2">
                  <Scale className="h-5 w-5 text-blue-500" />
                  권장 용량
                </span>
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead>
                    <tr className="border-b text-left text-gray-500">
                      <th className="pb-2 pr-4">대상</th>
                      <th className="pb-2 pr-4">용량</th>
                      <th className="pb-2 pr-4">빈도</th>
                      <th className="pb-2 pr-4">유형</th>
                      <th className="pb-2">비고</th>
                    </tr>
                  </thead>
                  <tbody className="text-gray-700">
                    {dosageGuidelines.map((dg: any) => (
                      <tr key={dg.id} className="border-b border-gray-50">
                        <td className="py-2 pr-4 font-medium">{dg.population_group}</td>
                        <td className="py-2 pr-4">
                          {dg.dose_min}
                          {dg.dose_max ? `~${dg.dose_max}` : ""} {dg.dose_unit}
                        </td>
                        <td className="py-2 pr-4">{dg.frequency_text}</td>
                        <td className="py-2 pr-4">
                          <Badge className="bg-gray-100 text-gray-600">
                            {dg.recommendation_type}
                          </Badge>
                        </td>
                        <td className="py-2 text-xs text-gray-400">{dg.notes}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </CardContent>
          </Card>
        )}

        {/* 이 원료를 포함한 제품 */}
        {productCount > 0 && (
          <Card>
            <CardHeader>
              <CardTitle>이 원료를 포함한 제품</CardTitle>
              <p className="text-sm text-gray-500">
                총 {productCount.toLocaleString()}개 제품이 이 원료를 포함하고 있습니다.
              </p>
            </CardHeader>
            <CardContent>
              <div className="rounded-2xl border border-gray-100 bg-gray-50 p-4">
                <p className="text-sm leading-6 text-gray-600">
                  개별 제품을 이 페이지에서 길게 펼치기보다, 제품 목록에서 이 원료를 기준으로
                  탐색하는 편이 더 효율적입니다.
                </p>
                {productLinks.length > 0 && (
                  <div className="mt-4 flex flex-wrap gap-2">
                    {productLinks.map((pl: any) => (
                      <span
                        key={pl.id}
                        className="inline-flex rounded-full border border-gray-200 bg-white px-3 py-1 text-xs font-medium text-gray-600"
                      >
                        {pl.products?.product_name}
                      </span>
                    ))}
                    {productCount > productLinks.length && (
                      <span className="inline-flex rounded-full border border-dashed border-gray-300 px-3 py-1 text-xs font-medium text-gray-500">
                        외 {(productCount - productLinks.length).toLocaleString()}개
                      </span>
                    )}
                  </div>
                )}
                <Link
                  href={`/products?ingredientId=${ingredient.id}`}
                  className="mt-5 inline-flex items-center rounded-xl bg-green-600 px-4 py-2 text-sm font-semibold text-white transition-colors hover:bg-green-700"
                >
                  제품 목록에서 보기
                </Link>
              </div>
            </CardContent>
          </Card>
        )}
      </div>

      {/* 면책 조항 */}
      <div className="mt-12 rounded-lg border border-yellow-200 bg-yellow-50 p-4 text-xs text-yellow-800">
        <p className="font-medium">의료 면책 조항</p>
        <p className="mt-1">
          본 정보는 의학적 조언이 아닙니다. 건강 관련 결정은 반드시 의료 전문가와
          상담하세요.{" "}
          <Link href="/disclaimer" className="underline">
            자세히 보기
          </Link>
        </p>
      </div>
    </div>
  );
}
