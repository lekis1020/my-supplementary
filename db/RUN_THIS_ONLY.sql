-- ============================================================================
-- 올인원 패치: 이 파일 하나만 Supabase SQL Editor에서 실행하세요
-- (001_schema.sql은 이미 실행된 상태 가정)
-- 포함: 컬럼 추가 + RLS + 시드 데이터
-- ============================================================================

-- ============================================================================
-- STEP 1: products 테이블에 is_published 컬럼 추가
-- ============================================================================
ALTER TABLE products ADD COLUMN IF NOT EXISTS is_published BOOLEAN NOT NULL DEFAULT FALSE;

-- ============================================================================
-- STEP 2: RLS 헬퍼 함수
-- ============================================================================
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN (
        current_setting('request.jwt.claims', true)::jsonb
        -> 'app_metadata' ->> 'role'
    ) = 'admin';
EXCEPTION
    WHEN OTHERS THEN RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION is_reviewer()
RETURNS BOOLEAN AS $$
DECLARE
    user_role TEXT;
BEGIN
    user_role := (
        current_setting('request.jwt.claims', true)::jsonb
        -> 'app_metadata' ->> 'role'
    );
    RETURN user_role IN ('admin', 'scientific_reviewer', 'regulatory_reviewer', 'qa');
EXCEPTION
    WHEN OTHERS THEN RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- STEP 3: RLS 정책 (DROP IF EXISTS 후 재생성)
-- ============================================================================

-- ingredients
ALTER TABLE ingredients ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "공개: 게시된 원료 조회" ON ingredients;
DROP POLICY IF EXISTS "Admin: 원료 전체 접근" ON ingredients;
CREATE POLICY "공개: 게시된 원료 조회" ON ingredients FOR SELECT TO anon, authenticated USING (is_published = TRUE);
CREATE POLICY "Admin: 원료 전체 접근" ON ingredients FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());

-- ingredient_synonyms
ALTER TABLE ingredient_synonyms ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "공개: 게시된 원료의 동의어" ON ingredient_synonyms;
DROP POLICY IF EXISTS "Admin: 동의어 전체 접근" ON ingredient_synonyms;
CREATE POLICY "공개: 게시된 원료의 동의어" ON ingredient_synonyms FOR SELECT TO anon, authenticated
    USING (EXISTS (SELECT 1 FROM ingredients WHERE ingredients.id = ingredient_synonyms.ingredient_id AND ingredients.is_published = TRUE));
CREATE POLICY "Admin: 동의어 전체 접근" ON ingredient_synonyms FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());

-- claims
ALTER TABLE claims ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "공개: claim 조회" ON claims;
DROP POLICY IF EXISTS "Admin: claim 전체 접근" ON claims;
CREATE POLICY "공개: claim 조회" ON claims FOR SELECT TO anon, authenticated USING (TRUE);
CREATE POLICY "Admin: claim 전체 접근" ON claims FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());

-- ingredient_claims
ALTER TABLE ingredient_claims ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "공개: 게시된 원료의 기능성" ON ingredient_claims;
DROP POLICY IF EXISTS "Admin: 원료기능성 전체 접근" ON ingredient_claims;
CREATE POLICY "공개: 게시된 원료의 기능성" ON ingredient_claims FOR SELECT TO anon, authenticated
    USING (EXISTS (SELECT 1 FROM ingredients WHERE ingredients.id = ingredient_claims.ingredient_id AND ingredients.is_published = TRUE));
CREATE POLICY "Admin: 원료기능성 전체 접근" ON ingredient_claims FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());

-- safety_items
ALTER TABLE safety_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "공개: 게시된 원료의 안전성" ON safety_items;
DROP POLICY IF EXISTS "Admin: 안전성 전체 접근" ON safety_items;
CREATE POLICY "공개: 게시된 원료의 안전성" ON safety_items FOR SELECT TO anon, authenticated
    USING (EXISTS (SELECT 1 FROM ingredients WHERE ingredients.id = safety_items.ingredient_id AND ingredients.is_published = TRUE));
CREATE POLICY "Admin: 안전성 전체 접근" ON safety_items FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());

-- dosage_guidelines
ALTER TABLE dosage_guidelines ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "공개: 게시된 원료의 용량" ON dosage_guidelines;
DROP POLICY IF EXISTS "Admin: 용량 전체 접근" ON dosage_guidelines;
CREATE POLICY "공개: 게시된 원료의 용량" ON dosage_guidelines FOR SELECT TO anon, authenticated
    USING (EXISTS (SELECT 1 FROM ingredients WHERE ingredients.id = dosage_guidelines.ingredient_id AND ingredients.is_published = TRUE));
CREATE POLICY "Admin: 용량 전체 접근" ON dosage_guidelines FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());

-- ingredient_drug_interactions
ALTER TABLE ingredient_drug_interactions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "공개: 게시된 원료의 약물상호작용" ON ingredient_drug_interactions;
DROP POLICY IF EXISTS "Admin: 약물상호작용 전체 접근" ON ingredient_drug_interactions;
CREATE POLICY "공개: 게시된 원료의 약물상호작용" ON ingredient_drug_interactions FOR SELECT TO anon, authenticated
    USING (EXISTS (SELECT 1 FROM ingredients WHERE ingredients.id = ingredient_drug_interactions.ingredient_id AND ingredients.is_published = TRUE));
CREATE POLICY "Admin: 약물상호작용 전체 접근" ON ingredient_drug_interactions FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());

-- regulatory_statuses
ALTER TABLE regulatory_statuses ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "공개: 게시된 원료의 규제상태" ON regulatory_statuses;
DROP POLICY IF EXISTS "Admin: 규제상태 전체 접근" ON regulatory_statuses;
CREATE POLICY "공개: 게시된 원료의 규제상태" ON regulatory_statuses FOR SELECT TO anon, authenticated
    USING (EXISTS (SELECT 1 FROM ingredients WHERE ingredients.id = regulatory_statuses.ingredient_id AND ingredients.is_published = TRUE));
CREATE POLICY "Admin: 규제상태 전체 접근" ON regulatory_statuses FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());

-- products
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "공개: 게시된 제품 조회" ON products;
DROP POLICY IF EXISTS "Admin: 제품 전체 접근" ON products;
CREATE POLICY "공개: 게시된 제품 조회" ON products FOR SELECT TO anon, authenticated USING (is_published = TRUE);
CREATE POLICY "Admin: 제품 전체 접근" ON products FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());

-- product_ingredients
ALTER TABLE product_ingredients ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "공개: 게시된 제품의 성분" ON product_ingredients;
DROP POLICY IF EXISTS "Admin: 제품성분 전체 접근" ON product_ingredients;
CREATE POLICY "공개: 게시된 제품의 성분" ON product_ingredients FOR SELECT TO anon, authenticated
    USING (EXISTS (SELECT 1 FROM products WHERE products.id = product_ingredients.product_id AND products.is_published = TRUE));
CREATE POLICY "Admin: 제품성분 전체 접근" ON product_ingredients FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());

-- label_snapshots
ALTER TABLE label_snapshots ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "공개: 게시된 제품의 라벨" ON label_snapshots;
DROP POLICY IF EXISTS "Admin: 라벨 전체 접근" ON label_snapshots;
CREATE POLICY "공개: 게시된 제품의 라벨" ON label_snapshots FOR SELECT TO anon, authenticated
    USING (EXISTS (SELECT 1 FROM products WHERE products.id = label_snapshots.product_id AND products.is_published = TRUE));
CREATE POLICY "Admin: 라벨 전체 접근" ON label_snapshots FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());

-- evidence_studies
ALTER TABLE evidence_studies ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "공개: 포함된 논문 조회" ON evidence_studies;
DROP POLICY IF EXISTS "Admin: 논문 전체 접근" ON evidence_studies;
CREATE POLICY "공개: 포함된 논문 조회" ON evidence_studies FOR SELECT TO anon, authenticated
    USING (screening_status = 'included' AND EXISTS (SELECT 1 FROM ingredients WHERE ingredients.id = evidence_studies.ingredient_id AND ingredients.is_published = TRUE));
CREATE POLICY "Admin: 논문 전체 접근" ON evidence_studies FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());

-- evidence_outcomes (주의: evidence_study_id 사용)
ALTER TABLE evidence_outcomes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "공개: 게시된 논문의 결과" ON evidence_outcomes;
DROP POLICY IF EXISTS "Admin: 논문결과 전체 접근" ON evidence_outcomes;
CREATE POLICY "공개: 게시된 논문의 결과" ON evidence_outcomes FOR SELECT TO anon, authenticated
    USING (EXISTS (
        SELECT 1 FROM evidence_studies es JOIN ingredients i ON i.id = es.ingredient_id
        WHERE es.id = evidence_outcomes.evidence_study_id AND es.screening_status = 'included' AND i.is_published = TRUE
    ));
CREATE POLICY "Admin: 논문결과 전체 접근" ON evidence_outcomes FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());

-- evidence_grade_history
ALTER TABLE evidence_grade_history ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "공개: 게시된 원료의 등급이력" ON evidence_grade_history;
DROP POLICY IF EXISTS "Admin: 등급이력 전체 접근" ON evidence_grade_history;
CREATE POLICY "공개: 게시된 원료의 등급이력" ON evidence_grade_history FOR SELECT TO anon, authenticated
    USING (EXISTS (SELECT 1 FROM ingredients WHERE ingredients.id = evidence_grade_history.ingredient_id AND ingredients.is_published = TRUE));
CREATE POLICY "Admin: 등급이력 전체 접근" ON evidence_grade_history FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());

-- 코드/출처 (공개 읽기)
ALTER TABLE code_tables ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "공개: 코드테이블 조회" ON code_tables;
DROP POLICY IF EXISTS "Admin: 코드테이블 관리" ON code_tables;
CREATE POLICY "공개: 코드테이블 조회" ON code_tables FOR SELECT TO anon, authenticated USING (TRUE);
CREATE POLICY "Admin: 코드테이블 관리" ON code_tables FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());

ALTER TABLE code_values ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "공개: 코드값 조회" ON code_values;
DROP POLICY IF EXISTS "Admin: 코드값 관리" ON code_values;
CREATE POLICY "공개: 코드값 조회" ON code_values FOR SELECT TO anon, authenticated USING (TRUE);
CREATE POLICY "Admin: 코드값 관리" ON code_values FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());

ALTER TABLE sources ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "공개: 출처 조회" ON sources;
DROP POLICY IF EXISTS "Admin: 출처 관리" ON sources;
CREATE POLICY "공개: 출처 조회" ON sources FOR SELECT TO anon, authenticated USING (TRUE);
CREATE POLICY "Admin: 출처 관리" ON sources FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());

ALTER TABLE source_links ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "공개: 출처연결 조회" ON source_links;
DROP POLICY IF EXISTS "Admin: 출처연결 관리" ON source_links;
CREATE POLICY "공개: 출처연결 조회" ON source_links FOR SELECT TO anon, authenticated USING (TRUE);
CREATE POLICY "Admin: 출처연결 관리" ON source_links FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());

-- 검색 최적화
ALTER TABLE ingredient_search_documents ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "공개: 게시된 원료 검색" ON ingredient_search_documents;
DROP POLICY IF EXISTS "Admin: 검색문서 전체 접근" ON ingredient_search_documents;
CREATE POLICY "공개: 게시된 원료 검색" ON ingredient_search_documents FOR SELECT TO anon, authenticated
    USING (EXISTS (SELECT 1 FROM ingredients WHERE ingredients.id = ingredient_search_documents.ingredient_id AND ingredients.is_published = TRUE));
CREATE POLICY "Admin: 검색문서 전체 접근" ON ingredient_search_documents FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());

-- 운영 전용
ALTER TABLE review_tasks ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "검수자: 검수 태스크 조회" ON review_tasks;
DROP POLICY IF EXISTS "검수자: 검수 태스크 수정" ON review_tasks;
DROP POLICY IF EXISTS "Admin: 검수 태스크 전체 접근" ON review_tasks;
CREATE POLICY "검수자: 검수 태스크 조회" ON review_tasks FOR SELECT TO authenticated USING (is_reviewer());
CREATE POLICY "검수자: 검수 태스크 수정" ON review_tasks FOR UPDATE TO authenticated USING (is_reviewer()) WITH CHECK (is_reviewer());
CREATE POLICY "Admin: 검수 태스크 전체 접근" ON review_tasks FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());

ALTER TABLE revision_histories ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "검수자: 변경이력 조회" ON revision_histories;
DROP POLICY IF EXISTS "Admin: 변경이력 전체 접근" ON revision_histories;
CREATE POLICY "검수자: 변경이력 조회" ON revision_histories FOR SELECT TO authenticated USING (is_reviewer());
CREATE POLICY "Admin: 변경이력 전체 접근" ON revision_histories FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());

-- 수집 계층 (Admin 전용)
ALTER TABLE source_connectors ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Admin: 커넥터 전체 접근" ON source_connectors;
CREATE POLICY "Admin: 커넥터 전체 접근" ON source_connectors FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());

ALTER TABLE collection_jobs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Admin: 수집작업 전체 접근" ON collection_jobs;
CREATE POLICY "Admin: 수집작업 전체 접근" ON collection_jobs FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());

ALTER TABLE collection_runs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Admin: 수집실행 전체 접근" ON collection_runs;
CREATE POLICY "Admin: 수집실행 전체 접근" ON collection_runs FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());

ALTER TABLE raw_documents ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Admin: 원문 전체 접근" ON raw_documents;
DROP POLICY IF EXISTS "검수자: 원문 조회" ON raw_documents;
CREATE POLICY "Admin: 원문 전체 접근" ON raw_documents FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());
CREATE POLICY "검수자: 원문 조회" ON raw_documents FOR SELECT TO authenticated USING (is_reviewer());

ALTER TABLE extraction_results ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Admin: 추출결과 전체 접근" ON extraction_results;
DROP POLICY IF EXISTS "검수자: 추출결과 조회" ON extraction_results;
CREATE POLICY "Admin: 추출결과 전체 접근" ON extraction_results FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());
CREATE POLICY "검수자: 추출결과 조회" ON extraction_results FOR SELECT TO authenticated USING (is_reviewer());

ALTER TABLE refresh_policies ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Admin: 갱신정책 전체 접근" ON refresh_policies;
CREATE POLICY "Admin: 갱신정책 전체 접근" ON refresh_policies FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());

ALTER TABLE entity_refresh_states ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Admin: 갱신상태 전체 접근" ON entity_refresh_states;
CREATE POLICY "Admin: 갱신상태 전체 접근" ON entity_refresh_states FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());

-- ============================================================================
-- STEP 4: 시드 데이터 (기존 데이터 정리 후 삽입)
-- ============================================================================

-- 기존 시드 정리 (FK 순서 고려)
TRUNCATE label_snapshots, product_ingredients, products,
         ingredient_claims, safety_items, ingredient_drug_interactions, dosage_guidelines,
         claims, ingredients, code_values, sources CASCADE;

