-- ============================================================================
-- 추가 제품 시드 데이터 (008) — 30~40개 신규 제품
-- Version: 1.0.0
-- 대상: ingredients(신규 6종), products(35개), product_ingredients, label_snapshots
-- 실행 순서: 001 → 004 → 002 → 003 → 이 파일(008)
-- ============================================================================

-- ============================================================================
-- A. 신규 원료 6종 (기존 20종에 없는 성분)
-- ============================================================================

INSERT INTO ingredients (canonical_name_ko, canonical_name_en, display_name, scientific_name, slug, ingredient_type, description, origin_type, form_description, standardization_info, is_active, is_published) VALUES
('홍삼',          'Red Ginseng',      '홍삼',         'Panax ginseng C.A. Meyer',  'red-ginseng',  'herb',       '인삼을 증삼 건조한 것. 진세노사이드를 주요 활성 성분으로 하며 면역 기능, 피로 개선 등에 관한 연구가 있음.',     'natural',   '홍삼 추출물(진세노사이드 Rg1+Rb1+Rg3)',    '진세노사이드 Rg1+Rb1+Rg3 합계 기준',  true, true),
('콜라겐',        'Collagen',         '콜라겐',       'Collagen peptides',         'collagen',     'amino_acid', '피부 진피, 연골, 뼈의 구조 단백질. 가수분해 콜라겐(펩타이드) 형태로 섭취 시 흡수율 증가.',               'natural',   '어류/돼지 유래 가수분해 콜라겐 펩타이드', NULL,                                   true, true),
('크레아틴',      'Creatine',         '크레아틴',     'Creatine monohydrate',      'creatine',     'amino_acid', '근육 내 ATP 재합성에 관여하는 질소 함유 유기산. 고강도 운동 수행 능력 향상에 가장 근거 강한 스포츠 영양소.', 'synthetic', '크레아틴 모노하이드레이트',               NULL,                                   true, true),
('가르시니아',    'Garcinia',         '가르시니아',   'Garcinia cambogia',         'garcinia',     'herb',       '가르시니아 캄보지아 껍질에서 추출한 HCA(하이드록시시트르산)가 주요 활성 성분. 식욕 조절 연구가 있음.',      'natural',   '가르시니아 껍질 추출물(HCA 60%)',         'HCA 60% 표준화',                       true, true),
('MSM',           'MSM',              'MSM',          'Methylsulfonylmethane',     'msm',          'other',      '유기 황 화합물. 관절 통증, 염증 감소에 관한 임상 연구가 있음. 글루코사민/콘드로이틴과 병용 흔함.',         'synthetic', '메틸설포닐메탄',                          NULL,                                   true, true),
('지아잔틴',      'Zeaxanthin',       '지아잔틴',     'Zeaxanthin',                'zeaxanthin',   'herb',       '루테인과 함께 황반에 존재하는 카로티노이드. 황반색소밀도 유지 및 블루라이트 차단에 관여.',               'natural',   '마리골드꽃추출물(지아잔틴)',               NULL,                                   true, true)
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- B. 신규 제품 — KR 20개 + US 15개 = 35개
-- ============================================================================

