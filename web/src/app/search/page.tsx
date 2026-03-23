import Link from "next/link";
import type { ReactNode } from "react";
import { Search, SlidersHorizontal } from "lucide-react";
import { createClient } from "@/lib/supabase/server";
import { Badge } from "@/components/ui/badge";
import {
  formatProductName,
  getIngredientHref,
  getIngredientRoleLabel,
  getIngredientTypeLabel,
  hasClearlyIdentifiedProbioticStrain,
  normalizeProbioticStrainNameForDisplay,
} from "@/lib/utils";

export const dynamic = "force-dynamic";

const PAGE_SIZE = 20;

interface SearchPageProps {
  searchParams?: Promise<Record<string, string | string[] | undefined>>;
}

interface IngredientSearchResult {
  id: number;
  title: string;
  subtitle: string | null;
  href: string;
  badge: string;
}

type IngredientMatchKind = "direct" | "probiotic-strain-category";

interface ProductSearchResult {
  id: number;
  title: string;
  subtitle: string | null;
  href: string;
  directNameMatch: boolean;
  activeMatches: string[];
  supportingMatches: string[];
}

interface IngredientRow {
  id: number;
  canonical_name_ko: string;
  canonical_name_en: string | null;
  display_name: string | null;
  slug: string | null;
  ingredient_type: string;
}

const PROBIOTIC_QUERY_KEYWORDS = [
  "프로바이오틱스",
  "프로바이오틱",
  "유산균",
  "probiotic",
  "probiotics",
  "lactic acid bacteria",
  "lab",
] as const;

function getSearchParam(
  value: string | string[] | undefined,
  fallback = "",
): string {
  return Array.isArray(value) ? value[0] ?? fallback : value ?? fallback;
}

function parsePage(value: string | string[] | undefined): number {
  const parsed = Number(getSearchParam(value, "1"));
  return Number.isFinite(parsed) && parsed > 0 ? Math.floor(parsed) : 1;
}

