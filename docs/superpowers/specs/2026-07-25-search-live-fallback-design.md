# /search 실시간 판매확인 폴백 UI 설계

날짜: 2026-07-25
상태: 승인됨

## 목표

`/search` 페이지에서 판매확인(sale-verified) 제품 결과가 빈약할 때, 기존
`/api/products/live-search` API를 활용해 네이버 쇼핑 실시간 검색 결과를
별도 섹션으로 보여준다. 성분 상세 페이지에 이미 구현된 실시간 폴백 패턴을
일반화해 재사용한다.

## 범위

- 대상: `/search`만. `/products`는 자유 검색창이 없어 이번 범위에서 제외.
- 백엔드 변경 없음 — `/api/products/live-search`를 그대로 사용.

## 설계

### 1. 컴포넌트 일반화

`web/src/components/product/live-related-products.tsx`를
`web/src/components/product/live-search-fallback.tsx`로 일반화한다.

```
LiveSearchFallback({
  query: string;        // 검색어 (성분명 또는 사용자 검색어)
  initialCount: number; // 페이지가 이미 표시 중인 판매확인 결과 수
  threshold: number;    // 폴백 발동 기준 (initialCount < threshold일 때만 fetch)
  description?: string; // 배지 옆 안내 문구 (기본: 기존 문구)
})
```

- fetch 로직, 카드 UI, 로딩 스켈레톤, "실시간 검색 결과" 배지는 기존 그대로.
  단, 가격(lprice) 표시는 제거한다 — 카드에는 제품명 / 브랜드·몰 / 외부
  구매 링크만 남긴다. 공유 컴포넌트이므로 성분 상세 페이지에도 동일 적용.
- `MAX_DISPLAY = 6`, 검색어 2자 미만 시 fetch 생략 규칙 유지.
- 성분 상세 페이지(`ingredients/[slug]/page.tsx`)는 새 컴포넌트를
  `threshold={3}`으로 호출하도록 변경 — 동작 변화 없음.
- 기존 `live-related-products.tsx` 파일은 삭제(대체).

### 2. /search 통합

`web/src/app/search/page.tsx` 서버 컴포넌트에서:

- `productResults.filter(p => p.saleVerified).length`로 판매확인 총수 계산
  (페이지네이션과 무관하게 전체 결과 기준).
- 제품 결과 섹션 아래(결과 0건으로 EmptyState가 표시될 때도 그 아래)에
  `<LiveSearchFallback query={query} initialCount={verifiedCount} threshold={5} />`
  렌더. threshold 5는 API의 `MIN_DB_RESULTS`와 일치.
- 페이지 이동 시 반복 fetch는 API의 24시간 인메모리 캐시가 흡수한다.

### 3. 법적 준수·엣지 케이스

- 실시간 카드에는 제품명 / 브랜드·몰 / 외부 구매 링크만 표시 (가격 미표시).
  건강 기능 표방 문구·성분 매칭 정보는 절대 표시하지 않는다 (기존 규칙).
- API 실패 또는 빈 결과 시 섹션 자체를 숨긴다.
- 검색어 없음(`!query`) 상태에서는 렌더하지 않는다.

## 검증

1. `npm run lint`, `npm run build` 통과.
2. dev 서버에서:
   - 판매확인 결과가 빈약한 검색어 → 실시간 섹션 표시 확인.
   - 결과가 풍부한 검색어(예: "마그네슘") → 실시간 섹션 미표시 확인.
   - 성분 상세 페이지 폴백 회귀 확인 (threshold 3 동작 동일).
