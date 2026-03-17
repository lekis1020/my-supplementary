# 데이터 수집 계획서

> Version: 1.0.0
> 작성일: 2026-03-13
> 기준: PLAN.md (Phase 1 MVP-Core), source-catalog.md, canonical-dictionary.md

---

## 0. 현황 진단

### 시드 데이터 현재 상태

| 테이블 | 현재 건수 | MVP 목표 | 갭 | 비고 |
|--------|-----------|----------|-----|------|
| `ingredients` | 20종 | 20종 | **5종 불일치** | 아래 상세 |
| `ingredient_synonyms` | 0 | 200+ | **전무** | 표준화의 핵심 |
| `claims` | 18 | 20~25 | 2~7 | 체지방 감소, 운동수행능력 등 누락 |
| `ingredient_claims` | 25 | 60~80 | 35~55 | 누락 원료 다수 |
| `safety_items` | 10 | 60~80 | 50~70 | 6개 원료만 존재 |
| `dosage_guidelines` | 12 | 40~50 | 28~38 | 절반 이상 원료 누락 |
| `products` | 10 | 30~50 | **20~40** | KR 5 + US 5만 존재 |
| `product_ingredients` | ~30 | 100~200 | 70~170 | 제품 부족에 연동 |
| `label_snapshots` | 4 | 30~50 | **26~46** | 4개 제품만 라벨 존재 |
| `evidence_studies` | 0 | 40~100 | **전무** | Phase 1.5이지만 시드 필요 |
| `evidence_outcomes` | 0 | 80~200 | **전무** | 위와 동일 |
| `ingredient_drug_interactions` | 0 | 30~50 | **전무** | safety_items에 일부만 |
| `regulatory_statuses` | 0 | 20~40 | **전무** | KR+US 규제 상태 |
| `sources` | 7 | 10 | 3 | MFDS, USDA FDC 등 추가 |

### 원료 불일치 상세

PLAN.md에 명시된 MVP 20종과 현재 시드 데이터가 다름:

| PLAN.md에 있지만 시드에 없는 원료 | 시드에 있지만 PLAN.md에 없는 원료 |
|-----------------------------------|-----------------------------------|
| 홍삼 (Red Ginseng) | 비타민 C (Vitamin C) |
| MSM | 셀레늄 (Selenium) |
| 가르시니아 (Garcinia) | 비타민 A (Vitamin A) |
| 콜라겐 (Collagen) | 비타민 E (Vitamin E) |
| 크레아틴 (Creatine) | 커큐민 (Curcumin) |

> **결정 필요**: 시드 기준 25종으로 확장할지, PLAN.md 기준 20종으로 교체할지

---

## 1. 수집 단계 총괄

