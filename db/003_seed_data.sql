-- ============================================================================
-- 시드 데이터 — MVP 초기 적재
-- Version: 1.0.0
-- 대상: code_values, ingredients(20종), claims, ingredient_claims,
--       safety_items, dosage_guidelines, products(10개), product_ingredients,
--       label_snapshots, sources
-- ============================================================================

-- ============================================================================
-- 0. 코드 테이블 마스터
-- ============================================================================

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
('recommendation_type','권장 유형',       'Recommendation Type','RDA, UL, AI 등');

-- ============================================================================
-- 0-1. 코드 값
-- ============================================================================

-- ingredient_type
INSERT INTO code_values (code_table_id, code, label_ko, label_en, sort_order) VALUES
((SELECT id FROM code_tables WHERE table_code='ingredient_type'), 'vitamin',    '비타민',       'Vitamin',     1),
((SELECT id FROM code_tables WHERE table_code='ingredient_type'), 'mineral',    '미네랄',       'Mineral',     2),
((SELECT id FROM code_tables WHERE table_code='ingredient_type'), 'amino_acid', '아미노산',     'Amino Acid',  3),
((SELECT id FROM code_tables WHERE table_code='ingredient_type'), 'fatty_acid', '지방산',       'Fatty Acid',  4),
((SELECT id FROM code_tables WHERE table_code='ingredient_type'), 'probiotic',  '프로바이오틱스','Probiotic',   5),
((SELECT id FROM code_tables WHERE table_code='ingredient_type'), 'herbal',     '허브/식물성',  'Herbal',      6),
((SELECT id FROM code_tables WHERE table_code='ingredient_type'), 'enzyme',     '효소',         'Enzyme',      7),
((SELECT id FROM code_tables WHERE table_code='ingredient_type'), 'other',      '기타',         'Other',       8);

-- safety_type
INSERT INTO code_values (code_table_id, code, label_ko, label_en, sort_order) VALUES
((SELECT id FROM code_tables WHERE table_code='safety_type'), 'adverse_effect',   '이상반응',     'Adverse Effect',    1),
((SELECT id FROM code_tables WHERE table_code='safety_type'), 'contraindication', '금기',         'Contraindication',  2),
((SELECT id FROM code_tables WHERE table_code='safety_type'), 'precaution',       '주의사항',     'Precaution',        3),
((SELECT id FROM code_tables WHERE table_code='safety_type'), 'drug_interaction', '약물상호작용', 'Drug Interaction',  4),
((SELECT id FROM code_tables WHERE table_code='safety_type'), 'pregnancy',        '임신/수유',    'Pregnancy',         5),
((SELECT id FROM code_tables WHERE table_code='safety_type'), 'pediatric',        '소아',         'Pediatric',         6),
((SELECT id FROM code_tables WHERE table_code='safety_type'), 'overdose',         '과다복용',     'Overdose',          7);

-- severity_level
INSERT INTO code_values (code_table_id, code, label_ko, label_en, sort_order) VALUES
((SELECT id FROM code_tables WHERE table_code='severity_level'), 'critical', '심각',   'Critical', 1),
((SELECT id FROM code_tables WHERE table_code='severity_level'), 'serious',  '중대',   'Serious',  2),
((SELECT id FROM code_tables WHERE table_code='severity_level'), 'moderate', '보통',   'Moderate', 3),
((SELECT id FROM code_tables WHERE table_code='severity_level'), 'mild',     '경미',   'Mild',     4);

-- claim_scope
INSERT INTO code_values (code_table_id, code, label_ko, label_en, sort_order) VALUES
((SELECT id FROM code_tables WHERE table_code='claim_scope'), 'approved_kr', '식약처 인정',  'MFDS Approved',  1),
((SELECT id FROM code_tables WHERE table_code='claim_scope'), 'approved_us', 'FDA 인정',     'FDA Approved',   2),
((SELECT id FROM code_tables WHERE table_code='claim_scope'), 'studied',     '학술 연구',    'Studied',        3),
((SELECT id FROM code_tables WHERE table_code='claim_scope'), 'traditional', '전통적 사용',  'Traditional',    4),
((SELECT id FROM code_tables WHERE table_code='claim_scope'), 'prohibited',  '금지 표현',    'Prohibited',     5);

-- evidence_grade
INSERT INTO code_values (code_table_id, code, label_ko, label_en, sort_order) VALUES
((SELECT id FROM code_tables WHERE table_code='evidence_grade'), 'A', '매우 강함', 'Strong',         1),
((SELECT id FROM code_tables WHERE table_code='evidence_grade'), 'B', '강함',     'Good',           2),
((SELECT id FROM code_tables WHERE table_code='evidence_grade'), 'C', '보통',     'Fair',           3),
((SELECT id FROM code_tables WHERE table_code='evidence_grade'), 'D', '약함',     'Limited',        4),
((SELECT id FROM code_tables WHERE table_code='evidence_grade'), 'F', '불충분',   'Insufficient',   5);

-- product_type
INSERT INTO code_values (code_table_id, code, label_ko, label_en, sort_order) VALUES
((SELECT id FROM code_tables WHERE table_code='product_type'), 'health_functional_food', '건강기능식품',     'Health Functional Food', 1),
((SELECT id FROM code_tables WHERE table_code='product_type'), 'dietary_supplement',     '다이어터리 서플',  'Dietary Supplement',     2),
((SELECT id FROM code_tables WHERE table_code='product_type'), 'general_food',           '일반식품',         'General Food',           3);

