// Data layer for `web/src/app/ingredients/[slug]/page.tsx`.
// Moved out of the page (former L36–420): claim/source-link helpers, the
// base ingredient query, the 7-way parallel fetch, probiotic/propolis
// family resolution, claims/evidence merge, and source-link lookups.
//
// All queries go through the RLS-scoped `@/lib/supabase/server` client —
// never service_role — matching consumer-page conventions elsewhere in the
// app. `getIngredientDetail` returns `null` for "not found" (the page calls
// `notFound()`); every other Supabase query error is thrown with an
// `ingredient-detail: <context>: <message>` prefix so failures surface
// instead of silently rendering an empty page.

import type { QueryData } from "@supabase/supabase-js";
import { createClient } from "@/lib/supabase/server";
import { buildBenefitClaimDetails, buildBenefitProfile } from "@/lib/benefit-profile";
import { getVitaminSideEffectInfosForIngredient } from "@/lib/vitamin-side-effects";
import { getIngredientCategory, normalizeProbioticStrainNameForDisplay } from "@/lib/utils";
import { resolveIngredientFamily, resolvePropolisFamily } from "./ingredient-family";

// ---- shared helpers (re-exported for tests) --------------------------------

/**
 * Unwraps a Supabase embedded-relation value, which comes back as an array
 * when the relation could be one-to-many and as a single object (or null)
 * when it's one-to-one — Postgrest's typing doesn't always disambiguate.
 * Used for both `claims` (on ingredient_claims/evidence_outcomes rows) and
 * `sources` (on source_links rows) — hence "generic"; the page previously
 * defined two identical copies (`getClaimMeta`/`getSourceMeta`) for these.
 */
export function getClaimMeta<T>(input: T | T[] | null | undefined): T | null {
  return Array.isArray(input) ? input[0] ?? null : input ?? null;
}

export function dedupeSourceLinks<
  T extends {
    entity_type: string;
    entity_id: number;
    source_reference: string | null;
    sources?: { source_name: string } | Array<{ source_name: string }> | null;
  },
>(rows: T[]): T[] {
  const map = new Map<string, T>();

  for (const row of rows) {
    const source = getClaimMeta(row.sources);
    const key = [
      row.entity_type,
      row.entity_id,
      source?.source_name ?? "",
      row.source_reference ?? "",
    ].join("|");

    if (!map.has(key)) {
      map.set(key, row);
    }
  }

  return Array.from(map.values());
}

