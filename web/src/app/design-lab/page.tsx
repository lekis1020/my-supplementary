import React from 'react';
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { 
  CheckCircle2, 
  ShoppingCart, 
  Zap, 
  Eye, 
  ShieldCheck,
  TrendingDown,
  ChevronRight
} from "lucide-react";

/**
 * [Iteration 5 최종 합의안] 고도화된 제품 카드 컴포넌트
 * - 시각적 신뢰성 (Emerald & Slate)
 * - 데이터 시각화 (Progress Bar)
 * - 가성비 지표 (Unit Price)
 */
const EnhancedProductCard = ({ product }: { product: any }) => {
  return (
    <Card className="group overflow-hidden border-slate-200 hover:border-emerald-200 hover:shadow-xl transition-all duration-300 bg-white">
      <CardContent className="p-5">
        {/* 상단: 브랜드 및 핵심 배지 */}
        <div className="flex justify-between items-start mb-3">
          <span className="text-xs text-slate-400 font-semibold tracking-wider uppercase">
            {product.brand}
          </span>
          <div className="flex gap-1">
            {product.isBest && (
              <Badge variant="secondary" className="bg-emerald-50 text-emerald-700 border-emerald-100 px-2 py-0.5 text-[10px] font-bold">
                BEST 가성비
              </Badge>
            )}
            {product.isNew && (
              <Badge variant="outline" className="text-blue-600 border-blue-200 px-2 py-0.5 text-[10px] font-bold">
                NEW
              </Badge>
            )}
          </div>
        </div>

        {/* 중단: 제품명 및 효능 아이콘 */}
        <div className="flex justify-between items-start mb-4">
          <h3 className="text-lg font-bold text-slate-900 leading-tight group-hover:text-emerald-700 transition-colors">
            {product.name}
          </h3>
          <div className="bg-slate-50 p-1.5 rounded-lg text-slate-400 group-hover:text-emerald-500 transition-colors">
            {product.categoryIcon}
          </div>
        </div>
        
        {/* 핵심 성분 함량 시각화 (Progress Bar) */}
        <div className="space-y-4 mb-6">
          <div>
            <div className="flex justify-between text-xs mb-1.5">
              <span className="text-slate-500 font-medium">핵심성분: {product.mainIngredient}</span>
              <span className="text-emerald-600 font-bold">{product.percentage}%</span>
            </div>
            <div className="h-2 w-full bg-slate-100 rounded-full overflow-hidden">
              <div 
                className="h-full bg-emerald-500 rounded-full transition-all duration-700 ease-out"
                style={{ width: `${product.percentage}%` }}
              />
            </div>
          </div>
          
          <div className="flex flex-wrap gap-2">
            {product.tags.map((tag: string) => (
              <span key={tag} className="text-[11px] text-slate-400 bg-slate-50 px-2 py-0.5 rounded-md border border-slate-100">
                #{tag}
              </span>
            ))}
          </div>
        </div>

        {/* 하단: 가격 및 가성비 지표 */}
        <div className="flex items-center justify-between pt-4 border-t border-slate-100">
          <div>
            <div className="flex items-center gap-1 text-slate-400 mb-0.5">
              <TrendingDown size={12} />
              <span className="text-[10px] font-medium">10mg당 {product.unitPrice}원</span>
            </div>
            <div className="text-xl font-black text-slate-900 tracking-tight">
              {product.price.toLocaleString()}<span className="text-sm font-normal ml-0.5">원</span>
            </div>
          </div>
          <button className="flex items-center justify-center w-10 h-10 bg-slate-900 text-white rounded-xl hover:bg-emerald-600 active:scale-95 transition-all shadow-md shadow-slate-200">
            <ShoppingCart size={18} />
          </button>
        </div>
      </CardContent>
    </Card>
  );
};