-- ============================================================================
-- 1. 원료 20종
-- ============================================================================

INSERT INTO ingredients (canonical_name_ko, canonical_name_en, display_name, scientific_name, slug, ingredient_type, description, origin_type, form_description, standardization_info, is_active, is_published) VALUES
('비타민 D',      'Vitamin D',       '비타민 D',      'Cholecalciferol',            'vitamin-d',       'vitamin',    '칼슘 흡수와 면역 기능에 필수적인 지용성 비타민. 햇빛 노출로 체내 합성 가능.',                          'synthetic', 'D3 (콜레칼시페롤), D2 (에르고칼시페롤)',  '1mcg = 40IU',            true, true),
('비타민 C',      'Vitamin C',       '비타민 C',      'Ascorbic acid',              'vitamin-c',       'vitamin',    '항산화 기능, 콜라겐 합성, 면역 기능에 관여하는 수용성 비타민.',                                        'synthetic', '아스코르브산, 칼슘 아스코르베이트',       NULL,                     true, true),
('비타민 B12',    'Vitamin B12',     '비타민 B12',    'Cyanocobalamin',             'vitamin-b12',     'vitamin',    '적혈구 형성, 신경 기능, DNA 합성에 필수. 채식주의자에게 결핍 흔함.',                                   'synthetic', '시아노코발라민, 메틸코발라민',            NULL,                     true, true),
('엽산',          'Folate',          '엽산',          'Folic acid',                 'folate',          'vitamin',    '세포 분열, DNA 합성에 필수. 임신 중 신경관 결손 예방에 중요.',                                         'synthetic', '폴산(합성), 5-MTHF(활성형)',             '1mcg DFE = 0.6mcg 폴산', true, true),
('오메가-3',      'Omega-3',         '오메가-3',      'EPA/DHA',                    'omega-3',         'fatty_acid', 'EPA와 DHA를 포함하는 필수 지방산. 심혈관, 뇌 건강에 관여.',                                            'natural',   '어유, 크릴오일, 미세조류 유래',           'EPA+DHA 합계 기준',      true, true),
('마그네슘',      'Magnesium',       '마그네슘',      'Magnesium',                  'magnesium',       'mineral',    '300종 이상의 효소 반응에 관여. 근육, 신경, 뼈 건강에 필수.',                                           'synthetic', '산화물, 구연산, 비스글리시네이트',        '원소 마그네슘 기준',     true, true),
('아연',          'Zinc',            '아연',          'Zinc',                       'zinc',            'mineral',    '면역 기능, 상처 치유, 단백질 합성에 관여하는 필수 미량 원소.',                                         'synthetic', '글루콘산, 피콜리네이트, 황산아연',        '원소 아연 기준',         true, true),
('철분',          'Iron',            '철분',          'Ferrous/Ferric iron',        'iron',            'mineral',    '헤모글로빈 구성, 산소 운반에 필수. 결핍 시 빈혈 발생.',                                                'synthetic', '황산제일철, 퓨마르산, 비스글리시네이트',  '원소 철 기준',           true, true),
('칼슘',          'Calcium',         '칼슘',          'Calcium',                    'calcium',         'mineral',    '뼈와 치아 구성, 근육 수축, 신경 전달에 필수.',                                                        'natural',   '탄산칼슘, 구연산칼슘, 인산칼슘',          '원소 칼슘 기준',         true, true),
('프로바이오틱스', 'Probiotics',      '프로바이오틱스', 'Lactobacillus/Bifidobacterium', 'probiotics',   'probiotic',  '장내 미생물 균형에 기여하는 유익한 미생물. 면역, 소화 건강에 관여.',                                    'natural',   '락토바실러스, 비피도박테리움 등',          'CFU 기준',               true, true),
('루테인',        'Lutein',          '루테인',        'Lutein',                     'lutein',          'herbal',     '눈의 황반에 존재하는 카로티노이드. 블루라이트 차단, 황반변성 예방에 관여.',                              'natural',   '마리골드 추출물',                         NULL,                     true, true),
('코엔자임Q10',   'CoQ10',           '코엔자임Q10',   'Ubiquinone',                 'coq10',           'other',      '세포 에너지 생성(미토콘드리아)에 관여하는 항산화 물질. 나이 들수록 체내 합성 감소.',                     'synthetic', '유비퀴논(산화형), 유비퀴놀(환원형)',       NULL,                     true, true),
('밀크씨슬',      'Milk Thistle',    '밀크씨슬',      'Silybum marianum',           'milk-thistle',    'herbal',     '실리마린 성분이 간세포 보호에 관여. 전통적으로 간 건강에 사용.',                                        'natural',   '실리마린 추출물',                         '실리마린 80% 표준화',    true, true),
('글루코사민',    'Glucosamine',     '글루코사민',    'Glucosamine',                'glucosamine',     'amino_acid', '관절 연골 구성 성분. 관절 건강 유지에 사용.',                                                          'synthetic', '글루코사민 황산염, 염산염',               NULL,                     true, true),
('비오틴',        'Biotin',          '비오틴',        'Biotin',                     'biotin',          'vitamin',    '에너지 대사, 피부·모발·손톱 건강에 관여하는 수용성 비타민 (B7).',                                       'synthetic', NULL,                                      NULL,                     true, true),
('셀레늄',        'Selenium',        '셀레늄',        'Selenium',                   'selenium',        'mineral',    '항산화 효소의 구성 성분. 갑상선 기능, 면역에 관여.',                                                   'synthetic', '셀레노메티오닌, 아셀렌산나트륨',          '원소 셀레늄 기준',       true, true),
('비타민 A',      'Vitamin A',       '비타민 A',      'Retinol',                    'vitamin-a',       'vitamin',    '시력, 면역 기능, 피부 건강에 필수적인 지용성 비타민.',                                                  'synthetic', '레티놀, 베타카로틴(전구체)',              '1mcg RAE = 12mcg 베타카로틴', true, true),
('비타민 E',      'Vitamin E',       '비타민 E',      'Tocopherol',                 'vitamin-e',       'vitamin',    '지용성 항산화 비타민. 세포막 보호, 피부 건강에 관여.',                                                  'natural',   '알파토코페롤, 혼합 토코페롤',             '1mg = 1.49IU(d-alpha)',  true, true),
('커큐민',        'Curcumin',        '커큐민',        'Curcuma longa',              'curcumin',        'herbal',     '강황의 주요 활성 성분. 항염, 항산화 작용이 연구됨. 체내 흡수율이 낮아 제형이 중요.',                     'natural',   '강황 추출물, 피페린 복합',                '커큐미노이드 95% 표준화', true, true),
('멜라토닌',      'Melatonin',       '멜라토닌',      'Melatonin',                  'melatonin',       'other',      '수면-각성 주기를 조절하는 호르몬. 시차 적응, 수면 개선에 사용. 한국에서는 전문의약품.',                  'synthetic', NULL,                                      NULL,                     true, true);