function buildSearchHref(query: string, includeSupporting: boolean, page = 1) {
  const params = new URLSearchParams();

  if (query.trim()) params.set("q", query.trim());
  if (includeSupporting) params.set("includeSupporting", "true");
  if (page > 1) params.set("page", String(page));

  const queryString = params.toString();
  return queryString ? `/search?${queryString}` : "/search";
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

function normalizeSearchToken(value: string | null | undefined): string {
  if (!value) return "";
  return value.toLowerCase().replace(/\s+/g, "").trim();
}

function isGenericProbioticQuery(queryToken: string): boolean {
  if (!queryToken) return false;
  return PROBIOTIC_QUERY_KEYWORDS.some(
    (keyword) => normalizeSearchToken(keyword) === queryToken,
  );
}

function includesProbioticKeyword(value: string | null | undefined): boolean {
  const token = normalizeSearchToken(value);
  if (!token) return false;

  return PROBIOTIC_QUERY_KEYWORDS.some((keyword) =>
    token.includes(normalizeSearchToken(keyword)),
  );
}

function getIngredientMatchKind(
  ingredient: IngredientRow,
  queryToken: string,
): IngredientMatchKind {
  if (!isGenericProbioticQuery(queryToken)) {
    return "direct";
  }

  const isStrain = hasClearlyIdentifiedProbioticStrain({
    canonicalNameKo: ingredient.canonical_name_ko,
    canonicalNameEn: ingredient.canonical_name_en,
    rawLabelName: ingredient.display_name,
  });

  if (!isStrain) {
    return "direct";
  }

  if (
    includesProbioticKeyword(ingredient.canonical_name_ko) ||
    includesProbioticKeyword(ingredient.canonical_name_en) ||
    includesProbioticKeyword(ingredient.display_name)
  ) {
    return "probiotic-strain-category";
  }

  return "direct";
}

function buildIngredientSearchResult(
  ingredient: IngredientRow,
): IngredientSearchResult {
  const normalizedTitle = normalizeProbioticStrainNameForDisplay(
    ingredient.canonical_name_ko,
  );
  const subtitleParts: string[] = [];
  const isClearlyStrain = hasClearlyIdentifiedProbioticStrain({
    canonicalNameKo: ingredient.canonical_name_ko,
    canonicalNameEn: ingredient.canonical_name_en,
    rawLabelName: ingredient.display_name,
  });

  if (
    normalizedTitle !== ingredient.canonical_name_ko &&
    ingredient.canonical_name_ko &&
    !isClearlyStrain
  ) {
    subtitleParts.push(ingredient.canonical_name_ko);
  }

  if (ingredient.canonical_name_en) {
    subtitleParts.push(ingredient.canonical_name_en);
  }

  return {
    id: ingredient.id,
    title: normalizedTitle,
    subtitle: subtitleParts.length > 0 ? subtitleParts.join(" · ") : null,
    href: getIngredientHref({ id: ingredient.id, slug: ingredient.slug }),
    badge: getIngredientTypeLabel(ingredient.ingredient_type),
  };
}

function getIngredientMatchScore(ingredient: IngredientRow, queryToken: string): number {
  const fields = [
    ingredient.canonical_name_ko,
    ingredient.display_name,
    ingredient.canonical_name_en,
  ];
  let score = 0;

  for (const field of fields) {
    const token = normalizeSearchToken(field);
    if (!token) continue;

    if (token === queryToken) {
      score = Math.max(score, 120);
      continue;
    }

    if (token.startsWith(queryToken)) {
      score = Math.max(score, 100);
      continue;
    }

    if (token.includes(queryToken)) {
      score = Math.max(score, 80);
      continue;
    }

    if (queryToken.includes(token)) {
      score = Math.max(score, 70);
    }
  }

  if (queryToken === "프로바이오틱스" || queryToken === "유산균") {
    if (ingredient.slug === "probiotics" || normalizeSearchToken(ingredient.canonical_name_ko) === "프로바이오틱스") {
      score += 40;
    }

    if (hasClearlyIdentifiedProbioticStrain(ingredient.canonical_name_ko)) {
      score -= 5;
    }
  }

  return score;
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

    const rankedIngredients = ((ingredients ?? []) as IngredientRow[])
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
      .slice(0, 8)
      .map(({ ingredient }) => buildIngredientSearchResult(ingredient));

    probioticStrainIngredientResults = rankedWithScore
      .filter(({ matchKind }) => matchKind === "probiotic-strain-category")
      .slice(0, 8)
      .map(({ ingredient }) => buildIngredientSearchResult(ingredient));

    const ingredientIds = rankedWithScore
      .slice(0, 20)
      .map(({ ingredient }) => ingredient.id);

    const { data: directProducts } = await supabase
      .from("products")
      .select("id, product_name, brand_name, manufacturer_name")
      .eq("is_published", true)
      .or(`product_name.ilike.%${query}%,brand_name.ilike.%${query}%`)
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
        activeMatches: [],
        supportingMatches: [],
      });
    }

    if (ingredientIds.length > 0) {
      const { data: productIngredients } = await supabase
        .from("product_ingredients")
        .select(
          "product_id, ingredient_id, ingredient_role, products!inner(id, product_name, brand_name, manufacturer_name, is_published), ingredients!inner(canonical_name_ko)",
        )
        .in("ingredient_id", ingredientIds)
        .eq("products.is_published", true);

      for (const row of productIngredients ?? []) {
        const product = Array.isArray(row.products) ? row.products[0] : row.products;
        const ingredient = Array.isArray(row.ingredients) ? row.ingredients[0] : row.ingredients;

        if (!product || !ingredient) continue;

        const existing = productMap.get(product.id) ?? {
          id: product.id,
          title: formatProductName(product.product_name),
          subtitle: product.brand_name || product.manufacturer_name,
          href: `/products/${product.id}`,
          directNameMatch: false,
          activeMatches: [],
          supportingMatches: [],
        };

        const matchBucket =
          row.ingredient_role === "active"
            ? existing.activeMatches
            : existing.supportingMatches;
        const ingredientName = normalizeProbioticStrainNameForDisplay(ingredient.canonical_name_ko);

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

  return (
    <div className="min-h-screen bg-white">
      <section className="border-b border-slate-200 bg-[radial-gradient(circle_at_top,#ecfdf5,transparent_55%)] px-4 py-14">
        <div className="mx-auto max-w-5xl">
          <div className="max-w-3xl">
            <p className="text-xs font-semibold uppercase tracking-[0.18em] text-emerald-600">
              Search
            </p>
            <h1 className="mt-3 text-4xl font-black tracking-tight text-slate-900">
              통합 검색
            </h1>
            <p className="mt-3 text-base leading-7 text-slate-600">
              원료 사전과 제품 데이터를 함께 탐색합니다. 제품 결과는 검색한 원료가
              주성분인지, 부원료인지 구분해서 확인할 수 있습니다.
            </p>
          </div>

          <form action="/search" className="mt-8 rounded-3xl border border-slate-200 bg-white p-4 shadow-sm">
            <div className="grid gap-4 lg:grid-cols-[minmax(0,1fr)_220px_auto]">
              <label htmlFor="search-query" className="relative block">
                <span className="sr-only">검색어</span>
                <Search className="pointer-events-none absolute left-4 top-1/2 h-5 w-5 -translate-y-1/2 text-slate-400" />
                <input
                  id="search-query"
                  name="q"
                  type="search"
                  defaultValue={query}
                  placeholder="원료명, 제품명, 영문명으로 검색"
                  className="w-full rounded-2xl border border-slate-300 bg-white py-3 pl-12 pr-4 text-slate-900 placeholder:text-slate-400 focus:border-emerald-500 focus:outline-none focus:ring-4 focus:ring-emerald-100"
                />
              </label>

              <label
                htmlFor="include-supporting"
                className="flex min-h-14 items-center gap-3 rounded-2xl border border-slate-200 bg-slate-50 px-4 text-sm text-slate-700"
              >
                <SlidersHorizontal className="h-4 w-4 text-slate-400" />
                <input
                  id="include-supporting"
                  name="includeSupporting"
                  type="checkbox"
                  value="true"
                  defaultChecked={includeSupporting}
                  className="h-4 w-4 rounded border-slate-300 text-emerald-600 focus:ring-emerald-500"
                />
                부원료 포함
              </label>

              <button
                type="submit"
                className="rounded-2xl bg-emerald-600 px-5 py-3 text-sm font-semibold text-white transition-colors hover:bg-emerald-700"
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
                  className="rounded-full border border-slate-200 bg-white px-4 py-2 text-sm text-slate-600 transition-colors hover:border-emerald-200 hover:text-emerald-700"
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
              countToneClassName="bg-emerald-50 text-emerald-700"
            />

            <IngredientResultSection
              title="프로바이오틱스 균주 일치"
              description="검색어가 프로바이오틱스 계열(유산균)일 때, 균주명에 포함된 일반 키워드 일치를 별도로 분류한 결과입니다."
              results={probioticStrainIngredientResults}
              countToneClassName="bg-violet-50 text-violet-700"
            />

            <section>
              <div className="mb-4 flex flex-wrap items-end justify-between gap-4">
                <div>
                  <h2 className="text-xl font-bold text-slate-900">제품 결과</h2>
                  <p className="mt-1 text-sm text-slate-500">
                    총 {productResults.length.toLocaleString()}개 제품 중{" "}
                    {productResults.length === 0 ? 0 : pageStart + 1}-
                    {Math.min(pageStart + PAGE_SIZE, productResults.length)}개를 표시합니다.
                  </p>
                </div>
                <div className="rounded-full bg-slate-100 px-3 py-1 text-xs font-medium text-slate-600">
                  {includeSupporting ? "부원료 포함 검색" : "주성분 우선 검색"}
                </div>
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
                  />

                  {includeSupporting && (
                    <ProductResultSection
                      title="부원료 일치"
                      description="검색한 원료가 부원료 또는 기타 성분으로 들어 있는 제품입니다."
                      products={supportingProducts}
                    />
                  )}

                  <ProductResultSection
                    title="제품명/브랜드 직접 일치"
                    description="원료 일치 없이 제품명 또는 브랜드명으로 직접 찾은 결과입니다."
                    products={directOnlyProducts}
                  />

                  {totalPages > 1 && (
                    <div className="flex flex-wrap items-center justify-center gap-2 border-t border-slate-200 pt-8">
                      <PaginationLink
                        href={buildSearchHref(query, includeSupporting, Math.max(1, safeCurrentPage - 1))}
                        disabled={safeCurrentPage <= 1}
                      >
                        이전
                      </PaginationLink>
                      {pageLinks.map((page) => (
                        <PaginationLink
                          key={page}
                          href={buildSearchHref(query, includeSupporting, page)}
                          active={page === safeCurrentPage}
                        >
                          {page}
                        </PaginationLink>
                      ))}
                      <PaginationLink
                        href={buildSearchHref(query, includeSupporting, Math.min(totalPages, safeCurrentPage + 1))}
                        disabled={safeCurrentPage >= totalPages}
                      >
                        다음
                      </PaginationLink>
                    </div>
                  )}
                </div>
              )}
            </section>
          </div>
        )}
      </section>
    </div>
  );
}