INSERT INTO products (product_name, brand_name, manufacturer_name, country_code, product_type, status, is_published) VALUES
-- KR 제품 20개
('정관장 홍삼정 에브리타임',                  '정관장',        'KGC인삼공사',          'KR', 'health_functional_food', 'active', true),
('정관장 홍삼톤 골드',                        '정관장',        'KGC인삼공사',          'KR', 'health_functional_food', 'active', true),
('종근당 비타민D 1000IU',                     '종근당건강',    '종근당건강',           'KR', 'health_functional_food', 'active', true),
('종근당 아이클리어 루테인 지아잔틴',          '종근당건강',    '종근당건강',           'KR', 'health_functional_food', 'active', true),
('고려은단 비타민C 1000',                     '고려은단',      '고려은단',             'KR', 'health_functional_food', 'active', true),
('대웅제약 에너씨슬 밀크씨슬',                '대웅제약',      '대웅제약',             'KR', 'health_functional_food', 'active', true),
('쎌바이오텍 듀오락 골드 프로바이오틱스',      '쎌바이오텍',    '쎌바이오텍',           'KR', 'health_functional_food', 'active', true),
('뉴트리원 비타민B 콤플렉스',                 '뉴트리원',      '뉴트리원',             'KR', 'health_functional_food', 'active', true),
('GNM자연의품격 칼슘마그네슘아연비타민D',      'GNM자연의품격', 'GNM자연의품격',        'KR', 'health_functional_food', 'active', true),
('뉴트리디데이 프리미엄 오메가3',             '뉴트리디데이',  '뉴트리디데이',         'KR', 'health_functional_food', 'active', true),
('한미양행 철분 플러스',                      '한미양행',      '한미양행',             'KR', 'health_functional_food', 'active', true),
('일양약품 글루코사민 1500',                  '일양약품',      '일양약품',             'KR', 'health_functional_food', 'active', true),
('뉴트리코어 MSM 플러스',                     '뉴트리코어',    '뉴트리코어',           'KR', 'health_functional_food', 'active', true),
('뉴트리디데이 가르시니아 캄보지아',           '뉴트리디데이',  '뉴트리디데이',         'KR', 'health_functional_food', 'active', true),
('에버콜라겐 타임 비오틴 콜라겐',             '에버콜라겐',    '뉴트리',               'KR', 'health_functional_food', 'active', true),
('세노비스 셀레늄',                           '세노비스',      '대상웰라이프',         'KR', 'health_functional_food', 'active', true),
('세노비스 비타민E 400IU',                    '세노비스',      '대상웰라이프',         'KR', 'health_functional_food', 'active', true),
('안국건강 비타민A 5000IU',                   '안국건강',      '안국건강',             'KR', 'health_functional_food', 'active', true),
('나우푸드 커큐민 500mg',                     'NOW Foods',     'NOW Health Group',     'KR', 'dietary_supplement',     'active', true),
('동국제약 인사돌플러스',                     '동국제약',      '동국제약',             'KR', 'health_functional_food', 'active', true),
-- US 제품 15개
('NOW Vitamin D3 5000 IU',                   'NOW Foods',     'NOW Health Group',     'US', 'dietary_supplement',     'active', true),
('Citracal Calcium Citrate + D3',            'Citracal',      'Bayer HealthCare',     'US', 'dietary_supplement',     'active', true),
('Doctor''s Best Magnesium Glycinate 400mg', 'Doctor''s Best','Doctor''s Best Inc.',  'US', 'dietary_supplement',     'active', true),
('Thorne Zinc Picolinate 30mg',              'Thorne',        'Thorne Research Inc.', 'US', 'dietary_supplement',     'active', true),
('Thorne Iron Bisglycinate 25mg',            'Thorne',        'Thorne Research Inc.', 'US', 'dietary_supplement',     'active', true),
('Nature Made Super B-Complex',              'Nature Made',   'Pharmavite LLC',       'US', 'dietary_supplement',     'active', true),
('Nature''s Bounty Milk Thistle 250mg',      'Nature''s Bounty','Nestlé Health Science','US','dietary_supplement',   'active', true),
('Qunol Ultra CoQ10 200mg',                  'Qunol',         'Qunol LLC',            'US', 'dietary_supplement',     'active', true),
('Vital Proteins Collagen Peptides',         'Vital Proteins','Nestlé Health Science','US', 'dietary_supplement',     'active', true),
('Optimum Nutrition Creatine Monohydrate',   'Optimum Nutrition','Glanbia Performance Nutrition','US','dietary_supplement','active',true),
('Nature Made Turmeric Curcumin 500mg',      'Nature Made',   'Pharmavite LLC',       'US', 'dietary_supplement',     'active', true),
('Culturelle Daily Probiotic',               'Culturelle',    'i-Health Inc.',        'US', 'dietary_supplement',     'active', true),
('CheongKwanJang Korean Red Ginseng Extract','CheongKwanJang','KGC Inc.',             'US', 'dietary_supplement',     'active', true),
('Doctor''s Best OptiMSM 1500mg',            'Doctor''s Best','Doctor''s Best Inc.',  'US', 'dietary_supplement',     'active', true),
('Nature''s Bounty Garcinia Cambogia 1000mg','Nature''s Bounty','Nestlé Health Science','US','dietary_supplement',   'active', true)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- C. 제품-원료 연결 (product_ingredients)
-- ============================================================================

-- 정관장 홍삼정 에브리타임
INSERT INTO product_ingredients (product_id, ingredient_id, amount_per_serving, amount_unit, ingredient_role, raw_label_name) VALUES
((SELECT id FROM products WHERE product_name = '정관장 홍삼정 에브리타임'),
 (SELECT id FROM ingredients WHERE slug='red-ginseng'), 1000, 'mg', 'active', '홍삼농축액(홍삼분말 함유)');

-- 정관장 홍삼톤 골드
INSERT INTO product_ingredients (product_id, ingredient_id, amount_per_serving, amount_unit, ingredient_role, raw_label_name) VALUES
((SELECT id FROM products WHERE product_name = '정관장 홍삼톤 골드'),
 (SELECT id FROM ingredients WHERE slug='red-ginseng'), 1500, 'mg', 'active', '홍삼농축액');

-- 종근당 비타민D 1000IU
INSERT INTO product_ingredients (product_id, ingredient_id, amount_per_serving, amount_unit, ingredient_role, raw_label_name) VALUES
((SELECT id FROM products WHERE product_name = '종근당 비타민D 1000IU'),
 (SELECT id FROM ingredients WHERE slug='vitamin-d'), 1000, 'IU', 'active', '콜레칼시페롤(비타민D3)');

-- 종근당 아이클리어 루테인 지아잔틴
INSERT INTO product_ingredients (product_id, ingredient_id, amount_per_serving, amount_unit, ingredient_role, raw_label_name) VALUES
((SELECT id FROM products WHERE product_name = '종근당 아이클리어 루테인 지아잔틴'),
 (SELECT id FROM ingredients WHERE slug='lutein'),     20,  'mg', 'active', '마리골드꽃추출물(루테인)'),
((SELECT id FROM products WHERE product_name = '종근당 아이클리어 루테인 지아잔틴'),
 (SELECT id FROM ingredients WHERE slug='zeaxanthin'),  4,  'mg', 'active', '마리골드꽃추출물(지아잔틴)');

-- 고려은단 비타민C 1000
INSERT INTO product_ingredients (product_id, ingredient_id, amount_per_serving, amount_unit, ingredient_role, raw_label_name) VALUES
((SELECT id FROM products WHERE product_name = '고려은단 비타민C 1000'),
 (SELECT id FROM ingredients WHERE slug='vitamin-c'), 1000, 'mg', 'active', '아스코르브산');

