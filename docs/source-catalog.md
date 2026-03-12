# Source Catalog

> Version: 1.0.0
> 작성일: 2026-03-12
> 대상: KR + US 데이터 소스

---

## 1. 소스 총괄

| # | 소스 | 국가 | 접근 전략 | 인증 | 우선순위 | Phase |
|---|------|------|-----------|------|----------|-------|
| 1 | 공공데이터포털 (건강기능식품) | KR | api | API Key (무료) | **1순위** | 1 |
| 2 | 공공데이터포털 (기능성 원료 인정) | KR | api | API Key (무료) | **1순위** | 1 |
| 3 | PubMed E-utilities | US | api | API Key (권장) | **1순위** | 1 |
| 4 | 식품안전나라 | KR | api | API Key (무료) | 2순위 | 1 |
| 5 | NIH DSLD | US | api | 불필요 | **1순위** | 1 |
| 6 | DailyMed | US | api | 불필요 | 2순위 | 1.5 |
| 7 | MFDS 고시/가이드 | KR | hybrid | 포털 가입 | 2순위 | 1.5 |
| 8 | openFDA (adverse event) | US | api | API Key (무료) | 3순위 | 2 |
| 9 | USDA FoodData Central | US | api | API Key (무료) | 3순위 | 2 |
| 10 | 제품 판매 사이트 (라벨) | KR/US | browser_agent | 불필요 | 2순위 | 1.5 |

---

## 2. KR 소스 상세

### 2.1 공공데이터포털 — 건강기능식품 정보

| 항목 | 내용 |
|------|------|
| **소스명** | 공공데이터포털 건강기능식품정보 |
| **URL** | https://www.data.go.kr/data/15056760/openapi.do |
| **접근 전략** | `api` |
| **인증** | API Key (무료, 가입 후 2~3일 승인) |
| **응답 포맷** | JSON, XML |
| **Rate Limit** | 개발: 1,000건/일, 운영: 100,000건/일 |
| **페이지네이션** | 최대 1,000건/요청 |
| **데이터 범위** | 제품명, 제조사, 제조번호, 외관, 섭취방법, 섭취량, 유통기한 |
| **데이터 기간** | 2001~현재 |
| **갱신 빈도** | 비정기 (신규 등록 시) |
| **신뢰도** | 높음 (정부 공식) |
| **파싱 난이도** | 낮음 (구조화 JSON) |
| **연결 엔티티** | products, product_ingredients |
| **robots/이용약관** | 공공데이터 이용약관 준수 |

### 2.2 공공데이터포털 — 기능성 원료 인정 현황

| 항목 | 내용 |
|------|------|
| **소스명** | 건강기능식품 기능성 원료 인정 현황 |
| **URL** | https://www.data.go.kr/data/15058359/openapi.do |
| **접근 전략** | `api` |
| **인증** | API Key (위와 동일) |
| **Rate Limit** | 개발: 1,000건/일 |
| **데이터 범위** | 인정번호, 일일섭취량 상하한, 원료명, 주의사항, 기능성 내용 |
| **갱신 빈도** | 인정 변경 시 |
| **신뢰도** | 높음 |
| **파싱 난이도** | 낮음 |
| **연결 엔티티** | ingredients, claims, ingredient_claims, safety_items |

### 2.3 식품안전나라

| 항목 | 내용 |
|------|------|
| **소스명** | 식품안전나라 API |
| **URL** | https://www.foodsafetykorea.go.kr/api/main.do |
| **접근 전략** | `api` |
| **인증** | API Key (무료) |
| **Rate Limit** | 30건/분 |
| **데이터 범위** | 제품 정보, 영양성분 DB, 기능별 분류 |
| **갱신 빈도** | 비정기 |
| **신뢰도** | 높음 |
| **파싱 난이도** | 낮음 |
| **연결 엔티티** | ingredients, products, dosage_guidelines |

### 2.4 MFDS 고시/가이드

