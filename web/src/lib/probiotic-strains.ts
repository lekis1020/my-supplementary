import { getProbioticSubgroup } from "@/lib/utils";

export interface ProbioticStrainMatch {
  key: string;
  label: string;
  subgroup: string;
}

interface KnownProbioticStrain {
  key: string;
  label: string;
  aliases: string[];
}

const KNOWN_PROBIOTIC_STRAINS: KnownProbioticStrain[] = [
  {
    key: "lactobacillus-rhamnosus-gg",
    label: "락토바실러스 람노서스 GG (LGG)",
    aliases: [
      "락토바실러스 람노서스 gg",
      "lactobacillus rhamnosus gg",
      "lacticaseibacillus rhamnosus gg",
      "l. rhamnosus gg",
      "lgg",
      "atcc 53103",
      "atcc53103",
    ],
  },
  {
    key: "bifidobacterium-lactis-bb12",
    label: "비피도박테리움 락티스 BB-12",
    aliases: [
      "비피도박테리움 아니말리스 bb-12",
      "비피도박테리움 락티스 bb-12",
      "bifidobacterium animalis subsp lactis bb-12",
      "bifidobacterium lactis bb-12",
      "b. lactis bb-12",
      "bb-12",
      "bb12",
      "dsm 15954",
      "dsm15954",
    ],
  },
  {
    key: "lactobacillus-acidophilus-ncfm",
    label: "락토바실러스 애시도필루스 NCFM",
    aliases: [
      "락토바실러스 애시도필루스 ncfm",
      "lactobacillus acidophilus ncfm",
      "l. acidophilus ncfm",
      "ncfm",
    ],
  },
  {
    key: "bifidobacterium-longum-bb536",
    label: "비피도박테리움 롱검 BB536",
    aliases: [
      "비피도박테리움 롱검 bb536",
      "bifidobacterium longum bb536",
      "b. longum bb536",
      "bb536",
    ],
  },
  {
    key: "lactobacillus-rhamnosus-hn001",
    label: "락토바실러스 람노서스 HN001",
    aliases: [
      "락토바실러스 람노서스 hn001",
      "lactobacillus rhamnosus hn001",
      "lacticaseibacillus rhamnosus hn001",
      "hn001",
    ],
  },
  {
    key: "bifidobacterium-lactis-hn019",
    label: "비피도박테리움 락티스 HN019",
    aliases: [
      "비피도박테리움 아니말리스 hn019",
      "비피도박테리움 락티스 hn019",
      "bifidobacterium animalis subsp lactis hn019",
      "bifidobacterium lactis hn019",
      "hn019",
      "howaru bifido",
    ],
  },
  {
    key: "lactobacillus-casei-shirota",
    label: "락토바실러스 카제이 시로타",
    aliases: [
      "락토바실러스 카제이 시로타",
      "lactobacillus casei shirota",
      "lacticaseibacillus paracasei shirota",
      "shirota",
      "시로타균",
      "야쿠르트균",
    ],
  },
  {
    key: "lactobacillus-reuteri-dsm17938",
    label: "락토바실러스 로이테리 DSM 17938",
    aliases: [
      "락토바실러스 로이테리 dsm 17938",
      "lactobacillus reuteri dsm 17938",
      "limosilactobacillus reuteri dsm 17938",
      "dsm17938",
      "dsm 17938",
      "biogaia protectis",
    ],
  },
  {
    key: "lactobacillus-plantarum-299v",
    label: "락토플란티바실러스 플란타룸 299v",
    aliases: [
      "락토플란티바실러스 플란타룸 299v",
      "lactiplantibacillus plantarum 299v",
      "lactobacillus plantarum 299v",
      "lp299v",
      "299v",
      "dsm9843",
      "dsm 9843",
    ],
  },
  {
    key: "lactobacillus-helveticus-r0052",
    label: "락토바실러스 헬베티쿠스 R0052",
    aliases: [
      "락토바실러스 헬베티쿠스 r0052",
      "lactobacillus helveticus r0052",
      "r0052",
    ],
  },
  {
    key: "bifidobacterium-longum-r0175",
    label: "비피도박테리움 롱검 R0175",
    aliases: [
      "비피도박테리움 롱검 r0175",
      "bifidobacterium longum r0175",
      "r0175",
    ],
  },
  {
    key: "lactobacillus-gasseri-bnr17",
    label: "락토바실러스 가세리 BNR17",
    aliases: [
      "락토바실러스 가세리 bnr17",
      "lactobacillus gasseri bnr17",
      "bnr17",
      "bnrthin",
      "가세리균",
    ],
  },
  {
    key: "streptococcus-thermophilus",
    label: "스트렙토코커스 써모필루스",
    aliases: [
      "스트렙토코커스 써모필루스",
      "streptococcus thermophilus",
      "s. thermophilus",
      "써모필루스",
    ],
  },
  {
    key: "bifidobacterium-bifidum-bgn4",
    label: "비피도박테리움 비피덤 BGN4",
    aliases: [
      "비피도박테리움 비피덤 bgn4",
      "bifidobacterium bifidum bgn4",
      "bgn4",
    ],
  },
];

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