-- ============================================================================
-- 2. 기능성(Claims) 시드
-- ============================================================================

INSERT INTO claims (claim_code, claim_name_ko, claim_name_en, claim_category, claim_scope, description) VALUES
('BONE_HEALTH',      '뼈 건강에 도움',                  'Bone Health',              'bone_joint',    'approved_kr', '뼈의 형성과 유지에 필요'),
('IMMUNE_FUNCTION',  '면역 기능 개선에 도움',            'Immune Function',          'immune',        'approved_kr', '정상적인 면역 기능에 필요'),
('ANTIOXIDANT',      '항산화에 도움',                   'Antioxidant',              'antioxidant',   'approved_kr', '유해산소로부터 세포를 보호하는 데 필요'),
('EYE_HEALTH',       '눈 건강에 도움',                  'Eye Health',               'eye',           'approved_kr', '노화로 인해 감소될 수 있는 황반색소밀도를 유지'),
('LIVER_HEALTH',     '간 건강에 도움',                  'Liver Health',             'liver',         'approved_kr', '간 건강에 도움을 줄 수 있음'),
('JOINT_HEALTH',     '관절 건강에 도움',                'Joint Health',             'bone_joint',    'approved_kr', '관절 건강에 도움을 줄 수 있음'),
('GUT_HEALTH',       '장 건강에 도움',                  'Gut Health',               'digestive',     'approved_kr', '유익균 증식 및 유해균 억제'),
('BLOOD_LIPID',      '혈중 중성지질 개선에 도움',        'Blood Lipid',              'cardiovascular','approved_kr', '혈중 중성지방 수치를 낮추는 데 도움'),
('SKIN_HEALTH',      '피부 건강에 도움',                'Skin Health',              'skin_hair',     'approved_kr', '피부 보습에 도움'),
('ENERGY_METABOLISM', '에너지 대사에 도움',              'Energy Metabolism',        'energy',        'approved_kr', '체내 에너지 생성에 필요'),
('RBC_FORMATION',    '적혈구 형성에 도움',              'Red Blood Cell Formation', 'blood',         'approved_kr', '정상적인 적혈구 형성에 필요'),
('NEURAL_TUBE',      '태아 신경관 정상 발달에 도움',     'Neural Tube Development',  'pregnancy',     'approved_kr', '태아 신경관의 정상 발달에 필요'),
('SLEEP_AID',        '수면 개선에 도움',                'Sleep Aid',                'sleep',         'studied',     '수면의 질 개선에 관한 연구 결과가 있음'),
('ANTI_INFLAMMATORY','항염 작용',                       'Anti-inflammatory',        'anti_inflammatory','studied',  '염증 반응 억제에 관한 연구 결과가 있음'),
('THYROID_FUNCTION', '갑상선 기능에 도움',              'Thyroid Function',         'endocrine',     'approved_kr', '갑상선 호르몬 합성에 필요'),
('CARDIOVASCULAR',   '심혈관 건강에 도움',              'Cardiovascular Health',    'cardiovascular','studied',     '심혈관 건강 유지에 관한 연구 결과가 있음'),
('HAIR_NAIL',        '모발·손톱 건강에 도움',           'Hair & Nail Health',       'skin_hair',     'studied',     '모발 및 손톱 건강 유지에 관한 연구'),
('COLLAGEN_SYNTHESIS','콜라겐 합성에 도움',             'Collagen Synthesis',       'skin_hair',     'approved_kr', '결합조직 형성과 기능유지에 필요');