| 항목 | 내용 |
|------|------|
| **소스명** | MFDS (식품의약품안전처) 고시/가이드/재평가 공시 |
| **URL** | https://www.mfds.go.kr/, https://data.mfds.go.kr/ |
| **접근 전략** | `hybrid` (목록: data.mfds.go.kr API, 상세/PDF: browser_agent) |
| **인증** | 포털 가입 (구조화 데이터는 data.go.kr API Key) |
| **Rate Limit** | 10,000건/일 (data.mfds.go.kr) |
| **데이터 범위** | 규제 고시, 인정 기준, 재평가 결과, 문구 변경 이력, 가이드라인 PDF |
| **갱신 빈도** | 비정기 (규제 변경 시) |
| **신뢰도** | 최고 (규제기관 공식) |
| **파싱 난이도** | **높음** (PDF 파싱 필요, 비정형 문서) |
| **연결 엔티티** | regulatory_statuses, claims, safety_items |
| **robots/이용약관** | 공공 정보, 브라우저 접근 시 적절한 간격 유지 |

---

## 3. US 소스 상세

### 3.1 PubMed E-utilities

| 항목 | 내용 |
|------|------|
| **소스명** | PubMed / NCBI E-utilities |
| **URL** | https://eutils.ncbi.nlm.nih.gov/entrez/eutils/ |
| **Docs** | https://www.ncbi.nlm.nih.gov/books/NBK25497/ |
| **접근 전략** | `api` |
| **인증** | API Key (NCBI 계정에서 발급, 권장) |
| **Rate Limit** | API Key 없음: 3건/초, API Key 있음: 10건/초 |
| **데이터 범위** | 3,000만+ 논문 인용, 초록, MeSH 용어, PMC 전문 링크 |
| **갱신 빈도** | 일간 (신규 논문 지속 추가) |
| **신뢰도** | 최고 (학술 DB 표준) |
| **파싱 난이도** | 낮음 (XML/JSON 구조화) |
| **연결 엔티티** | evidence_studies, evidence_outcomes |
| **검색 전략** | 원료별 MeSH term + supplement keyword 조합 |

### 3.2 NIH DSLD (Dietary Supplement Label Database)

| 항목 | 내용 |
|------|------|
| **소스명** | NIH Office of Dietary Supplements / DSLD |
| **URL** | https://dsld.od.nih.gov/ |
| **API** | https://api.ods.od.nih.gov/dsld/v9/ |
| **Docs** | https://dsld.od.nih.gov/api-guide |
| **접근 전략** | `api` |
| **인증** | **불필요** (공개 API) |
| **Rate Limit** | 명시 없음 (합리적 사용) |
| **데이터 범위** | 200,000+ 보충제 라벨, 성분 정보, 함량, %DV, 제조사, 경고문, 건강 주장 |
| **갱신 빈도** | 비정기 |
| **신뢰도** | 높음 (NIH 공식) |
| **파싱 난이도** | 낮음 (JSON API) |
| **연결 엔티티** | products, product_ingredients, label_snapshots, claims |

### 3.3 DailyMed

| 항목 | 내용 |
|------|------|
| **소스명** | DailyMed (NLM) |
| **URL** | https://dailymed.nlm.nih.gov/ |
| **API** | https://dailymed.nlm.nih.gov/dailymed/services/v2/spls.json |
| **Docs** | https://dailymed.nlm.nih.gov/dailymed/webservices-help/v2/spls_api.cfm |
| **접근 전략** | `api` |
| **인증** | **불필요** (공개 API) |
| **Rate Limit** | 명시 없음 |
| **데이터 범위** | 140,000+ 제품 라벨 (의약품 + 보충제), SPL XML, NDC, 성분, 경고, 용법 |
| **갱신 빈도** | 지속 |
| **신뢰도** | 높음 (NLM/FDA 공식) |
| **파싱 난이도** | 중간 (SPL XML 구조 이해 필요) |
| **연결 엔티티** | products, safety_items, ingredient_drug_interactions |

