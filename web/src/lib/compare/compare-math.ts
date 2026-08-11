// Pure comparison-table construction logic for the product comparison workbench.
// No "use client" — this module must be safely importable from server code too.

import { extractProbioticStrains, isLikelyProbioticType } from "@/lib/probiotic-strains";
import { resolveIngredientAmount, type IngredientAmountFields, type NormalizedAmount } from "./units";
import type { Database } from "@/lib/types/supabase";

// Canonical product shape for the comparison workbench and its leaf table
// components. Defined here (not in compare-workbench.tsx) so the pure
// comparison-math module is the single source of truth for every comparison
// type; compare-workbench.tsx re-exports this for its existing consumers.
export type Product = Pick<
  Database["public"]["Tables"]["products"]["Row"],
  "id" | "product_name" | "manufacturer_name" | "country_code"
>;

// Minimal structural shape of the joined `ingredients` relation, as selected by
// compare-workbench's `buildProductIngredientsQuery` (id, canonical_name_ko,
// canonical_name_en, scientific_name, ingredient_type, slug).
export interface ComparisonIngredientRelation {
  id: number;
  canonical_name_ko: string;
  canonical_name_en: string | null;
  scientific_name: string | null;
  ingredient_type: string;
  slug: string | null;
}

// Minimal structural shape of a product_ingredients row (joined with its
// ingredients relation) as consumed by the functions in this module. The
// component's richer, Supabase-derived ProductIngredient type satisfies this
// shape structurally, so the lib never needs to import it.
export interface ComparisonProductIngredient extends IngredientAmountFields {
  ingredient_id: number;
  ingredient_role: string | null;
  raw_label_name: string | null;
  ingredients: ComparisonIngredientRelation | null;
}

export interface IngredientMetaEntry {
  name: string;
  href: string;
}

export interface ComparisonCell<TIngredient extends ComparisonProductIngredient = ComparisonProductIngredient> {
  productId: number;
  ingredient: TIngredient | null;
  amount: NormalizedAmount | null;
}

export interface IngredientComparisonRow<TIngredient extends ComparisonProductIngredient = ComparisonProductIngredient> {
  ingredientId: number;
  ingredientName: string;
  ingredientHref: string;
  cells: ComparisonCell<TIngredient>[];
  productCount: number;
  isComparable: boolean;
  compareLabel: string | null;
  maxComparableValue: number | null;
  duplicate: boolean;
  uniqueOwnerId: number | null;
}

export interface ProbioticStrainCell {
  productId: number;
  present: boolean;
  rawLabels: string[];
  amountTexts: string[];
}

export interface ProbioticStrainRow {
  key: string;
  label: string;
  subgroup: string;
  productCount: number;
  cells: ProbioticStrainCell[];
}

export interface ProbioticStrainGroup {
  subgroup: string;
  rows: ProbioticStrainRow[];
}

// Minimal structural shape of a product row (only what sortProductsByName reads).
export interface SortableProduct {
  product_name: string;
}

export function sortProductsByName(left: SortableProduct, right: SortableProduct) {
  return left.product_name.localeCompare(right.product_name, "ko");
}

export function buildComparisonRow<TIngredient extends ComparisonProductIngredient>(
  ingredientId: number,
  selectedIds: number[],
  productIngredients: Record<number, TIngredient[]>,
  ingredientMap: Map<number, IngredientMetaEntry>,
): IngredientComparisonRow<TIngredient> | null {
  const ingredientMeta = ingredientMap.get(ingredientId);
  if (!ingredientMeta) return null;

  const cells: ComparisonCell<TIngredient>[] = selectedIds.map((productId) => {
    const ingredient =
      (productIngredients[productId] ?? []).find((entry) => entry.ingredient_id === ingredientId) ?? null;
    return {
      productId,
      ingredient,
      amount: ingredient ? resolveIngredientAmount(ingredient) : null,
    };
  });

  const presentCells = cells.filter((cell) => cell.ingredient);
  const compareKeys = new Set(
    presentCells.map((cell) => cell.amount?.compareKey).filter(Boolean) as string[],
  );
  const comparableValues = presentCells
    .map((cell) => cell.amount?.normalizedValue)
    .filter((value): value is number => typeof value === "number" && Number.isFinite(value));

  const isComparable =
    presentCells.length >= 2 &&
    compareKeys.size === 1 &&
    comparableValues.length === presentCells.length;

  return {
    ingredientId,
    ingredientName: ingredientMeta.name,
    ingredientHref: ingredientMeta.href,
    cells,
    productCount: presentCells.length,
    isComparable,
    compareLabel: isComparable ? presentCells[0]?.amount?.compareLabel ?? null : null,
    maxComparableValue: isComparable ? Math.max(...comparableValues) : null,
    duplicate: presentCells.length >= 2,
    uniqueOwnerId: presentCells.length === 1 ? presentCells[0]!.productId : null,
  };
}

