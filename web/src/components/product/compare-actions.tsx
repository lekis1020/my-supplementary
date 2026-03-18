"use client";

import Link from "next/link";
import { useMemo, useState } from "react";
import type { ReactNode } from "react";
import { ArrowRightLeft, Check, Plus } from "lucide-react";
import {
  buildCompareHref,
  COMPARE_MAX_PRODUCTS,
  COMPARE_STORAGE_KEY,
  normalizeCompareIds,
} from "@/lib/compare";

interface CompareActionsProps {
  productId: number;
}

export function CompareActions({ productId }: CompareActionsProps) {
  const [storedIds, setStoredIds] = useState<number[]>(() => {
    if (typeof window === "undefined") return [];

    const rawValue = window.localStorage.getItem(COMPARE_STORAGE_KEY);
    if (!rawValue) return [];

    try {
      const parsed = JSON.parse(rawValue);
      return Array.isArray(parsed)
        ? normalizeCompareIds(parsed.map((value) => Number(value)))
        : [];
    } catch {
      window.localStorage.removeItem(COMPARE_STORAGE_KEY);
      return [];
    }
  });

  const isSelected = storedIds.includes(productId);
  const compareHref = useMemo(
    () => buildCompareHref(isSelected ? storedIds : [...storedIds, productId]),
    [isSelected, productId, storedIds],
  );

  const addToCompare = () => {
    if (typeof window === "undefined") return;

    const nextIds = normalizeCompareIds([...storedIds, productId]);
    window.localStorage.setItem(COMPARE_STORAGE_KEY, JSON.stringify(nextIds));
    setStoredIds(nextIds);
  };

  const helperText = isSelected
    ? "비교 바구니에 담긴 제품입니다."
    : storedIds.length >= COMPARE_MAX_PRODUCTS
      ? `최대 ${COMPARE_MAX_PRODUCTS}개까지 담을 수 있습니다. 비교 페이지에서 교체해 주세요.`
      : "다른 제품 페이지를 둘러보며 비교 후보를 모을 수 있습니다.";

  return (
    <CardShell>
      <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
        <div>
          <p className="text-sm font-semibold text-slate-900">비교 도구로 보내기</p>
          <p className="mt-1 text-sm text-slate-500">{helperText}</p>
        </div>
        <div className="flex flex-col gap-3 sm:flex-row">
          <button
            type="button"
            onClick={addToCompare}
            disabled={isSelected || storedIds.length >= COMPARE_MAX_PRODUCTS}
            className="inline-flex items-center justify-center gap-2 rounded-xl border border-slate-200 bg-white px-4 py-3 text-sm font-semibold text-slate-700 transition-colors hover:border-emerald-200 hover:text-emerald-700 disabled:cursor-not-allowed disabled:opacity-50"
          >
            {isSelected ? <Check className="h-4 w-4" /> : <Plus className="h-4 w-4" />}
            {isSelected ? "비교에 담김" : "비교에 담기"}
          </button>
          <Link
            href={compareHref}
            onClick={addToCompare}
            className="inline-flex items-center justify-center gap-2 rounded-xl bg-emerald-600 px-4 py-3 text-sm font-semibold text-white transition-colors hover:bg-emerald-700"
          >
            <ArrowRightLeft className="h-4 w-4" />
            지금 비교하기
          </Link>
        </div>
      </div>
    </CardShell>
  );
}

function CardShell({ children }: { children: ReactNode }) {
  return (
    <div className="rounded-2xl border border-emerald-100 bg-[linear-gradient(135deg,#ecfdf5,white_55%)] p-5 shadow-sm">
      {children}
    </div>
  );
}
