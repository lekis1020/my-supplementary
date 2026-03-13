-- ============================================================================
-- 보충 시드 데이터 — 005_seed_supplementary.sql
-- Version: 1.0.0
-- 대상: 신규 원료 5종, 동의어 200+, 추가 기능성, 원료-기능성 연결,
--       안전성, 용량 가이드라인, 약물상호작용, 규제 상태
-- 주의: 003_seed_data.sql 이후 실행. 중복 없음. ON CONFLICT 처리 포함.
-- ============================================================================

-- ============================================================================
-- SECTION 1: 신규 원료 5종
-- ============================================================================

INSERT INTO ingredients (canonical_name_ko, canonical_name_en, display_name, scientific_name, slug, ingredient_type, description, origin_type, form_description, standardization_info, is_active, is_published) VALUES
('홍삼',       'Red Ginseng',       '홍삼',       'Panax ginseng C.A.Meyer',      'red-ginseng', 'herbal',     '수삼을 증기로 쪄서 건조한 것. 진세노사이드가 주요 활성 성분. 면역, 혈행, 피로 개선 등에 관한 식약처 인정 기능성.',  'natural',   '홍삼 추출물, 홍삼 농축액, 진세노사이드(Rg1+Rb1+Rg3)',       'Rg1+Rb1+Rg3 합계 기준 mg',  true, true),
('MSM',        'MSM',               'MSM',        'Methylsulfonylmethane',         'msm',         'other',      '유기황 화합물(메틸설포닐메탄). 관절 건강, 항염 기능에 관여. 천연 및 합성 공급원 모두 사용.',                     'synthetic', 'MSM 분말, MSM 결정형',                                      NULL,                        true, true),
('가르시니아', 'Garcinia Cambogia', '가르시니아', 'Garcinia gummi-gutta',          'garcinia',    'herbal',     '동남아시아 원산 과일 추출물. 주성분 HCA(히드록시시트르산)가 체지방 감소에 관여. 식약처 인정 기능성.',           'natural',   '가르시니아 캄보지아 추출물, HCA(히드록시시트르산)',            'HCA 60% 표준화',            true, true),
('콜라겐',     'Collagen',          '콜라겐',     'Collagen',                      'collagen',    'other',      '체내 결합조직의 주요 단백질. 피부, 관절, 뼈 건강에 관여. 가수분해 형태(펩타이드)로 흡수율 향상.',              'natural',   '어류콜라겐, 소콜라겐, 가수분해 콜라겐(펩타이드), I형/II형/III형', NULL,                     true, true),
('크레아틴',   'Creatine',          '크레아틴',   'Creatine monohydrate',          'creatine',    'amino_acid', '근육 내 에너지(ATP) 재합성에 관여하는 질소 함유 유기산. 운동 수행능력 향상 연구 다수.',                         'synthetic', '크레아틴 모노하이드레이트, 크레아틴 HCl, 버퍼드 크레아틴',    NULL,                        true, true)
ON CONFLICT (slug) DO UPDATE SET
  description = EXCLUDED.description,
  updated_at  = NOW();

-- ============================================================================
-- SECTION 2: 원료 동의어 (ingredient_synonyms) — 전체 25종
-- ============================================================================

INSERT INTO ingredient_synonyms (ingredient_id, synonym, language_code, synonym_type, is_preferred) VALUES

-- ── 비타민 D ──────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='vitamin-d'), '비타민D',           'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='vitamin-d'), '비타민디',          'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='vitamin-d'), '비타민 D3',         'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='vitamin-d'), '비타민D3',          'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='vitamin-d'), 'Vitamin D3',        'en', 'common',       false),
((SELECT id FROM ingredients WHERE slug='vitamin-d'), 'Cholecalciferol',   'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-d'), 'Ergocalciferol',    'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-d'), 'Vit D',             'en', 'abbreviation', false),
((SELECT id FROM ingredients WHERE slug='vitamin-d'), 'D3',                'en', 'abbreviation', false),
((SELECT id FROM ingredients WHERE slug='vitamin-d'), '콜레칼시페롤',      'ko', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-d'), '에르고칼시페롤',    'ko', 'scientific',   false),

-- ── 비타민 C ──────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='vitamin-c'), '비타민C',           'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='vitamin-c'), '비타민씨',          'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='vitamin-c'), '아스코르브산',      'ko', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-c'), '아스코르빈산',      'ko', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-c'), 'Ascorbic Acid',     'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-c'), 'Vit C',             'en', 'abbreviation', false),
((SELECT id FROM ingredients WHERE slug='vitamin-c'), 'L-Ascorbic Acid',   'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-c'), '칼슘아스코르베이트','ko', 'common',       false),

-- ── 비타민 B12 ────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='vitamin-b12'), 'B12',               'en', 'abbreviation', false),
((SELECT id FROM ingredients WHERE slug='vitamin-b12'), '비타민B12',         'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='vitamin-b12'), '코발라민',          'ko', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-b12'), '시아노코발라민',    'ko', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-b12'), '메틸코발라민',      'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='vitamin-b12'), 'Cyanocobalamin',    'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-b12'), 'Methylcobalamin',   'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-b12'), 'Cobalamin',         'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-b12'), 'MeCbl',             'en', 'abbreviation', false),

-- ── 엽산 ──────────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='folate'), '폴산',              'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='folate'), '폴레이트',          'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='folate'), '비타민B9',          'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='folate'), '메틸폴레이트',      'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='folate'), 'Folic Acid',        'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='folate'), 'Folate',            'en', 'common',       false),
((SELECT id FROM ingredients WHERE slug='folate'), 'Vitamin B9',        'en', 'common',       false),
((SELECT id FROM ingredients WHERE slug='folate'), '5-MTHF',            'en', 'abbreviation', false),
((SELECT id FROM ingredients WHERE slug='folate'), 'L-Methylfolate',    'en', 'scientific',   false),

-- ── 오메가-3 ──────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='omega-3'), '오메가쓰리',        'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='omega-3'), '피쉬오일',          'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='omega-3'), '어유',              'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='omega-3'), '크릴오일',          'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='omega-3'), 'Fish Oil',          'en', 'common',       false),
((SELECT id FROM ingredients WHERE slug='omega-3'), 'EPA',               'en', 'abbreviation', false),
((SELECT id FROM ingredients WHERE slug='omega-3'), 'DHA',               'en', 'abbreviation', false),
((SELECT id FROM ingredients WHERE slug='omega-3'), 'EPA+DHA',           'en', 'abbreviation', false),
((SELECT id FROM ingredients WHERE slug='omega-3'), 'Omega-3 Fatty Acids','en','scientific',   false),
((SELECT id FROM ingredients WHERE slug='omega-3'), 'n-3 PUFA',          'en', 'abbreviation', false),

-- ── 마그네슘 ──────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='magnesium'), '마그네시움',            'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='magnesium'), 'Mg',                    'en', 'abbreviation', false),
((SELECT id FROM ingredients WHERE slug='magnesium'), '산화마그네슘',          'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='magnesium'), '구연산마그네슘',        'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='magnesium'), '마그네슘 비스글리시네이트','ko','common',    false),
((SELECT id FROM ingredients WHERE slug='magnesium'), 'Magnesium Oxide',       'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='magnesium'), 'Magnesium Citrate',     'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='magnesium'), 'Magnesium Bisglycinate','en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='magnesium'), 'Magnesium Glycinate',   'en', 'scientific',   false),

-- ── 아연 ──────────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='zinc'), '징크',                'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='zinc'), 'Zn',                  'en', 'abbreviation', false),
((SELECT id FROM ingredients WHERE slug='zinc'), '글루콘산아연',        'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='zinc'), '피콜린산아연',        'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='zinc'), 'Zinc Gluconate',      'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='zinc'), 'Zinc Picolinate',     'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='zinc'), 'Zinc Bisglycinate',   'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='zinc'), 'Zinc Sulfate',        'en', 'scientific',   false),

-- ── 철분 ──────────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='iron'), '철분',                'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='iron'), '아이언',              'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='iron'), 'Fe',                  'en', 'abbreviation', false),
((SELECT id FROM ingredients WHERE slug='iron'), '황산제일철',          'ko', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='iron'), '철비스글리시네이트',  'ko', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='iron'), 'Ferrous Sulfate',     'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='iron'), 'Ferrous Fumarate',    'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='iron'), 'Ferrous Bisglycinate','en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='iron'), 'Heme Iron',           'en', 'scientific',   false),

-- ── 칼슘 ──────────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='calcium'), '칼시움',            'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='calcium'), 'Ca',                'en', 'abbreviation', false),
((SELECT id FROM ingredients WHERE slug='calcium'), '탄산칼슘',          'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='calcium'), '구연산칼슘',        'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='calcium'), 'Calcium Carbonate', 'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='calcium'), 'Calcium Citrate',   'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='calcium'), 'Calcium Phosphate', 'en', 'scientific',   false),

-- ── 프로바이오틱스 ────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='probiotics'), '유산균',              'ko', 'common',     false),
((SELECT id FROM ingredients WHERE slug='probiotics'), '생균제',              'ko', 'common',     false),
((SELECT id FROM ingredients WHERE slug='probiotics'), '락토바실러스',        'ko', 'scientific', false),
((SELECT id FROM ingredients WHERE slug='probiotics'), '비피도박테리움',      'ko', 'scientific', false),
((SELECT id FROM ingredients WHERE slug='probiotics'), 'Lactobacillus',       'en', 'scientific', false),
((SELECT id FROM ingredients WHERE slug='probiotics'), 'Bifidobacterium',     'en', 'scientific', false),
((SELECT id FROM ingredients WHERE slug='probiotics'), 'Lactic Acid Bacteria','en', 'common',    false),
((SELECT id FROM ingredients WHERE slug='probiotics'), 'LAB',                 'en', 'abbreviation',false),

