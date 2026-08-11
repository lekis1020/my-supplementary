// Pure unit-normalization logic for the product comparison workbench.
// No "use client" — this module must be safely importable from server code too.

export interface NormalizedAmount {
  displayText: string;
  normalizedValue: number | null;
  compareKey: string | null;
  compareLabel: string | null;
}

// Minimal structural shape of the fields resolveIngredientAmount reads off a
// product_ingredients row. Callers (e.g. compare-math.ts) can pass their own
// richer row types as long as they satisfy this shape.
export interface IngredientAmountFields {
  amount_per_serving: string | number | null;
  amount_unit: string | null;
  daily_amount: string | number | null;
  daily_amount_unit: string | null;
}

const MASS_UNIT_FACTORS: Array<{ pattern: RegExp; factor: number; compareKey: string; label: string }> = [
  { pattern: /(mcg|μg|ug|㎍)/i, factor: 0.001, compareKey: "mass-mg", label: "mg" },
  { pattern: /(mg|㎎)/i, factor: 1, compareKey: "mass-mg", label: "mg" },
  { pattern: /\bg\b/i, factor: 1000, compareKey: "mass-mg", label: "mg" },
];

const VOLUME_UNIT_FACTORS: Array<{ pattern: RegExp; factor: number; compareKey: string; label: string }> = [
  { pattern: /(ml|mL)/, factor: 1, compareKey: "volume-ml", label: "mL" },
  { pattern: /\bl\b/i, factor: 1000, compareKey: "volume-ml", label: "mL" },
];

const CFU_UNIT_FACTORS: Array<{ pattern: RegExp; factor: number }> = [
  { pattern: /억\s*cfu/i, factor: 100000000 },
  { pattern: /천만\s*cfu/i, factor: 10000000 },
  { pattern: /백만\s*cfu/i, factor: 1000000 },
  { pattern: /만\s*cfu/i, factor: 10000 },
  { pattern: /cfu/i, factor: 1 },
];

export function normalizeAmount(amountPerServing: string | number | null, amountUnit: string | null): NormalizedAmount {
  const amountText = amountPerServing == null ? null : String(amountPerServing);
  const displayText = [amountPerServing, amountUnit].filter(Boolean).join(" ").trim() || "표기 없음";
  const numericValue = parseNumericValue(amountText);
  const normalizedUnit = normalizeUnit(amountUnit);

  if (numericValue === null || !normalizedUnit) {
    return {
      displayText,
      normalizedValue: null,
      compareKey: null,
      compareLabel: null,
    };
  }

  return {
    displayText,
    normalizedValue: numericValue * normalizedUnit.factor,
    compareKey: normalizedUnit.compareKey,
    compareLabel: normalizedUnit.label,
  };
}

export function parseNumericValue(value: string | null): number | null {
  if (!value) return null;
  const cleaned = value.replace(/,/g, "").match(/-?\d+(\.\d+)?/);
  if (!cleaned) return null;
  const parsed = Number(cleaned[0]);
  return Number.isFinite(parsed) ? parsed : null;
}

export function resolveIngredientAmount(ingredient: IngredientAmountFields): NormalizedAmount {
  if (ingredient.amount_per_serving != null || ingredient.amount_unit) {
    return normalizeAmount(ingredient.amount_per_serving, ingredient.amount_unit);
  }

  if (ingredient.daily_amount != null || ingredient.daily_amount_unit) {
    return normalizeAmount(ingredient.daily_amount, ingredient.daily_amount_unit);
  }

  return {
    displayText: "함량 정보 없음",
    normalizedValue: null,
    compareKey: null,
    compareLabel: null,
  };
}

export function normalizeUnit(unit: string | null): { factor: number; compareKey: string; label: string } | null {
  if (!unit) return null;
  const normalized = unit.replace(/\s+/g, " ").trim();

  for (const candidate of CFU_UNIT_FACTORS) {
    if (candidate.pattern.test(normalized)) {
      return {
        factor: candidate.factor,
        compareKey: "count-cfu",
        label: "CFU",
      };
    }
  }

  if (/iu/i.test(normalized)) {
    return { factor: 1, compareKey: "count-iu", label: "IU" };
  }

  for (const candidate of MASS_UNIT_FACTORS) {
    if (candidate.pattern.test(normalized)) {
      return candidate;
    }
  }

  for (const candidate of VOLUME_UNIT_FACTORS) {
    if (candidate.pattern.test(normalized)) {
      return candidate;
    }
  }

  return null;
}