-- ============================================================================
-- 3. 원료-기능성 연결 (ingredient_claims)
-- ============================================================================

INSERT INTO ingredient_claims (ingredient_id, claim_id, evidence_grade, evidence_summary, is_regulator_approved, approval_country_code, allowed_expression) VALUES
-- 비타민 D
((SELECT id FROM ingredients WHERE slug='vitamin-d'), (SELECT id FROM claims WHERE claim_code='BONE_HEALTH'),     'A', '다수의 메타분석에서 뼈 건강 효과 확인', true,  'KR', '뼈의 형성과 유지에 필요'),
((SELECT id FROM ingredients WHERE slug='vitamin-d'), (SELECT id FROM claims WHERE claim_code='IMMUNE_FUNCTION'), 'B', '면역세포 조절에 관한 임상 연구 다수',   true,  'KR', '정상적인 면역 기능에 필요'),
-- 비타민 C
((SELECT id FROM ingredients WHERE slug='vitamin-c'), (SELECT id FROM claims WHERE claim_code='ANTIOXIDANT'),     'A', '강력한 수용성 항산화제로 확립',         true,  'KR', '유해산소로부터 세포를 보호하는데 필요'),
((SELECT id FROM ingredients WHERE slug='vitamin-c'), (SELECT id FROM claims WHERE claim_code='IMMUNE_FUNCTION'), 'B', '면역세포 기능 지원에 관한 근거',        true,  'KR', '정상적인 면역 기능에 필요'),
((SELECT id FROM ingredients WHERE slug='vitamin-c'), (SELECT id FROM claims WHERE claim_code='COLLAGEN_SYNTHESIS'), 'A', '콜라겐 합성 보조인자로 필수적',       true,  'KR', '결합조직 형성과 기능유지에 필요'),
-- 오메가-3
((SELECT id FROM ingredients WHERE slug='omega-3'), (SELECT id FROM claims WHERE claim_code='BLOOD_LIPID'),       'A', '혈중 중성지방 감소 효과 메타분석 확인', true,  'KR', '혈중 중성지질 개선에 도움을 줄 수 있음'),
((SELECT id FROM ingredients WHERE slug='omega-3'), (SELECT id FROM claims WHERE claim_code='CARDIOVASCULAR'),    'B', '심혈관 보호 효과 다수 연구',            false, NULL, NULL),
-- 마그네슘
((SELECT id FROM ingredients WHERE slug='magnesium'), (SELECT id FROM claims WHERE claim_code='ENERGY_METABOLISM'), 'A', '300+ 효소 반응의 보조인자',            true,  'KR', '에너지 이용에 필요'),
((SELECT id FROM ingredients WHERE slug='magnesium'), (SELECT id FROM claims WHERE claim_code='BONE_HEALTH'),      'B', '뼈 건강에 관여 (칼슘과 시너지)',       true,  'KR', '뼈의 형성과 유지에 필요'),
-- 프로바이오틱스
((SELECT id FROM ingredients WHERE slug='probiotics'), (SELECT id FROM claims WHERE claim_code='GUT_HEALTH'),      'A', '장내 미생물 균형에 다수 근거',         true,  'KR', '유익균 증식 및 유해균 억제에 도움'),
-- 루테인
((SELECT id FROM ingredients WHERE slug='lutein'), (SELECT id FROM claims WHERE claim_code='EYE_HEALTH'),          'A', '황반색소밀도 유지 효과 확인',          true,  'KR', '노화로 인해 감소될 수 있는 황반색소밀도를 유지'),
-- 밀크씨슬
((SELECT id FROM ingredients WHERE slug='milk-thistle'), (SELECT id FROM claims WHERE claim_code='LIVER_HEALTH'),  'B', '간세포 보호 효과 임상 연구',           true,  'KR', '간 건강에 도움을 줄 수 있음'),
-- 글루코사민
((SELECT id FROM ingredients WHERE slug='glucosamine'), (SELECT id FROM claims WHERE claim_code='JOINT_HEALTH'),   'B', '관절 건강 유지 효과 일부 연구',        true,  'KR', '관절 건강에 도움을 줄 수 있음'),
-- 엽산
((SELECT id FROM ingredients WHERE slug='folate'), (SELECT id FROM claims WHERE claim_code='NEURAL_TUBE'),         'A', '신경관 결손 예방 강력한 근거',         true,  'KR', '태아 신경관의 정상 발달에 필요'),
((SELECT id FROM ingredients WHERE slug='folate'), (SELECT id FROM claims WHERE claim_code='RBC_FORMATION'),       'A', '적혈구 형성에 필수',                   true,  'KR', '정상적인 적혈구 형성에 필요'),
-- 아연
((SELECT id FROM ingredients WHERE slug='zinc'), (SELECT id FROM claims WHERE claim_code='IMMUNE_FUNCTION'),       'A', '면역 기능에 필수적 미량 원소',         true,  'KR', '정상적인 면역 기능에 필요'),
-- 철분
((SELECT id FROM ingredients WHERE slug='iron'), (SELECT id FROM claims WHERE claim_code='RBC_FORMATION'),         'A', '헤모글로빈 합성에 필수',               true,  'KR', '체내 산소운반과 혈액생성에 필요'),
-- 커큐민
((SELECT id FROM ingredients WHERE slug='curcumin'), (SELECT id FROM claims WHERE claim_code='ANTI_INFLAMMATORY'), 'C', '항염 효과 in vitro/소규모 임상',       false, NULL, NULL),
-- 멜라토닌
((SELECT id FROM ingredients WHERE slug='melatonin'), (SELECT id FROM claims WHERE claim_code='SLEEP_AID'),        'A', '수면 잠복기 단축 효과 메타분석 확인',  false, NULL, NULL),
-- 비오틴
((SELECT id FROM ingredients WHERE slug='biotin'), (SELECT id FROM claims WHERE claim_code='HAIR_NAIL'),           'C', '결핍 시 효과 있으나, 정상인에서 근거 제한적', false, NULL, NULL),
-- 셀레늄
((SELECT id FROM ingredients WHERE slug='selenium'), (SELECT id FROM claims WHERE claim_code='ANTIOXIDANT'),       'B', '글루타치온 퍼옥시다제 보조인자',       true,  'KR', '유해산소로부터 세포를 보호하는데 필요'),
((SELECT id FROM ingredients WHERE slug='selenium'), (SELECT id FROM claims WHERE claim_code='THYROID_FUNCTION'),  'B', '갑상선 호르몬 대사에 필수',            true,  'KR', '갑상선 호르몬 합성에 필요'),
-- 칼슘
((SELECT id FROM ingredients WHERE slug='calcium'), (SELECT id FROM claims WHERE claim_code='BONE_HEALTH'),        'A', '뼈 건강의 핵심 구성 성분',             true,  'KR', '뼈와 치아 형성에 필요'),
-- 비타민 B12
((SELECT id FROM ingredients WHERE slug='vitamin-b12'), (SELECT id FROM claims WHERE claim_code='RBC_FORMATION'),  'A', '적혈구 성숙에 필수',                   true,  'KR', '정상적인 적혈구 형성에 필요'),
-- 비타민 A
((SELECT id FROM ingredients WHERE slug='vitamin-a'), (SELECT id FROM claims WHERE claim_code='EYE_HEALTH'),       'A', '시각 기능 유지에 필수',                true,  'KR', '어두운 곳에서 시각 적응을 위해 필요'),
-- CoQ10
((SELECT id FROM ingredients WHERE slug='coq10'), (SELECT id FROM claims WHERE claim_code='ANTIOXIDANT'),          'B', '미토콘드리아 항산화 기능',              false, NULL, NULL),
-- 비타민 E
((SELECT id FROM ingredients WHERE slug='vitamin-e'), (SELECT id FROM claims WHERE claim_code='ANTIOXIDANT'),      'A', '지용성 세포막 항산화제로 확립',        true,  'KR', '유해산소로부터 세포를 보호하는데 필요');

