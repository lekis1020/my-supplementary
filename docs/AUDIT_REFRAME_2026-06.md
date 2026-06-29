# NutriCompare 전체 코드 점검 & Reframe 제안 (2026-06)

> 6개 서브시스템 매핑 → 6개 차원 리뷰 → 적대적 검증 → reframe 판정단(3안) → 종합.
> 45개 이슈 확정 (HIGH 5 / MEDIUM 22 / LOW 18).

## 핵심 결론

아키텍처 부채는 실재하지만 **긴급한 건 부채가 아니라, 작게 고칠 수 있는 결함 몇 개**다:
1. **법적 컴플라이언스 위반** — 금지(prohibited) 표현 건강기능 클레임이 소비자 화면에 노출
2. **service_role 관리자 페이지가 인증 없이 노출** (RLS 우회)
3. **정부 API 키가 평문으로 DB 컬럼(raw_documents.source_url)에 저장**

→ 큰 리라이트보다 **출혈부터 막고(Phase 1) → 테스트/CI 안전망 → 값싼 위생작업 → 그다음 구조 개편(Phase 2)**.

## HIGH 이슈 (즉시)

| # | 차원 | 이슈 | 위치 |
|---|---|---|---|
| H1 | security | 금지 클레임이 ingredient/[slug]·products/[id] 소비자 화면에 승인 클레임과 동일 뱃지로 노출 (법적 요구 위반). claims RLS는 USING(TRUE)라 DB 백스톱 없음 | `ingredients/[slug]/page.tsx`, `products/[id]/page.tsx`, `db/002_rls_policies.sql:96` |
| H2 | architecture/security | `/admin/data-health`가 service_role(adminDb, RLS 우회)인데 인증 게이트 없음. `middleware.ts` 부재 | `app/admin/data-health/page.tsx` |
| H3 | security | KR 정부 API 키가 fetch URL에 박힌 채 `raw_documents.source_url`로 저장(쿼리 가능). http:// 평문 전송도 동반 | `scripts/backfill_kr_gov_raw.mjs:123/660/698` |
| H4 | data-integrity | 규제 vs 과학 분리가 컬럼으로만 모델링, DB 제약 없음 (`is_regulator_approved` ↔ `approval_country_code` CHECK 부재, 코드값 FK 미결속) | `db/001_schema.sql` |

## 주목 MEDIUM

- **getClaimWeight 데드 브랜치**(`benefit-profile.ts:101-105`): 둘 다 `return 1` → 약한/금지 클레임도 'possible'로 과대평가, 'inactive' 도달 불가. (correctness+quality 양쪽서 확인)
- **검색 인젝션**(`search/page.tsx:255,302`): 원본 쿼리를 PostgREST `.or()`에 그대로 보간 → 콤마/괄호/점으로 필터 깨짐 + 오퍼레이터 인젝션 벡터.
- **스크래퍼 매칭 임계값 3종 불일치**: cafe24 raw≥0.3 / ckdhc raw≥0.35 / naver 합성점수≥4 → 같은 상품쌍이 스크래퍼에 따라 매칭/미스.
- **god-file 2개**: `ingredients/[slug]` 1174 LOC, `compare-workbench` 1149 LOC — fetch+도메인연산+렌더 혼재. 서비스/도메인 레이어 부재.
- **마이그레이션 혼돈**: 015~019 번호 중복 2회씩, 적용 원장 없음. 9+개 dedup/merge/normalize 마이그레이션 = ingest 시점 유니크 미강제. RUN_THIS_ONLY.sql(175KB) vs 번호파일 vs supabase/migrations 3중 진실원.
- **테스트 0%**: 러너·스펙·CI 전무 (lint만).
- **Drizzle 스키마 드리프트**: FK가 bigserial, DATE를 timestamp로 — `drizzle-kit push` 시 시퀀스 손상 위험.

(LOW 18개: debug API 미게이트, utils.ts 535 LOC 잡탕, 페이지네이션/localStorage/env로더 중복, products.is_published 미생성으로 001→002 깨짐 등 — 파일 참조)

## Reframe 권장 실행 순서

**Phase 1 — 출혈 차단 (모두 S, 당일 가능)**
1. 금지 클레임 필터(두 소비자 화면) + getClaimWeight 가드(prohibited/무신호→0, 끝 `return 1`→`return 0`)
2. `middleware.ts` 추가로 `/admin/*`·`/api/admin/*` 게이트 + 페이지 자체 fail-closed, debug API는 prod 404
3. API 키를 source_url에서 분리(fetch용/저장용 URL 분기) + https + 기존행 스크럽 + 키 회전
4. 검색 `.or()` 입력 sanitize(양쪽 호출부)

**Phase 2 — 안전망 & 위생 (잠금)**
5. Vitest + `test` 스크립트 + CI(lint+tsc+test). 순수 모듈(benefit-profile/probiotic/compare) 우선. getClaimWeight 회귀 시 red 확인
6. 값싼 마이그레이션 위생: products.is_published를 001로, `018_*_test.sql` 퇴역, `RUN_ORDER.md`, 중복 016 인덱스 drop, RUN_THIS_ONLY 재생성
7. `scripts/lib/{match,save-image,vision}.mjs` 추출 + 전 스크립트를 `lib/env.mjs`로. `lib/compare-normalize.ts` 추출 후 `/api/compare/summary`와 수렴

**Phase 3 — 구조 개편 (XL, 불 끈 뒤)**
8. `lib/repositories/*`(getConsumerClaims가 allowlist 내장 → 법적 필터가 구조적으로 강제) + `lib/domain/*`, utils.ts 분리, 타입드 Supabase 클라이언트, god-file을 섹션 컴포넌트로 thin화
9. KR ingest에 canonical-name 해석 + ON CONFLICT upsert, 누락 제약 추가(dosage 유니크, NULL-country 부분 유니크, 컴플라이언스 CHECK), 단일 마이그레이션 트랙+원장, Drizzle introspect 재정렬

## 기각된 안 (이유)
- pg_tsvector 검색 전면 재작성을 1차로: 옳은 종착점이나 L공수, 출혈차단엔 sanitize면 충분 → 지연 TODO
- 마이그레이션 툴 도입을 첫수로: fresh 배포는 RUN_THIS_ONLY로 동작 중, 응급 아님 → Phase 2
- 중복번호 5쌍 즉시 리넘버: destructive·순서 의존 高위험 → RUN_ORDER.md로 대체, 리넘버는 원장 도입 후 1회
- god-file 전면 분해를 단기 산출물로: 유지보수비일 뿐 결함 아님 → 순수연산 추출만 단기, 나머지 Phase 3
