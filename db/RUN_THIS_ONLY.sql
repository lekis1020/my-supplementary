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

-- 완료!
SELECT 'SUCCESS: 모든 데이터가 적용되었습니다.' AS result,
       (SELECT count(*) FROM ingredients) AS ingredients_count,
       (SELECT count(*) FROM products) AS products_count,
       (SELECT count(*) FROM ingredient_claims) AS claims_count;