-- ── 루테인 ────────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='lutein'), '루틴',              'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='lutein'), '마리골드추출물',    'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='lutein'), '제아잔틴',          'ko', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='lutein'), 'Zeaxanthin',        'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='lutein'), 'Lutein Ester',      'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='lutein'), 'Marigold Extract',  'en', 'common',       false),

-- ── 코엔자임Q10 ───────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='coq10'), '코큐텐',            'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='coq10'), 'CoQ10',             'en', 'abbreviation', false),
((SELECT id FROM ingredients WHERE slug='coq10'), 'Ubiquinone',        'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='coq10'), 'Ubiquinol',         'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='coq10'), '유비퀴논',          'ko', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='coq10'), '유비퀴놀',          'ko', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='coq10'), 'Coenzyme Q10',      'en', 'scientific',   true),

-- ── 밀크씨슬 ──────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='milk-thistle'), '밀크시슬',          'ko', 'common',     false),
((SELECT id FROM ingredients WHERE slug='milk-thistle'), '엉겅퀴',            'ko', 'common',     false),
((SELECT id FROM ingredients WHERE slug='milk-thistle'), '실리마린',          'ko', 'scientific', false),
((SELECT id FROM ingredients WHERE slug='milk-thistle'), '실리빈',            'ko', 'scientific', false),
((SELECT id FROM ingredients WHERE slug='milk-thistle'), 'Silymarin',         'en', 'scientific', false),
((SELECT id FROM ingredients WHERE slug='milk-thistle'), 'Silybum marianum',  'en', 'scientific', false),
((SELECT id FROM ingredients WHERE slug='milk-thistle'), 'Silibinin',         'en', 'scientific', false),

-- ── 글루코사민 ────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='glucosamine'), 'Glucosamine Sulfate',  'en', 'scientific', false),
((SELECT id FROM ingredients WHERE slug='glucosamine'), 'Glucosamine HCl',      'en', 'scientific', false),
((SELECT id FROM ingredients WHERE slug='glucosamine'), 'N-Acetylglucosamine',  'en', 'scientific', false),
((SELECT id FROM ingredients WHERE slug='glucosamine'), '글루코사민 황산염',    'ko', 'scientific', false),
((SELECT id FROM ingredients WHERE slug='glucosamine'), '글루코사민 염산염',    'ko', 'scientific', false),
((SELECT id FROM ingredients WHERE slug='glucosamine'), 'NAG',                  'en', 'abbreviation',false),

-- ── 비오틴 ────────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='biotin'), '비타민H',           'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='biotin'), '비타민B7',          'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='biotin'), 'Vitamin B7',        'en', 'common',       false),
((SELECT id FROM ingredients WHERE slug='biotin'), 'Vitamin H',         'en', 'common',       false),
((SELECT id FROM ingredients WHERE slug='biotin'), 'D-Biotin',          'en', 'scientific',   false),

-- ── 셀레늄 ────────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='selenium'), 'Se',                    'en', 'abbreviation', false),
((SELECT id FROM ingredients WHERE slug='selenium'), '셀레노메티오닌',        'ko', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='selenium'), '아셀렌산나트륨',        'ko', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='selenium'), 'Selenomethionine',      'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='selenium'), 'Sodium Selenite',       'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='selenium'), 'Sodium Selenate',       'en', 'scientific',   false),

-- ── 비타민 A ──────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='vitamin-a'), '비타민A',           'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='vitamin-a'), 'Vit A',             'en', 'abbreviation', false),
((SELECT id FROM ingredients WHERE slug='vitamin-a'), '레티놀',            'ko', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-a'), '베타카로틴',        'ko', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-a'), 'Retinol',           'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-a'), 'Beta-Carotene',     'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-a'), 'Retinyl Acetate',   'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-a'), 'RAE',               'en', 'abbreviation', false),

-- ── 비타민 E ──────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='vitamin-e'), '비타민E',           'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='vitamin-e'), 'Vit E',             'en', 'abbreviation', false),
((SELECT id FROM ingredients WHERE slug='vitamin-e'), '토코페롤',          'ko', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-e'), '알파토코페롤',      'ko', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-e'), 'Tocopherol',        'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-e'), 'Alpha-Tocopherol',  'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-e'), 'Mixed Tocopherols', 'en', 'scientific',   false),

-- ── 커큐민 ────────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='curcumin'), '강황',              'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='curcumin'), '터메릭',            'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='curcumin'), 'Turmeric',          'en', 'common',       false),
((SELECT id FROM ingredients WHERE slug='curcumin'), 'Curcuma longa',     'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='curcumin'), 'Curcuminoids',      'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='curcumin'), 'BCM-95',            'en', 'brand_like',   false),
((SELECT id FROM ingredients WHERE slug='curcumin'), 'Meriva',            'en', 'brand_like',   false),
((SELECT id FROM ingredients WHERE slug='curcumin'), 'Theracurmin',       'en', 'brand_like',   false),

-- ── 멜라토닌 ──────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='melatonin'), 'N-Acetyl-5-methoxytryptamine','en','scientific',false),
((SELECT id FROM ingredients WHERE slug='melatonin'), '멜라토닌 서방형',   'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='melatonin'), 'Extended-Release Melatonin','en','common', false),
((SELECT id FROM ingredients WHERE slug='melatonin'), 'MLT',               'en', 'abbreviation', false),
((SELECT id FROM ingredients WHERE slug='melatonin'), '수면유도호르몬',    'ko', 'common',       false),

-- ── 홍삼 (신규) ──────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='red-ginseng'), '홍삼 추출물',       'ko', 'common',     false),
((SELECT id FROM ingredients WHERE slug='red-ginseng'), '고려홍삼',          'ko', 'common',     false),
((SELECT id FROM ingredients WHERE slug='red-ginseng'), '인삼',              'ko', 'common',     false),
((SELECT id FROM ingredients WHERE slug='red-ginseng'), 'Korean Red Ginseng','en', 'common',     false),
((SELECT id FROM ingredients WHERE slug='red-ginseng'), 'Panax Ginseng',     'en', 'scientific', false),
((SELECT id FROM ingredients WHERE slug='red-ginseng'), 'Ginsenoside',       'en', 'scientific', false),
((SELECT id FROM ingredients WHERE slug='red-ginseng'), '진세노사이드',      'ko', 'scientific', false),
((SELECT id FROM ingredients WHERE slug='red-ginseng'), 'KRG',               'en', 'abbreviation',false),

-- ── MSM (신규) ────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='msm'), '메틸설포닐메탄',      'ko', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='msm'), '엠에스엠',            'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='msm'), 'Methylsulfonylmethane','en','scientific',   false),
((SELECT id FROM ingredients WHERE slug='msm'), 'DMSO2',               'en', 'abbreviation', false),
((SELECT id FROM ingredients WHERE slug='msm'), 'Methyl sulfone',      'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='msm'), '유기황',              'ko', 'common',       false),

-- ── 가르시니아 (신규) ─────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='garcinia'), '가르시니아 캄보지아',  'ko', 'common',     false),
((SELECT id FROM ingredients WHERE slug='garcinia'), 'HCA',                  'en', 'abbreviation',false),
((SELECT id FROM ingredients WHERE slug='garcinia'), '히드록시시트르산',     'ko', 'scientific', false),
((SELECT id FROM ingredients WHERE slug='garcinia'), 'Hydroxycitric Acid',   'en', 'scientific', false),
((SELECT id FROM ingredients WHERE slug='garcinia'), 'Garcinia Cambogia',    'en', 'common',     false),
((SELECT id FROM ingredients WHERE slug='garcinia'), 'Malabar Tamarind',     'en', 'common',     false),
((SELECT id FROM ingredients WHERE slug='garcinia'), 'Gambooge',             'en', 'common',     false),

-- ── 콜라겐 (신규) ────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='collagen'), '콜라젠',              'ko', 'common',     false),
((SELECT id FROM ingredients WHERE slug='collagen'), '가수분해 콜라겐',     'ko', 'common',     false),
((SELECT id FROM ingredients WHERE slug='collagen'), '콜라겐 펩타이드',     'ko', 'common',     false),
((SELECT id FROM ingredients WHERE slug='collagen'), '피쉬콜라겐',          'ko', 'common',     false),
((SELECT id FROM ingredients WHERE slug='collagen'), 'Hydrolyzed Collagen', 'en', 'scientific', false),
((SELECT id FROM ingredients WHERE slug='collagen'), 'Collagen Peptide',    'en', 'scientific', false),
((SELECT id FROM ingredients WHERE slug='collagen'), 'Marine Collagen',     'en', 'common',     false),
((SELECT id FROM ingredients WHERE slug='collagen'), 'Bovine Collagen',     'en', 'common',     false),
((SELECT id FROM ingredients WHERE slug='collagen'), 'Type I Collagen',     'en', 'scientific', false),
((SELECT id FROM ingredients WHERE slug='collagen'), 'Type II Collagen',    'en', 'scientific', false),

