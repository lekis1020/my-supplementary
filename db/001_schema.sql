-- ============================================================================
-- 영양제·건강기능식품 비교 분석 플랫폼 — PostgreSQL DDL
-- Version: 1.0.0
-- 설계 원칙:
--   1. ingredient_id 중심 연결 (원료 중심 DB)
--   2. 국내 규제 문구와 학술 근거 분리
--   3. 모든 데이터에 출처(source)와 갱신일 연결
--   4. ENUM 대신 코드 테이블 사용 (운영 확장성)
-- ============================================================================

-- ============================================================================
-- 0. 코드 테이블 (ENUM 대체)
-- ============================================================================
-- ENUM 대신 코드 테이블을 사용하면 규칙 변경 시 migration 부담이 적다.

CREATE TABLE code_tables (
    id BIGSERIAL PRIMARY KEY,
    table_code VARCHAR(100) NOT NULL UNIQUE,
    table_name_ko VARCHAR(255) NOT NULL,
    table_name_en VARCHAR(255),
    description TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE code_tables IS '코드 테이블 마스터. ENUM 대체용.';

CREATE TABLE code_values (
    id BIGSERIAL PRIMARY KEY,
    code_table_id BIGINT NOT NULL REFERENCES code_tables(id) ON DELETE CASCADE,
    code VARCHAR(100) NOT NULL,
    label_ko VARCHAR(255) NOT NULL,
    label_en VARCHAR(255),
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),

    UNIQUE (code_table_id, code)
);

COMMENT ON TABLE code_values IS '코드 값. code_tables의 자식.';

-- 초기 코드 테이블 시드 데이터
INSERT INTO code_tables (table_code, table_name_ko, table_name_en) VALUES
    ('ingredient_type',    '원료 분류',       'Ingredient Type'),
    ('claim_category',     '기능성 카테고리', 'Claim Category'),
    ('claim_scope',        '기능성 범위',     'Claim Scope'),
    ('evidence_grade',     '근거 등급',       'Evidence Grade'),
    ('safety_type',        '안전성 유형',     'Safety Type'),
    ('severity_level',     '심각도',          'Severity Level'),
    ('evidence_level',     '근거 수준',       'Evidence Level'),
    ('study_design',       '연구 설계',       'Study Design'),
    ('effect_direction',   '효과 방향',       'Effect Direction'),
    ('risk_of_bias',       '비뚤림 위험',     'Risk of Bias'),
    ('product_type',       '제품 유형',       'Product Type'),
    ('ingredient_role',    '원료 역할',       'Ingredient Role'),
    ('origin_type',        '원료 기원',       'Origin Type'),
    ('synonym_type',       '동의어 유형',     'Synonym Type'),
    ('regulatory_category','규제 분류',       'Regulatory Category'),
    ('regulatory_status',  '규제 상태',       'Regulatory Status'),
    ('source_type',        '출처 유형',       'Source Type'),
    ('trust_level',        '신뢰 등급',       'Trust Level'),
    ('review_task_type',   '검수 유형',       'Review Task Type'),
    ('review_status',      '검수 상태',       'Review Status'),
    ('change_type',        '변경 유형',       'Change Type'),
    ('recommendation_type','권장 유형',       'Recommendation Type'),
    ('frequency_text',     '빈도 표현',       'Frequency Text'),
    ('outcome_type',       '결과지표 유형',   'Outcome Type'),
    ('screening_status',   '스크리닝 상태',   'Screening Status');

-- ingredient_type 코드 값
INSERT INTO code_values (code_table_id, code, label_ko, label_en, sort_order)
SELECT ct.id, v.code, v.label_ko, v.label_en, v.sort_order
FROM code_tables ct,
(VALUES
    ('vitamin',     '비타민',           'Vitamin',       1),
    ('mineral',     '미네랄',           'Mineral',       2),
    ('herb',        '허브/식물추출물',  'Herb/Botanical', 3),
    ('probiotic',   '프로바이오틱스',   'Probiotic',     4),
    ('fatty_acid',  '지방산',           'Fatty Acid',    5),
    ('amino_acid',  '아미노산',         'Amino Acid',    6),
    ('enzyme',      '효소/코엔자임',    'Enzyme/Coenzyme', 7),
    ('other',       '기타',             'Other',         8)
) AS v(code, label_ko, label_en, sort_order)
WHERE ct.table_code = 'ingredient_type';

