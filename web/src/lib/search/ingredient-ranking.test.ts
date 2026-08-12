import { describe, it, expect } from "vitest";
import {
  buildIngredientSearchResult,
  getIngredientMatchKind,
  getIngredientMatchScore,
  includesProbioticKeyword,
  isGenericProbioticQuery,
  normalizeSearchToken,
} from "./ingredient-ranking";

interface TestIngredient {
  id: number;
  canonical_name_ko: string;
  canonical_name_en: string | null;
  display_name: string | null;
  slug: string | null;
  ingredient_type: string;
}

function ingredient(overrides: Partial<TestIngredient>): TestIngredient {
  return {
    id: 1,
    canonical_name_ko: "마그네슘",
    canonical_name_en: "Magnesium",
    display_name: "마그네슘",
    slug: "magnesium",
    ingredient_type: "mineral",
    ...overrides,
  };
}

describe("normalizeSearchToken", () => {
  it("lowercases, strips whitespace, and trims", () => {
    expect(normalizeSearchToken(" Vitamin D3 ")).toBe("vitamind3");
  });

  it("returns empty string for null", () => {
    expect(normalizeSearchToken(null)).toBe("");
  });

  it("returns empty string for undefined", () => {
    expect(normalizeSearchToken(undefined)).toBe("");
  });

  it("returns empty string for an empty string", () => {
    expect(normalizeSearchToken("")).toBe("");
  });

  it("collapses internal whitespace (not just leading/trailing)", () => {
    expect(normalizeSearchToken("유산균  나라")).toBe("유산균나라");
  });

  it("is case-insensitive for mixed-case English input", () => {
    expect(normalizeSearchToken("LAB")).toBe(normalizeSearchToken("lab"));
  });
});

describe("isGenericProbioticQuery", () => {
  it("matches a normalized keyword exactly", () => {
    expect(isGenericProbioticQuery(normalizeSearchToken("프로바이오틱스"))).toBe(true);
  });

  it("matches 유산균", () => {
    expect(isGenericProbioticQuery(normalizeSearchToken("유산균"))).toBe(true);
  });

  it("matches english 'probiotics' case-insensitively", () => {
    expect(isGenericProbioticQuery(normalizeSearchToken("Probiotics"))).toBe(true);
  });

  it("does not match a query that merely contains a keyword as substring", () => {
    // isGenericProbioticQuery requires an exact token match, unlike includesProbioticKeyword
    expect(isGenericProbioticQuery(normalizeSearchToken("락토바실러스 유산균"))).toBe(false);
  });

  it("returns false for an unrelated query", () => {
    expect(isGenericProbioticQuery(normalizeSearchToken("마그네슘"))).toBe(false);
  });

  it("returns false for an empty token", () => {
    expect(isGenericProbioticQuery("")).toBe(false);
  });
});

describe("includesProbioticKeyword", () => {
  it("matches when the keyword is a substring of a longer name", () => {
    expect(includesProbioticKeyword("락토바실러스 프로바이오틱스 복합물")).toBe(true);
  });

  it("returns false when no keyword is present", () => {
    expect(includesProbioticKeyword("마그네슘")).toBe(false);
  });

  it("returns false for null/undefined", () => {
    expect(includesProbioticKeyword(null)).toBe(false);
    expect(includesProbioticKeyword(undefined)).toBe(false);
  });
});

describe("getIngredientMatchKind", () => {
  it("returns 'direct' when the query is not a generic probiotic query", () => {
    const magnesium = ingredient({});
    expect(getIngredientMatchKind(magnesium, normalizeSearchToken("마그네슘"))).toBe("direct");
  });

  it("returns 'probiotic-strain-category' for a clearly-identified strain matched by a generic probiotic query", () => {
    // "락토바실러스 람노서스 GG" matches hasClearlyIdentifiedProbioticStrain's Korean species
    // pattern (람노서스) AND includesProbioticKeyword via "락토바실러스" containing no keyword —
    // use a name that also carries a probiotic keyword substring per includesProbioticKeyword.
    const strain = ingredient({
      canonical_name_ko: "락토바실러스 람노서스 GG 프로바이오틱스",
      canonical_name_en: "Lactobacillus rhamnosus GG",
      display_name: "락토바실러스 람노서스 GG 프로바이오틱스",
    });
    expect(
      getIngredientMatchKind(strain, normalizeSearchToken("프로바이오틱스")),
    ).toBe("probiotic-strain-category");
  });

  it("returns 'direct' for the generic probiotics category ingredient itself (not a strain)", () => {
    const probioticsCategory = ingredient({
      canonical_name_ko: "프로바이오틱스",
      canonical_name_en: "Probiotics",
      display_name: "프로바이오틱스",
      slug: "probiotics",
      ingredient_type: "probiotic",
    });
    expect(
      getIngredientMatchKind(probioticsCategory, normalizeSearchToken("프로바이오틱스")),
    ).toBe("direct");
  });

  it("returns 'direct' for a strain matched by a generic query when the strain name carries no probiotic keyword", () => {
    const strainWithoutKeyword = ingredient({
      canonical_name_ko: "락토바실러스 람노서스 GG",
      canonical_name_en: "Lactobacillus rhamnosus GG",
      display_name: "락토바실러스 람노서스 GG",
    });
    expect(
      getIngredientMatchKind(strainWithoutKeyword, normalizeSearchToken("프로바이오틱스")),
    ).toBe("direct");
  });
});