-- code_tables: ON CONFLICT로 안전하게 upsert
INSERT INTO code_tables (table_code, table_name_ko, table_name_en, description) VALUES
('ingredient_type',   '원료 유형',        'Ingredient Type',   '비타민, 미네랄, 허브 등'),
('safety_type',       '안전성 유형',      'Safety Type',       '이상반응, 금기, 주의사항 등'),
('severity_level',    '심각도',           'Severity Level',    'critical~mild'),
('claim_scope',       '효능 범위',        'Claim Scope',       'approved_kr, studied 등'),
('claim_category',    '효능 카테고리',    'Claim Category',    '뼈/관절, 면역 등'),
('evidence_grade',    '근거 등급',        'Evidence Grade',    'A~F'),
('review_level',      '검수 단계',        'Review Level',      'L1, L2, L3'),
('review_status',     '검수 상태',        'Review Status',     'pending, approved 등'),
('product_type',      '제품 유형',        'Product Type',      '건강기능식품, dietary supplement 등'),
('connector_type',    '커넥터 유형',      'Connector Type',    'api, browser_agent, hybrid'),
('origin_type',       '원료 기원',        'Origin Type',       'synthetic, natural 등'),
('recommendation_type','권장 유형',       'Recommendation Type','RDA, UL, AI 등')
ON CONFLICT (table_code) DO UPDATE SET table_name_ko = EXCLUDED.table_name_ko, description = EXCLUDED.description;

-- code_values
INSERT INTO code_values (code_table_id, code, label_ko, label_en, sort_order) VALUES
((SELECT id FROM code_tables WHERE table_code='ingredient_type'), 'vitamin',    '비타민',       'Vitamin',     1),
((SELECT id FROM code_tables WHERE table_code='ingredient_type'), 'mineral',    '미네랄',       'Mineral',     2),
((SELECT id FROM code_tables WHERE table_code='ingredient_type'), 'amino_acid', '아미노산',     'Amino Acid',  3),
((SELECT id FROM code_tables WHERE table_code='ingredient_type'), 'fatty_acid', '지방산',       'Fatty Acid',  4),
((SELECT id FROM code_tables WHERE table_code='ingredient_type'), 'probiotic',  '프로바이오틱스','Probiotic',   5),
((SELECT id FROM code_tables WHERE table_code='ingredient_type'), 'herbal',     '허브/식물성',  'Herbal',      6),
((SELECT id FROM code_tables WHERE table_code='ingredient_type'), 'enzyme',     '효소',         'Enzyme',      7),
((SELECT id FROM code_tables WHERE table_code='ingredient_type'), 'other',      '기타',         'Other',       8),
((SELECT id FROM code_tables WHERE table_code='safety_type'), 'adverse_effect',   '이상반응',     'Adverse Effect',    1),
((SELECT id FROM code_tables WHERE table_code='safety_type'), 'contraindication', '금기',         'Contraindication',  2),
((SELECT id FROM code_tables WHERE table_code='safety_type'), 'precaution',       '주의사항',     'Precaution',        3),
((SELECT id FROM code_tables WHERE table_code='safety_type'), 'drug_interaction', '약물상호작용', 'Drug Interaction',  4),
((SELECT id FROM code_tables WHERE table_code='safety_type'), 'pregnancy',        '임신/수유',    'Pregnancy',         5),
((SELECT id FROM code_tables WHERE table_code='safety_type'), 'pediatric',        '소아',         'Pediatric',         6),
((SELECT id FROM code_tables WHERE table_code='safety_type'), 'overdose',         '과다복용',     'Overdose',          7),
((SELECT id FROM code_tables WHERE table_code='severity_level'), 'critical', '심각', 'Critical', 1),
((SELECT id FROM code_tables WHERE table_code='severity_level'), 'serious',  '중대', 'Serious',  2),
((SELECT id FROM code_tables WHERE table_code='severity_level'), 'moderate', '보통', 'Moderate', 3),
((SELECT id FROM code_tables WHERE table_code='severity_level'), 'mild',     '경미', 'Mild',     4),
((SELECT id FROM code_tables WHERE table_code='claim_scope'), 'approved_kr', '식약처 인정', 'MFDS Approved', 1),
((SELECT id FROM code_tables WHERE table_code='claim_scope'), 'approved_us', 'FDA 인정',    'FDA Approved',  2),
((SELECT id FROM code_tables WHERE table_code='claim_scope'), 'studied',     '학술 연구',   'Studied',       3),
((SELECT id FROM code_tables WHERE table_code='claim_scope'), 'traditional', '전통적 사용', 'Traditional',   4),
((SELECT id FROM code_tables WHERE table_code='claim_scope'), 'prohibited',  '금지 표현',   'Prohibited',    5),
((SELECT id FROM code_tables WHERE table_code='evidence_grade'), 'A', '매우 강함', 'Strong',       1),
((SELECT id FROM code_tables WHERE table_code='evidence_grade'), 'B', '강함',     'Good',         2),
((SELECT id FROM code_tables WHERE table_code='evidence_grade'), 'C', '보통',     'Fair',         3),
((SELECT id FROM code_tables WHERE table_code='evidence_grade'), 'D', '약함',     'Limited',      4),
((SELECT id FROM code_tables WHERE table_code='evidence_grade'), 'F', '불충분',   'Insufficient', 5),
((SELECT id FROM code_tables WHERE table_code='product_type'), 'health_functional_food', '건강기능식품',    'Health Functional Food', 1),
((SELECT id FROM code_tables WHERE table_code='product_type'), 'dietary_supplement',     '다이어터리 서플', 'Dietary Supplement',     2),
((SELECT id FROM code_tables WHERE table_code='product_type'), 'general_food',           '일반식품',        'General Food',           3);

-- 원료 20종
INSERT INTO ingredients (canonical_name_ko, canonical_name_en, display_name, scientific_name, slug, ingredient_type, description, origin_type, form_description, standardization_info, is_active, is_published) VALUES
('비타민 D',      'Vitamin D',       '비타민 D',      'Cholecalciferol',            'vitamin-d',       'vitamin',    '칼슘 흡수와 면역 기능에 필수적인 지용성 비타민.',    'synthetic', 'D3 (콜레칼시페롤), D2 (에르고칼시페롤)', '1mcg = 40IU',            true, true),
('비타민 C',      'Vitamin C',       '비타민 C',      'Ascorbic acid',              'vitamin-c',       'vitamin',    '항산화 기능, 콜라겐 합성, 면역 기능에 관여.',         'synthetic', '아스코르브산, 칼슘 아스코르베이트',      NULL,                     true, true),
('비타민 B12',    'Vitamin B12',     '비타민 B12',    'Cyanocobalamin',             'vitamin-b12',     'vitamin',    '적혈구 형성, 신경 기능, DNA 합성에 필수.',            'synthetic', '시아노코발라민, 메틸코발라민',           NULL,                     true, true),
('엽산',          'Folate',          '엽산',          'Folic acid',                 'folate',          'vitamin',    '세포 분열, DNA 합성에 필수. 임신 중 중요.',            'synthetic', '폴산(합성), 5-MTHF(활성형)',            '1mcg DFE = 0.6mcg 폴산', true, true),
('오메가-3',      'Omega-3',         '오메가-3',      'EPA/DHA',                    'omega-3',         'fatty_acid', 'EPA와 DHA를 포함하는 필수 지방산.',                    'natural',   '어유, 크릴오일, 미세조류 유래',          'EPA+DHA 합계 기준',      true, true),
('마그네슘',      'Magnesium',       '마그네슘',      'Magnesium',                  'magnesium',       'mineral',    '300종 이상의 효소 반응에 관여. 근육, 신경, 뼈 건강.', 'synthetic', '산화물, 구연산, 비스글리시네이트',       '원소 마그네슘 기준',     true, true),
('아연',          'Zinc',            '아연',          'Zinc',                       'zinc',            'mineral',    '면역 기능, 상처 치유, 단백질 합성에 관여.',            'synthetic', '글루콘산, 피콜리네이트, 황산아연',       '원소 아연 기준',         true, true),
('철분',          'Iron',            '철분',          'Ferrous/Ferric iron',        'iron',            'mineral',    '헤모글로빈 구성, 산소 운반에 필수.',                   'synthetic', '황산제일철, 퓨마르산, 비스글리시네이트', '원소 철 기준',           true, true),
('칼슘',          'Calcium',         '칼슘',          'Calcium',                    'calcium',         'mineral',    '뼈와 치아 구성, 근육 수축, 신경 전달에 필수.',         'natural',   '탄산칼슘, 구연산칼슘, 인산칼슘',         '원소 칼슘 기준',         true, true),
('프로바이오틱스', 'Probiotics',      '프로바이오틱스', 'Lactobacillus/Bifidobacterium','probiotics',    'probiotic',  '장내 미생물 균형에 기여하는 유익한 미생물.',           'natural',   '락토바실러스, 비피도박테리움 등',         'CFU 기준',               true, true),
('루테인',        'Lutein',          '루테인',        'Lutein',                     'lutein',          'herbal',     '눈의 황반에 존재하는 카로티노이드.',                   'natural',   '마리골드 추출물',                        NULL,                     true, true),
('코엔자임Q10',   'CoQ10',           '코엔자임Q10',   'Ubiquinone',                 'coq10',           'other',      '세포 에너지 생성에 관여하는 항산화 물질.',              'synthetic', '유비퀴논(산화형), 유비퀴놀(환원형)',      NULL,                     true, true),
('밀크씨슬',      'Milk Thistle',    '밀크씨슬',      'Silybum marianum',           'milk-thistle',    'herbal',     '실리마린 성분이 간세포 보호에 관여.',                  'natural',   '실리마린 추출물',                        '실리마린 80% 표준화',    true, true),
('글루코사민',    'Glucosamine',     '글루코사민',    'Glucosamine',                'glucosamine',     'amino_acid', '관절 연골 구성 성분.',                                 'synthetic', '글루코사민 황산염, 염산염',              NULL,                     true, true),
('비오틴',        'Biotin',          '비오틴',        'Biotin',                     'biotin',          'vitamin',    '에너지 대사, 피부·모발·손톱 건강에 관여 (B7).',        'synthetic', NULL,                                     NULL,                     true, true),
('셀레늄',        'Selenium',        '셀레늄',        'Selenium',                   'selenium',        'mineral',    '항산화 효소의 구성 성분. 갑상선 기능, 면역.',          'synthetic', '셀레노메티오닌, 아셀렌산나트륨',         '원소 셀레늄 기준',       true, true),
('비타민 A',      'Vitamin A',       '비타민 A',      'Retinol',                    'vitamin-a',       'vitamin',    '시력, 면역 기능, 피부 건강에 필수.',                   'synthetic', '레티놀, 베타카로틴(전구체)',             '1mcg RAE = 12mcg β-카로틴', true, true),
('비타민 E',      'Vitamin E',       '비타민 E',      'Tocopherol',                 'vitamin-e',       'vitamin',    '지용성 항산화 비타민. 세포막 보호.',                   'natural',   '알파토코페롤, 혼합 토코페롤',            '1mg = 1.49IU(d-alpha)',  true, true),
('커큐민',        'Curcumin',        '커큐민',        'Curcuma longa',              'curcumin',        'herbal',     '강황의 주요 활성 성분. 항염, 항산화 작용.',             'natural',   '강황 추출물, 피페린 복합',               '커큐미노이드 95% 표준화', true, true),
('멜라토닌',      'Melatonin',       '멜라토닌',      'Melatonin',                  'melatonin',       'other',      '수면-각성 주기를 조절하는 호르몬.',                    'synthetic', NULL,                                     NULL,                     true, true);

-- 기능성 18종
INSERT INTO claims (claim_code, claim_name_ko, claim_name_en, claim_category, claim_scope, description) VALUES
('BONE_HEALTH',       '뼈 건강에 도움',              'Bone Health',              'bone_joint',        'approved_kr', '뼈의 형성과 유지에 필요'),
('IMMUNE_FUNCTION',   '면역 기능 개선에 도움',        'Immune Function',          'immune',            'approved_kr', '정상적인 면역 기능에 필요'),
('ANTIOXIDANT',       '항산화에 도움',               'Antioxidant',              'antioxidant',       'approved_kr', '유해산소로부터 세포를 보호'),
('EYE_HEALTH',        '눈 건강에 도움',              'Eye Health',               'eye',               'approved_kr', '황반색소밀도를 유지'),
('LIVER_HEALTH',      '간 건강에 도움',              'Liver Health',             'liver',             'approved_kr', '간 건강에 도움'),
('JOINT_HEALTH',      '관절 건강에 도움',            'Joint Health',             'bone_joint',        'approved_kr', '관절 건강에 도움'),
('GUT_HEALTH',        '장 건강에 도움',              'Gut Health',               'digestive',         'approved_kr', '유익균 증식 및 유해균 억제'),
('BLOOD_LIPID',       '혈중 중성지질 개선에 도움',    'Blood Lipid',              'cardiovascular',    'approved_kr', '혈중 중성지방 수치 개선'),
('SKIN_HEALTH',       '피부 건강에 도움',            'Skin Health',              'skin_hair',         'approved_kr', '피부 보습에 도움'),
('ENERGY_METABOLISM',  '에너지 대사에 도움',          'Energy Metabolism',        'energy',            'approved_kr', '에너지 생성에 필요'),
('RBC_FORMATION',     '적혈구 형성에 도움',          'Red Blood Cell Formation', 'blood',             'approved_kr', '적혈구 형성에 필요'),
('NEURAL_TUBE',       '태아 신경관 정상 발달에 도움', 'Neural Tube Development',  'pregnancy',         'approved_kr', '태아 신경관의 정상 발달에 필요'),
('SLEEP_AID',         '수면 개선에 도움',            'Sleep Aid',                'sleep',             'studied',     '수면의 질 개선 연구'),
('ANTI_INFLAMMATORY', '항염 작용',                   'Anti-inflammatory',        'anti_inflammatory', 'studied',     '염증 반응 억제 연구'),
('THYROID_FUNCTION',  '갑상선 기능에 도움',          'Thyroid Function',         'endocrine',         'approved_kr', '갑상선 호르몬 합성에 필요'),
('CARDIOVASCULAR',    '심혈관 건강에 도움',          'Cardiovascular Health',    'cardiovascular',    'studied',     '심혈관 건강 유지 연구'),
('HAIR_NAIL',         '모발·손톱 건강에 도움',       'Hair & Nail Health',       'skin_hair',         'studied',     '모발 및 손톱 건강 유지 연구'),
('COLLAGEN_SYNTHESIS','콜라겐 합성에 도움',          'Collagen Synthesis',       'skin_hair',         'approved_kr', '결합조직 형성에 필요');