### 3.4 openFDA (Adverse Event)

| 항목 | 내용 |
|------|------|
| **소스명** | openFDA Food Adverse Event API |
| **URL** | https://open.fda.gov/apis/food/event/ |
| **접근 전략** | `api` |
| **인증** | API Key (무료, 등록 필요) |
| **Rate Limit** | API Key 없음: 240건/분, 1,000건/일. API Key 있음: 240건/분, 120,000건/일 |
| **데이터 범위** | 식품/보충제 이상사례 보고 (CAERS), 증상, 결과, 제품 정보, 보고자 정보 |
| **갱신 빈도** | 분기별 |
| **신뢰도** | 중간 (자발보고, 인과관계 미확정 — **3층 신호로만 사용**) |
| **파싱 난이도** | 낮음 (JSON API) |
| **연결 엔티티** | safety_items (evidence_level = 'spontaneous_report') |
| **주의** | 보고 건수 ≠ 발생 빈도. 신호 탐지용으로만 사용 |

### 3.5 USDA FoodData Central

| 항목 | 내용 |
|------|------|
| **소스명** | USDA FoodData Central |
| **URL** | https://fdc.nal.usda.gov/ |
| **API** | https://api.nal.usda.gov/fdc/v1/ |
| **Docs** | https://fdc.nal.usda.gov/api-guide/ |
| **접근 전략** | `api` |
| **인증** | API Key (data.gov, 무료) |
| **Rate Limit** | 1,000건/시간 |
| **데이터 범위** | 영양성분 DB (비타민, 미네랄, 생리활성물질), 브랜드 제품, 서빙 사이즈 |
| **갱신 빈도** | 연 1~2회 |
| **신뢰도** | 높음 (USDA 공식) |
| **파싱 난이도** | 낮음 (JSON API) |
| **연결 엔티티** | ingredients (영양성분 보충), dosage_guidelines |

---

## 4. 제품 라벨 수집 (브라우저 에이전트)

### 4.1 KR 제품 라벨 소스 후보

| 소스 | 접근 | 데이터 | 파싱 난이도 | 비고 |
|------|------|--------|-------------|------|
| 네이버 쇼핑 제품 상세 | browser_agent | 성분표, 주의사항 | 중간 | robots.txt 확인 필요 |
| 쿠팡 제품 상세 | browser_agent | 성분표, 라벨 이미지 | 중간 | 이용약관 엄격 |
| iHerb 한국어 페이지 | browser_agent | 성분표, 제품 설명 | 낮음 | 구조화 잘 되어 있음 |
| 제조사 공식 사이트 | browser_agent | 상세 성분, 인증 정보 | 높음 (사이트마다 다름) | 소수만 |

### 4.2 US 제품 라벨 소스 후보

| 소스 | 접근 | 데이터 | 파싱 난이도 | 비고 |
|------|------|--------|-------------|------|
| **DSLD API** | api | 라벨 전체 (200K+) | 낮음 | **1순위 — API로 라벨 확보** |
| iHerb | browser_agent | 성분표, Supplement Facts | 낮음 | 구조화 잘 되어 있음 |
| Amazon 제품 상세 | browser_agent | Supplement Facts 이미지 | 높음 (OCR 필요) | 이용약관 엄격 |

> **권장**: US 제품 라벨은 DSLD API로 먼저 확보. KR 제품 라벨은 iHerb 한국어 + 공공데이터포털 조합.

---

## 5. API Key 발급 체크리스트

Phase 1 시작 전 미리 발급해야 할 API Key:

