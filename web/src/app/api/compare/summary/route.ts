import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

/**
 * POST /api/compare/summary
 *
 * Body: { productIds: number[] }
 *
 * Aggregates published product + ingredient data on the server, feeds a
 * compact comparison brief to an LLM (default: gpt-5-mini), and returns a
 * short Korean-language summary to render above the detailed compare tables.
 */

const OPENAI_MODEL = process.env.OPENAI_COMPARE_MODEL || "gpt-5-mini";
const OPENAI_ENDPOINT = "https://api.openai.com/v1/chat/completions";
const CACHE_TTL_MS = 10 * 60 * 1000; // 10 minutes
const MAX_PRODUCTS = 4;

interface CacheEntry {
  expiresAt: number;
  payload: SummaryResponse;
}

interface SummaryResponse {
  summary: string;
  model: string;
  cached: boolean;
  stats: {
    productCount: number;
    commonIngredientCount: number;
    overlapIngredientCount: number;
    uniqueIngredientCount: number;
    duplicateIngredientCount: number;
  };
}

// Module-scope cache (per server instance). Good enough for a low-traffic
// comparison tool; swap for Redis later if needed.
const summaryCache = new Map<string, CacheEntry>();

interface ProductRow {
  id: number;
  product_name: string;
  manufacturer_name: string | null;
  country_code: string | null;
}

interface IngredientJoin {
  id: number;
  canonical_name_ko: string | null;
  canonical_name_en: string | null;
  ingredient_type: string | null;
}

interface ProductIngredientRow {
  product_id: number;
  ingredient_id: number;
  amount_per_serving: string | number | null;
  amount_unit: string | null;
  daily_amount: string | number | null;
  daily_amount_unit: string | null;
  raw_label_name: string | null;
  ingredient_role: string | null;
  ingredients: IngredientJoin | null;
}

function cacheKey(productIds: number[]) {
  return [...productIds].sort((a, b) => a - b).join("-");
}

function formatAmount(row: ProductIngredientRow): string {
  const value = row.amount_per_serving ?? row.daily_amount;
  const unit = row.amount_unit ?? row.daily_amount_unit;
  if (value == null && !unit) return "";
  return `${value ?? ""}${unit ?? ""}`.trim();
}