-- 원료-기능성 연결
INSERT INTO ingredient_claims (ingredient_id, claim_id, evidence_grade, evidence_summary, is_regulator_approved, approval_country_code, allowed_expression) VALUES
((SELECT id FROM ingredients WHERE slug='vitamin-d'),  (SELECT id FROM claims WHERE claim_code='BONE_HEALTH'),       'A', '메타분석 확인',       true, 'KR', '뼈의 형성과 유지에 필요'),
((SELECT id FROM ingredients WHERE slug='vitamin-d'),  (SELECT id FROM claims WHERE claim_code='IMMUNE_FUNCTION'),   'B', '임상 연구 다수',     true, 'KR', '정상적인 면역 기능에 필요'),
((SELECT id FROM ingredients WHERE slug='vitamin-c'),  (SELECT id FROM claims WHERE claim_code='ANTIOXIDANT'),       'A', '수용성 항산화제',     true, 'KR', '유해산소로부터 세포를 보호'),
((SELECT id FROM ingredients WHERE slug='vitamin-c'),  (SELECT id FROM claims WHERE claim_code='IMMUNE_FUNCTION'),   'B', '면역세포 기능 지원',  true, 'KR', '정상적인 면역 기능에 필요'),
((SELECT id FROM ingredients WHERE slug='vitamin-c'),  (SELECT id FROM claims WHERE claim_code='COLLAGEN_SYNTHESIS'),'A', '콜라겐 합성 보조인자',true, 'KR', '결합조직 형성에 필요'),
((SELECT id FROM ingredients WHERE slug='omega-3'),    (SELECT id FROM claims WHERE claim_code='BLOOD_LIPID'),       'A', '중성지방 감소 확인',  true, 'KR', '혈중 중성지질 개선에 도움'),
((SELECT id FROM ingredients WHERE slug='omega-3'),    (SELECT id FROM claims WHERE claim_code='CARDIOVASCULAR'),    'B', '심혈관 보호 연구',    false, NULL, NULL),
((SELECT id FROM ingredients WHERE slug='magnesium'),  (SELECT id FROM claims WHERE claim_code='ENERGY_METABOLISM'), 'A', '300+ 효소 보조인자',  true, 'KR', '에너지 이용에 필요'),
((SELECT id FROM ingredients WHERE slug='magnesium'),  (SELECT id FROM claims WHERE claim_code='BONE_HEALTH'),       'B', '뼈 건강 관여',        true, 'KR', '뼈의 형성과 유지에 필요'),
((SELECT id FROM ingredients WHERE slug='probiotics'), (SELECT id FROM claims WHERE claim_code='GUT_HEALTH'),        'A', '장내 균형 다수 근거', true, 'KR', '유익균 증식 및 유해균 억제에 도움'),
((SELECT id FROM ingredients WHERE slug='lutein'),     (SELECT id FROM claims WHERE claim_code='EYE_HEALTH'),        'A', '황반색소밀도 유지',   true, 'KR', '황반색소밀도를 유지'),
((SELECT id FROM ingredients WHERE slug='milk-thistle'),(SELECT id FROM claims WHERE claim_code='LIVER_HEALTH'),     'B', '간세포 보호 연구',    true, 'KR', '간 건강에 도움'),
((SELECT id FROM ingredients WHERE slug='glucosamine'), (SELECT id FROM claims WHERE claim_code='JOINT_HEALTH'),     'B', '관절 건강 유지',      true, 'KR', '관절 건강에 도움'),
((SELECT id FROM ingredients WHERE slug='folate'),     (SELECT id FROM claims WHERE claim_code='NEURAL_TUBE'),       'A', '신경관 결손 예방',    true, 'KR', '태아 신경관의 정상 발달에 필요'),
((SELECT id FROM ingredients WHERE slug='folate'),     (SELECT id FROM claims WHERE claim_code='RBC_FORMATION'),     'A', '적혈구 형성 필수',    true, 'KR', '정상적인 적혈구 형성에 필요'),
((SELECT id FROM ingredients WHERE slug='zinc'),       (SELECT id FROM claims WHERE claim_code='IMMUNE_FUNCTION'),   'A', '면역 필수 미량 원소', true, 'KR', '정상적인 면역 기능에 필요'),
((SELECT id FROM ingredients WHERE slug='iron'),       (SELECT id FROM claims WHERE claim_code='RBC_FORMATION'),     'A', '헤모글로빈 합성 필수',true, 'KR', '체내 산소운반과 혈액생성에 필요'),
((SELECT id FROM ingredients WHERE slug='curcumin'),   (SELECT id FROM claims WHERE claim_code='ANTI_INFLAMMATORY'), 'C', '소규모 임상',         false, NULL, NULL),
((SELECT id FROM ingredients WHERE slug='melatonin'),  (SELECT id FROM claims WHERE claim_code='SLEEP_AID'),         'A', '수면 잠복기 단축',    false, NULL, NULL),
((SELECT id FROM ingredients WHERE slug='biotin'),     (SELECT id FROM claims WHERE claim_code='HAIR_NAIL'),         'C', '정상인 근거 제한적',  false, NULL, NULL),
((SELECT id FROM ingredients WHERE slug='selenium'),   (SELECT id FROM claims WHERE claim_code='ANTIOXIDANT'),       'B', '글루타치온 보조인자', true, 'KR', '유해산소로부터 세포를 보호'),
((SELECT id FROM ingredients WHERE slug='selenium'),   (SELECT id FROM claims WHERE claim_code='THYROID_FUNCTION'),  'B', '갑상선 호르몬 대사',  true, 'KR', '갑상선 호르몬 합성에 필요'),
((SELECT id FROM ingredients WHERE slug='calcium'),    (SELECT id FROM claims WHERE claim_code='BONE_HEALTH'),       'A', '뼈 핵심 구성 성분',   true, 'KR', '뼈와 치아 형성에 필요'),
((SELECT id FROM ingredients WHERE slug='vitamin-b12'),(SELECT id FROM claims WHERE claim_code='RBC_FORMATION'),     'A', '적혈구 성숙 필수',    true, 'KR', '정상적인 적혈구 형성에 필요'),
((SELECT id FROM ingredients WHERE slug='vitamin-a'),  (SELECT id FROM claims WHERE claim_code='EYE_HEALTH'),        'A', '시각 기능 유지 필수', true, 'KR', '어두운 곳에서 시각 적응을 위해 필요'),
((SELECT id FROM ingredients WHERE slug='coq10'),      (SELECT id FROM claims WHERE claim_code='ANTIOXIDANT'),       'B', '미토콘드리아 항산화', false, NULL, NULL),
((SELECT id FROM ingredients WHERE slug='vitamin-e'),  (SELECT id FROM claims WHERE claim_code='ANTIOXIDANT'),       'A', '지용성 항산화제',     true, 'KR', '유해산소로부터 세포를 보호');

-- 안전성
INSERT INTO safety_items (ingredient_id, safety_type, title, description, severity_level, evidence_level, applies_to_population, management_advice) VALUES
((SELECT id FROM ingredients WHERE slug='vitamin-d'), 'overdose',         '비타민 D 과다복용',        '고칼슘혈증, 신장 손상 가능. 4,000IU 이상 장기 복용 주의.', 'serious',  'A', '성인', '혈중 25(OH)D 모니터링'),
((SELECT id FROM ingredients WHERE slug='vitamin-d'), 'drug_interaction', '비타민 D-이뇨제 상호작용', 'Thiazide 이뇨제 병용 시 고칼슘혈증 위험.',                  'moderate', 'B', '이뇨제 복용자', '칼슘 수치 정기 검사'),
((SELECT id FROM ingredients WHERE slug='omega-3'),   'adverse_effect',   '오메가-3 소화기 이상반응', '비린내, 트림, 소화불량, 설사 가능.',                        'mild',     'A', '성인', '식후 복용'),
((SELECT id FROM ingredients WHERE slug='omega-3'),   'drug_interaction', '오메가-3-항응고제',        '와파린 등 병용 시 출혈 위험 증가.',                         'serious',  'B', '항응고제 복용자', '담당의 상담'),
((SELECT id FROM ingredients WHERE slug='iron'),      'adverse_effect',   '철분 소화기 장애',         '변비, 구역, 위장 자극.',                                    'mild',     'A', '성인', '식후 복용'),
((SELECT id FROM ingredients WHERE slug='iron'),      'overdose',         '철분 과다복용',            '급성 중독(소아) 위험. 만성 과잉 시 장기 손상.',              'critical', 'A', '소아', '어린이 손 닿지 않는 곳 보관'),
((SELECT id FROM ingredients WHERE slug='vitamin-a'), 'pregnancy',        '비타민 A 임신 중 과다',   '레티놀 과다 시 태아 기형 위험. 10,000IU 이상 금지.',         'critical', 'A', '임산부', '베타카로틴 형태 권장'),
((SELECT id FROM ingredients WHERE slug='melatonin'), 'precaution',       '멜라토닌 주간 졸음',       '복용 후 졸음 발생. 운전·기계 조작 주의.',                   'moderate', 'A', '성인', '취침 30분~1시간 전 복용'),
((SELECT id FROM ingredients WHERE slug='magnesium'), 'adverse_effect',   '마그네슘 설사',            '고용량 시 삼투성 설사 가능.',                                'mild',     'A', '성인', '비스글리시네이트 형태 또는 분할 복용');

-- 용량 가이드라인
INSERT INTO dosage_guidelines (ingredient_id, population_group, indication_context, dose_min, dose_max, dose_unit, frequency_text, route, recommendation_type, notes) VALUES
((SELECT id FROM ingredients WHERE slug='vitamin-d'), '성인 (19~64세)', '일반 건강',    600,  2000, 'IU',      '1일 1회',   'oral', 'RDA', 'UL 4,000IU'),
((SELECT id FROM ingredients WHERE slug='vitamin-d'), '65세 이상',      '일반 건강',    800,  4000, 'IU',      '1일 1회',   'oral', 'RDA', 'UL 4,000IU'),
((SELECT id FROM ingredients WHERE slug='vitamin-c'), '성인',           '일반 건강',    100,  2000, 'mg',      '1일 1~2회', 'oral', 'RDA', 'UL 2,000mg'),
((SELECT id FROM ingredients WHERE slug='omega-3'),   '성인',           '혈중 중성지방',500,  2000, 'mg',      '1일 1~2회', 'oral', 'RDA', 'EPA+DHA 합계'),
((SELECT id FROM ingredients WHERE slug='magnesium'), '성인 남성',      '일반 건강',    350,  400,  'mg',      '1일 1~2회', 'oral', 'RDA', '원소 마그네슘 기준'),
((SELECT id FROM ingredients WHERE slug='magnesium'), '성인 여성',      '일반 건강',    280,  310,  'mg',      '1일 1~2회', 'oral', 'RDA', '원소 마그네슘 기준'),
((SELECT id FROM ingredients WHERE slug='zinc'),      '성인 남성',      '일반 건강',    8.5,  11,   'mg',      '1일 1회',   'oral', 'RDA', 'UL 40mg'),
((SELECT id FROM ingredients WHERE slug='iron'),      '성인 여성',      '빈혈 예방',    14,   18,   'mg',      '1일 1회',   'oral', 'RDA', 'UL 45mg'),
((SELECT id FROM ingredients WHERE slug='folate'),    '임산부',         '신경관 결손',  400,  800,  'mcg DFE', '1일 1회',   'oral', 'RDA', '임신 전~12주 특히 중요'),
((SELECT id FROM ingredients WHERE slug='probiotics'),'성인',           '장 건강',      1,    100,  '억 CFU',  '1일 1회',   'oral', 'AI',  '균주별 상이'),
((SELECT id FROM ingredients WHERE slug='lutein'),    '성인',           '눈 건강',      10,   20,   'mg',      '1일 1회',   'oral', 'AI',  'AREDS2 기준 10mg'),
((SELECT id FROM ingredients WHERE slug='calcium'),   '성인',           '뼈 건강',      700,  1000, 'mg',      '1일 1~2회', 'oral', 'RDA', '1회 500mg 이하 분할');

-- 제품 10개
INSERT INTO products (product_name, brand_name, manufacturer_name, country_code, product_type, status, is_published) VALUES
('종근당 칼슘 마그네슘 비타민D 아연',    '종근당건강',  '종근당건강',      'KR', 'health_functional_food', 'active', true),
('뉴트리원 루테인 오메가3',              '뉴트리원',    '뉴트리원',        'KR', 'health_functional_food', 'active', true),
('닥터린 멀티비타민 미네랄',              '닥터린',      '일동제약',        'KR', 'health_functional_food', 'active', true),
('솔가 비타민 D3 1000IU',               'Solgar',     'Solgar Inc.',     'US', 'dietary_supplement',     'active', true),
('나우푸드 오메가-3 1000mg',             'NOW Foods',  'NOW Health Group','US', 'dietary_supplement',     'active', true),
('네이처메이드 종합비타민',               'Nature Made','Pharmavite LLC',  'US', 'dietary_supplement',     'active', true),
('한미양행 프로바이오틱스 19 플러스',     '한미양행',    '한미양행',        'KR', 'health_functional_food', 'active', true),
('엘지생활건강 밀크씨슬 골드',           '엘지생건',    'LG생활건강',      'KR', 'health_functional_food', 'active', true),
('GNC 트리플 스트렝스 피쉬오일',         'GNC',        'GNC Holdings',    'US', 'dietary_supplement',     'active', true),
('세노비스 슈퍼바이오틱스 프로 100억',    '세노비스',    '대상웰라이프',    'KR', 'health_functional_food', 'active', true);

