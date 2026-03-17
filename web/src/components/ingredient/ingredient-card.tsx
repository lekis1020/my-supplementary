import Link from "next/link";
import { Badge } from "@/components/ui/badge";
import {
  getIngredientHref,
  getIngredientSubgroupLabel,
  getIngredientTypeLabels,
} from "@/lib/utils";

interface IngredientCardProps {
  ingredient: {
    id: number;
    canonical_name_ko: string;
    canonical_name_en: string | null;
    slug: string | null;
    ingredient_type: string;
    description: string | null;
  };
  subgroupLabel?: string | null;
}

export function IngredientCard({ ingredient, subgroupLabel }: IngredientCardProps) {
  const typeLabels = getIngredientTypeLabels(ingredient.ingredient_type);

  return (
    <Link
      href={getIngredientHref({ id: ingredient.id, slug: ingredient.slug })}
      className="group rounded-lg border border-gray-200 bg-white p-5 transition-shadow hover:shadow-md"
    >
      <div className="flex items-start justify-between gap-3">
        <div>
          <h3 className="font-semibold text-gray-900 group-hover:text-green-600">
            {ingredient.canonical_name_ko}
          </h3>
          {ingredient.canonical_name_en && (
            <p className="text-sm text-gray-400">{ingredient.canonical_name_en}</p>
          )}
        </div>
        <div className="flex flex-wrap justify-end gap-1.5">
          {typeLabels.map((label) => (
            <Badge key={label} className="bg-gray-100 text-gray-600">
              {label}
            </Badge>
          ))}
        </div>
      </div>
      {subgroupLabel && !typeLabels.includes(subgroupLabel) && subgroupLabel !== getIngredientSubgroupLabel(ingredient.ingredient_type) && (
        <p className="mt-3 text-xs font-medium uppercase tracking-[0.16em] text-emerald-600">
          {subgroupLabel}
        </p>
      )}
      {ingredient.description && (
        <p className="mt-3 line-clamp-2 text-sm text-gray-500">{ingredient.description}</p>
      )}
    </Link>
  );
}
