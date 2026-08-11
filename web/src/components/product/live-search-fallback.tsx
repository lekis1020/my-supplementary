"use client";

import { useEffect, useState } from "react";
import Image from "next/image";
import { Badge } from "@/components/ui/badge";

/**
 * 판매확인 제품이 부족한 페이지의 실시간 검색 폴백.
 *
 * initialCount < threshold일 때 /api/products/live-search를 호출해
 * "실시간 검색 결과"로 구분 표시. 성분 상세·통합 검색 페이지에서 공용.
 *
 * 법적 준수: 실시간 결과에는 건강 기능 표방 문구를 절대 표시하지 않는다.
 * 카드는 클릭 불가능한 정보 카드 — 제품명/브랜드만 노출하고 가격·몰·구매
 * 링크는 표시하지 않는다. 출처는 섹션 안내 문구로만 표기.
 */

const MAX_DISPLAY = 6;

interface LiveItem {
  title: string;
  link: string;
  image: string | null;
  lprice: number | null;
  mallName: string | null;
  brand: string | null;
}

interface LiveSearchPayload {
  live?: LiveItem[];
}

export function LiveSearchFallback({
  query,
  initialCount,
  threshold,
  description = "네이버 쇼핑 검색 결과로, 아직 성분 검증이 완료되지 않은 제품입니다.",
}: {
  query: string;
  initialCount: number;
  threshold: number;
  description?: string;
}) {
  const shouldFetch = initialCount < threshold && query.length >= 2;

  const [items, setItems] = useState<LiveItem[] | null>(null);
  const [loading, setLoading] = useState(shouldFetch);

  useEffect(() => {
    if (!shouldFetch) return;

    let cancelled = false;

    fetch(`/api/products/live-search?q=${encodeURIComponent(query)}`)
      .then((res) => (res.ok ? res.json() : null))
      .then((payload: LiveSearchPayload | null) => {
        if (cancelled) return;
        setItems((payload?.live ?? []).slice(0, MAX_DISPLAY));
      })
      .catch(() => {
        if (!cancelled) setItems([]);
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });

    return () => {
      cancelled = true;
    };
  }, [shouldFetch, query]);

  if (!shouldFetch) return null;

  if (loading) {
    return (
      <div className="mt-4 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
        {Array.from({ length: 3 }).map((_, i) => (
          <div
            key={i}
            className="h-24 animate-pulse rounded-2xl border border-stone-100 bg-stone-50"
          />
        ))}
      </div>
    );
  }

  if (!items || items.length === 0) return null;

  return (
    <div className="mt-6">
      <div className="mb-3 flex items-center gap-2">
        <Badge className="bg-sky-50 text-sky-700">실시간 검색 결과</Badge>
        <p className="text-xs text-ink-faint">{description}</p>
      </div>
      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
        {items.map((item) => (
          <div
            key={item.link}
            className="flex gap-3 rounded-2xl border border-stone-200 bg-white p-3"
          >
            {item.image && (
              <div className="relative h-16 w-16 shrink-0 overflow-hidden rounded-xl border border-stone-100 bg-white">
                <Image
                  src={item.image}
                  alt={item.title}
                  fill
                  sizes="64px"
                  className="object-contain"
                  unoptimized
                />
              </div>
            )}
            <div className="min-w-0">
              <p className="line-clamp-2 text-sm font-semibold text-ink">
                {item.title}
              </p>
              {item.brand && (
                <p className="mt-1 text-xs text-ink-muted">{item.brand}</p>
              )}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
