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

interface ProductCardProps {
  product: {
    id: string;
    product_name: string;
    brand_name: string | null;
    manufacturer_name?: string | null;
    approval_or_report_no?: string | null;
    product_type?: string;
    country_code?: string;
    tags?: string[];
  };
}

/**
 * [bochoong.com 개선안] 고도화된 제품 카드 컴포넌트
 * - 실제 제품 메타데이터 기반 요약
 * - Medical Clean 테마 적용
 */
export const EnhancedProductCard = ({ product }: ProductCardProps) => {
  // 건강기능식품 여부 레이블
  const typeLabel = product.product_type === "health_functional_food" 
    ? "건강기능식품" 
    : "보충제";

  return (
    <Link href={`/products/${product.id}`} className="block group">
      <Card className="overflow-hidden border-slate-200 group-hover:border-emerald-200 group-hover:shadow-xl transition-all duration-300 bg-white h-full flex flex-col">
        <CardContent className="p-5 flex-1 flex flex-col">
          {/* 상단: 브랜드 및 핵심 배지 */}
          <div className="flex justify-between items-start mb-3">
            <span className="text-[10px] text-slate-400 font-bold tracking-wider uppercase">
              {product.brand_name}
            </span>
            <div className="flex gap-1">
              <Badge className="bg-emerald-50 text-emerald-700 border-emerald-100 px-2 py-0.5 text-[9px] font-bold">
                {typeLabel}
              </Badge>
              {product.country_code === "KR" && (
                <Badge className="text-slate-400 border-slate-200 px-2 py-0.5 text-[9px] font-bold">
                  KOREA
                </Badge>
              )}
            </div>
          </div>

          {/* 중단: 제품명 */}
          <div className="mb-4">
            <h3 className="text-base font-bold text-slate-900 leading-snug group-hover:text-emerald-700 transition-colors line-clamp-2">
              {formatProductName(product.product_name)}
            </h3>
          </div>
          
          <div className="space-y-4 mb-6 mt-auto">
            <div className="space-y-2 rounded-xl bg-slate-50 p-3">
              <div className="flex items-start gap-2 text-[11px] text-slate-500">
                <Factory size={12} className="mt-0.5 shrink-0" />
                <div>
                  <div className="font-semibold text-slate-600">제조사</div>
                  <div className="mt-0.5 line-clamp-2 text-slate-500">
                    {product.manufacturer_name || product.brand_name || "정보 없음"}
                  </div>
                </div>
              </div>
              <div className="flex items-start gap-2 text-[11px] text-slate-500">
                <FileBadge2 size={12} className="mt-0.5 shrink-0" />
                <div>
                  <div className="font-semibold text-slate-600">신고번호</div>
                  <div className="mt-0.5 text-slate-500">
                    {product.approval_or_report_no || "정보 없음"}
                  </div>
                </div>
              </div>
            </div>

            <div className="flex flex-wrap gap-1.5">
              {(product.tags || []).slice(0, 2).map((tag) => (
                <span key={tag} className="text-[10px] text-slate-400 bg-slate-50 px-1.5 py-0.5 rounded-md border border-slate-100">
                  #{tag}
                </span>
              ))}
            </div>
          </div>

          <div className="flex items-center justify-between pt-4 border-t border-slate-100 mt-2">
            <div>
              <div className="text-[11px] font-medium uppercase tracking-[0.18em] text-slate-400">
                Product Record
              </div>
              <div className="mt-1 text-base font-black text-slate-900 tracking-tight">
                상세 보기
              </div>
            </div>
            <div className="w-8 h-8 bg-slate-900 text-white rounded-lg flex items-center justify-center group-hover:bg-emerald-600 transition-colors shadow-sm">
              <ChevronRight size={16} />
            </div>
          </div>
        </CardContent>
      </Card>
    </Link>
  );
};
