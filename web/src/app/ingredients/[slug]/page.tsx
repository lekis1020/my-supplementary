import { notFound } from "next/navigation";
import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import { BenefitHexagon } from "@/components/benefit/benefit-hexagon";
import { IngredientHero } from "@/components/ingredient/ingredient-hero";
import { ClaimsSection } from "@/components/ingredient/claims-section";
import { EvidenceSection } from "@/components/ingredient/evidence-section";
import { SafetySection } from "@/components/ingredient/safety-section";
import { DosageSection } from "@/components/ingredient/dosage-section";
import { SourcesSection } from "@/components/ingredient/sources-section";
import { RelatedProductsSection } from "@/components/ingredient/related-products-section";
import { getIngredientDetail } from "@/lib/data/ingredient-detail";
import type { Metadata } from "next";

export const dynamic = "force-dynamic";

interface Props {
  params: Promise<{ slug: string }>;
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
  const detail = await getIngredientDetail(slug);
  if (!detail) notFound();

  const {
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
    products: productCount,
    verifiedProducts,
    verifiedProductCount,
    sourceLinks: {
      ingredient: ingredientSourceLinks,
      claim: claimSourceLinks,
      evidence: evidenceSourceLinks,
    },
  } = detail;

  return (
    <div className="mx-auto max-w-4xl px-4 py-12">
      <IngredientHero
        ingredient={ingredient}
        category={category}
        displayIngredientName={displayIngredientName}
        summary={detail.summary}
        hasApprovedClaim={detail.summary.approvedClaimCount > 0}
        isProbiotic={isProbiotic}
        propolisFamilyRoot={propolisFamilyRoot}
        propolisFamilyChildren={propolisFamilyChildren}
      />

      <div className="space-y-8">
        <BenefitHexagon
          title="효능 육각형"
          description="강도 비교가 아니라, 이 원료가 어떤 효능 축에 관련되는지를 빠르게 읽기 위한 요약입니다."
          profile={benefitProfile}
          claimDetails={benefitClaimDetails}
        />

        {/* 기능성/효능 */}
        {mergedIngredientClaims.length > 0 && (
          <ClaimsSection
            claims={mergedIngredientClaims}
            ingredientId={ingredient.id}
            relatedIngredientNameMap={relatedIngredientNameMap}
            includeFamilyEvidence={includeFamilyEvidence}
            isFamilyRootPage={isFamilyRootPage}
          />
        )}

        {/* 연구 근거 */}
        <EvidenceSection
          studies={prioritizedEvidenceStudies}
          highlightedStudies={highlightedEvidenceStudies}
          ingredientId={ingredient.id}
          relatedIngredientNameMap={relatedIngredientNameMap}
          includeFamilyEvidence={includeFamilyEvidence}
          isFamilyRootPage={isFamilyRootPage}
        />

        {(ingredientSourceLinks.length > 0 ||
          claimSourceLinks.length > 0 ||
          evidenceSourceLinks.length > 0 ||
          hasEvidenceGap) && (
          <SourcesSection
            sourceLinks={{
              ingredient: ingredientSourceLinks,
              claim: claimSourceLinks,
              evidence: evidenceSourceLinks,
            }}
            hasEvidenceGap={hasEvidenceGap}
            claimsMissingDirectEvidence={claimsMissingDirectEvidence}
          />
        )}

        {/* 안전성 · 상호작용 */}
        {(safetyItems.length > 0 ||
          vitaminSideEffectInfos.length > 0 ||
          drugInteractions.length > 0) && (
          <SafetySection
            safetyItems={safetyItems}
            drugInteractions={drugInteractions}
            vitaminSideEffectInfos={vitaminSideEffectInfos}
          />
        )}

        {/* 권장 용량 */}
        {dosageGuidelines.length > 0 && (
          <DosageSection dosageGuidelines={dosageGuidelines} />
        )}

        {/* 판매중인 관련 제품 */}
        <RelatedProductsSection
          verifiedProducts={verifiedProducts}
          verifiedProductCount={verifiedProductCount}
          productCount={productCount}
          ingredientId={ingredient.id}
          ingredientNameKo={displayIngredientName}
        />
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
