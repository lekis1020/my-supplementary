import Link from "next/link";
import { notFound } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { IngredientCard } from "@/components/ingredient/ingredient-card";
import {
  getIngredientCategory,
  getIngredientCategoryDescription,
  getIngredientCategoryLabel,
  getIngredientSubgroupLabel,
  getProbioticSubgroup,
  INGREDIENT_CATEGORY_ORDER,
  isIngredientCategory,
  type IngredientCategory,
} from "@/lib/utils";
import type { Metadata } from "next";

export const dynamic = "force-dynamic";

interface CategoryPageProps {
  params: Promise<{ category: string }>;
}

type IngredientRow = {
  id: number;
  canonical_name_ko: string;
  canonical_name_en: string | null;
  scientific_name: string | null;
  slug: string | null;
  ingredient_type: string;
  description: string | null;
};

export async function generateMetadata({ params }: CategoryPageProps): Promise<Metadata> {
  const { category } = await params;
  if (!isIngredientCategory(category)) {
    return { title: "원료 카테고리를 찾을 수 없습니다" };
  }

  return {
    title: `${getIngredientCategoryLabel(category)} | 원료 사전`,
    description: getIngredientCategoryDescription(category),
  };
}

export default async function IngredientCategoryPage({ params }: CategoryPageProps) {
  const { category } = await params;

  if (!isIngredientCategory(category)) {
    notFound();
  }

  const supabase = await createClient();
  const { data: ingredients, error } = await supabase
    .from("ingredients")
    .select(
      "id, canonical_name_ko, canonical_name_en, scientific_name, slug, ingredient_type, description",
    )
    .eq("is_published", true)
    .eq("is_active", true)
    .order("canonical_name_ko");

  if (error) {
    return <ErrorState message={error.message} />;
  }

  const categoryIngredients = (ingredients ?? []).filter(
    (ingredient) => getIngredientCategory(ingredient.ingredient_type) === category,
  );

  if (categoryIngredients.length === 0) {
    notFound();
  }

  const grouped = groupIngredients(categoryIngredients, category);

  return (
    <div className="mx-auto max-w-6xl px-4 py-12">
      <nav className="mb-6 flex flex-wrap items-center gap-2 text-sm text-slate-400">
        <Link href="/ingredients" className="hover:text-emerald-600">
          원료 사전
        </Link>
        <span>/</span>
        <span className="font-medium text-slate-600">{getIngredientCategoryLabel(category)}</span>
      </nav>

      <div className="mb-10 rounded-3xl border border-slate-200 bg-white p-8 shadow-sm">
        <p className="text-xs font-semibold uppercase tracking-[0.18em] text-emerald-600">
          {getIngredientCategoryLabel(category)}
        </p>
        <h1 className="mt-3 text-3xl font-black tracking-tight text-slate-900">
          {getIngredientCategoryLabel(category)} 원료
        </h1>
        <p className="mt-3 max-w-3xl text-slate-500">
          {getIngredientCategoryDescription(category)}
        </p>
        <div className="mt-5 flex flex-wrap gap-2">
          {INGREDIENT_CATEGORY_ORDER.map((item) => (
            <Link
              key={item}
              href={`/ingredients/category/${item}`}
              className={[
                "rounded-full border px-3 py-1.5 text-sm font-medium transition-colors",
                item === category
                  ? "border-emerald-600 bg-emerald-600 text-white"
                  : "border-slate-200 bg-slate-50 text-slate-500 hover:border-emerald-200 hover:text-emerald-700",
              ].join(" ")}
            >
              {getIngredientCategoryLabel(item)}
            </Link>
          ))}
        </div>
        <p className="mt-6 text-sm font-medium text-slate-400">
          총 {categoryIngredients.length.toLocaleString()}개 원료
        </p>
      </div>

      <div className="space-y-10">
        {grouped.map(([groupName, items]) => (
          <section key={groupName}>
            <div className="mb-5 flex items-center justify-between gap-4">
              <div>
                <h2 className="text-xl font-bold text-slate-900">{groupName}</h2>
                <p className="mt-1 text-sm text-slate-400">{items.length.toLocaleString()}개 원료</p>
              </div>
            </div>
            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
              {items.map((ingredient) => (
                <IngredientCard
                  key={ingredient.id}
                  ingredient={ingredient}
                  subgroupLabel={category === "probiotics" ? groupName : null}
                />
              ))}
            </div>
          </section>
        ))}
      </div>
    </div>
  );
}

function groupIngredients(
  ingredients: IngredientRow[],
  category: IngredientCategory,
): Array<[string, IngredientRow[]]> {
  if (category === "probiotics") {
    const grouped = ingredients.reduce<Record<string, IngredientRow[]>>((acc, ingredient) => {
      const subgroup = getProbioticSubgroup({
        canonicalNameKo: ingredient.canonical_name_ko,
        canonicalNameEn: ingredient.canonical_name_en,
        scientificName: ingredient.scientific_name,
      });
      if (!acc[subgroup]) acc[subgroup] = [];
      acc[subgroup].push(ingredient);
      return acc;
    }, {});

    const probioticOrder = [
      "락토바실러스 계열",
      "비피도박테리움 계열",
      "스트렙토코커스/엔테로코커스",
      "효모/포자균 계열",
      "기능성·복합 균주",
      "일반 프로바이오틱스",
      "기타 균주",
    ];

    return probioticOrder
      .map((groupName) => [groupName, grouped[groupName] ?? []] as [string, IngredientRow[]])
      .filter(([, items]) => items.length > 0);
  }

  if (category === "others") {
    const grouped = ingredients.reduce<Record<string, IngredientRow[]>>((acc, ingredient) => {
      const subgroup = getIngredientSubgroupLabel(ingredient.ingredient_type);
      if (!acc[subgroup]) acc[subgroup] = [];
      acc[subgroup].push(ingredient);
      return acc;
    }, {});

    const otherOrder = ["아미노산", "효소", "기타"];

    return otherOrder
      .map((groupName) => [groupName, grouped[groupName] ?? []] as [string, IngredientRow[]])
      .filter(([, items]) => items.length > 0);
  }

  return [[getIngredientCategoryLabel(category), ingredients]];
}

function ErrorState({ message }: { message: string }) {
  return (
    <div className="mx-auto max-w-6xl px-4 py-12 text-center">
      <p className="text-red-500">데이터를 불러오지 못했습니다: {message}</p>
      <p className="mt-2 text-sm text-gray-400">Supabase 연결을 확인해 주세요.</p>
    </div>
  );
}