export function buildProbioticStrainGroups<TIngredient extends ComparisonProductIngredient>(
  selectedIds: number[],
  productIngredients: Record<number, TIngredient[]>,
): ProbioticStrainGroup[] {
  if (selectedIds.length === 0) {
    return [];
  }

  const rowMap = new Map<
    string,
    {
      label: string;
      subgroup: string;
      byProduct: Map<number, TIngredient[]>;
    }
  >();

  for (const productId of selectedIds) {
    const ingredients = productIngredients[productId] ?? [];

    for (const ingredient of ingredients) {
      const relation = ingredient.ingredients;
      if (!relation) continue;

      if (
        !isLikelyProbioticType({
          ingredientType: relation.ingredient_type,
          canonicalNameKo: relation.canonical_name_ko,
          canonicalNameEn: relation.canonical_name_en,
          rawLabelName: ingredient.raw_label_name,
        })
      ) {
        continue;
      }

      const strains = extractProbioticStrains({
        canonicalNameKo: relation.canonical_name_ko,
        canonicalNameEn: relation.canonical_name_en,
        scientificName: relation.scientific_name,
        rawLabelName: ingredient.raw_label_name,
      });

      for (const strain of strains) {
        const existingRow = rowMap.get(strain.key) ?? {
          label: strain.label,
          subgroup: strain.subgroup,
          byProduct: new Map<number, TIngredient[]>(),
        };
        const currentEntries = existingRow.byProduct.get(productId) ?? [];
        existingRow.byProduct.set(productId, [...currentEntries, ingredient]);
        rowMap.set(strain.key, existingRow);
      }
    }
  }

  const rows: ProbioticStrainRow[] = Array.from(rowMap.entries())
    .map(([key, row]) => {
      const cells = selectedIds.map((productId) => {
        const entries = row.byProduct.get(productId) ?? [];
        const rawLabels = Array.from(
          new Set(entries.map((entry) => entry.raw_label_name).filter(Boolean) as string[]),
        );
        const amountTexts = Array.from(
          new Set(
            entries
              .map((entry) => resolveIngredientAmount(entry).displayText)
              .filter((value) => value !== "함량 정보 없음"),
          ),
        );

        return {
          productId,
          present: entries.length > 0,
          rawLabels,
          amountTexts,
        };
      });

      return {
        key,
        label: row.label,
        subgroup: row.subgroup,
        productCount: cells.filter((cell) => cell.present).length,
        cells,
      };
    })
    .filter((row) => row.productCount > 0)
    .sort((left, right) => {
      if (right.productCount !== left.productCount) {
        return right.productCount - left.productCount;
      }

      return left.label.localeCompare(right.label, "ko");
    });

  const grouped = new Map<string, ProbioticStrainRow[]>();
  for (const row of rows) {
    const current = grouped.get(row.subgroup) ?? [];
    current.push(row);
    grouped.set(row.subgroup, current);
  }

  return Array.from(grouped.entries())
    .map(([subgroup, subgroupRows]) => ({
      subgroup,
      rows: subgroupRows,
    }))
    .sort((left, right) => right.rows.length - left.rows.length);
}
