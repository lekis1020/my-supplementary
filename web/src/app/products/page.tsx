import { createClient } from "@/lib/supabase/server";
import { EnhancedProductCard } from "@/components/product/product-card";
import type { Metadata } from "next";

export const dynamic = "force-dynamic";

export const metadata: Metadata = {
  title: "제품 목록 | bochoong.com",
  description: "인기 영양제·건강기능식품의 성분과 가성비를 한눈에 비교하세요.",
};

export default async function ProductsPage() {
  const supabase = await createClient();

  const { data: products, error } = await supabase
    .from("products")
    .select(
      "id, product_name, brand_name, manufacturer_name, country_code, product_type, approval_or_report_no"
    )
    .eq("is_published", true)
    .order("product_name");

  if (error) {
    return (
      <div className="mx-auto max-w-6xl px-4 py-12 text-center">
        <div className="inline-flex h-12 w-12 items-center justify-center rounded-full bg-red-50 text-red-500 mb-4">
          !
        </div>
        <p className="text-slate-600 font-medium">데이터를 불러오지 못했습니다: {error.message}</p>
      </div>
    );
  }

  const normalizedProducts = (products ?? []).map((product) => ({
    ...product,
    tags:
      product.country_code === "KR"
        ? ["식품안전나라", "공개데이터"]
        : ["Global", "Supplement"],
  }));

  const krProducts = normalizedProducts.filter((p) => p.country_code === "KR");
  const usProducts = normalizedProducts.filter((p) => p.country_code === "US");

  return (
    <div className="min-h-screen bg-slate-50 pb-24">
      <div className="bg-white border-b border-slate-200 px-6 py-12 mb-10">
        <div className="mx-auto max-w-6xl">
          <div className="inline-block px-3 py-1 rounded-full bg-emerald-50 text-emerald-600 text-xs font-bold mb-4">
            Product Database
          </div>
          <h1 className="text-3xl font-black text-slate-900 tracking-tight">영양제 제품 목록</h1>
          <p className="mt-3 text-slate-500 text-lg max-w-2xl leading-relaxed">
            총 {products?.length ?? 0}개의 검증된 제품 데이터를 기반으로 제품 유형, 제조사, 신고번호를 빠르게 확인해 보세요.
          </p>
        </div>
      </div>

      <div className="mx-auto max-w-6xl px-6">
        {/* 한국 제품 섹션 */}
        {krProducts.length > 0 && (
          <section className="mb-16">
            <div className="flex items-center gap-2 mb-6">
              <span className="text-2xl">🇰🇷</span>
              <h2 className="text-xl font-bold text-slate-800">국내 건강기능식품</h2>
              <span className="text-sm text-slate-400 font-medium ml-1">({krProducts.length})</span>
            </div>
            <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
              {krProducts.map((product) => (
                <EnhancedProductCard key={product.id} product={product} />
              ))}
            </div>
          </section>
        )}

        {/* 미국 제품 섹션 */}
        {usProducts.length > 0 && (
          <section>
            <div className="flex items-center gap-2 mb-6">
              <span className="text-2xl">🇺🇸</span>
              <h2 className="text-xl font-bold text-slate-800">해외 보충제 (US)</h2>
              <span className="text-sm text-slate-400 font-medium ml-1">({usProducts.length})</span>
            </div>
            <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
              {usProducts.map((product) => (
                <EnhancedProductCard key={product.id} product={product} />
              ))}
            </div>
          </section>
        )}
      </div>
    </div>
  );
}
