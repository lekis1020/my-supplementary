-- ============================================================================
-- US 제품 라벨 시드 데이터 — 011_seed_us_labels.sql
-- Version: 1.0.0
-- 생성일: 2026-03-16
-- 대상: US 제품 19개 label_snapshots (008 15개 + 003 4개)
-- 소스: 제조사 공식 사이트 공개 정보 기반
-- 실행 순서: 001 → 003 → 008 → 이 파일(011)
-- ============================================================================
-- NOTE: DailyMed API는 인기 보충제 브랜드 SPL 미등록으로 활용 불가.
--       제조사 공식 사이트의 공개 라벨 정보를 수동 정리하여 시드 데이터 생성.
-- ============================================================================

-- ============================================================================
-- SECTION 1: US 제품 label_snapshots (008 제품 15개)
-- ============================================================================

-- NOW Vitamin D3 5000 IU
INSERT INTO label_snapshots (product_id, label_version, source_name, serving_size_text, servings_per_container, warning_text, directions_text, is_current) VALUES
((SELECT id FROM products WHERE product_name = 'NOW Vitamin D3 5000 IU'),
 'v1', 'NOW Foods Official',
 '1 softgel',
 '240 softgels',
 'For adults only. Consult physician if pregnant/nursing, taking medication, or have a medical condition. Keep out of reach of children. Store in a cool, dry place after opening.',
 'Take 1 softgel daily with a fat-containing meal.',
 true)
ON CONFLICT DO NOTHING;

-- Citracal Calcium Citrate + D3
INSERT INTO label_snapshots (product_id, label_version, source_name, serving_size_text, servings_per_container, warning_text, directions_text, is_current) VALUES
((SELECT id FROM products WHERE product_name = 'Citracal Calcium Citrate + D3'),
 'v1', 'Citracal Official',
 '2 caplets',
 '60 caplets / 30 servings',
 'Ask a doctor before use if you have kidney disease. Do not exceed recommended dose. Keep out of reach of children.',
 'Take 2 caplets daily with or without food. Do not take more than 4 caplets per day.',
 true)
ON CONFLICT DO NOTHING;

-- Doctor''s Best Magnesium Glycinate 400mg
INSERT INTO label_snapshots (product_id, label_version, source_name, serving_size_text, servings_per_container, warning_text, directions_text, is_current) VALUES
((SELECT id FROM products WHERE product_name LIKE 'Doctor''s Best Magnesium%'),
 'v1', 'Doctor''s Best Official',
 '2 tablets',
 '120 tablets / 60 servings',
 'If you are pregnant, nursing, taking any medications or have any medical condition, consult your doctor before use. Keep out of reach of children.',
 'Take 2 tablets daily, preferably with food, or as recommended by a nutritionally-informed physician.',
 true)
ON CONFLICT DO NOTHING;

-- Thorne Zinc Picolinate 30mg
INSERT INTO label_snapshots (product_id, label_version, source_name, serving_size_text, servings_per_container, warning_text, directions_text, is_current) VALUES
((SELECT id FROM products WHERE product_name = 'Thorne Zinc Picolinate 30mg'),
 'v1', 'Thorne Official',
 '1 capsule',
 '60 capsules',
 'If pregnant, consult your health-care practitioner before using this product. Keep out of reach of children.',
 'Take 1 capsule one to two times daily, or as recommended by your health-care practitioner.',
 true)
ON CONFLICT DO NOTHING;

-- Thorne Iron Bisglycinate 25mg
INSERT INTO label_snapshots (product_id, label_version, source_name, serving_size_text, servings_per_container, warning_text, directions_text, is_current) VALUES
((SELECT id FROM products WHERE product_name = 'Thorne Iron Bisglycinate 25mg'),
 'v1', 'Thorne Official',
 '1 capsule',
 '60 capsules',
 'WARNING: Accidental overdose of iron-containing products is a leading cause of fatal poisoning in children under 6. Keep this product out of reach of children. In case of accidental overdose, call a doctor or Poison Control Center immediately.',
 'Take 1 capsule one to two times daily, or as recommended by your health-care practitioner. Best absorbed on an empty stomach.',
 true)