export async function POST(request: Request) {
  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  const rawIds = (body as { productIds?: unknown })?.productIds;
  if (!Array.isArray(rawIds) || rawIds.length < 2) {
    return NextResponse.json(
      { error: "productIds must be an array with at least 2 IDs" },
      { status: 400 },
    );
  }

  const productIds = Array.from(
    new Set(
      rawIds
        .map((value) => Number(value))
        .filter((value) => Number.isFinite(value) && value > 0),
    ),
  ).slice(0, MAX_PRODUCTS);

  if (productIds.length < 2) {
    return NextResponse.json(
      { error: "At least 2 valid product IDs required" },
      { status: 400 },
    );
  }

  const key = cacheKey(productIds);
  const now = Date.now();
  const cached = summaryCache.get(key);
  if (cached && cached.expiresAt > now) {
    return NextResponse.json({ ...cached.payload, cached: true });
  }

  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    return NextResponse.json(
      { error: "OPENAI_API_KEY is not configured on the server" },
      { status: 503 },
    );
  }

  const supabase = await createClient();

  const { data: products, error: productError } = await supabase
    .from("products")
    .select("id, product_name, manufacturer_name, country_code")
    .eq("is_published", true)
    .in("id", productIds);

  if (productError) {
    return NextResponse.json({ error: productError.message }, { status: 500 });
  }
  if (!products || products.length < 2) {
    return NextResponse.json(
      { error: "요청한 제품을 찾을 수 없습니다" },
      { status: 404 },
    );
  }

  const { data: ingredients, error: ingredientError } = await supabase
    .from("product_ingredients")
    .select(
      "product_id, ingredient_id, amount_per_serving, amount_unit, daily_amount, daily_amount_unit, raw_label_name, ingredient_role, ingredients(id, canonical_name_ko, canonical_name_en, ingredient_type)",
    )
    .in("product_id", productIds);

  if (ingredientError) {
    return NextResponse.json({ error: ingredientError.message }, { status: 500 });
  }

  const productMap = new Map<number, ProductRow>();
  for (const product of (products as ProductRow[]) ?? []) {
    productMap.set(product.id, product);
  }

  const rows = ((ingredients as unknown) as ProductIngredientRow[]) ?? [];
  const byProduct = new Map<number, ProductIngredientRow[]>();
  const ingredientProducts = new Map<number, Set<number>>();
  const ingredientNames = new Map<number, string>();

  for (const row of rows) {
    if (!row.ingredients) continue;
    const list = byProduct.get(row.product_id) ?? [];
    list.push(row);
    byProduct.set(row.product_id, list);

    const productSet = ingredientProducts.get(row.ingredient_id) ?? new Set<number>();
    productSet.add(row.product_id);
    ingredientProducts.set(row.ingredient_id, productSet);

    if (!ingredientNames.has(row.ingredient_id)) {
      const name =
        row.ingredients.canonical_name_ko ||
        row.ingredients.canonical_name_en ||
        row.raw_label_name ||
        `성분 #${row.ingredient_id}`;
      ingredientNames.set(row.ingredient_id, name);
    }
  }

  const selectedProducts = productIds
    .map((id) => productMap.get(id))
    .filter((p): p is ProductRow => Boolean(p));

  const totalSelected = selectedProducts.length;
  const commonIngredients: string[] = [];
  const overlapIngredients: string[] = [];
  const duplicateIngredients: string[] = [];
  const uniqueByProduct = new Map<number, string[]>();

  for (const [ingredientId, productSet] of ingredientProducts.entries()) {
    const name = ingredientNames.get(ingredientId) ?? `성분 #${ingredientId}`;
    if (productSet.size === totalSelected) {
      commonIngredients.push(name);
    } else if (productSet.size >= 2) {
      overlapIngredients.push(name);
    } else if (productSet.size === 1) {
      const owner = Array.from(productSet)[0]!;
      const list = uniqueByProduct.get(owner) ?? [];
      list.push(name);
      uniqueByProduct.set(owner, list);
    }
    if (productSet.size >= 2) {
      duplicateIngredients.push(name);
    }
  }

  // Per-product detail lines with ingredients + amounts, capped to keep the
  // prompt small.
  const productBriefs = selectedProducts.map((product) => {
    const list = (byProduct.get(product.id) ?? [])
      .slice(0, 30)
      .map((row) => {
        const name =
          row.ingredients?.canonical_name_ko ||
          row.ingredients?.canonical_name_en ||
          row.raw_label_name ||
          `성분 #${row.ingredient_id}`;
        const amount = formatAmount(row);
        return amount ? `${name} ${amount}` : name;
      });
    return {
      id: product.id,
      name: product.product_name,
      manufacturer: product.manufacturer_name,
      country: product.country_code,
      ingredientCount: (byProduct.get(product.id) ?? []).length,
      ingredientsPreview: list,
    };
  });

  const stats: SummaryResponse["stats"] = {
    productCount: totalSelected,
    commonIngredientCount: commonIngredients.length,
    overlapIngredientCount: overlapIngredients.length,
    uniqueIngredientCount: Array.from(uniqueByProduct.values()).reduce(
      (sum, list) => sum + list.length,
      0,
    ),
    duplicateIngredientCount: duplicateIngredients.length,
  };

  const prompt = buildPrompt({
    products: productBriefs,
    commonIngredients: commonIngredients.slice(0, 40),
    overlapIngredients: overlapIngredients.slice(0, 40),
    duplicateIngredients: duplicateIngredients.slice(0, 40),
    uniqueByProduct: Array.from(uniqueByProduct.entries()).map(([productId, list]) => ({
      productId,
      productName: productMap.get(productId)?.product_name ?? `제품 #${productId}`,
      ingredients: list.slice(0, 30),
    })),
    stats,
  });

  let summaryText: string;
  try {
    summaryText = await callOpenAI(apiKey, prompt);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return NextResponse.json(
      { error: `요약 생성에 실패했습니다: ${message}` },
      { status: 502 },
    );
  }

  const payload: SummaryResponse = {
    summary: summaryText,
    model: OPENAI_MODEL,
    cached: false,
    stats,
  };

  summaryCache.set(key, { expiresAt: now + CACHE_TTL_MS, payload });

  return NextResponse.json(payload);
}