```
┌─────────────────────────────────────────────────────────────────────┐
│ Step 0: 원료 목록 확정 + 불일치 해소               (즉시, 수동)     │
├─────────────────────────────────────────────────────────────────────┤
│ Step 1: 원료 기반 데이터 보강                      (1주차)          │
│   1-A  동의어 사전 (ingredient_synonyms)                            │
│   1-B  기능성 연결 보강 (claims + ingredient_claims)                │
│   1-C  안전성 보강 (safety_items)                                   │
│   1-D  용량 가이드라인 보강 (dosage_guidelines)                     │
│   1-E  약물 상호작용 (ingredient_drug_interactions)                 │
│   1-F  규제 상태 (regulatory_statuses)                              │
├─────────────────────────────────────────────────────────────────────┤
│ Step 2: 제품 데이터 확보                           (2주차)          │
│   2-A  KR 제품 20~25개 추가                                        │
│   2-B  US 제품 10~15개 추가                                        │
│   2-C  제품-원료 연결 (product_ingredients)                         │
│   2-D  라벨 스냅샷 (label_snapshots)                                │
├─────────────────────────────────────────────────────────────────────┤
│ Step 3: 논문 근거 시드                             (2~3주차)        │
│   3-A  핵심 논문 40~100건 수집 (evidence_studies)                   │
│   3-B  결과지표 연결 (evidence_outcomes)                            │
├─────────────────────────────────────────────────────────────────────┤
│ Step 4: 출처 + 검색 인덱스 정비                    (3주차)          │
│   4-A  sources 테이블 보강                                          │
│   4-B  source_links 연결                                            │
│   4-C  ingredient_search_documents 생성                             │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 2. Step 0 — 원료 목록 확정 (즉시)

### 의사결정 필요

| 옵션 | 설명 | 장점 | 단점 |
|------|------|------|------|
| **A) 25종 확장** | PLAN.md 5종 + 시드 고유 5종 모두 포함 | 데이터 손실 없음, 커버리지 넓음 | 수집 작업량 25% 증가 |
| **B) PLAN.md 20종 유지** | 시드 고유 5종 제거, PLAN.md 5종 추가 | 원래 계획대로 | 기존 시드 데이터 폐기 |
| **C) 20종 교체** | 시드 고유 5종 → PLAN.md 5종으로 대체 | 일관성 | 비타민C 등 필수 원료 빠짐 |

> **권장: 옵션 A (25종 확장)** — 비타민 C, 셀레늄, 비타민 A, 비타민 E, 커큐민 모두 중요 원료이므로 제외 근거가 약함. PLAN.md의 홍삼, MSM, 가르시니아, 콜라겐, 크레아틴도 한국 시장에서 인기 원료.

### 추가 필요 원료 (PLAN.md 기준 누락분)

```sql
-- Step 0: PLAN.md 누락 원료 5종 추가
INSERT INTO ingredients (canonical_name_ko, canonical_name_en, display_name, scientific_name, slug, ingredient_type, description, origin_type, form_description, standardization_info, is_active, is_published) VALUES
('홍삼',     'Red Ginseng',       '홍삼',     'Panax ginseng',        'red-ginseng',      'herbal',     '고려인삼을 증숙·건조한 것. 진세노사이드가 주요 활성 성분.', 'natural', '홍삼 추출물, 농축액', 'Rg1+Rb1+Rg3 합계 기준', true, true),
('MSM',      'MSM',               'MSM',      'Methylsulfonylmethane','msm',              'other',      '유기 황 화합물. 관절 건강, 항염에 사용.',                    'synthetic', NULL, NULL, true, true),
('가르시니아','Garcinia Cambogia', '가르시니아','Garcinia cambogia',    'garcinia',         'herbal',     'HCA(히드록시시트르산) 함유. 체지방 감소에 사용.',            'natural', '가르시니아 캄보지아 추출물', 'HCA 60% 표준화', true, true),
('콜라겐',   'Collagen',          '콜라겐',   'Collagen',             'collagen',         'other',      '결합조직 구성 단백질. 피부, 관절, 뼈 건강에 관여.',          'natural', '어류콜라겐, 소콜라겐, 가수분해', 'I형/II형/III형', true, true),
('크레아틴', 'Creatine',          '크레아틴', 'Creatine',             'creatine',         'amino_acid', '근육 에너지 대사에 관여. 운동 수행능력 향상에 사용.',         'synthetic', '크레아틴 모노하이드레이트', NULL, true, true);
```

---

## 3. Step 1 — 원료 기반 데이터 보강 (1주차)

### 1-A. 동의어 사전 (`ingredient_synonyms`)

**현황**: 0건 → **목표**: 200건 이상 (원료당 평균 8~10개)

**수집 방식**: 수동 + canonical-dictionary.md 기반

**수집 항목 (동의어 유형별)**:

| synonym_type | 예시 | 수집 소스 |
|-------------|------|-----------|
| `korean` | 비타민디, 비타민D3 | 국내 라벨, 네이버 건강 |
| `english` | Vit D, Cholecalciferol | DSLD, DailyMed |
| `scientific` | Cholecalciferol, Ergocalciferol | PubMed MeSH |
| `brand` | 콜레칼시페롤 | 제품 라벨 |
| `chinese` | 维生素D | (Phase 2 이후) |
| `abbreviation` | CoQ10, EPA, DHA | 공통 약어 |

**우선순위**: 전 원료 한글·영문·학명 동의어 먼저, 브랜드/약어는 제품 수집 시 병행

**작업 방법**:
1. canonical-dictionary.md의 동의어 컬럼 → SQL INSERT 변환
2. 원료별 최소 5개 동의어 확보
3. 프로바이오틱스는 균주명까지 (Lactobacillus rhamnosus GG 등)

---

### 1-B. 기능성 연결 보강 (`claims` + `ingredient_claims`)

**현황**: claims 18건 / 연결 25건

**추가 필요 claims**:

| claim_code | claim_name_ko | claim_scope | 관련 원료 |
|-----------|---------------|-------------|-----------|
| `BODY_FAT` | 체지방 감소에 도움 | approved_kr | 가르시니아 |
| `EXERCISE_PERF` | 운동 수행능력 향상 | studied | 크레아틴 |
| `BLOOD_CIRCULATION` | 혈행 개선에 도움 | approved_kr | 홍삼 |
| `FATIGUE` | 피로 개선에 도움 | approved_kr | 홍삼 |
| `MEMORY` | 기억력 개선에 도움 | approved_kr | 홍삼 |
| `CALCIUM_ABSORPTION` | 칼슘 흡수 촉진 | approved_kr | 비타민 D |
| `BLOOD_PRESSURE` | 혈압 조절에 도움 | studied | 마그네슘, 오메가-3 |

**추가 필요 ingredient_claims 연결** (누락 조합):

| 원료 | 기능성 | 근거등급 | 승인여부 |
|------|--------|----------|----------|
| 홍삼 | 면역 기능 | A | approved_kr |
| 홍삼 | 혈행 개선 | A | approved_kr |
| 홍삼 | 피로 개선 | A | approved_kr |
| 홍삼 | 기억력 개선 | B | approved_kr |
| 가르시니아 | 체지방 감소 | B | approved_kr |
| 크레아틴 | 운동 수행능력 | A | studied |
| 콜라겐 | 피부 건강 | B | approved_kr |
| 콜라겐 | 관절 건강 | C | studied |
| MSM | 관절 건강 | B | approved_kr |
| 비타민 C | 에너지 대사 | A | approved_kr |
| 비타민 A | 피부 건강 | B | approved_kr |
| 비타민 E | 피부 건강 | B | studied |
| 커큐민 | 항산화 | B | studied |
| 코엔자임Q10 | 에너지 대사 | B | studied |
| 마그네슘 | 혈압 조절 | B | studied |
| 오메가-3 | 혈압 조절 | B | studied |

**수집 소스**:
- 1순위: 식약처 건강기능식품 기능성 정보 (공공데이터포털 API)
- 2순위: canonical-dictionary.md 기존 정리 내용
- 3순위: NIH ODS Fact Sheets (US 기준 보충)

---

### 1-C. 안전성 보강 (`safety_items`)

**현황**: 10건 (6개 원료만) → **목표**: 60~80건 (전 원료 커버)

**누락 원료별 필수 안전성 항목**:

| 원료 | safety_type | 항목 | severity |
|------|-------------|------|----------|
| 비타민 C | overdose | 고용량 시 소화기 장애, 신장 결석 위험 | mild~moderate |
| 비타민 B12 | precaution | 일반적으로 안전, 고용량 주의 | mild |
| 칼슘 | drug_interaction | 항생제/갑상선약 흡수 방해 | moderate |
| 칼슘 | overdose | 고칼슘혈증, 심혈관 위험 논란 | serious |
| 프로바이오틱스 | precaution | 면역저하자 주의 | moderate |
| 루테인 | precaution | 카로테노더미아 (과다 시 피부 황변) | mild |
| 코엔자임Q10 | drug_interaction | 와파린 효과 감소 가능 | serious |
| 밀크씨슬 | adverse_effect | 소화기 장애 (구역, 설사) | mild |
| 글루코사민 | precaution | 갑각류 알레르기 주의 | serious |
| 글루코사민 | drug_interaction | 와파린과 상호작용 | moderate |
| 비오틴 | precaution | 갑상선 검사 결과 왜곡 | moderate |
| 셀레늄 | overdose | 셀레노시스 (만성 중독) | serious |
| 비타민 A | overdose | 간독성 (고용량 장기 복용) | serious |
| 비타민 E | drug_interaction | 항응고제 출혈 위험 증가 | serious |
| 비타민 E | overdose | 고용량 시 사망률 증가 논란 | serious |
| 커큐민 | drug_interaction | 항응고제 상호작용 | moderate |
| 홍삼 | drug_interaction | 와파린, 당뇨약, 혈압약 상호작용 | serious |
| 홍삼 | precaution | 고혈압 환자 주의 | moderate |
| 가르시니아 | adverse_effect | 간독성 보고 (드묾) | serious |
| 가르시니아 | precaution | 당뇨약 병용 주의 | moderate |
| 콜라겐 | adverse_effect | 소화기 불편감, 알레르기 반응 | mild |
| 크레아틴 | adverse_effect | 수분 저류, 체중 증가 | mild |
| 크레아틴 | precaution | 신장 질환자 주의 | moderate |
| MSM | adverse_effect | 소화기 불편감 (드묾) | mild |
| 멜라토닌 | drug_interaction | 혈압약, 당뇨약, 면역억제제 상호작용 | moderate |
| 멜라토닌 | population_warning | 임산부, 수유부, 소아 금기 | serious |

**수집 소스**:
- 1순위: 식약처 건강기능식품 주의사항 / 제품 라벨 경고문
- 2순위: NIH ODS Fact Sheets
- 3순위: DailyMed safety sections
- 4순위: 교과서/가이드라인 (수동 입력)

---

### 1-D. 용량 가이드라인 보강 (`dosage_guidelines`)

**현황**: 12건 → **목표**: 40~50건

**추가 필요 항목**:

| 원료 | 인구집단 | dose_min~max | unit | recommendation_type |
|------|----------|-------------|------|---------------------|
| 비타민 B12 | 성인 | 2.4~1000 | mcg | RDA |
| 비오틴 | 성인 | 30~100 | mcg | AI |
| 셀레늄 | 성인 | 55~200 | mcg | RDA |
| 비타민 A | 성인 남성 | 750~900 | mcg RAE | RDA |
| 비타민 A | 성인 여성 | 650~700 | mcg RAE | RDA |
| 비타민 E | 성인 | 15~400 | mg | RDA |
| 커큐민 | 성인 | 500~2000 | mg | AI |
| 코엔자임Q10 | 성인 | 100~300 | mg | AI |
| 밀크씨슬 | 성인 | 140~420 | mg silymarin | AI |
| 글루코사민 | 성인 | 1500~1500 | mg | AI |
| MSM | 성인 | 1500~3000 | mg | AI |
| 홍삼 | 성인 | 3~6 | g (원생약 기준) | AI |
| 가르시니아 | 성인 | 750~1500 | mg HCA | AI |
| 콜라겐 | 성인 | 2500~10000 | mg | AI |
| 크레아틴 | 성인 | 3000~5000 | mg | AI |
| 멜라토닌 | 성인 | 0.5~5 | mg | AI |
| 칼슘 | 65세 이상 | 800~1200 | mg | RDA |
| 비타민 D | 임산부 | 600~4000 | IU | RDA |
| 엽산 | 성인 여성 (비임신) | 400~400 | mcg DFE | RDA |

**수집 소스**:
- 1순위: 한국인 영양소 섭취기준 (보건복지부)
- 2순위: NIH ODS Recommended Intakes
- 3순위: 식약처 건강기능식품 일일섭취량 기준

---

### 1-E. 약물 상호작용 (`ingredient_drug_interactions`)

**현황**: 0건 → **목표**: 30~50건

현재 `safety_items`에 `drug_interaction` 타입으로 일부 들어가 있으나, 전용 테이블에 구조화된 데이터 필요.

**우선순위 상호작용** (빈도·심각도 기준):

| 원료 | 약물군 | 상호작용 | 심각도 |
|------|--------|----------|--------|
| 오메가-3 | 항응고제 (와파린) | 출혈 위험 증가 | serious |
| 비타민 K | 항응고제 (와파린) | 약효 감소 | serious |
| 비타민 D | 티아지드 이뇨제 | 고칼슘혈증 | moderate |
| 칼슘 | 테트라사이클린 항생제 | 항생제 흡수 감소 | moderate |
| 칼슘 | 레보티록신 (갑상선약) | 갑상선약 흡수 감소 | moderate |
| 철분 | 레보티록신 | 갑상선약 흡수 감소 | moderate |
| 철분 | ACE 억제제 | 철분 흡수 변화 | mild |
| 마그네슘 | 비스포스포네이트 | 약물 흡수 감소 | moderate |
| 코엔자임Q10 | 와파린 | 항응고 효과 감소 | serious |
| 비타민 E | 항응고제 | 출혈 위험 증가 | serious |
| 홍삼 | 와파린 | INR 변동 | serious |
| 홍삼 | 인슐린/당뇨약 | 저혈당 위험 | moderate |
| 커큐민 | 항응고제 | 출혈 위험 증가 | moderate |
| 밀크씨슬 | CYP3A4 기질 약물 | 약물 대사 변화 | moderate |
| 멜라토닌 | 면역억제제 | 면역 자극 가능 | moderate |
| 멜라토닌 | 항경련제 | CNS 억제 증가 | moderate |
| 가르시니아 | 당뇨약 | 저혈당 위험 | moderate |
| 글루코사민 | 와파린 | INR 증가 보고 | moderate |
| 프로바이오틱스 | 면역억제제 | 감염 위험 (이론적) | moderate |

**수집 소스**:
- 1순위: DailyMed drug interaction sections
- 2순위: NIH ODS Fact Sheets
- 3순위: Lexicomp / Micromedex (라이선스 확인 필요)
- 4순위: 개별 논문/리뷰 (수동)

---

### 1-F. 규제 상태 (`regulatory_statuses`)

**현황**: 0건 → **목표**: 20~40건 (원료당 KR+US 각 1건)

**수집 항목**:

| 원료 | 국가 | 규제 분류 | 상태 |
|------|------|-----------|------|
| 비타민류 (8종) | KR | 건강기능식품 원료 (고시형) | 허용 |
| 미네랄류 (5종) | KR | 건강기능식품 원료 (고시형) | 허용 |
| 오메가-3 | KR | 건강기능식품 원료 (고시형) | 허용 |
| 프로바이오틱스 | KR | 건강기능식품 원료 (고시형) | 허용 |
| 홍삼 | KR | 건강기능식품 원료 (고시형) | 허용 |
| 가르시니아 | KR | 건강기능식품 원료 (고시형) | 허용 |
| 멜라토닌 | KR | **전문의약품** | 보충제로 판매 불가 |
| 크레아틴 | KR | 일반식품 원료 | 건기식 아님 |
| 전 원료 | US | Dietary Supplement | 허용 (DSHEA) |

**수집 소스**:
- 1순위: MFDS 건강기능식품 고시형 원료 목록
- 2순위: 공공데이터포털 기능성 원료 인정 현황 API
- 3순위: FDA DSHEA 분류 (US 측)

---

## 4. Step 2 — 제품 데이터 확보 (2주차)

### 2-A. KR 제품 추가 (20~25개)

**수집 기준**:
- 20종(또는 25종) 원료 중심 단일성분 제품 우선
- 국내 판매량/인지도 상위 브랜드
- 복합제 소수 포함 (멀티비타민 2~3개)

**KR 제품 후보 리스트**:

| # | 제품명 (예시) | 브랜드 | 원료 | 수집 소스 |
|---|-------------|--------|------|-----------|
| 1 | 정관장 홍삼정 에브리타임 | 정관장 | 홍삼 | 제조사 사이트 |
| 2 | 종근당 비타민D 1000IU | 종근당건강 | 비타민 D | 공공데이터포털 |
| 3 | 종근당 아이클리어 루테인 | 종근당건강 | 루테인 | 공공데이터포털 |
| 4 | 고려은단 비타민C 1000 | 고려은단 | 비타민 C | 공공데이터포털 |
| 5 | 뉴트리코어 철분 | 뉴트리코어 | 철분 | 공공데이터포털 |
| 6 | 대웅제약 에너씨슬 밀크씨슬 | 대웅제약 | 밀크씨슬 | 공공데이터포털 |
| 7 | 일양약품 프로바이오틱스 | 일양약품 | 프로바이오틱스 | 공공데이터포털 |
| 8 | 쎌바이오텍 듀오락 골드 | 쎌바이오텍 | 프로바이오틱스 | 공공데이터포털 |
| 9 | 뉴트리원 비타민B 콤플렉스 | 뉴트리원 | B12+엽산+비오틴 | 공공데이터포털 |
| 10 | 종근당 오메가3 | 종근당건강 | 오메가-3 | 공공데이터포털 |
| 11 | GNM자연의품격 칼슘마그네슘 | GNM | 칼슘+마그네슘 | 공공데이터포털 |
| 12 | 뉴트리디데이 비타민A | 뉴트리디데이 | 비타민 A | 공공데이터포털 |
| 13 | 나우푸드 코큐텐 100mg | NOW Foods | CoQ10 | iHerb 한국어 |
| 14 | 얼라이브 종합비타민 | Nature's Way | 멀티 | iHerb 한국어 |
| 15 | 닥터스베스트 글루코사민 | Doctor's Best | 글루코사민+MSM | iHerb 한국어 |
| 16 | 뉴트리코어 콜라겐 | 뉴트리코어 | 콜라겐 | 공공데이터포털 |
| 17 | 머슬팜 크레아틴 | MuscleTech | 크레아틴 | iHerb 한국어 |
| 18 | 뉴트리디데이 가르시니아 | 뉴트리디데이 | 가르시니아 | 공공데이터포털 |
| 19 | 대상웰라이프 비타민E | 세노비스 | 비타민 E | 공공데이터포털 |
| 20 | 솔가 셀레늄 200mcg | Solgar | 셀레늄 | iHerb 한국어 |

**수집 방법**:
1. **공공데이터포털 API** → 제품명/제조사/기본정보 (1순위, 구조화)
2. **식품안전나라 API** → 보충 정보 (2순위)
3. **iHerb 한국어 페이지** → US 제품 한국 유통분 (browser_agent, Phase 1.5)

### 2-B. US 제품 추가 (10~15개)

**수집 소스**: NIH DSLD API (1순위, 인증 불필요)

| # | 제품명 (예시) | 브랜드 | 원료 |
|---|-------------|--------|------|
| 1 | Vitamin D3 5000 IU | NOW Foods | 비타민 D |
| 2 | Calcium Citrate + D3 | Citracal | 칼슘+비타민 D |
| 3 | Magnesium Glycinate 400mg | Doctor's Best | 마그네슘 |
| 4 | Zinc Picolinate 50mg | Thorne | 아연 |
| 5 | Iron Bisglycinate 25mg | Thorne | 철분 |
| 6 | Folate 1000mcg | Jarrow Formulas | 엽산 |
| 7 | Super B-Complex | Nature Made | B12+엽산+비오틴 |
| 8 | Milk Thistle 150mg | Nature's Bounty | 밀크씨슬 |
| 9 | Glucosamine & MSM | Schiff | 글루코사민+MSM |
| 10 | CoQ10 200mg | Qunol | CoQ10 |
| 11 | Collagen Peptides | Vital Proteins | 콜라겐 |
| 12 | Creatine Monohydrate | Optimum Nutrition | 크레아틴 |
| 13 | Turmeric Curcumin | Nature Made | 커큐민 |
| 14 | Culturelle Probiotics | Culturelle | 프로바이오틱스 |
| 15 | Korean Red Ginseng | CheongKwanJang | 홍삼 |

**수집 방법**:
1. **DSLD API** (`/products?ingredient=...`) → 라벨 포함 전체 데이터
2. 제품 선정 후 `product_ingredients`, `label_snapshots` 동시 적재

### 2-C. 제품-원료 연결 (`product_ingredients`)

- 각 제품의 Supplement Facts / 영양·기능 정보 기준
- `raw_label_name` 반드시 보존 (원문 그대로)
- `amount_per_serving`, `amount_unit` 표준화 적용

### 2-D. 라벨 스냅샷 (`label_snapshots`)

**전 제품 최소 1건의 라벨 스냅샷 확보 목표**

수집 항목:
- `serving_size_text`: 1회 섭취량
- `servings_per_container`: 총 내용량
- `warning_text`: 주의사항 전문
- `directions_text`: 섭취 방법
- `raw_label_text`: (가능 시) 라벨 전문

---

## 5. Step 3 — 논문 근거 시드 (2~3주차)

### 수집 전략

원료당 핵심 논문 2~5건, 총 40~100건 목표.

**논문 선정 기준**:
1. 메타분석/체계적 문헌고찰 우선 (근거등급 A~B)
2. 최근 5년 이내 (2021~2026)
3. 인체연구 (RCT) 우선
4. Cochrane Review, 주요 저널 우선

**원료별 PubMed 검색 쿼리 예시**:

| 원료 | 검색 쿼리 | 예상 결과 |
|------|-----------|-----------|
| 비타민 D | `"vitamin D"[MeSH] AND "meta-analysis"[pt] AND supplement` | 200+ |
| 오메가-3 | `"Fatty Acids, Omega-3"[MeSH] AND "meta-analysis"[pt]` | 300+ |
| 프로바이오틱스 | `"Probiotics"[MeSH] AND "meta-analysis"[pt] AND "gut"` | 100+ |
| 홍삼 | `"Panax"[MeSH] AND "randomized controlled trial"[pt]` | 50+ |
| 커큐민 | `"Curcumin"[MeSH] AND "meta-analysis"[pt]` | 80+ |

**수집 방법**:
1. PubMed E-utilities API (`esearch` + `efetch`)
2. 원료별 MeSH term으로 검색
3. 상위 2~5건 선별 → `evidence_studies` INSERT
4. 각 논문에서 주요 결과지표 추출 → `evidence_outcomes` INSERT

**수집 필드**:
- `pmid`, `title`, `authors_json`, `journal`, `publication_year`
- `study_type` (meta_analysis, rct, observational 등)
- `abstract_text`, `full_text_url` (PMC 있는 경우)
- `screening_status`: 초기 `included`로 설정 (L2 검수 대상)

---

## 6. Step 4 — 출처 + 검색 인덱스 (3주차)

### 4-A. sources 추가

```sql
INSERT INTO sources (source_name, source_type, organization_name, source_url, country_code, trust_level, access_method) VALUES
('MFDS 고시/가이드',      'government_db', '식품의약품안전처',      'https://www.mfds.go.kr',           'KR', 'authoritative', 'hybrid'),
('USDA FoodData Central', 'government_db', 'USDA',                'https://fdc.nal.usda.gov',          'US', 'authoritative', 'api'),
('NIH ODS Fact Sheets',   'government_db', 'NIH ODS',             'https://ods.od.nih.gov',            'US', 'authoritative', 'manual');
```

### 4-B. source_links 연결

모든 데이터에 출처 연결:
- 각 `ingredient_claims` → 근거 소스 연결
- 각 `safety_items` → 출처 연결
- 각 `product` → 데이터 수집 소스 연결
- 각 `evidence_studies` → PubMed 연결

### 4-C. 검색 인덱스 (`ingredient_search_documents`)

전 원료에 대해 검색 문서 생성:
- 표준명(한/영) + 동의어 + 기능성 키워드 + 부작용 키워드 결합
- PostgreSQL GIN 인덱스로 full-text search 지원

---

## 7. 수집 소스별 작업 매핑

| 수집 소스 | 접근 방법 | 대상 테이블 | 단계 | API Key 필요 |
|-----------|-----------|-------------|------|-------------|
| 공공데이터포털 (건기식) | API | products, product_ingredients | Step 2 | O (2~3일 승인) |
| 공공데이터포털 (원료 인정) | API | ingredients, claims, ingredient_claims | Step 1 | O (위와 동일) |
| 식품안전나라 | API | products, dosage_guidelines | Step 2 | O (즉시~1일) |
| PubMed E-utilities | API | evidence_studies, evidence_outcomes | Step 3 | O (즉시) |
| NIH DSLD | API | products, label_snapshots, product_ingredients | Step 2 | X |
| NIH ODS Fact Sheets | 수동 | safety_items, dosage_guidelines, regulatory | Step 1 | X |
| canonical-dictionary.md | 수동 변환 | ingredient_synonyms | Step 1 | X |
| 교과서/가이드라인 | 수동 | safety_items, drug_interactions, dosage | Step 1 | X |

---

## 8. 일정 요약

| 주차 | 작업 | 예상 건수 | 방법 |
|------|------|-----------|------|
| **즉시** | 원료 목록 확정 (25종 확장 or 교체) | +5 ingredients | 수동 SQL |
| **1주차** | Step 1: 원료 기반 데이터 보강 | +200 synonyms, +30 claims 연결, +50 safety, +30 dosage, +30 interactions, +25 regulatory | 수동 + API |
| **2주차** | Step 2: 제품 30~40개 + 라벨 | +30 products, +100 product_ingredients, +30 label_snapshots | API + 수동 |
| **2~3주차** | Step 3: 논문 시드 | +50 studies, +100 outcomes | PubMed API |
| **3주차** | Step 4: 출처 연결 + 검색 인덱스 | +3 sources, +200 source_links, +25 search_docs | 수동 + 스크립트 |

---

## 9. API Key 발급 (선행 작업)

Step 2~3 시작 전 반드시 발급:

| # | 소스 | 발급 URL | 소요 | 용도 |
|---|------|----------|------|------|
| 1 | **공공데이터포털** | https://www.data.go.kr | **2~3일** (승인 필요) | KR 제품+원료 |
| 2 | **식품안전나라** | https://www.foodsafetykorea.go.kr/apiMain.do | 즉시~1일 | KR 제품 보충 |
| 3 | **PubMed (NCBI)** | NCBI 계정 설정 | 즉시 | 논문 검색 |

> DSLD, DailyMed은 인증 불필요. 지금 바로 사용 가능.

---

## 10. 수동 vs 자동 수집 판단

| 데이터 | Phase 1 방법 | Phase 1.5+ 방법 |
|--------|-------------|-----------------|
| 원료 마스터 | **수동** (25종 고정) | 수동 + API 보강 |
| 동의어 | **수동** (canonical-dictionary 기반) | API 추출 자동화 |
| 기능성 연결 | **수동** + 공공데이터 API | API 자동 수집 |
| 안전성 | **수동** (NIH ODS, 교과서) | DailyMed API + openFDA |
| 용량 | **수동** (한국 영양소 기준, NIH) | API 보강 |
| 약물 상호작용 | **수동** (DailyMed 참조) | DailyMed API 자동화 |
| 규제 상태 | **수동** (MFDS 확인) | MFDS API + 브라우저 |
| 제품 (KR) | **공공데이터 API** + 수동 보강 | 자동 수집 파이프라인 |
| 제품 (US) | **DSLD API** | 자동 수집 파이프라인 |
| 라벨 | **DSLD API (US)** + 수동 (KR) | 브라우저 에이전트 자동화 |
| 논문 | **PubMed API** + 수동 선별 | 자동 수집 + L2 검수 |

---

## 11. 리스크 및 대응

| 리스크 | 영향 | 대응 |
|--------|------|------|
| 공공데이터포털 API Key 승인 지연 | Step 2 KR 제품 수집 지연 | 즉시 신청, 대기 중 수동 입력 병행 |
| 식약처 기능성 데이터 불완전 | 기능성 연결 누락 | NIH ODS + canonical-dictionary로 보강 |
| KR 제품 라벨 자동 수집 불가 | 라벨 데이터 빈약 | Phase 1은 수동 입력, Phase 1.5에서 브라우저 에이전트 |
| 원료 표준명 매핑 실패 | 제품-원료 연결 오류 | 동의어 사전을 먼저 구축 (Step 1-A 최우선) |
| 논문 선별 기준 불명확 | 근거등급 신뢰도 저하 | 메타분석/체계적 문헌고찰 한정으로 시작 |

---

## 12. 체크리스트

### 즉시 (이번 주)
- [x] 원료 목록 최종 확정 → **25종 확장 (옵션 A)** (2026-03-15)
- [x] 공공데이터포털 API Key 신청 → 승인 대기 중 (키 미설정 상태, 2026-03-16 재확인)
- [x] 식품안전나라 API Key 신청 → 이전 세션에서 검증 성공 (I0030/I0760/I-0040)
- [x] PubMed API Key 발급 → 완료 (447eb2e...)

### 1주차
- [x] PLAN.md 누락 원료 5종 DB 추가 → `005_seed_supplementary.sql` (홍삼/MSM/가르시니아/콜라겐/크레아틴)
- [x] ingredient_synonyms 200건+ 적재 → `005_seed_supplementary.sql` (25종 전체)
- [x] claims 추가 (7건) + ingredient_claims 보강 (30건+) → `005_seed_supplementary.sql`
- [x] safety_items 보강 (50건+) → `005_seed_supplementary.sql`
- [x] dosage_guidelines 보강 (30건+) → `005_seed_supplementary.sql`
- [x] ingredient_drug_interactions 초기 적재 (30건+) → `005_seed_supplementary.sql`
- [x] regulatory_statuses 초기 적재 (25건+) → `005_seed_supplementary.sql`

### 2주차
- [x] KR 제품 20~25개 추가 → `008_seed_products_additional.sql` (35제품, zeaxanthin 포함 26종 원료)
- [x] US 제품 15개 추가 → `008_seed_products_additional.sql` (수동 시드, DSLD 대신)
- [x] product_ingredients 연결 (100건+) → `008_seed_products_additional.sql`
- [x] label_snapshots 30건+ 확보 → KR 4건(003) + US 15건(011) + KR 추가 확보 예정

### 2~3주차
- [x] PubMed API로 핵심 논문 50건+ 수집 → `009_seed_evidence.sql` (50 studies, 50 outcomes, 25종 전체)
- [x] evidence_outcomes 100건+ 연결 → `009_seed_evidence.sql` (50건, 추후 보강 가능)
- [x] sources 3건 추가 → `010_seed_sources_search.sql` (MFDS 고시/가이드, USDA FDC, 공공데이터포털 기능성원료인정)
- [x] source_links 전체 데이터 연결 → `010_seed_sources_search.sql` (12종 연결: 원료, 기능성, 논문, 제품, 안전성, 용량, 라벨)
- [x] ingredient_search_documents 전 원료 생성 → `010_seed_sources_search.sql` (tsvector 기반, 동의어+기능성+안전성 통합)

### 3주차 — 연구 근거 보강 (Phase 1)
- [x] 신규 claims 5종 추가 → `013_enrich_evidence.sql` (COGNITIVE_FUNCTION, BLOOD_SUGAR, MUSCLE_STRENGTH, WEIGHT_MANAGEMENT, MENTAL_HEALTH)
- [x] 누락 ingredient_claims 16건 추가 → `013_enrich_evidence.sql` (creatine, collagen, red-ginseng, MSM, garcinia, coq10 등)
- [x] evidence_outcomes ↔ claim_id 전체 매핑 (50건) → `013_enrich_evidence.sql`
- [x] 잘못된 outcome 설명 교정 (12건) → vitamin-d, vitamin-b12, omega-3, magnesium, zinc
- [x] 정량 데이터 추출 (16건) → effect_size_text, p_value_text, confidence_interval_text
- [x] evidence_studies 메타데이터 보강 (14건) → sample_size, population_text, duration_text
- [x] RUN_THIS_ONLY.sql 통합 완료
- [ ] Phase 2: 원료당 study 2→5건 확대, 나머지 34건 정량 데이터, adverse_event_summary, risk_of_bias

### 블로커
- **DSLD API**: v9 전체 엔드포인트 빈 응답 또는 HTML 반환 (2026-03-16). US 제품은 008에서 수동 시드 15건 입력 완료. 향후 DSLD 복구 시 자동 수집 전환.
- **한국 API Key**: 확보 완료 (2026-03-16). `.env.local`에 `FOODSAFETY_KOREA_API_KEY`, `DATA_GO_KR_SERVICE_KEY_DECODED` 설정 후 재테스트 필요.
