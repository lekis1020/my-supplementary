import { notFound } from "next/navigation";
import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import { Badge } from "@/components/ui/badge";
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card";
import {
  getIngredientTypeLabel,
  getEvidenceGradeColor,
  getSeverityColor,
  getClaimScopeLabel,
} from "@/lib/utils";
import { ArrowLeft, AlertTriangle, Pill, FlaskConical, Scale } from "lucide-react";
import type { Metadata } from "next";

export const dynamic = "force-dynamic";

interface Props {
  params: Promise<{ slug: string }>;
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { slug } = await params;
  const supabase = await createClient();
  const { data } = await supabase
    .from("ingredients")
    .select("canonical_name_ko, canonical_name_en, description")
    .eq("slug", slug)
    .single();

  if (!data) return { title: "원료를 찾을 수 없습니다" };

  return {
    title: `${data.canonical_name_ko} (${data.canonical_name_en ?? ""})`,
    description: data.description ?? undefined,
  };
}

export default async function IngredientDetailPage({ params }: Props) {
  const { slug } = await params;
  const supabase = await createClient();

  // 원료 기본 정보
  const { data: ingredient } = await supabase
    .from("ingredients")
    .select("*")
    .eq("slug", slug)
    .eq("is_published", true)
    .single();

  if (!ingredient) notFound();

  // 병렬 쿼리: 기능성, 안전성, 약물상호작용, 용량, 포함 제품
  const [claimsRes, safetyRes, drugRes, dosageRes, productsRes] = await Promise.all([
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
      .select("*, products(*)")
      .eq("ingredient_id", ingredient.id),
  ]);

  const ingredientClaims = claimsRes.data ?? [];
  const safetyItems = safetyRes.data ?? [];
  const drugInteractions = drugRes.data ?? [];
  const dosageGuidelines = dosageRes.data ?? [];
  const productLinks = productsRes.data ?? [];

  return (
    <div className="mx-auto max-w-4xl px-4 py-12">
      {/* Breadcrumb */}
      <Link
        href="/ingredients"
        className="mb-6 inline-flex items-center gap-1 text-sm text-gray-500 hover:text-green-600"
      >
        <ArrowLeft className="h-4 w-4" />
        원료 사전
      </Link>

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
        {/* 기능성/효능 */}
        {ingredientClaims.length > 0 && (
          <Card>
            <CardHeader>
              <CardTitle>
                <span className="flex items-center gap-2">
                  <FlaskConical className="h-5 w-5 text-green-600" />
                  기능성 · 효능
                </span>
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {ingredientClaims.map((ic: any) => (
                  <div key={ic.id} className="rounded-lg border border-gray-100 bg-gray-50 p-4">
                    <div className="flex items-start justify-between">
                      <div>
                        <p className="font-medium text-gray-900">
                          {ic.claims?.claim_name_ko}
                        </p>
                        <Badge className="mt-1 bg-blue-50 text-blue-700">
                          {getClaimScopeLabel(ic.claims?.claim_scope ?? "")}
                        </Badge>
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
                ))}
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
        {productLinks.length > 0 && (
          <Card>
            <CardHeader>
              <CardTitle>이 원료를 포함한 제품</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-2">
                {productLinks.map((pl: any) => (
                  <Link
                    key={pl.id}
                    href={`/products/${pl.products?.id}`}
                    className="flex items-center justify-between rounded-lg border border-gray-100 p-3 transition-colors hover:bg-gray-50"
                  >
                    <div>
                      <p className="font-medium text-gray-900">
                        {pl.products?.product_name}
                      </p>
                      <p className="text-xs text-gray-400">
                        {pl.products?.brand_name}
                      </p>
                    </div>
                    <p className="text-sm text-gray-500">
                      {pl.amount_per_serving} {pl.amount_unit}
                    </p>
                  </Link>
                ))}
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
