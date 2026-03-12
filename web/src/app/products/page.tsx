import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import { Badge } from "@/components/ui/badge";
import type { Metadata } from "next";

export const dynamic = "force-dynamic";

export const metadata: Metadata = {
  title: "제품 목록",
  description: "인기 영양제·건강기능식품을 비교하세요.",
};

export default async function ProductsPage() {
  const supabase = await createClient();

  const { data: products, error } = await supabase
    .from("products")
    .select("id, product_name, brand_name, manufacturer_name, country_code, product_type")
    .eq("is_published", true)
    .order("product_name");

  if (error) {
    return (
      <div className="mx-auto max-w-6xl px-4 py-12 text-center">
        <p className="text-red-500">데이터를 불러오지 못했습니다: {error.message}</p>
      </div>
    );
  }

  const krProducts = (products ?? []).filter((p) => p.country_code === "KR");
  const usProducts = (products ?? []).filter((p) => p.country_code === "US");

  return (
    <div className="mx-auto max-w-6xl px-4 py-12">
      <div className="mb-8 flex items-end justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">제품 목록</h1>
          <p className="mt-2 text-gray-500">
            {products?.length ?? 0}개 제품의 원료 조성과 라벨 정보를 확인하세요.
          </p>
        </div>
        <Link
          href="/compare"
          className="rounded-lg bg-green-600 px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-green-700"
        >
          비교 도구
        </Link>
      </div>

      {/* 한국 제품 */}
      {krProducts.length > 0 && (
        <ProductSection title="한국 제품" flag="KR" products={krProducts} />
      )}

      {/* 미국 제품 */}
      {usProducts.length > 0 && (
        <ProductSection title="미국 제품" flag="US" products={usProducts} />
      )}
    </div>
  );
}

function ProductSection({
  title,
  flag,
  products,
}: {
  title: string;
  flag: string;
  products: any[];
}) {
  return (
    <section className="mb-10">
      <h2 className="mb-4 text-xl font-semibold text-gray-800">
        {flag === "KR" ? "🇰🇷" : "🇺🇸"} {title}
      </h2>
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {products.map((product) => (
          <Link
            key={product.id}
            href={`/products/${product.id}`}
            className="group rounded-lg border border-gray-200 bg-white p-5 transition-shadow hover:shadow-md"
          >
            <h3 className="font-semibold text-gray-900 group-hover:text-green-600">
              {product.product_name}
            </h3>
            <p className="mt-1 text-sm text-gray-400">{product.brand_name}</p>
            {product.product_type && (
              <Badge className="mt-3 bg-gray-100 text-gray-600">
                {product.product_type === "health_functional_food"
                  ? "건강기능식품"
                  : "Dietary Supplement"}
              </Badge>
            )}
          </Link>
        ))}
      </div>
    </section>
  );
}