-- 제품-원료 연결
INSERT INTO product_ingredients (product_id, ingredient_id, amount_per_serving, amount_unit, ingredient_role, raw_label_name) VALUES
((SELECT id FROM products WHERE product_name LIKE '종근당 칼슘%'), (SELECT id FROM ingredients WHERE slug='calcium'),   500, 'mg', 'active', '탄산칼슘'),
((SELECT id FROM products WHERE product_name LIKE '종근당 칼슘%'), (SELECT id FROM ingredients WHERE slug='magnesium'), 150, 'mg', 'active', '산화마그네슘'),
((SELECT id FROM products WHERE product_name LIKE '종근당 칼슘%'), (SELECT id FROM ingredients WHERE slug='vitamin-d'), 400, 'IU', 'active', '콜레칼시페롤'),
((SELECT id FROM products WHERE product_name LIKE '종근당 칼슘%'), (SELECT id FROM ingredients WHERE slug='zinc'),      4.2, 'mg', 'active', '글루콘산아연'),
((SELECT id FROM products WHERE product_name LIKE '뉴트리원 루테인%'), (SELECT id FROM ingredients WHERE slug='lutein'),  20, 'mg', 'active', '마리골드꽃추출물(루테인)'),
((SELECT id FROM products WHERE product_name LIKE '뉴트리원 루테인%'), (SELECT id FROM ingredients WHERE slug='omega-3'), 600,'mg', 'active', '정제어유(EPA+DHA)'),
((SELECT id FROM products WHERE product_name LIKE '닥터린%'), (SELECT id FROM ingredients WHERE slug='vitamin-c'),   100, 'mg',  'active', '아스코르브산'),
((SELECT id FROM products WHERE product_name LIKE '닥터린%'), (SELECT id FROM ingredients WHERE slug='vitamin-d'),   400, 'IU',  'active', '콜레칼시페롤'),
((SELECT id FROM products WHERE product_name LIKE '닥터린%'), (SELECT id FROM ingredients WHERE slug='vitamin-b12'), 2.4, 'mcg', 'active', '시아노코발라민'),
((SELECT id FROM products WHERE product_name LIKE '닥터린%'), (SELECT id FROM ingredients WHERE slug='folate'),      400, 'mcg', 'active', '엽산'),
((SELECT id FROM products WHERE product_name LIKE '닥터린%'), (SELECT id FROM ingredients WHERE slug='zinc'),        8.5, 'mg',  'active', '글루콘산아연'),
((SELECT id FROM products WHERE product_name LIKE '닥터린%'), (SELECT id FROM ingredients WHERE slug='iron'),        12,  'mg',  'active', '퓨마르산제일철'),
((SELECT id FROM products WHERE product_name LIKE '닥터린%'), (SELECT id FROM ingredients WHERE slug='biotin'),      30,  'mcg', 'active', '비오틴'),
((SELECT id FROM products WHERE product_name LIKE '닥터린%'), (SELECT id FROM ingredients WHERE slug='selenium'),    55,  'mcg', 'active', '셀레노메티오닌'),
((SELECT id FROM products WHERE product_name LIKE '솔가%'), (SELECT id FROM ingredients WHERE slug='vitamin-d'), 1000, 'IU', 'active', 'Cholecalciferol (Vitamin D3)'),
((SELECT id FROM products WHERE product_name LIKE '나우푸드%'), (SELECT id FROM ingredients WHERE slug='omega-3'), 1000, 'mg', 'active', 'Fish Oil (EPA 360mg, DHA 240mg)'),
((SELECT id FROM products WHERE product_name LIKE '네이처메이드%'), (SELECT id FROM ingredients WHERE slug='vitamin-c'),   60,  'mg',  'active', 'Vitamin C'),
((SELECT id FROM products WHERE product_name LIKE '네이처메이드%'), (SELECT id FROM ingredients WHERE slug='vitamin-d'),   1000,'IU',  'active', 'Vitamin D3'),
((SELECT id FROM products WHERE product_name LIKE '네이처메이드%'), (SELECT id FROM ingredients WHERE slug='vitamin-b12'), 6,   'mcg', 'active', 'Vitamin B12'),
((SELECT id FROM products WHERE product_name LIKE '네이처메이드%'), (SELECT id FROM ingredients WHERE slug='vitamin-e'),   13.5,'mg',  'active', 'Vitamin E'),
((SELECT id FROM products WHERE product_name LIKE '네이처메이드%'), (SELECT id FROM ingredients WHERE slug='zinc'),        11,  'mg',  'active', 'Zinc'),
((SELECT id FROM products WHERE product_name LIKE '네이처메이드%'), (SELECT id FROM ingredients WHERE slug='iron'),        18,  'mg',  'active', 'Iron'),
((SELECT id FROM products WHERE product_name LIKE '네이처메이드%'), (SELECT id FROM ingredients WHERE slug='selenium'),    55,  'mcg', 'active', 'Selenium'),
((SELECT id FROM products WHERE product_name LIKE '한미양행%'), (SELECT id FROM ingredients WHERE slug='probiotics'), 100, '억 CFU', 'active', '프로바이오틱스 19종 혼합'),
((SELECT id FROM products WHERE product_name LIKE '엘지생활건강%'), (SELECT id FROM ingredients WHERE slug='milk-thistle'), 130, 'mg', 'active', '밀크씨슬추출물(실리마린)'),
((SELECT id FROM products WHERE product_name LIKE 'GNC%'), (SELECT id FROM ingredients WHERE slug='omega-3'), 1500, 'mg', 'active', 'Fish Oil (EPA 540mg, DHA 360mg)'),
((SELECT id FROM products WHERE product_name LIKE '세노비스%'), (SELECT id FROM ingredients WHERE slug='probiotics'), 100, '억 CFU', 'active', '프로바이오틱스 혼합');

-- 라벨 스냅샷
INSERT INTO label_snapshots (product_id, label_version, source_name, serving_size_text, servings_per_container, warning_text, directions_text, is_current) VALUES
((SELECT id FROM products WHERE product_name LIKE '종근당 칼슘%'), 'v1', '제품 패키지', '1일 1회, 1회 2정', '60정/30일분', '임산부·수유부·어린이·질환자는 섭취 전 전문가와 상담하십시오.', '1일 1회, 1회 2정을 물과 함께 섭취하십시오.', true),
((SELECT id FROM products WHERE product_name LIKE '솔가%'), 'v1', 'Product Label', '1 softgel daily', '100 softgels', 'If pregnant, nursing, or taking medication, consult your doctor.', 'Take one softgel daily with a meal.', true),
((SELECT id FROM products WHERE product_name LIKE '나우푸드%'), 'v1', 'Product Label', '2 softgels daily', '100 softgels', 'Consult physician if pregnant/nursing or have a medical condition.', 'Take 2 softgels 1 to 3 times daily with food.', true),
((SELECT id FROM products WHERE product_name LIKE '네이처메이드%'), 'v1', 'Product Label', '1 tablet daily', '300 tablets', 'If pregnant or nursing, ask a health professional before use.', 'Take one tablet daily with water and a meal.', true);

-- 출처
INSERT INTO sources (source_name, source_type, organization_name, source_url, country_code, trust_level, access_method) VALUES
('공공데이터포털 건강기능식품', 'government_db', '한국정보화진흥원',   'https://www.data.go.kr',            'KR', 'authoritative', 'api'),
('식품안전나라',               'government_db', '식품의약품안전처',   'https://www.foodsafetykorea.go.kr', 'KR', 'authoritative', 'api'),
('PubMed',                    'academic_db',   'NIH/NLM',          'https://pubmed.ncbi.nlm.nih.gov',   'US', 'authoritative', 'api'),
('NIH DSLD',                  'government_db', 'NIH ODS',          'https://dsld.od.nih.gov',           'US', 'authoritative', 'api'),
('DailyMed',                  'government_db', 'NIH/NLM',          'https://dailymed.nlm.nih.gov',      'US', 'authoritative', 'api'),
('openFDA',                   'government_db', 'FDA',              'https://open.fda.gov',              'US', 'authoritative', 'api'),
('제품 라벨 (브라우저 수집)',  'product_label', NULL,               NULL,                                 NULL, 'primary',       'browser_agent');

-- 추가 소스 3건
INSERT INTO sources (source_name, source_type, organization_name, source_url, country_code, trust_level, access_method, notes) VALUES
('MFDS 고시/가이드',             'regulator',      '식품의약품안전처',    'https://www.mfds.go.kr/',                          'KR', 'authoritative', 'hybrid',  '규제 고시, 인정 기준, 재평가 결과, 가이드라인 PDF.'),
('USDA FoodData Central',        'government_db',  'USDA',               'https://fdc.nal.usda.gov/',                         'US', 'authoritative', 'api',     '영양성분 DB (비타민, 미네랄, 생리활성물질).'),
('공공데이터포털 기능성원료인정', 'government_db',  '식품의약품안전처',    'https://www.data.go.kr/data/15058359/openapi.do',   'KR', 'authoritative', 'api',     '건강기능식품 기능성 원료 인정 현황.')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- source_links — 엔티티-출처 연결
-- ============================================================================

-- 원료 → 공공데이터포털
INSERT INTO source_links (source_id, entity_type, entity_id, source_reference, retrieved_at)
SELECT (SELECT id FROM sources WHERE source_name = '공공데이터포털 건강기능식품'),
       'ingredient', i.id, 'https://www.data.go.kr/data/15056760/openapi.do', '2026-03-12'::timestamp
FROM ingredients i WHERE i.is_active = true;

-- 원료 → 기능성원료인정
INSERT INTO source_links (source_id, entity_type, entity_id, source_reference, retrieved_at)
SELECT (SELECT id FROM sources WHERE source_name = '공공데이터포털 기능성원료인정'),
       'ingredient', i.id, 'https://www.data.go.kr/data/15058359/openapi.do', '2026-03-12'::timestamp
FROM ingredients i WHERE i.is_active = true;

-- 인정 기능성 → 공공데이터포털
INSERT INTO source_links (source_id, entity_type, entity_id, source_reference, retrieved_at)
SELECT (SELECT id FROM sources WHERE source_name = '공공데이터포털 건강기능식품'),
       'claim', c.id, 'https://www.data.go.kr/data/15056760/openapi.do', '2026-03-12'::timestamp
FROM claims c WHERE c.claim_scope = 'approved_kr';

-- 연구 기능성 → PubMed
INSERT INTO source_links (source_id, entity_type, entity_id, source_reference, retrieved_at)
SELECT (SELECT id FROM sources WHERE source_name = 'PubMed'),
       'claim', c.id, 'https://pubmed.ncbi.nlm.nih.gov/', '2026-03-16'::timestamp
FROM claims c WHERE c.claim_scope = 'studied';

-- 논문 → PubMed
INSERT INTO source_links (source_id, entity_type, entity_id, source_reference, source_excerpt, retrieved_at)
SELECT (SELECT id FROM sources WHERE source_name = 'PubMed'),
       'evidence_study', es.id,
       'https://pubmed.ncbi.nlm.nih.gov/' || es.pmid || '/',
       'PMID: ' || es.pmid || COALESCE(', DOI: ' || es.doi, ''),
       '2026-03-16'::timestamp
FROM evidence_studies es WHERE es.source_type = 'pubmed' AND es.pmid IS NOT NULL;

-- KR 제품 → 공공데이터포털
INSERT INTO source_links (source_id, entity_type, entity_id, source_reference, retrieved_at)
SELECT (SELECT id FROM sources WHERE source_name = '공공데이터포털 건강기능식품'),
       'product', p.id, 'https://www.data.go.kr/data/15056760/openapi.do', '2026-03-12'::timestamp
FROM products p WHERE p.country_code = 'KR';

-- KR 제품 → 식품안전나라
INSERT INTO source_links (source_id, entity_type, entity_id, source_reference, retrieved_at)
SELECT (SELECT id FROM sources WHERE source_name = '식품안전나라'),
       'product', p.id, 'https://www.foodsafetykorea.go.kr/api/main.do', '2026-03-12'::timestamp
FROM products p WHERE p.country_code = 'KR';

-- US 제품 → NIH DSLD
INSERT INTO source_links (source_id, entity_type, entity_id, source_reference, retrieved_at)
SELECT (SELECT id FROM sources WHERE source_name = 'NIH DSLD'),
       'product', p.id, 'https://dsld.od.nih.gov/', '2026-03-16'::timestamp
FROM products p WHERE p.country_code = 'US';

-- 안전성 → PubMed
INSERT INTO source_links (source_id, entity_type, entity_id, source_reference, retrieved_at)
SELECT (SELECT id FROM sources WHERE source_name = 'PubMed'),
       'safety_item', si.id, 'https://pubmed.ncbi.nlm.nih.gov/', '2026-03-16'::timestamp
FROM safety_items si WHERE si.evidence_level IN ('A', 'B', 'rct', 'observational');

-- 안전성(가이드라인) → MFDS
INSERT INTO source_links (source_id, entity_type, entity_id, source_reference, retrieved_at)
SELECT (SELECT id FROM sources WHERE source_name = 'MFDS 고시/가이드'),
       'safety_item', si.id, 'https://www.mfds.go.kr/', '2026-03-16'::timestamp
FROM safety_items si WHERE si.evidence_level = 'guideline';

-- 용량 가이드라인 → 공공데이터포털
INSERT INTO source_links (source_id, entity_type, entity_id, source_reference, retrieved_at)
SELECT (SELECT id FROM sources WHERE source_name = '공공데이터포털 건강기능식품'),
       'dosage_guideline', dg.id, 'https://www.data.go.kr/data/15056760/openapi.do', '2026-03-12'::timestamp
FROM dosage_guidelines dg;

-- 라벨 스냅샷 → 제품 라벨
INSERT INTO source_links (source_id, entity_type, entity_id, source_reference, retrieved_at)
SELECT (SELECT id FROM sources WHERE source_name = '제품 라벨 (브라우저 수집)'),
       'label_snapshot', ls.id, ls.source_name, '2026-03-12'::timestamp
FROM label_snapshots ls;

-- ============================================================================
-- ingredient_search_documents — 전 원료 검색 인덱스
-- ============================================================================

INSERT INTO ingredient_search_documents (ingredient_id, search_text, search_vector, updated_at)
SELECT
  i.id,
  COALESCE(i.canonical_name_ko, '') || ' ' ||
  COALESCE(i.canonical_name_en, '') || ' ' ||
  COALESCE(i.display_name, '') || ' ' ||
  COALESCE(i.scientific_name, '') || ' ' ||
  COALESCE(i.description, '') || ' ' ||
  COALESCE(i.form_description, '') || ' ' ||
  COALESCE((SELECT string_agg(syn.synonym, ' ') FROM ingredient_synonyms syn WHERE syn.ingredient_id = i.id), '') || ' ' ||
  COALESCE((SELECT string_agg(c.claim_name_ko || ' ' || COALESCE(c.claim_name_en, ''), ' ')
            FROM ingredient_claims ic JOIN claims c ON c.id = ic.claim_id WHERE ic.ingredient_id = i.id), '') || ' ' ||
  COALESCE((SELECT string_agg(si.title || ' ' || COALESCE(si.description, ''), ' ')
            FROM safety_items si WHERE si.ingredient_id = i.id), ''),
  to_tsvector('simple',
    COALESCE(i.canonical_name_ko, '') || ' ' ||
    COALESCE(i.canonical_name_en, '') || ' ' ||
    COALESCE(i.display_name, '') || ' ' ||
    COALESCE(i.scientific_name, '') || ' ' ||
    COALESCE(i.description, '') || ' ' ||
    COALESCE(i.form_description, '') || ' ' ||
    COALESCE((SELECT string_agg(syn.synonym, ' ') FROM ingredient_synonyms syn WHERE syn.ingredient_id = i.id), '') || ' ' ||
    COALESCE((SELECT string_agg(c.claim_name_ko || ' ' || COALESCE(c.claim_name_en, ''), ' ')
              FROM ingredient_claims ic JOIN claims c ON c.id = ic.claim_id WHERE ic.ingredient_id = i.id), '') || ' ' ||
    COALESCE((SELECT string_agg(si.title || ' ' || COALESCE(si.description, ''), ' ')
              FROM safety_items si WHERE si.ingredient_id = i.id), '')
  ),
  NOW()
FROM ingredients i
WHERE i.is_active = true
ON CONFLICT (ingredient_id) DO UPDATE SET
  search_text   = EXCLUDED.search_text,
  search_vector = EXCLUDED.search_vector,
  updated_at    = NOW();

-- ============================================================================
-- US 제품 라벨 스냅샷 (제조사 공식 사이트 기반)
-- ============================================================================

-- NOW Vitamin D3 5000 IU
INSERT INTO label_snapshots (product_id, label_version, source_name, serving_size_text, servings_per_container, warning_text, directions_text, is_current) VALUES
((SELECT id FROM products WHERE product_name = 'NOW Vitamin D3 5000 IU'),
 'v1', 'NOW Foods Official', '1 softgel', '240 softgels',
 'For adults only. Consult physician if pregnant/nursing, taking medication, or have a medical condition. Keep out of reach of children.',
 'Take 1 softgel daily with a fat-containing meal.', true)
ON CONFLICT DO NOTHING;

-- Citracal Calcium Citrate + D3
INSERT INTO label_snapshots (product_id, label_version, source_name, serving_size_text, servings_per_container, warning_text, directions_text, is_current) VALUES
((SELECT id FROM products WHERE product_name = 'Citracal Calcium Citrate + D3'),
 'v1', 'Citracal Official', '2 caplets', '60 caplets / 30 servings',
 'Ask a doctor before use if you have kidney disease. Do not exceed recommended dose. Keep out of reach of children.',
 'Take 2 caplets daily with or without food.', true)
ON CONFLICT DO NOTHING;

