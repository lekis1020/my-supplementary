import Link from "next/link";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { EnhancedProductCard } from "@/components/product/product-card";
import { CompareWorkbench } from "@/components/product/compare-workbench";
import { Pagination } from "@/components/ui/pagination";
import { Card } from "@/components/ui/card";
import { getPaginationPages, parsePage } from "@/lib/pagination";
import type { Metadata } from "next";

export const dynamic = "force-dynamic";
const PAGE_SIZE = 24;

export const metadata: Metadata = {
  title: "제품 데이터베이스 | bochoong.com",
  description: "인기 영양제·건강기능식품의 성분과 가성비를 한눈에 비교하세요.",
};

interface ProductsPageProps {
  searchParams?: Promise<Record<string, string | string[] | undefined>>;
}

function parsePositiveInteger(rawValue: string | string[] | undefined) {
  const value = Array.isArray(rawValue) ? rawValue[0] : rawValue;
  const parsed = Number(value);
  return Number.isInteger(parsed) && parsed > 0 ? parsed : null;
}

function buildPageHref(page: number, ingredientId?: number | null) {
  const params = new URLSearchParams();

  if (ingredientId) {
    params.set("ingredientId", String(ingredientId));
  }

  if (page > 1) {
    params.set("page", String(page));
  }

  const query = params.toString();
  return query ? `/products?${query}` : "/products";
}