| # | 소스 | 발급 URL | 예상 소요 |
|---|------|----------|-----------|
| 1 | 공공데이터포털 | https://www.data.go.kr | 2~3일 (승인) |
| 2 | 식품안전나라 | https://www.foodsafetykorea.go.kr/apiMain.do | 즉시~1일 |
| 3 | PubMed (NCBI) | NCBI 계정 설정 | 즉시 |
| 4 | openFDA | https://open.fda.gov/ | 즉시 |
| 5 | USDA FDC | https://fdc.nal.usda.gov/api-key-signup/ | 즉시 |

> DSLD, DailyMed은 인증 불필요

---

## 6. 수집 우선순위 (Phase별)

### Phase 1 (MVP) — 핵심 4개 소스
1. **공공데이터포털** (KR 기능성 원료 + 제품 정보) → ingredients, claims, products
2. **PubMed** (논문 근거) → evidence_studies, evidence_outcomes
3. **NIH DSLD** (US 라벨 데이터) → products, label_snapshots, product_ingredients
4. **식품안전나라** (KR 제품 보충) → products, dosage_guidelines

### Phase 1.5 — 라벨+규제 보강
5. **DailyMed** (US 구조화 라벨) → safety_items, ingredient_drug_interactions
6. **MFDS 고시/가이드** (KR 규제 문서) → regulatory_statuses, claims
7. **제품 사이트 브라우저 에이전트** (KR 라벨) → label_snapshots

### Phase 2 — 안전성+영양 확장
8. **openFDA** (이상사례) → safety_items (3층 신호)
9. **USDA FDC** (영양성분) → ingredients 보충

---

## 7. source_connectors 시드 데이터

```sql
-- Phase 1 커넥터
INSERT INTO source_connectors (source_id, connector_name, source_category, base_url, access_strategy, auth_type, rate_limit_per_minute) VALUES
((SELECT id FROM sources WHERE source_name = '공공데이터포털'), '공공데이터_건강기능식품정보', 'product_catalog', 'https://apis.data.go.kr/1471000/HtfsInfoService', 'api', 'api_key', 16),
((SELECT id FROM sources WHERE source_name = '공공데이터포털'), '공공데이터_기능성원료인정', 'regulator', 'https://apis.data.go.kr/1471000/HtfsFncltyInformationService', 'api', 'api_key', 16),
((SELECT id FROM sources WHERE source_name = 'PubMed'), 'PubMed_E-utilities', 'literature', 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/', 'api', 'api_key', 600),
((SELECT id FROM sources WHERE source_name = 'NIH ODS / DSLD'), 'DSLD_API_v9', 'label_db', 'https://api.ods.od.nih.gov/dsld/v9/', 'api', 'none', 60),
((SELECT id FROM sources WHERE source_name = '식품안전나라'), '식품안전나라_API', 'product_catalog', 'https://www.foodsafetykorea.go.kr/api/', 'api', 'api_key', 30);

-- Phase 1.5 커넥터
INSERT INTO source_connectors (source_id, connector_name, source_category, base_url, access_strategy, auth_type, rate_limit_per_minute) VALUES
((SELECT id FROM sources WHERE source_name = 'DailyMed'), 'DailyMed_SPL_API', 'label_db', 'https://dailymed.nlm.nih.gov/dailymed/services/v2/', 'api', 'none', 60),
((SELECT id FROM sources WHERE source_name = 'MFDS 고시/가이드'), 'MFDS_규제문서', 'regulator', 'https://www.mfds.go.kr/', 'hybrid', 'none', 10);

-- Phase 2 커넥터
INSERT INTO source_connectors (source_id, connector_name, source_category, base_url, access_strategy, auth_type, rate_limit_per_minute) VALUES
((SELECT id FROM sources WHERE source_name = 'openFDA'), 'openFDA_FoodEvent', 'safety_db', 'https://api.fda.gov/food/event.json', 'api', 'api_key', 240),
((SELECT id FROM sources WHERE source_name = 'USDA FoodData Central'), 'USDA_FDC_API', 'product_catalog', 'https://api.nal.usda.gov/fdc/v1/', 'api', 'api_key', 16);
```