-- ── 크레아틴 (신규) ───────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='creatine'), '크레아틴 모노하이드레이트','ko','common',  false),
((SELECT id FROM ingredients WHERE slug='creatine'), 'Creatine Monohydrate',  'en', 'scientific',false),
((SELECT id FROM ingredients WHERE slug='creatine'), 'Creatine HCl',          'en', 'scientific',false),
((SELECT id FROM ingredients WHERE slug='creatine'), 'Buffered Creatine',     'en', 'scientific',false),
((SELECT id FROM ingredients WHERE slug='creatine'), 'Kre-Alkalyn',           'en', 'brand_like',false),
((SELECT id FROM ingredients WHERE slug='creatine'), 'PCr',                   'en', 'abbreviation',false),
((SELECT id FROM ingredients WHERE slug='creatine'), '크레아틴 HCl',         'ko', 'common',    false)

ON CONFLICT DO NOTHING;

-- ============================================================================
-- SECTION 3: 추가 기능성 Claims (7종)
-- ============================================================================

INSERT INTO claims (claim_code, claim_name_ko, claim_name_en, claim_category, claim_scope, description) VALUES
('BODY_FAT',          '체지방 감소에 도움',        'Body Fat Reduction',        'weight_management', 'approved_kr', '체지방 축적을 억제하는 데 도움을 줄 수 있음'),
('EXERCISE_PERF',     '운동 수행능력 향상에 도움', 'Exercise Performance',      'physical_fitness',  'studied',     '단기 고강도 운동 수행능력 향상에 관한 연구 결과가 있음'),
('BLOOD_CIRCULATION', '혈행 개선에 도움',          'Blood Circulation',         'cardiovascular',    'approved_kr', '혈액 흐름과 순환에 도움을 줄 수 있음'),
('FATIGUE',           '피로 개선에 도움',          'Fatigue Reduction',         'energy',            'approved_kr', '일상적인 피로를 완화하는 데 도움을 줄 수 있음'),
('MEMORY',            '기억력 개선에 도움',        'Memory Improvement',        'cognitive',         'approved_kr', '기억력 유지 및 개선에 도움을 줄 수 있음'),
('CALCIUM_ABSORPTION','칼슘 흡수 촉진에 도움',     'Calcium Absorption',        'bone_joint',        'approved_kr', '칼슘 흡수를 증가시키는 데 도움을 줄 수 있음'),
('BLOOD_PRESSURE',    '혈압 조절에 도움',          'Blood Pressure Regulation', 'cardiovascular',    'studied',     '정상 혈압 유지에 관한 연구 결과가 있음')
ON CONFLICT (claim_code) DO UPDATE SET
  claim_name_ko = EXCLUDED.claim_name_ko,
  description   = EXCLUDED.description;

-- ============================================================================
-- SECTION 4: 추가 원료-기능성 연결 (ingredient_claims)
-- ============================================================================

INSERT INTO ingredient_claims (ingredient_id, claim_id, evidence_grade, evidence_summary, is_regulator_approved, approval_country_code, allowed_expression) VALUES

-- ── 홍삼 ──────────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='red-ginseng'), (SELECT id FROM claims WHERE claim_code='IMMUNE_FUNCTION'),   'B', '진세노사이드의 면역세포 활성화 임상 연구',           true,  'KR', '면역 기능에 도움을 줄 수 있음'),
((SELECT id FROM ingredients WHERE slug='red-ginseng'), (SELECT id FROM claims WHERE claim_code='BLOOD_CIRCULATION'), 'B', '혈소판 응집 억제 및 혈류 개선 임상 연구',           true,  'KR', '혈행 개선에 도움을 줄 수 있음'),
((SELECT id FROM ingredients WHERE slug='red-ginseng'), (SELECT id FROM claims WHERE claim_code='FATIGUE'),           'B', '피로 지표(코르티솔 등) 개선 다수 임상',             true,  'KR', '피로 개선에 도움을 줄 수 있음'),
((SELECT id FROM ingredients WHERE slug='red-ginseng'), (SELECT id FROM claims WHERE claim_code='MEMORY'),            'B', '인지기능 및 기억력 개선 임상 연구',                 true,  'KR', '기억력 개선에 도움을 줄 수 있음'),

-- ── 가르시니아 ────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='garcinia'), (SELECT id FROM claims WHERE claim_code='BODY_FAT'),             'B', 'HCA가 지방합성 억제(ATP-시트레이트 라이아제) 기전', true,  'KR', '체지방 감소에 도움을 줄 수 있음'),

-- ── 콜라겐 ────────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='collagen'), (SELECT id FROM claims WHERE claim_code='SKIN_HEALTH'),          'B', '피부 탄력 및 보습 개선 임상 연구 다수',             true,  'KR', '피부 건강에 도움을 줄 수 있음'),
((SELECT id FROM ingredients WHERE slug='collagen'), (SELECT id FROM claims WHERE claim_code='JOINT_HEALTH'),         'C', '관절 통증 및 기능 개선 소규모 임상',                false, NULL, NULL),

-- ── 크레아틴 ──────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='creatine'), (SELECT id FROM claims WHERE claim_code='EXERCISE_PERF'),        'A', '단기 고강도 운동 수행능력 향상 메타분석 일관된 결과',false, NULL, NULL),

-- ── MSM ───────────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='msm'), (SELECT id FROM claims WHERE claim_code='JOINT_HEALTH'),              'B', '관절 통증 및 기능 개선 다수 임상 연구',             true,  'KR', '관절 건강에 도움을 줄 수 있음'),

-- ── 비타민 D (칼슘흡수) ───────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='vitamin-d'), (SELECT id FROM claims WHERE claim_code='CALCIUM_ABSORPTION'),  'A', '장내 칼슘 흡수 수용체 활성화 강력한 근거',         true,  'KR', '칼슘 흡수를 도와 뼈와 치아 형성에 필요'),

-- ── 비타민 C ──────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='vitamin-c'), (SELECT id FROM claims WHERE claim_code='ENERGY_METABOLISM'),   'A', '에너지 대사 보조인자로 필수적 역할',               true,  'KR', '에너지 이용에 필요'),

-- ── 비타민 A ──────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='vitamin-a'), (SELECT id FROM claims WHERE claim_code='SKIN_HEALTH'),         'B', '피부 세포 분화 및 장벽 기능 유지 연구',            true,  'KR', '피부 건강에 도움을 줄 수 있음'),
((SELECT id FROM ingredients WHERE slug='vitamin-a'), (SELECT id FROM claims WHERE claim_code='IMMUNE_FUNCTION'),     'B', '점막 면역 및 T세포 기능 지원',                     true,  'KR', '정상적인 면역 기능에 필요'),

-- ── 비타민 E ──────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='vitamin-e'), (SELECT id FROM claims WHERE claim_code='SKIN_HEALTH'),         'B', '지용성 항산화로 세포막 보호 및 피부 건강 연구',    false, NULL, NULL),

-- ── 커큐민 ────────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='curcumin'), (SELECT id FROM claims WHERE claim_code='ANTIOXIDANT'),          'B', '커큐미노이드의 항산화 활성 다수 연구',              false, NULL, NULL),
((SELECT id FROM ingredients WHERE slug='curcumin'), (SELECT id FROM claims WHERE claim_code='JOINT_HEALTH'),         'C', '관절 통증 완화 소규모 임상',                        false, NULL, NULL),

-- ── CoQ10 ─────────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='coq10'), (SELECT id FROM claims WHERE claim_code='ENERGY_METABOLISM'),       'B', '미토콘드리아 ATP 생성 보조인자로 작용',             false, NULL, NULL),
((SELECT id FROM ingredients WHERE slug='coq10'), (SELECT id FROM claims WHERE claim_code='CARDIOVASCULAR'),          'B', '심부전 환자 심기능 보조 임상 연구 다수',            false, NULL, NULL),

-- ── 마그네슘 (혈압) ───────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='magnesium'), (SELECT id FROM claims WHERE claim_code='BLOOD_PRESSURE'),      'B', '혈관 이완 및 혈압 강하 메타분석 연구',             false, NULL, NULL),

-- ── 오메가-3 (혈압) ───────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='omega-3'), (SELECT id FROM claims WHERE claim_code='BLOOD_PRESSURE'),        'B', '고용량 EPA+DHA 혈압 강하 메타분석',                false, NULL, NULL),

-- ── 칼슘 (BONE_HEALTH 이미 존재, 추가) ──────────────────────────────────
((SELECT id FROM ingredients WHERE slug='calcium'), (SELECT id FROM claims WHERE claim_code='CALCIUM_ABSORPTION'),    'A', '칼슘 섭취와 체내 이용률 직접적 관련',              true,  'KR', '뼈와 치아 형성에 필요한 칼슘 공급원'),

-- ── 비타민 B12 (에너지 대사 추가) ────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='vitamin-b12'), (SELECT id FROM claims WHERE claim_code='ENERGY_METABOLISM'), 'A', '지방산 및 아미노산 대사에 필수 보조인자',          true,  'KR', '에너지 이용에 필요'),
((SELECT id FROM ingredients WHERE slug='vitamin-b12'), (SELECT id FROM claims WHERE claim_code='FATIGUE'),           'B', 'B12 결핍 시 피로·무력감 개선',                     false, NULL, NULL),

-- ── 비오틴 (에너지 대사 추가) ────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='biotin'), (SELECT id FROM claims WHERE claim_code='ENERGY_METABOLISM'),      'B', '탄수화물·지방산 대사 보조효소 역할',               true,  'KR', '에너지 이용에 필요'),

-- ── 셀레늄 (면역 추가) ───────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='selenium'), (SELECT id FROM claims WHERE claim_code='IMMUNE_FUNCTION'),      'B', '셀레노단백질이 면역세포 기능 지원',                true,  'KR', '정상적인 면역 기능에 필요'),