-- 대웅제약 에너씨슬 밀크씨슬
INSERT INTO product_ingredients (product_id, ingredient_id, amount_per_serving, amount_unit, ingredient_role, raw_label_name) VALUES
((SELECT id FROM products WHERE product_name = '대웅제약 에너씨슬 밀크씨슬'),
 (SELECT id FROM ingredients WHERE slug='milk-thistle'), 130, 'mg', 'active', '밀크씨슬추출물(실리마린 104mg 함유)');

-- 쎌바이오텍 듀오락 골드
INSERT INTO product_ingredients (product_id, ingredient_id, amount_per_serving, amount_unit, ingredient_role, raw_label_name) VALUES
((SELECT id FROM products WHERE product_name = '쎌바이오텍 듀오락 골드 프로바이오틱스'),
 (SELECT id FROM ingredients WHERE slug='probiotics'), 50, '억 CFU', 'active', '프로바이오틱스 복합 균주 (락토바실러스 외 14종)');

-- 뉴트리원 비타민B 콤플렉스
INSERT INTO product_ingredients (product_id, ingredient_id, amount_per_serving, amount_unit, ingredient_role, raw_label_name) VALUES
((SELECT id FROM products WHERE product_name = '뉴트리원 비타민B 콤플렉스'),
 (SELECT id FROM ingredients WHERE slug='vitamin-b12'), 1000, 'mcg', 'active', '시아노코발라민(비타민B12)'),
((SELECT id FROM products WHERE product_name = '뉴트리원 비타민B 콤플렉스'),
 (SELECT id FROM ingredients WHERE slug='folate'),       400, 'mcg', 'active', '엽산'),
((SELECT id FROM products WHERE product_name = '뉴트리원 비타민B 콤플렉스'),
 (SELECT id FROM ingredients WHERE slug='biotin'),      5000, 'mcg', 'active', '비오틴');

-- GNM자연의품격 칼슘마그네슘아연비타민D
INSERT INTO product_ingredients (product_id, ingredient_id, amount_per_serving, amount_unit, ingredient_role, raw_label_name) VALUES
((SELECT id FROM products WHERE product_name = 'GNM자연의품격 칼슘마그네슘아연비타민D'),
 (SELECT id FROM ingredients WHERE slug='calcium'),   600,  'mg',  'active', '탄산칼슘'),
((SELECT id FROM products WHERE product_name = 'GNM자연의품격 칼슘마그네슘아연비타민D'),
 (SELECT id FROM ingredients WHERE slug='magnesium'), 200,  'mg',  'active', '산화마그네슘'),
((SELECT id FROM products WHERE product_name = 'GNM자연의품격 칼슘마그네슘아연비타민D'),
 (SELECT id FROM ingredients WHERE slug='zinc'),        8,  'mg',  'active', '글루콘산아연'),
((SELECT id FROM products WHERE product_name = 'GNM자연의품격 칼슘마그네슘아연비타민D'),
 (SELECT id FROM ingredients WHERE slug='vitamin-d'), 800,  'IU',  'active', '콜레칼시페롤');

-- 뉴트리디데이 프리미엄 오메가3
INSERT INTO product_ingredients (product_id, ingredient_id, amount_per_serving, amount_unit, ingredient_role, raw_label_name) VALUES
((SELECT id FROM products WHERE product_name = '뉴트리디데이 프리미엄 오메가3'),
 (SELECT id FROM ingredients WHERE slug='omega-3'), 1200, 'mg', 'active', '정제어유 (EPA 648mg, DHA 252mg)');

-- 한미양행 철분 플러스
INSERT INTO product_ingredients (product_id, ingredient_id, amount_per_serving, amount_unit, ingredient_role, raw_label_name) VALUES
((SELECT id FROM products WHERE product_name = '한미양행 철분 플러스'),
 (SELECT id FROM ingredients WHERE slug='iron'),      14, 'mg',  'active', '피로인산철'),
((SELECT id FROM products WHERE product_name = '한미양행 철분 플러스'),
 (SELECT id FROM ingredients WHERE slug='vitamin-c'), 60, 'mg',  'active', '아스코르브산(철분 흡수 보조)');

-- 일양약품 글루코사민 1500
INSERT INTO product_ingredients (product_id, ingredient_id, amount_per_serving, amount_unit, ingredient_role, raw_label_name) VALUES
((SELECT id FROM products WHERE product_name = '일양약품 글루코사민 1500'),
 (SELECT id FROM ingredients WHERE slug='glucosamine'), 1500, 'mg', 'active', '글루코사민염산염');

-- 뉴트리코어 MSM 플러스
INSERT INTO product_ingredients (product_id, ingredient_id, amount_per_serving, amount_unit, ingredient_role, raw_label_name) VALUES
((SELECT id FROM products WHERE product_name = '뉴트리코어 MSM 플러스'),
 (SELECT id FROM ingredients WHERE slug='msm'),         2000, 'mg', 'active', '메틸설포닐메탄(MSM)'),
((SELECT id FROM products WHERE product_name = '뉴트리코어 MSM 플러스'),
 (SELECT id FROM ingredients WHERE slug='glucosamine'),  500, 'mg', 'active', '글루코사민염산염');

