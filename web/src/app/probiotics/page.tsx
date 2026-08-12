import Link from "next/link";
import type { Metadata } from "next";
import { createClient } from "@/lib/supabase/server";
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card";
import { normalizeProbioticStrainNameForDisplay } from "@/lib/utils";
import { StrainBenefitComparison } from "@/components/probiotic/strain-benefit-comparison";
import {
  buildBenefitGroups,
  PROBIOTIC_BENEFIT_AXES,
  type StrainClaimInput,
} from "@/lib/probiotic-comparison";
import { FlaskConical } from "lucide-react";

export const dynamic = "force-dynamic";

export const metadata: Metadata = {
  title: "유산균 균주별 효능 비교",
  description:
    "유산균은 균주에 따라 유효 효과가 다릅니다. 장건강·면역·정신건강·체지방 효능별로 균주를 근거등급과 함께 비교하세요.",
};

const AXIS_CODES = PROBIOTIC_BENEFIT_AXES.map((axis) => axis.claimCode);

function getClaimMeta<T>(input: T | T[] | null | undefined): T | null {
  return Array.isArray(input) ? input[0] ?? null : input ?? null;
}

export default async function ProbioticsComparePage() {
  const supabase = await createClient();

  const { data: root } = await supabase
    .from("ingredients")
    .select("id")
    .eq("slug", "probiotics")
    .eq("is_published", true)
    .maybeSingle();

  const strains = root
    ? (
        await supabase
          .from("ingredients")
          .select("id, slug, canonical_name_ko, display_name, scientific_name, standardization_info")
          .eq("parent_ingredient_id", root.id)
          .eq("is_published", true)
      ).data ?? []
    : [];

  const strainMeta = new Map(strains.map((s) => [s.id, s]));

  const claimRows = strains.length
    ? ((
        await supabase
          .from("ingredient_claims")
          .select("ingredient_id, evidence_grade, evidence_summary, allowed_expression, is_regulator_approved, claims(claim_code, claim_name_ko)")
          .in("ingredient_id", Array.from(strainMeta.keys()))
      ).data ?? [])
    : [];

  const inputs: StrainClaimInput[] = claimRows
    .map((row): StrainClaimInput | null => {
      const claim = getClaimMeta(row.claims);
      const meta = strainMeta.get(row.ingredient_id);
      if (!claim?.claim_code || !meta) return null;
      if (!AXIS_CODES.includes(claim.claim_code)) return null;
      return {
        ingredientId: row.ingredient_id,
        slug: meta.slug,
        strainName:
          meta.display_name ?? normalizeProbioticStrainNameForDisplay(meta.canonical_name_ko),
        scientificName: meta.scientific_name,
        cfuText: meta.standardization_info,
        claimCode: claim.claim_code,
        claimNameKo: claim.claim_name_ko,
        evidenceGrade: row.evidence_grade,
        evidenceSummary: row.evidence_summary,
        allowedExpression: row.allowed_expression,
        isRegulatorApproved: row.is_regulator_approved === true,
      };
    })
    .filter((v): v is StrainClaimInput => v !== null);

  const groups = buildBenefitGroups(inputs);

  return (
    <div className="mx-auto max-w-4xl px-4 py-12">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900">유산균, 균주에 따라 효과가 다릅니다</h1>
        <p className="mt-3 text-gray-600">
          같은 &ldquo;유산균&rdquo;이라도 균주(strain)마다 입증된 효능과 근거 수준이 다릅니다.
          효능을 먼저 고르면, 그 효능에 강한 균주가 근거 순으로 나열됩니다.
        </p>
        {/* 범례: 규제 vs 학술 분리(법적 요구) */}
        <div className="mt-4 flex flex-wrap gap-x-6 gap-y-2 rounded-xl border border-gray-100 bg-gray-50 p-4 text-xs text-gray-600">
          <span><strong className="text-regulatory">식약처 인정</strong> — 규제기관이 기능성을 인정한 균주</span>
          <span><strong className="text-gray-700">근거 A~C</strong> — 학술 연구의 근거 수준(A가 가장 강함)</span>
        </div>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>
            <span className="flex items-center gap-2">
              <FlaskConical className="h-5 w-5 text-orange-700" />
              균주별 효능 비교
            </span>
          </CardTitle>
        </CardHeader>
        <CardContent>
          {groups.length > 0 ? (
            <StrainBenefitComparison groups={groups} />
          ) : (
            <p className="rounded-lg border border-dashed border-gray-200 bg-gray-50 p-4 text-sm text-gray-500">
              비교할 균주 데이터가 아직 준비되지 않았습니다.
            </p>
          )}
        </CardContent>
      </Card>

      {/* 의료 면책 조항 (법적 필수) */}
      <div className="mt-12 rounded-lg border border-yellow-200 bg-yellow-50 p-4 text-xs text-yellow-800">
        <p className="font-medium">의료 면책 조항</p>
        <p className="mt-1">
          본 정보는 의학적 조언이 아닙니다. 건강 관련 결정은 반드시 의료 전문가와 상담하세요.{" "}
          <Link href="/disclaimer" className="underline">
            자세히 보기
          </Link>
        </p>
      </div>
    </div>
  );
}