-- Doctor's Best Magnesium Glycinate 400mg
INSERT INTO label_snapshots (product_id, label_version, source_name, serving_size_text, servings_per_container, warning_text, directions_text, is_current) VALUES
((SELECT id FROM products WHERE product_name LIKE 'Doctor''s Best Magnesium%'),
 'v1', 'Doctor''s Best Official', '2 tablets', '120 tablets / 60 servings',
 'If you are pregnant, nursing, taking any medications or have any medical condition, consult your doctor before use.',
 'Take 2 tablets daily, preferably with food.', true)
ON CONFLICT DO NOTHING;

-- Thorne Zinc Picolinate 30mg
INSERT INTO label_snapshots (product_id, label_version, source_name, serving_size_text, servings_per_container, warning_text, directions_text, is_current) VALUES
((SELECT id FROM products WHERE product_name = 'Thorne Zinc Picolinate 30mg'),
 'v1', 'Thorne Official', '1 capsule', '60 capsules',
 'If pregnant, consult your health-care practitioner before using this product.',
 'Take 1 capsule one to two times daily.', true)
ON CONFLICT DO NOTHING;

-- Thorne Iron Bisglycinate 25mg
INSERT INTO label_snapshots (product_id, label_version, source_name, serving_size_text, servings_per_container, warning_text, directions_text, is_current) VALUES
((SELECT id FROM products WHERE product_name = 'Thorne Iron Bisglycinate 25mg'),
 'v1', 'Thorne Official', '1 capsule', '60 capsules',
 'WARNING: Accidental overdose of iron-containing products is a leading cause of fatal poisoning in children under 6. Keep this product out of reach of children.',
 'Take 1 capsule one to two times daily. Best absorbed on an empty stomach.', true)
ON CONFLICT DO NOTHING;

-- Nature Made Super B-Complex
INSERT INTO label_snapshots (product_id, label_version, source_name, serving_size_text, servings_per_container, warning_text, directions_text, is_current) VALUES
((SELECT id FROM products WHERE product_name = 'Nature Made Super B-Complex'),
 'v1', 'Nature Made Official', '1 tablet', '140 tablets',
 'If you are pregnant or nursing, ask a health professional before use.',
 'Take one tablet daily with water and a meal.', true)
ON CONFLICT DO NOTHING;

-- Nature's Bounty Milk Thistle 250mg
INSERT INTO label_snapshots (product_id, label_version, source_name, serving_size_text, servings_per_container, warning_text, directions_text, is_current) VALUES
((SELECT id FROM products WHERE product_name LIKE 'Nature''s Bounty Milk Thistle%'),
 'v1', 'Nature''s Bounty Official', '1 capsule', '200 capsules',
 'If you are pregnant, nursing, taking any medications or have any medical condition, consult your doctor before use. Discontinue use and consult your doctor if any adverse reactions occur.',
 'For adults, take one (1) capsule three times daily, preferably with a meal.', true)
ON CONFLICT DO NOTHING;

-- Qunol Ultra CoQ10 200mg
INSERT INTO label_snapshots (product_id, label_version, source_name, serving_size_text, servings_per_container, warning_text, directions_text, is_current) VALUES
((SELECT id FROM products WHERE product_name = 'Qunol Ultra CoQ10 200mg'),
 'v1', 'Qunol Official', '1 softgel', '120 softgels',
 'If you are pregnant, nursing, or taking medications (especially blood thinners), consult your physician before use.',
 'Adults take one (1) softgel daily with food.', true)
ON CONFLICT DO NOTHING;

-- Vital Proteins Collagen Peptides
INSERT INTO label_snapshots (product_id, label_version, source_name, serving_size_text, servings_per_container, warning_text, directions_text, is_current) VALUES
((SELECT id FROM products WHERE product_name = 'Vital Proteins Collagen Peptides'),
 'v1', 'Vital Proteins Official', '2 scoops (20g)', '28 servings (567g)',
 'Contains: Fish (wild-caught whitefish). If you are pregnant, nursing, or have a medical condition, consult your physician before use.',
 'Add two (2) scoops to 8+ oz of any hot or cold liquid. Mix until dissolved.', true)
ON CONFLICT DO NOTHING;

-- Optimum Nutrition Creatine Monohydrate
INSERT INTO label_snapshots (product_id, label_version, source_name, serving_size_text, servings_per_container, warning_text, directions_text, is_current) VALUES
((SELECT id FROM products WHERE product_name = 'Optimum Nutrition Creatine Monohydrate'),
 'v1', 'Optimum Nutrition Official', '1 rounded teaspoon (5g)', '60 servings (300g)',
 'Consult a medical doctor before use if you have been treated for or diagnosed with any medical condition. Not for use by those under 18.',
 'Mix one rounded teaspoon with your protein shake or juice. On training days, consume before or after exercise.', true)
ON CONFLICT DO NOTHING;

-- Nature Made Turmeric Curcumin 500mg
INSERT INTO label_snapshots (product_id, label_version, source_name, serving_size_text, servings_per_container, warning_text, directions_text, is_current) VALUES
((SELECT id FROM products WHERE product_name = 'Nature Made Turmeric Curcumin 500mg'),
 'v1', 'Nature Made Official', '1 capsule', '60 capsules',
 'If you are pregnant or nursing, ask a health professional before use. If you are taking blood thinners, consult your doctor before use.',
 'Take one capsule daily with water and a meal.', true)
ON CONFLICT DO NOTHING;

-- Culturelle Daily Probiotic
INSERT INTO label_snapshots (product_id, label_version, source_name, serving_size_text, servings_per_container, warning_text, directions_text, is_current) VALUES
((SELECT id FROM products WHERE product_name = 'Culturelle Daily Probiotic'),
 'v1', 'Culturelle Official', '1 capsule', '30 capsules',
 'If you are pregnant, nursing, or taking a prescription drug, including immunosuppressants, consult your doctor before use.',
 'Take one (1) capsule daily. May be taken with or without food.', true)
ON CONFLICT DO NOTHING;

-- CheongKwanJang Korean Red Ginseng Extract
INSERT INTO label_snapshots (product_id, label_version, source_name, serving_size_text, servings_per_container, warning_text, directions_text, is_current) VALUES
((SELECT id FROM products WHERE product_name = 'CheongKwanJang Korean Red Ginseng Extract'),
 'v1', 'CheongKwanJang Official (US)', '1 pouch (10mL)', '30 pouches',
 'Not intended for use by children. If you are pregnant, nursing, taking medication or have any medical condition, consult a physician before use.',
 'Take one (1) pouch daily. May be taken straight or mixed with water. Best consumed on an empty stomach.', true)
ON CONFLICT DO NOTHING;

-- Doctor's Best OptiMSM 1500mg
INSERT INTO label_snapshots (product_id, label_version, source_name, serving_size_text, servings_per_container, warning_text, directions_text, is_current) VALUES
((SELECT id FROM products WHERE product_name LIKE 'Doctor''s Best OptiMSM%'),
 'v1', 'Doctor''s Best Official', '1 tablet', '120 tablets',
 'If you are pregnant, nursing, taking any medications or have any medical condition, consult your doctor before use.',
 'Take 1 tablet twice daily, or as recommended by a nutritionally-informed physician.', true)
ON CONFLICT DO NOTHING;

-- Nature's Bounty Garcinia Cambogia 1000mg
INSERT INTO label_snapshots (product_id, label_version, source_name, serving_size_text, servings_per_container, warning_text, directions_text, is_current) VALUES
((SELECT id FROM products WHERE product_name LIKE 'Nature''s Bounty Garcinia Cambogia%'),
 'v1', 'Nature''s Bounty Official', '2 capsules', '60 capsules / 30 servings',
 'Do not use if you are pregnant, nursing, or taking prescription drugs without first consulting your doctor. Discontinue use two weeks prior to surgery.',
 'For adults, take two (2) capsules 30 to 60 minutes before your two largest meals. Do not exceed four (4) capsules per day.', true)
ON CONFLICT DO NOTHING;

-- US 라벨 → source_links 연결
INSERT INTO source_links (source_id, entity_type, entity_id, source_reference, retrieved_at)
SELECT (SELECT id FROM sources WHERE source_name = '제품 라벨 (브라우저 수집)'),
       'label_snapshot', ls.id, ls.source_name, '2026-03-16'::timestamp
FROM label_snapshots ls
JOIN products p ON p.id = ls.product_id
WHERE p.country_code = 'US'
  AND NOT EXISTS (SELECT 1 FROM source_links sl WHERE sl.entity_type = 'label_snapshot' AND sl.entity_id = ls.id);

-- ============================================================================
-- 013: 연구 근거 보강 — claim 연결, 정량 데이터, 누락 기능성 추가
-- ============================================================================

-- 신규 claims (5종)
INSERT INTO claims (claim_code, claim_name_ko, claim_name_en, claim_category, claim_scope, description) VALUES
('COGNITIVE_FUNCTION', '인지 기능 개선에 도움',       'Cognitive Function',    'brain',          'studied',     '인지 기능 유지 및 치매 위험 감소 연구'),
('BLOOD_SUGAR',        '혈당 조절에 도움',            'Blood Sugar Regulation','metabolic',      'studied',     '혈당 조절 및 당뇨 위험 감소 연구'),
('MUSCLE_STRENGTH',    '근력 및 운동 수행에 도움',    'Muscle & Exercise',     'musculoskeletal','studied',     '근력 향상 및 운동 수행 능력 연구'),
('WEIGHT_MANAGEMENT',  '체중 조절에 도움',            'Weight Management',     'metabolic',      'studied',     '체중 및 체지방 감소 연구'),
('MENTAL_HEALTH',      '정신 건강에 도움',            'Mental Health',         'brain',          'studied',     '우울·불안 등 정신 건강 관련 연구')
ON CONFLICT (claim_code) DO NOTHING;

-- 누락된 ingredient_claims (16건)
INSERT INTO ingredient_claims (ingredient_id, claim_id, evidence_grade, evidence_summary, is_regulator_approved, approval_country_code, allowed_expression) VALUES
((SELECT id FROM ingredients WHERE slug='vitamin-d'),
 (SELECT id FROM claims WHERE claim_code='BLOOD_SUGAR'),
 'B', '전당뇨 환자 대상 메타분석: 당뇨 발생 위험 15% 감소 (HR 0.85)', false, NULL, NULL),
((SELECT id FROM ingredients WHERE slug='vitamin-b12'),
 (SELECT id FROM claims WHERE claim_code='COGNITIVE_FUNCTION'),
 'C', 'B12 단독 효과 제한적; B군 비타민 복합 보충 시 인지 저하 완화 가능성', false, NULL, NULL),
((SELECT id FROM ingredients WHERE slug='omega-3'),
 (SELECT id FROM claims WHERE claim_code='COGNITIVE_FUNCTION'),
 'B', 'DHA 섭취가 인지 저하 위험 ~20% 감소; 장기 보충 시 AD 위험 64% 감소', false, NULL, NULL),
((SELECT id FROM ingredients WHERE slug='magnesium'),
 (SELECT id FROM claims WHERE claim_code='SLEEP_AID'),
 'B', '노인 불면증 대상: 수면 잠복기 17분 단축 (P=0.0006). 근거 질 낮음', false, NULL, NULL),
((SELECT id FROM ingredients WHERE slug='magnesium'),
 (SELECT id FROM claims WHERE claim_code='MUSCLE_STRENGTH'),
 'C', '운동선수·건강인에서 유의한 효과 없음. 결핍 노인에서만 유익', false, NULL, NULL),
((SELECT id FROM ingredients WHERE slug='creatine'),
 (SELECT id FROM claims WHERE claim_code='MUSCLE_STRENGTH'),
 'A', '다수 메타분석에서 고강도 운동 시 근력·파워 출력 향상 확인', false, NULL, NULL),
((SELECT id FROM ingredients WHERE slug='collagen'),
 (SELECT id FROM claims WHERE claim_code='SKIN_HEALTH'),
 'B', '콜라겐 펩타이드 보충이 피부 탄력·수분 개선에 기여', false, NULL, NULL),
((SELECT id FROM ingredients WHERE slug='collagen'),
 (SELECT id FROM claims WHERE claim_code='JOINT_HEALTH'),
 'C', '관절 통증 감소에 소폭 기여; 대규모 근거 부족', false, NULL, NULL),
((SELECT id FROM ingredients WHERE slug='red-ginseng'),
 (SELECT id FROM claims WHERE claim_code='IMMUNE_FUNCTION'),
 'B', '홍삼이 면역 세포(NK 세포 등) 활성화에 기여', true, 'KR', '면역력 증진에 도움'),
((SELECT id FROM ingredients WHERE slug='red-ginseng'),
 (SELECT id FROM claims WHERE claim_code='ENERGY_METABOLISM'),
 'B', '홍삼의 항피로 효과 다수 임상 확인', true, 'KR', '피로 개선에 도움'),
((SELECT id FROM ingredients WHERE slug='msm'),
 (SELECT id FROM claims WHERE claim_code='JOINT_HEALTH'),
 'C', '골관절염 통증 감소에 소폭 기여; 근거 규모 제한적', false, NULL, NULL),
((SELECT id FROM ingredients WHERE slug='garcinia'),
 (SELECT id FROM claims WHERE claim_code='WEIGHT_MANAGEMENT'),
 'D', 'HCA의 체중 감소 효과가 소규모이며 임상적 유의성 논란', false, NULL, NULL),
((SELECT id FROM ingredients WHERE slug='coq10'),
 (SELECT id FROM claims WHERE claim_code='CARDIOVASCULAR'),
 'B', 'CoQ10이 심부전 환자의 운동 능력·증상 개선에 기여', false, NULL, NULL),
((SELECT id FROM ingredients WHERE slug='zinc'),
 (SELECT id FROM claims WHERE claim_code='MENTAL_HEALTH'),
 'B', 'WFSBP/CANMAT 가이드라인: 보조적 아연이 단극성 우울증에 잠정 권장(++)', false, NULL, NULL)
ON CONFLICT (ingredient_id, claim_id, approval_country_code) DO NOTHING;

-- evidence_outcomes: claim_id 매핑 + 정량 데이터 + 설명 교정

-- vitamin-d (PMID 31405892): 원래 '골밀도' → 실제: 사망률·암 사망
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'IMMUNE_FUNCTION'),
  outcome_name = '전체 사망률 및 암 사망 위험',
  outcome_type = 'efficacy', effect_direction = 'positive',
  conclusion_summary = '비타민 D 보충이 전체 사망률에 유의한 효과 없으나 (RR 0.98), 암 사망 위험을 16% 감소 (RR 0.84). 비타민 D3가 D2보다 우수한 경향',
  effect_size_text = 'RR 0.98 (전체 사망), RR 0.84 (암 사망)',
  p_value_text = '전체 사망: NS; 암 사망: P<0.05',
  confidence_interval_text = '전체: 0.95-1.02; 암: 0.74-0.95'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '31405892' LIMIT 1);

-- vitamin-d (PMID 36745886): 원래 '골밀도' → 실제: 전당뇨→당뇨 예방
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'BLOOD_SUGAR'),
  outcome_name = '전당뇨 환자의 당뇨 발생 위험 감소',
  outcome_type = 'efficacy', effect_direction = 'positive',
  conclusion_summary = '비타민 D가 전당뇨 환자의 당뇨 발생 위험을 15% 감소 (HR 0.85). 혈중 25(OH)D ≥125nmol/L 도달 시 76% 감소. 정상 혈당 복귀 30% 증가',
  effect_size_text = 'HR 0.85 (당뇨 발생); ARR 3.3% (3년)',
  p_value_text = 'P<0.05',
  confidence_interval_text = 'HR: 0.75-0.96; ARR: 0.6%-6.0%'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '36745886' LIMIT 1);