-- ============================================================================
-- 4. 안전성 정보 (safety_items) — 주요 원료만
-- ============================================================================

INSERT INTO safety_items (ingredient_id, safety_type, title, description, severity_level, evidence_level, applies_to_population, management_advice) VALUES
-- 비타민 D
((SELECT id FROM ingredients WHERE slug='vitamin-d'), 'overdose',         '비타민 D 과다복용',          '고칼슘혈증, 신장 손상 가능. 하루 4,000IU 이상 장기 복용 시 주의.', 'serious',  'A', '성인', '혈중 25(OH)D 수치 모니터링'),
((SELECT id FROM ingredients WHERE slug='vitamin-d'), 'drug_interaction', '비타민 D-이뇨제 상호작용',   'Thiazide 이뇨제와 병용 시 고칼슘혈증 위험 증가.',                  'moderate', 'B', '이뇨제 복용자', '칼슘 수치 정기 검사'),
-- 오메가-3
((SELECT id FROM ingredients WHERE slug='omega-3'), 'adverse_effect',     '오메가-3 소화기 이상반응',   '비린내, 트림, 소화불량, 설사 가능.',                                'mild',     'A', '성인', '식후 복용, 냉동 후 복용'),
((SELECT id FROM ingredients WHERE slug='omega-3'), 'drug_interaction',   '오메가-3-항응고제 상호작용', '와파린 등 항응고제와 병용 시 출혈 위험 증가 가능.',                 'serious',  'B', '항응고제 복용자', '담당의와 상담'),
-- 철분
((SELECT id FROM ingredients WHERE slug='iron'), 'adverse_effect',        '철분 소화기 장애',           '변비, 구역, 위장 자극 흔함.',                                      'mild',     'A', '성인', '식후 복용, 저용량부터 시작'),
((SELECT id FROM ingredients WHERE slug='iron'), 'overdose',              '철분 과다복용',              '급성 중독(특히 소아) 위험. 만성 과잉 시 장기 손상.',                'critical', 'A', '소아', '어린이 손에 닿지 않는 곳 보관'),
-- 비타민 A
((SELECT id FROM ingredients WHERE slug='vitamin-a'), 'pregnancy',        '비타민 A 임신 중 과다복용',  '레티놀 과다 시 태아 기형 위험. 임신 중 10,000IU 이상 금지.',        'critical', 'A', '임산부', '베타카로틴 형태 선택 권장'),
-- 멜라토닌
((SELECT id FROM ingredients WHERE slug='melatonin'), 'precaution',       '멜라토닌 주간 졸음',         '복용 후 졸음 발생 가능. 운전·기계 조작 주의.',                     'moderate', 'A', '성인', '취침 30분~1시간 전 복용'),
-- 마그네슘
((SELECT id FROM ingredients WHERE slug='magnesium'), 'adverse_effect',   '마그네슘 설사',              '고용량(특히 산화마그네슘) 시 삼투성 설사 가능.',                    'mild',     'A', '성인', '비스글리시네이트 형태 선택 또는 분할 복용');