ON CONFLICT DO NOTHING;

-- Nature Made Super B-Complex
INSERT INTO label_snapshots (product_id, label_version, source_name, serving_size_text, servings_per_container, warning_text, directions_text, is_current) VALUES
((SELECT id FROM products WHERE product_name = 'Nature Made Super B-Complex'),
 'v1', 'Nature Made Official',
 '1 tablet',
 '140 tablets',
 'If you are pregnant or nursing, ask a health professional before use. Keep out of reach of children.',
 'Take one tablet daily with water and a meal.',
 true)
ON CONFLICT DO NOTHING;

-- Nature''s Bounty Milk Thistle 250mg
INSERT INTO label_snapshots (product_id, label_version, source_name, serving_size_text, servings_per_container, warning_text, directions_text, is_current) VALUES
((SELECT id FROM products WHERE product_name LIKE 'Nature''s Bounty Milk Thistle%'),
 'v1', 'Nature''s Bounty Official',
 '1 capsule',
 '200 capsules',
 'If you are pregnant, nursing, taking any medications or have any medical condition, consult your doctor before use. Discontinue use and consult your doctor if any adverse reactions occur. Keep out of reach of children.',
 'For adults, take one (1) capsule three times daily, preferably with a meal.',
 true)
ON CONFLICT DO NOTHING;

-- Qunol Ultra CoQ10 200mg
INSERT INTO label_snapshots (product_id, label_version, source_name, serving_size_text, servings_per_container, warning_text, directions_text, is_current) VALUES
((SELECT id FROM products WHERE product_name = 'Qunol Ultra CoQ10 200mg'),
 'v1', 'Qunol Official',
 '1 softgel',
 '120 softgels',
 'If you are pregnant, nursing, or taking medications (especially blood thinners), consult your physician before use. Keep out of reach of children.',
 'Adults take one (1) softgel daily with food. Can be taken at any time of day, even on an empty stomach.',
 true)
ON CONFLICT DO NOTHING;

-- Vital Proteins Collagen Peptides
INSERT INTO label_snapshots (product_id, label_version, source_name, serving_size_text, servings_per_container, warning_text, directions_text, is_current) VALUES
((SELECT id FROM products WHERE product_name = 'Vital Proteins Collagen Peptides'),
 'v1', 'Vital Proteins Official',
 '2 scoops (20g)',
 '28 servings (567g)',
 'Contains: Fish (wild-caught whitefish). If you are pregnant, nursing, or have a medical condition, consult your physician before use.',
 'Add two (2) scoops to 8+ oz of any hot or cold liquid. Mix, shake, or blend until dissolved.',
 true)
ON CONFLICT DO NOTHING;

-- Optimum Nutrition Creatine Monohydrate
INSERT INTO label_snapshots (product_id, label_version, source_name, serving_size_text, servings_per_container, warning_text, directions_text, is_current) VALUES
((SELECT id FROM products WHERE product_name = 'Optimum Nutrition Creatine Monohydrate'),
 'v1', 'Optimum Nutrition Official',
 '1 rounded teaspoon (5g)',
 '60 servings (300g)',
 'Consult a medical doctor before use if you have been treated for or diagnosed with or have a family history of any medical condition, or if you are using any prescription or over-the-counter drug(s). Not for use by those under 18.',
 'Mix one rounded teaspoon of Micronized Creatine Powder with your protein shake or juice. On training days, consume before or after exercise. On rest days, consume in the morning.',
 true)
ON CONFLICT DO NOTHING;

-- Nature Made Turmeric Curcumin 500mg
INSERT INTO label_snapshots (product_id, label_version, source_name, serving_size_text, servings_per_container, warning_text, directions_text, is_current) VALUES
((SELECT id FROM products WHERE product_name = 'Nature Made Turmeric Curcumin 500mg'),
 'v1', 'Nature Made Official',
 '1 capsule',
 '60 capsules',
 'If you are pregnant or nursing, ask a health professional before use. If you are taking blood thinners, consult your doctor before use. Keep out of reach of children.',
 'Take one capsule daily with water and a meal.',
 true)
