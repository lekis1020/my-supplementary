import Link from "next/link";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { EnhancedProductCard } from "@/components/product/product-card";
import { CompareWorkbench } from "@/components/product/compare-workbench";
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

function parsePage(rawPage: string | string[] | undefined) {
  const pageValue = Array.isArray(rawPage) ? rawPage[0] : rawPage;
  const parsed = Number(pageValue);
  return Number.isFinite(parsed) && parsed > 0 ? Math.floor(parsed) : 1;
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

function getPaginationPages(currentPage: number, totalPages: number, visibleCount = 5) {
  if (totalPages <= visibleCount) {
    return Array.from({ length: totalPages }, (_, index) => index + 1);
  }

  const half = Math.floor(visibleCount / 2);
  let start = Math.max(1, currentPage - half);
  let end = start + visibleCount - 1;

  if (end > totalPages) {
    end = totalPages;
    start = end - visibleCount + 1;
  }

  return Array.from({ length: end - start + 1 }, (_, index) => start + index);
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

  const productsQuery = ingredientId
    ? supabase
        .from("products")
        .select(
          "id, product_name, brand_name, manufacturer_name, country_code, product_type, approval_or_report_no, product_ingredients!inner(ingredient_id)",
          { count: "exact" }
        )
        .eq("is_published", true)
        .eq("product_ingredients.ingredient_id", ingredientId)
        .order("product_name")
    : supabase
        .from("products")
        .select(
          "id, product_name, brand_name, manufacturer_name, country_code, product_type, approval_or_report_no",
          { count: "exact" }
        )
        .eq("is_published", true)
        .order("product_name");

  const { data: products, error, count } = await productsQuery.range(rangeFrom, rangeTo);

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
    <div className="min-h-screen bg-slate-50 pb-24">
      <div className="bg-white border-b border-slate-200 px-6 py-12 mb-10">
        <div className="mx-auto max-w-6xl">
          <div className="inline-block px-3 py-1 rounded-full bg-emerald-50 text-emerald-600 text-xs font-bold mb-4">
            Product Database
          </div>
          <h1 className="text-3xl font-black text-slate-900 tracking-tight">영양제 제품 데이터베이스</h1>
          <p className="mt-3 text-slate-500 text-lg max-w-2xl leading-relaxed">
            {filteredIngredientName
              ? `${filteredIngredientName}을 포함한 제품 ${totalCount.toLocaleString()}개 중 ${pageStart.toLocaleString()}-${pageEnd.toLocaleString()}번째 항목을 보고 있습니다.`
              : `총 ${totalCount.toLocaleString()}개의 검증된 제품 중 ${pageStart.toLocaleString()}-${pageEnd.toLocaleString()}번째 항목을 보고 있습니다.`}
          </p>
          <p className="mt-2 text-sm font-medium text-slate-400">
            페이지 {currentPage} / {totalPages}
          </p>
          {filteredIngredientName && (
            <div className="mt-5 flex flex-wrap items-center gap-3 rounded-2xl border border-emerald-100 bg-emerald-50 px-4 py-3">
              <span className="inline-flex items-center rounded-full bg-white px-3 py-1 text-xs font-bold text-emerald-700">
                원료 필터
              </span>
              <p className="text-sm text-emerald-900">
                <span className="font-semibold">{filteredIngredientName}</span> 포함 제품만 보고 있습니다.
              </p>
              <Link
                href="/products"
                className="text-sm font-semibold text-emerald-700 underline-offset-4 hover:underline"
              >
                필터 해제
              </Link>
            </div>
          )}
        </div>
      </div>

      <div className="mx-auto max-w-6xl px-6">
        <CompareWorkbench embedded />

        {normalizedProducts.length === 0 && (
          <div className="mt-10 rounded-3xl border border-dashed border-slate-200 bg-white px-6 py-12 text-center text-slate-500">
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
          <section className={krProducts.length === 0 ? "mt-10" : ""}>
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

        <div className="mt-12 flex flex-col items-center gap-4 border-t border-slate-200 pt-8">
          <div className="text-sm text-slate-500">
            현재 페이지에 {normalizedProducts.length.toLocaleString()}개 제품이 표시됩니다.
          </div>
          <div className="flex flex-wrap items-center justify-center gap-2">
            <PaginationLink
              href={buildPageHref(Math.max(1, currentPage - 1), ingredientId)}
              disabled={currentPage <= 1}
            >
              이전
            </PaginationLink>
            {pageLinks.map((page) => (
              <PaginationLink
                key={page}
                href={buildPageHref(page, ingredientId)}
                active={page === currentPage}
              >
                {page}
              </PaginationLink>
            ))}
            <PaginationLink
              href={buildPageHref(Math.min(totalPages, currentPage + 1), ingredientId)}
              disabled={currentPage >= totalPages}
            >
              다음
            </PaginationLink>
          </div>
        </div>
      </div>
    </div>
  );
}

function PaginationLink({
  href,
  children,
  active = false,
  disabled = false,
}: {
  href: string;
  children: React.ReactNode;
  active?: boolean;
  disabled?: boolean;
}) {
  const className = [
    "inline-flex min-w-10 items-center justify-center rounded-lg border px-3 py-2 text-sm font-semibold transition-colors",
    active
      ? "border-emerald-600 bg-emerald-600 text-white"
      : "border-slate-200 bg-white text-slate-600 hover:border-emerald-200 hover:text-emerald-700",
    disabled ? "pointer-events-none opacity-40" : "",
  ]
    .filter(Boolean)
    .join(" ");

  return (
    <Link href={href} aria-disabled={disabled} className={className}>
      {children}
    </Link>
  );
}