-- ── 아연 (피부 건강 추가) ────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='zinc'), (SELECT id FROM claims WHERE claim_code='SKIN_HEALTH'),              'B', '피부 세포 증식 및 상처 치유에 필요',               false, NULL, NULL),

-- ── 엽산 (에너지 대사 추가) ──────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='folate'), (SELECT id FROM claims WHERE claim_code='ENERGY_METABOLISM'),      'A', '세포 에너지 대사 메틸화 반응에 필수',              true,  'KR', '에너지 이용에 필요')

ON CONFLICT (ingredient_id, claim_id, approval_country_code) DO UPDATE SET
  evidence_grade   = EXCLUDED.evidence_grade,
  evidence_summary = EXCLUDED.evidence_summary,
  updated_at       = NOW();

-- ============================================================================
-- SECTION 5: 안전성 정보 (safety_items) — 전체 25종 보완
-- ============================================================================

INSERT INTO safety_items (ingredient_id, safety_type, title, description, severity_level, evidence_level, frequency_text, applies_to_population, management_advice) VALUES

-- ── 비타민 C ──────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='vitamin-c'), 'adverse_effect',    '비타민 C 고용량 소화 장애',       '2,000mg 이상 고용량 시 구역, 설사, 위장 자극 가능.',       'mild',     'rct',       'common',   '성인',           '1,000mg 이하로 분할 복용'),
((SELECT id FROM ingredients WHERE slug='vitamin-c'), 'precaution',        '비타민 C 신장결석',               '옥살산 결석 병력자에서 고용량 복용 시 위험 증가.',          'moderate', 'observational','uncommon','신장결석 병력자', '하루 500mg 이하로 제한'),
((SELECT id FROM ingredients WHERE slug='vitamin-c'), 'precaution',        '검사 간섭',                       '고용량 비타민 C 복용 시 혈당 검사(일부 기기)에 위양성.',    'mild',     'guideline', 'uncommon', '당뇨 환자',      '검사 48시간 전 중단 고려'),

-- ── 비타민 B12 ────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='vitamin-b12'), 'precaution',      '메틸코발라민 전환 불가 (일부 유전)',  'MTHFR 변이 등 일부에서 시아노코발라민 전환 불량.',          'mild',     'observational','rare',  '성인 일반',    '메틸코발라민 형태 선택 권장'),
((SELECT id FROM ingredients WHERE slug='vitamin-b12'), 'drug_interaction','메트포르민과 B12 흡수 저하',       '메트포르민 장기 복용 시 B12 흡수 감소 가능.',               'moderate', 'rct',       'common',   '당뇨 환자',    '정기적 B12 수치 모니터링'),

-- ── 엽산 ──────────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='folate'), 'precaution',           '엽산 고용량 비타민 B12 결핍 마스킹', '고용량 엽산이 B12 결핍의 신경 증상을 가릴 수 있음.',      'serious',  'guideline', 'uncommon', '고령자, 채식주의자', 'B12와 함께 복용 또는 수치 확인'),
((SELECT id FROM ingredients WHERE slug='folate'), 'drug_interaction',     '엽산-항경련제 상호작용',           '페니토인, 메토트렉사트 등이 엽산 대사를 저해.',             'serious',  'guideline', 'common',   '항경련제 복용자', '담당의 상담 필수'),

-- ── 아연 ──────────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='zinc'), 'adverse_effect',         '아연 고용량 구역·구토',            '40mg 이상 고용량 시 구역, 구토, 복통 가능.',                'moderate', 'rct',       'common',   '성인',         '식후 복용, 하루 40mg 미만 유지'),
((SELECT id FROM ingredients WHERE slug='zinc'), 'overdose',               '아연 과다복용 구리 결핍',          '장기 고용량(150mg+ 이상) 복용 시 구리 흡수 저해.',          'serious',  'guideline', 'uncommon', '성인',         'UL 40mg/일 준수'),
((SELECT id FROM ingredients WHERE slug='zinc'), 'drug_interaction',       '아연-항생제 흡수 저하',            '아연이 테트라사이클린, 퀴놀론 계열 항생제 흡수 감소.',       'moderate', 'guideline', 'common',   '항생제 복용자', '2시간 간격 두고 복용'),

-- ── 칼슘 ──────────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='calcium'), 'adverse_effect',      '칼슘 변비·복부팽만',               '탄산칼슘 고용량 복용 시 변비, 복부팽만 가능.',              'mild',     'rct',       'common',   '성인',         '구연산칼슘 형태 고려, 충분한 수분 섭취'),
((SELECT id FROM ingredients WHERE slug='calcium'), 'overdose',            '칼슘 과다복용 고칼슘혈증',         '하루 2,500mg 이상 장기 복용 시 고칼슘혈증, 신장결석 위험.', 'serious',  'guideline', 'uncommon', '성인',         'UL 2,500mg/일 준수'),
((SELECT id FROM ingredients WHERE slug='calcium'), 'drug_interaction',    '칼슘-레보티록신 흡수 저하',        '칼슘 보충제가 갑상선 호르몬 흡수를 방해.',                  'moderate', 'guideline', 'common',   '갑상선 질환자', '4시간 간격 두고 복용'),

-- ── 프로바이오틱스 ────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='probiotics'), 'adverse_effect',   '프로바이오틱스 초기 소화기 증상',  '복용 초기 복부팽만, 가스, 설사 가능(1~2주 내 소실).',       'mild',     'rct',       'common',   '성인',           '저용량으로 시작, 용량 서서히 증량'),
((SELECT id FROM ingredients WHERE slug='probiotics'), 'contraindication', '면역저하자 주의',                  '중증 면역저하자(장기이식, 항암치료 중)에서 균혈증 보고.',    'serious',  'case_report','rare',   '면역저하자',     '담당의 상담 후 복용'),

-- ── 루테인 ────────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='lutein'), 'adverse_effect',       '루테인 황달 유사 피부색 변화',     '고용량 장기 복용 시 피부에 황색 착색(카로테노데르마) 가능.', 'mild',     'observational','uncommon','성인',        '권장량(20mg/일) 이하 유지'),
((SELECT id FROM ingredients WHERE slug='lutein'), 'precaution',           '루테인 흡연자 주의',               '흡연자에서 고용량 카로티노이드 복용의 폐암 위험 불확실.',    'moderate', 'observational','uncommon','흡연자',     '흡연자는 의사 상담 권고'),

-- ── 코엔자임Q10 ───────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='coq10'), 'adverse_effect',        'CoQ10 소화기 이상반응',            '고용량(300mg+) 시 구역, 설사, 위장 불편감 가능.',           'mild',     'rct',       'uncommon', '성인',           '식후 복용, 분할 복용'),
((SELECT id FROM ingredients WHERE slug='coq10'), 'drug_interaction',      'CoQ10-와파린 상호작용',            'CoQ10이 와파린의 항응고 효과를 감소시킬 수 있음.',          'moderate', 'case_report','uncommon','항응고제 복용자','INR 모니터링 필요'),
((SELECT id FROM ingredients WHERE slug='coq10'), 'drug_interaction',      'CoQ10-스타틴 병용',               '스타틴이 CoQ10 체내 합성을 저해하므로 CoQ10 보충 고려.',   'mild',     'rct',       'common',   '스타틴 복용자',  '심근병증 예방 목적으로 병용 가능'),

-- ── 밀크씨슬 ──────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='milk-thistle'), 'adverse_effect', '밀크씨슬 소화기 증상',             '드물게 구역, 설사, 두통 가능.',                             'mild',     'rct',       'uncommon', '성인',           '식후 복용'),
((SELECT id FROM ingredients WHERE slug='milk-thistle'), 'drug_interaction','밀크씨슬 CYP3A4 억제',            '실리마린이 CYP3A4 효소 억제 → 일부 약물 농도 증가 가능.',  'moderate', 'observational','uncommon','다약제 복용자', '처방약 복용 중 담당의 상담'),
((SELECT id FROM ingredients WHERE slug='milk-thistle'), 'precaution',     '에스트로겐 민감성 종양 주의',      '식물성 에스트로겐 유사 작용 가능, 호르몬 민감 종양 주의.',  'moderate', 'observational','rare',   '호르몬 민감 종양', '담당의 상담 권고'),

-- ── 글루코사민 ────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='glucosamine'), 'adverse_effect',  '글루코사민 소화 장애',             '위장 불편감, 구역, 설사, 변비 가능.',                       'mild',     'rct',       'common',   '성인',           '식후 복용'),
((SELECT id FROM ingredients WHERE slug='glucosamine'), 'precaution',      '갑각류 알레르기',                  '갑각류 유래 글루코사민 알레르기 반응 가능.',                 'moderate', 'case_report','uncommon','갑각류 알레르기','갑각류 알레르기 시 균류 유래 선택'),
((SELECT id FROM ingredients WHERE slug='glucosamine'), 'drug_interaction','글루코사민-와파린 상호작용',       '와파린 병용 시 INR 상승, 출혈 위험 증가 보고.',             'moderate', 'case_report','uncommon','항응고제 복용자','INR 정기 모니터링'),

-- ── 비오틴 ────────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='biotin'), 'precaution',           '비오틴 검사 간섭',                 '고용량 비오틴이 갑상선·심장 표지자 등 면역분석 검사에 위양성/위음성 유발.',  'serious',  'guideline', 'uncommon', '성인',           '검사 3~7일 전 중단 필요'),
((SELECT id FROM ingredients WHERE slug='biotin'), 'precaution',           '비오틴 과다복용 증거 없는 효과',   '정상적인 비오틴 상태에서 고용량 복용의 모발·손톱 효과 근거 제한적.',          'mild',     'rct',       'common',   '성인',           '권장량(30~100mcg/일) 준수'),