ON CONFLICT DO NOTHING;

-- Culturelle Daily Probiotic
INSERT INTO label_snapshots (product_id, label_version, source_name, serving_size_text, servings_per_container, warning_text, directions_text, is_current) VALUES
((SELECT id FROM products WHERE product_name = 'Culturelle Daily Probiotic'),
 'v1', 'Culturelle Official',
 '1 capsule',
 '30 capsules',
 'If you are pregnant or nursing, or taking a prescription drug, including immunosuppressants, consult your doctor before use. Discontinue use and consult your doctor if any adverse reactions occur. Keep out of reach of children.',
 'Take one (1) capsule daily. May be taken with or without food. Capsule may be opened and contents mixed into a cool drink or food.',
 true)
ON CONFLICT DO NOTHING;

-- CheongKwanJang Korean Red Ginseng Extract
INSERT INTO label_snapshots (product_id, label_version, source_name, serving_size_text, servings_per_container, warning_text, directions_text, is_current) VALUES
((SELECT id FROM products WHERE product_name = 'CheongKwanJang Korean Red Ginseng Extract'),
 'v1', 'CheongKwanJang Official (US)',
 '1 pouch (10mL)',
 '30 pouches',
 'Not intended for use by children. If you are pregnant, nursing, taking medication or have any medical condition, consult a physician before use. Do not exceed recommended dosage.',
 'Take one (1) pouch daily. May be taken straight or mixed with water or juice. Best consumed on an empty stomach.',
 true)
ON CONFLICT DO NOTHING;

-- Doctor''s Best OptiMSM 1500mg
INSERT INTO label_snapshots (product_id, label_version, source_name, serving_size_text, servings_per_container, warning_text, directions_text, is_current) VALUES
((SELECT id FROM products WHERE product_name LIKE 'Doctor''s Best OptiMSM%'),
 'v1', 'Doctor''s Best Official',
 '1 tablet',
 '120 tablets',
 'If you are pregnant, nursing, taking any medications or have any medical condition, consult your doctor before use. Keep out of reach of children.',
 'Take 1 tablet twice daily, or as recommended by a nutritionally-informed physician.',
 true)
ON CONFLICT DO NOTHING;

-- Nature''s Bounty Garcinia Cambogia 1000mg
INSERT INTO label_snapshots (product_id, label_version, source_name, serving_size_text, servings_per_container, warning_text, directions_text, is_current) VALUES
((SELECT id FROM products WHERE product_name LIKE 'Nature''s Bounty Garcinia Cambogia%'),
 'v1', 'Nature''s Bounty Official',
 '2 capsules',
 '60 capsules / 30 servings',
 'Do not use if you are pregnant, nursing, or taking prescription drugs without first consulting your doctor. Discontinue use two weeks prior to surgery. Keep out of reach of children. Do not exceed recommended dosage.',
 'For adults, take two (2) capsules 30 to 60 minutes before your two largest meals (i.e. lunch and dinner). Do not exceed four (4) capsules per day.',
 true)
ON CONFLICT DO NOTHING;


-- ============================================================================
-- SECTION 2: source_links — US 라벨 → 제품라벨 소스 연결
-- ============================================================================

INSERT INTO source_links (source_id, entity_type, entity_id, source_reference, retrieved_at)
SELECT
  (SELECT id FROM sources WHERE source_name = '제품 라벨 (브라우저 수집)'),
  'label_snapshot',
  ls.id,
  ls.source_name,
  '2026-03-16'::timestamp
FROM label_snapshots ls
JOIN products p ON p.id = ls.product_id
WHERE p.country_code = 'US'
  AND NOT EXISTS (
    SELECT 1 FROM source_links sl
    WHERE sl.entity_type = 'label_snapshot'
      AND sl.entity_id = ls.id
  );
