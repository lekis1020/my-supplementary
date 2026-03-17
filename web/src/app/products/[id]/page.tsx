import { notFound } from "next/navigation";
import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import { BenefitHexagon } from "@/components/benefit/benefit-hexagon";
import { Badge } from "@/components/ui/badge";
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card";
import { buildBenefitProfile } from "@/lib/benefit-profile";
import { getIngredientHref } from "@/lib/utils";
import { ArrowLeft, Tag, FileText } from "lucide-react";
import type { Metadata } from "next";

export const dynamic = "force-dynamic";

interface Props {
  params: Promise<{ id: string }>;
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { id } = await params;
  const supabase = await createClient();
  const { data } = await supabase
    .from("products")
    .select("product_name, brand_name")
    .eq("id", Number(id))
    .single();

  if (!data) return { title: "제품을 찾을 수 없습니다" };
  return {
    title: `${data.product_name} — ${data.brand_name ?? ""}`,
  };
}

export default async function ProductDetailPage({ params }: Props) {
  const { id } = await params;
  const supabase = await createClient();

  const { data: product } = await supabase
    .from("products")
    .select("*")
    .eq("id", Number(id))
    .eq("is_published", true)
    .single();

  if (!product) notFound();

  const [ingredientsRes, labelsRes] = await Promise.all([
    supabase
      .from("product_ingredients")
      .select("*, ingredients(id, canonical_name_ko, canonical_name_en, slug, ingredient_type)")
      .eq("product_id", product.id),
    supabase
      .from("label_snapshots")
      .select("*")
      .eq("product_id", product.id)
      .eq("is_current", true)
      .limit(1),
  ]);

  const productIngredients = ingredientsRes.data ?? [];
  const label = labelsRes.data?.[0] ?? null;
  const ingredientIds = productIngredients
    .map((pi: any) => pi.ingredients?.id)
    .filter((value: number | null | undefined): value is number => Number.isInteger(value));
  const productClaims = ingredientIds.length > 0
    ? (
        await supabase
          .from("ingredient_claims")
          .select("ingredient_id, evidence_grade, is_regulator_approved, claims(claim_category, claim_scope)")
          .in("ingredient_id", ingredientIds)
      ).data ?? []
    : [];
  const benefitProfile = buildBenefitProfile(productClaims as any[]);

  return (
    <div className="mx-auto max-w-4xl px-4 py-12">
      <Link
        href="/products"
        className="mb-6 inline-flex items-center gap-1 text-sm text-gray-500 hover:text-green-600"
      >
        <ArrowLeft className="h-4 w-4" />
        제품 목록
      </Link>

      {/* Header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900">{product.product_name}</h1>
        <div className="mt-2 flex flex-wrap gap-2 text-sm text-gray-500">
          {product.brand_name && <span>브랜드: {product.brand_name}</span>}
          {product.manufacturer_name && (
            <>
              <span className="text-gray-300">·</span>
              <span>제조: {product.manufacturer_name}</span>
            </>
          )}
          {product.country_code && (
            <Badge className="bg-gray-100 text-gray-600">
              {product.country_code === "KR" ? "🇰🇷 한국" : "🇺🇸 미국"}
            </Badge>
          )}
          {product.product_type && (
            <Badge className="bg-blue-50 text-blue-700">
              {product.product_type === "health_functional_food"
                ? "건강기능식품"
                : "Dietary Supplement"}
            </Badge>
          )}
        </div>
      </div>

      <div className="space-y-8">
        <BenefitHexagon
          title="제품 효능 육각형"
          description="포함된 원료의 기능성 데이터를 묶어, 이 제품이 어느 효능 축을 커버하는지 요약한 시각화입니다."
          profile={benefitProfile}
        />

        {/* 원료 조성 */}
        <Card>
          <CardHeader>
            <CardTitle>
              <span className="flex items-center gap-2">
                <Tag className="h-5 w-5 text-green-600" />
                원료 조성 ({productIngredients.length}종)
              </span>
            </CardTitle>
          </CardHeader>
          <CardContent>
            {productIngredients.length === 0 ? (
              <p className="text-sm text-gray-400">원료 정보가 없습니다.</p>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead>
                    <tr className="border-b text-left text-gray-500">
                      <th className="pb-2 pr-4">원료명</th>
                      <th className="pb-2 pr-4">1회 함량</th>
                      <th className="pb-2 pr-4">역할</th>
                      <th className="pb-2">라벨 표기명</th>
                    </tr>
                  </thead>
                  <tbody className="text-gray-700">
                    {productIngredients.map((pi: any) => (
                      <tr key={pi.id} className="border-b border-gray-50">
                        <td className="py-2.5 pr-4">
                          <Link
                            href={getIngredientHref({
                              id: pi.ingredients?.id,
                              slug: pi.ingredients?.slug,
                            })}
                            className="font-medium text-green-600 hover:underline"
                          >
                            {pi.ingredients?.canonical_name_ko}
                          </Link>
                        </td>
                        <td className="py-2.5 pr-4">
                          {pi.amount_per_serving} {pi.amount_unit}
                        </td>
                        <td className="py-2.5 pr-4">
                          <Badge className="bg-gray-100 text-gray-600">
                            {pi.ingredient_role === "active" ? "주성분" : pi.ingredient_role}
                          </Badge>
                        </td>
                        <td className="py-2.5 text-xs text-gray-400">
                          {pi.raw_label_name}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </CardContent>
        </Card>

        {/* 라벨 정보 */}
        {label && (
          <Card>
            <CardHeader>
              <CardTitle>
                <span className="flex items-center gap-2">
                  <FileText className="h-5 w-5 text-blue-500" />
                  라벨 정보
                </span>
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-3 text-sm">
                {label.serving_size_text && (
                  <InfoRow label="1회 섭취량" value={label.serving_size_text} />
                )}
                {label.servings_per_container && (
                  <InfoRow label="총 내용량" value={label.servings_per_container} />
                )}
                {label.directions_text && (
                  <InfoRow label="섭취 방법" value={label.directions_text} />
                )}
                {label.warning_text && (
                  <div className="rounded-lg border border-yellow-200 bg-yellow-50 p-3">
                    <p className="font-medium text-yellow-800">주의사항</p>
                    <p className="mt-1 text-yellow-700">{label.warning_text}</p>
                  </div>
                )}
                {label.storage_text && (
                  <InfoRow label="보관 방법" value={label.storage_text} />
                )}
              </div>
            </CardContent>
          </Card>
        )}
      </div>
    </div>
  );
}

function InfoRow({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex gap-4">
      <span className="w-24 shrink-0 font-medium text-gray-500">{label}</span>
      <span className="text-gray-700">{value}</span>
    </div>
  );
}