-- 뉴트리디데이 가르시니아 캄보지아
INSERT INTO product_ingredients (product_id, ingredient_id, amount_per_serving, amount_unit, ingredient_role, raw_label_name) VALUES
((SELECT id FROM products WHERE product_name = '뉴트리디데이 가르시니아 캄보지아'),
 (SELECT id FROM ingredients WHERE slug='garcinia'), 1000, 'mg', 'active', '가르시니아캄보지아추출물(HCA 60% 함유)');

-- 에버콜라겐 타임 비오틴 콜라겐
INSERT INTO product_ingredients (product_id, ingredient_id, amount_per_serving, amount_unit, ingredient_role, raw_label_name) VALUES
((SELECT id FROM products WHERE product_name = '에버콜라겐 타임 비오틴 콜라겐'),
 (SELECT id FROM ingredients WHERE slug='collagen'),  2500, 'mg',  'active', '저분자 어류 콜라겐 펩타이드'),
((SELECT id FROM products WHERE product_name = '에버콜라겐 타임 비오틴 콜라겐'),
 (SELECT id FROM ingredients WHERE slug='biotin'),    5000, 'mcg', 'active', '비오틴'),
((SELECT id FROM products WHERE product_name = '에버콜라겐 타임 비오틴 콜라겐'),
 (SELECT id FROM ingredients WHERE slug='vitamin-c'), 100,  'mg',  'active', '아스코르브산');

-- 세노비스 셀레늄
INSERT INTO product_ingredients (product_id, ingredient_id, amount_per_serving, amount_unit, ingredient_role, raw_label_name) VALUES
((SELECT id FROM products WHERE product_name = '세노비스 셀레늄'),
 (SELECT id FROM ingredients WHERE slug='selenium'), 200, 'mcg', 'active', '셀레노메티오닌(셀레늄)');

-- 세노비스 비타민E 400IU
INSERT INTO product_ingredients (product_id, ingredient_id, amount_per_serving, amount_unit, ingredient_role, raw_label_name) VALUES
((SELECT id FROM products WHERE product_name = '세노비스 비타민E 400IU'),
 (SELECT id FROM ingredients WHERE slug='vitamin-e'), 400, 'IU', 'active', '천연 비타민E(d-알파토코페롤)');

-- 안국건강 비타민A 5000IU
INSERT INTO product_ingredients (product_id, ingredient_id, amount_per_serving, amount_unit, ingredient_role, raw_label_name) VALUES
((SELECT id FROM products WHERE product_name = '안국건강 비타민A 5000IU'),
 (SELECT id FROM ingredients WHERE slug='vitamin-a'), 5000, 'IU', 'active', '레티닐아세테이트(비타민A)');

-- 나우푸드 커큐민 500mg (iHerb KR)
INSERT INTO product_ingredients (product_id, ingredient_id, amount_per_serving, amount_unit, ingredient_role, raw_label_name) VALUES
((SELECT id FROM products WHERE product_name = '나우푸드 커큐민 500mg'),
 (SELECT id FROM ingredients WHERE slug='curcumin'), 500, 'mg', 'active', 'Curcumin Extract (Curcuma longa) Root (95% Curcuminoids)');

-- 동국제약 인사돌플러스
INSERT INTO product_ingredients (product_id, ingredient_id, amount_per_serving, amount_unit, ingredient_role, raw_label_name) VALUES
((SELECT id FROM products WHERE product_name = '동국제약 인사돌플러스'),
 (SELECT id FROM ingredients WHERE slug='red-ginseng'), 500,  'mg', 'active', '홍삼추출물분말'),
((SELECT id FROM products WHERE product_name = '동국제약 인사돌플러스'),
 (SELECT id FROM ingredients WHERE slug='vitamin-c'),    60,  'mg', 'active', '아스코르브산'),
((SELECT id FROM products WHERE product_name = '동국제약 인사돌플러스'),
 (SELECT id FROM ingredients WHERE slug='vitamin-b12'),  2.4, 'mcg','active', '시아노코발라민');

-- NOW Vitamin D3 5000 IU
INSERT INTO product_ingredients (product_id, ingredient_id, amount_per_serving, amount_unit, ingredient_role, raw_label_name) VALUES
((SELECT id FROM products WHERE product_name = 'NOW Vitamin D3 5000 IU'),
 (SELECT id FROM ingredients WHERE slug='vitamin-d'), 5000, 'IU', 'active', 'Vitamin D-3 (as Cholecalciferol)');

-- Citracal Calcium Citrate + D3
INSERT INTO product_ingredients (product_id, ingredient_id, amount_per_serving, amount_unit, ingredient_role, raw_label_name) VALUES
((SELECT id FROM products WHERE product_name = 'Citracal Calcium Citrate + D3'),
 (SELECT id FROM ingredients WHERE slug='calcium'),   630, 'mg',  'active', 'Calcium (as Calcium Citrate)'),
((SELECT id FROM products WHERE product_name = 'Citracal Calcium Citrate + D3'),
 (SELECT id FROM ingredients WHERE slug='vitamin-d'), 500, 'IU',  'active', 'Vitamin D3 (as Cholecalciferol)');

-- Doctor's Best Magnesium Glycinate 400mg
INSERT INTO product_ingredients (product_id, ingredient_id, amount_per_serving, amount_unit, ingredient_role, raw_label_name) VALUES
((SELECT id FROM products WHERE product_name = 'Doctor''s Best Magnesium Glycinate 400mg'),
 (SELECT id FROM ingredients WHERE slug='magnesium'), 400, 'mg', 'active', 'Magnesium (as Magnesium Glycinate Lysinate Chelate TRAACS®)');