-- ── 셀레늄 ────────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='selenium'), 'overdose',           '셀레늄 과다복용(셀레노증)',        '하루 400mcg 이상 장기 복용 시 탈모, 손발톱 이상, 신경 독성 가능.',   'serious',  'guideline', 'uncommon', '성인',           'UL 400mcg/일 준수'),
((SELECT id FROM ingredients WHERE slug='selenium'), 'precaution',         '셀레늄 식이 섭취 지역 차이',       '토양 셀레늄 농도에 따라 식이 섭취량이 크게 달라 추가 보충 주의.', 'mild',     'observational','common', '셀레늄 고섭취 지역 거주자', '혈중 셀레늄 수치 확인'),

-- ── 비타민 A ──────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='vitamin-a'), 'overdose',          '비타민 A 급성/만성 독성',         '하루 10,000IU 이상 장기 복용 시 두통, 간 독성, 뼈 약화.',   'serious',  'guideline', 'uncommon', '성인',           'UL 10,000IU/일 준수, 베타카로틴 형태 선택 권장'),
((SELECT id FROM ingredients WHERE slug='vitamin-a'), 'contraindication',  '레티놀 임신 금기',                '합성 레티놀 고용량은 태아 기형(두개안면기형 등) 위험.',       'critical', 'guideline', 'uncommon', '임산부',         '임신 중 레티놀 10,000IU 이상 절대 금지'),

-- ── 비타민 E ──────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='vitamin-e'), 'overdose',          '비타민 E 고용량 출혈 위험',        '하루 1,000mg 이상 복용 시 출혈 위험 증가.',                 'moderate', 'guideline', 'uncommon', '성인',           'UL 1,000mg/일 준수'),
((SELECT id FROM ingredients WHERE slug='vitamin-e'), 'drug_interaction',  '비타민 E-항응고제 상호작용',       '항응고제와 병용 시 출혈 위험 증가 가능.',                    'moderate', 'rct',       'uncommon', '항응고제 복용자', '담당의 상담 필수'),

-- ── 커큐민 ────────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='curcumin'), 'adverse_effect',     '커큐민 소화기 증상',               '고용량 시 구역, 설사, 위장 불편감 가능.',                   'mild',     'rct',       'uncommon', '성인',           '식후 복용, 분할 복용'),
((SELECT id FROM ingredients WHERE slug='curcumin'), 'drug_interaction',   '커큐민-항응고제 상호작용',         '항응고제와 병용 시 출혈 위험 증가 가능.',                    'moderate', 'observational','uncommon','항응고제 복용자','담당의 상담 필수'),
((SELECT id FROM ingredients WHERE slug='curcumin'), 'precaution',         '커큐민 담석/담도 폐쇄 금기',       '커큐민은 담즙 분비를 촉진하므로 담도 폐쇄 시 금기.',         'moderate', 'guideline', 'rare',     '담도 질환자',    '담도 폐쇄, 담석증 환자 복용 금지'),

-- ── 멜라토닌 ──────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='melatonin'), 'adverse_effect',    '멜라토닌 두통·어지럼증',           '복용 후 두통, 어지럼증, 기억력 저하 가능.',                 'mild',     'rct',       'common',   '성인',           '저용량(0.5~1mg)부터 시작'),
((SELECT id FROM ingredients WHERE slug='melatonin'), 'drug_interaction',  '멜라토닌-면역억제제 상호작용',     '멜라토닌이 면역 기능에 영향을 주어 면역억제제 효과 변화 가능.','moderate', 'case_report','uncommon','면역억제제 복용자','담당의 상담 필수'),
((SELECT id FROM ingredients WHERE slug='melatonin'), 'drug_interaction',  '멜라토닌-CNS 억제제 상호작용',     '알코올, 수면제와 병용 시 중추신경 억제 상가 효과.',          'moderate', 'rct',       'common',   '성인',           '알코올, 수면제와 병용 피함'),
((SELECT id FROM ingredients WHERE slug='melatonin'), 'precaution',        '한국 전문의약품 주의',             '한국에서 멜라토닌은 전문의약품(서시르카딘 등). 해외 보충제로 구입·복용 시 용량·품질 주의.','moderate','label','common','성인','식약처 승인 의약품 이용 권고'),

-- ── 홍삼 (신규) ──────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='red-ginseng'), 'adverse_effect',  '홍삼 불면·흥분',                   '일부에서 불면증, 흥분, 두근거림 가능. 특히 고용량 시.',      'mild',     'rct',       'uncommon', '성인',           '취침 전 복용 피함, 용량 조절'),
((SELECT id FROM ingredients WHERE slug='red-ginseng'), 'drug_interaction','홍삼-와파린 상호작용',             '홍삼이 와파린의 항응고 효과를 감소시킬 수 있음.',           'moderate', 'rct',       'uncommon', '항응고제 복용자','INR 모니터링 필요'),
((SELECT id FROM ingredients WHERE slug='red-ginseng'), 'drug_interaction','홍삼-당뇨약 상호작용',             '홍삼의 혈당 강하 효과가 인슐린/경구혈당강하제와 상가 가능.','moderate', 'rct',       'uncommon', '당뇨 환자',      '혈당 모니터링, 담당의 상담'),
((SELECT id FROM ingredients WHERE slug='red-ginseng'), 'precaution',      '홍삼 임신·수유 주의',              '임신 중 홍삼 고용량 복용 안전성 데이터 부족.',               'moderate', 'guideline', 'uncommon', '임산부, 수유부', '임신·수유 중 복용 전 담당의 상담'),

-- ── MSM (신규) ────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='msm'), 'adverse_effect',          'MSM 소화기 증상',                  '일부에서 구역, 설사, 복통 가능.',                           'mild',     'rct',       'uncommon', '성인',           '식후 복용'),
((SELECT id FROM ingredients WHERE slug='msm'), 'adverse_effect',          'MSM 두통·피로',                    '복용 초기 두통, 피로감 가능(초기 해독 반응 가능성).',        'mild',     'observational','uncommon','성인',           '용량을 서서히 증량'),

-- ── 가르시니아 (신규) ─────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='garcinia'), 'adverse_effect',     '가르시니아 간 독성 보고',          '고용량·복합 제품에서 드물게 간 손상 사례 보고.',             'serious',  'case_report','rare',   '성인',           '권장량 준수, 황달·복통 발생 시 중단'),
((SELECT id FROM ingredients WHERE slug='garcinia'), 'drug_interaction',   '가르시니아-당뇨약 상호작용',       'HCA의 혈당 강하 효과가 당뇨약과 상가 가능.',               'moderate', 'observational','uncommon','당뇨 환자',   '혈당 모니터링 강화'),
((SELECT id FROM ingredients WHERE slug='garcinia'), 'precaution',         '가르시니아 임신·수유 주의',        '임신·수유 중 안전성 데이터 부족.',                           'moderate', 'guideline', 'unknown',  '임산부, 수유부', '복용 금지 권고'),

-- ── 콜라겐 (신규) ────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='collagen'), 'adverse_effect',     '콜라겐 소화 불편감',               '드물게 구역, 복부팽만, 과민반응 가능.',                     'mild',     'rct',       'uncommon', '성인',           '식후 복용, 충분한 수분 섭취'),
((SELECT id FROM ingredients WHERE slug='collagen'), 'precaution',         '콜라겐 알레르기 주의',             '어류·소·돼지 유래 콜라겐: 해당 식품 알레르기자 주의.',       'moderate', 'guideline', 'uncommon', '식품 알레르기자','알레르기 원인 동물 유래 제품 회피'),

-- ── 크레아틴 (신규) ───────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='creatine'), 'adverse_effect',     '크레아틴 수분 저류·체중 증가',     '로딩기 초기 체수분 증가로 체중 1~2kg 증가 가능.',           'mild',     'rct',       'common',   '성인',           '충분한 수분 섭취'),
((SELECT id FROM ingredients WHERE slug='creatine'), 'precaution',         '크레아틴 신장 기능 주의',          '신장 기능 저하자에서 크레아티닌 수치 증가 가능(허위 상승).','moderate', 'observational','common', '신장 기능 저하자','담당의 상담 후 복용, eGFR 모니터링'),
((SELECT id FROM ingredients WHERE slug='creatine'), 'adverse_effect',     '크레아틴 위장 불편감',             '고용량(로딩 단계) 시 구역, 복통 가능.',                     'mild',     'rct',       'common',   '성인',           '유지 용량(3~5g)으로 복용, 로딩 단계 생략 가능');

-- ============================================================================
-- SECTION 6: 용량 가이드라인 (dosage_guidelines) — 전체 25종
-- ============================================================================

INSERT INTO dosage_guidelines (ingredient_id, population_group, indication_context, dose_min, dose_max, dose_unit, frequency_text, route, recommendation_type, notes) VALUES

-- ── 비타민 D (추가 집단) ──────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='vitamin-d'), '임산부',            '태아 뼈 건강',         600,  4000, 'IU',       '1일 1회',   'oral', 'RDA', '임신 중 비타민 D 요구량 증가'),
((SELECT id FROM ingredients WHERE slug='vitamin-d'), '영아 (0~12개월)',   '구루병 예방',          400,  400,  'IU',       '1일 1회',   'oral', 'RDA', '모유 수유아는 출생 직후부터 보충 권장'),

