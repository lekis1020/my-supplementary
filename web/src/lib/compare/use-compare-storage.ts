"use client";

// This is the one exception to "lib is pure" in this directory: it's a React
// hook, so it needs "use client". COMPARE_STORAGE_KEY is re-exported
// (not redefined) from @/lib/compare, which stays the single,
// framework-free source of truth for the key string — other pure helpers
// there (parseCompareIds, buildCompareHref) depend on it too, and keeping
// the canonical definition in a plain module avoids that module ever
// needing to import from a "use client" file.
//
// normalizeCompareIds here is a thin `unknown`-accepting wrapper (per the
// hook contract, so it can take raw JSON.parse() output straight from
// localStorage) that delegates the actual dedupe/cap-at-4 rule to
// @/lib/compare's normalizeCompareIds(number[]) — the single implementation
// of that rule, unchanged and still used as-is by parseCompareIds/
// buildCompareHref.
import { useCallback, useEffect, useState } from "react";
import {
  COMPARE_STORAGE_KEY,
  normalizeCompareIds as normalizeCompareIdList,
} from "@/lib/compare";

export { COMPARE_STORAGE_KEY } from "@/lib/compare";

export function normalizeCompareIds(input: unknown): number[] {
  const ids = Array.isArray(input) ? input.map((value) => Number(value)) : [];
  return normalizeCompareIdList(ids);
}

function readCompareIds(): number[] {
  if (typeof window === "undefined") return [];

  try {
    const rawValue = window.localStorage.getItem(COMPARE_STORAGE_KEY);
    if (!rawValue) return [];

    return normalizeCompareIds(JSON.parse(rawValue));
  } catch {
    window.localStorage.removeItem(COMPARE_STORAGE_KEY);
    return [];
  }
}

function writeCompareIds(ids: number[]): void {
  if (typeof window === "undefined") return;

  window.localStorage.setItem(COMPARE_STORAGE_KEY, JSON.stringify(ids));
}

/**
 * Shared read/write access to the compare-basket product ids persisted in
 * localStorage. Storage-only: URL `?ids=`/`?compare=` hydration priority is
 * a workbench-specific concern and stays there.
 *
 * The initial read happens in an effect (not a useState initializer) so the
 * very first client render matches the server-rendered `[]` and avoids a
 * hydration mismatch; `isLoaded` flips to `true` once that read completes.
 */
export function useCompareStorage(): {
  ids: number[];
  setIds: (ids: number[]) => void;
  isLoaded: boolean;
} {
  const [ids, setIdsState] = useState<number[]>([]);
  const [isLoaded, setIsLoaded] = useState(false);

  useEffect(() => {
    setIdsState(readCompareIds());
    setIsLoaded(true);

    const onStorage = (event: StorageEvent) => {
      if (event.key === COMPARE_STORAGE_KEY) {
        setIdsState(readCompareIds());
      }
    };
    const onFocus = () => setIdsState(readCompareIds());

    window.addEventListener("storage", onStorage);
    window.addEventListener("focus", onFocus);
    return () => {
      window.removeEventListener("storage", onStorage);
      window.removeEventListener("focus", onFocus);
    };
  }, []);

  const setIds = useCallback((next: number[]) => {
    const normalized = normalizeCompareIds(next);
    writeCompareIds(normalized);
    setIdsState(normalized);
  }, []);

  return { ids, setIds, isLoaded };
}