-- Thorne Zinc Picolinate 30mg
INSERT INTO product_ingredients (product_id, ingredient_id, amount_per_serving, amount_unit, ingredient_role, raw_label_name) VALUES
((SELECT id FROM products WHERE product_name = 'Thorne Zinc Picolinate 30mg'),
 (SELECT id FROM ingredients WHERE slug='zinc'), 30, 'mg', 'active', 'Zinc (as Zinc Picolinate)');

-- Thorne Iron Bisglycinate 25mg
INSERT INTO product_ingredients (product_id, ingredient_id, amount_per_serving, amount_unit, ingredient_role, raw_label_name) VALUES
((SELECT id FROM products WHERE product_name = 'Thorne Iron Bisglycinate 25mg'),
 (SELECT id FROM ingredients WHERE slug='iron'), 25, 'mg', 'active', 'Iron (as Ferrous Bisglycinate Chelate)');

-- Nature Made Super B-Complex
INSERT INTO product_ingredients (product_id, ingredient_id, amount_per_serving, amount_unit, ingredient_role, raw_label_name) VALUES
((SELECT id FROM products WHERE product_name = 'Nature Made Super B-Complex'),
 (SELECT id FROM ingredients WHERE slug='vitamin-b12'),  6,    'mcg', 'active', 'Vitamin B12 (as Cyanocobalamin)'),
((SELECT id FROM products WHERE product_name = 'Nature Made Super B-Complex'),
 (SELECT id FROM ingredients WHERE slug='folate'),       400,  'mcg', 'active', 'Folic Acid'),
((SELECT id FROM products WHERE product_name = 'Nature Made Super B-Complex'),
 (SELECT id FROM ingredients WHERE slug='biotin'),       300,  'mcg', 'active', 'Biotin');

-- Nature's Bounty Milk Thistle 250mg
INSERT INTO product_ingredients (product_id, ingredient_id, amount_per_serving, amount_unit, ingredient_role, raw_label_name) VALUES
((SELECT id FROM products WHERE product_name = 'Nature''s Bounty Milk Thistle 250mg'),
 (SELECT id FROM ingredients WHERE slug='milk-thistle'), 250, 'mg', 'active', 'Milk Thistle Extract (Silybum marianum) Seed (standardized to 80% Silymarin)');

-- Qunol Ultra CoQ10 200mg
INSERT INTO product_ingredients (product_id, ingredient_id, amount_per_serving, amount_unit, ingredient_role, raw_label_name) VALUES
((SELECT id FROM products WHERE product_name = 'Qunol Ultra CoQ10 200mg'),
 (SELECT id FROM ingredients WHERE slug='coq10'), 200, 'mg', 'active', 'CoQ10 (Coenzyme Q10, Ubiquinone)');

-- Vital Proteins Collagen Peptides
INSERT INTO product_ingredients (product_id, ingredient_id, amount_per_serving, amount_unit, ingredient_role, raw_label_name) VALUES
((SELECT id FROM products WHERE product_name = 'Vital Proteins Collagen Peptides'),
 (SELECT id FROM ingredients WHERE slug='collagen'), 10000, 'mg', 'active', 'Bovine Hide Collagen Peptides');

-- Optimum Nutrition Creatine Monohydrate
INSERT INTO product_ingredients (product_id, ingredient_id, amount_per_serving, amount_unit, ingredient_role, raw_label_name) VALUES
((SELECT id FROM products WHERE product_name = 'Optimum Nutrition Creatine Monohydrate'),
 (SELECT id FROM ingredients WHERE slug='creatine'), 5000, 'mg', 'active', 'Creatine Monohydrate (Creapure®)');

-- Nature Made Turmeric Curcumin 500mg
INSERT INTO product_ingredients (product_id, ingredient_id, amount_per_serving, amount_unit, ingredient_role, raw_label_name) VALUES
((SELECT id FROM products WHERE product_name = 'Nature Made Turmeric Curcumin 500mg'),
 (SELECT id FROM ingredients WHERE slug='curcumin'), 500, 'mg', 'active', 'Turmeric Root Extract (Curcuma longa) (standardized to 95% Curcuminoids)');

-- Culturelle Daily Probiotic
INSERT INTO product_ingredients (product_id, ingredient_id, amount_per_serving, amount_unit, ingredient_role, raw_label_name) VALUES
((SELECT id FROM products WHERE product_name = 'Culturelle Daily Probiotic'),
 (SELECT id FROM ingredients WHERE slug='probiotics'), 10, '억 CFU', 'active', 'Lactobacillus rhamnosus GG (LGG®) 10 Billion CFU');

-- CheongKwanJang Korean Red Ginseng Extract
INSERT INTO product_ingredients (product_id, ingredient_id, amount_per_serving, amount_unit, ingredient_role, raw_label_name) VALUES
((SELECT id FROM products WHERE product_name = 'CheongKwanJang Korean Red Ginseng Extract'),
 (SELECT id FROM ingredients WHERE slug='red-ginseng'), 3000, 'mg', 'active', 'Korean Red Ginseng Extract (Panax ginseng C.A. Meyer)');