function IngredientResultSection({
  title,
  description,
  results,
  countToneClassName,
}: {
  title: string;
  description: string;
  results: IngredientSearchResult[];
  countToneClassName: string;
}) {
  if (results.length === 0) return null;

  return (
    <section>
      <div className="mb-4 flex items-center justify-between gap-3">
        <div>
          <h2 className="text-xl font-bold text-slate-900">{title}</h2>
          <p className="mt-1 text-sm text-slate-500">{description}</p>
        </div>
        <Badge className={countToneClassName}>{results.length}개</Badge>
      </div>

      <div className="grid gap-3 md:grid-cols-2">
        {results.map((result) => (
          <Link
            key={result.id}
            href={result.href}
            className="rounded-2xl border border-slate-200 bg-white p-5 transition-colors hover:border-emerald-200 hover:bg-emerald-50/40"
          >
            <div className="flex items-start justify-between gap-4">
              <div>
                <p className="font-semibold text-slate-900">{result.title}</p>
                {result.subtitle && (
                  <p className="mt-1 text-sm text-slate-500">{result.subtitle}</p>
                )}
              </div>
              <Badge className="bg-emerald-50 text-emerald-700">{result.badge}</Badge>
            </div>
          </Link>
        ))}
      </div>
    </section>
  );
}

