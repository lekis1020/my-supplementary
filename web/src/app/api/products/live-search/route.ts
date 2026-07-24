import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { createAdminClient } from "@/lib/supabase/admin";
import { searchNaverShopping } from "@/lib/scraper/naver-client.mjs";
import { filterItemsForQuery, normalize } from "@/lib/scraper/naver-match.mjs";

/**
 * GET /api/products/live-search?q=<검색어>
 *
 * DB 우선 → 미스 시 Naver Shopping 실시간 폴백.
 *  1. products를 RLS 경유로 검색 (판매확인 우선 정렬)
 *  2. 판매확인 결과가 MIN_DB_RESULTS 미만이면 Naver API 호출
 *  3. 카테고리 필터 + 토큰 매칭 통과분만 응답에 포함하고,
 *     service_role로 products upsert + 성분 보강 큐(product_enrichment_queue) 등록
 *
 * 보호 장치: 동일 쿼리 24시간 인메모리 캐시, 일일 Naver 호출 예산.
 * (서버 인스턴스 재시작 시 캐시/카운터 초기화 — 일 25,000 한도 대비 보수적 예산)
 */

export const dynamic = "force-dynamic";

const MIN_DB_RESULTS = 5;
const DB_LIMIT = 20;
const LIVE_DISPLAY = 20;
const MAX_PERSIST = 5;
const CACHE_TTL_MS = 24 * 60 * 60 * 1000; // 24h
const DAILY_NAVER_BUDGET = 2000; // 일일 API 한도 25,000의 일부만 실시간에 허용

interface DbResult {
  id: number;
  product_name: string;
  brand_name: string | null;
  manufacturer_name: string | null;
  product_image_url: string | null;
  sale_verified_at: string | null;
  sale_channel: string | null;
  sale_url: string | null;
}

interface LiveResult {
  title: string;
  link: string;
  image: string | null;
  lprice: number | null;
  mallName: string | null;
  brand: string | null;
  productId: number | null; // 적재된 products.id (실패 시 null)
}

interface LiveSearchResponse {
  query: string;
  db: DbResult[];
  live: LiveResult[];
  liveFetched: boolean;
  cached: boolean;
}

interface NaverItem {
  title: string;
  link: string;
  image: string | null;
  lprice: number | null;
  mallName: string | null;
  brand: string | null;
  maker: string | null;
  category1?: string;
  category2?: string;
}

// 모듈 스코프 캐시/예산 (인스턴스 단위 — compare/summary와 동일 패턴)
const liveCache = new Map<string, { expiresAt: number; live: LiveResult[] }>();
let budgetDay = "";
let budgetUsed = 0;

function consumeBudget(): boolean {
  const today = new Date().toISOString().slice(0, 10);
  if (budgetDay !== today) {
    budgetDay = today;
    budgetUsed = 0;
  }
  if (budgetUsed >= DAILY_NAVER_BUDGET) return false;
  budgetUsed += 1;
  return true;
}

function cacheKey(q: string): string {
  return normalize(q).toLowerCase();
}

async function searchDb(query: string): Promise<DbResult[]> {
  const supabase = await createClient();
  const { data } = await supabase
    .from("products")
    .select(
      "id, product_name, brand_name, manufacturer_name, product_image_url, sale_verified_at, sale_channel, sale_url",
    )
    .eq("is_published", true)
    .or(`product_name.ilike.%${query}%,brand_name.ilike.%${query}%`)
    .order("sale_verified_at", { ascending: false, nullsFirst: false })
    .order("product_name")
    .limit(DB_LIMIT);

  return (data ?? []) as DbResult[];
}

/** 검증 통과한 Naver 아이템을 products + 보강 큐에 적재. 실패해도 응답은 계속. */
async function persistLiveItem(item: NaverItem): Promise<number | null> {
  try {
    const admin = createAdminClient();

    // 이미 같은 판매 링크로 적재된 제품이 있으면 재사용
    const { data: existing } = await admin
      .from("products")
      .select("id")
      .eq("sale_url", item.link)
      .limit(1)
      .maybeSingle();

    if (existing) return existing.id;

    const { data: inserted, error } = await admin
      .from("products")
      .insert({
        product_name: normalize(item.title).slice(0, 255),
        brand_name: item.brand || item.maker || null,
        country_code: "KR",
        product_type: "health_functional_food",
        status: "active",
        is_published: true,
        sale_verified_at: new Date().toISOString(),
        sale_channel: "live_search",
        sale_url: item.link,
      })
      .select("id")
      .single();

    if (error || !inserted) return null;

    await admin.from("product_enrichment_queue").upsert(
      {
        product_id: inserted.id,
        status: "pending",
        source: "live_search",
        payload: {
          naver_title: item.title,
          link: item.link,
          image: item.image,
          lprice: item.lprice,
          mall_name: item.mallName,
          brand: item.brand,
          maker: item.maker,
        },
      },
      { onConflict: "product_id", ignoreDuplicates: true },
    );

    return inserted.id;
  } catch {
    return null;
  }
}

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const query = (searchParams.get("q") ?? "").trim();

  if (query.length < 2 || query.length > 80) {
    return NextResponse.json(
      { error: "검색어는 2자 이상 80자 이하여야 합니다." },
      { status: 400 },
    );
  }

  const db = await searchDb(query);
  const verifiedCount = db.filter((p) => p.sale_verified_at != null).length;

  const base: LiveSearchResponse = {
    query,
    db,
    live: [],
    liveFetched: false,
    cached: false,
  };

  // 판매확인 결과가 충분하면 실시간 폴백 불필요
  if (verifiedCount >= MIN_DB_RESULTS) {
    return NextResponse.json(base);
  }

  // 캐시 히트
  const key = cacheKey(query);
  const cachedEntry = liveCache.get(key);
  if (cachedEntry && cachedEntry.expiresAt > Date.now()) {
    return NextResponse.json({ ...base, live: cachedEntry.live, cached: true });
  }

  // Naver 키 미설정 또는 예산 소진 시 DB 결과만 반환
  if (
    !process.env.NAVER_SHOPPING_CLIENT_ID ||
    !process.env.NAVER_SHOPPING_CLIENT_SECRET ||
    !consumeBudget()
  ) {
    return NextResponse.json(base);
  }

  try {
    const res = await searchNaverShopping(query, { display: LIVE_DISPLAY });
    const accepted = filterItemsForQuery(query, res.items) as NaverItem[];

    // DB 결과와 중복(동일 판매 링크) 제거
    const knownUrls = new Set(db.map((p) => p.sale_url).filter(Boolean));
    const fresh = accepted.filter((item) => !knownUrls.has(item.link));

    // 상위 일부만 적재 (요청 경로 지연 최소화)
    const live: LiveResult[] = [];
    for (const [index, item] of fresh.entries()) {
      const productId =
        index < MAX_PERSIST ? await persistLiveItem(item) : null;
      live.push({
        title: normalize(item.title),
        link: item.link,
        image: item.image ?? null,
        lprice: item.lprice ?? null,
        mallName: item.mallName ?? null,
        brand: item.brand || item.maker || null,
        productId,
      });
    }

    liveCache.set(key, { expiresAt: Date.now() + CACHE_TTL_MS, live });

    return NextResponse.json({ ...base, live, liveFetched: true });
  } catch {
    // Naver 장애 시에도 DB 결과는 반환
    return NextResponse.json(base);
  }
}