-- Doctor's Best OptiMSM 1500mg
INSERT INTO product_ingredients (product_id, ingredient_id, amount_per_serving, amount_unit, ingredient_role, raw_label_name) VALUES
((SELECT id FROM products WHERE product_name = 'Doctor''s Best OptiMSM 1500mg'),
 (SELECT id FROM ingredients WHERE slug='msm'), 1500, 'mg', 'active', 'OptiMSM® (Methylsulfonylmethane)');

-- Nature's Bounty Garcinia Cambogia 1000mg
INSERT INTO product_ingredients (product_id, ingredient_id, amount_per_serving, amount_unit, ingredient_role, raw_label_name) VALUES
((SELECT id FROM products WHERE product_name = 'Nature''s Bounty Garcinia Cambogia 1000mg'),
 (SELECT id FROM ingredients WHERE slug='garcinia'), 1000, 'mg', 'active', 'Garcinia Cambogia Extract (fruit rind) (60% Hydroxycitric Acid)');

-- ============================================================================
-- D. 라벨 스냅샷 (label_snapshots) — 전 신규 제품 35개
-- ============================================================================

INSERT INTO label_snapshots (product_id, label_version, source_name, serving_size_text, servings_per_container, warning_text, directions_text, is_current) VALUES

-- KR 제품 20개
((SELECT id FROM products WHERE product_name = '정관장 홍삼정 에브리타임'),
 'v1', '제품 패키지', '1일 1회, 1회 1포(10mL)', '30포/30일분',
 '특이체질이거나 알레르기 체질인 경우 또는 의약품 복용 시 전문가와 상담하십시오. 어린이 손에 닿지 않는 곳에 보관하십시오.',
 '1일 1포를 그대로 또는 물·음료에 희석하여 섭취하십시오.', true),

((SELECT id FROM products WHERE product_name = '정관장 홍삼톤 골드'),
 'v1', '제품 패키지', '1일 1~2회, 1회 1포(50mL)', '30포/30일분',
 '특이체질이거나 알레르기 체질인 경우 의사·약사와 상담하십시오. 냉장 보관 후 섭취하십시오.',
 '1일 1~2회, 1회 1포씩 그대로 섭취하거나 차게 하여 드십시오.', true),

((SELECT id FROM products WHERE product_name = '종근당 비타민D 1000IU'),
 'v1', '제품 패키지', '1일 1회, 1회 1정', '60정/60일분',
 '임산부·수유부·질환자는 섭취 전 전문가와 상담하십시오. 고칼슘혈증 환자는 섭취하지 마십시오.',
 '1일 1회, 1회 1정을 충분한 물과 함께 섭취하십시오.', true),

((SELECT id FROM products WHERE product_name = '종근당 아이클리어 루테인 지아잔틴'),
 'v1', '제품 패키지', '1일 1회, 1회 1캡슐', '30캡슐/30일분',
 '임산부·수유부·어린이·질환자는 섭취 전 전문가와 상담하십시오.',
 '1일 1회, 1회 1캡슐을 물과 함께 섭취하십시오. 식후 섭취를 권장합니다.', true),

((SELECT id FROM products WHERE product_name = '고려은단 비타민C 1000'),
 'v1', '제품 패키지', '1일 1회, 1회 1정', '60정/60일분',
 '신장질환자 또는 구연산·비타민C에 알레르기가 있는 경우 섭취하지 마십시오. 임산부·수유부는 전문가와 상담하십시오.',
 '1일 1회, 1정을 물과 함께 섭취하십시오. 공복 시 위장 장애가 있는 경우 식후에 섭취하십시오.', true),

((SELECT id FROM products WHERE product_name = '대웅제약 에너씨슬 밀크씨슬'),
 'v1', '제품 패키지', '1일 3회, 1회 1정', '90정/30일분',
 '임산부·수유부·어린이 또는 간 질환으로 치료 중인 경우 섭취 전 전문가와 상담하십시오.',
 '1일 3회, 1회 1정씩 식후 물과 함께 섭취하십시오.', true),

((SELECT id FROM products WHERE product_name = '쎌바이오텍 듀오락 골드 프로바이오틱스'),
 'v1', '제품 패키지', '1일 1회, 1회 1캡슐', '30캡슐/30일분',
 '면역 저하자·질환자는 섭취 전 전문가와 상담하십시오. 직사광선 및 고온다습한 장소를 피하여 냉장 보관하십시오.',
 '1일 1회, 1캡슐을 물과 함께 섭취하십시오. 식전 또는 공복에 섭취하는 것이 효과적입니다.', true),

((SELECT id FROM products WHERE product_name = '뉴트리원 비타민B 콤플렉스'),
 'v1', '제품 패키지', '1일 1회, 1회 1정', '60정/60일분',
 '임산부는 의사와 상담 후 섭취하십시오. 어린이 손에 닿지 않는 곳에 보관하십시오.',
 '1일 1회, 1회 1정을 충분한 물과 함께 섭취하십시오.', true),

((SELECT id FROM products WHERE product_name = 'GNM자연의품격 칼슘마그네슘아연비타민D'),
 'v1', '제품 패키지', '1일 1회, 1회 3정', '90정/30일분',
 '임산부·수유부·신장질환자는 섭취 전 전문가와 상담하십시오. 고칼슘혈증 환자는 섭취하지 마십시오.',
 '1일 1회, 1회 3정을 물과 함께 섭취하십시오.', true),

