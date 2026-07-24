-- ============================================================================
-- 037: 비타민 safety_items 보강 + 중복 제거
-- (1) 중복 6건 삭제 (B2, K, B3, B5)
-- (2) vitamin-c, vitamin-e, vitamin-b6, folate 안전성 정보 추가
-- 출처: NIH ODS Fact Sheets, 한국 2020 DRI, EFSA Scientific Opinions
-- ============================================================================

-- ── 1. 중복 제거 ──────────────────────────────────────────────────────────
-- B2(264): 1999는 1993의 중복
-- K(269): 1997은 1991, 1998은 1992의 중복
-- B3(1578): 1994는 1988, 1995는 1989의 중복
-- B5(1579): 1996은 1990의 중복
DELETE FROM safety_items WHERE id IN (1999, 1997, 1998, 1994, 1995, 1996);


-- ── 2. 비타민 C (id=2) ───────────────────────────────────────────────────
INSERT INTO safety_items (ingredient_id, safety_type, title, description, severity_level, evidence_level, frequency_text, applies_to_population, management_advice) VALUES
(2, 'adverse_effect', '고용량 소화기 장애',
 '2,000mg/일 이상 복용 시 설사, 오심, 복통, 속쓰림 등 소화기 증상이 나타날 수 있다.',
 'mild', 'rct', 'common', NULL,
 '1회 복용량을 줄이거나 식후 복용. 증상 지속 시 복용 중단.'),

(2, 'adverse_effect', '신장결석 위험 증가',
 '고용량 비타민 C는 체내에서 옥살산으로 대사되어 옥살산칼슘 결석 위험을 높일 수 있다. 남성에서 더 뚜렷한 경향.',
 'moderate', 'observational', 'uncommon', '신장결석 병력자',
 '결석 병력이 있으면 UL(2,000mg/일) 이하로 제한. 충분한 수분 섭취 병행.'),

(2, 'drug_interaction', '알루미늄 함유 제산제 상호작용',
 '비타민 C가 알루미늄 흡수를 증가시켜 신장 기능 저하자에서 알루미늄 축적 위험을 높일 수 있다.',
 'moderate', 'observational', 'rare', '신장 기능 저하자',
 '신부전 환자는 알루미늄 제산제와 비타민 C 고용량 병용을 피한다.'),

(2, 'precaution', '상한섭취량(UL) 2,000mg/일',
 '한국 2020 DRI 기준 성인 상한섭취량은 2,000mg/일. 이를 초과하면 소화기 이상 및 신장결석 위험 증가.',
 'mild', 'guideline', NULL, '일반 성인',
 '보충제 + 식품 합산 2,000mg/일 이하 유지 권장.'),

(2, 'caution', '혈색소침착증(hemochromatosis) 환자 주의',
 '비타민 C가 비헴철 흡수를 촉진하여 유전성 혈색소침착증 환자에서 철 과부하를 악화시킬 수 있다.',
 'serious', 'guideline', NULL, '혈색소침착증 환자',
 '혈색소침착증 진단 시 고용량 비타민 C 보충제 사용 전 반드시 전문가 상담.');


-- ── 3. 비타민 E (id=18) ──────────────────────────────────────────────────
INSERT INTO safety_items (ingredient_id, safety_type, title, description, severity_level, evidence_level, frequency_text, applies_to_population, management_advice) VALUES
(18, 'adverse_effect', '고용량 출혈 위험 증가',
 '400IU/일 이상 장기 복용 시 항혈소판 작용으로 출혈 경향이 증가한다. 특히 수술 전후 주의 필요.',
 'serious', 'rct', 'uncommon', '출혈 경향 환자, 수술 예정자',
 '수술 2~4주 전 고용량 비타민 E 보충 중단. 이상 출혈 발생 시 의료진 상담.'),

(18, 'drug_interaction', '항응고제(와파린) 출혈 위험 증가',
 '비타민 E가 비타민 K 의존 응고인자를 억제하여 와파린의 항응고 효과를 강화, 출혈 위험을 높인다.',
 'serious', 'rct', 'uncommon', '항응고제 복용자',
 '와파린 복용 중 비타민 E 고용량 보충 시 INR 모니터링 강화. 의료진과 상의.'),

(18, 'adverse_effect', '전립선암 위험 증가 가능성',
 'SELECT 대규모 RCT에서 비타민 E 400IU/일 보충군의 전립선암 발생률이 유의하게 증가(HR 1.17). 건강한 남성 대상.',
 'moderate', 'rct', 'rare', '건강한 남성',
 '전립선암 예방 목적의 고용량 비타민 E 보충은 권장되지 않음.'),

