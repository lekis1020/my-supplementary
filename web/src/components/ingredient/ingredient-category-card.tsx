import Link from "next/link";
import { Badge } from "@/components/ui/badge";
import type { IngredientCategory } from "@/lib/utils";
import { getIngredientCategoryDescription, getIngredientCategoryLabel } from "@/lib/utils";

interface IngredientCategoryCardProps {
  category: IngredientCategory;
  count: number;
  examples: string[];
}

export function IngredientCategoryCard({
  category,
  count,
  examples,
}: IngredientCategoryCardProps) {
  return (
    <Link
      href={`/ingredients/category/${category}`}
      className="group rounded-2xl border border-slate-200 bg-white p-6 shadow-sm transition-all hover:-translate-y-0.5 hover:border-emerald-200 hover:shadow-lg"
    >
      <div className="flex items-start justify-between gap-4">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.18em] text-emerald-600">
            Ingredient Category
          </p>
          <h2 className="mt-2 text-2xl font-black tracking-tight text-slate-900 group-hover:text-emerald-700">
            {getIngredientCategoryLabel(category)}
          </h2>
        </div>
        <Badge className="bg-slate-100 text-slate-600">{count.toLocaleString()}개</Badge>
      </div>
      <p className="mt-4 text-sm leading-6 text-slate-500">
        {getIngredientCategoryDescription(category)}
      </p>
      {examples.length > 0 && (
        <div className="mt-5 flex flex-wrap gap-2">
          {examples.slice(0, 4).map((example) => (
            <span
              key={example}
              className="rounded-full border border-slate-200 bg-slate-50 px-3 py-1 text-xs text-slate-500"
            >
              {example}
            </span>
          ))}
        </div>
      )}
      <div className="mt-6 text-sm font-semibold text-emerald-700">카테고리 열기</div>
    </Link>
  );
}