((SELECT id FROM products WHERE product_name = '뉴트리디데이 프리미엄 오메가3'),
 'v1', '제품 패키지', '1일 1회, 1회 2캡슐', '60캡슐/30일분',
 '항응고제 복용자는 섭취 전 전문가와 상담하십시오. 어패류 알레르기 있는 경우 주의하십시오.',
 '1일 1회, 2캡슐을 식후에 물과 함께 섭취하십시오. 냉동 보관 후 섭취하면 비린 맛이 감소합니다.', true),

((SELECT id FROM products WHERE product_name = '한미양행 철분 플러스'),
 'v1', '제품 패키지', '1일 1회, 1회 1정', '30정/30일분',
 '철분 과잉 흡수 관련 질환자는 섭취하지 마십시오. 어린이 손에 닿지 않는 곳에 보관하십시오.',
 '1일 1회, 1정을 충분한 물과 함께 섭취하십시오. 식간 또는 공복에 섭취하면 흡수율이 높아집니다.', true),

((SELECT id FROM products WHERE product_name = '일양약품 글루코사민 1500'),
 'v1', '제품 패키지', '1일 1회, 1회 3정', '90정/30일분',
 '갑각류 알레르기 있는 경우 섭취하지 마십시오. 당뇨 환자는 혈당 변화를 모니터링하십시오. 임산부는 섭취하지 마십시오.',
 '1일 1회, 1회 3정을 물과 함께 섭취하십시오.', true),

((SELECT id FROM products WHERE product_name = '뉴트리코어 MSM 플러스'),
 'v1', '제품 패키지', '1일 2회, 1회 2정', '120정/30일분',
 '임산부·수유부·어린이는 섭취 전 전문가와 상담하십시오. 설파 알레르기 있는 경우 주의하십시오.',
 '1일 2회, 1회 2정씩 식후 물과 함께 섭취하십시오.', true),

((SELECT id FROM products WHERE product_name = '뉴트리디데이 가르시니아 캄보지아'),
 'v1', '제품 패키지', '1일 3회, 1회 2캡슐', '180캡슐/30일분',
 '임산부·수유부·어린이는 섭취하지 마십시오. 간 질환이 있거나 간독성 약물 복용 시 전문가와 상담하십시오.',
 '1일 3회, 식사 30분~1시간 전에 2캡슐씩 물과 함께 섭취하십시오.', true),

((SELECT id FROM products WHERE product_name = '에버콜라겐 타임 비오틴 콜라겐'),
 'v1', '제품 패키지', '1일 1회, 1회 1포(2g)', '30포/30일분',
 '어패류 유래 콜라겐이 포함되어 있으므로 어패류 알레르기가 있는 경우 섭취하지 마십시오.',
 '1일 1회, 1포를 물 150~200mL에 녹여 섭취하십시오.', true),

((SELECT id FROM products WHERE product_name = '세노비스 셀레늄'),
 'v1', '제품 패키지', '1일 1회, 1회 1정', '60정/60일분',
 '셀레늄 상한섭취량(400mcg/일)을 초과하지 않도록 다른 셀레늄 함유 제품과 병용에 주의하십시오.',
 '1일 1회, 1회 1정을 물과 함께 섭취하십시오.', true),

((SELECT id FROM products WHERE product_name = '세노비스 비타민E 400IU'),
 'v1', '제품 패키지', '1일 1회, 1회 1캡슐', '60캡슐/60일분',
 '항응고제(와파린 등) 복용자는 섭취 전 전문가와 상담하십시오. 혈액 응고에 영향을 줄 수 있습니다.',
 '1일 1회, 1캡슐을 식사와 함께 섭취하십시오.', true),

((SELECT id FROM products WHERE product_name = '안국건강 비타민A 5000IU'),
 'v1', '제품 패키지', '1일 1회, 1회 1정', '30정/30일분',
 '임산부는 섭취하지 마십시오(태아 기형 위험). 비타민A 함유 제품 중복 섭취에 주의하십시오. 하루 10,000IU를 초과하지 마십시오.',
 '1일 1회, 1회 1정을 식사와 함께 물로 섭취하십시오.', true),

((SELECT id FROM products WHERE product_name = '나우푸드 커큐민 500mg'),
 'v1', 'Product Label', '1 capsule daily', '60 capsules / 60 servings',
 'If pregnant, nursing, taking medication, or have a medical condition, consult your doctor before use. Keep out of reach of children.',
 'Take 1 capsule daily, preferably with meals.', true),

((SELECT id FROM products WHERE product_name = '동국제약 인사돌플러스'),
 'v1', '제품 패키지', '1일 2회, 1회 1정', '60정/30일분',
 '특이체질이거나 알레르기 체질의 경우 전문가와 상담하십시오. 어린이 손에 닿지 않는 곳에 보관하십시오.',
 '1일 2회, 1회 1정씩 식후 물과 함께 섭취하십시오.', true),

-- US 제품 15개
((SELECT id FROM products WHERE product_name = 'NOW Vitamin D3 5000 IU'),
 'v1', 'Product Label', '1 softgel daily', '240 softgels / 240 servings',
 'Do not exceed recommended dosage. If pregnant, nursing, or taking medications consult your physician before use. Keep out of reach of children.',
 'As a dietary supplement, take 1 softgel daily with a meal.', true),

((SELECT id FROM products WHERE product_name = 'Citracal Calcium Citrate + D3'),
 'v1', 'Product Label', '2 caplets twice daily', '120 caplets / 60 servings',
 'Do not take more than recommended. If you have a history of kidney stones, consult your physician before use. Keep out of reach of children.',
 'Take 2 caplets twice daily, preferably with a meal. Swallow whole; do not crush or chew.', true),