-- ============================================================================
-- 5. 용량 가이드라인 (dosage_guidelines) — 주요 원료
-- ============================================================================

INSERT INTO dosage_guidelines (ingredient_id, population_group, indication_context, dose_min, dose_max, dose_unit, frequency_text, route, recommendation_type, notes) VALUES
-- 비타민 D
((SELECT id FROM ingredients WHERE slug='vitamin-d'), '성인 (19~64세)', '일반 건강',      600,  2000, 'IU',  '1일 1회',  'oral', 'RDA',   '결핍 시 더 높은 용량 필요할 수 있음'),
((SELECT id FROM ingredients WHERE slug='vitamin-d'), '65세 이상',      '일반 건강',      800,  4000, 'IU',  '1일 1회',  'oral', 'RDA',   '상한섭취량(UL) 4,000IU/일'),
-- 비타민 C
((SELECT id FROM ingredients WHERE slug='vitamin-c'), '성인',           '일반 건강',      100,  2000, 'mg',  '1일 1~2회','oral', 'RDA',   '한국 RDA 100mg. UL 2,000mg'),
-- 오메가-3
((SELECT id FROM ingredients WHERE slug='omega-3'), '성인',             '혈중 중성지방',  500,  2000, 'mg',  '1일 1~2회','oral', 'RDA',   'EPA+DHA 합계. 식약처 인정 500~2000mg'),
-- 마그네슘
((SELECT id FROM ingredients WHERE slug='magnesium'), '성인 남성',      '일반 건강',      350,  400,  'mg',  '1일 1~2회','oral', 'RDA',   '원소 마그네슘 기준. 분할 복용 권장'),
((SELECT id FROM ingredients WHERE slug='magnesium'), '성인 여성',      '일반 건강',      280,  310,  'mg',  '1일 1~2회','oral', 'RDA',   '원소 마그네슘 기준'),
-- 아연
((SELECT id FROM ingredients WHERE slug='zinc'), '성인 남성',           '일반 건강',      8.5,  11,   'mg',  '1일 1회',  'oral', 'RDA',   'UL 40mg'),
-- 철분
((SELECT id FROM ingredients WHERE slug='iron'), '성인 여성 (가임기)',  '빈혈 예방',      14,   18,   'mg',  '1일 1회',  'oral', 'RDA',   '원소 철 기준. UL 45mg'),
-- 엽산
((SELECT id FROM ingredients WHERE slug='folate'), '임산부',            '신경관 결손 예방', 400, 800,  'mcg DFE', '1일 1회', 'oral', 'RDA', '임신 전 4주~임신 12주까지 특히 중요'),
-- 프로바이오틱스
((SELECT id FROM ingredients WHERE slug='probiotics'), '성인',          '장 건강',        1,    100,  '억 CFU', '1일 1회', 'oral', 'AI',   '균주에 따라 권장량 상이'),
-- 루테인
((SELECT id FROM ingredients WHERE slug='lutein'), '성인',              '눈 건강',        10,   20,   'mg',  '1일 1회',  'oral', 'AI',    'AREDS2 연구 기준 10mg'),
-- 칼슘
((SELECT id FROM ingredients WHERE slug='calcium'), '성인',             '뼈 건강',        700,  1000, 'mg',  '1일 1~2회','oral', 'RDA',   '원소 칼슘 기준. 1회 500mg 이하 분할 권장');

-- ============================================================================
-- 6. 제품 시드 (10개)
-- ============================================================================

INSERT INTO products (product_name, brand_name, manufacturer_name, country_code, product_type, status, is_published) VALUES
('종근당 칼슘 마그네슘 비타민D 아연',         '종근당건강',    '종근당건강',           'KR', 'health_functional_food', 'active', true),
('뉴트리원 루테인 오메가3',                   '뉴트리원',      '뉴트리원',             'KR', 'health_functional_food', 'active', true),
('닥터린 멀티비타민 미네랄',                   '닥터린',        '일동제약',             'KR', 'health_functional_food', 'active', true),
('솔가 비타민 D3 1000IU',                     'Solgar',       'Solgar Inc.',          'US', 'dietary_supplement',     'active', true),
('나우푸드 오메가-3 1000mg',                  'NOW Foods',    'NOW Health Group',     'US', 'dietary_supplement',     'active', true),
('네이처메이드 종합비타민',                    'Nature Made',  'Pharmavite LLC',       'US', 'dietary_supplement',     'active', true),
('한미양행 프로바이오틱스 19 플러스',          '한미양행',      '한미양행',             'KR', 'health_functional_food', 'active', true),
('엘지생활건강 밀크씨슬 골드',                '엘지생건',      'LG생활건강',           'KR', 'health_functional_food', 'active', true),
('GNC 트리플 스트렝스 피쉬오일',              'GNC',          'GNC Holdings',         'US', 'dietary_supplement',     'active', true),
('세노비스 슈퍼바이오틱스 프로 100억',         '세노비스',      '대상웰라이프',         'KR', 'health_functional_food', 'active', true);

