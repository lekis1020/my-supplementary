import { describe, it, expect } from "vitest";
import { buildBenefitGroups, type StrainClaimInput } from "./probiotic-comparison";

function input(overrides: Partial<StrainClaimInput>): StrainClaimInput {
  return {
    ingredientId: 1,
    slug: "s",
    strainName: "S",
    scientificName: null,
    cfuText: null,
    claimCode: "GUT_HEALTH",
    claimNameKo: "장 건강에 도움",
    evidenceGrade: "B",
    evidenceSummary: null,
    allowedExpression: null,
    isRegulatorApproved: false,
    ...overrides,
  };
}

describe("buildBenefitGroups", () => {
  it("returns axes in fixed order and drops empty axes", () => {
    const groups = buildBenefitGroups([
      input({ ingredientId: 1, slug: "a", strainName: "A", claimCode: "IMMUNE_FUNCTION" }),
      input({ ingredientId: 2, slug: "b", strainName: "B", claimCode: "GUT_HEALTH" }),
    ]);
    expect(groups.map((g) => g.claimCode)).toEqual(["GUT_HEALTH", "IMMUNE_FUNCTION"]);
  });

  it("sorts regulator-approved first, then grade A>B>C, then name", () => {
    const groups = buildBenefitGroups([
      input({ ingredientId: 1, slug: "z", strainName: "지", evidenceGrade: "A", isRegulatorApproved: false }),
      input({ ingredientId: 2, slug: "x", strainName: "가", evidenceGrade: "C", isRegulatorApproved: true }),
      input({ ingredientId: 3, slug: "y", strainName: "나", evidenceGrade: "A", isRegulatorApproved: true }),
    ]);
    const gut = groups.find((g) => g.claimCode === "GUT_HEALTH")!;
    expect(gut.rows.map((r) => r.strainName)).toEqual(["나", "가", "지"]);
  });

  it("merges R0052 + R0175 into a single combination row under MENTAL_HEALTH", () => {
    const groups = buildBenefitGroups([
      input({ ingredientId: 10, slug: "lactobacillus-helveticus-r0052", strainName: "R0052", claimCode: "MENTAL_HEALTH", evidenceGrade: "B" }),
      input({ ingredientId: 11, slug: "bifidobacterium-longum-r0175", strainName: "R0175", claimCode: "MENTAL_HEALTH", evidenceGrade: "B" }),
    ]);
    const mental = groups.find((g) => g.claimCode === "MENTAL_HEALTH")!;
    expect(mental.rows).toHaveLength(1);
    expect(mental.rows[0].isCombination).toBe(true);
    expect(mental.rows[0].href).toBeNull();
    expect(mental.rows[0].strainName).toContain("R0052");
    expect(mental.rows[0].strainName).toContain("R0175");
  });

  it("builds href from slug for normal strains", () => {
    const groups = buildBenefitGroups([input({ slug: "lactobacillus-rhamnosus-gg" })]);
    expect(groups[0].rows[0].href).toBe("/ingredients/lactobacillus-rhamnosus-gg");
    expect(groups[0].rows[0].isCombination).toBe(false);
  });
});