describe("getIngredientMatchScore", () => {
  it("scores an exact token match higher than a prefix match", () => {
    // canonical_name_ko/display_name/canonical_name_en all deliberately set (not left to
    // ingredient()'s magnesium defaults) so only the intended field drives the score.
    const exact = ingredient({
      canonical_name_ko: "마그네슘",
      display_name: "마그네슘",
      canonical_name_en: "Magnesium",
    });
    const prefix = ingredient({
      canonical_name_ko: "마그네슘옥사이드",
      display_name: "마그네슘옥사이드",
      canonical_name_en: "Magnesium Oxide",
    });
    const token = normalizeSearchToken("마그네슘");

    const exactScore = getIngredientMatchScore(exact, token);
    const prefixScore = getIngredientMatchScore(prefix, token);

    expect(exactScore).toBeGreaterThan(prefixScore);
    expect(exactScore).toBe(120);
    expect(prefixScore).toBe(100);
  });

  it("scores a prefix match higher than a mid-string substring match", () => {
    const prefix = ingredient({
      canonical_name_ko: "마그네슘옥사이드",
      display_name: "마그네슘옥사이드",
      canonical_name_en: "Magnesium Oxide",
    });
    const substring = ingredient({
      canonical_name_ko: "산화마그네슘",
      display_name: "산화마그네슘",
      canonical_name_en: "Magnesium Oxide (as oxide)",
    });
    const token = normalizeSearchToken("마그네슘");

    expect(getIngredientMatchScore(prefix, token)).toBeGreaterThan(
      getIngredientMatchScore(substring, token),
    );
    expect(getIngredientMatchScore(substring, token)).toBe(80);
  });

  it("scores 0 when no field matches the query token at all", () => {
    const unrelated = ingredient({
      canonical_name_ko: "비타민 D",
      canonical_name_en: "Vitamin D",
      display_name: "비타민 D",
    });
    expect(getIngredientMatchScore(unrelated, normalizeSearchToken("마그네슘"))).toBe(0);
  });

  it("gives the 'probiotics' slug a +40 bonus for the exact 프로바이오틱스 query", () => {
    const category = ingredient({
      canonical_name_ko: "프로바이오틱스",
      display_name: "프로바이오틱스",
      canonical_name_en: "Probiotics",
      slug: "probiotics",
    });
    const other = ingredient({
      canonical_name_ko: "프로바이오틱스아님", // prefix match, but not exact and not slug=probiotics
      display_name: "프로바이오틱스아님",
      canonical_name_en: null,
      slug: "other-slug",
    });
    const token = normalizeSearchToken("프로바이오틱스");

    // category: exact match (120) + slug bonus (40) = 160
    expect(getIngredientMatchScore(category, token)).toBe(160);
    expect(getIngredientMatchScore(category, token)).toBeGreaterThan(
      getIngredientMatchScore(other, token),
    );
  });

  it("applies a -5 penalty when canonical_name_ko is itself a clearly-identified strain, under the 유산균 query", () => {
    // getIngredientMatchScore calls hasClearlyIdentifiedProbioticStrain(ingredient.canonical_name_ko)
    // directly (the bare string, not the {canonicalNameKo,...} object form used elsewhere). Only
    // display_name is the literal query match here so the exact-match score (120) comes from it,
    // while canonical_name_ko carries a recognizable Korean species token (람노서스) to trigger the
    // penalty branch.
    const strain = ingredient({
      canonical_name_ko: "락토바실러스 람노서스 GG",
      canonical_name_en: "Lactobacillus rhamnosus GG",
      display_name: "유산균",
    });
    expect(getIngredientMatchScore(strain, normalizeSearchToken("유산균"))).toBe(115);
  });
});

describe("buildIngredientSearchResult", () => {
  it("uses the normalized Korean name as the title and omits a redundant Korean subtitle", () => {
    const magnesium = ingredient({});
    const result = buildIngredientSearchResult(magnesium);
    expect(result.title).toBe("마그네슘");
    expect(result.subtitle).toBe("Magnesium");
  });

  it("includes the raw Korean name in the subtitle when normalization changes the title", () => {
    // "프로폴리스" collapsing rule: any name containing 프로폴리스 normalizes down to "프로폴리스"
    const propolis = ingredient({
      canonical_name_ko: "프로폴리스 추출물",
      canonical_name_en: "Propolis Extract",
      display_name: "프로폴리스 추출물",
    });
    const result = buildIngredientSearchResult(propolis);
    expect(result.title).toBe("프로폴리스");
    expect(result.subtitle).toBe("프로폴리스 추출물 · Propolis Extract");
  });

  it("builds the href from slug when present", () => {
    const result = buildIngredientSearchResult(ingredient({ id: 42, slug: "magnesium" }));
    expect(result.href).toBe("/ingredients/magnesium");
  });

  it("falls back to id-based href when slug is null", () => {
    const result = buildIngredientSearchResult(ingredient({ id: 42, slug: null }));
    expect(result.href).toBe("/ingredients/42");
  });

  it("sets subtitle to null when there is no English name and no redundant Korean name", () => {
    const result = buildIngredientSearchResult(
      ingredient({ canonical_name_ko: "마그네슘", canonical_name_en: null, display_name: "마그네슘" }),
    );
    expect(result.subtitle).toBeNull();
  });
});