function ProductResultSection({
  title,
  description,
  products,
}: {
  title: string;
  description: string;
  products: ProductSearchResult[];
}) {
  if (products.length === 0) return null;

  return (
    <section>
      <div className="mb-4 flex items-center justify-between gap-3">
        <div>
          <h3 className="text-lg font-bold text-slate-900">{title}</h3>
          <p className="mt-1 text-sm text-slate-500">{description}</p>
        </div>
        <Badge className="bg-slate-100 text-slate-700">{products.length}개</Badge>
      </div>

      <div className="space-y-3">
        {products.map((product) => (
          <Link
            key={product.id}
            href={product.href}
            className="block rounded-2xl border border-slate-200 bg-white p-5 transition-colors hover:border-emerald-200 hover:bg-emerald-50/30"
          >
            <div className="flex flex-col gap-3 md:flex-row md:items-start md:justify-between">
              <div>
                <p className="text-lg font-semibold text-slate-900">{product.title}</p>
                {product.subtitle && (
                  <p className="mt-1 text-sm text-slate-500">{product.subtitle}</p>
                )}
              </div>

              <div className="flex flex-wrap gap-2">
                {product.directNameMatch && (
                  <Badge className="bg-blue-50 text-blue-700">제품명 일치</Badge>
                )}
                {product.activeMatches.length > 0 && (
                  <Badge className="bg-emerald-50 text-emerald-700">
                    {getIngredientRoleLabel("active")} {product.activeMatches.length}개
                  </Badge>
                )}
                {product.supportingMatches.length > 0 && (
                  <Badge className="bg-amber-50 text-amber-700">
                    {getIngredientRoleLabel("supporting")} {product.supportingMatches.length}개
                  </Badge>
                )}
              </div>
            </div>

            {product.activeMatches.length > 0 && (
              <p className="mt-3 text-sm text-slate-600">
                <span className="font-medium text-slate-900">주성분:</span>{" "}
                {product.activeMatches.join(", ")}
              </p>
            )}

            {product.supportingMatches.length > 0 && (
              <p className="mt-2 text-sm text-slate-500">
                <span className="font-medium text-slate-800">부원료:</span>{" "}
                {product.supportingMatches.join(", ")}
              </p>
            )}
          </Link>
        ))}
      </div>
    </section>
  );
}

function EmptyState({
  title,
  description,
}: {
  title: string;
  description: string;
}) {
  return (
    <div className="rounded-3xl border border-dashed border-slate-200 bg-slate-50 px-6 py-14 text-center">
      <p className="text-lg font-semibold text-slate-900">{title}</p>
      <p className="mt-2 text-sm text-slate-500">{description}</p>
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
  children: ReactNode;
  active?: boolean;
  disabled?: boolean;
}) {
  const className = [
    "inline-flex min-w-10 items-center justify-center rounded-xl border px-3 py-2 text-sm font-semibold transition-colors",
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
