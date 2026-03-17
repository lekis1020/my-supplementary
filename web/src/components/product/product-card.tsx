import React from 'react';
import Link from "next/link";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { 
  ShoppingCart, 
  Zap, 
  TrendingDown,
  ChevronRight
} from "lucide-react";

interface ProductCardProps {
  product: {
    id: string;
    product_name: string;
    brand_name: string;
    price?: number;
    capacity?: number;
    unit?: string;
    product_type?: string;
    country_code?: string;
    main_ingredient?: string;
    percentage?: number;
    tags?: string[];
  };
}

/**
 * [bochoong.com 개선안] 고도화된 제품 카드 컴포넌트
 * - 데이터 기반 시각화 (권장량 대비 함량)
 * - 단위 가격 자동 산출 (10mg/unit당 가격)
 * - Medical Clean 테마 적용
 */
export const EnhancedProductCard = ({ product }: ProductCardProps) => {
  // 단위 가격 계산 (예시: 10단위당 가격)
  const unitPrice = product.price && product.capacity 
    ? Math.round(product.price / (product.capacity / 10)) 
    : null;

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
              <Badge variant="secondary" className="bg-emerald-50 text-emerald-700 border-emerald-100 px-2 py-0.5 text-[9px] font-bold">
                {typeLabel}
              </Badge>
              {product.country_code === "KR" && (
                <Badge variant="outline" className="text-slate-400 border-slate-200 px-2 py-0.5 text-[9px] font-bold">
                  KOREA
                </Badge>
              )}
            </div>
          </div>

          {/* 중단: 제품명 */}
          <div className="mb-4">
            <h3 className="text-base font-bold text-slate-900 leading-snug group-hover:text-emerald-700 transition-colors line-clamp-2">
              {product.product_name}
            </h3>
          </div>
          
          {/* 핵심 성분 함량 시각화 (실데이터 연동 준비) */}
          <div className="space-y-4 mb-6 mt-auto">
            {product.main_ingredient && (
              <div>
                <div className="flex justify-between text-[11px] mb-1.5">
                  <span className="text-slate-500 font-medium">핵심성분: {product.main_ingredient}</span>
                  <span className="text-emerald-600 font-bold">{product.percentage || 0}%</span>
                </div>
                <div className="h-1.5 w-full bg-slate-100 rounded-full overflow-hidden">
                  <div 
                    className="h-full bg-emerald-500 rounded-full transition-all duration-700 ease-out"
                    style={{ width: `${product.percentage || 0}%` }}
                  />
                </div>
              </div>
            )}
            
            <div className="flex flex-wrap gap-1.5">
              {(product.tags || []).slice(0, 2).map((tag) => (
                <span key={tag} className="text-[10px] text-slate-400 bg-slate-50 px-1.5 py-0.5 rounded-md border border-slate-100">
                  #{tag}
                </span>
              ))}
            </div>
          </div>

          {/* 하단: 가격 및 가성비 지표 */}
          <div className="flex items-center justify-between pt-4 border-t border-slate-100 mt-2">
            <div>
              {unitPrice && (
                <div className="flex items-center gap-1 text-slate-400 mb-0.5">
                  <TrendingDown size={10} />
                  <span className="text-[10px] font-medium">단위당 {unitPrice}원</span>
                </div>
              )}
              <div className="text-lg font-black text-slate-900 tracking-tight">
                {product.price ? product.price.toLocaleString() : "가격 미정"}<span className="text-xs font-normal ml-0.5">원</span>
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
