import { notFound } from "next/navigation";
import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import { BenefitHexagon } from "@/components/benefit/benefit-hexagon";
import { Badge } from "@/components/ui/badge";
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card";
import { buildBenefitProfile } from "@/lib/benefit-profile";
import { cn, getIngredientHref } from "@/lib/utils";
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

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8 items-start">
        {/* Left Content: Ingredients Table (2/3 width) */}
        <div className="lg:col-span-2 space-y-8">
          {/* 원료 조성 */}
          <Card className="border-slate-200 shadow-sm overflow-hidden">
            <CardHeader className="bg-slate-50/50 border-b border-slate-100">
              <CardTitle className="text-lg font-black text-slate-900 flex items-center gap-2">
                <Tag className="h-5 w-5 text-emerald-500" />
                원료 조성 ({productIngredients.length}종)
              </CardTitle>
            </CardHeader>
            <CardContent className="p-0">
              {productIngredients.length === 0 ? (
                <div className="p-8 text-center">
                  <p className="text-sm text-slate-400">원료 정보가 아직 등록되지 않았습니다.</p>
                </div>
              ) : (
                <div className="overflow-x-auto">
                  <table className="w-full text-sm">
                    <thead>
                      <tr className="bg-slate-50/30 text-left text-slate-500 border-b border-slate-100">
                        <th className="px-6 py-4 font-bold uppercase tracking-wider text-[11px]">원료명</th>
                        <th className="px-6 py-4 font-bold uppercase tracking-wider text-[11px]">함량 (1회)</th>
                        <th className="px-6 py-4 font-bold uppercase tracking-wider text-[11px]">역할</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-50 text-slate-700">
                      {productIngredients.map((pi: any) => (
                        <tr key={pi.id} className="hover:bg-slate-50/50 transition-colors">
                          <td className="px-6 py-4">
                            <Link
                              href={getIngredientHref({
                                id: pi.ingredients?.id,
                                slug: pi.ingredients?.slug,
                              })}
                              className="font-black text-emerald-600 hover:underline flex flex-col"
                            >
                              <span>{pi.ingredients?.canonical_name_ko}</span>
                              <span className="text-[10px] font-medium text-slate-400 mt-0.5">{pi.raw_label_name}</span>
                            </Link>
                          </td>
                          <td className="px-6 py-4 font-bold text-slate-900">
                            {pi.amount_per_serving} {pi.amount_unit}
                          </td>
                          <td className="px-6 py-4">
                            <Badge className={cn(
                              "px-2 py-0.5 rounded-md text-[10px] font-black border-none",
                              pi.ingredient_role === "active" ? "bg-emerald-50 text-emerald-700" : "bg-slate-100 text-slate-500"
                            )}>
                              {pi.ingredient_role === "active" ? "주성분" : "부원료"}
                            </Badge>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </CardContent>
          </Card>

          {/* 라벨 정보 (필요시) */}
          {label && (
            <Card className="border-slate-200 shadow-sm overflow-hidden">
              <CardHeader className="bg-slate-50/50 border-b border-slate-100">
                <CardTitle className="text-lg font-black text-slate-900 flex items-center gap-2">
                  <FileText className="h-5 w-5 text-blue-500" />
                  제품 상세 정보
                </CardTitle>
              </CardHeader>
              <CardContent className="p-6">
                <div className="space-y-4 text-sm">
                  {label.serving_size_text && (
                    <InfoRow label="1회 섭취량" value={label.serving_size_text} />
                  )}
                  {label.directions_text && (
                    <InfoRow label="섭취 방법" value={label.directions_text} />
                  )}
                  {label.warning_text && (
                    <div className="rounded-2xl border border-amber-200 bg-amber-50/50 p-4">
                      <p className="font-black text-amber-800 flex items-center gap-1.5 mb-2">
                        <span className="text-lg">⚠️</span> 주의사항
                      </p>
                      <p className="text-xs leading-relaxed text-amber-900 font-medium">{label.warning_text}</p>
                    </div>
                  )}
                </div>
              </CardContent>
            </Card>
          )}
        </div>

        {/* Right Content: Benefit Hexagon (1/3 width, Sticky) */}
        <div className="lg:sticky lg:top-8">
          <BenefitHexagon
            title="효능 분석 요약"
            description="원료 데이터를 기반으로 이 제품이 기여하는 주요 건강 효능을 시각화합니다."
            profile={benefitProfile}
          />
        </div>
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
