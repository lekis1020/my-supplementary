-- ============================================================================
-- Supabase Row Level Security (RLS) 정책
-- Version: 1.0.0
--
-- 접근 전략 (하이브리드 ORM):
--   소비자 (anon/authenticated) → Supabase Client → RLS 자동 적용
--   Admin/수집 파이프라인 → Drizzle (service_role key) → RLS 우회
--
-- 원칙:
--   1. 모든 테이블에 RLS 활성화
--   2. 소비자: is_published = TRUE인 데이터만 SELECT
--   3. Admin: service_role로 전체 접근 (Drizzle 경유)
--   4. 쓰기 작업: service_role만 허용 (소비자 쓰기 불가)
-- ============================================================================


-- ============================================================================
-- 헬퍼 함수: 현재 사용자 역할 확인
-- ============================================================================

-- Admin 역할 확인 (Supabase Auth JWT의 app_metadata.role)
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

-- 검수자 역할 확인 (scientific_reviewer, regulatory_reviewer, qa)
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
-- 1. 공개 읽기 테이블 (is_published 필터)
-- ============================================================================
-- 소비자는 is_published = TRUE인 원료만 볼 수 있음

ALTER TABLE ingredients ENABLE ROW LEVEL SECURITY;

CREATE POLICY "공개: 게시된 원료 조회"
    ON ingredients FOR SELECT
    TO anon, authenticated
    USING (is_published = TRUE);

CREATE POLICY "Admin: 원료 전체 접근"
    ON ingredients FOR ALL
    TO authenticated
    USING (is_admin())
    WITH CHECK (is_admin());


-- ============================================================================
-- 2. 공개 읽기 테이블 (게시된 원료에 연결된 데이터만)
-- ============================================================================

-- ingredient_synonyms
ALTER TABLE ingredient_synonyms ENABLE ROW LEVEL SECURITY;

CREATE POLICY "공개: 게시된 원료의 동의어"
    ON ingredient_synonyms FOR SELECT
    TO anon, authenticated
    USING (
        EXISTS (
            SELECT 1 FROM ingredients
            WHERE ingredients.id = ingredient_synonyms.ingredient_id
            AND ingredients.is_published = TRUE
        )
    );

CREATE POLICY "Admin: 동의어 전체 접근"
    ON ingredient_synonyms FOR ALL
    TO authenticated
    USING (is_admin())
    WITH CHECK (is_admin());


-- claims
ALTER TABLE claims ENABLE ROW LEVEL SECURITY;

CREATE POLICY "공개: claim 조회"
    ON claims FOR SELECT
    TO anon, authenticated
    USING (TRUE);

CREATE POLICY "Admin: claim 전체 접근"
    ON claims FOR ALL
    TO authenticated
    USING (is_admin())
    WITH CHECK (is_admin());


-- ingredient_claims
ALTER TABLE ingredient_claims ENABLE ROW LEVEL SECURITY;

CREATE POLICY "공개: 게시된 원료의 기능성"
    ON ingredient_claims FOR SELECT
    TO anon, authenticated
    USING (
        EXISTS (
            SELECT 1 FROM ingredients
            WHERE ingredients.id = ingredient_claims.ingredient_id
            AND ingredients.is_published = TRUE
        )
    );

CREATE POLICY "Admin: 원료기능성 전체 접근"
    ON ingredient_claims FOR ALL
    TO authenticated
    USING (is_admin())
    WITH CHECK (is_admin());


-- safety_items
ALTER TABLE safety_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "공개: 게시된 원료의 안전성"
    ON safety_items FOR SELECT
    TO anon, authenticated
    USING (
        EXISTS (
            SELECT 1 FROM ingredients
            WHERE ingredients.id = safety_items.ingredient_id
            AND ingredients.is_published = TRUE
        )
    );

CREATE POLICY "Admin: 안전성 전체 접근"
    ON safety_items FOR ALL
    TO authenticated
    USING (is_admin())
    WITH CHECK (is_admin());


-- dosage_guidelines
ALTER TABLE dosage_guidelines ENABLE ROW LEVEL SECURITY;

CREATE POLICY "공개: 게시된 원료의 용량"
    ON dosage_guidelines FOR SELECT
    TO anon, authenticated
    USING (
        EXISTS (
            SELECT 1 FROM ingredients
            WHERE ingredients.id = dosage_guidelines.ingredient_id
            AND ingredients.is_published = TRUE
        )
    );

CREATE POLICY "Admin: 용량 전체 접근"
    ON dosage_guidelines FOR ALL
    TO authenticated
    USING (is_admin())
    WITH CHECK (is_admin());


