import { getProbioticSubgroup } from "@/lib/utils";

export interface ProbioticStrainMatch {
  key: string;
  label: string;
  subgroup: string;
}

const LATIN_GENUS = [
  "lactobacillus",
  "lacticaseibacillus",
  "lactiplantibacillus",
  "limosilactobacillus",
  "bifidobacterium",
  "streptococcus",
  "enterococcus",
  "bacillus",
  "saccharomyces",
] as const;

const ABBREVIATED_GENUS_MAP: Record<string, string> = {
  l: "Lactobacillus",
  b: "Bifidobacterium",
  s: "Streptococcus",
};

const LATIN_STRAIN_PATTERN = new RegExp(
  `\\b(${LATIN_GENUS.join("|")})\\s+([a-z][a-z-]{2,})(?:\\s+(?:subsp\\.?\\s+)?([a-z][a-z-]{2,}|[A-Z0-9-]{2,12}))?(?:\\s+([A-Z0-9-]{2,12}))?`,
  "gi",
);
const ABBREVIATED_STRAIN_PATTERN = /\b([lbs])\.?\s*([a-z][a-z-]{2,})(?:\s+([A-Z0-9-]{2,12}))?/gi;
const STRAIN_CODE_PATTERN = /\b([A-Z]{2,5}-?\d{1,5}[A-Z0-9-]*)\b/g;

const GENERIC_PROBIOTIC_PATTERN = /프로바이오틱스|프로바이오틱|유산균|probiotics?|lactic\s*acid\s*bacteria|\bLAB\b/i;
const NOISE_PATTERN = /프로바이오틱스|프로바이오틱|유산균|혼합|복합|원료|건조물|분말|배양|사균체|열처리|식물성|기타|및|plus|complex/gi;

function normalizeText(value: string | null | undefined): string {
  return value?.replace(/\s+/g, " ").trim() ?? "";
}

function formatLatinLabel(genus: string, species: string, strain?: string | null) {
  const normalizedGenus = `${genus.slice(0, 1).toUpperCase()}${genus.slice(1).toLowerCase()}`;
  const normalizedSpecies = species.toLowerCase();
  const normalizedStrain = strain?.trim();

  return [normalizedGenus, normalizedSpecies, normalizedStrain].filter(Boolean).join(" ");
}

function normalizeKey(value: string): string {
  return value
    .toLowerCase()
    .replace(NOISE_PATTERN, " ")
    .replace(/[^a-z0-9가-힣]/g, "")
    .trim();
}

function buildSubgroup(label: string): string {
  return getProbioticSubgroup({
    canonicalNameKo: label,
    canonicalNameEn: label,
    scientificName: label,
  });
}

export function isLikelyProbioticType(input: {
  ingredientType?: string | null;
  canonicalNameKo?: string | null;
  canonicalNameEn?: string | null;
  rawLabelName?: string | null;
}): boolean {
  const type = normalizeText(input.ingredientType).toLowerCase();
  const haystack = [input.canonicalNameKo, input.canonicalNameEn, input.rawLabelName]
    .map((value) => normalizeText(value).toLowerCase())
    .join(" ");

  return type.includes("probiotic") || GENERIC_PROBIOTIC_PATTERN.test(haystack);
}

export function extractProbioticStrains(input: {
  canonicalNameKo?: string | null;
  canonicalNameEn?: string | null;
  scientificName?: string | null;
  rawLabelName?: string | null;
}): ProbioticStrainMatch[] {
  const texts = [input.rawLabelName, input.canonicalNameKo, input.canonicalNameEn, input.scientificName]
    .map((value) => normalizeText(value))
    .filter(Boolean);

  const mergedText = texts.join(" ");
  const matches = new Map<string, ProbioticStrainMatch>();

  for (const text of texts) {
    LATIN_STRAIN_PATTERN.lastIndex = 0;

    let latinMatch: RegExpExecArray | null = LATIN_STRAIN_PATTERN.exec(text);
    while (latinMatch) {
      const genus = latinMatch[1] ?? "";
      const species = latinMatch[2] ?? "";
      const maybeSubspecies = latinMatch[3] ?? "";
      const maybeStrain = latinMatch[4] ?? "";

      const strain = maybeStrain || (/[A-Z0-9-]{2,}/.test(maybeSubspecies) ? maybeSubspecies : "");
      const label = formatLatinLabel(genus, species, strain);
      const key = normalizeKey(label);

      if (key) {
        matches.set(key, { key, label, subgroup: buildSubgroup(label) });
      }

      latinMatch = LATIN_STRAIN_PATTERN.exec(text);
    }

    ABBREVIATED_STRAIN_PATTERN.lastIndex = 0;
    let abbreviatedMatch: RegExpExecArray | null = ABBREVIATED_STRAIN_PATTERN.exec(text);

    while (abbreviatedMatch) {
      const genusKey = (abbreviatedMatch[1] ?? "").toLowerCase();
      const genus = ABBREVIATED_GENUS_MAP[genusKey];
      const species = abbreviatedMatch[2] ?? "";
      const strain = abbreviatedMatch[3] ?? "";

      if (genus && species) {
        const label = formatLatinLabel(genus, species, strain);
        const key = normalizeKey(label);
        if (key) {
          matches.set(key, { key, label, subgroup: buildSubgroup(label) });
        }
      }

      abbreviatedMatch = ABBREVIATED_STRAIN_PATTERN.exec(text);
    }
  }

  STRAIN_CODE_PATTERN.lastIndex = 0;
  let strainCodeMatch: RegExpExecArray | null = STRAIN_CODE_PATTERN.exec(mergedText);

  while (strainCodeMatch) {
    const code = strainCodeMatch[1]?.toUpperCase();
    if (code) {
      const label = `프로바이오틱스 균주 ${code}`;
      const key = normalizeKey(label);

      if (key && !matches.has(key)) {
        matches.set(key, {
          key,
          label,
          subgroup: "기능성·복합 균주",
        });
      }
    }

    strainCodeMatch = STRAIN_CODE_PATTERN.exec(mergedText);
  }

  const result = Array.from(matches.values());

  if (result.length > 0) {
    return result;
  }

  if (GENERIC_PROBIOTIC_PATTERN.test(mergedText)) {
    const label = "프로바이오틱스 (균주 미상)";
    const key = normalizeKey(label);
    return [{ key, label, subgroup: "일반 프로바이오틱스" }];
  }

  return [];
}
