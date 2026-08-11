import {
  getIngredientHref,
  getIngredientTypeLabel,
  hasClearlyIdentifiedProbioticStrain,
  normalizeIngredientNameForDisplay,
} from "@/lib/utils";

export interface IngredientSearchResult {
  id: number;
  title: string;
  subtitle: string | null;
  href: string;
  badge: string;
}

export type IngredientMatchKind = "direct" | "probiotic-strain-category";

export const PROBIOTIC_QUERY_KEYWORDS = [
  "프로바이오틱스",
  "프로바이오틱",
  "유산균",
  "probiotic",
  "probiotics",
  "lactic acid bacteria",
  "lab",
] as const;

export function normalizeSearchToken(value: string | null | undefined): string {
  if (!value) return "";
  return value.toLowerCase().replace(/\s+/g, "").trim();
}

export function isGenericProbioticQuery(queryToken: string): boolean {
  if (!queryToken) return false;
  return PROBIOTIC_QUERY_KEYWORDS.some(
    (keyword) => normalizeSearchToken(keyword) === queryToken,
  );
}

export function includesProbioticKeyword(value: string | null | undefined): boolean {
  const token = normalizeSearchToken(value);
  if (!token) return false;

  return PROBIOTIC_QUERY_KEYWORDS.some((keyword) =>
    token.includes(normalizeSearchToken(keyword)),
  );
}

export function getIngredientMatchKind<
  T extends {
    canonical_name_ko: string;
    canonical_name_en: string | null;
    display_name: string | null;
  },
>(ingredient: T, queryToken: string): IngredientMatchKind {
  if (!isGenericProbioticQuery(queryToken)) {
    return "direct";
  }

  const isStrain = hasClearlyIdentifiedProbioticStrain({
    canonicalNameKo: ingredient.canonical_name_ko,
    canonicalNameEn: ingredient.canonical_name_en,
    rawLabelName: ingredient.display_name,
  });

  if (!isStrain) {
    return "direct";
  }

  if (
    includesProbioticKeyword(ingredient.canonical_name_ko) ||
    includesProbioticKeyword(ingredient.canonical_name_en) ||
    includesProbioticKeyword(ingredient.display_name)
  ) {
    return "probiotic-strain-category";
  }

  return "direct";
}

export function buildIngredientSearchResult<
  T extends {
    id: number;
    canonical_name_ko: string;
    canonical_name_en: string | null;
    display_name: string | null;
    slug: string | null;
    ingredient_type: string;
  },
>(ingredient: T): IngredientSearchResult {
  const normalizedTitle = normalizeIngredientNameForDisplay(ingredient.canonical_name_ko);
  const subtitleParts: string[] = [];
  const isClearlyStrain = hasClearlyIdentifiedProbioticStrain({
    canonicalNameKo: ingredient.canonical_name_ko,
    canonicalNameEn: ingredient.canonical_name_en,
    rawLabelName: ingredient.display_name,
  });

  if (
    normalizedTitle !== ingredient.canonical_name_ko &&
    ingredient.canonical_name_ko &&
    !isClearlyStrain
  ) {
    subtitleParts.push(ingredient.canonical_name_ko);
  }

  if (ingredient.canonical_name_en) {
    subtitleParts.push(ingredient.canonical_name_en);
  }

  return {
    id: ingredient.id,
    title: normalizedTitle,
    subtitle: subtitleParts.length > 0 ? subtitleParts.join(" · ") : null,
    href: getIngredientHref({ id: ingredient.id, slug: ingredient.slug }),
    badge: getIngredientTypeLabel(ingredient.ingredient_type),
  };
}

export function getIngredientMatchScore<
  T extends {
    canonical_name_ko: string;
    canonical_name_en: string | null;
    display_name: string | null;
    slug: string | null;
  },
>(ingredient: T, queryToken: string): number {
  const fields = [
    ingredient.canonical_name_ko,
    ingredient.display_name,
    ingredient.canonical_name_en,
  ];
  let score = 0;

  for (const field of fields) {
    const token = normalizeSearchToken(field);
    if (!token) continue;

    if (token === queryToken) {
      score = Math.max(score, 120);
      continue;
    }

    if (token.startsWith(queryToken)) {
      score = Math.max(score, 100);
      continue;
    }

    if (token.includes(queryToken)) {
      score = Math.max(score, 80);
      continue;
    }

    if (queryToken.includes(token)) {
      score = Math.max(score, 70);
    }
  }

  if (queryToken === "프로바이오틱스" || queryToken === "유산균") {
    if (ingredient.slug === "probiotics" || normalizeSearchToken(ingredient.canonical_name_ko) === "프로바이오틱스") {
      score += 40;
    }

    if (hasClearlyIdentifiedProbioticStrain(ingredient.canonical_name_ko)) {
      score -= 5;
    }
  }

  return score;
}