-- ============================================================================
-- 7. 제품-원료 연결 (product_ingredients) — 주요 조성만
-- ============================================================================

-- 종근당 칼슘 마그네슘 비타민D 아연
INSERT INTO product_ingredients (product_id, ingredient_id, amount_per_serving, amount_unit, ingredient_role, raw_label_name) VALUES
((SELECT id FROM products WHERE product_name LIKE '종근당 칼슘%'), (SELECT id FROM ingredients WHERE slug='calcium'),   500,  'mg', 'active', '탄산칼슘'),
((SELECT id FROM products WHERE product_name LIKE '종근당 칼슘%'), (SELECT id FROM ingredients WHERE slug='magnesium'), 150,  'mg', 'active', '산화마그네슘'),
((SELECT id FROM products WHERE product_name LIKE '종근당 칼슘%'), (SELECT id FROM ingredients WHERE slug='vitamin-d'), 400,  'IU', 'active', '콜레칼시페롤'),
((SELECT id FROM products WHERE product_name LIKE '종근당 칼슘%'), (SELECT id FROM ingredients WHERE slug='zinc'),      4.2,  'mg', 'active', '글루콘산아연');

-- 뉴트리원 루테인 오메가3
INSERT INTO product_ingredients (product_id, ingredient_id, amount_per_serving, amount_unit, ingredient_role, raw_label_name) VALUES
((SELECT id FROM products WHERE product_name LIKE '뉴트리원 루테인%'), (SELECT id FROM ingredients WHERE slug='lutein'),  20,   'mg', 'active', '마리골드꽃추출물(루테인)'),
((SELECT id FROM products WHERE product_name LIKE '뉴트리원 루테인%'), (SELECT id FROM ingredients WHERE slug='omega-3'), 600,  'mg', 'active', '정제어유(EPA+DHA)');

-- 닥터린 멀티비타민 미네랄
INSERT INTO product_ingredients (product_id, ingredient_id, amount_per_serving, amount_unit, ingredient_role, raw_label_name) VALUES
((SELECT id FROM products WHERE product_name LIKE '닥터린%'), (SELECT id FROM ingredients WHERE slug='vitamin-c'),   100,  'mg',  'active', '아스코르브산'),
((SELECT id FROM products WHERE product_name LIKE '닥터린%'), (SELECT id FROM ingredients WHERE slug='vitamin-d'),   400,  'IU',  'active', '콜레칼시페롤'),
((SELECT id FROM products WHERE product_name LIKE '닥터린%'), (SELECT id FROM ingredients WHERE slug='vitamin-b12'), 2.4,  'mcg', 'active', '시아노코발라민'),
((SELECT id FROM products WHERE product_name LIKE '닥터린%'), (SELECT id FROM ingredients WHERE slug='folate'),      400,  'mcg', 'active', '엽산'),
((SELECT id FROM products WHERE product_name LIKE '닥터린%'), (SELECT id FROM ingredients WHERE slug='zinc'),        8.5,  'mg',  'active', '글루콘산아연'),
((SELECT id FROM products WHERE product_name LIKE '닥터린%'), (SELECT id FROM ingredients WHERE slug='iron'),        12,   'mg',  'active', '퓨마르산제일철'),
((SELECT id FROM products WHERE product_name LIKE '닥터린%'), (SELECT id FROM ingredients WHERE slug='biotin'),      30,   'mcg', 'active', '비오틴'),
((SELECT id FROM products WHERE product_name LIKE '닥터린%'), (SELECT id FROM ingredients WHERE slug='selenium'),    55,   'mcg', 'active', '셀레노메티오닌');

-- Solgar 비타민 D3
INSERT INTO product_ingredients (product_id, ingredient_id, amount_per_serving, amount_unit, ingredient_role, raw_label_name) VALUES
((SELECT id FROM products WHERE product_name LIKE '솔가%'), (SELECT id FROM ingredients WHERE slug='vitamin-d'), 1000, 'IU', 'active', 'Cholecalciferol (Vitamin D3)');

-- NOW Foods 오메가-3
INSERT INTO product_ingredients (product_id, ingredient_id, amount_per_serving, amount_unit, ingredient_role, raw_label_name) VALUES
((SELECT id FROM products WHERE product_name LIKE '나우푸드%'), (SELECT id FROM ingredients WHERE slug='omega-3'), 1000, 'mg', 'active', 'Fish Oil Concentrate (EPA 360mg, DHA 240mg)');

