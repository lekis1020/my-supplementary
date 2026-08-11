"use client";

import Link from "next/link";
import { useMemo } from "react";
import { ArrowRightLeft, Check, Plus } from "lucide-react";
import { buildCompareHref, COMPARE_MAX_PRODUCTS } from "@/lib/compare";
import { useCompareStorage } from "@/lib/compare/use-compare-storage";
import { Card } from "@/components/ui/card";

interface CompareActionsProps {
  productId: number;
}

export function CompareActions({ productId }: CompareActionsProps) {
  const { ids: storedIds, setIds: setStoredIds } = useCompareStorage();

  const isSelected = storedIds.includes(productId);
  const compareHref = useMemo(
    () => buildCompareHref(isSelected ? storedIds : [...storedIds, productId]),
    [isSelected, productId, storedIds],
  );

  const addToCompare = () => {
    setStoredIds([...storedIds, productId]);
  };

  const helperText = isSelected
    ? "비교 바구니에 담긴 제품입니다."
    : storedIds.length >= COMPARE_MAX_PRODUCTS
      ? `최대 ${COMPARE_MAX_PRODUCTS}개까지 담을 수 있습니다. 제품 데이터베이스 상단 비교 도구에서 교체해 주세요.`
      : "다른 제품 페이지를 둘러보며 비교 후보를 모을 수 있습니다.";

  return (
    <Card tone="highlight" className="p-5">
      <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
        <div>
          <p className="text-sm font-semibold text-ink">비교 도구로 보내기</p>
          <p className="mt-1 text-sm text-ink-muted">{helperText}</p>
        </div>
        <div className="flex flex-col gap-3 sm:flex-row">
          <button
            type="button"
            onClick={addToCompare}
            disabled={isSelected || storedIds.length >= COMPARE_MAX_PRODUCTS}
            className="inline-flex items-center justify-center gap-2 rounded-xl border border-stone-200 bg-surface px-4 py-3 text-sm font-semibold text-ink-muted transition-colors hover:border-orange-200 hover:text-orange-700 disabled:cursor-not-allowed disabled:opacity-50"
          >
            {isSelected ? <Check className="h-4 w-4" /> : <Plus className="h-4 w-4" />}
            {isSelected ? "비교에 담김" : "비교에 담기"}
          </button>
          <Link
            href={compareHref}
            onClick={addToCompare}
            className="inline-flex items-center justify-center gap-2 rounded-xl bg-brand px-4 py-3 text-sm font-semibold text-white transition-colors hover:bg-orange-600"
          >
            <ArrowRightLeft className="h-4 w-4" />
            지금 비교하기
          </Link>
        </div>
      </div>
    </Card>
  );
}