((SELECT id FROM products WHERE product_name = 'Doctor''s Best Magnesium Glycinate 400mg'),
 'v1', 'Product Label', '2 tablets daily', '240 tablets / 120 servings',
 'Keep out of reach of children. If pregnant, nursing, or taking medications, consult your doctor before use.',
 'Take 2 tablets daily, preferably with food or as directed by a healthcare practitioner.', true),

((SELECT id FROM products WHERE product_name = 'Thorne Zinc Picolinate 30mg'),
 'v1', 'Product Label', '1 capsule daily', '60 capsules / 60 servings',
 'Keep out of reach of children. If pregnant, nursing, or taking medications, consult your physician before use. Do not exceed recommended dose.',
 'Take 1 capsule one to three times daily or as recommended by your health-care practitioner.', true),

((SELECT id FROM products WHERE product_name = 'Thorne Iron Bisglycinate 25mg'),
 'v1', 'Product Label', '1 capsule daily', '60 capsules / 60 servings',
 'Keep out of reach of children. WARNING: Accidental overdose of iron-containing products is a leading cause of fatal poisoning in children under 6. Keep this product out of reach of children.',
 'Take 1 capsule one to three times daily or as recommended by your health-care practitioner.', true),

((SELECT id FROM products WHERE product_name = 'Nature Made Super B-Complex'),
 'v1', 'Product Label', '1 tablet daily', '460 tablets / 460 servings',
 'If pregnant, nursing, or taking medication, consult your physician before use. Keep out of reach of children. Do not use if seal is broken.',
 'Take one tablet daily with a full glass of water and a meal.', true),

((SELECT id FROM products WHERE product_name = 'Nature''s Bounty Milk Thistle 250mg'),
 'v1', 'Product Label', '1 softgel daily', '200 softgels / 200 servings',
 'If you are pregnant, nursing, taking any medications or have any medical condition, consult your doctor before use. Keep out of reach of children.',
 'As a dietary supplement, take one (1) softgel daily, preferably with a meal.', true),

((SELECT id FROM products WHERE product_name = 'Qunol Ultra CoQ10 200mg'),
 'v1', 'Product Label', '1 softgel daily', '60 softgels / 60 servings',
 'If pregnant, nursing, or taking medications including blood thinners, consult your doctor before use. Keep out of reach of children.',
 'Take one (1) softgel daily with or without food.', true),

((SELECT id FROM products WHERE product_name = 'Vital Proteins Collagen Peptides'),
 'v1', 'Product Label', '2 scoops (20g) daily', '28 servings',
 'Contains: Bovine. If pregnant, nursing, taking any medications, or under the care of a physician, consult your health care professional before using. Keep out of reach of children.',
 'Mix 2 scoops into 8–12 oz of liquid such as coffee, smoothies, or water. Stir well and enjoy. Can be used hot or cold.', true),

((SELECT id FROM products WHERE product_name = 'Optimum Nutrition Creatine Monohydrate'),
 'v1', 'Product Label', '1 teaspoon (5g) daily', '114 servings',
 'Not intended for use by persons under 18. Do not use if pregnant or nursing. Consult a physician prior to use if you have any medical condition.',
 'On training days, mix 1 teaspoon (5g) with 8 oz of cold water or your preferred beverage. On non-training days, take 1 serving at any time.', true),

((SELECT id FROM products WHERE product_name = 'Nature Made Turmeric Curcumin 500mg'),
 'v1', 'Product Label', '2 capsules daily', '90 capsules / 45 servings',
 'If pregnant, nursing, or taking any medications including blood thinners, consult your physician before use. Keep out of reach of children.',
 'Take 2 capsules daily with water and a meal.', true),

((SELECT id FROM products WHERE product_name = 'Culturelle Daily Probiotic'),
 'v1', 'Product Label', '1 capsule daily', '30 capsules / 30 servings',
 'If you have an immune-compromised condition, consult a physician before use. Keep out of reach of children. Store in a cool, dry place.',
 'Take one (1) capsule daily. Can be taken with or without food.', true),

((SELECT id FROM products WHERE product_name = 'CheongKwanJang Korean Red Ginseng Extract'),
 'v1', 'Product Label', '1 stick daily (10mL)', '30 sticks / 30 servings',
 'Do not use if you are pregnant. Consult your physician if you are taking blood thinners or immunosuppressants. Keep out of reach of children.',
 'Take one stick daily, preferably in the morning. May be taken directly or mixed with water.', true),

((SELECT id FROM products WHERE product_name = 'Doctor''s Best OptiMSM 1500mg'),
 'v1', 'Product Label', '1 tablet daily', '120 tablets / 120 servings',
 'If pregnant, nursing, or taking medications, consult your doctor before use. Keep out of reach of children.',
 'Take 1 tablet one to four times daily with or without food, or as recommended by a nutritionally-informed physician.', true),

((SELECT id FROM products WHERE product_name = 'Nature''s Bounty Garcinia Cambogia 1000mg'),
 'v1', 'Product Label', '2 capsules 3 times daily', '90 capsules / 45 servings',
 'Not for use by individuals under the age of 18. If pregnant, nursing, or taking any medications, consult your doctor before use. Keep out of reach of children.',
 'Take 2 capsules 3 times daily, 30–60 minutes before each meal with a full glass of water.', true);