export default function DesignLabPage() {
  const mockProducts = [
    {
      id: 1,
      brand: "Nature's Way",
      name: "얼라이브 멀티비타민 포 맨",
      mainIngredient: "비타민 C",
      percentage: 120,
      price: 24500,
      unitPrice: 145,
      isBest: true,
      isNew: false,
      categoryIcon: <Zap size={20} />,
      tags: ["남성전용", "피로회복", "60정"]
    },
    {
      id: 2,
      brand: "Doctor's Best",
      name: "루테인 위드 플로라글로",
      mainIngredient: "루테인",
      percentage: 100,
      price: 18900,
      unitPrice: 315,
      isBest: false,
      isNew: true,
      categoryIcon: <Eye size={20} />,
      tags: ["눈건강", "황반보호", "120캡슐"]
    },
    {
      id: 3,
      brand: "California Gold",
      name: "락토비프 프로바이오틱스",
      mainIngredient: "유산균",
      percentage: 85,
      price: 32000,
      unitPrice: 530,
      isBest: false,
      isNew: false,
      categoryIcon: <ShieldCheck size={20} />,
      tags: ["장건강", "면역력", "300억 CFU"]
    }
  ];

  return (
    <div className="min-h-screen bg-slate-50 pb-20">
      {/* Header Area */}
      <div className="bg-white border-b border-slate-200 px-6 py-12 mb-8">
        <div className="max-w-5xl mx-auto">
          <Badge className="mb-4 bg-emerald-500 hover:bg-emerald-600 border-none px-3 py-1">Design Lab</Badge>
          <h1 className="text-4xl font-black text-slate-900 mb-3 tracking-tight">영양제 비교 디자인 개선안</h1>
          <p className="text-slate-500 text-lg max-w-2xl leading-relaxed">
            랄플랜(ralplan) 5회 이터레이션을 통해 도출된 최종 UI 컴포넌트입니다. 
            시인성, 가독성, 모바일 환경에서의 조작 편의성을 극대화했습니다.
          </p>
        </div>
      </div>

      <main className="max-w-5xl mx-auto px-6">
        {/* 카드 리스트 섹션 */}
        <section className="mb-16">
          <div className="flex justify-between items-end mb-8">
            <h2 className="text-2xl font-bold text-slate-800 tracking-tight">추천 영양제 카드 (Grid)</h2>
            <button className="text-sm text-emerald-600 font-bold flex items-center hover:underline group">
              전체보기 <ChevronRight size={16} className="group-hover:translate-x-1 transition-transform" />
            </button>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
            {mockProducts.map(p => (
              <EnhancedProductCard key={p.id} product={p} />
            ))}
          </div>
        </section>

        {/* 디자인 개선 핵심 포인트 섹션 */}
        <section className="bg-white rounded-[32px] p-10 border border-slate-200 shadow-sm mb-16">
          <h2 className="text-2xl font-bold text-slate-900 mb-8 flex items-center gap-3">
            <div className="w-10 h-10 bg-emerald-50 rounded-xl flex items-center justify-center">
              <CheckCircle2 className="text-emerald-500" size={24} />
            </div>
            디자인 개선 핵심 포인트 (Consensus)
          </h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-10">
            <div className="space-y-6">
              <div className="group">
                <h4 className="font-bold text-slate-800 mb-2 flex items-center gap-2">
                  <span className="text-emerald-500 text-xs font-black">01</span> Visual Credibility
                </h4>
                <p className="text-sm text-slate-500 leading-relaxed">
                  전형적인 쇼핑몰 느낌을 탈피하고, 신뢰감을 주는 Emerald Green 포인트와 정갈한 타이포그래피를 사용하여 '건강/의료' 전문성을 강조했습니다.
                </p>
              </div>
              <div className="group">
                <h4 className="font-bold text-slate-800 mb-2 flex items-center gap-2">
                  <span className="text-emerald-500 text-xs font-black">02</span> Data Visualization
                </h4>
                <p className="text-sm text-slate-500 leading-relaxed">
                  복잡한 함량 수치를 단순 텍스트가 아닌 'Progress Bar'로 시각화하여, 1일 권장량 대비 충족도를 직관적으로 인지하게 했습니다.
                </p>
              </div>
            </div>
            <div className="space-y-6">
              <div className="group">
                <h4 className="font-bold text-slate-800 mb-2 flex items-center gap-2">
                  <span className="text-emerald-500 text-xs font-black">03</span> Mobile-First UX
                </h4>
                <p className="text-sm text-slate-500 leading-relaxed">
                  모바일 환경을 고려하여 카드의 터치 영역을 최적화하고, 가성비 지표(단위 가격)를 노출하여 빠른 의사결정을 돕습니다.
                </p>
              </div>
              <div className="group">
                <h4 className="font-bold text-slate-800 mb-2 flex items-center gap-2">
                  <span className="text-emerald-500 text-xs font-black">04</span> Information Hierarchy
                </h4>
                <p className="text-sm text-slate-500 leading-relaxed">
                  시선의 흐름에 따라 [브랜드/상태] → [제품명] → [성분 지표] → [가격/액션] 순으로 정보를 배치하여 인지 부하를 최소화했습니다.
                </p>
              </div>
            </div>
          </div>
        </section>

        {/* 하단 플로팅 비교 바 (모사) */}
        <div className="fixed bottom-8 left-1/2 -translate-x-1/2 w-[90%] max-w-md bg-slate-900/95 backdrop-blur-md text-white p-4 rounded-[24px] shadow-2xl flex items-center justify-between z-50 border border-slate-700/50">
          <div className="flex -space-x-3 overflow-hidden ml-2">
            <div className="inline-block h-10 w-10 rounded-full ring-2 ring-slate-900 bg-emerald-500 flex items-center justify-center text-[10px] font-bold">Nature</div>
            <div className="inline-block h-10 w-10 rounded-full ring-2 ring-slate-900 bg-blue-500 flex items-center justify-center text-[10px] font-bold">Doc's</div>
          </div>
          <div className="flex-1 px-4 text-sm font-bold tracking-tight">
            2개 제품 비교하기
          </div>
          <button className="bg-emerald-500 text-white px-6 py-3 rounded-[16px] font-black text-sm hover:bg-emerald-400 active:scale-95 transition-all shadow-lg shadow-emerald-500/20">
            비교 GO
          </button>
        </div>
      </main>
    </div>
  );
}