export function getStudyPriority(design: string | null): number {
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

// ---- summary (evidence grade / approved claims / cautions) -----------------

const GRADE_RANK: Record<string, number> = { A: 0, B: 1, C: 2, D: 3, I: 4 };

function gradeRank(grade: string | null): number {
  if (!grade || !(grade in GRADE_RANK)) return Number.POSITIVE_INFINITY;
  return GRADE_RANK[grade];
}

function computeTopEvidenceGrade(claims: Array<{ evidence_grade: string | null }>): string | null {
  let best: string | null = null;
  for (const claim of claims) {
    if (claim.evidence_grade && (best === null || gradeRank(claim.evidence_grade) < gradeRank(best))) {
      best = claim.evidence_grade;
    }
  }
  return best;
}

// ---- main fetch --------------------------------------------------------------

async function fetchIngredientDetail(slug: string) {
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

  const { data: ingredient, error: ingredientError } = await ingredientQuery.single();
  if (ingredientError && ingredientError.code !== "PGRST116") {
    throw new Error(`ingredient-detail: base ingredient: ${ingredientError.message}`);
  }
  if (!ingredient) return null;

  // 판매 확인된 관련 제품 (이미지 우선 정렬은 JS에서) — QueryData로 조인 결과 타입을 도출
  const verifiedProductsQuery = supabase
    .from("product_ingredients")
    .select(
      "id, products!inner(id, product_name, brand_name, product_image_url, sale_url, sale_channel, sale_verified_at)",
      { count: "exact" },
    )
    .eq("ingredient_id", ingredient.id)
    .not("products.sale_verified_at", "is", null)
    .limit(24);
  type VerifiedProductsEmbed = QueryData<typeof verifiedProductsQuery>[number]["products"];
  type VerifiedProduct = VerifiedProductsEmbed extends Array<infer P> ? P : NonNullable<VerifiedProductsEmbed>;

  // 병렬 쿼리: 기능성, 안전성, 약물상호작용, 용량, 포함 제품, 근거논문, 판매확인 제품
  const [claimsRes, safetyRes, drugRes, dosageRes, productsRes, evidenceRes, verifiedProductsRes] = await Promise.all([
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
    verifiedProductsQuery,
  ]);

  if (claimsRes.error) throw new Error(`ingredient-detail: ingredient claims: ${claimsRes.error.message}`);
  if (safetyRes.error) throw new Error(`ingredient-detail: safety items: ${safetyRes.error.message}`);
  if (drugRes.error) throw new Error(`ingredient-detail: drug interactions: ${drugRes.error.message}`);
  if (dosageRes.error) throw new Error(`ingredient-detail: dosage guidelines: ${dosageRes.error.message}`);
  if (productsRes.error) throw new Error(`ingredient-detail: product count: ${productsRes.error.message}`);
  if (evidenceRes.error) throw new Error(`ingredient-detail: evidence studies: ${evidenceRes.error.message}`);
  if (verifiedProductsRes.error) {
    throw new Error(`ingredient-detail: verified products: ${verifiedProductsRes.error.message}`);
  }

  const ingredientClaims = claimsRes.data ?? [];
  const safetyItems = safetyRes.data ?? [];
  const drugInteractions = drugRes.data ?? [];
  const dosageGuidelines = dosageRes.data ?? [];
  const evidenceStudies = evidenceRes.data ?? [];
  const productCount = productsRes.count ?? 0;

  // 판매확인 제품: product 단위 dedupe → 이미지 보유 우선 → 상위 8건
  const verifiedProductMap = new Map<number, VerifiedProduct>();
  for (const row of verifiedProductsRes.data ?? []) {
    const product = Array.isArray(row.products) ? row.products[0] : row.products;
    if (product && !verifiedProductMap.has(product.id)) {
      verifiedProductMap.set(product.id, product);
    }
  }
  const verifiedProducts = Array.from(verifiedProductMap.values())
    .sort((a, b) => Number(b.product_image_url != null) - Number(a.product_image_url != null))
    .slice(0, 8);
  const verifiedProductCount = verifiedProductsRes.count ?? verifiedProducts.length;

  const category = getIngredientCategory(ingredient.ingredient_type);
  const vitaminSideEffectInfos =
    category === "vitamins"
      ? getVitaminSideEffectInfosForIngredient({
          canonicalNameKo: ingredient.canonical_name_ko,
          canonicalNameEn: ingredient.canonical_name_en,
          scientificName: ingredient.scientific_name,
        })
      : [];
  const displayIngredientName = normalizeProbioticStrainNameForDisplay(ingredient.canonical_name_ko);
  const isProbiotic = category === "probiotics";

  // 프로바이오틱스/프로폴리스 패밀리 해석 (원료 자신 + 형제 + 상위 카테고리)
  const family = await resolveIngredientFamily(supabase, ingredient);
  const { propolisFamilyRoot, propolisFamilyChildren } = await resolvePropolisFamily(supabase, ingredient);

  const relatedIngredientIds = family.relatedIngredientIds;
  const relatedIngredientNameMap = new Map<number, string>([
    [ingredient.id, ingredient.canonical_name_ko],
    ...(family.familyRootId !== null && family.familyRootName !== null
      ? ([[family.familyRootId, family.familyRootName]] as const)
      : []),
    ...family.relatedIngredients.map((item) => [item.id, item.canonical_name_ko] as const),
  ]);
  const isFamilyRootPage = family.familyRootId === ingredient.id;
  const includeFamilyEvidence = relatedIngredientIds.length > 1;

  const [relatedClaimsRes, relatedEvidenceRes] = relatedIngredientIds.length > 1
    ? await Promise.all([
        supabase
          .from("ingredient_claims")
          .select("id, ingredient_id, claim_id, evidence_grade, evidence_summary, allowed_expression, claims(claim_name_ko, claim_scope)")
          .in("ingredient_id", relatedIngredientIds),
        supabase
          .from("evidence_studies")
          .select("id, ingredient_id, title, authors, journal_name, publication_year, pmid, external_url, study_design, population_text, sample_size, duration_text, evidence_outcomes(id, effect_direction, effect_size_text, p_value_text, confidence_interval_text, conclusion_summary, claims(claim_code, claim_name_ko))")
          .in("ingredient_id", relatedIngredientIds)
          .eq("included_in_summary", true),
      ])
    : [null, null];

  if (relatedClaimsRes?.error) {
    throw new Error(`ingredient-detail: related ingredient claims: ${relatedClaimsRes.error.message}`);
  }
  if (relatedEvidenceRes?.error) {
    throw new Error(`ingredient-detail: related evidence studies: ${relatedEvidenceRes.error.message}`);
  }

  const mergedIngredientClaims =
    relatedClaimsRes?.data?.length ? relatedClaimsRes.data : ingredientClaims;
  const mergedEvidenceStudies =
    relatedEvidenceRes?.data?.length ? relatedEvidenceRes.data : evidenceStudies;
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
  const claimIds = Array.from(
    new Set(
      mergedIngredientClaims
        .map((claim) => claim.claim_id)
        .filter((value): value is number => Number.isInteger(value)),
    ),
  );
  const evidenceStudyIds = prioritizedEvidenceStudies.map((study) => study.id);

  // 소스링크 3종 — entity_id 필터가 타입별로 달라 단일 .in(entity_type,...) 쿼리로
  // 합치면 "ids가 비었을 때 아예 쿼리하지 않는다"는 기존 스킵 동작을 잃는다
  // (그리고 그 스킵을 .or() 절 안에서 재현하려면 결국 동일한 조건부 분기가 필요해진다).
  // 필터 의미를 그대로 보존하기 위해 병렬화만 적용한다: 3개 쿼리를 Promise.all로 동시 실행.
  const ingredientSourceLinksQuery = supabase
    .from("source_links")
    .select("id, entity_type, entity_id, source_reference, source_excerpt, retrieved_at, sources(source_name, organization_name, source_url)")
    .eq("entity_type", "ingredient")
    .in("entity_id", relatedIngredientIds)
    .order("retrieved_at", { ascending: false });
  type SourceLink = QueryData<typeof ingredientSourceLinksQuery>[number];

  const claimSourceLinksQuery =
    claimIds.length > 0
      ? supabase
          .from("source_links")
          .select("id, entity_type, entity_id, source_reference, source_excerpt, retrieved_at, sources(source_name, organization_name, source_url)")
          .eq("entity_type", "claim")
          .in("entity_id", claimIds)
          .order("retrieved_at", { ascending: false })
      : null;

  const evidenceSourceLinksQuery =
    evidenceStudyIds.length > 0
      ? supabase
          .from("source_links")
          .select("id, entity_type, entity_id, source_reference, source_excerpt, retrieved_at, sources(source_name, organization_name, source_url)")
          .eq("entity_type", "evidence_study")
          .in("entity_id", evidenceStudyIds)
          .order("retrieved_at", { ascending: false })
      : null;

  const emptySourceLinksResult = Promise.resolve({ data: [] as SourceLink[], error: null });

  const [ingredientSourceLinksRes, claimSourceLinksRes, evidenceSourceLinksRes] = await Promise.all([
    ingredientSourceLinksQuery,
    claimSourceLinksQuery ?? emptySourceLinksResult,
    evidenceSourceLinksQuery ?? emptySourceLinksResult,
  ]);

  if (ingredientSourceLinksRes.error) {
    throw new Error(`ingredient-detail: ingredient source links: ${ingredientSourceLinksRes.error.message}`);
  }
  if (claimSourceLinksRes.error) {
    throw new Error(`ingredient-detail: claim source links: ${claimSourceLinksRes.error.message}`);
  }
  if (evidenceSourceLinksRes.error) {
    throw new Error(`ingredient-detail: evidence source links: ${evidenceSourceLinksRes.error.message}`);
  }

  const ingredientSourceLinks = dedupeSourceLinks(ingredientSourceLinksRes.data ?? []);
  const claimSourceLinks = dedupeSourceLinks(claimSourceLinksRes.data ?? []);
  const evidenceSourceLinks = dedupeSourceLinks(evidenceSourceLinksRes.data ?? []);

  const claimNamesWithEvidence = new Set(
    prioritizedEvidenceStudies.flatMap((study) =>
      (study.evidence_outcomes ?? [])
        .map((outcome) => getClaimMeta(outcome.claims)?.claim_name_ko)
        .filter((value): value is string => Boolean(value)),
    ),
  );
  const claimsMissingDirectEvidence = Array.from(
    new Set(
      mergedIngredientClaims
        .map((claim) => getClaimMeta(claim.claims)?.claim_name_ko)
        .filter((value): value is string => Boolean(value))
        .filter((claimName) => !claimNamesWithEvidence.has(claimName)),
    ),
  );
  const hasEvidenceGap = prioritizedEvidenceStudies.length === 0 || claimsMissingDirectEvidence.length > 0;
  const benefitProfile = buildBenefitProfile(mergedIngredientClaims);
  const benefitClaimDetails = buildBenefitClaimDetails(mergedIngredientClaims);

  // summary는 원료 자신의 ingredient_claims 기준으로 계산한다 — 균주 패밀리 병합용
  // relatedClaimsRes select에는 is_regulator_approved가 없고(claims/evidence 병합은
  // 표시 보완 목적), "이 원료의 승인 클레임 수"라는 의미도 병합 전 집합이 맞다.
  const summary = {
    topEvidenceGrade: computeTopEvidenceGrade(ingredientClaims),
    approvedClaimCount: ingredientClaims.filter((claim) => claim.is_regulator_approved === true).length,
    cautionCount: safetyItems.length + drugInteractions.length,
  };

  return {
    ingredient,
    category,
    displayIngredientName,
    isProbiotic,
    vitaminSideEffectInfos,
    propolisFamilyRoot,
    propolisFamilyChildren,
    isFamilyRootPage,
    includeFamilyEvidence,
    relatedIngredientNameMap,
    claims: mergedIngredientClaims,
    benefitProfile,
    benefitClaimDetails,
    evidenceStudies: prioritizedEvidenceStudies,
    highlightedEvidenceStudies,
    hasEvidenceGap,
    claimsMissingDirectEvidence,
    safetyItems,
    drugInteractions,
    dosageGuidelines,
    productCount,
    verifiedProducts,
    verifiedProductCount,
    sourceLinks: {
      ingredient: ingredientSourceLinks,
      claim: claimSourceLinks,
      evidence: evidenceSourceLinks,
    },
    summary,
  };
}

export type IngredientDetail = NonNullable<Awaited<ReturnType<typeof fetchIngredientDetail>>>;

/**
 * Loads everything `/ingredients/[slug]` needs to render, in one call.
 * Returns `null` when no published ingredient matches `slug` (or the
 * numeric id fallback) — the caller is expected to call `notFound()`.
 * Every other Supabase error is thrown (see file header).
 */
export async function getIngredientDetail(slug: string): Promise<IngredientDetail | null> {
  return fetchIngredientDetail(slug);
}
