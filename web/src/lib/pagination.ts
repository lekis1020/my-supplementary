const PAGINATION_VISIBLE_COUNT = 10;

export function parsePage(value: string | string[] | undefined): number {
  const pageValue = Array.isArray(value) ? value[0] : value;
  const parsed = Number(pageValue);
  return Number.isFinite(parsed) && parsed > 0 ? Math.floor(parsed) : 1;
}

export function getPaginationPages(
  currentPage: number,
  totalPages: number,
  visibleCount = PAGINATION_VISIBLE_COUNT,
) {
  if (totalPages <= visibleCount) {
    return Array.from({ length: totalPages }, (_, index) => index + 1);
  }

  const half = Math.floor(visibleCount / 2);
  let start = Math.max(1, currentPage - half);
  let end = start + visibleCount - 1;

  if (end > totalPages) {
    end = totalPages;
    start = end - visibleCount + 1;
  }

  return Array.from({ length: end - start + 1 }, (_, index) => start + index);
}
