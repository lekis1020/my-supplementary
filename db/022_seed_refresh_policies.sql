-- ============================================================================
-- refresh_policies 시드 데이터
-- 엔티티별 갱신 주기 및 staleness 기준 설정
-- ============================================================================

-- 기존 데이터 있으면 덮어쓰기 (entity_type 기준)
INSERT INTO refresh_policies (entity_type, refresh_mode, staleness_days, change_detection_method, is_active)
VALUES
    -- 핵심 제품/원료 데이터: 30일 주기 (신제품, 리포뮬레이션 빈번)
    ('product',              'periodic', 30,  'checksum',      TRUE),
    ('product_ingredient',   'periodic', 30,  'checksum',      TRUE),
    ('label_snapshot',       'periodic', 30,  'checksum',      TRUE),

    -- 원료 마스터: 90일 주기 (비교적 안정)
    ('ingredient',           'periodic', 90,  'checksum',      TRUE),

    -- 기능성/규제: 60일 주기 (규제 변경에 따라 갱신)
    ('claim',                'periodic', 60,  'content_diff',  TRUE),
    ('ingredient_claim',     'periodic', 60,  'content_diff',  TRUE),

    -- 안전성: 90일 주기
    ('safety_item',          'periodic', 90,  'content_diff',  TRUE),

    -- 용량 가이드라인: 180일 주기 (변경 드묾)
    ('dosage_guideline',     'periodic', 180, 'content_diff',  TRUE),

    -- 근거문헌: 180일 주기 (문헌 리뷰 사이클)
    ('evidence_study',       'periodic', 180, 'search_requery', TRUE)

ON CONFLICT DO NOTHING;