-- vitamin-c (PMID 34967304)
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'IMMUNE_FUNCTION'),
  outcome_name = '호흡기 감염 기간 단축',
  conclusion_summary = '비타민 C가 호흡기 감염 발생에는 유의한 효과 없으나 (RR 0.94, P=0.09), 감염 기간을 유의하게 단축 (SMD -0.36, P=0.01)',
  effect_size_text = 'RR 0.94 (발생); SMD -0.36 (기간)',
  p_value_text = '발생: P=0.09 (NS); 기간: P=0.01',
  confidence_interval_text = '발생: 0.87-1.01; 기간: -0.62 to -0.09'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '34967304' LIMIT 1);

-- vitamin-c (PMID 37682265)
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'IMMUNE_FUNCTION'),
  outcome_name = 'COVID-19 환자 염증 반응 완화',
  conclusion_summary = '고용량 비타민 C가 COVID-19 환자의 페리틴·림프구 수치 개선 및 질병 악화 억제 (OR 0.344, P=0.025)',
  effect_size_text = 'SMD 0.376 (림프구); OR 0.344 (악화 억제)',
  p_value_text = '림프구: P=0.001; 악화: P=0.025; ICU: P=0.004',
  confidence_interval_text = '림프구: 0.153-0.599; 악화: 0.135-0.873'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '37682265' LIMIT 1);

-- vitamin-b12 (PMID 33809274): 원래 '혈중 B12' → 실제: 인지·우울 효과 없음
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'COGNITIVE_FUNCTION'),
  outcome_name = '인지 기능 및 우울 증상 (효과 제한적)',
  effect_direction = 'neutral',
  conclusion_summary = 'B12 단독 또는 B복합 보충이 인지 기능·우울 증상에 유의한 효과 없음. 신경 장애 없는 대상에서 보충 효과 제한적 (16 RCTs, 6,276명)',
  effect_size_text = '인지·우울 전 영역 NS',
  p_value_text = 'NS (모든 하위 분석)',
  confidence_interval_text = '-'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '33809274' LIMIT 1);

-- vitamin-b12 (PMID 34432056): 원래 '혈중 B12' → 실제: B군·인지 저하
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'COGNITIVE_FUNCTION'),
  outcome_name = '인지 저하 및 치매 예방 (B군 비타민)',
  effect_direction = 'positive',
  conclusion_summary = 'B군 비타민이 MMSE 점수 저하를 완화 (MD 0.14). 12개월 이상 비치매 대상에서 유효. 엽산 결핍·고호모시스테인이 치매 위험 증가와 연관',
  effect_size_text = 'MD 0.14 (MMSE)',
  p_value_text = '-',
  confidence_interval_text = '0.04-0.23'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '34432056' LIMIT 1);

-- folate (PMID 36321557)
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'NEURAL_TUBE'),
  outcome_name = '엽산·말라리아 감수성 (항말라리아제 병용)',
  conclusion_summary = '말라리아 유행 지역에서 엽산 보충과 항말라리아제(SP) 병용에 대한 코크란 체계적 문헌고찰. 임산부 엽산 400μg/일 권고 유지'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '36321557' LIMIT 1);

-- folate (PMID 39145520)
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'RBC_FORMATION'),
  outcome_name = '임산부 빈혈 예방 (철분+엽산)',
  conclusion_summary = '임산부 철분 보충이 빈혈 유의하게 감소 (RR 0.30). 저체중아 출산 감소 (RR 0.84). 57개 시험, 48,971명',
  effect_size_text = 'RR 0.30 (빈혈); RR 0.84 (저체중아)',
  p_value_text = '-',
  confidence_interval_text = '빈혈: 0.20-0.47; 저체중아: 0.72-0.99'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '39145520' LIMIT 1);

-- omega-3 (PMID 37028557): 원래 '중성지방' → 실제: 인지·치매
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'COGNITIVE_FUNCTION'),
  outcome_name = '오메가-3와 인지 기능 저하·치매 예방',
  conclusion_summary = 'DHA 섭취가 인지 저하 위험 ~20% 감소 (RR 0.82, P=0.001). 장기 보충 시 AD 위험 64% 감소 (HR 0.36, P=0.004)',
  effect_size_text = 'HR 0.36 (AD, 장기 보충); RR 0.82 (DHA 인지 저하)',
  p_value_text = 'AD: P=0.004; DHA: P=0.001; 용량반응: P<0.0005',
  confidence_interval_text = 'AD: 0.18-0.72; DHA: I²=63.6%'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '37028557' LIMIT 1);

-- omega-3 (PMID 32114706): 원래 '중성지방' → 실제: 심혈관 예방 (코크란)
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'CARDIOVASCULAR'),
  outcome_name = '오메가-3와 심혈관 질환 예방',
  conclusion_summary = '86개 RCT (162,796명). 전체 사망률에 미미한 효과 (RR 0.97, 고확실성). 관상동맥 사건 소폭 감소 (RR 0.91, NNT 167)',
  effect_size_text = 'RR 0.97 (전체 사망); RR 0.91 (CHD 사건)',
  p_value_text = '-',
  confidence_interval_text = '사망: 0.93-1.01; CHD: 0.85-0.97'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '32114706' LIMIT 1);

-- magnesium (PMID 33865376): 원래 '혈압' → 실제: 수면 잠복기
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'SLEEP_AID'),
  outcome_name = '마그네슘과 노인 불면증 (수면 잠복기)',
  conclusion_summary = '마그네슘 보충이 수면 잠복기를 17.36분 단축 (P=0.0006). 총 수면시간 16분 증가 (비유의). 3개 RCT, 151명',
  effect_size_text = '-17.36분 (수면 잠복기); +16.06분 (총 수면시간, NS)',
  p_value_text = '잠복기: P=0.0006; 수면시간: NS',
  confidence_interval_text = '잠복기: -27.27 to -7.44'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '33865376' LIMIT 1);

-- magnesium (PMID 29637897): 원래 '혈압' → 실제: 근육 기능
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'MUSCLE_STRENGTH'),
  outcome_name = '마그네슘과 근육 기능',
  conclusion_summary = '운동선수·건강인에서 유의한 근력 개선 없음 (WMD 0.87, NS). 마그네슘 결핍 노인·알코올 중독자에서 유익. 14개 RCT, 542명',
  effect_size_text = 'WMD 0.87 (등속 최대 토크, NS); WMD 3.28 (근파워, NS)',
  p_value_text = 'NS (운동선수/건강인); 노인/결핍군에서 유의',
  confidence_interval_text = '토크: -1.43 to 3.18; 파워: -14.94 to 21.50'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '29637897' LIMIT 1);

-- zinc (PMID 35311615): 원래 '감기' → 실제: 정신 건강 가이드라인
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'MENTAL_HEALTH'),
  outcome_name = '아연과 정신 건강 (WFSBP/CANMAT 가이드라인)',
  conclusion_summary = '31개국 전문가 31인 참여 임상 가이드라인. 보조적 아연이 단극성 우울증에 잠정 권장(++)',
  effect_size_text = '권장 등급: ++ (Provisionally Recommended)',
  p_value_text = 'Grade A evidence (메타분석/2+ RCTs 기반)',
  confidence_interval_text = '-'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '35311615' LIMIT 1);

-- zinc (PMID 39683510): 원래 '감기' → 실제: 생리통 완화
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'IMMUNE_FUNCTION'),
  outcome_name = '아연과 생리통(월경통) 완화',
  conclusion_summary = '아연 보충이 일차성 월경통의 통증 강도를 유의하게 감소 (Hedges g=-1.541, P<0.001). 8주 이상 복용 시 효과 증대. 6개 RCT, 739명',
  effect_size_text = 'Hedges g = -1.541 (통증 강도)',
  p_value_text = 'P<0.001; 기간: P=0.003; 용량: P=0.005',
  confidence_interval_text = '-2.268 to -0.814'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '39683510' LIMIT 1);

-- iron (PMID 36728680)
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'RBC_FORMATION'),
  outcome_name = '비스글리시네이트 철분의 헤모글로빈 개선',
  conclusion_summary = '비스글리시네이트 철분이 다른 철분 제제 대비 임산부 헤모글로빈 더 높이 증가 (SMD 0.54, P<0.01) 및 위장 부작용 감소 (IRR 0.36, P<0.01)',
  effect_size_text = 'SMD 0.54 g/dL (Hb, 임산부)',
  p_value_text = 'Hb: P<0.01; 부작용: P<0.01',
  confidence_interval_text = 'Hb: 0.15-0.94; 부작용 IRR: 0.17-0.76'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '36728680' LIMIT 1);

-- 나머지 outcome → claim 매핑 (정량 데이터 없이 claim_id만)
UPDATE evidence_outcomes SET claim_id = (SELECT id FROM claims WHERE claim_code = 'RBC_FORMATION')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '39951396' LIMIT 1);
UPDATE evidence_outcomes SET claim_id = (SELECT id FROM claims WHERE claim_code = 'BONE_HEALTH')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '33237064' LIMIT 1);
UPDATE evidence_outcomes SET claim_id = (SELECT id FROM claims WHERE claim_code = 'BONE_HEALTH')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '26510847' LIMIT 1);
UPDATE evidence_outcomes SET claim_id = (SELECT id FROM claims WHERE claim_code = 'GUT_HEALTH')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '31004628' LIMIT 1);
UPDATE evidence_outcomes SET claim_id = (SELECT id FROM claims WHERE claim_code = 'GUT_HEALTH')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '37168869' LIMIT 1);
UPDATE evidence_outcomes SET claim_id = (SELECT id FROM claims WHERE claim_code = 'EYE_HEALTH')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '37702300' LIMIT 1);
UPDATE evidence_outcomes SET claim_id = (SELECT id FROM claims WHERE claim_code = 'EYE_HEALTH')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '33998846' LIMIT 1);
UPDATE evidence_outcomes SET claim_id = (SELECT id FROM claims WHERE claim_code = 'CARDIOVASCULAR')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '39019217' LIMIT 1);
UPDATE evidence_outcomes SET claim_id = (SELECT id FROM claims WHERE claim_code = 'CARDIOVASCULAR')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '39129455' LIMIT 1);
UPDATE evidence_outcomes SET claim_id = (SELECT id FROM claims WHERE claim_code = 'LIVER_HEALTH')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '38579127' LIMIT 1);
UPDATE evidence_outcomes SET claim_id = (SELECT id FROM claims WHERE claim_code = 'LIVER_HEALTH')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '32065376' LIMIT 1);
UPDATE evidence_outcomes SET claim_id = (SELECT id FROM claims WHERE claim_code = 'JOINT_HEALTH')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '36142319' LIMIT 1);
UPDATE evidence_outcomes SET claim_id = (SELECT id FROM claims WHERE claim_code = 'JOINT_HEALTH')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '35024906' LIMIT 1);
UPDATE evidence_outcomes SET claim_id = (SELECT id FROM claims WHERE claim_code = 'HAIR_NAIL')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '33171595' LIMIT 1);
UPDATE evidence_outcomes SET claim_id = (SELECT id FROM claims WHERE claim_code = 'HAIR_NAIL')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '38688776' LIMIT 1);
UPDATE evidence_outcomes SET claim_id = (SELECT id FROM claims WHERE claim_code = 'THYROID_FUNCTION')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '38243784' LIMIT 1);
UPDATE evidence_outcomes SET claim_id = (SELECT id FROM claims WHERE claim_code = 'THYROID_FUNCTION')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '39698034' LIMIT 1);
UPDATE evidence_outcomes SET claim_id = (SELECT id FROM claims WHERE claim_code = 'EYE_HEALTH')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '35294044' LIMIT 1);
UPDATE evidence_outcomes SET claim_id = (SELECT id FROM claims WHERE claim_code = 'EYE_HEALTH')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '8426449' LIMIT 1);
UPDATE evidence_outcomes SET claim_id = (SELECT id FROM claims WHERE claim_code = 'ANTIOXIDANT')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '15537682' LIMIT 1);
UPDATE evidence_outcomes SET claim_id = (SELECT id FROM claims WHERE claim_code = 'ANTIOXIDANT')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '37698992' LIMIT 1);
UPDATE evidence_outcomes SET claim_id = (SELECT id FROM claims WHERE claim_code = 'ANTI_INFLAMMATORY')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '35935936' LIMIT 1);
UPDATE evidence_outcomes SET claim_id = (SELECT id FROM claims WHERE claim_code = 'ANTI_INFLAMMATORY')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '36804260' LIMIT 1);
UPDATE evidence_outcomes SET claim_id = (SELECT id FROM claims WHERE claim_code = 'SLEEP_AID')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '33417003' LIMIT 1);
UPDATE evidence_outcomes SET claim_id = (SELECT id FROM claims WHERE claim_code = 'SLEEP_AID')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '35843245' LIMIT 1);
UPDATE evidence_outcomes SET claim_id = (SELECT id FROM claims WHERE claim_code = 'IMMUNE_FUNCTION')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '39474788' LIMIT 1);
UPDATE evidence_outcomes SET claim_id = (SELECT id FROM claims WHERE claim_code = 'IMMUNE_FUNCTION')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '29624410' LIMIT 1);
UPDATE evidence_outcomes SET claim_id = (SELECT id FROM claims WHERE claim_code = 'JOINT_HEALTH')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '29018060' LIMIT 1);
UPDATE evidence_outcomes SET claim_id = (SELECT id FROM claims WHERE claim_code = 'JOINT_HEALTH')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '35545381' LIMIT 1);
UPDATE evidence_outcomes SET claim_id = (SELECT id FROM claims WHERE claim_code = 'WEIGHT_MANAGEMENT')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '38151892' LIMIT 1);
UPDATE evidence_outcomes SET claim_id = (SELECT id FROM claims WHERE claim_code = 'WEIGHT_MANAGEMENT')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '38876392' LIMIT 1);
UPDATE evidence_outcomes SET claim_id = (SELECT id FROM claims WHERE claim_code = 'SKIN_HEALTH')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '33742704' LIMIT 1);
UPDATE evidence_outcomes SET claim_id = (SELECT id FROM claims WHERE claim_code = 'SKIN_HEALTH')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '34491424' LIMIT 1);
UPDATE evidence_outcomes SET claim_id = (SELECT id FROM claims WHERE claim_code = 'MUSCLE_STRENGTH')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '31375416' LIMIT 1);
UPDATE evidence_outcomes SET claim_id = (SELECT id FROM claims WHERE claim_code = 'MUSCLE_STRENGTH')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '35984306' LIMIT 1);