-- ingredient_drug_interactions
ALTER TABLE ingredient_drug_interactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "공개: 게시된 원료의 약물상호작용"
    ON ingredient_drug_interactions FOR SELECT
    TO anon, authenticated
    USING (
        EXISTS (
            SELECT 1 FROM ingredients
            WHERE ingredients.id = ingredient_drug_interactions.ingredient_id
            AND ingredients.is_published = TRUE
        )
    );

CREATE POLICY "Admin: 약물상호작용 전체 접근"
    ON ingredient_drug_interactions FOR ALL
    TO authenticated
    USING (is_admin())
    WITH CHECK (is_admin());


-- regulatory_statuses
ALTER TABLE regulatory_statuses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "공개: 게시된 원료의 규제상태"
    ON regulatory_statuses FOR SELECT
    TO anon, authenticated
    USING (
        EXISTS (
            SELECT 1 FROM ingredients
            WHERE ingredients.id = regulatory_statuses.ingredient_id
            AND ingredients.is_published = TRUE
        )
    );

CREATE POLICY "Admin: 규제상태 전체 접근"
    ON regulatory_statuses FOR ALL
    TO authenticated
    USING (is_admin())
    WITH CHECK (is_admin());


-- ============================================================================
-- 3. 제품 관련 테이블
-- ============================================================================

ALTER TABLE products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "공개: 게시된 제품 조회"
    ON products FOR SELECT
    TO anon, authenticated
    USING (is_published = TRUE);

CREATE POLICY "Admin: 제품 전체 접근"
    ON products FOR ALL
    TO authenticated
    USING (is_admin())
    WITH CHECK (is_admin());


-- product_ingredients
ALTER TABLE product_ingredients ENABLE ROW LEVEL SECURITY;

CREATE POLICY "공개: 게시된 제품의 성분"
    ON product_ingredients FOR SELECT
    TO anon, authenticated
    USING (
        EXISTS (
            SELECT 1 FROM products
            WHERE products.id = product_ingredients.product_id
            AND products.is_published = TRUE
        )
    );

CREATE POLICY "Admin: 제품성분 전체 접근"
    ON product_ingredients FOR ALL
    TO authenticated
    USING (is_admin())
    WITH CHECK (is_admin());


-- label_snapshots
ALTER TABLE label_snapshots ENABLE ROW LEVEL SECURITY;

CREATE POLICY "공개: 게시된 제품의 라벨"
    ON label_snapshots FOR SELECT
    TO anon, authenticated
    USING (
        EXISTS (
            SELECT 1 FROM products
            WHERE products.id = label_snapshots.product_id
            AND products.is_published = TRUE
        )
    );

CREATE POLICY "Admin: 라벨 전체 접근"
    ON label_snapshots FOR ALL
    TO authenticated
    USING (is_admin())
    WITH CHECK (is_admin());


-- ============================================================================
-- 4. 근거문헌 테이블
-- ============================================================================

-- evidence_studies: screening_status = 'included'이고 연결된 원료가 게시된 것만
ALTER TABLE evidence_studies ENABLE ROW LEVEL SECURITY;

CREATE POLICY "공개: 포함된 논문 조회"
    ON evidence_studies FOR SELECT
    TO anon, authenticated
    USING (
        screening_status = 'included'
        AND EXISTS (
            SELECT 1 FROM ingredients
            WHERE ingredients.id = evidence_studies.ingredient_id
            AND ingredients.is_published = TRUE
        )
    );

CREATE POLICY "Admin: 논문 전체 접근"
    ON evidence_studies FOR ALL
    TO authenticated
    USING (is_admin())
    WITH CHECK (is_admin());


-- evidence_outcomes
ALTER TABLE evidence_outcomes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "공개: 게시된 논문의 결과"
    ON evidence_outcomes FOR SELECT
    TO anon, authenticated
    USING (
        EXISTS (
            SELECT 1 FROM evidence_studies es
            JOIN ingredients i ON i.id = es.ingredient_id
            WHERE es.id = evidence_outcomes.evidence_study_id
            AND es.screening_status = 'included'
            AND i.is_published = TRUE
        )
    );

CREATE POLICY "Admin: 논문결과 전체 접근"
    ON evidence_outcomes FOR ALL
    TO authenticated
    USING (is_admin())
    WITH CHECK (is_admin());


-- evidence_grade_history
ALTER TABLE evidence_grade_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "공개: 게시된 원료의 등급이력"
    ON evidence_grade_history FOR SELECT
    TO anon, authenticated
    USING (
        EXISTS (
            SELECT 1 FROM ingredients
            WHERE ingredients.id = evidence_grade_history.ingredient_id
            AND ingredients.is_published = TRUE
        )
    );

