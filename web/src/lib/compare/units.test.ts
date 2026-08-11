import { describe, expect, it } from "vitest";
import { normalizeAmount, normalizeUnit, parseNumericValue, resolveIngredientAmount } from "./units";

describe("normalizeUnit", () => {
  it("returns null for a missing unit", () => {
    expect(normalizeUnit(null)).toBeNull();
  });

  // Note: for mass/volume units (unlike CFU/IU), normalizeUnit returns the
  // matched table entry as-is, which also carries its `pattern` RegExp field.
  // toMatchObject is used here to assert the relevant fields without pinning
  // to that incidental `pattern` property.
  it("converts micrograms (mcg/μg/ug/㎍) to the mg compare scale via factor 0.001", () => {
    expect(normalizeUnit("mcg")).toMatchObject({ factor: 0.001, compareKey: "mass-mg", label: "mg" });
    expect(normalizeUnit("μg")).toMatchObject({ factor: 0.001, compareKey: "mass-mg", label: "mg" });
    expect(normalizeUnit("ug")).toMatchObject({ factor: 0.001, compareKey: "mass-mg", label: "mg" });
    expect(normalizeUnit("㎍")).toMatchObject({ factor: 0.001, compareKey: "mass-mg", label: "mg" });
  });

  it("treats mg/㎎ as the mg compare scale via factor 1", () => {
    expect(normalizeUnit("mg")).toMatchObject({ factor: 1, compareKey: "mass-mg", label: "mg" });
    expect(normalizeUnit("㎎")).toMatchObject({ factor: 1, compareKey: "mass-mg", label: "mg" });
  });

  it("converts grams to the mg compare scale via factor 1000", () => {
    expect(normalizeUnit("g")).toMatchObject({ factor: 1000, compareKey: "mass-mg", label: "mg" });
  });

  it("converts mL to the mL compare scale via factor 1 (case-sensitive: only 'ml' or 'mL')", () => {
    expect(normalizeUnit("ml")).toMatchObject({ factor: 1, compareKey: "volume-ml", label: "mL" });
    expect(normalizeUnit("mL")).toMatchObject({ factor: 1, compareKey: "volume-ml", label: "mL" });
  });

  it("converts standalone L to the mL compare scale via factor 1000", () => {
    expect(normalizeUnit("L")).toMatchObject({ factor: 1000, compareKey: "volume-ml", label: "mL" });
    expect(normalizeUnit("l")).toMatchObject({ factor: 1000, compareKey: "volume-ml", label: "mL" });
  });

  it("recognizes IU with factor 1", () => {
    expect(normalizeUnit("IU")).toEqual({ factor: 1, compareKey: "count-iu", label: "IU" });
    expect(normalizeUnit("iu")).toEqual({ factor: 1, compareKey: "count-iu", label: "IU" });
  });

  it("recognizes bare CFU with factor 1", () => {
    expect(normalizeUnit("CFU")).toEqual({ factor: 1, compareKey: "count-cfu", label: "CFU" });
  });

  it("recognizes Korean magnitude-prefixed CFU (억/천만/백만/만) with their real multipliers", () => {
    expect(normalizeUnit("억 CFU")).toEqual({ factor: 100000000, compareKey: "count-cfu", label: "CFU" });
    expect(normalizeUnit("천만CFU")).toEqual({ factor: 10000000, compareKey: "count-cfu", label: "CFU" });
    expect(normalizeUnit("백만 cfu")).toEqual({ factor: 1000000, compareKey: "count-cfu", label: "CFU" });
    expect(normalizeUnit("만cfu")).toEqual({ factor: 10000, compareKey: "count-cfu", label: "CFU" });
  });

  it("returns null for an unrecognized unit (e.g. tablet count '정')", () => {
    expect(normalizeUnit("정")).toBeNull();
  });

  it("normalizes internal whitespace before matching", () => {
    expect(normalizeUnit("  mg  ")).toMatchObject({ factor: 1, compareKey: "mass-mg", label: "mg" });
  });
});