interface PromptInput {
  products: Array<{
    id: number;
    name: string;
    manufacturer: string | null;
    country: string | null;
    ingredientCount: number;
    ingredientsPreview: string[];
  }>;
  commonIngredients: string[];
  overlapIngredients: string[];
  duplicateIngredients: string[];
  uniqueByProduct: Array<{ productId: number; productName: string; ingredients: string[] }>;
  stats: SummaryResponse["stats"];
}

function buildPrompt(input: PromptInput): { system: string; user: string } {
  const system = [
    "당신은 한국어 영양제 비교 분석가입니다.",
    "사용자가 선택한 영양제 제품들을 소비자 관점에서 간결하게 요약해주세요.",
    "의료적 조언은 하지 말고, 성분 구성과 조합 시 고려할 점을 객관적으로 정리합니다.",
    "결과는 한국어로, 마크다운 헤더 없이 짧은 문단 + 불릿(•)으로 구성합니다.",
    "길이는 공백 포함 600자 이내로 제한합니다.",
    "형식:",
    "1) 첫 2~3문장: 제품들의 전반적인 특징과 차이점 요약.",
    "2) '공통/중복 성분' 불릿: 주요 겹치는 성분 2~4개와 중복 섭취 시 유의점.",
    "3) '제품별 차별점' 불릿: 각 제품의 단독 성분이나 컨셉 요약.",
    "4) 마지막 한 줄: 어떤 사용자에게 어떤 제품이 더 맞을 수 있는지 힌트(확정적 표현 금지).",
  ].join("\n");

  const productLines = input.products
    .map((product) => {
      const header = `[${product.name}${product.manufacturer ? ` · ${product.manufacturer}` : ""}] (성분 ${product.ingredientCount}개)`;
      const preview = product.ingredientsPreview.join(", ");
      return `${header}\n- ${preview}`;
    })
    .join("\n\n");

  const uniqueLines = input.uniqueByProduct
    .map((entry) => `· ${entry.productName}: ${entry.ingredients.join(", ") || "(없음)"}`)
    .join("\n");

  const user = [
    `선택된 제품 수: ${input.stats.productCount}`,
    `공통 성분 수: ${input.stats.commonIngredientCount} / 중복 위험 성분 수: ${input.stats.duplicateIngredientCount} / 고유 성분 수: ${input.stats.uniqueIngredientCount}`,
    "",
    "== 제품별 성분 ==",
    productLines,
    "",
    `공통 성분: ${input.commonIngredients.join(", ") || "(없음)"}`,
    `부분 중복 성분: ${input.overlapIngredients.join(", ") || "(없음)"}`,
    "",
    "제품별 고유 성분:",
    uniqueLines || "(없음)",
  ].join("\n");

  return { system, user };
}

async function callOpenAI(
  apiKey: string,
  prompt: { system: string; user: string },
): Promise<string> {
  const response = await fetch(OPENAI_ENDPOINT, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model: OPENAI_MODEL,
      messages: [
        { role: "system", content: prompt.system },
        { role: "user", content: prompt.user },
      ],
      max_completion_tokens: 600,
    }),
  });

  if (!response.ok) {
    const errorText = await response.text().catch(() => "");
    throw new Error(
      `OpenAI ${response.status}: ${errorText.slice(0, 200) || response.statusText}`,
    );
  }

  const data = (await response.json()) as {
    choices?: Array<{ message?: { content?: string } }>;
  };
  const content = data.choices?.[0]?.message?.content?.trim();
  if (!content) {
    throw new Error("빈 응답이 반환되었습니다");
  }
  return content;
}
