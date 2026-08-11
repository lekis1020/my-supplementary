import Link from "next/link";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { getIngredientHref, getIngredientTypeLabel } from "@/lib/utils";
import type { Database } from "@/lib/types/supabase";

type IngredientRow = Database["public"]["Tables"]["ingredients"]["Row"];

interface IngredientCardProps {
  ingredient: Pick<
    IngredientRow,
    "id" | "slug" | "canonical_name_ko" | "canonical_name_en" | "ingredient_type" | "description"
  >;
}

export function IngredientCard({ ingredient }: IngredientCardProps) {
  return (
    <Link
      href={getIngredientHref({ id: ingredient.id, slug: ingredient.slug })}
      className="block h-full"
    >
      <Card
        padding="md"
        className="h-full transition hover:border-brand hover:shadow-card-hover"
      >
        <div className="flex items-start justify-between gap-3">
          <div>
            <h3 className="font-bold text-ink">{ingredient.canonical_name_ko}</h3>
            {ingredient.canonical_name_en && (
              <p className="text-sm text-ink-faint">{ingredient.canonical_name_en}</p>
            )}
          </div>
          <Badge variant="tag">{getIngredientTypeLabel(ingredient.ingredient_type)}</Badge>
        </div>
        {ingredient.description && (
          <p className="mt-3 line-clamp-2 text-sm text-ink-muted">{ingredient.description}</p>
        )}
      </Card>
    </Link>
  );
}
