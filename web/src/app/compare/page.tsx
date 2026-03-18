"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { Badge } from "@/components/ui/badge";
import { Card } from "@/components/ui/card";
import { cn, formatProductName, getIngredientHref, getIngredientRoleLabel } from "@/lib/utils";
import {
  COMPARE_MAX_PRODUCTS,
  COMPARE_STORAGE_KEY,
  normalizeCompareIds,
  parseCompareIds,
} from "@/lib/compare";
import { AlertTriangle, Plus, Scale, Sparkles, X } from "lucide-react";
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
  ingredient_role?: string | null;
  raw_label_name: string | null;
  ingredients: {
    id: number;
    canonical_name_ko: string;
    slug: string | null;
  } | null;
}

interface NormalizedAmount {
  displayText: string;
  normalizedValue: number | null;
  compareKey: string | null;
  compareLabel: string | null;
}

interface ComparisonCell {
  productId: number;
  ingredient: ProductIngredient | null;
  amount: NormalizedAmount | null;
}

interface IngredientComparisonRow {
  ingredientId: number;
  ingredientName: string;
  ingredientHref: string;
  cells: ComparisonCell[];
  productCount: number;
  isComparable: boolean;
  compareLabel: string | null;
  maxComparableValue: number | null;
  duplicate: boolean;
  uniqueOwnerId: number | null;
}

const MASS_UNIT_FACTORS: Array<{ pattern: RegExp; factor: number; compareKey: string; label: string }> = [
  { pattern: /(mcg|μg|ug|㎍)/i, factor: 0.001, compareKey: "mass-mg", label: "mg" },
  { pattern: /(mg|㎎)/i, factor: 1, compareKey: "mass-mg", label: "mg" },
  { pattern: /\bg\b/i, factor: 1000, compareKey: "mass-mg", label: "mg" },
];

const VOLUME_UNIT_FACTORS: Array<{ pattern: RegExp; factor: number; compareKey: string; label: string }> = [
  { pattern: /(ml|mL)/, factor: 1, compareKey: "volume-ml", label: "mL" },
  { pattern: /\bl\b/i, factor: 1000, compareKey: "volume-ml", label: "mL" },
];

const CFU_UNIT_FACTORS: Array<{ pattern: RegExp; factor: number }> = [
  { pattern: /억\s*cfu/i, factor: 100000000 },
  { pattern: /천만\s*cfu/i, factor: 10000000 },
  { pattern: /백만\s*cfu/i, factor: 1000000 },
  { pattern: /만\s*cfu/i, factor: 10000 },
  { pattern: /cfu/i, factor: 1 },
];