-- evidence_studies 메타데이터 보강 (sample_size, population, duration)
UPDATE evidence_studies SET sample_size = 75454, population_text = '성인 (52개 RCT 통합)', duration_text = 'RCT 통합 (기간 다양)' WHERE pmid = '31405892';
UPDATE evidence_studies SET population_text = '전당뇨 성인', duration_text = '3년 추적' WHERE pmid = '36745886';
UPDATE evidence_studies SET population_text = '성인', duration_text = '연구 기간 다양' WHERE pmid = '34967304';
UPDATE evidence_studies SET sample_size = 2334, population_text = 'COVID-19 환자 (7 RCT + 7 후향적)', duration_text = '입원 기간' WHERE pmid = '37682265';
UPDATE evidence_studies SET sample_size = 6276, population_text = '신경 장애 없는 성인 (16 RCTs)', duration_text = '연구 기간 다양' WHERE pmid = '33809274';
UPDATE evidence_studies SET sample_size = 46175, population_text = '성인 (25 RCTs, 20 코호트, 50 횡단면)', duration_text = '>12개월 (유효 기간)' WHERE pmid = '34432056';
UPDATE evidence_studies SET sample_size = 103651, population_text = '비치매 성인 (평균 73세)', duration_text = '6년 추적 (ADNI 코호트)' WHERE pmid = '37028557';
UPDATE evidence_studies SET sample_size = 162796, population_text = '심혈관 위험도 다양한 성인 (86 RCTs)', duration_text = '12-88개월' WHERE pmid = '32114706';
UPDATE evidence_studies SET sample_size = 151, population_text = '불면증 있는 노인 (3 RCTs)', duration_text = '연구별 상이' WHERE pmid = '33865376';
UPDATE evidence_studies SET sample_size = 542, population_text = '운동선수 215명, 비훈련 건강인 95명, 노인/알코올 중독자 232명', duration_text = '연구별 상이' WHERE pmid = '29637897';
UPDATE evidence_studies SET population_text = '정신 질환 환자 (31개국 전문가 31인 가이드라인)', duration_text = '2019-2021 (가이드라인 개발)' WHERE pmid = '35311615';
UPDATE evidence_studies SET sample_size = 739, population_text = '일차성 월경통 여성 (6 RCTs)', duration_text = '≥8주 복용 시 효과 증대' WHERE pmid = '39683510';
UPDATE evidence_studies SET population_text = '임산부 및 아동 (17 RCTs)', duration_text = '4-20주' WHERE pmid = '36728680';
UPDATE evidence_studies SET sample_size = 48971, population_text = '임산부 (57개 시험)', duration_text = '임신 기간' WHERE pmid = '39145520';

-- ============================================================================
-- 015: 연구 근거 보강 Phase 2 — 정량 데이터 + claim_id 교정
-- ============================================================================

-- claim_id 매핑 교정 (논문 실제 내용 기반)
UPDATE evidence_outcomes SET claim_id = (SELECT id FROM claims WHERE claim_code = 'COGNITIVE_FUNCTION')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '39474788' LIMIT 1);
UPDATE evidence_outcomes SET claim_id = (SELECT id FROM claims WHERE claim_code = 'ENERGY_METABOLISM')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '29624410' LIMIT 1);
UPDATE evidence_outcomes SET claim_id = (SELECT id FROM claims WHERE claim_code = 'COGNITIVE_FUNCTION')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '35984306' LIMIT 1);
UPDATE evidence_outcomes SET claim_id = (SELECT id FROM claims WHERE claim_code = 'MENTAL_HEALTH')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '33171595' LIMIT 1);

-- evidence_outcomes 정량 데이터 보강 (36건)
UPDATE evidence_outcomes SET outcome_name = '소아·청소년 철결핍빈혈의 철분 보충 효과', outcome_type = 'efficacy', effect_direction = 'positive', conclusion_summary = '철분 보충이 헤모글로빈 2.01 g/dL 개선 (P<0.001). 저용량(<5mg/kg/일)이 최적. 28개 연구, 8,829명', effect_size_text = 'SMD 2.01 g/dL (Hb); 2.39 g/dL (<3개월)', p_value_text = 'P<0.001', confidence_interval_text = 'Hb: 1.48-2.54' WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '39951396' LIMIT 1);
UPDATE evidence_outcomes SET outcome_name = '칼슘+비타민D의 폐경 후 골밀도 및 골절 예방', outcome_type = 'efficacy', effect_direction = 'positive', conclusion_summary = '칼슘+비타민D가 총 골밀도 증가 (SMD 0.537). 고관절 골절 13.6% 감소 (RR 0.864)', effect_size_text = 'SMD 0.537 (BMD); RR 0.864 (골절)', p_value_text = 'P<0.05', confidence_interval_text = 'BMD: 0.227-0.847; 골절: 0.763-0.979' WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '33237064' LIMIT 1);
UPDATE evidence_outcomes SET outcome_name = '칼슘+비타민D의 골절 위험 감소 (NOF)', outcome_type = 'efficacy', effect_direction = 'positive', conclusion_summary = '총 골절 15% 감소 (SRRE 0.85), 고관절 골절 30% 감소 (SRRE 0.70). 8개 RCT, 30,970명', effect_size_text = 'SRRE 0.85 (총); SRRE 0.70 (고관절)', p_value_text = 'P<0.05', confidence_interval_text = '총: 0.73-0.98; 고관절: 0.56-0.87' WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '26510847' LIMIT 1);
UPDATE evidence_outcomes SET outcome_name = '프로바이오틱스의 우울·불안 증상 개선', outcome_type = 'efficacy', effect_direction = 'positive', conclusion_summary = '프로바이오틱스가 우울 (d=-0.24, P<0.01), 불안 (d=-0.10, P=0.03) 유의 개선. 34개 시험', effect_size_text = 'd=-0.24 (우울); d=-0.10 (불안)', p_value_text = '우울: P<0.01; 불안: P=0.03', confidence_interval_text = '-' WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '31004628' LIMIT 1);
UPDATE evidence_outcomes SET outcome_name = '프로바이오틱스의 장벽 기능 강화', outcome_type = 'efficacy', effect_direction = 'positive', conclusion_summary = '장벽 투과성 개선 (TER MD 5.27, P<0.00001). 조눌린·내독소 감소. 26개 RCT, 1,891명', effect_size_text = 'MD 5.27 (TER); SMD -1.58 (조눌린)', p_value_text = 'TER: P<0.00001; 조눌린: P=0.0007', confidence_interval_text = 'TER: 3.82-6.72' WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '37168869' LIMIT 1);
UPDATE evidence_outcomes SET outcome_name = '항산화 비타민·루테인의 AMD 진행 억제', outcome_type = 'efficacy', effect_direction = 'positive', conclusion_summary = '후기 AMD 28% 감소 (OR 0.72). 루테인/제아잔틴 대체 시 18% 추가 감소 (HR 0.82). 26개 연구, 11,952명', effect_size_text = 'OR 0.72 (AMD); HR 0.82 (루테인)', p_value_text = '-', confidence_interval_text = 'AMD: 0.58-0.90; 루테인: 0.69-0.96' WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '37702300' LIMIT 1);
UPDATE evidence_outcomes SET outcome_name = '카로티노이드(루테인 포함)의 항염증 효과', outcome_type = 'biomarker', effect_direction = 'positive', conclusion_summary = 'CRP (WMD -0.54, P<0.001), IL-6 (WMD -0.54, P=0.025) 감소. 루테인 CRP WMD -0.30', effect_size_text = 'WMD -0.54 (CRP); WMD -0.30 (루테인 CRP)', p_value_text = 'CRP: P<0.001; IL-6: P=0.025', confidence_interval_text = 'CRP: -0.71 to -0.37' WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '33998846' LIMIT 1);
UPDATE evidence_outcomes SET outcome_name = 'CoQ10의 난소 노화 여성 생식능 개선', outcome_type = 'efficacy', effect_direction = 'positive', conclusion_summary = 'CoQ10이 타 항산화제 대비 우수. 최적 30mg/일 3개월. 20개 RCT, 2,617명', effect_size_text = 'CoQ10이 멜라토닌·미오이노시톨 대비 우수', p_value_text = '-', confidence_interval_text = '-' WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '39019217' LIMIT 1);
UPDATE evidence_outcomes SET outcome_name = 'CoQ10 전처치의 IVF/ICSI 결과 개선', outcome_type = 'efficacy', effect_direction = 'positive', conclusion_summary = '임신율 84% 증가 (OR 1.84, P=0.0002). 난자 수 증가 (MD 1.30). 6개 RCT, 1,529명', effect_size_text = 'OR 1.84 (임신율); MD 1.30 (난자); OR 0.38 (유산)', p_value_text = '임신: P=0.0002; 난자: P<0.00001', confidence_interval_text = '임신: 1.33-2.53; 난자: 1.21-1.40' WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '39129455' LIMIT 1);
UPDATE evidence_outcomes SET outcome_name = '실리마린의 NAFLD 개선', outcome_type = 'efficacy', effect_direction = 'positive', conclusion_summary = 'ALT (SMD -12.39), AST (SMD -10.97) 감소. 지방증 개선 (OR 3.25). 26개 RCT, 2,375명', effect_size_text = 'SMD -12.39 (ALT); OR 3.25 (지방증)', p_value_text = 'P<0.05', confidence_interval_text = 'ALT: -19.69 to -5.08; 지방증: 1.80-5.87' WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '38579127' LIMIT 1);
UPDATE evidence_outcomes SET outcome_name = '실리마린의 간 질환 보조 치료 (서술적 고찰)', outcome_type = 'efficacy', effect_direction = 'positive', conclusion_summary = '간경변 환자 통합 분석: 간 관련 사망 유의 감소. 부작용 낮음', effect_size_text = '간경변 환자 간 관련 사망 유의 감소 (통합 분석)', p_value_text = '-', confidence_interval_text = '-' WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '32065376' LIMIT 1);
UPDATE evidence_outcomes SET outcome_name = '글루코사민·콘드로이틴 골관절염 (동물 연구)', outcome_type = 'efficacy', effect_direction = 'neutral', conclusion_summary = '개·고양이 OA 대상. 콘드로이틴-글루코사민 무효과 판정. 동물 연구로 인체 적용 한계', effect_size_text = '콘드로이틴-글루코사민: non-effect', p_value_text = '-', confidence_interval_text = '-' WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '36142319' LIMIT 1);
UPDATE evidence_outcomes SET outcome_name = '글루코사민+콘드로이틴의 무릎 OA 효과', outcome_type = 'efficacy', effect_direction = 'positive', conclusion_summary = 'WOMAC 개선 (MD -12.04, P=0.02). 관절간격 억제 (MD -0.09, P=0.04). 8개 RCT, 3,793명', effect_size_text = 'MD -12.04 (WOMAC); MD -0.09 (JSN)', p_value_text = 'WOMAC: P=0.02; JSN: P=0.04', confidence_interval_text = 'WOMAC: -22.33 to -1.75' WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '35024906' LIMIT 1);
UPDATE evidence_outcomes SET outcome_name = '프로바이오틱스+비오틴의 우울증 보조 효과', outcome_type = 'efficacy', effect_direction = 'neutral', conclusion_summary = '82명 RCT. 양 군 모두 개선. 프로바이오틱스 군 미생물 다양성 증가, 임상 차이 NS', effect_size_text = '양 군 개선; 군간 차이 NS', p_value_text = 'NS', confidence_interval_text = '-' WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '33171595' LIMIT 1);
UPDATE evidence_outcomes SET outcome_name = '경구 비오틴 vs 미녹시딜의 모발 성장', outcome_type = 'efficacy', effect_direction = 'neutral', conclusion_summary = '남성 탈모 대상 교차 RCT. 초록 미제공으로 정량 데이터 제한', effect_size_text = '초록 미제공', p_value_text = '-', confidence_interval_text = '-' WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '38688776' LIMIT 1);
UPDATE evidence_outcomes SET outcome_name = '셀레늄의 하시모토 갑상선염 보조', outcome_type = 'efficacy', effect_direction = 'positive', conclusion_summary = 'TSH 감소 (SMD -0.21). TPOAb 감소 (SMD -0.96). 부작용 유사. 35개 RCT', effect_size_text = 'SMD -0.21 (TSH); SMD -0.96 (TPOAb)', p_value_text = 'TSH: P<0.05; TPOAb: P<0.05', confidence_interval_text = 'TSH: -0.43 to -0.02; TPOAb: -1.36 to -0.56' WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '38243784' LIMIT 1);
UPDATE evidence_outcomes SET outcome_name = 'HT 보충제 비교 (셀레늄 우위)', outcome_type = 'efficacy', effect_direction = 'positive', conclusion_summary = '셀레늄이 TPOAb (SMD -2.44), TgAb (SMD -2.76) 유의 감소. 비타민D·미오이노시톨 비유의', effect_size_text = 'SMD -2.44 (TPOAb); SMD -2.76 (TgAb)', p_value_text = 'P<0.05', confidence_interval_text = 'TPOAb: -4.19 to -0.69; TgAb: -4.50 to -1.02' WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '39698034' LIMIT 1);
UPDATE evidence_outcomes SET outcome_name = '비타민A의 소아 사망률 예방 (코크란)', outcome_type = 'efficacy', effect_direction = 'positive', conclusion_summary = '전체 사망 12% 감소 (RR 0.88, 고확실성). 설사 사망 12% 감소. 47개 연구, ~1,223,856명', effect_size_text = 'RR 0.88 (전체); RR 0.88 (설사)', p_value_text = 'P<0.05', confidence_interval_text = '전체: 0.83-0.93; 설사: 0.79-0.98' WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '35294044' LIMIT 1);
UPDATE evidence_outcomes SET outcome_name = '비타민A와 소아 사망률 감소 (1993)', outcome_type = 'efficacy', effect_direction = 'positive', conclusion_summary = '홍역 입원 사망 61% 감소 (OR 0.39). 지역사회 30% 감소 (OR 0.70). 12개 시험', effect_size_text = 'OR 0.39 (홍역); OR 0.70 (지역사회)', p_value_text = '홍역: P=0.0004; 지역사회: P=0.001', confidence_interval_text = '홍역: 0.22-0.66; 지역사회: 0.56-0.87' WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '8426449' LIMIT 1);
UPDATE evidence_outcomes SET outcome_name = '고용량 비타민E의 사망률 증가 위험', outcome_type = 'safety', effect_direction = 'negative', conclusion_summary = '≥400 IU/일 사망 위험 증가 (+39/만명, P=0.035). 150 IU 초과 시 용량반응. 19개 시험, 135,967명', effect_size_text = '+39/만명 (고용량); -16/만명 (저용량, NS)', p_value_text = '고용량: P=0.035', confidence_interval_text = '고용량: 3-74/만명' WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '15537682' LIMIT 1);
UPDATE evidence_outcomes SET outcome_name = '비타민E와 뇌졸중 (혼합 결과)', outcome_type = 'safety', effect_direction = 'neutral', conclusion_summary = '단독: 효과 없음. 병용 시 허혈성 감소 (RR 0.91) but 출혈성 증가 (RR 1.22). 16개 RCT', effect_size_text = 'RR 0.91 (허혈성); RR 1.22 (출혈성)', p_value_text = '허혈: P=0.02; 출혈: P=0.04', confidence_interval_text = '허혈: 0.84-0.99; 출혈: 1.0-1.48' WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '37698992' LIMIT 1);
UPDATE evidence_outcomes SET outcome_name = '커큐민의 관절염 증상·염증 개선', outcome_type = 'efficacy', effect_direction = 'positive', conclusion_summary = '5종 관절염 환자 대상. 120-1500mg 투여 시 염증·통증 개선. 29개 RCT, 2,396명', effect_size_text = '염증·통증 개선 (통합 ES 미제공)', p_value_text = '-', confidence_interval_text = '-' WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '35935936' LIMIT 1);
UPDATE evidence_outcomes SET outcome_name = '커큐민의 항산화·항염증 (GRADE)', outcome_type = 'biomarker', effect_direction = 'positive', conclusion_summary = 'CRP (WMD -0.58), TNF-α (WMD -3.48), IL-6 (WMD -1.31) 유의 감소. 66개 RCT', effect_size_text = 'WMD -0.58 (CRP); WMD -3.48 (TNF-α)', p_value_text = 'P<0.05', confidence_interval_text = 'CRP: -0.74 to -0.41; TNF-α: -4.38 to -2.58' WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '36804260' LIMIT 1);
UPDATE evidence_outcomes SET outcome_name = '멜라토닌의 수면 질(PSQI) 개선', outcome_type = 'efficacy', effect_direction = 'positive', conclusion_summary = 'PSQI 유의 개선 (WMD -1.24, P<0.001). 대사장애에서 가장 효과적. 23개 RCT', effect_size_text = 'WMD -1.24 (PSQI)', p_value_text = 'P<0.001', confidence_interval_text = '-1.77 to -0.71' WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '33417003' LIMIT 1);
UPDATE evidence_outcomes SET outcome_name = '멜라토닌의 불면증 약물 대비 효과', outcome_type = 'efficacy', effect_direction = 'neutral', conclusion_summary = '벤조·졸피뎀이 멜라토닌보다 유의하게 효과적. 멜라토닌은 부작용 유리. 154개 RCT, 44,089명', effect_size_text = '멜라토닌 < 벤조·졸피뎀 (SMD 0.27-0.71 차이)', p_value_text = '-', confidence_interval_text = '-' WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '35843245' LIMIT 1);
UPDATE evidence_outcomes SET outcome_name = '인삼의 기억력 개선', outcome_type = 'efficacy', effect_direction = 'positive', conclusion_summary = '기억력 개선 (SMD 0.19, P<0.05). 고용량 시 (SMD 0.33). 인지/주의력 NS. 15개 RCT, 671명', effect_size_text = 'SMD 0.19 (기억력); SMD 0.33 (고용량)', p_value_text = '기억력: P<0.05; 인지/주의: NS', confidence_interval_text = '기억력: 0.02-0.36; 고용량: 0.04-0.61' WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '39474788' LIMIT 1);
UPDATE evidence_outcomes SET outcome_name = '인삼의 피로 개선 효과', outcome_type = 'efficacy', effect_direction = 'positive', conclusion_summary = '아시아·미국 인삼 모두 만성질환 피로에 중등도 유효성. 부작용 낮음. 10개 연구', effect_size_text = '10개 연구에서 중등도 유효성', p_value_text = '-', confidence_interval_text = '-' WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '29624410' LIMIT 1);
UPDATE evidence_outcomes SET outcome_name = 'MSM 등 보조식품의 골관절염 효과', outcome_type = 'efficacy', effect_direction = 'positive', conclusion_summary = 'MSM: 통증 유의 감소, 임상적 중요성 불확실. 콜라겐·커큐민 등 7종이 단기 대효과. 69개 RCT', effect_size_text = 'MSM: 유의하나 임상적 중요성 불확실; 7종 ES>0.80 (단기)', p_value_text = '-', confidence_interval_text = '-' WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '29018060' LIMIT 1);
UPDATE evidence_outcomes SET outcome_name = '(데이터 오류) HIV PrEP — MSM 보조식품 무관', outcome_type = 'efficacy', effect_direction = 'neutral', conclusion_summary = '주의: HIV PrEP 메타분석. MSM(메틸설포닐메탄) 무관. 검색 시 약어 혼동. 데이터 교체 필요', effect_size_text = '해당 없음 (주제 불일치)', p_value_text = '-', confidence_interval_text = '-' WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '35545381' LIMIT 1);
UPDATE evidence_outcomes SET outcome_name = '가르시니아의 혈중 지질 개선', outcome_type = 'biomarker', effect_direction = 'positive', conclusion_summary = 'TC (WMD -6.76, P=0.032), TG (WMD -24.21, P<0.001) 감소. HDL 증가. 14개 시험, 623명', effect_size_text = 'WMD -6.76 (TC); WMD -24.21 (TG); WMD +2.95 (HDL)', p_value_text = 'TC: P=0.032; TG: P<0.001; HDL: P<0.001', confidence_interval_text = 'TC: -12.39 to -0.59; TG: -37.84 to -10.58' WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '38151892' LIMIT 1);
UPDATE evidence_outcomes SET outcome_name = '가르시니아의 렙틴 감소', outcome_type = 'biomarker', effect_direction = 'positive', conclusion_summary = '렙틴 유의 감소 (WMD -5.01, P=0.02). 50명+ 표본·30세+ 에서 효과 뚜렷. 8개 시험, 330명', effect_size_text = 'WMD -5.01 ng/mL (렙틴)', p_value_text = 'P=0.02', confidence_interval_text = '-9.22 to -0.80' WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '38876392' LIMIT 1);
UPDATE evidence_outcomes SET outcome_name = '가수분해 콜라겐의 피부 노화 개선', outcome_type = 'efficacy', effect_direction = 'positive', conclusion_summary = '수분·탄력·주름 유의 개선. 90일+ 섭취 시 효과적. 19개 RCT, 1,125명', effect_size_text = '수분·탄력·주름 통합 효과 유의', p_value_text = 'P<0.05', confidence_interval_text = '-' WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '33742704' LIMIT 1);
UPDATE evidence_outcomes SET outcome_name = '콜라겐 펩타이드의 관절·체성분 개선', outcome_type = 'efficacy', effect_direction = 'positive', conclusion_summary = '관절 기능·통증에 가장 유익. 체성분·근력 일부 개선. 15개 RCT', effect_size_text = '관절 기능 유의 개선; MPS: 고품질 단백질 대비 NS', p_value_text = '-', confidence_interval_text = '-' WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '34491424' LIMIT 1);
UPDATE evidence_outcomes SET outcome_name = '크레아틴의 신장 안전성', outcome_type = 'safety', effect_direction = 'positive', conclusion_summary = '크레아티닌·요소 정상범위. 신장 손상 유발하지 않음. 15개 연구', effect_size_text = 'SMD 0.48 (크레아티닌); SMD 1.10 (요소)', p_value_text = '-', confidence_interval_text = '크레아티닌: 0.24-0.73; 요소: 0.34-1.85' WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '31375416' LIMIT 1);
UPDATE evidence_outcomes SET outcome_name = '크레아틴의 기억력 개선', outcome_type = 'efficacy', effect_direction = 'positive', conclusion_summary = '기억력 유의 개선 (SMD 0.29). 고령자 대효과 (SMD 0.88). 젊은 층 NS. 8개 RCT', effect_size_text = 'SMD 0.29 (전체); SMD 0.88 (고령자)', p_value_text = '전체: P=0.02; 고령자: P=0.009', confidence_interval_text = '전체: 0.04-0.53; 고령자: 0.22-1.55' WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '35984306' LIMIT 1);
UPDATE evidence_outcomes SET effect_size_text = '엽산 400μg/일 보충 권고 유지 (코크란)', p_value_text = '-', confidence_interval_text = '-' WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '36321557' LIMIT 1) AND effect_size_text IS NULL;
UPDATE evidence_outcomes SET p_value_text = '빈혈: P<0.05; 저체중아: P<0.05' WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '39145520' LIMIT 1) AND p_value_text IS NULL;