export default async function ProductsPage({ searchParams }: ProductsPageProps) {
  const resolvedSearchParams = searchParams ? await searchParams : undefined;
  const currentPage = parsePage(resolvedSearchParams?.page);
  const ingredientId = parsePositiveInteger(resolvedSearchParams?.ingredientId);
  const rangeFrom = (currentPage - 1) * PAGE_SIZE;
  const rangeTo = rangeFrom + PAGE_SIZE - 1;
  const supabase = await createClient();

  const filteredIngredient = ingredientId
    ? (
        await supabase
          .from("ingredients")
          .select("id, canonical_name_ko")
          .eq("id", ingredientId)
          .maybeSingle()
      ).data
    : null;

  // 판매 확인(sale_verified_at)된 제품만 기본 노출 — 신고만 있고 유통 미확인인
  // 제품은 목록에서 제외 (제품명 직접 검색으로만 접근 가능)
  const productsQuery = ingredientId
    ? supabase
        .from("products")
        .select(
          "id, product_name, brand_name, manufacturer_name, country_code, product_type, approval_or_report_no, product_ingredients!inner(ingredient_id)",
          { count: "exact" }
        )
        .eq("is_published", true)
        .not("sale_verified_at", "is", null)
        .eq("product_ingredients.ingredient_id", ingredientId)
        .order("product_name")
    : supabase
        .from("products")
        .select(
          "id, product_name, brand_name, manufacturer_name, country_code, product_type, approval_or_report_no",
          { count: "exact" }
        )
        .eq("is_published", true)
        .not("sale_verified_at", "is", null)
        .order("product_name");

  const { data: products, error, count } = await productsQuery.range(rangeFrom, rangeTo);

  if (error) {
    return (
      <div className="mx-auto max-w-6xl px-4 py-12 text-center">
        <div className="inline-flex h-12 w-12 items-center justify-center rounded-full bg-danger-bg text-danger mb-4">
          !
        </div>
        <p className="text-ink font-medium">데이터를 불러오지 못했습니다: {error.message}</p>
      </div>
    );
  }

  const totalCount = count ?? 0;
  const totalPages = Math.max(1, Math.ceil(totalCount / PAGE_SIZE));

  if (totalCount > 0 && currentPage > totalPages) {
    redirect(buildPageHref(totalPages, ingredientId));
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
  const pageStart = totalCount === 0 ? 0 : rangeFrom + 1;
  const pageEnd = totalCount === 0 ? 0 : Math.min(rangeFrom + normalizedProducts.length, totalCount);
  const pageLinks = getPaginationPages(currentPage, totalPages);
  const filteredIngredientName = filteredIngredient?.canonical_name_ko ?? null;

  return (
    <div className="min-h-screen bg-canvas pb-24">
      <div className="bg-surface border-b border-stone-200 px-6 py-12 mb-10">
        <div className="mx-auto max-w-6xl">
          <div className="inline-block px-3 py-1 rounded-full bg-brand-bg text-orange-700 text-xs font-bold mb-4">
            Product Database
          </div>
          <h1 className="text-3xl font-black text-ink tracking-tight">영양제 제품 데이터베이스</h1>
          <p className="mt-3 text-ink-muted text-lg max-w-2xl leading-relaxed">
            {filteredIngredientName
              ? `${filteredIngredientName}을 포함한 판매 확인 제품 ${totalCount.toLocaleString()}개 중 ${pageStart.toLocaleString()}-${pageEnd.toLocaleString()}번째 항목을 보고 있습니다.`
              : `실제 판매가 확인된 제품 ${totalCount.toLocaleString()}개 중 ${pageStart.toLocaleString()}-${pageEnd.toLocaleString()}번째 항목을 보고 있습니다.`}
          </p>
          <p className="mt-1 text-sm text-ink-faint">
            판매처가 확인되지 않은 신고 제품은 목록에서 제외되며, 제품명 검색으로 찾을 수 있습니다.
          </p>
          <p className="mt-2 text-sm font-medium text-ink-faint">
            페이지 {currentPage} / {totalPages}
          </p>
          {filteredIngredientName && (
            <Card tone="highlight" padding="sm" className="mt-5 flex flex-wrap items-center gap-3">
              <span className="inline-flex items-center rounded-full bg-surface px-3 py-1 text-xs font-bold text-orange-700">
                원료 필터
              </span>
              <p className="text-sm text-ink">
                <span className="font-semibold">{filteredIngredientName}</span> 포함 제품만 보고 있습니다.
              </p>
              <Link
                href="/products"
                className="text-sm font-semibold text-orange-700 underline-offset-4 hover:underline"
              >
                필터 해제
              </Link>
            </Card>
          )}
        </div>
      </div>

      <div className="mx-auto max-w-6xl px-6">
        <CompareWorkbench embedded />

        {normalizedProducts.length === 0 && (
          <div className="mt-10 rounded-3xl border border-dashed border-stone-200 bg-surface px-6 py-12 text-center text-ink-muted">
            {filteredIngredientName
              ? `${filteredIngredientName}을 포함한 공개 제품이 아직 없습니다.`
              : "표시할 제품이 없습니다."}
          </div>
        )}

        {/* 한국 제품 섹션 */}
        {krProducts.length > 0 && (
          <section className="mb-16 mt-10">
            <div className="flex items-center gap-2 mb-6">
              <span className="text-2xl">🇰🇷</span>
              <h2 className="text-xl font-bold text-ink">국내 건강기능식품</h2>
              <span className="text-sm text-ink-faint font-medium ml-1">({krProducts.length})</span>
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
          <section className={krProducts.length === 0 ? "mt-10" : ""}>
            <div className="flex items-center gap-2 mb-6">
              <span className="text-2xl">🇺🇸</span>
              <h2 className="text-xl font-bold text-ink">해외 보충제 (US)</h2>
              <span className="text-sm text-ink-faint font-medium ml-1">({usProducts.length})</span>
            </div>
            <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
              {usProducts.map((product) => (
                <EnhancedProductCard key={product.id} product={product} />
              ))}
            </div>
          </section>
        )}

        <div className="mt-12 flex flex-col items-center gap-4 border-t border-stone-200 pt-8">
          <div className="text-sm text-ink-muted">
            현재 페이지에 {normalizedProducts.length.toLocaleString()}개 제품이 표시됩니다.
          </div>
          <Pagination
            currentPage={currentPage}
            totalPages={totalPages}
            pageLinks={pageLinks}
            buildHref={(page) => buildPageHref(page, ingredientId)}
          />
        </div>
      </div>
    </div>
  );
}