export default function ComparePage() {
  const [allProducts, setAllProducts] = useState<Product[]>([]);
  const [selectedIds, setSelectedIds] = useState<number[]>(() => {
    if (typeof window === "undefined") return [];

    const queryIds = parseCompareIds(new URLSearchParams(window.location.search).get("ids"));
    let storedIds: number[] = [];

    try {
      const rawValue = window.localStorage.getItem(COMPARE_STORAGE_KEY);
      if (rawValue) {
        const parsed = JSON.parse(rawValue);
        if (Array.isArray(parsed)) {
          storedIds = normalizeCompareIds(parsed.map((value) => Number(value)));
        }
      }
    } catch {
      window.localStorage.removeItem(COMPARE_STORAGE_KEY);
    }

    return normalizeCompareIds([...queryIds, ...storedIds]);
  });
  const [productIngredients, setProductIngredients] = useState<Record<number, ProductIngredient[]>>(
    {},
  );
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

  const validProductIds = useMemo(() => new Set(allProducts.map((product) => product.id)), [allProducts]);
  const effectiveSelectedIds = useMemo(
    () => selectedIds.filter((id) => validProductIds.has(id)),
    [selectedIds, validProductIds],
  );

  useEffect(() => {
    if (typeof window === "undefined") return;

    window.localStorage.setItem(COMPARE_STORAGE_KEY, JSON.stringify(effectiveSelectedIds));
  }, [effectiveSelectedIds]);

  useEffect(() => {
    async function loadIngredients() {
      const supabase = getSupabase();
      const newIngredients: Record<number, ProductIngredient[]> = {};

      for (const id of effectiveSelectedIds) {
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

    if (effectiveSelectedIds.length > 0) {
      loadIngredients();
    }
  }, [effectiveSelectedIds]); // eslint-disable-line react-hooks/exhaustive-deps

  const addProduct = (id: number) => {
    if (selectedIds.length >= COMPARE_MAX_PRODUCTS || selectedIds.includes(id)) return;
    setSelectedIds([...selectedIds, id]);
  };

  const removeProduct = (id: number) => {
    setSelectedIds(selectedIds.filter((sid) => sid !== id));
  };

  const selectedProducts = effectiveSelectedIds
    .map((id) => allProducts.find((product) => product.id === id))
    .filter(Boolean) as Product[];
  const availableProducts = allProducts.filter((product) => !effectiveSelectedIds.includes(product.id));

  const comparison = useMemo(() => {
    const allIngredientIds = new Set<number>();
    const ingredientMap = new Map<number, { name: string; href: string }>();

    for (const productId of effectiveSelectedIds) {
      for (const ingredient of productIngredients[productId] ?? []) {
        if (!ingredient.ingredients) continue;
        allIngredientIds.add(ingredient.ingredient_id);
        ingredientMap.set(ingredient.ingredient_id, {
          name: ingredient.ingredients.canonical_name_ko,
          href: getIngredientHref({
            id: ingredient.ingredients.id,
            slug: ingredient.ingredients.slug,
          }),
        });
      }
    }

    const rows = Array.from(allIngredientIds)
      .map((ingredientId) =>
        buildComparisonRow(ingredientId, effectiveSelectedIds, productIngredients, ingredientMap),
      )
      .filter(Boolean) as IngredientComparisonRow[];

    rows.sort((left, right) => left.ingredientName.localeCompare(right.ingredientName, "ko"));

    const commonRows = rows.filter((row) => row.productCount === effectiveSelectedIds.length);
    const overlapRows = rows.filter(
      (row) => row.productCount >= 2 && row.productCount < effectiveSelectedIds.length,
    );
    const uniqueRows = rows.filter((row) => row.productCount === 1);
    const duplicateRows = rows.filter((row) => row.duplicate);

    const uniqueByProduct = selectedProducts
      .map((product) => ({
        product,
        rows: uniqueRows.filter((row) => row.uniqueOwnerId === product.id),
      }))
      .filter((entry) => entry.rows.length > 0);

    return {
      rows,
      commonRows,
      overlapRows,
      uniqueRows,
      duplicateRows,
      uniqueByProduct,
    };
  }, [effectiveSelectedIds, productIngredients, selectedProducts]);

  if (loading) {
    return (
      <div className="mx-auto max-w-6xl px-4 py-12 text-center text-gray-400">
        로딩 중...
      </div>
    );
  }

  return (
    <div className="mx-auto max-w-6xl px-4 py-12">
      <div className="max-w-3xl">
        <p className="text-xs font-semibold uppercase tracking-[0.18em] text-emerald-600">
          Compare Tool
        </p>
        <h1 className="mt-3 text-3xl font-black tracking-tight text-gray-900">제품 비교 도구</h1>
        <p className="mt-3 text-gray-500">
          최대 4개 제품을 비교합니다. 공통 원료, 중복 위험, 제품별 고유 원료를 나누어 보고,
          같은 단위인 경우에는 어떤 제품에 더 많이 들어있는지도 직관적으로 확인할 수 있습니다.
        </p>
      </div>

      <Card className="mt-8 border-slate-200 bg-slate-50 p-5">
        <div className="flex flex-wrap items-start gap-3">
          {selectedProducts.map((product) => (
            <div
              key={product.id}
              className="flex min-w-[220px] items-start justify-between gap-3 rounded-xl border border-emerald-100 bg-white px-4 py-3"
            >
              <div>
                <p className="text-sm font-semibold text-slate-900">{formatProductName(product.product_name)}</p>
                <p className="mt-1 text-xs text-slate-400">
                  {product.brand_name || "브랜드 정보 없음"}
                </p>
              </div>
              <button
                onClick={() => removeProduct(product.id)}
                className="rounded-full p-1 text-slate-400 transition-colors hover:bg-red-50 hover:text-red-600"
                aria-label={`${formatProductName(product.product_name)} 제거`}
              >
                <X className="h-4 w-4" />
              </button>
            </div>
          ))}

          {effectiveSelectedIds.length < COMPARE_MAX_PRODUCTS && (
            <div className="min-w-[260px] flex-1">
              <label className="mb-2 block text-xs font-semibold uppercase tracking-[0.16em] text-slate-400">
                제품 추가
              </label>
              <select
                className="w-full rounded-xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-700"
                value=""
                onChange={(event) => addProduct(Number(event.target.value))}
              >
                <option value="" disabled>
                  + 제품 추가 ({COMPARE_MAX_PRODUCTS - effectiveSelectedIds.length}개 남음)
                </option>
                {availableProducts.map((product) => (
                  <option key={product.id} value={product.id}>
                    {formatProductName(product.product_name)} ({product.brand_name || "브랜드 없음"})
                  </option>
                ))}
              </select>
            </div>
          )}
        </div>
      </Card>

      {effectiveSelectedIds.length >= 2 && (
        <>
          <div className="mt-8 grid gap-4 md:grid-cols-4">
            <SummaryCard
              label="공통 원료"
              value={comparison.commonRows.length}
              description="모든 선택 제품에 함께 들어있는 원료"
              tone="emerald"
            />
            <SummaryCard
              label="중복 위험"
              value={comparison.duplicateRows.length}
              description="2개 이상 제품에 동시에 포함된 원료"
              tone="amber"
            />
            <SummaryCard
              label="고유 원료"
              value={comparison.uniqueRows.length}
              description="한 제품에만 단독으로 들어있는 원료"
              tone="blue"
            />
            <SummaryCard
              label="총 비교 원료"
              value={comparison.rows.length}
              description="선택 제품 전체에서 비교 가능한 원료"
              tone="slate"
            />
          </div>

          {comparison.duplicateRows.length > 0 && (
            <Card className="mt-6 border-yellow-200 bg-yellow-50 p-5">
              <div className="flex items-start gap-3">
                <AlertTriangle className="mt-0.5 h-5 w-5 shrink-0 text-yellow-600" />
                <div>
                  <p className="font-semibold text-yellow-900">중복 섭취 가능성이 있는 원료</p>
                  <p className="mt-1 text-sm text-yellow-800">
                    같은 원료를 여러 제품에서 동시에 섭취할 수 있습니다. 아래 원료는 우선 확인하는
                    것이 좋습니다.
                  </p>
                  <div className="mt-3 flex flex-wrap gap-2">
                    {comparison.duplicateRows.slice(0, 12).map((row) => (
                      <span
                        key={row.ingredientId}
                        className="rounded-full border border-yellow-200 bg-white px-3 py-1 text-xs font-medium text-yellow-800"
                      >
                        {row.ingredientName}
                      </span>
                    ))}
                  </div>
                </div>
              </div>
            </Card>
          )}

          <div className="mt-10 space-y-10">
            <ComparisonSection
              title="공통 원료"
              description="모든 선택 제품에 같이 포함된 원료입니다. 같은 단위로 표기된 경우 상대 함량을 막대로 보여줍니다."
              icon={<Sparkles className="h-5 w-5 text-emerald-600" />}
              rows={comparison.commonRows}
              selectedProducts={selectedProducts}
              emptyMessage="모든 제품에 공통으로 들어있는 원료는 없습니다."
            />

            <ComparisonSection
              title="부분 중복 원료"
              description="일부 제품끼리만 겹치는 원료입니다. 복용 조합을 볼 때 가장 먼저 확인해야 하는 구간입니다."
              icon={<AlertTriangle className="h-5 w-5 text-amber-600" />}
              rows={comparison.overlapRows}
              selectedProducts={selectedProducts}
              emptyMessage="부분적으로만 겹치는 원료는 없습니다."
            />

            <section>
              <div className="mb-5">
                <div className="flex items-center gap-2">
                  <Scale className="h-5 w-5 text-blue-600" />
                  <h2 className="text-2xl font-bold tracking-tight text-slate-900">제품별 고유 원료</h2>
                </div>
                <p className="mt-2 text-sm text-slate-500">
                  한 제품에만 들어있는 원료를 제품별로 나누어 봅니다.
                </p>
              </div>

              <div className="space-y-6">
                {comparison.uniqueByProduct.length > 0 ? (
                  comparison.uniqueByProduct.map((entry) => (
                    <ComparisonSection
                      key={entry.product.id}
                      title={formatProductName(entry.product.product_name)}
                      description={entry.product.brand_name || "브랜드 정보 없음"}
                      rows={entry.rows}
                      selectedProducts={selectedProducts}
                      focusProductId={entry.product.id}
                    />
                  ))
                ) : (
                  <EmptySection message="제품별 고유 원료는 없습니다." />
                )}
              </div>
            </section>
          </div>
        </>
      )}

      {effectiveSelectedIds.length < 2 && (
        <div className="py-20 text-center text-gray-400">
          <Plus className="mx-auto mb-3 h-12 w-12 text-gray-300" />
          <p>비교할 제품을 2개 이상 선택하세요 (최대 {COMPARE_MAX_PRODUCTS}개)</p>
        </div>
      )}
    </div>
  );
}

function ComparisonSection({
  title,
  description,
  icon,
  rows,
  selectedProducts,
  emptyMessage,
  focusProductId,
}: {
  title: string;
  description: string;
  icon?: React.ReactNode;
  rows: IngredientComparisonRow[];
  selectedProducts: Product[];
  emptyMessage?: string;
  focusProductId?: number;
}) {
  return (
    <section>
      <div className="mb-5">
        <div className="flex items-center gap-2">
          {icon}
          <h2 className="text-2xl font-bold tracking-tight text-slate-900">{title}</h2>
          <Badge className="bg-slate-100 text-slate-600">{rows.length.toLocaleString()}개</Badge>
        </div>
        <p className="mt-2 text-sm text-slate-500">{description}</p>
      </div>

      {rows.length === 0 ? (
        <EmptySection message={emptyMessage || "표시할 항목이 없습니다."} />
      ) : (
        <div className="overflow-x-auto rounded-2xl border border-slate-200 bg-white shadow-sm">
          <div className="min-w-[860px]">
            <div
              className="grid gap-0 border-b border-slate-200 bg-slate-50"
              style={{
                gridTemplateColumns: `minmax(220px, 1.1fr) repeat(${selectedProducts.length}, minmax(160px, 1fr))`,
              }}
            >
              <div className="px-4 py-4 text-sm font-semibold text-slate-600">원료</div>
              {selectedProducts.map((product) => (
                <div
                  key={product.id}
                  className={cn(
                    "border-l border-slate-200 px-4 py-4 text-sm",
                    focusProductId === product.id ? "bg-blue-50/70" : "",
                  )}
                >
                  <div className="font-semibold text-slate-900">{formatProductName(product.product_name)}</div>
                  <div className="mt-1 text-xs text-slate-400">
                    {product.brand_name || "브랜드 정보 없음"}
                  </div>
                </div>
              ))}
            </div>

            <div className="divide-y divide-slate-100">
              {rows.map((row) => (
                <div
                  key={row.ingredientId}
                  className="grid gap-0"
                  style={{
                    gridTemplateColumns: `minmax(220px, 1.1fr) repeat(${selectedProducts.length}, minmax(160px, 1fr))`,
                  }}
                >
                  <div className="px-4 py-4">
                    <Link
                      href={row.ingredientHref}
                      className="font-semibold text-emerald-700 hover:underline"
                    >
                      {row.ingredientName}
                    </Link>
                    <div className="mt-2 flex flex-wrap gap-2">
                      {row.duplicate && (
                        <span className="rounded-full bg-yellow-100 px-2.5 py-1 text-[11px] font-semibold text-yellow-800">
                          중복
                        </span>
                      )}
                      {row.isComparable && row.compareLabel && (
                        <span className="rounded-full bg-emerald-50 px-2.5 py-1 text-[11px] font-semibold text-emerald-700">
                          동일 기준 비교 · {row.compareLabel}
                        </span>
                      )}
                      {!row.isComparable && row.productCount >= 2 && (
                        <span className="rounded-full bg-slate-100 px-2.5 py-1 text-[11px] font-semibold text-slate-500">
                          단위 상이 또는 표기 부족
                        </span>
                      )}
                    </div>
                  </div>

                  {row.cells.map((cell) => (
                    <div
                      key={`${row.ingredientId}-${cell.productId}`}
                      className={cn(
                        "border-l border-slate-100 px-4 py-4",
                        focusProductId === cell.productId ? "bg-blue-50/40" : "",
                      )}
                    >
                      <AmountCell
                        cell={cell}
                        row={row}
                        highlighted={focusProductId === cell.productId}
                      />
                    </div>
                  ))}
                </div>
              ))}
            </div>
          </div>
        </div>
      )}
    </section>
  );
}

function AmountCell({
  cell,
  row,
  highlighted,
}: {
  cell: ComparisonCell;
  row: IngredientComparisonRow;
  highlighted?: boolean;
}) {
  if (!cell.ingredient) {
    return <div className="py-3 text-center text-sm text-slate-300">—</div>;
  }

  const amount = cell.amount;
  const isComparable =
    row.isComparable &&
    amount?.normalizedValue !== null &&
    row.maxComparableValue !== null &&
    row.maxComparableValue > 0;
  const comparableAmountValue = isComparable ? amount?.normalizedValue ?? null : null;
  const ratio =
    comparableAmountValue !== null && row.maxComparableValue !== null
      ? Math.max(8, (comparableAmountValue / row.maxComparableValue) * 100)
      : 0;
  const isMax = comparableAmountValue !== null && comparableAmountValue === row.maxComparableValue;

  return (
    <div
      className={cn(
        "rounded-xl border px-3 py-3",
        highlighted ? "border-blue-200 bg-white" : "border-slate-200 bg-slate-50/60",
      )}
    >
      <div className="flex items-start justify-between gap-3">
        <div>
          <div className="text-sm font-semibold text-slate-900">
            {amount?.displayText || "표기 없음"}
          </div>
          <div className="mt-1 text-[11px] text-slate-400">
            {getIngredientRoleLabel(cell.ingredient.ingredient_role)}
          </div>
        </div>
        {isMax && (
          <span className="rounded-full bg-emerald-100 px-2 py-1 text-[11px] font-semibold text-emerald-700">
            최대
          </span>
        )}
      </div>

      {isComparable ? (
        <div className="mt-3">
          <div className="h-2 rounded-full bg-slate-200">
            <div
              className="h-2 rounded-full bg-emerald-500 transition-all"
              style={{ width: `${Math.min(ratio, 100)}%` }}
            />
          </div>
        </div>
      ) : (
        <div className="mt-3 text-[11px] text-slate-400">
          {row.productCount >= 2 ? "상대 비교 없음" : "단독 포함"}
        </div>
      )}
    </div>
  );
}

function SummaryCard({
  label,
  value,
  description,
  tone,
}: {
  label: string;
  value: number;
  description: string;
  tone: "emerald" | "amber" | "blue" | "slate";
}) {
  const toneClassName =
    {
      emerald: "bg-emerald-50 text-emerald-700 border-emerald-100",
      amber: "bg-amber-50 text-amber-700 border-amber-100",
      blue: "bg-blue-50 text-blue-700 border-blue-100",
      slate: "bg-slate-50 text-slate-700 border-slate-100",
    }[tone] || "bg-slate-50 text-slate-700 border-slate-100";

  return (
    <Card className="border-slate-200 p-5">
      <div className={cn("inline-flex rounded-full border px-3 py-1 text-xs font-semibold", toneClassName)}>
        {label}
      </div>
      <div className="mt-4 text-3xl font-black tracking-tight text-slate-900">
        {value.toLocaleString()}
      </div>
      <p className="mt-2 text-sm leading-6 text-slate-500">{description}</p>
    </Card>
  );
}

function EmptySection({ message }: { message: string }) {
  return (
    <Card className="border-dashed border-slate-200 bg-slate-50/70 p-8 text-center text-sm text-slate-400">
      {message}
    </Card>
  );
}

function buildComparisonRow(
  ingredientId: number,
  selectedIds: number[],
  productIngredients: Record<number, ProductIngredient[]>,
  ingredientMap: Map<number, { name: string; href: string }>,
): IngredientComparisonRow | null {
  const ingredientMeta = ingredientMap.get(ingredientId);
  if (!ingredientMeta) return null;

  const cells: ComparisonCell[] = selectedIds.map((productId) => {
    const ingredient =
      (productIngredients[productId] ?? []).find((entry) => entry.ingredient_id === ingredientId) ?? null;
    return {
      productId,
      ingredient,
      amount: ingredient
        ? normalizeAmount(ingredient.amount_per_serving, ingredient.amount_unit)
        : null,
    };
  });

  const presentCells = cells.filter((cell) => cell.ingredient);
  const compareKeys = new Set(
    presentCells.map((cell) => cell.amount?.compareKey).filter(Boolean) as string[],
  );
  const comparableValues = presentCells
    .map((cell) => cell.amount?.normalizedValue)
    .filter((value): value is number => typeof value === "number" && Number.isFinite(value));

  const isComparable =
    presentCells.length >= 2 &&
    compareKeys.size === 1 &&
    comparableValues.length === presentCells.length;

  return {
    ingredientId,
    ingredientName: ingredientMeta.name,
    ingredientHref: ingredientMeta.href,
    cells,
    productCount: presentCells.length,
    isComparable,
    compareLabel: isComparable ? presentCells[0]?.amount?.compareLabel ?? null : null,
    maxComparableValue: isComparable ? Math.max(...comparableValues) : null,
    duplicate: presentCells.length >= 2,
    uniqueOwnerId: presentCells.length === 1 ? presentCells[0]!.productId : null,
  };
}

function normalizeAmount(amountPerServing: string | null, amountUnit: string | null): NormalizedAmount {
  const displayText = [amountPerServing, amountUnit].filter(Boolean).join(" ").trim() || "표기 없음";
  const numericValue = parseNumericValue(amountPerServing);
  const normalizedUnit = normalizeUnit(amountUnit);

  if (numericValue === null || !normalizedUnit) {
    return {
      displayText,
      normalizedValue: null,
      compareKey: null,
      compareLabel: null,
    };
  }

  return {
    displayText,
    normalizedValue: numericValue * normalizedUnit.factor,
    compareKey: normalizedUnit.compareKey,
    compareLabel: normalizedUnit.label,
  };
}

function parseNumericValue(value: string | null): number | null {
  if (!value) return null;
  const cleaned = value.replace(/,/g, "").match(/-?\d+(\.\d+)?/);
  if (!cleaned) return null;
  const parsed = Number(cleaned[0]);
  return Number.isFinite(parsed) ? parsed : null;
}

function normalizeUnit(unit: string | null): { factor: number; compareKey: string; label: string } | null {
  if (!unit) return null;
  const normalized = unit.replace(/\s+/g, " ").trim();

  for (const candidate of CFU_UNIT_FACTORS) {
    if (candidate.pattern.test(normalized)) {
      return {
        factor: candidate.factor,
        compareKey: "count-cfu",
        label: "CFU",
      };
    }
  }

  if (/iu/i.test(normalized)) {
    return { factor: 1, compareKey: "count-iu", label: "IU" };
  }

  for (const candidate of MASS_UNIT_FACTORS) {
    if (candidate.pattern.test(normalized)) {
      return candidate;
    }
  }

  for (const candidate of VOLUME_UNIT_FACTORS) {
    if (candidate.pattern.test(normalized)) {
      return candidate;
    }
  }

  return null;
}
