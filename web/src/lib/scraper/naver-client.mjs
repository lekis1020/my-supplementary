/**
 * Naver Shopping Open API 클라이언트.
 *
 * Docs: https://developers.naver.com/docs/serviceapi/search/shopping/shopping.md
 *
 * Rate limit: 개발자 센터 계정당 일 25,000 호출 무료.
 * 분당 제한은 문서화되지 않았으나 ~1 req/sec 권장.
 */

const ENDPOINT = "https://openapi.naver.com/v1/search/shop.json";

/**
 * @param {string} query 검색어 (제품명)
 * @param {object} opts
 * @param {number} [opts.display=10] 반환 건수 (1-100)
 * @param {number} [opts.start=1]    시작 오프셋 (1-1000)
 * @param {string} [opts.sort='sim'] sim | date | asc | dsc
 */
export async function searchNaverShopping(query, opts = {}) {
  const clientId = process.env.NAVER_SHOPPING_CLIENT_ID;
  const clientSecret = process.env.NAVER_SHOPPING_CLIENT_SECRET;

  if (!clientId || !clientSecret) {
    throw new Error("NAVER_SHOPPING_CLIENT_ID/SECRET 미설정");
  }

  const params = new URLSearchParams({
    query,
    display: String(opts.display ?? 10),
    start: String(opts.start ?? 1),
    sort: opts.sort ?? "sim",
  });

  const res = await fetch(`${ENDPOINT}?${params}`, {
    headers: {
      "X-Naver-Client-Id": clientId,
      "X-Naver-Client-Secret": clientSecret,
      "User-Agent": "bochoong-scraper/1.0 (+https://bochoong.com/about)",
    },
  });

  if (!res.ok) {
    const body = await res.text().catch(() => "");
    throw new Error(`Naver API ${res.status}: ${body.slice(0, 200)}`);
  }

  const data = await res.json();
  return {
    total: data.total ?? 0,
    items: (data.items ?? []).map(normalizeItem),
  };
}

/**
 * Naver 응답을 정규화.
 *   title, brand, maker는 HTML 태그(<b>...</b>) 포함 가능 → strip.
 */
function normalizeItem(item) {
  const stripHtml = (s) => (s ?? "").replace(/<[^>]*>/g, "").trim();
  return {
    title: stripHtml(item.title),
    link: item.link,                   // 상품 상세 페이지 (랜딩)
    image: item.image,                 // 대표 이미지 URL
    lprice: item.lprice ? Number(item.lprice) : null,
    hprice: item.hprice ? Number(item.hprice) : null,
    mallName: item.mallName,
    productId: item.productId,         // Naver 내부 ID
    productType: item.productType,     // 1=일반, 2=중고 등
    brand: stripHtml(item.brand),
    maker: stripHtml(item.maker),
    category1: item.category1,
    category2: item.category2,
    category3: item.category3,
    category4: item.category4,
  };
}

/** 간단한 rate limit: 각 호출 사이 delayMs 대기. */
export async function throttle(ms) {
  return new Promise((r) => setTimeout(r, ms));
}
