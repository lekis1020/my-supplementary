import { describe, it, expect } from "vitest";
import { getPaginationPages, parsePage } from "./pagination";

describe("getPaginationPages", () => {
  it("returns all pages when totalPages <= visibleCount", () => {
    expect(getPaginationPages(1, 5)).toEqual([1, 2, 3, 4, 5]);
  });

  it("returns a single page when there is only one page", () => {
    expect(getPaginationPages(1, 1)).toEqual([1]);
  });

  it("centers the window around the current page in the middle of the range", () => {
    // visibleCount defaults to 10, half = 5; currentPage=15 -> start=10, end=19
    expect(getPaginationPages(15, 30)).toEqual([
      10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
    ]);
  });

  it("clamps the window to the start when currentPage is near page 1", () => {
    expect(getPaginationPages(1, 30)).toEqual([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
  });

  it("clamps the window to the end when currentPage is near the last page", () => {
    expect(getPaginationPages(30, 30)).toEqual([
      21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
    ]);
  });

  it("respects a custom visibleCount", () => {
    expect(getPaginationPages(5, 20, 3)).toEqual([4, 5, 6]);
  });
});

describe("parsePage", () => {
  it("returns 1 for undefined", () => {
    expect(parsePage(undefined)).toBe(1);
  });

  it("parses a valid numeric string", () => {
    expect(parsePage("3")).toBe(3);
  });

  it("floors fractional page values", () => {
    expect(parsePage("2.9")).toBe(2);
  });

  it("returns 1 for negative numbers", () => {
    expect(parsePage("-5")).toBe(1);
  });

  it("returns 1 for zero", () => {
    expect(parsePage("0")).toBe(1);
  });

  it("returns 1 for NaN / non-numeric strings", () => {
    expect(parsePage("abc")).toBe(1);
  });

  it("uses the first element when given an array", () => {
    expect(parsePage(["4", "7"])).toBe(4);
  });

  it("returns 1 for an empty array", () => {
    expect(parsePage([])).toBe(1);
  });
});