const KNOWN_STRAIN_INDEX = KNOWN_PROBIOTIC_STRAINS.map((strain) => {
  const aliasSet = new Set<string>([strain.label, ...strain.aliases].map((alias) => normalizeForLookup(alias)));
  return {
    ...strain,
    normalizedAliases: Array.from(aliasSet).filter(Boolean),
  };
});

const KNOWN_ALIAS_MAP = new Map<string, (typeof KNOWN_STRAIN_INDEX)[number]>();
for (const strain of KNOWN_STRAIN_INDEX) {
  for (const alias of strain.normalizedAliases) {
    if (!KNOWN_ALIAS_MAP.has(alias)) {
      KNOWN_ALIAS_MAP.set(alias, strain);
    }
  }
}

function normalizeText(value: string | null | undefined): string {
  return value?.replace(/\s+/g, " ").trim() ?? "";
}

function normalizeForLookup(value: string | null | undefined): string {
  return normalizeText(value)
    .toLowerCase()
    .replace(/[^a-z0-9가-힣]/g, "");
}

function tokenizeForLookup(value: string): Set<string> {
  const chunks = value
    .toLowerCase()
    .split(/[^a-z0-9가-힣]+/)
    .map((chunk) => normalizeForLookup(chunk))
    .filter(Boolean);

  return new Set(chunks);
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

function matchKnownAliasInText(
  normalizedAlias: string,
  mergedNormalized: string,
  mergedTokens: Set<string>,
): boolean {
  if (!normalizedAlias) {
    return false;
  }

  if (normalizedAlias.length <= 3) {
    return mergedTokens.has(normalizedAlias);
  }

  return mergedNormalized.includes(normalizedAlias);
}

function resolveKnownStrain(
  candidate: string,
  mergedNormalized: string,
  mergedTokens: Set<string>,
): (typeof KNOWN_STRAIN_INDEX)[number] | null {
  const normalizedCandidate = normalizeForLookup(candidate);
  if (!normalizedCandidate) {
    return null;
  }

  const direct = KNOWN_ALIAS_MAP.get(normalizedCandidate);
  if (direct) {
    return direct;
  }

  for (const strain of KNOWN_STRAIN_INDEX) {
    if (
      strain.normalizedAliases.some(
        (alias) =>
          alias.length >= 4 &&
          (normalizedCandidate.includes(alias) ||
            (normalizedCandidate.length >= 6 && alias.includes(normalizedCandidate))),
      )
    ) {
      return strain;
    }

    if (strain.normalizedAliases.some((alias) => matchKnownAliasInText(alias, mergedNormalized, mergedTokens))) {
      return strain;
    }
  }

  return null;
}

function addKnownMatch(
  matches: Map<string, ProbioticStrainMatch>,
  known: (typeof KNOWN_STRAIN_INDEX)[number],
) {
  matches.set(known.key, {
    key: known.key,
    label: known.label,
    subgroup: buildSubgroup(known.label),
  });
}

function addCandidateMatch(
  matches: Map<string, ProbioticStrainMatch>,
  candidateLabel: string,
  mergedNormalized: string,
  mergedTokens: Set<string>,
) {
  const known = resolveKnownStrain(candidateLabel, mergedNormalized, mergedTokens);
  if (known) {
    addKnownMatch(matches, known);
    return;
  }

  const key = normalizeKey(candidateLabel);
  if (!key) {
    return;
  }

  if (!matches.has(key)) {
    matches.set(key, {
      key,
      label: candidateLabel,
      subgroup: buildSubgroup(candidateLabel),
    });
  }
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
  const mergedNormalized = normalizeForLookup(mergedText);
  const mergedTokens = tokenizeForLookup(mergedText);
  const matches = new Map<string, ProbioticStrainMatch>();

  for (const known of KNOWN_STRAIN_INDEX) {
    if (
      known.normalizedAliases.some((alias) =>
        matchKnownAliasInText(alias, mergedNormalized, mergedTokens),
      )
    ) {
      addKnownMatch(matches, known);
    }
  }

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

      addCandidateMatch(matches, label, mergedNormalized, mergedTokens);
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
        addCandidateMatch(matches, label, mergedNormalized, mergedTokens);
      }

      abbreviatedMatch = ABBREVIATED_STRAIN_PATTERN.exec(text);
    }
  }

  STRAIN_CODE_PATTERN.lastIndex = 0;
  let strainCodeMatch: RegExpExecArray | null = STRAIN_CODE_PATTERN.exec(mergedText);

  while (strainCodeMatch) {
    const code = strainCodeMatch[1]?.toUpperCase();
    if (code) {
      addCandidateMatch(matches, code, mergedNormalized, mergedTokens);
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
