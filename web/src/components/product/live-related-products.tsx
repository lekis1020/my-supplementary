"use client";

import { useEffect, useState } from "react";
import Image from "next/image";
import { ExternalLink } from "lucide-react";
import { Badge } from "@/components/ui/badge";

/**
 * 성분 상세 페이지의 실시간 검색 폴백.
 *
 * DB에 판매 확인된 관련 제품이 부족할 때(initialCount < MIN_VERIFIED)
 * /api/products/live-search를 성분명으로 호출해 "실시간 검색 결과"로 구분 표시.
 *
 * 법적 준수: 실시간 결과에는 건강 기능 표방 문구를 절대 표시하지 않는다 —
 * 제품명 / 가격 / 판매처 / 구매 링크만 노출.
 */

const MIN_VERIFIED = 3;
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

export function LiveRelatedProducts({
  ingredientName,
  initialCount,
}: {
  ingredientName: string;
  initialCount: number;
}) {
  const shouldFetch = initialCount < MIN_VERIFIED && ingredientName.length >= 2;

  const [items, setItems] = useState<LiveItem[] | null>(null);
  const [loading, setLoading] = useState(shouldFetch);

  useEffect(() => {
    if (!shouldFetch) return;

    let cancelled = false;

    fetch(`/api/products/live-search?q=${encodeURIComponent(ingredientName)}`)
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
  }, [shouldFetch, ingredientName]);

  if (!shouldFetch) return null;

  if (loading) {
    return (
      <div className="mt-4 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
        {Array.from({ length: 3 }).map((_, i) => (
          <div
            key={i}
            className="h-24 animate-pulse rounded-2xl border border-slate-100 bg-slate-50"
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
        <p className="text-xs text-slate-400">
          네이버 쇼핑에서 방금 검색한 결과로, 아직 성분 검증이 완료되지 않은 제품입니다.
        </p>
      </div>
      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
        {items.map((item) => (
          <a
            key={item.link}
            href={item.link}
            target="_blank"
            rel="noopener noreferrer nofollow"
            className="group flex gap-3 rounded-2xl border border-slate-200 bg-white p-3 transition-colors hover:border-sky-200 hover:bg-sky-50/40"
          >
            {item.image && (
              <div className="relative h-16 w-16 shrink-0 overflow-hidden rounded-xl border border-slate-100 bg-white">
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
              <p className="line-clamp-2 text-sm font-semibold text-slate-800 group-hover:text-sky-800">
                {item.title}
              </p>
              <p className="mt-1 text-xs text-slate-500">
                {[item.brand, item.mallName].filter(Boolean).join(" · ")}
              </p>
              <p className="mt-1 inline-flex items-center gap-1 text-xs font-semibold text-sky-700">
                {item.lprice != null && `${item.lprice.toLocaleString()}원`}
                <ExternalLink className="h-3 w-3" />
              </p>
            </div>
          </a>
        ))}
      </div>
    </div>
  );
}
