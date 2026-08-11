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
import { useCallback, useSyncExternalStore } from "react";
import {
  COMPARE_STORAGE_KEY,
  normalizeCompareIds as normalizeCompareIdList,
} from "@/lib/compare";

export { COMPARE_STORAGE_KEY } from "@/lib/compare";

export function normalizeCompareIds(input: unknown): number[] {
  const ids = Array.isArray(input) ? input.map((value) => Number(value)) : [];
  return normalizeCompareIdList(ids);
}

const EMPTY_IDS: number[] = [];

// Module-scope store shared by every useCompareStorage() call across the
// app: a set of React-registered listeners plus a raw-string-keyed cache so
// getIdsSnapshot() returns a referentially stable array when the underlying
// localStorage value hasn't changed. useSyncExternalStore requires that
// stability — without it, every render would see a "new" snapshot and React
// would loop re-rendering forever.
const listeners = new Set<() => void>();
let cache: { raw: string | null; ids: number[] } | null = null;
let windowListenersAttached = false;

function notifyListeners(): void {
  for (const listener of listeners) listener();
}

function onStorageEvent(event: StorageEvent): void {
  if (event.key === COMPARE_STORAGE_KEY) {
    notifyListeners();
  }
}

function onFocusEvent(): void {
  notifyListeners();
}

// Attach the real browser listeners only while at least one component is
// subscribed (ref-counted via listeners.size), and detach them once the
// last one unmounts — mirrors the cleanup the previous per-component effect
// did, just centralized here since the store itself is now the shared
// singleton.
function attachWindowListeners(): void {
  if (windowListenersAttached) return;
  windowListenersAttached = true;
  window.addEventListener("storage", onStorageEvent);
  window.addEventListener("focus", onFocusEvent);
}

function detachWindowListeners(): void {
  if (!windowListenersAttached) return;
  windowListenersAttached = false;
  window.removeEventListener("storage", onStorageEvent);
  window.removeEventListener("focus", onFocusEvent);
}

function subscribe(callback: () => void): () => void {
  listeners.add(callback);
  attachWindowListeners();

  return () => {
    listeners.delete(callback);
    if (listeners.size === 0) {
      detachWindowListeners();
    }
  };
}

function readRawValue(): string | null {
  try {
    return window.localStorage.getItem(COMPARE_STORAGE_KEY);
  } catch {
    return null;
  }
}

function parseIds(raw: string | null): number[] {
  if (!raw) return EMPTY_IDS;

  try {
    return normalizeCompareIds(JSON.parse(raw));
  } catch {
    try {
      window.localStorage.removeItem(COMPARE_STORAGE_KEY);
    } catch {
      // Storage unavailable (private mode, quota, disabled) — nothing more
      // to clean up; parseIds already falls through to EMPTY_IDS below.
    }
    return EMPTY_IDS;
  }
}

// The client getSnapshot for the `ids` store. Cached by raw string so
// repeated calls between actual localStorage changes return the exact same
// array reference (see the module-scope comment above for why that's
// required, not just an optimization).
function getIdsSnapshot(): number[] {
  const raw = readRawValue();
  if (cache && cache.raw === raw) return cache.ids;

  const ids = parseIds(raw);
  cache = { raw, ids };
  return ids;
}

function getIdsServerSnapshot(): number[] {
  return EMPTY_IDS;
}

function getIsLoadedSnapshot(): boolean {
  return true;
}

function getIsLoadedServerSnapshot(): boolean {
  return false;
}

function writeCompareIds(ids: number[]): void {
  if (typeof window === "undefined") return;

  try {
    window.localStorage.setItem(COMPARE_STORAGE_KEY, JSON.stringify(ids));
  } catch {
    // localStorage unavailable — fall through and still notify listeners so
    // same-tab consumers reflect the in-memory value below.
  }

  cache = null;
  notifyListeners();
}

/**
 * Shared read/write access to the compare-basket product ids persisted in
 * localStorage. Storage-only: URL `?ids=`/`?compare=` hydration priority is
 * a workbench-specific concern and stays there.
 *
 * Built on useSyncExternalStore, so the localStorage read never happens as
 * a setState call inside an effect: `getServerSnapshot` (and the very first
 * client snapshot before subscription settles) reports `ids: []` /
 * `isLoaded: false`, matching the server-rendered markup and avoiding a
 * hydration mismatch. Once mounted, the client snapshot reflects whatever
 * is actually in storage and `isLoaded` flips to `true`.
 *
 * Cross-tab sync still comes from the `storage` (and `focus`, as a refresh
 * fallback) window events, same as before. Same-tab consumers now also sync
 * through the shared module-scope listener set — `setIds` calls
 * `notifyListeners()` directly since `storage` events never fire in the
 * originating tab — which is at worst an improvement over the previous
 * per-component local state.
 */
export function useCompareStorage(): {
  ids: number[];
  setIds: (ids: number[]) => void;
  isLoaded: boolean;
} {
  const ids = useSyncExternalStore(subscribe, getIdsSnapshot, getIdsServerSnapshot);
  const isLoaded = useSyncExternalStore(
    subscribe,
    getIsLoadedSnapshot,
    getIsLoadedServerSnapshot,
  );

  const setIds = useCallback((next: number[]) => {
    writeCompareIds(normalizeCompareIds(next));
  }, []);

  return { ids, setIds, isLoaded };
}