-- Nature Made 종합비타민
INSERT INTO product_ingredients (product_id, ingredient_id, amount_per_serving, amount_unit, ingredient_role, raw_label_name) VALUES
((SELECT id FROM products WHERE product_name LIKE '네이처메이드%'), (SELECT id FROM ingredients WHERE slug='vitamin-c'),   60,   'mg',  'active', 'Vitamin C (as Ascorbic Acid)'),
((SELECT id FROM products WHERE product_name LIKE '네이처메이드%'), (SELECT id FROM ingredients WHERE slug='vitamin-d'),   1000, 'IU',  'active', 'Vitamin D3 (as Cholecalciferol)'),
((SELECT id FROM products WHERE product_name LIKE '네이처메이드%'), (SELECT id FROM ingredients WHERE slug='vitamin-b12'), 6,    'mcg', 'active', 'Vitamin B12 (as Cyanocobalamin)'),
((SELECT id FROM products WHERE product_name LIKE '네이처메이드%'), (SELECT id FROM ingredients WHERE slug='vitamin-e'),   13.5, 'mg',  'active', 'Vitamin E (as dl-Alpha Tocopheryl Acetate)'),
((SELECT id FROM products WHERE product_name LIKE '네이처메이드%'), (SELECT id FROM ingredients WHERE slug='zinc'),        11,   'mg',  'active', 'Zinc (as Zinc Oxide)'),
((SELECT id FROM products WHERE product_name LIKE '네이처메이드%'), (SELECT id FROM ingredients WHERE slug='iron'),        18,   'mg',  'active', 'Iron (as Ferrous Fumarate)'),
((SELECT id FROM products WHERE product_name LIKE '네이처메이드%'), (SELECT id FROM ingredients WHERE slug='selenium'),    55,   'mcg', 'active', 'Selenium (as Sodium Selenate)');

-- 한미양행 프로바이오틱스
INSERT INTO product_ingredients (product_id, ingredient_id, amount_per_serving, amount_unit, ingredient_role, raw_label_name) VALUES
((SELECT id FROM products WHERE product_name LIKE '한미양행%'), (SELECT id FROM ingredients WHERE slug='probiotics'), 100, '억 CFU', 'active', '프로바이오틱스 19종 혼합');

-- LG 밀크씨슬
INSERT INTO product_ingredients (product_id, ingredient_id, amount_per_serving, amount_unit, ingredient_role, raw_label_name) VALUES
((SELECT id FROM products WHERE product_name LIKE '엘지생활건강%'), (SELECT id FROM ingredients WHERE slug='milk-thistle'), 130, 'mg', 'active', '밀크씨슬추출물(실리마린)');

-- GNC 피쉬오일
INSERT INTO product_ingredients (product_id, ingredient_id, amount_per_serving, amount_unit, ingredient_role, raw_label_name) VALUES
((SELECT id FROM products WHERE product_name LIKE 'GNC%'), (SELECT id FROM ingredients WHERE slug='omega-3'), 1500, 'mg', 'active', 'Fish Oil (EPA 540mg, DHA 360mg)');

-- 세노비스 프로바이오틱스
INSERT INTO product_ingredients (product_id, ingredient_id, amount_per_serving, amount_unit, ingredient_role, raw_label_name) VALUES
((SELECT id FROM products WHERE product_name LIKE '세노비스%'), (SELECT id FROM ingredients WHERE slug='probiotics'), 100, '억 CFU', 'active', '프로바이오틱스 혼합(락토바실러스 외)');

-- ============================================================================
-- 8. 라벨 스냅샷 (label_snapshots) — 주요 제품만
-- ============================================================================

INSERT INTO label_snapshots (product_id, label_version, source_name, serving_size_text, servings_per_container, warning_text, directions_text, is_current) VALUES
((SELECT id FROM products WHERE product_name LIKE '종근당 칼슘%'),   'v1', '제품 패키지', '1일 1회, 1회 2정', '60정/30일분', '임산부·수유부·어린이·질환자는 섭취 전 전문가와 상담하십시오.', '1일 1회, 1회 2정을 물과 함께 섭취하십시오.', true),
((SELECT id FROM products WHERE product_name LIKE '솔가%'),         'v1', 'Product Label', '1 softgel daily', '100 softgels', 'If you are pregnant, nursing, or taking medication, consult your doctor before use.', 'As a dietary supplement, take one (1) softgel daily with a meal.', true),
((SELECT id FROM products WHERE product_name LIKE '나우푸드%'),      'v1', 'Product Label', '2 softgels daily', '100 softgels', 'Consult physician if pregnant/nursing, taking medication, or have a medical condition.', 'Take 2 softgels 1 to 3 times daily with food.', true),
((SELECT id FROM products WHERE product_name LIKE '네이처메이드%'),   'v1', 'Product Label', '1 tablet daily', '300 tablets', 'If pregnant or nursing, ask a health professional before use.', 'Take one tablet daily with water and a meal.', true);

-- ============================================================================
-- 9. 출처 (sources) — 초기 시드
-- ============================================================================

INSERT INTO sources (source_name, source_type, organization_name, source_url, country_code, trust_level, access_method) VALUES
('공공데이터포털 건강기능식품',  'government_db',  '한국정보화진흥원',      'https://www.data.go.kr',           'KR', 'authoritative', 'api'),
('식품안전나라',                'government_db',  '식품의약품안전처',      'https://www.foodsafetykorea.go.kr', 'KR', 'authoritative', 'api'),
('PubMed',                     'academic_db',    'NIH/NLM',             'https://pubmed.ncbi.nlm.nih.gov',   'US', 'authoritative', 'api'),
('NIH DSLD',                   'government_db',  'NIH ODS',             'https://dsld.od.nih.gov',           'US', 'authoritative', 'api'),
('DailyMed',                   'government_db',  'NIH/NLM',             'https://dailymed.nlm.nih.gov',      'US', 'authoritative', 'api'),
('openFDA',                    'government_db',  'FDA',                 'https://open.fda.gov',              'US', 'authoritative', 'api'),
('제품 라벨 (브라우저 수집)',   'product_label',  NULL,                  NULL,                                 NULL, 'primary',       'browser_agent');