(18, 'precaution', '상한섭취량(UL) 540mg/일 α-토코페롤',
 '한국 2020 DRI 기준 성인 UL 540mg/일(약 800IU). 합성 dl-α-토코페롤은 천연 대비 생체이용률 50%.',
 'mild', 'guideline', NULL, '일반 성인',
 '보충제 라벨의 IU와 mg 환산 확인. UL 이하 복용 권장.');


-- ── 4. 비타민 B6 (id=265) ────────────────────────────────────────────────
INSERT INTO safety_items (ingredient_id, safety_type, title, description, severity_level, evidence_level, frequency_text, applies_to_population, management_advice) VALUES
(265, 'adverse_effect', '고용량 장기 복용 시 말초신경병증',
 '200mg/일 이상을 수개월~수년 복용하면 감각이상, 사지 저림, 보행장애 등 말초신경병증이 발생할 수 있다. 용량 의존적이며 중단 시 대부분 회복.',
 'serious', 'observational', 'uncommon', NULL,
 '100mg/일 이하로 제한. 저림·감각이상 발생 시 즉시 복용 중단 후 의료진 상담.'),

(265, 'drug_interaction', '레보도파 단독 효과 감소',
 '비타민 B6가 말초에서 레보도파의 도파민 전환을 촉진해 뇌 도달량을 감소시킨다. 카르비도파 병용 제제에서는 해당 없음.',
 'serious', 'rct', 'common', '파킨슨병 레보도파 단독 복용자',
 '레보도파 단독 복용 중이면 B6 보충제 병용 금지. 카르비도파/레보도파 복합제 사용 시에는 안전.'),

(265, 'precaution', '상한섭취량(UL) 100mg/일',
 '한국 2020 DRI 기준 성인 UL 100mg/일. 이를 초과하면 신경독성 위험이 증가한다.',
 'mild', 'guideline', NULL, '일반 성인',
 'UL 100mg/일 이하 유지. 고용량 B-complex 제품의 B6 함량 확인 필요.'),

(265, 'adverse_effect', '광과민성 피부반응',
 '고용량 비타민 B6 장기 복용 시 드물게 광과민성 피부 발진이 보고되었다.',
 'mild', 'case_report', 'rare', NULL,
 '햇빛 노출 후 피부 발진 발생 시 복용량 감량 또는 중단 고려.');


-- ── 5. 엽산 (id=4) ───────────────────────────────────────────────────────
INSERT INTO safety_items (ingredient_id, safety_type, title, description, severity_level, evidence_level, frequency_text, applies_to_population, management_advice) VALUES
(4, 'adverse_effect', '비타민 B12 결핍 은폐',
 '고용량 합성 엽산(>1,000μg/일)이 거대적아구성 빈혈을 교정하여 B12 결핍의 혈액학적 징후를 마스킹한다. B12 결핍 신경손상은 진행될 수 있어 진단 지연 위험.',
 'serious', 'observational', 'uncommon', '고령자, 채식주의자, 위장질환자',
 '엽산 고용량 보충 시 B12 수치 정기 검사. 50세 이상은 B12 병행 보충 고려.'),

(4, 'drug_interaction', '메토트렉세이트 효과 감소',
 '엽산이 메토트렉세이트(항엽산제)의 세포독성 효과를 길항할 수 있다. 류마티스 치료에서는 부작용 경감 목적으로 의도적 병용하기도 함.',
 'serious', 'rct', 'common', '메토트렉세이트 복용자',
 '메토트렉세이트 복용 중 엽산 보충은 반드시 처방 의사 지시에 따른다.'),

(4, 'drug_interaction', '항경련제 상호작용',
 '엽산이 페니토인, 카르바마제핀, 발프로산 등 항경련제의 혈중 농도를 낮출 수 있다. 역으로 이들 약물은 엽산 대사를 촉진해 결핍을 유발.',
 'moderate', 'observational', 'uncommon', '항경련제 복용자',
 '항경련제 복용 중 엽산 보충·중단 시 약물 혈중 농도 모니터링 필요.'),

(4, 'precaution', '상한섭취량(UL) 1,000μg/일 합성 엽산',
 '한국 2020 DRI 기준 성인 UL 1,000μg/일(합성 folic acid). 식품 중 자연 엽산(folate)에는 UL 미적용.',
 'mild', 'guideline', NULL, '일반 성인',
 '보충제 라벨의 엽산 함량이 합성(folic acid)인지 확인. UL은 합성 엽산에만 적용.'),

(4, 'precaution', '임신 전·초기 충분 섭취 권고',
 '임신 전 최소 4주~임신 12주까지 400~800μg/일 합성 엽산 보충이 신경관결손(NTD) 예방에 권고됨. 보충 부족 시 NTD 위험 증가.',
 'moderate', 'rct', NULL, '가임기 여성, 임신 초기',
 '임신 계획 시 최소 1개월 전부터 엽산 400μg/일 이상 보충 시작.');