-- evidence_grade 코드 값
INSERT INTO code_values (code_table_id, code, label_ko, label_en, sort_order)
SELECT ct.id, v.code, v.label_ko, v.label_en, v.sort_order
FROM code_tables ct,
(VALUES
    ('A', '다수의 고품질 메타분석/가이드라인/일관된 RCT',       'Multiple high-quality meta-analyses/guidelines/consistent RCTs', 1),
    ('B', 'RCT 존재하나 규모 제한 또는 결과 불일치',           'RCTs exist but limited size or inconsistent results',           2),
    ('C', '관찰연구 또는 소규모 인체연구 위주',                'Mainly observational or small human studies',                     3),
    ('D', '전임상/기전연구 위주',                             'Mainly preclinical/mechanistic studies',                          4),
    ('I', '근거 불충분',                                     'Insufficient evidence',                                           5)
) AS v(code, label_ko, label_en, sort_order)
WHERE ct.table_code = 'evidence_grade';

-- severity_level 코드 값
INSERT INTO code_values (code_table_id, code, label_ko, label_en, sort_order)
SELECT ct.id, v.code, v.label_ko, v.label_en, v.sort_order
FROM code_tables ct,
(VALUES
    ('mild',     '경미',   'Mild',     1),
    ('moderate', '중등도', 'Moderate', 2),
    ('severe',   '중증',   'Severe',   3),
    ('critical', '위험',   'Critical', 4)
) AS v(code, label_ko, label_en, sort_order)
WHERE ct.table_code = 'severity_level';

-- claim_scope 코드 값
INSERT INTO code_values (code_table_id, code, label_ko, label_en, sort_order)
SELECT ct.id, v.code, v.label_ko, v.label_en, v.sort_order
FROM code_tables ct,
(VALUES
    ('structure_function',         '구조/기능 기능성',                'Structure/Function',          1),
    ('general_health',             '일반 건강 관련',                  'General Health',              2),
    ('research_only',              '연구 단계 (인정 전)',             'Research Only',               3),
    ('prohibited_disease_claim',   '질병 치료/예방 표현 (금지)',      'Prohibited Disease Claim',    4)
) AS v(code, label_ko, label_en, sort_order)
WHERE ct.table_code = 'claim_scope';


-- ============================================================================
-- 1. 핵심 엔티티: 원료 (Ingredients)
-- ============================================================================

