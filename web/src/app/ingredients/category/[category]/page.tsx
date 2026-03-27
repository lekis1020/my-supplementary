import Link from "next/link";
import { notFound } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { IngredientCard } from "@/components/ingredient/ingredient-card";
import { getVitaminSideEffectInfoBySubgroup } from "@/lib/vitamin-side-effects";
import {
  getIngredientCategories,
  getIngredientCategoryDescription,
  getIngredientCategoryLabel,
  getIngredientSubgroupLabel,
  getIngredientTypeLabels,
  getProbioticSubgroup,
  getVitaminSubgroups,
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
    (ingredient) => getIngredientCategories(ingredient.ingredient_type).includes(category),
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
        {category === "vitamins" && (
          <p className="mt-2 text-sm text-slate-500">
            복합 비타민 원료는 포함된 성분 기준으로 여러 세부 분류에 함께 표시됩니다.
            복합 유형 원료는 관련 카테고리에 각각 나뉘어 표시됩니다.
          </p>
        )}
      </div>

      <div className="space-y-10">
        {grouped.map(([groupName, items]) => {
          const sideEffectInfo =
            category === "vitamins" ? getVitaminSideEffectInfoBySubgroup(groupName) : null;

          return (
            <section key={groupName}>
              <div className="mb-5 flex items-center justify-between gap-4">
                <div>
                  <h2 className="text-xl font-bold text-slate-900">{groupName}</h2>
                  <p className="mt-1 text-sm text-slate-400">{items.length.toLocaleString()}개 원료</p>
                  {sideEffectInfo && (
                    <div className="mt-2 rounded-xl border border-amber-200 bg-amber-50 px-3 py-2 text-xs text-amber-900">
                      <p className="font-semibold">부작용 요약</p>
                      <p className="mt-1">{sideEffectInfo.summary}</p>
                      <p className="mt-1 text-amber-700">주의: {sideEffectInfo.caution}</p>
                      <a
                        href={sideEffectInfo.referenceUrl}
                        target="_blank"
                        rel="noreferrer"
                        className="mt-1 inline-block font-medium underline decoration-amber-400 underline-offset-2"
                      >
                        참고문헌(ODS)
                      </a>
                    </div>
                  )}
                </div>
              </div>
              <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
                {items.map((ingredient) => (
                  <IngredientCard
                    key={ingredient.id}
                    ingredient={ingredient}
                    subgroupLabel={
                      category === "probiotics" || category === "vitamins" ? groupName : null
                    }
                  />
                ))}
              </div>
            </section>
          );
        })}
      </div>
    </div>
  );
}

function groupIngredients(
  ingredients: IngredientRow[],
  category: IngredientCategory,
): Array<[string, IngredientRow[]]> {
  if (category === "vitamins") {
    const grouped = ingredients.reduce<Record<string, IngredientRow[]>>((acc, ingredient) => {
      const subgroups = getVitaminSubgroups({
        canonicalNameKo: ingredient.canonical_name_ko,
        canonicalNameEn: ingredient.canonical_name_en,
        scientificName: ingredient.scientific_name,
      });

      subgroups.forEach((subgroup) => {
        if (!acc[subgroup]) acc[subgroup] = [];
        acc[subgroup].push(ingredient);
      });

      return acc;
    }, {});

    const vitaminOrder = [
      "비타민 A",
      "비타민 B군",
      "비타민 B1",
      "비타민 B2",
      "비타민 B3",
      "비타민 B5",
      "비타민 B6",
      "비타민 B7",
      "비타민 B9",
      "비타민 B12",
      "비타민 C",
      "비타민 D",
      "비타민 E",
      "비타민 K",
      "루테인·카로티노이드",
      "기타 복합 비타민",
    ];

    return vitaminOrder
      .map((groupName) => [groupName, grouped[groupName] ?? []] as [string, IngredientRow[]])
      .filter(([, items]) => items.length > 0);
  }

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
      const subgroups = getIngredientTypeLabels(ingredient.ingredient_type).filter((label) =>
        ["아미노산", "효소", "기타"].includes(label),
      );

      (subgroups.length > 0 ? subgroups : [getIngredientSubgroupLabel(ingredient.ingredient_type)]).forEach(
        (subgroup) => {
          if (!acc[subgroup]) acc[subgroup] = [];
          acc[subgroup].push(ingredient);
        },
      );

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