-- ── 비타민 B12 ────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='vitamin-b12'), '성인',            '일반 건강',            2.4,  1000, 'mcg',      '1일 1회',   'oral', 'RDA', '한국 RDA 2.4mcg. 흡수율 고려 시 더 높은 용량 사용'),
((SELECT id FROM ingredients WHERE slug='vitamin-b12'), '65세 이상',       '결핍 예방',            100,  1000, 'mcg',      '1일 1회',   'oral', 'RDA', '고령자는 위산 분비 감소로 결정형 섭취 권장'),

-- ── 마그네슘 (추가 집단) ──────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='magnesium'), '임산부',            '임신 중 건강',         350,  360,  'mg',       '1일 1~2회', 'oral', 'RDA', '임신 중 마그네슘 요구량 증가'),
((SELECT id FROM ingredients WHERE slug='magnesium'), '65세 이상 여성',    '일반 건강',            300,  320,  'mg',       '1일 1~2회', 'oral', 'RDA', '원소 마그네슘 기준'),

-- ── 아연 (추가 집단) ──────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='zinc'), '성인 여성',             '일반 건강',            7,    8,    'mg',       '1일 1회',   'oral', 'RDA', 'UL 40mg/일'),
((SELECT id FROM ingredients WHERE slug='zinc'), '임산부',                '태아 발달',            10,   12,   'mg',       '1일 1회',   'oral', 'RDA', '임신 중 아연 요구량 증가'),

-- ── 철분 (추가 집단) ──────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='iron'), '성인 남성',             '일반 건강',            8,    10,   'mg',       '1일 1회',   'oral', 'RDA', '원소 철 기준. 남성은 여성보다 필요량 낮음'),
((SELECT id FROM ingredients WHERE slug='iron'), '임산부',                '빈혈 예방',            24,   27,   'mg',       '1일 1회',   'oral', 'RDA', '임신 중 철 요구량 현저히 증가'),

-- ── 비타민 A ──────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='vitamin-a'), '성인 남성',         '일반 건강',            700,  3000, 'mcg RAE',  '1일 1회',   'oral', 'RDA', 'UL 3,000mcg RAE/일 (레티놀 기준). 베타카로틴은 UL 없음'),
((SELECT id FROM ingredients WHERE slug='vitamin-a'), '성인 여성',         '일반 건강',            600,  3000, 'mcg RAE',  '1일 1회',   'oral', 'RDA', '임산부 레티놀 3,000mcg RAE 이상 금기'),

-- ── 비타민 E ──────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='vitamin-e'), '성인',              '항산화',               10,   200,  'mg',       '1일 1회',   'oral', 'RDA', 'UL 1,000mg/일. d-알파 토코페롤 기준'),

-- ── 셀레늄 ────────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='selenium'), '성인',               '일반 건강',            55,   200,  'mcg',      '1일 1회',   'oral', 'RDA', 'UL 400mcg/일. 원소 셀레늄 기준'),

-- ── 비오틴 ────────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='biotin'), '성인',                 '일반 건강',            30,   5000, 'mcg',      '1일 1회',   'oral', 'AI',  '공식 UL 미설정. 검사 간섭 위험 고려'),
((SELECT id FROM ingredients WHERE slug='biotin'), '임산부',               '태아 발달',            30,   30,   'mcg',      '1일 1회',   'oral', 'AI',  '임신 중 비오틴 AI 30mcg/일'),

-- ── CoQ10 ─────────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='coq10'), '성인',                  '항산화/에너지',        100,  300,  'mg',       '1일 1~2회', 'oral', 'AI',  '공식 RDA 없음. 연구 기반 100~300mg'),
((SELECT id FROM ingredients WHERE slug='coq10'), '스타틴 복용 성인',     '근육 부작용 예방',     100,  200,  'mg',       '1일 1회',   'oral', 'AI',  '스타틴 처방 시 보조로 사용 연구 있음'),

-- ── 밀크씨슬 ──────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='milk-thistle'), '성인',           '간 건강',              140,  420,  'mg',       '1일 2~3회', 'oral', 'AI',  '실리마린 기준. 식약처 인정: 130mg/일'),
((SELECT id FROM ingredients WHERE slug='milk-thistle'), '간질환 환자',    '간세포 보호',          420,  600,  'mg',       '1일 3회',   'oral', 'AI',  '담당의 지도하에 복용'),

-- ── 글루코사민 ────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='glucosamine'), '성인',            '관절 건강',            1000, 1500, 'mg',       '1일 1~3회', 'oral', 'AI',  '글루코사민 황산염 기준. 최소 8주 복용 권장'),

-- ── 커큐민 ────────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='curcumin'), '성인',               '항산화/항염',          500,  2000, 'mg',       '1일 1~2회', 'oral', 'AI',  '커큐미노이드 기준. 피페린(BioPerine) 병용 시 흡수율 향상'),

-- ── 멜라토닌 ──────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='melatonin'), '성인',              '수면 개선',            0.5,  5,    'mg',       '취침 30~60분 전', 'oral', 'AI', '저용량(0.5~1mg)이 고용량보다 효과적인 경우도 있음'),
((SELECT id FROM ingredients WHERE slug='melatonin'), '65세 이상',         '수면 개선',            0.5,  2,    'mg',       '취침 30분 전', 'oral', 'AI', '고령자는 저용량 사용 권장. 한국은 전문의약품'),

-- ── 홍삼 (신규) ──────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='red-ginseng'), '성인',            '면역/피로/혈행',       1000, 3000, 'mg',       '1일 2~3회', 'oral', 'AI',  '홍삼 추출물 기준. 식약처 인정: 진세노사이드 Rg1+Rb1+Rg3 합계 1.2~11mg'),
((SELECT id FROM ingredients WHERE slug='red-ginseng'), '65세 이상',       '면역/피로',            500,  1500, 'mg',       '1일 1~2회', 'oral', 'AI',  '고령자는 저용량부터 시작'),

-- ── MSM (신규) ────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='msm'), '성인',                    '관절 건강',            1000, 3000, 'mg',       '1일 2~3회', 'oral', 'AI',  '식약처 인정 기능성: 1,500mg 이상. 최소 12주 복용 권장'),

-- ── 가르시니아 (신규) ─────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='garcinia'), '성인',                '체지방 감소',          500,  1500, 'mg HCA',   '식전 30~60분 1일 3회', 'oral', 'AI', '식약처 인정: HCA 750~2,800mg/일. 운동 병행 시 효과적'),

-- ── 콜라겐 (신규) ────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='collagen'), '성인',                '피부 건강',            1000, 10000,'mg',       '1일 1회',   'oral', 'AI',  '가수분해 콜라겐(펩타이드) 기준. 비타민 C 병용 시 효과적'),
((SELECT id FROM ingredients WHERE slug='collagen'), '성인',                '관절 건강',            10000,10000,'mg',       '1일 1회',   'oral', 'AI',  'II형 비변성 콜라겐(UC-II)는 40mg/일로 효과 보고'),

-- ── 크레아틴 (신규) ───────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='creatine'), '성인 (운동선수)',     '근력/수행능력',        3,    5,    'g',        '1일 1회',   'oral', 'AI',  '유지 용량. 로딩(20g/일 × 5~7일) 후 유지 3~5g'),
((SELECT id FROM ingredients WHERE slug='creatine'), '성인 (로딩)',         '초기 포화',            20,   20,   'g',        '4회 분할/일', 'oral','AI',  '5~7일 단기 로딩 후 유지 용량으로 전환');

-- ============================================================================
-- SECTION 7: 약물 상호작용 (ingredient_drug_interactions)
-- ============================================================================

INSERT INTO ingredient_drug_interactions (ingredient_id, drug_name, drug_class, interaction_mechanism, clinical_effect, severity_level, recommendation, evidence_level) VALUES

-- ── 오메가-3 ──────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='omega-3'), '와파린',       '항응고제',                '오메가-3가 혈소판 응집 억제 및 TXA2 합성 저해로 항응고 효과 상가',           'INR 상승, 출혈 위험 증가',                             'moderate',  '정기 INR 모니터링. 3g/일 이상 복용 시 의사 상담',              'rct'),
((SELECT id FROM ingredients WHERE slug='omega-3'), '아스피린',     '항혈소판제',              '혈소판 응집 이중 억제로 출혈 위험 증가',                                       '출혈 시간 연장 가능',                                  'mild',      '의사 지시 없이 고용량 오메가-3 병용 주의',                       'observational'),
((SELECT id FROM ingredients WHERE slug='omega-3'), '리바록사반',   '항응고제(DOAC)',           '항응고 효과 상가 가능',                                                        '출혈 위험 증가',                                       'moderate',  '의사 상담 필수',                                                'observational'),

-- ── 비타민 D ──────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='vitamin-d'), '히드로클로로티아지드', '티아지드 이뇨제',  '티아지드는 신장 칼슘 재흡수 증가. 비타민 D와 병용 시 칼슘 축적',              '고칼슘혈증 위험 증가',                                 'moderate',  '혈청 칼슘 정기 모니터링',                                       'observational'),
((SELECT id FROM ingredients WHERE slug='vitamin-d'), '콜레스티라민',         '담즙산 수지',      '콜레스티라민이 지용성 비타민 D 흡수를 감소',                                   '비타민 D 흡수 감소',                                   'moderate',  '2시간 간격 두고 복용',                                          'guideline'),
((SELECT id FROM ingredients WHERE slug='vitamin-d'), '코르티코스테로이드',   '스테로이드',       '장기 스테로이드 사용 시 비타민 D 대사 및 칼슘 흡수 저해',                      '뼈 손실 위험 증가',                                    'moderate',  '비타민 D + 칼슘 보충 권고',                                     'guideline'),

