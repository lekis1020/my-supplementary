"use client";

import { useEffect, useState, useRef } from "react";
import { createClient } from "@/lib/supabase/client";
import { Badge } from "@/components/ui/badge";
import { Card } from "@/components/ui/card";
import { X, Plus, AlertTriangle } from "lucide-react";
import Link from "next/link";
import type { SupabaseClient } from "@supabase/supabase-js";

interface Product {
  id: number;
  product_name: string;
  brand_name: string | null;
  country_code: string | null;
}

interface ProductIngredient {
  id: number;
  product_id: number;
  ingredient_id: number;
  amount_per_serving: string | null;
  amount_unit: string | null;
  raw_label_name: string | null;
  ingredients: {
    id: number;
    canonical_name_ko: string;
    slug: string | null;
  } | null;
}

export default function ComparePage() {
  const [allProducts, setAllProducts] = useState<Product[]>([]);
  const [selectedIds, setSelectedIds] = useState<number[]>([]);
  const [productIngredients, setProductIngredients] = useState<
    Record<number, ProductIngredient[]>
  >({});
  const [loading, setLoading] = useState(true);
  const supabaseRef = useRef<SupabaseClient | null>(null);

  function getSupabase() {
    if (!supabaseRef.current) {
      supabaseRef.current = createClient();
    }
    return supabaseRef.current;
  }

  useEffect(() => {
    async function loadProducts() {
      const supabase = getSupabase();
      const { data } = await supabase
        .from("products")
        .select("id, product_name, brand_name, country_code")
        .eq("is_published", true)
        .order("product_name");
      setAllProducts(data ?? []);
      setLoading(false);
    }
    loadProducts();
  }, []);

  useEffect(() => {
    async function loadIngredients() {
      const supabase = getSupabase();
      const newIngredients: Record<number, ProductIngredient[]> = {};
      for (const id of selectedIds) {
        if (productIngredients[id]) {
          newIngredients[id] = productIngredients[id];
          continue;
        }
        const { data } = await supabase
          .from("product_ingredients")
          .select("*, ingredients(id, canonical_name_ko, slug)")
          .eq("product_id", id);
        newIngredients[id] = (data as ProductIngredient[]) ?? [];
      }
      setProductIngredients(newIngredients);
    }
    if (selectedIds.length > 0) loadIngredients();
  }, [selectedIds]); // eslint-disable-line react-hooks/exhaustive-deps

  const addProduct = (id: number) => {
    if (selectedIds.length >= 4 || selectedIds.includes(id)) return;
    setSelectedIds([...selectedIds, id]);
  };

  const removeProduct = (id: number) => {
    setSelectedIds(selectedIds.filter((sid) => sid !== id));
  };

  // 모든 선택된 제품의 원료 목록 (union)
  const allIngredientIds = new Set<number>();
  const ingredientMap = new Map<number, string>();
  const ingredientSlugMap = new Map<number, string | null>();
  for (const id of selectedIds) {
    for (const pi of productIngredients[id] ?? []) {
      if (pi.ingredients) {
        allIngredientIds.add(pi.ingredient_id);
        ingredientMap.set(pi.ingredient_id, pi.ingredients.canonical_name_ko);
        ingredientSlugMap.set(pi.ingredient_id, pi.ingredients.slug);
      }
    }
  }
  const sortedIngredientIds = Array.from(allIngredientIds);

  // 성분 중복 감지: 2개 이상 제품에 같은 원료가 있으면 중복
  const duplicateIngredients = new Set<number>();
  for (const ingId of sortedIngredientIds) {
    let count = 0;
    for (const prodId of selectedIds) {
      if ((productIngredients[prodId] ?? []).some((pi) => pi.ingredient_id === ingId)) {
        count++;
      }
    }
    if (count >= 2) duplicateIngredients.add(ingId);
  }

  const selectedProducts = selectedIds
    .map((id) => allProducts.find((p) => p.id === id))
    .filter(Boolean) as Product[];
  const availableProducts = allProducts.filter(
    (p) => !selectedIds.includes(p.id)
  );

  if (loading) {
    return (
      <div className="mx-auto max-w-6xl px-4 py-12 text-center text-gray-400">
        로딩 중...
      </div>
    );
  }

  return (
    <div className="mx-auto max-w-6xl px-4 py-12">
      <h1 className="mb-2 text-3xl font-bold text-gray-900">제품 비교 도구</h1>
      <p className="mb-8 text-gray-500">최대 4개 제품을 나란히 비교하세요.</p>

      {/* 제품 선택 */}
      <div className="mb-8">
        <div className="flex flex-wrap gap-2">
          {selectedProducts.map((p) => (
            <Badge
              key={p.id}
              className="flex items-center gap-1 bg-green-100 text-green-800 px-3 py-1.5"
            >
              {p.product_name}
              <button onClick={() => removeProduct(p.id)} className="ml-1 hover:text-red-600">
                <X className="h-3 w-3" />
              </button>
            </Badge>
          ))}
          {selectedIds.length < 4 && (
            <div className="relative">
              <select
                className="rounded-lg border border-gray-300 bg-white px-3 py-1.5 text-sm text-gray-700"
                value=""
                onChange={(e) => addProduct(Number(e.target.value))}
              >
                <option value="" disabled>
                  + 제품 추가 ({4 - selectedIds.length}개 남음)
                </option>
                {availableProducts.map((p) => (
                  <option key={p.id} value={p.id}>
                    {p.product_name} ({p.brand_name})
                  </option>
                ))}
              </select>
            </div>
          )}
        </div>
      </div>

      {/* 성분 중복 경고 */}
      {duplicateIngredients.size > 0 && selectedIds.length >= 2 && (
        <Card className="mb-6 border-yellow-200 bg-yellow-50 p-4">
          <div className="flex items-start gap-2">
            <AlertTriangle className="mt-0.5 h-5 w-5 shrink-0 text-yellow-600" />
            <div>
              <p className="font-medium text-yellow-800">성분 중복 감지</p>
              <p className="mt-1 text-sm text-yellow-700">
                다음 원료가 2개 이상 제품에 포함되어 있습니다:{" "}
                {Array.from(duplicateIngredients)
                  .map((id) => ingredientMap.get(id))
                  .join(", ")}
              </p>
              <p className="mt-1 text-xs text-yellow-600">
                동일 원료를 여러 제품에서 동시 섭취하면 과다 복용 위험이 있습니다.
              </p>
            </div>
          </div>
        </Card>
      )}

      {/* 비교 테이블 */}
      {selectedIds.length >= 2 && (
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b">
                <th className="py-3 pr-4 text-left font-semibold text-gray-700">원료</th>
                {selectedProducts.map((p) => (
                  <th key={p.id} className="py-3 px-4 text-center font-semibold text-gray-700">
                    <div>{p.product_name}</div>
                    <div className="text-xs font-normal text-gray-400">{p.brand_name}</div>
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {sortedIngredientIds.map((ingId) => {
                const isDuplicate = duplicateIngredients.has(ingId);
                return (
                  <tr
                    key={ingId}
                    className={`border-b border-gray-50 ${isDuplicate ? "bg-yellow-50" : ""}`}
                  >
                    <td className="py-2.5 pr-4">
                      <Link
                        href={`/ingredients/${ingredientSlugMap.get(ingId) ?? ingId}`}
                        className="font-medium text-green-600 hover:underline"
                      >
                        {ingredientMap.get(ingId)}
                      </Link>
                      {isDuplicate && (
                        <span className="ml-1 text-xs text-yellow-600">중복</span>
                      )}
                    </td>
                    {selectedIds.map((prodId) => {
                      const pi = (productIngredients[prodId] ?? []).find(
                        (p) => p.ingredient_id === ingId
                      );
                      return (
                        <td key={prodId} className="py-2.5 px-4 text-center">
                          {pi ? (
                            <span className="text-gray-700">
                              {pi.amount_per_serving} {pi.amount_unit}
                            </span>
                          ) : (
                            <span className="text-gray-300">—</span>
                          )}
                        </td>
                      );
                    })}
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}

      {selectedIds.length < 2 && (
        <div className="py-20 text-center text-gray-400">
          <Plus className="mx-auto mb-3 h-12 w-12 text-gray-300" />
          <p>비교할 제품을 2개 이상 선택하세요 (최대 4개)</p>
        </div>
      )}
    </div>
  );
}