CREATE TABLE ingredients (
    id BIGSERIAL PRIMARY KEY,
    canonical_name_ko VARCHAR(255) NOT NULL,
    canonical_name_en VARCHAR(255),
    display_name VARCHAR(255),
    scientific_name VARCHAR(255),
    slug VARCHAR(255) UNIQUE,

    ingredient_type VARCHAR(50) NOT NULL,
    -- vitamin, mineral, herb, probiotic, fatty_acid, amino_acid, enzyme, other
    -- 코드 테이블 code_tables.table_code = 'ingredient_type' 참조

    parent_ingredient_id BIGINT REFERENCES ingredients(id),
    -- 상위 원료-하위 제형 구조
    -- 예: 마그네슘(부모) → magnesium citrate(자식)
    -- 예: 비타민 D(부모) → cholecalciferol / ergocalciferol(자식)

    description TEXT,

    origin_type VARCHAR(50),
    -- natural, synthetic, mixed, unknown

    form_description TEXT,
    -- 추출물, 염형, 균주 등 설명

    standardization_info TEXT,
    -- 예: 80% silymarin

    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_published BOOLEAN NOT NULL DEFAULT FALSE,
    last_reviewed_at TIMESTAMP,
    last_synced_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE ingredients IS '원료 마스터. 모든 데이터의 중심축.';
COMMENT ON COLUMN ingredients.parent_ingredient_id IS '상위 원료 ID. 예: 마그네슘(부모) → 산화마그네슘(자식)';
COMMENT ON COLUMN ingredients.slug IS 'URL용 슬러그. 예: magnesium-citrate';
COMMENT ON COLUMN ingredients.is_published IS '공개 여부. false면 관리자만 볼 수 있음.';

CREATE INDEX idx_ingredients_name_ko ON ingredients (canonical_name_ko);
CREATE INDEX idx_ingredients_name_en ON ingredients (canonical_name_en);
CREATE INDEX idx_ingredients_slug ON ingredients (slug);
CREATE INDEX idx_ingredients_parent ON ingredients (parent_ingredient_id);
CREATE INDEX idx_ingredients_type ON ingredients (ingredient_type);


-- ============================================================================
-- 2. 원료 동의어 (Ingredient Synonyms)
-- ============================================================================

CREATE TABLE ingredient_synonyms (
    id BIGSERIAL PRIMARY KEY,
    ingredient_id BIGINT NOT NULL REFERENCES ingredients(id) ON DELETE CASCADE,
    synonym VARCHAR(255) NOT NULL,
    language_code VARCHAR(10) DEFAULT 'ko',

    synonym_type VARCHAR(50) NOT NULL,
    -- common, scientific, brand_like, abbreviation, regulatory
    -- 코드 테이블 code_tables.table_code = 'synonym_type' 참조

    is_preferred BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE ingredient_synonyms IS '원료 동의어/이명/검색어 처리용.';

CREATE INDEX idx_ingredient_synonyms_synonym ON ingredient_synonyms (synonym);
CREATE INDEX idx_ingredient_synonyms_ingredient_id ON ingredient_synonyms (ingredient_id);


-- ============================================================================
-- 3. 기능성/효능 (Claims)
-- ============================================================================

CREATE TABLE claims (
    id BIGSERIAL PRIMARY KEY,
    claim_code VARCHAR(100) UNIQUE,
    claim_name_ko VARCHAR(255) NOT NULL,
    claim_name_en VARCHAR(255),

    claim_category VARCHAR(100) NOT NULL,
    -- immune, bone_health, fatigue, eye_health, blood_lipid, sleep, etc.
    -- 코드 테이블 code_tables.table_code = 'claim_category' 참조

    claim_scope VARCHAR(50) NOT NULL,
    -- structure_function, general_health, research_only, prohibited_disease_claim
    -- 코드 테이블 code_tables.table_code = 'claim_scope' 참조

    description TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE claims IS '기능성/효능 표현 마스터.';
COMMENT ON COLUMN claims.claim_scope IS '기능성 범위. 질병 치료/예방 표현(prohibited_disease_claim)은 금지.';


-- ============================================================================
-- 4. 원료-기능성 연결 (Ingredient Claims, M:N)
-- ============================================================================

CREATE TABLE ingredient_claims (
    id BIGSERIAL PRIMARY KEY,
    ingredient_id BIGINT NOT NULL REFERENCES ingredients(id) ON DELETE CASCADE,
    claim_id BIGINT NOT NULL REFERENCES claims(id) ON DELETE CASCADE,

    evidence_grade VARCHAR(10),
    -- A, B, C, D, I
    -- 코드 테이블 code_tables.table_code = 'evidence_grade' 참조

    evidence_summary TEXT,
    is_regulator_approved BOOLEAN NOT NULL DEFAULT FALSE,
    approval_country_code VARCHAR(10),
    allowed_expression TEXT,
    prohibited_expression TEXT,

    source_priority INTEGER DEFAULT 100,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

    UNIQUE (ingredient_id, claim_id, approval_country_code)
);

COMMENT ON TABLE ingredient_claims IS '원료와 기능성의 M:N 연결. 국가별 허용 여부 분리.';
COMMENT ON COLUMN ingredient_claims.approval_country_code IS 'ISO 3166-1 alpha-2. 같은 claim도 국가별 허용 여부가 다름.';

CREATE INDEX idx_ingredient_claims_ingredient_id ON ingredient_claims (ingredient_id);
CREATE INDEX idx_ingredient_claims_claim_id ON ingredient_claims (claim_id);


-- ============================================================================
-- 5. 국가별 규제 상태 (Regulatory Statuses)
-- ============================================================================

CREATE TABLE regulatory_statuses (
    id BIGSERIAL PRIMARY KEY,
    ingredient_id BIGINT NOT NULL REFERENCES ingredients(id) ON DELETE CASCADE,
    country_code VARCHAR(10) NOT NULL,

    regulatory_category VARCHAR(100) NOT NULL,
    -- health_functional_food, dietary_supplement, novel_food, banned, restricted

    status VARCHAR(50) NOT NULL,
    -- approved, conditionally_approved, restricted, banned, unknown

    authority_name VARCHAR(255),
    reference_number VARCHAR(255),
    reference_url TEXT,
    notes TEXT,
    effective_date DATE,
    expiry_date DATE,

    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

    UNIQUE (ingredient_id, country_code, regulatory_category, status, effective_date)
);

COMMENT ON TABLE regulatory_statuses IS '국가별 규제 상태. 고시형/개별인정형 여부 등.';

CREATE INDEX idx_regulatory_statuses_ingredient_id ON regulatory_statuses (ingredient_id);
CREATE INDEX idx_regulatory_statuses_country ON regulatory_statuses (country_code);


-- ============================================================================
-- 6. 안전성 (Safety Items)
-- ============================================================================

CREATE TABLE safety_items (
    id BIGSERIAL PRIMARY KEY,
    ingredient_id BIGINT NOT NULL REFERENCES ingredients(id) ON DELETE CASCADE,

    safety_type VARCHAR(50) NOT NULL,
    -- adverse_effect, contraindication, warning, interaction,
    -- pregnancy_lactation, pediatrics, geriatrics, lab_interference

    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,

    severity_level VARCHAR(20),
    -- mild, moderate, severe, critical

    evidence_level VARCHAR(20),
    -- label, guideline, rct, observational, case_report, spontaneous_report, expert_opinion

    frequency_text VARCHAR(100),
    -- common, uncommon, rare, unknown

    applies_to_population TEXT,
    -- 임산부, 고령자, CKD 등

    management_advice TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE safety_items IS '부작용, 금기, 상호작용, 경고를 통합 관리.';
COMMENT ON COLUMN safety_items.evidence_level IS '부작용 3계층: label/guideline(1층), rct/observational/case_report(2층), spontaneous_report(3층)';

CREATE INDEX idx_safety_items_ingredient_id ON safety_items (ingredient_id);
CREATE INDEX idx_safety_items_type ON safety_items (safety_type);


-- ============================================================================
-- 7. 약물 상호작용 (Ingredient Drug Interactions)
-- ============================================================================

CREATE TABLE ingredient_drug_interactions (
    id BIGSERIAL PRIMARY KEY,
    ingredient_id BIGINT NOT NULL REFERENCES ingredients(id) ON DELETE CASCADE,

    drug_name VARCHAR(255) NOT NULL,
    drug_class VARCHAR(255),
    interaction_mechanism TEXT,
    clinical_effect TEXT,

    severity_level VARCHAR(20),
    -- mild, moderate, major

    recommendation TEXT,
    evidence_level VARCHAR(20),
    source_id BIGINT,
    -- sources 테이블 생성 후 FK 연결 (아래 ALTER TABLE 참조)

    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE ingredient_drug_interactions IS '약물 상호작용. safety_items과 별도 분리.';

CREATE INDEX idx_drug_interactions_ingredient_id ON ingredient_drug_interactions (ingredient_id);
CREATE INDEX idx_drug_interactions_drug_name ON ingredient_drug_interactions (drug_name);


-- ============================================================================
-- 8. 용량 가이드라인 (Dosage Guidelines)
-- ============================================================================

CREATE TABLE dosage_guidelines (
    id BIGSERIAL PRIMARY KEY,
    ingredient_id BIGINT NOT NULL REFERENCES ingredients(id) ON DELETE CASCADE,

    population_group VARCHAR(100) NOT NULL,
    -- adult, elderly, pregnancy, lactation, pediatric,
    -- renal_impairment, hepatic_impairment

    indication_context VARCHAR(255),
    -- 뼈 건강, 결핍 예방 등

    dose_min NUMERIC(12,4),
    dose_max NUMERIC(12,4),
    dose_unit VARCHAR(50),
    -- mg, mcg, IU, CFU, g

    frequency_text VARCHAR(100),
    route VARCHAR(50) DEFAULT 'oral',

    recommendation_type VARCHAR(50),
    -- daily_intake, upper_limit, studied_dose, label_dose

    notes TEXT,
    source_id BIGINT,
    -- sources 테이블 생성 후 FK 연결 (아래 ALTER TABLE 참조)

    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE dosage_guidelines IS '원료별 용량 가이드라인. 집단/적응증별 분리.';

CREATE INDEX idx_dosage_guidelines_ingredient_id ON dosage_guidelines (ingredient_id);


-- ============================================================================
-- 9. 제품 (Products)
-- ============================================================================

CREATE TABLE products (
    id BIGSERIAL PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL,
    brand_name VARCHAR(255),
    manufacturer_name VARCHAR(255),
    distributor_name VARCHAR(255),

    country_code VARCHAR(10),

    product_type VARCHAR(100),
    -- health_functional_food, dietary_supplement, general_food

    approval_or_report_no VARCHAR(255),

    status VARCHAR(50) DEFAULT 'active',
    -- active, discontinued, unknown

    barcode VARCHAR(100),
    product_image_url TEXT,
    marketplace_category VARCHAR(255),
    official_url TEXT,

    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE products IS '제품 마스터.';

CREATE INDEX idx_products_name ON products (product_name);
CREATE INDEX idx_products_brand ON products (brand_name);
CREATE INDEX idx_products_barcode ON products (barcode);


-- ============================================================================
-- 10. 제품-원료 연결 (Product Ingredients, M:N)
-- ============================================================================

CREATE TABLE product_ingredients (
    id BIGSERIAL PRIMARY KEY,
    product_id BIGINT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    ingredient_id BIGINT NOT NULL REFERENCES ingredients(id),

    amount_per_serving NUMERIC(12,4),
    amount_unit VARCHAR(50),
    daily_amount NUMERIC(12,4),
    daily_amount_unit VARCHAR(50),

    ingredient_role VARCHAR(50),
    -- active, inactive, additive, excipient

    raw_label_name VARCHAR(255),
    -- 원본 라벨 표기명 보존 (정규화 오류 추적용)

    is_standardized BOOLEAN DEFAULT FALSE,
    standardization_text TEXT,

    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE product_ingredients IS '제품과 원료의 M:N 연결. 함량 포함.';
COMMENT ON COLUMN product_ingredients.raw_label_name IS '원본 라벨 표기명. 정규화 오류 추적용으로 반드시 보존.';

CREATE INDEX idx_product_ingredients_product_id ON product_ingredients (product_id);
CREATE INDEX idx_product_ingredients_ingredient_id ON product_ingredients (ingredient_id);


-- ============================================================================
-- 11. 라벨 스냅샷 (Label Snapshots)
-- ============================================================================

CREATE TABLE label_snapshots (
    id BIGSERIAL PRIMARY KEY,
    product_id BIGINT NOT NULL REFERENCES products(id) ON DELETE CASCADE,

    label_version VARCHAR(100),
    source_name VARCHAR(255),
    source_url TEXT,

    serving_size_text VARCHAR(255),
    servings_per_container VARCHAR(100),

    warning_text TEXT,
    storage_text TEXT,
    directions_text TEXT,
    raw_label_text TEXT,
    -- 원본 보존: 파싱 로직 개선 시 재처리 가능

    captured_at TIMESTAMP,
    effective_date DATE,
    is_current BOOLEAN NOT NULL DEFAULT FALSE,

    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE label_snapshots IS '제품 라벨 버전 관리. 라벨은 자주 바뀌므로 현재값만 저장하면 안 됨.';
COMMENT ON COLUMN label_snapshots.raw_label_text IS '원본 라벨 텍스트 보존. 파싱 로직 개선 시 재처리 가능.';

CREATE INDEX idx_label_snapshots_product_id ON label_snapshots (product_id);
CREATE INDEX idx_label_snapshots_is_current ON label_snapshots (is_current) WHERE is_current = TRUE;


-- ============================================================================
-- 12. 근거 문헌 (Evidence Studies)
-- ============================================================================

CREATE TABLE evidence_studies (
    id BIGSERIAL PRIMARY KEY,
    ingredient_id BIGINT NOT NULL REFERENCES ingredients(id) ON DELETE CASCADE,

    source_type VARCHAR(50) NOT NULL,
    -- pubmed, guideline, regulatory_review, systematic_review, rct,
    -- observational, case_report

    title TEXT NOT NULL,
    abstract_text TEXT,
    authors TEXT,
    journal_name VARCHAR(255),
    publication_year INTEGER,
    publication_date DATE,

    pmid VARCHAR(50),
    doi VARCHAR(255),
    external_url TEXT,

    study_design VARCHAR(100),
    -- systematic_review, meta_analysis, rct, cohort, case_control,
    -- case_report, in_vitro, animal

    population_text TEXT,
    sample_size INTEGER,
    comparator_text TEXT,
    duration_text VARCHAR(255),

    risk_of_bias VARCHAR(50),
    -- low, some_concerns, high, unclear

    overall_relevance_score NUMERIC(5,2),

    -- 운영 추가 컬럼
    screening_status VARCHAR(50) DEFAULT 'pending',
    -- pending, included, excluded, needs_review
    included_in_summary BOOLEAN NOT NULL DEFAULT FALSE,
    duplicate_group_key VARCHAR(255),

    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE evidence_studies IS '논문 또는 근거 문서 기본 정보.';
COMMENT ON COLUMN evidence_studies.screening_status IS '스크리닝 상태. 수집 후 검수 워크플로우 추적.';
COMMENT ON COLUMN evidence_studies.duplicate_group_key IS '중복 논문 그룹 키. 같은 PMID 중복 수집 차단.';

-- pmid, doi는 NULL 허용이므로 partial unique index 사용
-- PostgreSQL에서 UNIQUE는 NULL 중복을 허용하지만, 의도를 명확히 하기 위해 partial index 적용
CREATE UNIQUE INDEX idx_evidence_studies_pmid ON evidence_studies (pmid) WHERE pmid IS NOT NULL;
CREATE UNIQUE INDEX idx_evidence_studies_doi ON evidence_studies (doi) WHERE doi IS NOT NULL;
CREATE INDEX idx_evidence_studies_ingredient_id ON evidence_studies (ingredient_id);
CREATE INDEX idx_evidence_studies_screening ON evidence_studies (screening_status);


-- ============================================================================
-- 13. 근거 결과지표 (Evidence Outcomes)
-- ============================================================================

CREATE TABLE evidence_outcomes (
    id BIGSERIAL PRIMARY KEY,
    evidence_study_id BIGINT NOT NULL REFERENCES evidence_studies(id) ON DELETE CASCADE,

    claim_id BIGINT REFERENCES claims(id),

    outcome_name VARCHAR(255) NOT NULL,
    outcome_type VARCHAR(100),
    -- efficacy, safety, biomarker, symptom, clinical_event

    effect_direction VARCHAR(20),
    -- positive, negative, neutral, mixed, unclear

    effect_size_text TEXT,
    p_value_text VARCHAR(100),
    confidence_interval_text VARCHAR(255),

    conclusion_summary TEXT,
    adverse_event_summary TEXT,

    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE evidence_outcomes IS '한 논문의 여러 결과지표. RCT가 피로와 수면을 동시 평가 가능.';

CREATE INDEX idx_evidence_outcomes_study_id ON evidence_outcomes (evidence_study_id);
CREATE INDEX idx_evidence_outcomes_claim_id ON evidence_outcomes (claim_id);


-- ============================================================================
-- 14. 근거 등급 변경 이력 (Evidence Grade History)
-- ============================================================================

CREATE TABLE evidence_grade_history (
    id BIGSERIAL PRIMARY KEY,
    ingredient_id BIGINT NOT NULL REFERENCES ingredients(id) ON DELETE CASCADE,
    claim_id BIGINT NOT NULL REFERENCES claims(id) ON DELETE CASCADE,

    old_grade VARCHAR(10),
    new_grade VARCHAR(10),
    change_reason TEXT,
    changed_by VARCHAR(255),
    changed_at TIMESTAMP NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE evidence_grade_history IS '근거 등급 변경 이력. 변경 시 사람 승인 필수.';

CREATE INDEX idx_evidence_grade_history_ingredient ON evidence_grade_history (ingredient_id);
CREATE INDEX idx_evidence_grade_history_claim ON evidence_grade_history (claim_id);


-- ============================================================================
-- 15. 출처 관리 (Sources)
-- ============================================================================

CREATE TABLE sources (
    id BIGSERIAL PRIMARY KEY,
    source_name VARCHAR(255) NOT NULL,

    source_type VARCHAR(50) NOT NULL,
    -- api, website, guideline, journal, regulator, database

    organization_name VARCHAR(255),
    source_url TEXT,
    country_code VARCHAR(10),

    trust_level VARCHAR(20),
    -- high, medium, low

    access_method VARCHAR(50),
    -- api, crawler, manual, import

    notes TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE sources IS '모든 출처 중앙 관리.';

CREATE INDEX idx_sources_type ON sources (source_type);


-- ============================================================================
-- 16. 출처 연결 (Source Links — Polymorphic)
-- ============================================================================
-- 주의: 범용 연결 테이블은 편리하지만 FK 강제가 안 됨.
-- 운영상 중요 엔티티는 별도 source_id 컬럼도 사용 권장.
-- (dosage_guidelines.source_id, ingredient_drug_interactions.source_id 등)

CREATE TABLE source_links (
    id BIGSERIAL PRIMARY KEY,
    source_id BIGINT NOT NULL REFERENCES sources(id) ON DELETE CASCADE,

    entity_type VARCHAR(50) NOT NULL,
    -- ingredient, claim, safety_item, product, label_snapshot,
    -- evidence_study, dosage_guideline, ingredient_drug_interaction

    entity_id BIGINT NOT NULL,
    source_reference TEXT,
    source_excerpt TEXT,

    retrieved_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),

    -- entity_type 값 범위 제한
    CONSTRAINT chk_source_links_entity_type CHECK (
        entity_type IN (
            'ingredient', 'claim', 'safety_item', 'product',
            'label_snapshot', 'evidence_study', 'dosage_guideline',
            'ingredient_drug_interaction', 'regulatory_status'
        )
    )
);

COMMENT ON TABLE source_links IS '각 엔티티에 출처를 연결하는 범용 테이블. FK 강제 불가, 체크 제약으로 보완.';

CREATE INDEX idx_source_links_entity ON source_links (entity_type, entity_id);
CREATE INDEX idx_source_links_source_id ON source_links (source_id);


-- ============================================================================
-- 17. 검수 워크플로우 (Review Tasks)
-- ============================================================================

CREATE TABLE review_tasks (
    id BIGSERIAL PRIMARY KEY,

    entity_type VARCHAR(50) NOT NULL,
    entity_id BIGINT NOT NULL,

    task_type VARCHAR(50) NOT NULL,
    -- scientific_review, regulatory_review, data_validation, content_update

    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    -- pending, in_progress, approved, rejected, needs_revision

    priority VARCHAR(20) DEFAULT 'normal',
    assigned_to VARCHAR(255),
    reviewer_comment TEXT,

    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    reviewed_at TIMESTAMP
);

COMMENT ON TABLE review_tasks IS '검수 워크플로우. L1(데이터), L2(과학), L3(규제) 검수용.';

CREATE INDEX idx_review_tasks_entity ON review_tasks (entity_type, entity_id);
CREATE INDEX idx_review_tasks_status ON review_tasks (status);


-- ============================================================================
-- 18. 변경 이력 (Revision Histories)
-- ============================================================================

CREATE TABLE revision_histories (
    id BIGSERIAL PRIMARY KEY,

    entity_type VARCHAR(50) NOT NULL,
    entity_id BIGINT NOT NULL,

    field_name VARCHAR(255),
    old_value TEXT,
    new_value TEXT,

    change_type VARCHAR(50),
    -- create, update, delete, merge, split

    changed_by VARCHAR(255),
    change_reason TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE revision_histories IS '모든 변경 이력 저장.';

CREATE INDEX idx_revision_histories_entity ON revision_histories (entity_type, entity_id);
CREATE INDEX idx_revision_histories_created ON revision_histories (created_at);


-- ============================================================================
-- 19. 검색 최적화 (Ingredient Search Documents)
-- ============================================================================
-- 원료명 + 동의어 + 기능성명 + 부작용 키워드를 합쳐 검색 인덱스 생성

CREATE TABLE ingredient_search_documents (
    ingredient_id BIGINT PRIMARY KEY REFERENCES ingredients(id) ON DELETE CASCADE,
    search_text TEXT NOT NULL,
    search_vector TSVECTOR,
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE ingredient_search_documents IS '검색 인덱스용. 원료명+동의어+기능성+부작용 키워드 통합.';

CREATE INDEX idx_ingredient_search_vector
    ON ingredient_search_documents USING GIN (search_vector);


-- ============================================================================
-- 20. 지연 FK 연결 (Deferred Foreign Keys)
-- ============================================================================
-- sources 테이블이 뒤에 생성되므로, 앞서 선언한 source_id 컬럼에 FK를 추가한다.

ALTER TABLE dosage_guidelines
    ADD CONSTRAINT fk_dosage_guidelines_source
    FOREIGN KEY (source_id) REFERENCES sources(id) ON DELETE SET NULL;

ALTER TABLE ingredient_drug_interactions
    ADD CONSTRAINT fk_drug_interactions_source
    FOREIGN KEY (source_id) REFERENCES sources(id) ON DELETE SET NULL;


-- ============================================================================
-- 21. 초기 출처 시드 데이터
-- ============================================================================

INSERT INTO sources (source_name, source_type, organization_name, source_url, country_code, trust_level, access_method) VALUES
    ('식품안전나라',              'api',       'MFDS',                  'https://www.foodsafetykorea.go.kr', 'KR', 'high',   'api'),
    ('공공데이터포털',            'api',       '행정안전부',              'https://www.data.go.kr',            'KR', 'high',   'api'),
    ('MFDS 고시/가이드',         'regulator', 'MFDS',                  'https://www.mfds.go.kr',            'KR', 'high',   'manual'),
    ('NIH ODS / DSLD',           'database',  'NIH',                   'https://dsld.od.nih.gov',           'US', 'high',   'api'),
    ('PubMed',                   'database',  'NLM/NCBI',              'https://pubmed.ncbi.nlm.nih.gov',   'US', 'high',   'api'),
    ('DailyMed',                 'database',  'NLM',                   'https://dailymed.nlm.nih.gov',      'US', 'high',   'api'),
    ('openFDA',                  'api',       'FDA',                   'https://open.fda.gov',              'US', 'medium', 'api'),
    ('USDA FoodData Central',    'database',  'USDA',                  'https://fdc.nal.usda.gov',          'US', 'high',   'api');


-- ============================================================================
-- 요약: MVP 필수 테이블 (10개)
-- ============================================================================
-- 1. ingredients
-- 2. ingredient_synonyms
-- 3. claims
-- 4. ingredient_claims
-- 5. safety_items
-- 6. dosage_guidelines
-- 7. products
-- 8. product_ingredients
-- 9. evidence_studies
-- 10. evidence_outcomes
--
-- + 지원 테이블: sources, source_links, code_tables, code_values
--
-- 이 구조로 아래 화면이 가능:
--   - 원료 상세 페이지 (기능성 요약, 근거 수준, 부작용, 복용량)
--   - 관련 제품 리스트
--   - 근거 문헌 목록
--   - 국내 허용 기능성 vs 학술 연구 분리 표시
