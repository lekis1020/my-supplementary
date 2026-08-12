import Link from "next/link";
import { SlidersHorizontal } from "lucide-react";
import { createClient } from "@/lib/supabase/server";
import { Badge } from "@/components/ui/badge";
import { Pagination } from "@/components/ui/pagination";
import { EmptyState } from "@/components/ui/state-message";
import { SectionHeader } from "@/components/ui/section-header";
import { SearchCombobox } from "@/components/search/search-combobox";
import { LiveSearchFallback } from "@/components/product/live-search-fallback";
import { IngredientResultSection } from "@/components/search/ingredient-result-section";
import {
  ProductResultSection,
  type ProductSearchResult,
} from "@/components/search/product-result-section";
import { formatProductName, normalizeIngredientNameForDisplay } from "@/lib/utils";
import { getPaginationPages, parsePage } from "@/lib/pagination";
import {
  buildIngredientSearchResult,
  getIngredientMatchKind,
  getIngredientMatchScore,
  normalizeSearchToken,
  type IngredientSearchResult,
} from "@/lib/search/ingredient-ranking";

export const dynamic = "force-dynamic";

const PAGE_SIZE = 20;

interface SearchPageProps {
  searchParams?: Promise<Record<string, string | string[] | undefined>>;
}

function getSearchParam(
  value: string | string[] | undefined,
  fallback = "",
): string {
  return Array.isArray(value) ? value[0] ?? fallback : value ?? fallback;
}

function buildSearchHref(query: string, includeSupporting: boolean, page = 1) {
  const params = new URLSearchParams();

  if (query.trim()) params.set("q", query.trim());
  if (includeSupporting) params.set("includeSupporting", "true");
  if (page > 1) params.set("page", String(page));

  const queryString = params.toString();
  return queryString ? `/search?${queryString}` : "/search";
}