-- ── 칼슘 ──────────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='calcium'), '테트라사이클린',   '항생제',                 '칼슘이 테트라사이클린 계열 항생제와 킬레이트 형성',                             '항생제 흡수율 50% 이상 감소',                          'moderate',  '칼슘 복용 2시간 전 또는 6시간 후 항생제 복용',                  'guideline'),
((SELECT id FROM ingredients WHERE slug='calcium'), '레보티록신',      '갑상선 호르몬',           '칼슘이 레보티록신 흡수를 방해',                                                 '갑상선 호르몬 효과 감소',                              'moderate',  '레보티록신 복용 4시간 후 칼슘 복용',                            'guideline'),
((SELECT id FROM ingredients WHERE slug='calcium'), '비스포스포네이트', '골다공증 치료제',         '칼슘이 비스포스포네이트 흡수를 방해',                                           '골다공증 치료제 효과 감소',                            'moderate',  '비스포스포네이트 복용 30분~2시간 전 공복, 칼슘은 이후',          'guideline'),

-- ── 철분 ──────────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='iron'), '레보티록신',       '갑상선 호르몬',             '철분이 레보티록신 흡수를 저해',                                                 '갑상선 호르몬 효과 감소',                              'moderate',  '레보티록신 복용 4시간 후 철분 복용',                            'guideline'),
((SELECT id FROM ingredients WHERE slug='iron'), '시프로플록사신',   '퀴놀론 항생제',             '철분이 퀴놀론과 킬레이트 형성, 항생제 흡수 감소',                               '항생제 흡수율 최대 90% 감소',                          'moderate',  '철분 복용 2시간 전 또는 6시간 후 항생제 복용',                  'guideline'),
((SELECT id FROM ingredients WHERE slug='iron'), '테트라사이클린',   '항생제',                    '철분이 테트라사이클린과 킬레이트 형성',                                          '항생제 흡수 감소',                                     'moderate',  '2시간 간격 두고 복용',                                          'guideline'),

-- ── 코엔자임Q10 ───────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='coq10'), '와파린',          '항응고제',                  'CoQ10이 비타민 K 유사 구조로 와파린의 항응고 효과 감소',                        'INR 감소, 혈전 위험 증가 가능',                        'moderate',  'INR 정기 모니터링. 용량 변경 시 INR 재확인',                    'case_report'),

-- ── 비타민 E ──────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='vitamin-e'), '와파린',        '항응고제',                '고용량 비타민 E가 비타민 K 의존성 응고인자 억제',                               'INR 상승, 출혈 위험 증가',                             'moderate',  '항응고제 복용 중 비타민 E 400IU 이상 고용량 주의',              'rct'),
((SELECT id FROM ingredients WHERE slug='vitamin-e'), '아스피린',      '항혈소판제',              '항혈소판 효과 상가',                                                            '출혈 위험 증가 가능',                                  'mild',      '고용량 병용 주의',                                               'observational'),

-- ── 홍삼 ─────────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='red-ginseng'), '와파린',       '항응고제',              '홍삼이 와파린의 항응고 효과를 감소시킬 가능성',                                  'INR 감소, 혈전 위험 증가 가능',                        'moderate',  'INR 정기 모니터링',                                             'rct'),
((SELECT id FROM ingredients WHERE slug='red-ginseng'), '메트포르민',   '혈당강하제',            '홍삼의 인슐린 감수성 개선 효과가 혈당강하 효과 상가',                            '저혈당 위험 증가',                                     'moderate',  '혈당 모니터링 강화, 담당의 상담',                               'rct'),
((SELECT id FROM ingredients WHERE slug='red-ginseng'), '이마티닙',     '항암제(BCR-ABL 억제제)', 'CYP3A4 경쟁적 억제로 이마티닙 혈중 농도 변화 가능',                             '항암 효과 변화 가능',                                  'moderate',  '항암 치료 중 홍삼 복용 금지 또는 담당의 상담',                  'case_report'),

-- ── 커큐민 ────────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='curcumin'), '와파린',         '항응고제',               '커큐민의 혈소판 응집 억제 및 피브리노겐 감소',                                   'INR 상승, 출혈 위험 증가',                             'moderate',  'INR 모니터링, 고용량 커큐민 병용 주의',                          'observational'),
((SELECT id FROM ingredients WHERE slug='curcumin'), '타목시펜',       '항에스트로겐',           '커큐민이 CYP2D6 억제로 타목시펜 활성대사체 감소',                                '타목시펜 치료 효과 감소 가능',                         'moderate',  '유방암 치료 중 고용량 커큐민 주의',                              'observational'),

-- ── 밀크씨슬 ──────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='milk-thistle'), '사이클로스포린', 'CYP3A4 기질 면역억제제', '실리마린이 CYP3A4 억제로 사이클로스포린 혈중 농도 증가',                      '면역억제 과잉, 신독성 위험',                           'moderate',  '장기 이식 환자 밀크씨슬 사용 금지 또는 담당의 승인',             'case_report'),
((SELECT id FROM ingredients WHERE slug='milk-thistle'), '인다비르',     '항바이러스제(HIV 프로테아제)', '실리마린이 인다비르 흡수 감소',                                          '항바이러스 효과 감소',                                 'moderate',  'HIV 치료 중 밀크씨슬 복용 전 의사 상담',                        'rct'),

-- ── 멜라토닌 ──────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='melatonin'), '플루복사민',    'SSRI/CYP1A2 억제제',     'CYP1A2 억제로 멜라토닌 혈중 농도 17배 이상 증가',                               '과도한 진정, 졸음',                                    'moderate',  '항우울제 복용 중 멜라토닌 사용 주의, 의사 상담',                'rct'),
((SELECT id FROM ingredients WHERE slug='melatonin'), '벤조디아제핀',  '수면진정제',             '중추신경 억제 효과 상가',                                                        '과도한 진정, 인지기능 저하',                           'moderate',  '수면제 복용 중 멜라토닌 병용 주의',                              'rct'),
((SELECT id FROM ingredients WHERE slug='melatonin'), '타크롤리무스',  '면역억제제',             '멜라토닌이 면역 조절 기능에 영향',                                               '면역억제 효과 변화 가능',                              'moderate',  '장기 이식 환자 의사 상담 필수',                                 'case_report'),

-- ── 가르시니아 ────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='garcinia'), '인슐린',         '혈당강하제',             'HCA의 혈당 강하 작용이 인슐린 효과와 상가',                                      '저혈당 위험 증가',                                     'moderate',  '혈당 모니터링 강화, 담당의 상담',                               'observational'),
((SELECT id FROM ingredients WHERE slug='garcinia'), '스타틴',         '지질강하제',             '가르시니아의 간 독성 가능성이 스타틴 병용 시 증가 우려',                         '간 독성 위험 증가 가능',                               'moderate',  '간 기능 정기 모니터링',                                         'case_report'),

-- ── 글루코사민 ────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='glucosamine'), '와파린',       '항응고제',              '기전 불명확, 와파린의 항응고 효과 증가 보고',                                    'INR 상승, 출혈 위험',                                  'moderate',  'INR 정기 모니터링',                                             'case_report'),

-- ── 마그네슘 ──────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='magnesium'), '비스포스포네이트','골다공증 치료제',        '마그네슘이 비스포스포네이트 흡수를 방해',                                        '골다공증 치료제 효과 감소',                            'moderate',  '비스포스포네이트 복용 후 2시간 이후 마그네슘 복용',              'guideline'),
((SELECT id FROM ingredients WHERE slug='magnesium'), '가바펜틴',       '신경통/항경련제',        '마그네슘이 NMDA 수용체 차단으로 가바펜틴 효과 상가',                             '중추신경 억제 상가',                                   'mild',      '의사 상담 권고',                                                'observational'),

-- ── 프로바이오틱스 ────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='probiotics'), '면역억제제',    '면역억제제(전반)',       '면역 조절 기능의 프로바이오틱스가 면역억제 효과에 영향',                         '면역억제 효과 약화 가능, 감염 위험',                   'moderate',  '면역억제제 복용 중 의사 상담 후 복용',                          'guideline'),
((SELECT id FROM ingredients WHERE slug='probiotics'), '항생제',        '항생제(전반)',           '항생제가 프로바이오틱스 균주를 사멸',                                            '프로바이오틱스 효과 감소',                             'mild',      '항생제와 2시간 간격 두고 복용',                                 'guideline');

-- ============================================================================
-- SECTION 8: 규제 상태 (regulatory_statuses) — 전체 25종
-- ============================================================================

INSERT INTO regulatory_statuses (ingredient_id, country_code, regulatory_category, status, authority_name, notes) VALUES

-- ── 비타민 D ──────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='vitamin-d'), 'KR', 'health_functional_food', 'approved', '식품의약품안전처(MFDS)', '고시형 기능성 원료. 1일 200~2,000IU 기준'),
((SELECT id FROM ingredients WHERE slug='vitamin-d'), 'US', 'dietary_supplement',     'approved', 'FDA', 'GRAS/DS. Structure-function claim 허용'),

-- ── 비타민 C ──────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='vitamin-c'), 'KR', 'health_functional_food', 'approved', '식품의약품안전처(MFDS)', '고시형 기능성 원료. 1일 100~1,000mg'),
((SELECT id FROM ingredients WHERE slug='vitamin-c'), 'US', 'dietary_supplement',     'approved', 'FDA', 'GRAS/DS'),

