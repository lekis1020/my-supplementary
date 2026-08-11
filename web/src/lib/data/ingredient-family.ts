// Ingredient "family" resolution — groups a probiotic strain page with its
// parent/sibling strains, and a propolis-derivative page with its sibling
// propolis extracts, so claims/evidence and cross-navigation can be merged
// across the family instead of showing a single (often evidence-sparse) row.
//
// Moved out of `web/src/app/ingredients/[slug]/page.tsx` (former L226–330).

import type { SupabaseClient } from "@supabase/supabase-js";
import type { Database } from "@/lib/types/supabase";
import { getIngredientCategory, hasClearlyIdentifiedProbioticStrain } from "@/lib/utils";

export interface FamilyResolution {
  /** Family root id + siblings + self, deduped. Always includes the ingredient's own id. */
  relatedIngredientIds: number[];
  /** Resolved probiotic family root id, or null when this ingredient has no probiotic family. */
  familyRootId: number | null;
  /** Display name of the family root, for building an id→name lookup. */
  familyRootName: string | null;
  /** Sibling ingredients under the family root (empty when familyRootId is null). */
  relatedIngredients: Array<{ id: number; canonical_name_ko: string }>;
}

export interface PropolisFamilyResolution {
  propolisFamilyRoot: { id: number; canonical_name_ko: string } | null;
  propolisFamilyChildren: Array<{ id: number; canonical_name_ko: string }>;
}

const PROPOLIS_FAMILY_ROOT_NAME = "프로폴리스추출물";

/**
 * Resolves the probiotic family (parent strain + siblings) for `ingredient`,
 * if it belongs to one. Non-probiotic ingredients resolve to a single-member
 * family containing only themselves.
 *
 * NOTE: `ingredient.canonical_name_ko` / `canonical_name_en` are required
 * (beyond the id/slug/ingredient_type/parent_ingredient_id the task brief's
 * illustrative signature listed) because probiotic-strain detection
 * (`hasClearlyIdentifiedProbioticStrain`) reads the display name — the
 * original page logic cannot run without it.
 */
export async function resolveIngredientFamily(
  supabase: SupabaseClient<Database>,
  ingredient: {
    id: number;
    slug: string | null;
    ingredient_type: string | null;
    parent_ingredient_id: number | null;
    canonical_name_ko: string;
    canonical_name_en: string | null;
  },
): Promise<FamilyResolution> {
  const category = getIngredientCategory(ingredient.ingredient_type ?? "");
  const isProbiotic = category === "probiotics";
  const isLikelyProbioticStrain =
    isProbiotic &&
    hasClearlyIdentifiedProbioticStrain({
      canonicalNameKo: ingredient.canonical_name_ko,
      canonicalNameEn: ingredient.canonical_name_en,
    });

  let familyRoot: { id: number; canonical_name_ko: string } | null = null;

  if (isProbiotic) {
    if (ingredient.parent_ingredient_id) {
      const { data, error } = await supabase
        .from("ingredients")
        .select("id, canonical_name_ko")
        .eq("id", ingredient.parent_ingredient_id)
        .eq("is_published", true)
        .maybeSingle();
      if (error) {
        throw new Error(`ingredient-detail: probiotic family root (by parent): ${error.message}`);
      }
      familyRoot = data ?? null;
    } else if (ingredient.slug === "probiotics") {
      familyRoot = { id: ingredient.id, canonical_name_ko: ingredient.canonical_name_ko };
    } else if (isLikelyProbioticStrain) {
      const { data, error } = await supabase
        .from("ingredients")
        .select("id, canonical_name_ko")
        .eq("slug", "probiotics")
        .eq("is_published", true)
        .maybeSingle();
      if (error) {
        throw new Error(`ingredient-detail: probiotic family root (by slug): ${error.message}`);
      }
      familyRoot = data && data.id !== ingredient.id ? data : null;
    }
  }

  const familyRootId =
    familyRoot?.id ?? (isProbiotic && ingredient.slug === "probiotics" ? ingredient.id : null);

  let relatedIngredients: Array<{ id: number; canonical_name_ko: string }> = [];
  if (familyRootId) {
    const { data, error } = await supabase
      .from("ingredients")
      .select("id, canonical_name_ko")
      .eq("parent_ingredient_id", familyRootId)
      .eq("is_published", true)
      .order("canonical_name_ko");
    if (error) {
      throw new Error(`ingredient-detail: related ingredients: ${error.message}`);
    }
    relatedIngredients = data ?? [];
  }

  const relatedIngredientIds = Array.from(
    new Set([
      ingredient.id,
      ...(familyRootId ? [familyRootId] : []),
      ...relatedIngredients.map((item) => item.id),
    ]),
  );

  return {
    relatedIngredientIds,
    familyRootId,
    familyRootName: familyRoot?.canonical_name_ko ?? null,
    relatedIngredients,
  };
}

/**
 * Resolves the propolis-derivative family (root extract + sibling
 * complex-labeled propolis ingredients) for display-only cross-navigation.
 * Unrelated to `resolveIngredientFamily` — propolis siblings are never
 * merged into claims/evidence, only shown as a navigation card.
 */
export async function resolvePropolisFamily(
  supabase: SupabaseClient<Database>,
  ingredient: { id: number; canonical_name_ko: string },
): Promise<PropolisFamilyResolution> {
  const isPropolisIngredient = ingredient.canonical_name_ko.replace(/\s+/g, "").includes("프로폴리스");
  if (!isPropolisIngredient) {
    return { propolisFamilyRoot: null, propolisFamilyChildren: [] };
  }

  let propolisFamilyRoot: { id: number; canonical_name_ko: string } | null = null;

  if (ingredient.canonical_name_ko === PROPOLIS_FAMILY_ROOT_NAME) {
    propolisFamilyRoot = { id: ingredient.id, canonical_name_ko: ingredient.canonical_name_ko };
  } else {
    const { data, error } = await supabase
      .from("ingredients")
      .select("id, canonical_name_ko")
      .eq("canonical_name_ko", PROPOLIS_FAMILY_ROOT_NAME)
      .eq("is_published", true)
      .maybeSingle();
    if (error) {
      throw new Error(`ingredient-detail: propolis family root: ${error.message}`);
    }
    propolisFamilyRoot = data ?? null;
  }

  let propolisFamilyChildren: Array<{ id: number; canonical_name_ko: string }> = [];
  if (propolisFamilyRoot) {
    const { data, error } = await supabase
      .from("ingredients")
      .select("id, canonical_name_ko")
      .eq("is_published", true)
      .ilike("canonical_name_ko", "%프로폴리스%")
      .neq("id", propolisFamilyRoot.id)
      .order("canonical_name_ko");
    if (error) {
      throw new Error(`ingredient-detail: propolis family children: ${error.message}`);
    }
    propolisFamilyChildren = data ?? [];
  }

  return { propolisFamilyRoot, propolisFamilyChildren };
}