export default async function SearchPage({ searchParams }: SearchPageProps) {
  const resolvedSearchParams = searchParams ? await searchParams : undefined;
  const query = getSearchParam(resolvedSearchParams?.q).trim();
  const includeSupporting = getSearchParam(resolvedSearchParams?.includeSupporting) === "true";
  const currentPage = parsePage(resolvedSearchParams?.page);

  let directIngredientResults: IngredientSearchResult[] = [];
  let probioticStrainIngredientResults: IngredientSearchResult[] = [];
  let productResults: ProductSearchResult[] = [];

  if (query) {
    const supabase = await createClient();
    const queryToken = normalizeSearchToken(query);

    const { data: ingredients } = await supabase
      .from("ingredients")
      .select("id, canonical_name_ko, canonical_name_en, display_name, slug, ingredient_type")
      .eq("is_published", true)
      .or(`canonical_name_ko.ilike.%${query}%,canonical_name_en.ilike.%${query}%,display_name.ilike.%${query}%`)
      .order("canonical_name_ko")
      .limit(100);

    const rankedIngredients = (ingredients ?? [])
      .map((ingredient) => ({
        ingredient,
        score: getIngredientMatchScore(ingredient, queryToken),
        matchKind: getIngredientMatchKind(ingredient, queryToken),
      }))
      .sort((left, right) => {
        if (left.score !== right.score) {
          return right.score - left.score;
        }

        const leftTitle = left.ingredient.canonical_name_ko ?? "";
        const rightTitle = right.ingredient.canonical_name_ko ?? "";
        if (leftTitle.length !== rightTitle.length) {
          return leftTitle.length - rightTitle.length;
        }

        return leftTitle.localeCompare(rightTitle, "ko");
      });

    const rankedWithScore = rankedIngredients.filter(({ score }) => score > 0);

    directIngredientResults = rankedWithScore
      .filter(({ matchKind }) => matchKind === "direct")
      .map(({ ingredient }) => buildIngredientSearchResult(ingredient))
      .filter((result, index, source) =>
        source.findIndex((candidate) => candidate.title === result.title) === index,
      )
      .slice(0, 8);

    probioticStrainIngredientResults = rankedWithScore
      .filter(({ matchKind }) => matchKind === "probiotic-strain-category")
      .slice(0, 8)
      .map(({ ingredient }) => buildIngredientSearchResult(ingredient));

    const ingredientIds = rankedWithScore
      .slice(0, 20)
      .map(({ ingredient }) => ingredient.id);

    // 제품명 직접 검색은 판매 미확인(신고 정보만 있는) 제품도 포함 —
    // 단, 결과에서 "식약처 신고 정보" 라벨로 구분 표시
    const { data: directProducts } = await supabase
      .from("products")
      .select("id, product_name, brand_name, manufacturer_name, sale_verified_at")
      .eq("is_published", true)
      .or(`product_name.ilike.%${query}%,brand_name.ilike.%${query}%`)
      .order("sale_verified_at", { ascending: false, nullsFirst: false })
      .order("product_name")
      .limit(500);

    const productMap = new Map<number, ProductSearchResult>();

    for (const product of directProducts ?? []) {
      productMap.set(product.id, {
        id: product.id,
        title: formatProductName(product.product_name),
        subtitle: product.brand_name || product.manufacturer_name,
        href: `/products/${product.id}`,
        directNameMatch: true,
        saleVerified: product.sale_verified_at != null,
        activeMatches: [],
        supportingMatches: [],
      });
    }

    if (ingredientIds.length > 0) {
      // 원료 기반 제품 결과는 판매 확인된 제품만 노출
      // products/ingredients는 product_ingredients 기준 다대일 FK이므로 항상 단일 객체로 반환된다.
      const { data: productIngredients } = await supabase
        .from("product_ingredients")
        .select(
          "product_id, ingredient_id, ingredient_role, products!inner(id, product_name, brand_name, manufacturer_name, is_published, sale_verified_at), ingredients!inner(canonical_name_ko)",
        )
        .in("ingredient_id", ingredientIds)
        .eq("products.is_published", true)
        .not("products.sale_verified_at", "is", null);

      for (const row of productIngredients ?? []) {
        const product = row.products;
        const ingredient = row.ingredients;

        if (!product || !ingredient) continue;

        const existing = productMap.get(product.id) ?? {
          id: product.id,
          title: formatProductName(product.product_name),
          subtitle: product.brand_name || product.manufacturer_name,
          href: `/products/${product.id}`,
          directNameMatch: false,
          saleVerified: true,
          activeMatches: [],
          supportingMatches: [],
        };

        const matchBucket =
          row.ingredient_role === "active"
            ? existing.activeMatches
            : existing.supportingMatches;
        const ingredientName = normalizeIngredientNameForDisplay(ingredient.canonical_name_ko);

        if (!matchBucket.includes(ingredientName)) {
          matchBucket.push(ingredientName);
        }

        productMap.set(product.id, existing);
      }
    }

    productResults = Array.from(productMap.values())
      .filter((product) =>
        includeSupporting
          ? product.directNameMatch ||
            product.activeMatches.length > 0 ||
            product.supportingMatches.length > 0
          : product.directNameMatch || product.activeMatches.length > 0,
      )
      .sort((left, right) => {
        if (left.directNameMatch !== right.directNameMatch) {
          return left.directNameMatch ? -1 : 1;
        }

        if (left.saleVerified !== right.saleVerified) {
          return left.saleVerified ? -1 : 1;
        }

        if (left.activeMatches.length !== right.activeMatches.length) {
          return right.activeMatches.length - left.activeMatches.length;
        }

        if (left.supportingMatches.length !== right.supportingMatches.length) {
          return right.supportingMatches.length - left.supportingMatches.length;
        }

        return left.title.localeCompare(right.title, "ko");
      });
  }

  const totalPages = Math.max(1, Math.ceil(productResults.length / PAGE_SIZE));
  const safeCurrentPage = Math.min(currentPage, totalPages);
  const pageStart = (safeCurrentPage - 1) * PAGE_SIZE;
  const paginatedProducts = productResults.slice(pageStart, pageStart + PAGE_SIZE);

  const activeProducts = paginatedProducts.filter((product) => product.activeMatches.length > 0);
  const supportingProducts = paginatedProducts.filter(
    (product) => product.activeMatches.length === 0 && product.supportingMatches.length > 0,
  );
  const directOnlyProducts = paginatedProducts.filter(
    (product) =>
      product.directNameMatch &&
      product.activeMatches.length === 0 &&
      product.supportingMatches.length === 0,
  );

  const pageLinks = getPaginationPages(safeCurrentPage, totalPages);

  const verifiedProductCount = productResults.filter(
    (product) => product.saleVerified,
  ).length;

  return (
    <div className="min-h-screen bg-canvas">
      <section className="border-b border-stone-200 bg-gradient-to-br from-brand-bg via-canvas to-surface px-4 py-14">
        <div className="mx-auto max-w-5xl">
          <div className="max-w-3xl">
            <p className="text-xs font-semibold uppercase tracking-[0.18em] text-orange-700">
              Search
            </p>
            <h1 className="mt-3 text-4xl font-black tracking-tight text-ink">
              통합 검색
            </h1>
            <p className="mt-3 text-base leading-7 text-ink-muted">
              원료 사전과 제품 데이터를 함께 탐색합니다. 제품 결과는 검색한 원료가
              주성분인지, 부원료인지 구분해서 확인할 수 있습니다.
            </p>
          </div>

          <form
            action="/search"
            role="search"
            className="mt-8 rounded-3xl border border-stone-200 bg-surface p-4 shadow-card"
          >
            <div className="grid gap-4 lg:grid-cols-[minmax(0,1fr)_220px_auto]">
              <SearchCombobox initialQuery={query} />

              <label
                htmlFor="include-supporting"
                className="flex min-h-14 items-center gap-3 rounded-2xl border border-stone-200 bg-stone-50 px-4 text-sm text-ink"
              >
                <SlidersHorizontal className="h-4 w-4 text-ink-faint" />
                <input
                  id="include-supporting"
                  name="includeSupporting"
                  type="checkbox"
                  value="true"
                  defaultChecked={includeSupporting}
                  className="h-4 w-4 rounded border-stone-300 text-orange-700 focus:ring-brand"
                />
                부원료 포함
              </label>

              <button
                type="submit"
                className="rounded-2xl bg-orange-700 px-5 py-3 text-sm font-semibold text-white transition-colors hover:bg-orange-800"
              >
                검색
              </button>
            </div>
          </form>

          {!query && (
            <div className="mt-6 flex flex-wrap gap-2">
              {["마그네슘", "루테인", "오메가3", "프로바이오틱스"].map((keyword) => (
                <Link
                  key={keyword}
                  href={buildSearchHref(keyword, false)}
                  className="rounded-full border border-stone-200 bg-surface px-4 py-2 text-sm text-ink-muted transition-colors hover:border-brand hover:text-orange-700"
                >
                  {keyword}
                </Link>
              ))}
            </div>
          )}
        </div>
      </section>

      <section className="mx-auto max-w-5xl px-4 py-10">
        {!query && (
          <EmptyState
            title="검색어를 입력해 보세요"
            description="제품명 직접 일치와 원료 포함 제품을 함께 찾아 보여줍니다."
          />
        )}

        {query && (
          <div className="space-y-10">
            <IngredientResultSection
              title="원료 직접 일치"
              description="검색어 자체와 직접 일치하는 원료입니다."
              results={directIngredientResults}
              query={query}
            />

            <IngredientResultSection
              title="프로바이오틱스 균주 일치"
              description="검색어가 프로바이오틱스 계열(유산균)일 때, 균주명에 포함된 일반 키워드 일치를 별도로 분류한 결과입니다."
              results={probioticStrainIngredientResults}
              query={query}
            />

            <section>
              <div className="mb-4 flex flex-wrap items-end justify-between gap-4">
                <SectionHeader
                  title="제품 결과"
                  description={`총 ${productResults.length.toLocaleString()}개 제품 중 ${
                    productResults.length === 0 ? 0 : pageStart + 1
                  }-${Math.min(pageStart + PAGE_SIZE, productResults.length)}개를 표시합니다.`}
                  className="mb-0"
                />
                <Badge variant="tag">
                  {includeSupporting ? "부원료 포함 검색" : "주성분 우선 검색"}
                </Badge>
              </div>

              {productResults.length === 0 ? (
                <EmptyState
                  title="검색 결과가 없습니다"
                  description="다른 원료명이나 제품명으로 다시 검색해 보세요."
                />
              ) : (
                <div className="space-y-8">
                  <ProductResultSection
                    title="주성분 일치"
                    description="검색한 원료가 주성분으로 들어 있는 제품입니다."
                    products={activeProducts}
                    query={query}
                  />

                  {includeSupporting && (
                    <ProductResultSection
                      title="부원료 일치"
                      description="검색한 원료가 부원료 또는 기타 성분으로 들어 있는 제품입니다."
                      products={supportingProducts}
                      query={query}
                    />
                  )}

                  <ProductResultSection
                    title="제품명/브랜드 직접 일치"
                    description="원료 일치 없이 제품명 또는 브랜드명으로 직접 찾은 결과입니다."
                    products={directOnlyProducts}
                    query={query}
                  />

                  <Pagination
                    currentPage={safeCurrentPage}
                    totalPages={totalPages}
                    pageLinks={pageLinks}
                    buildHref={(page) =>
                      buildSearchHref(query, includeSupporting, page)
                    }
                    className="border-t border-stone-200 pt-8"
                  />
                </div>
              )}
            </section>

            <LiveSearchFallback
              query={query}
              initialCount={verifiedProductCount}
              threshold={5}
            />
          </div>
        )}
      </section>
    </div>
  );
}
