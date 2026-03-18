export const COMPARE_STORAGE_KEY = "nutricompare:selected-product-ids";
export const COMPARE_MAX_PRODUCTS = 4;

export function normalizeCompareIds(ids: number[]): number[] {
  return Array.from(new Set(ids.filter((id) => Number.isInteger(id) && id > 0))).slice(
    0,
    COMPARE_MAX_PRODUCTS,
  );
}

export function parseCompareIds(input: string | null | undefined): number[] {
  if (!input) return [];

  return normalizeCompareIds(
    input
      .split(",")
      .map((value) => Number(value.trim()))
      .filter((value) => Number.isInteger(value) && value > 0),
  );
}

export function buildCompareHref(ids: number[]): string {
  const normalizedIds = normalizeCompareIds(ids);

  if (normalizedIds.length === 0) {
    return "/compare";
  }

  return `/compare?ids=${normalizedIds.join(",")}`;
}
