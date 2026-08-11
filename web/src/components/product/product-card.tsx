import React from 'react';
import Link from "next/link";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { formatProductName } from "@/lib/utils";
import {
  Factory,
  FileBadge2,
  ChevronRight
} from "lucide-react";
import type { Database } from "@/lib/types/supabase";

type ProductRow = Database["public"]["Tables"]["products"]["Row"];

interface ProductCardProps {
  product: Pick<
    ProductRow,
    | "id"
    | "product_name"
    | "brand_name"
    | "manufacturer_name"
    | "approval_or_report_no"
    | "product_type"
    | "country_code"
  > & { tags?: string[] };
}

/**
 * [bochoong.com 개선안] 고도화된 제품 카드 컴포넌트
 * - 실제 제품 메타데이터 기반 요약
 * - Warm commerce 테마 적용
 */
export const EnhancedProductCard = ({ product }: ProductCardProps) => {
  // 건강기능식품 여부 레이블
  const typeLabel = product.product_type === "health_functional_food"
    ? "건강기능식품"
    : "보충제";

  return (
    <Link href={`/products/${product.id}`} className="block group h-full">
      <Card
        padding="none"
        className="overflow-hidden h-full flex flex-col transition hover:border-brand hover:shadow-card-hover"
      >
        <CardContent className="p-5 flex-1 flex flex-col">
          {/* 상단: 브랜드 및 핵심 배지 */}
          <div className="flex justify-between items-start mb-3">
            <span className="text-[10px] text-ink-faint font-bold tracking-wider uppercase">
              {product.brand_name}
            </span>
            <div className="flex gap-1">
              <Badge variant="promo" className="px-2 py-0.5 text-[9px] font-bold">
                {typeLabel}
              </Badge>
              {product.country_code === "KR" && (
                <Badge variant="outline" className="px-2 py-0.5 text-[9px] font-bold">
                  KOREA
                </Badge>
              )}
            </div>
          </div>

          {/* 중단: 제품명 */}
          <div className="mb-4">
            <h3 className="text-base font-bold text-ink leading-snug group-hover:text-orange-700 transition-colors line-clamp-2">
              {formatProductName(product.product_name)}
            </h3>
          </div>

          <div className="space-y-4 mb-6 mt-auto">
            <div className="space-y-2 rounded-xl bg-stone-50 p-3">
              <div className="flex items-start gap-2 text-[11px] text-ink-muted">
                <Factory size={12} className="mt-0.5 shrink-0" />
                <div>
                  <div className="font-semibold text-ink">제조사</div>
                  <div className="mt-0.5 line-clamp-2 text-ink-muted">
                    {product.manufacturer_name || product.brand_name || "정보 없음"}
                  </div>
                </div>
              </div>
              <div className="flex items-start gap-2 text-[11px] text-ink-muted">
                <FileBadge2 size={12} className="mt-0.5 shrink-0" />
                <div>
                  <div className="font-semibold text-ink">신고번호</div>
                  <div className="mt-0.5 text-ink-muted">
                    {product.approval_or_report_no || "정보 없음"}
                  </div>
                </div>
              </div>
            </div>

            <div className="flex flex-wrap gap-1.5">
              {(product.tags || []).slice(0, 2).map((tag) => (
                <Badge key={tag} variant="tag" className="text-[10px] font-normal">
                  #{tag}
                </Badge>
              ))}
            </div>
          </div>

          <div className="flex items-center justify-between pt-4 border-t border-stone-100 mt-2">
            <div>
              <div className="text-[11px] font-medium uppercase tracking-[0.18em] text-ink-faint">
                Product Record
              </div>
              <div className="mt-1 text-base font-black text-ink tracking-tight">
                상세 보기
              </div>
            </div>
            <div className="w-8 h-8 bg-ink text-white rounded-lg flex items-center justify-center group-hover:bg-orange-700 transition-colors shadow-sm">
              <ChevronRight size={16} />
            </div>
          </div>
        </CardContent>
      </Card>
    </Link>
  );
};