-- evidence_studies 메타데이터 보강
UPDATE evidence_studies SET sample_size = 8829, population_text = '소아·청소년 IDA (28개 연구, 16개국)', duration_text = '≥30일' WHERE pmid = '39951396';
UPDATE evidence_studies SET population_text = '폐경 후 여성', duration_text = '연구별 상이' WHERE pmid = '33237064';
UPDATE evidence_studies SET sample_size = 30970, population_text = '중·고령 성인 (8개 RCT)', duration_text = '연구별 상이' WHERE pmid = '26510847';
UPDATE evidence_studies SET population_text = '다양한 표본 (34개 시험)', duration_text = '연구별 상이' WHERE pmid = '31004628';
UPDATE evidence_studies SET sample_size = 1891, population_text = '다양한 질환 성인 (26개 RCT)', duration_text = '연구별 상이' WHERE pmid = '37168869';
UPDATE evidence_studies SET sample_size = 11952, population_text = 'AMD 65-75세 (26개 연구)', duration_text = '약 1년' WHERE pmid = '37702300';
UPDATE evidence_studies SET population_text = '다양한 질환 성인 (26개 시험)', duration_text = '연구별 상이' WHERE pmid = '33998846';
UPDATE evidence_studies SET sample_size = 2617, population_text = '난소 노화 여성 (20개 RCT)', duration_text = 'IVF 전 3개월' WHERE pmid = '39019217';
UPDATE evidence_studies SET sample_size = 1529, population_text = 'DOR 여성 IVF/ICSI (6개 RCT)', duration_text = 'IVF 주기 전' WHERE pmid = '39129455';
UPDATE evidence_studies SET sample_size = 2375, population_text = 'NAFLD/NASH (26개 RCT)', duration_text = '연구별 상이' WHERE pmid = '38579127';
UPDATE evidence_studies SET population_text = '간 질환 (서술적 고찰)', duration_text = '연구별 상이' WHERE pmid = '32065376';
UPDATE evidence_studies SET population_text = '개·고양이 OA (57편)', duration_text = '연구별 상이' WHERE pmid = '36142319';
UPDATE evidence_studies SET sample_size = 3793, population_text = '무릎 OA (8개 RCT)', duration_text = '연구별 상이' WHERE pmid = '35024906';
UPDATE evidence_studies SET sample_size = 82, population_text = '입원 우울증 (RCT)', duration_text = '28일' WHERE pmid = '33171595';
UPDATE evidence_studies SET population_text = '남성 탈모 (교차 RCT)', duration_text = '연구별 상이' WHERE pmid = '38688776';
UPDATE evidence_studies SET sample_size = 2358, population_text = 'HT 환자 (35개 RCT)', duration_text = '연구별 상이' WHERE pmid = '38243784';
UPDATE evidence_studies SET population_text = 'HT 갑상선기능정상 (10개 연구)', duration_text = '6개월' WHERE pmid = '39698034';
UPDATE evidence_studies SET sample_size = 1223856, population_text = '6개월-5세 소아 (47개 연구)', duration_text = '약 1년' WHERE pmid = '35294044';
UPDATE evidence_studies SET population_text = '개도국 소아 (12개 시험)', duration_text = '연구별 상이' WHERE pmid = '8426449';
UPDATE evidence_studies SET sample_size = 135967, population_text = '만성 질환 성인 (19개 RCT)', duration_text = '연구별 상이' WHERE pmid = '15537682';
UPDATE evidence_studies SET population_text = '성인 (16개 RCT)', duration_text = '6개월-9.4년' WHERE pmid = '37698992';
UPDATE evidence_studies SET sample_size = 2396, population_text = '5종 관절염 (29개 RCT)', duration_text = '4-36주' WHERE pmid = '35935936';
UPDATE evidence_studies SET population_text = '다양한 질환 성인 (66개 RCT)', duration_text = '연구별 상이' WHERE pmid = '36804260';
UPDATE evidence_studies SET population_text = '다양한 질환 성인 (23개 RCT)', duration_text = '연구별 상이' WHERE pmid = '33417003';
UPDATE evidence_studies SET sample_size = 44089, population_text = '불면증 성인 (154개 RCT)', duration_text = '급성·장기' WHERE pmid = '35843245';
UPDATE evidence_studies SET sample_size = 671, population_text = '건강인·인지장애 등 (15개 RCT)', duration_text = '연구별 상이' WHERE pmid = '39474788';
UPDATE evidence_studies SET population_text = '만성 질환 피로 (10개 연구)', duration_text = '연구별 상이' WHERE pmid = '29624410';
UPDATE evidence_studies SET population_text = '골관절염 (69개 RCT, 20종)', duration_text = '단기·중기·장기' WHERE pmid = '29018060';
UPDATE evidence_studies SET population_text = '(데이터 오류: HIV PrEP)', duration_text = '-' WHERE pmid = '35545381';
UPDATE evidence_studies SET sample_size = 623, population_text = '성인 (14개 시험)', duration_text = '8주+ 효과 뚜렷' WHERE pmid = '38151892';
UPDATE evidence_studies SET sample_size = 330, population_text = '성인 (8개 시험)', duration_text = '연구별 상이' WHERE pmid = '38876392';
UPDATE evidence_studies SET sample_size = 1125, population_text = '20-70세 (95% 여성, 19개 RCT)', duration_text = '90일+ 권장' WHERE pmid = '33742704';
UPDATE evidence_studies SET population_text = '운동선수·노인 (15개 RCT)', duration_text = '연구별 상이' WHERE pmid = '34491424';
UPDATE evidence_studies SET population_text = '건강 성인 (15개 연구)', duration_text = '연구별 상이' WHERE pmid = '31375416';
UPDATE evidence_studies SET population_text = '건강인 11-76세 (8개 RCT)', duration_text = '5일-24주' WHERE pmid = '35984306';

-- 신규 ingredient_claims
INSERT INTO ingredient_claims (ingredient_id, claim_id, evidence_grade, evidence_summary, is_regulator_approved, approval_country_code, allowed_expression)
VALUES (
  (SELECT id FROM ingredients WHERE slug='red-ginseng'),
  (SELECT id FROM claims WHERE claim_code='COGNITIVE_FUNCTION'),
  'C', '인삼이 기억력 소폭 개선 (SMD 0.19); 전반적 인지에는 효과 제한적', false, NULL, NULL
) ON CONFLICT (ingredient_id, claim_id, approval_country_code) DO NOTHING;

INSERT INTO ingredient_claims (ingredient_id, claim_id, evidence_grade, evidence_summary, is_regulator_approved, approval_country_code, allowed_expression)
VALUES (
  (SELECT id FROM ingredients WHERE slug='creatine'),
  (SELECT id FROM claims WHERE claim_code='COGNITIVE_FUNCTION'),
  'B', '크레아틴이 기억력 개선 (SMD 0.29); 고령자에서 대효과 (SMD 0.88)', false, NULL, NULL
) ON CONFLICT (ingredient_id, claim_id, approval_country_code) DO NOTHING;

-- 완료!
SELECT 'SUCCESS: 모든 데이터가 적용되었습니다.' AS result,
       (SELECT count(*) FROM ingredients) AS ingredients_count,
       (SELECT count(*) FROM products) AS products_count,
       (SELECT count(*) FROM ingredient_claims) AS ingredient_claims_count,
       (SELECT count(*) FROM claims) AS claims_count,
       (SELECT count(*) FROM sources) AS sources_count,
       (SELECT count(*) FROM source_links) AS source_links_count,
       (SELECT count(*) FROM ingredient_search_documents) AS search_docs_count,
       (SELECT count(*) FROM label_snapshots) AS label_snapshots_count,
       (SELECT count(*) FROM evidence_outcomes WHERE claim_id IS NOT NULL) AS outcomes_with_claim,
       (SELECT count(*) FROM evidence_outcomes WHERE effect_size_text IS NOT NULL) AS outcomes_with_effect_size,
       (SELECT count(*) FROM evidence_studies WHERE sample_size IS NOT NULL) AS studies_with_sample_size;
