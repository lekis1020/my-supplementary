import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import { Badge } from "@/components/ui/badge";
import { getIngredientTypeLabel } from "@/lib/utils";
import type { Metadata } from "next";

export const dynamic = "force-dynamic";

export const metadata: Metadata = {
  title: "원료 사전",
  description: "20종 핵심 영양 원료의 기능성, 안전성, 용량 정보를 확인하세요.",
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

  // ingredient_type별 그룹
  const grouped = (ingredients ?? []).reduce<Record<string, typeof ingredients>>(
    (acc, item) => {
      const type = item.ingredient_type;
      if (!acc[type]) acc[type] = [];
      acc[type]!.push(item);
      return acc;
    },
    {}
  );

  const typeOrder = ["vitamin", "mineral", "fatty_acid", "probiotic", "herbal", "amino_acid", "enzyme", "other"];

  return (
    <div className="mx-auto max-w-6xl px-4 py-12">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900">원료 사전</h1>
        <p className="mt-2 text-gray-500">
          {ingredients?.length ?? 0}종 원료의 기능성, 안전성, 약물 상호작용, 권장 용량 정보
        </p>
      </div>

      {typeOrder.map((type) => {
        const items = grouped[type];
        if (!items || items.length === 0) return null;
        return (
          <section key={type} className="mb-10">
            <h2 className="mb-4 text-xl font-semibold text-gray-800">
              {getIngredientTypeLabel(type)}
            </h2>
            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
              {items.map((ing) => (
                <Link
                  key={ing.id}
                  href={`/ingredients/${ing.slug}`}
                  className="group rounded-lg border border-gray-200 bg-white p-5 transition-shadow hover:shadow-md"
                >
                  <div className="flex items-start justify-between">
                    <div>
                      <h3 className="font-semibold text-gray-900 group-hover:text-green-600">
                        {ing.canonical_name_ko}
                      </h3>
                      {ing.canonical_name_en && (
                        <p className="text-sm text-gray-400">{ing.canonical_name_en}</p>
                      )}
                    </div>
                    <Badge className="bg-gray-100 text-gray-600">
                      {getIngredientTypeLabel(ing.ingredient_type)}
                    </Badge>
                  </div>
                  {ing.description && (
                    <p className="mt-3 line-clamp-2 text-sm text-gray-500">
                      {ing.description}
                    </p>
                  )}
                </Link>
              ))}
            </div>
          </section>
        );
      })}
    </div>
  );
}

function ErrorState({ message }: { message: string }) {
  return (
    <div className="mx-auto max-w-6xl px-4 py-12 text-center">
      <p className="text-red-500">데이터를 불러오지 못했습니다: {message}</p>
      <p className="mt-2 text-sm text-gray-400">
        Supabase 연결을 확인해 주세요.
      </p>
    </div>
  );
}
