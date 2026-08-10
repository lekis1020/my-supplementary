import { describe, expect, it } from "vitest";
import { badgeVariantClasses } from "@/components/ui/badge";
import {
  evidenceGradeClasses,
  severityClasses,
} from "@/components/ui/domain-badges";

describe("badgeVariantClasses", () => {
  it("returns empty string when variant is omitted (backward compat)", () => {
    expect(badgeVariantClasses(undefined)).toBe("");
  });
  it("maps promo to brand tokens", () => {
    expect(badgeVariantClasses("promo")).toContain("bg-brand-bg");
  });
});

describe("evidenceGradeClasses", () => {
  it("maps grade A to evidence-a tokens", () => {
    expect(evidenceGradeClasses("A")).toContain("evidence-a");
  });
  it("is case-insensitive", () => {
    expect(evidenceGradeClasses("a")).toBe(evidenceGradeClasses("A"));
  });
  it("falls back to I for unknown grades", () => {
    expect(evidenceGradeClasses("Z")).toBe(evidenceGradeClasses("I"));
    expect(evidenceGradeClasses(null)).toBe(evidenceGradeClasses("I"));
  });
});

describe("severityClasses", () => {
  it("maps high to danger tokens", () => {
    expect(severityClasses("high")).toContain("danger");
  });
  it("falls back to low for unknown/null", () => {
    expect(severityClasses(null)).toBe(severityClasses("low"));
    expect(severityClasses("weird")).toBe(severityClasses("low"));
  });
});