-- ── 비타민 B12 ────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='vitamin-b12'), 'KR', 'health_functional_food', 'approved', '식품의약품안전처(MFDS)', '고시형 기능성 원료'),
((SELECT id FROM ingredients WHERE slug='vitamin-b12'), 'US', 'dietary_supplement',     'approved', 'FDA', 'GRAS/DS'),

-- ── 엽산 ──────────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='folate'), 'KR', 'health_functional_food', 'approved', '식품의약품안전처(MFDS)', '고시형 기능성 원료. 임산부 건강기능식품 핵심 원료'),
((SELECT id FROM ingredients WHERE slug='folate'), 'US', 'dietary_supplement',     'approved', 'FDA', 'Authorized Health Claim: 신경관 결손 예방'),

-- ── 오메가-3 ──────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='omega-3'), 'KR', 'health_functional_food', 'approved', '식품의약품안전처(MFDS)', '고시형 기능성 원료. EPA+DHA 합계 500~2,000mg'),
((SELECT id FROM ingredients WHERE slug='omega-3'), 'US', 'dietary_supplement',     'approved', 'FDA', 'Qualified Health Claim for cardiovascular'),

-- ── 마그네슘 ──────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='magnesium'), 'KR', 'health_functional_food', 'approved', '식품의약품안전처(MFDS)', '고시형 기능성 원료'),
((SELECT id FROM ingredients WHERE slug='magnesium'), 'US', 'dietary_supplement',     'approved', 'FDA', 'GRAS/DS'),

-- ── 아연 ──────────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='zinc'), 'KR', 'health_functional_food', 'approved', '식품의약품안전처(MFDS)', '고시형 기능성 원료'),
((SELECT id FROM ingredients WHERE slug='zinc'), 'US', 'dietary_supplement',     'approved', 'FDA', 'GRAS/DS'),

-- ── 철분 ──────────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='iron'), 'KR', 'health_functional_food', 'approved', '식품의약품안전처(MFDS)', '고시형 기능성 원료'),
((SELECT id FROM ingredients WHERE slug='iron'), 'US', 'dietary_supplement',     'approved', 'FDA', 'GRAS/DS. Authorized Health Claim for iron-deficiency anemia'),

-- ── 칼슘 ──────────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='calcium'), 'KR', 'health_functional_food', 'approved', '식품의약품안전처(MFDS)', '고시형 기능성 원료'),
((SELECT id FROM ingredients WHERE slug='calcium'), 'US', 'dietary_supplement',     'approved', 'FDA', 'Authorized Health Claim for osteoporosis'),

-- ── 프로바이오틱스 ────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='probiotics'), 'KR', 'health_functional_food', 'approved', '식품의약품안전처(MFDS)', '고시형 기능성 원료. 1일 1~100억 CFU'),
((SELECT id FROM ingredients WHERE slug='probiotics'), 'US', 'dietary_supplement',     'approved', 'FDA', 'GRAS/DS. 균주별 안전성 검토 필요'),

-- ── 루테인 ────────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='lutein'), 'KR', 'health_functional_food', 'approved', '식품의약품안전처(MFDS)', '고시형 기능성 원료. 1일 10~20mg'),
((SELECT id FROM ingredients WHERE slug='lutein'), 'US', 'dietary_supplement',     'approved', 'FDA', 'GRAS/DS. 마리골드 추출물'),

-- ── 코엔자임Q10 ───────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='coq10'), 'KR', 'health_functional_food', 'approved', '식품의약품안전처(MFDS)', '고시형 기능성 원료. 1일 90~100mg'),
((SELECT id FROM ingredients WHERE slug='coq10'), 'US', 'dietary_supplement',     'approved', 'FDA', 'GRAS/DS'),

-- ── 밀크씨슬 ──────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='milk-thistle'), 'KR', 'health_functional_food', 'approved', '식품의약품안전처(MFDS)', '고시형 기능성 원료. 1일 실리마린 130mg 이상'),
((SELECT id FROM ingredients WHERE slug='milk-thistle'), 'US', 'dietary_supplement',     'approved', 'FDA', 'Dietary Supplement. 약물 상호작용 모니터링 권고'),

-- ── 글루코사민 ────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='glucosamine'), 'KR', 'health_functional_food', 'approved', '식품의약품안전처(MFDS)', '고시형 기능성 원료. 1일 글루코사민 1,500mg 이상'),
((SELECT id FROM ingredients WHERE slug='glucosamine'), 'US', 'dietary_supplement',     'approved', 'FDA', 'Dietary Supplement'),

-- ── 비오틴 ────────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='biotin'), 'KR', 'health_functional_food', 'approved', '식품의약품안전처(MFDS)', '고시형 기능성 원료'),
((SELECT id FROM ingredients WHERE slug='biotin'), 'US', 'dietary_supplement',     'approved', 'FDA', 'GRAS/DS. 검사 간섭 FDA 경고(2017)'),

-- ── 셀레늄 ────────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='selenium'), 'KR', 'health_functional_food', 'approved', '식품의약품안전처(MFDS)', '고시형 기능성 원료. 1일 50~200mcg'),
((SELECT id FROM ingredients WHERE slug='selenium'), 'US', 'dietary_supplement',     'approved', 'FDA', 'Qualified Health Claim for certain cancers (limited evidence)'),

-- ── 비타민 A ──────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='vitamin-a'), 'KR', 'health_functional_food', 'approved', '식품의약품안전처(MFDS)', '고시형 기능성 원료. UL 3,000mcg RAE/일'),
((SELECT id FROM ingredients WHERE slug='vitamin-a'), 'US', 'dietary_supplement',     'approved', 'FDA', 'GRAS/DS'),

-- ── 비타민 E ──────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='vitamin-e'), 'KR', 'health_functional_food', 'approved', '식품의약품안전처(MFDS)', '고시형 기능성 원료. UL 540mg/일(한국)'),
((SELECT id FROM ingredients WHERE slug='vitamin-e'), 'US', 'dietary_supplement',     'approved', 'FDA', 'GRAS/DS'),

-- ── 커큐민 ────────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='curcumin'), 'KR', 'health_functional_food', 'approved', '식품의약품안전처(MFDS)', '강황 추출물로 개별인정형 포함. 항산화 기능성'),
((SELECT id FROM ingredients WHERE slug='curcumin'), 'US', 'dietary_supplement',     'approved', 'FDA', 'GRAS (강황/터메릭). 식품첨가물/보충제 허용'),

-- ── 멜라토닌 ──────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='melatonin'), 'KR', 'prescription_drug',      'approved', '식품의약품안전처(MFDS)', '전문의약품(서시르카딘 등). 건강기능식품으로 판매 불허'),
((SELECT id FROM ingredients WHERE slug='melatonin'), 'US', 'dietary_supplement',     'approved', 'FDA', 'Dietary Supplement으로 OTC 판매 허용. 미국과 한국 규제 상이'),
((SELECT id FROM ingredients WHERE slug='melatonin'), 'EU', 'novel_food',             'conditionally_approved', 'EFSA/EC', '식품보충제로 1mg 미만 허용. 국가별 상이'),

-- ── 홍삼 (신규) ──────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='red-ginseng'), 'KR', 'health_functional_food', 'approved', '식품의약품안전처(MFDS)', '고시형 기능성 원료. 진세노사이드 Rg1+Rb1+Rg3 합계 1.2~11mg/일'),
((SELECT id FROM ingredients WHERE slug='red-ginseng'), 'US', 'dietary_supplement',     'approved', 'FDA', 'Dietary Supplement. Panax ginseng'),

-- ── MSM (신규) ────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='msm'), 'KR', 'health_functional_food', 'approved', '식품의약품안전처(MFDS)', '고시형 기능성 원료. 관절 건강. 1일 1,500mg 이상'),
((SELECT id FROM ingredients WHERE slug='msm'), 'US', 'dietary_supplement',     'approved', 'FDA', 'GRAS/DS'),

-- ── 가르시니아 (신규) ─────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='garcinia'), 'KR', 'health_functional_food', 'approved', '식품의약품안전처(MFDS)', '고시형 기능성 원료. 체지방 감소. HCA 750~2,800mg/일'),
((SELECT id FROM ingredients WHERE slug='garcinia'), 'US', 'dietary_supplement',     'restricted', 'FDA', 'DS 허용이나 FDA가 일부 가르시니아 제품 간 독성 우려 경고 발령 (2017)'),

-- ── 콜라겐 (신규) ────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='collagen'), 'KR', 'health_functional_food', 'approved', '식품의약품안전처(MFDS)', '고시형 기능성 원료(어류 콜라겐 등). 피부 건강 기능성'),
((SELECT id FROM ingredients WHERE slug='collagen'), 'US', 'dietary_supplement',     'approved', 'FDA', 'GRAS/DS. Hydrolyzed collagen'),

-- ── 크레아틴 (신규) ───────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='creatine'), 'KR', 'general_food',           'approved', '식품의약품안전처(MFDS)', '일반식품 원료로 허용. 건강기능식품 기능성 원료 미인정(2026년 기준). 운동 보조식품 시장에서 일반식품으로 유통'),
((SELECT id FROM ingredients WHERE slug='creatine'), 'US', 'dietary_supplement',     'approved', 'FDA', 'Dietary Supplement. GRAS 논의 중. 광범위한 안전성 연구 있음')

ON CONFLICT (ingredient_id, country_code, regulatory_category, status, effective_date) DO UPDATE SET
  notes      = EXCLUDED.notes,
  updated_at = NOW();
