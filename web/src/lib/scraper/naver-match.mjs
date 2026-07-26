/**
 * Naver Shopping 매칭·검증 공용 모듈.
 *
 * 배치 스크레이퍼(scripts/scrape_naver_shopping.mjs)와
 * 실시간 검색 API(app/api/products/live-search)가 공유한다.
 *
 * 규칙 요약:
 *  - Bigram Jaccard 유사도 기반 매칭, 최소 점수 4.0 (공백 제거 5자 이하 이름은 5.0)
 *  - 카테고리 허용 목록: category1 "식품"만 통과 (화장품·육아용품 등 차단)
 *  - 브랜드 일치 +3, 이미지 존재 +1 보너스
 */

/** 기본 정규화: 공백 통일, zero-width 제거. */
export function normalize(text) {
  if (!text) return "";
  return text
    .replace(/\s+/g, " ")
    .replace(/[​-‍﻿]/g, "")
    .trim();
}

/**
 * 검색어 전처리:
 *  - 괄호 + 내용 제거: (전량수출용), 【...】
 *  - 한자 제거, 구두점 → 공백, 연속 공백 정리
 */
export function cleanSearchQuery(rawName) {
  return rawName
    .replace(/\([^)]*\)/g, "")
    .replace(/【[^】]*】/g, "")
    .replace(/[\u4E00-\u9FFF]/g, "")
    .replace(/[,./\-·•]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

/**
 * 검색어 단축 시퀀스 생성: "A B C D" → ["A B C D", "A B C", "A B"]
 */
export function queryVariants(query) {
  const variants = [query];
  const tokens = query.split(/\s+/);
  for (let len = tokens.length - 1; len >= 2; len--) {
    variants.push(tokens.slice(0, len).join(" "));
  }
  return variants;
}

/** 공백 무시 bigram 집합 (한국어 연속 제품명 대응) */
export function bigrams(s) {
  const clean = s.replace(/\s+/g, "").toLowerCase();
  const grams = new Set();
  for (let i = 0; i < clean.length - 1; i++) {
    grams.add(clean.slice(i, i + 2));
  }
  return grams;
}

/** Jaccard 유사도 (0~1) */
export function jaccard(a, b) {
  if (a.size === 0 || b.size === 0) return 0;
  let inter = 0;
  for (const g of a) if (b.has(g)) inter++;
  return inter / (a.size + b.size - inter);
}

/**
 * 허용 목록 방식 카테고리 필터.
 *
 * 건강기능식품·영양제는 예외 없이 "식품 > 건강식품" 경로에 분류되므로
 * category1이 "식품"인 항목만 통과시킨다. 차단 목록 방식은 화장품이
 * "출산/육아 > 스킨/바디용품" 등 다른 경로로 새어 들어오는 것을 막지
 * 못해 폐기했다. category 정보가 없는 항목은 안전하게 차단한다.
 */
export const ALLOWED_CATEGORY1 = ["식품"];

export function isAllowedCategory(item) {
  return ALLOWED_CATEGORY1.includes(item.category1);
}

/** 짧은 이름(공백 제거 ≤5자)은 오매칭 가능성이 높으므로 최소 점수 상향 */
export function minScoreForName(productName) {
  const nameLen = (productName ?? "").replace(/\s/g, "").length;
  return nameLen <= 5 ? 5 : 4;
}

/**
 * DB 제품 1건 vs Naver 검색 결과 items 중 최적 후보 선정.
 * @returns {{ item: object | null, score: number }}
 */
export function pickBestItem(product, items) {
  const nameNorm = normalize(product.product_name);
  const brandNorm = normalize(product.brand_name ?? product.manufacturer_name ?? "");
  const nameGrams = bigrams(nameNorm);

  let best = null;
  let bestScore = -Infinity;

  for (const item of items) {
    if (!isAllowedCategory(item)) continue;

    const title = normalize(item.title);
    const brand = normalize(item.brand ?? item.maker ?? "");
    const titleGrams = bigrams(title);

    // Jaccard 유사도 (이름 bigram) — 0~1 → 0~10점
    const jac = jaccard(nameGrams, titleGrams);
    let score = jac * 10;

    // 브랜드 일치 보너스 — DB 또는 Naver 측 brand/maker에 부분 포함
    if (brandNorm.length >= 2) {
      const brandClean = brandNorm.replace(/\s+/g, "").toLowerCase();
      const brandHit =
        brand.replace(/\s+/g, "").toLowerCase().includes(brandClean) ||
        title.replace(/\s+/g, "").toLowerCase().includes(brandClean);
      if (brandHit) score += 3;
    }

    // 이미지 존재 보너스
    if (item.image) score += 1;

    if (score > bestScore) {
      bestScore = score;
      best = item;
    }
  }

  return { item: best, score: bestScore };
}

/**
 * 자유 텍스트 검색어(성분명·제품명) 모드 필터.
 * 특정 DB 제품과의 1:1 매칭이 아니므로 Jaccard 임계값 대신
 * "차단 카테고리 제외 + 검색어 토큰 전부 포함" 기준을 쓴다.
 */
export function filterItemsForQuery(query, items) {
  const tokens = normalize(query)
    .toLowerCase()
    .split(/\s+/)
    .filter((t) => t.length >= 1);
  if (tokens.length === 0) return [];

  return items.filter((item) => {
    if (!isAllowedCategory(item)) return false;
    const haystack = `${item.title} ${item.brand ?? ""} ${item.maker ?? ""}`
      .replace(/\s+/g, "")
      .toLowerCase();
    return tokens.every((t) => haystack.includes(t.replace(/\s+/g, "")));
  });
}