CREATE POLICY "Admin: 등급이력 전체 접근"
    ON evidence_grade_history FOR ALL
    TO authenticated
    USING (is_admin())
    WITH CHECK (is_admin());


-- ============================================================================
-- 5. 코드/출처 테이블 (공개 읽기)
-- ============================================================================

ALTER TABLE code_tables ENABLE ROW LEVEL SECURITY;
CREATE POLICY "공개: 코드테이블 조회"
    ON code_tables FOR SELECT TO anon, authenticated USING (TRUE);
CREATE POLICY "Admin: 코드테이블 관리"
    ON code_tables FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());

ALTER TABLE code_values ENABLE ROW LEVEL SECURITY;
CREATE POLICY "공개: 코드값 조회"
    ON code_values FOR SELECT TO anon, authenticated USING (TRUE);
CREATE POLICY "Admin: 코드값 관리"
    ON code_values FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());

ALTER TABLE sources ENABLE ROW LEVEL SECURITY;
CREATE POLICY "공개: 출처 조회"
    ON sources FOR SELECT TO anon, authenticated USING (TRUE);
CREATE POLICY "Admin: 출처 관리"
    ON sources FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());

ALTER TABLE source_links ENABLE ROW LEVEL SECURITY;
CREATE POLICY "공개: 출처연결 조회"
    ON source_links FOR SELECT TO anon, authenticated USING (TRUE);
CREATE POLICY "Admin: 출처연결 관리"
    ON source_links FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());


-- ============================================================================
-- 6. 검색 최적화
-- ============================================================================

ALTER TABLE ingredient_search_documents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "공개: 게시된 원료 검색"
    ON ingredient_search_documents FOR SELECT
    TO anon, authenticated
    USING (
        EXISTS (
            SELECT 1 FROM ingredients
            WHERE ingredients.id = ingredient_search_documents.ingredient_id
            AND ingredients.is_published = TRUE
        )
    );

CREATE POLICY "Admin: 검색문서 전체 접근"
    ON ingredient_search_documents FOR ALL
    TO authenticated
    USING (is_admin())
    WITH CHECK (is_admin());


-- ============================================================================
-- 7. 운영 전용 테이블 (Admin/검수자만 접근)
-- ============================================================================

-- review_tasks: 검수자 이상만 접근
ALTER TABLE review_tasks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "검수자: 검수 태스크 조회"
    ON review_tasks FOR SELECT
    TO authenticated
    USING (is_reviewer());

CREATE POLICY "검수자: 검수 태스크 수정"
    ON review_tasks FOR UPDATE
    TO authenticated
    USING (is_reviewer())
    WITH CHECK (is_reviewer());

CREATE POLICY "Admin: 검수 태스크 전체 접근"
    ON review_tasks FOR ALL
    TO authenticated
    USING (is_admin())
    WITH CHECK (is_admin());


-- revision_histories: 검수자 이상만 조회
ALTER TABLE revision_histories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "검수자: 변경이력 조회"
    ON revision_histories FOR SELECT
    TO authenticated
    USING (is_reviewer());

CREATE POLICY "Admin: 변경이력 전체 접근"
    ON revision_histories FOR ALL
    TO authenticated
    USING (is_admin())
    WITH CHECK (is_admin());


-- ============================================================================
-- 8. 수집 계층 테이블 (Admin만 접근)
-- ============================================================================

ALTER TABLE source_connectors ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admin: 커넥터 전체 접근"
    ON source_connectors FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());

ALTER TABLE collection_jobs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admin: 수집작업 전체 접근"
    ON collection_jobs FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());

ALTER TABLE collection_runs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admin: 수집실행 전체 접근"
    ON collection_runs FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());

ALTER TABLE raw_documents ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admin: 원문 전체 접근"
    ON raw_documents FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());

ALTER TABLE extraction_results ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admin: 추출결과 전체 접근"
    ON extraction_results FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());

ALTER TABLE refresh_policies ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admin: 갱신정책 전체 접근"
    ON refresh_policies FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());

ALTER TABLE entity_refresh_states ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admin: 갱신상태 전체 접근"
    ON entity_refresh_states FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());

-- 검수자도 raw_documents와 extraction_results 읽기 허용 (검수 시 원문 확인용)
CREATE POLICY "검수자: 원문 조회"
    ON raw_documents FOR SELECT TO authenticated USING (is_reviewer());

CREATE POLICY "검수자: 추출결과 조회"
    ON extraction_results FOR SELECT TO authenticated USING (is_reviewer());