describe("parseNumericValue", () => {
  it("returns null for null or empty input", () => {
    expect(parseNumericValue(null)).toBeNull();
    expect(parseNumericValue("")).toBeNull();
  });

  it("returns null when no digits are present", () => {
    expect(parseNumericValue("abc")).toBeNull();
  });

  it("strips thousands-separator commas before parsing", () => {
    expect(parseNumericValue("1,000")).toBe(1000);
    expect(parseNumericValue("1,234.5mg")).toBe(1234.5);
  });

  it("parses a decimal embedded in surrounding text", () => {
    expect(parseNumericValue("500mg")).toBe(500);
    expect(parseNumericValue(" 12.5 ")).toBe(12.5);
  });

  it("parses a leading negative number", () => {
    expect(parseNumericValue("-5mg")).toBe(-5);
  });

  it("on a range like '10-20', only extracts the first number (real, possibly surprising behavior)", () => {
    // The regex `-?\d+(\.\d+)?` has no global flag, so `.match` stops at the
    // first match: "10". The trailing "-20" is never considered a second
    // number or a negative continuation.
    expect(parseNumericValue("10-20")).toBe(10);
  });
});

describe("normalizeAmount", () => {
  it("normalizes a simple mg amount", () => {
    expect(normalizeAmount(500, "mg")).toEqual({
      displayText: "500 mg",
      normalizedValue: 500,
      compareKey: "mass-mg",
      compareLabel: "mg",
    });
  });

  it("normalizes grams into the mg scale", () => {
    expect(normalizeAmount(1, "g")).toEqual({
      displayText: "1 g",
      normalizedValue: 1000,
      compareKey: "mass-mg",
      compareLabel: "mg",
    });
  });

  it("normalizes micrograms into the mg scale", () => {
    expect(normalizeAmount(500, "mcg")).toEqual({
      displayText: "500 mcg",
      normalizedValue: 0.5,
      compareKey: "mass-mg",
      compareLabel: "mg",
    });
  });

  it("normalizes an IU amount (factor 1, its own compare scale)", () => {
    expect(normalizeAmount(1000, "IU")).toEqual({
      displayText: "1000 IU",
      normalizedValue: 1000,
      compareKey: "count-iu",
      compareLabel: "IU",
    });
  });

  it("falls back to '표기 없음' and null fields when both amount and unit are missing", () => {
    expect(normalizeAmount(null, null)).toEqual({
      displayText: "표기 없음",
      normalizedValue: null,
      compareKey: null,
      compareLabel: null,
    });
  });

  it("keeps a readable displayText but null normalizedValue when the amount text is unparseable", () => {
    expect(normalizeAmount("abc", "mg")).toEqual({
      displayText: "abc mg",
      normalizedValue: null,
      compareKey: null,
      compareLabel: null,
    });
  });

  it("keeps a readable displayText but null normalizedValue when the unit is unrecognized", () => {
    expect(normalizeAmount(100, "정")).toEqual({
      displayText: "100 정",
      normalizedValue: null,
      compareKey: null,
      compareLabel: null,
    });
  });

  it("drops a falsy 0 amount from displayText (Boolean filter quirk) but still normalizes the value", () => {
    // displayText is built via `[amountPerServing, amountUnit].filter(Boolean).join(" ")`,
    // so a numeric 0 is filtered out even though 0 is a legitimate, parseable amount.
    expect(normalizeAmount(0, "mg")).toEqual({
      displayText: "mg",
      normalizedValue: 0,
      compareKey: "mass-mg",
      compareLabel: "mg",
    });
  });
});

describe("resolveIngredientAmount", () => {
  it("prefers amount_per_serving/amount_unit when either is present", () => {
    expect(
      resolveIngredientAmount({
        amount_per_serving: 500,
        amount_unit: "mg",
        daily_amount: 999,
        daily_amount_unit: "g",
      }),
    ).toEqual({
      displayText: "500 mg",
      normalizedValue: 500,
      compareKey: "mass-mg",
      compareLabel: "mg",
    });
  });

  it("falls back to daily_amount/daily_amount_unit when per-serving fields are both absent", () => {
    expect(
      resolveIngredientAmount({
        amount_per_serving: null,
        amount_unit: null,
        daily_amount: 200,
        daily_amount_unit: "mg",
      }),
    ).toEqual({
      displayText: "200 mg",
      normalizedValue: 200,
      compareKey: "mass-mg",
      compareLabel: "mg",
    });
  });

  it("returns the '함량 정보 없음' sentinel when no amount fields are present at all", () => {
    expect(
      resolveIngredientAmount({
        amount_per_serving: null,
        amount_unit: null,
        daily_amount: null,
        daily_amount_unit: null,
      }),
    ).toEqual({
      displayText: "함량 정보 없음",
      normalizedValue: null,
      compareKey: null,
      compareLabel: null,
    });
  });
});
