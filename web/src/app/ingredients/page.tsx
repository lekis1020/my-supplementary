import { createClient } from "@/lib/supabase/server";
import { IngredientCategoryCard } from "@/components/ingredient/ingredient-category-card";
import {
  getIngredientCategories,
  getIngredientCategoryDescription,
  getIngredientCategoryLabel,
  INGREDIENT_CATEGORY_ORDER,
  type IngredientCategory,
} from "@/lib/utils";
import type { Metadata } from "next";

export const dynamic = "force-dynamic";

export const metadata: Metadata = {
  title: "원료 사전",
  description: "원료를 대분류별로 탐색하고, 각 카테고리 안에서 세부 성분을 찾아보세요.",
};

type IngredientRow = {
  id: number;
  canonical_name_ko: string;
  canonical_name_en: string | null;
  slug: string | null;
  ingredient_type: string;
  description: string | null;
};

type CategorySummary = {
  category: IngredientCategory;
  count: number;
  examples: string[];
};

export default async function IngredientsPage() {
  const supabase = await createClient();

  const { data: ingredients, error } = await supabase
    .from("ingredients")
    .select("id, canonical_name_ko, canonical_name_en, slug, ingredient_type, description")
    .eq("is_published", true)
    .eq("is_active", true)
    .order("canonical_name_ko");

  if (error) {
    return <ErrorState message={error.message} />;
  }

  const categorySummaries = buildCategorySummaries(ingredients ?? []);

  return (
    <div className="mx-auto max-w-6xl px-4 py-12">
      <div className="mb-10">
        <p className="text-xs font-semibold uppercase tracking-[0.18em] text-emerald-600">
          Ingredient Directory
        </p>
        <h1 className="mt-3 text-3xl font-bold text-gray-900">원료 사전</h1>
        <p className="mt-3 max-w-3xl text-gray-500">
          총 {(ingredients?.length ?? 0).toLocaleString()}종 원료를 대분류별로 나누어 보여줍니다.
          비타민, 미네랄, 지방산, 프로바이오틱스, 허브/식물성, 기타 카테고리 안에서
          다시 세부 성분을 탐색할 수 있습니다.
        </p>
      </div>

      <div className="grid gap-5 md:grid-cols-2 xl:grid-cols-3">
        {categorySummaries.map((summary) => (
          <IngredientCategoryCard
            key={summary.category}
            category={summary.category}
            count={summary.count}
            examples={summary.examples}
          />
        ))}
      </div>

      <div className="mt-12 rounded-2xl border border-slate-200 bg-slate-50 p-6">
        <h2 className="text-lg font-bold text-slate-900">카테고리 구성</h2>
        <div className="mt-4 grid gap-4 md:grid-cols-2">
          {categorySummaries.map((summary) => (
            <div key={summary.category} className="rounded-xl bg-white p-4">
              <div className="flex items-center justify-between gap-3">
                <p className="font-semibold text-slate-900">
                  {getIngredientCategoryLabel(summary.category)}
                </p>
                <span className="text-sm font-medium text-slate-400">
                  {summary.count.toLocaleString()}개
                </span>
              </div>
              <p className="mt-2 text-sm text-slate-500">
                {getIngredientCategoryDescription(summary.category)}
              </p>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

function buildCategorySummaries(ingredients: IngredientRow[]): CategorySummary[] {
  const grouped = ingredients.reduce<Record<IngredientCategory, IngredientRow[]>>(
    (acc, ingredient) => {
      getIngredientCategories(ingredient.ingredient_type).forEach((category) => {
        if (!acc[category]) acc[category] = [];
        acc[category].push(ingredient);
      });
      return acc;
    },
    {
      vitamins: [],
      minerals: [],
      "fatty-acids": [],
      probiotics: [],
      herbals: [],
      others: [],
    },
  );

  return INGREDIENT_CATEGORY_ORDER.map((category) => ({
    category,
    count: grouped[category].length,
    examples: grouped[category].slice(0, 4).map((ingredient) => ingredient.canonical_name_ko),
  })).filter((summary) => summary.count > 0);
}

function ErrorState({ message }: { message: string }) {
  return (
    <div className="mx-auto max-w-6xl px-4 py-12 text-center">
      <p className="text-red-500">데이터를 불러오지 못했습니다: {message}</p>
      <p className="mt-2 text-sm text-gray-400">Supabase 연결을 확인해 주세요.</p>
    </div>
  );
}
