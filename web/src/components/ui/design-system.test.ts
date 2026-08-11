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
  it("is unaffected by the severity vocabulary change", () => {
    expect(evidenceGradeClasses("C")).toContain("evidence-c");
  });
});

describe("severityClasses", () => {
  it("maps severe to danger tokens", () => {
    expect(severityClasses("severe")).toContain("danger");
  });
  it("maps critical to danger tokens with a border", () => {
    expect(severityClasses("critical")).toContain("danger");
    expect(severityClasses("critical")).toContain("border");
  });
  it("falls back to moderate for unknown/null (never under-warns)", () => {
    expect(severityClasses(null)).toBe(severityClasses("moderate"));
    expect(severityClasses("weird")).toBe(severityClasses("moderate"));
  });
});
