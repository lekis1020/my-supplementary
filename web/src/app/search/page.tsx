"use client";

import { useState } from "react";
import { createClient } from "@/lib/supabase/client";
import Link from "next/link";
import { Search } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { getIngredientTypeLabel } from "@/lib/utils";

interface SearchResult {
  type: "ingredient" | "product";
  id: number;
  title: string;
  subtitle: string | null;
  href: string;
  badge: string;
}

export default function SearchPage() {
  const [query, setQuery] = useState("");
  const [results, setResults] = useState<SearchResult[]>([]);
  const [loading, setLoading] = useState(false);
  const [searched, setSearched] = useState(false);

  const supabase = createClient();

  async function handleSearch(e: React.FormEvent) {
    e.preventDefault();
    if (!query.trim()) return;

    setLoading(true);
    setSearched(true);

    const trimmed = query.trim();

    // 원료 검색
    const ingredientPromise = supabase
      .from("ingredients")
      .select("id, canonical_name_ko, canonical_name_en, slug, ingredient_type")
      .eq("is_published", true)
      .or(
        `canonical_name_ko.ilike.%${trimmed}%,canonical_name_en.ilike.%${trimmed}%`
      );

    // 제품 검색
    const productPromise = supabase
      .from("products")
      .select("id, product_name, brand_name")
      .eq("is_published", true)
      .or(
        `product_name.ilike.%${trimmed}%,brand_name.ilike.%${trimmed}%`
      );

    const [ingRes, prodRes] = await Promise.all([
      ingredientPromise,
      productPromise,
    ]);

    const combined: SearchResult[] = [];

    for (const ing of ingRes.data ?? []) {
      combined.push({
        type: "ingredient",
        id: ing.id,
        title: ing.canonical_name_ko,
        subtitle: ing.canonical_name_en,
        href: `/ingredients/${ing.slug}`,
        badge: getIngredientTypeLabel(ing.ingredient_type),
      });
    }

    for (const prod of prodRes.data ?? []) {
      combined.push({
        type: "product",
        id: prod.id,
        title: prod.product_name,
        subtitle: prod.brand_name,
        href: `/products/${prod.id}`,
        badge: "제품",
      });
    }

    setResults(combined);
    setLoading(false);
  }

  return (
    <div className="mx-auto max-w-3xl px-4 py-12">
      <h1 className="mb-6 text-3xl font-bold text-gray-900">통합 검색</h1>

      <form onSubmit={handleSearch} className="mb-8">
        <div className="relative">
          <Search className="absolute left-4 top-1/2 h-5 w-5 -translate-y-1/2 text-gray-400" />
          <input
            type="text"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="원료명, 제품명, 영문명으로 검색..."
            className="w-full rounded-xl border border-gray-300 bg-white py-3 pl-12 pr-4 text-gray-900 placeholder-gray-400 focus:border-green-500 focus:outline-none focus:ring-2 focus:ring-green-500/20"
          />
        </div>
      </form>

      {loading && <p className="text-center text-gray-400">검색 중...</p>}

      {!loading && searched && results.length === 0 && (
        <div className="py-16 text-center text-gray-400">
          <p>검색 결과가 없습니다.</p>
          <p className="mt-1 text-sm">다른 검색어를 시도해 보세요.</p>
        </div>
      )}

      {!loading && results.length > 0 && (
        <div className="space-y-2">
          <p className="mb-4 text-sm text-gray-500">{results.length}건의 결과</p>
          {results.map((result) => (
            <Link
              key={`${result.type}-${result.id}`}
              href={result.href}
              className="flex items-center justify-between rounded-lg border border-gray-200 bg-white p-4 transition-colors hover:bg-gray-50"
            >
              <div>
                <p className="font-medium text-gray-900">{result.title}</p>
                {result.subtitle && (
                  <p className="text-sm text-gray-400">{result.subtitle}</p>
                )}
              </div>
              <Badge
                className={
                  result.type === "ingredient"
                    ? "bg-green-100 text-green-700"
                    : "bg-blue-100 text-blue-700"
                }
              >
                {result.badge}
              </Badge>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}
