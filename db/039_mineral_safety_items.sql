-- ============================================================================
-- 039: 미네랄 safety_items 보강 (9종)
-- 아연(7), 칼슘(9), 셀레늄(16), 구리(59), 망간(185),
-- 몰리브덴(196), 요오드(433), 인(1586), 불소(1587)
-- 출처: NIH ODS Fact Sheets, 한국 영양소 섭취기준 2020, EFSA
-- ============================================================================

-- ── 아연 (id=7) ──────────────────────────────────────────────────────────
INSERT INTO safety_items (ingredient_id, safety_type, title, description, severity_level, evidence_level, frequency_text, applies_to_population, management_advice) VALUES
(7, 'adverse_effect', '고용량 소화기 장애',
 '40mg/일 이상 공복 복용 시 오심, 구토, 설사, 복통 등이 나타날 수 있다.',
 'mild', 'rct', 'common', NULL,
 '식후 복용으로 완화. 증상 지속 시 용량 감량.'),

(7, 'adverse_effect', '장기 고용량 시 구리 결핍',
 '40mg/일 이상 장기 복용 시 아연이 구리 흡수를 경쟁적으로 억제하여 구리 결핍(빈혈, 호중구감소증)을 유발할 수 있다.',
 'serious', 'rct', 'uncommon', NULL,
 '장기 고용량 보충 시 구리 1~2mg/일 병행 고려. 혈구 검사 정기 모니터링.'),

(7, 'drug_interaction', '항생제 흡수 감소',
 '아연이 퀴놀론계(시프로플록사신 등)·테트라사이클린계 항생제와 킬레이트를 형성해 흡수를 30~50% 감소시킨다.',
 'moderate', 'rct', 'common', '항생제 복용자',
 '항생제 복용 2시간 전 또는 4~6시간 후에 아연 보충제 복용.'),

(7, 'precaution', '상한섭취량(UL) 35mg/일',
 '한국 2020 영양소 섭취기준 성인 UL 35mg/일. 이를 초과하면 구리 결핍 및 소화기 이상 위험 증가.',
 'mild', 'guideline', NULL, '일반 성인',
 '보충제 + 식품 합산 UL 이하 유지. 아연 로젠지 장기 사용 시 총량 확인.');


-- ── 칼슘 (id=9) ──────────────────────────────────────────────────────────
INSERT INTO safety_items (ingredient_id, safety_type, title, description, severity_level, evidence_level, frequency_text, applies_to_population, management_advice) VALUES
(9, 'adverse_effect', '변비 및 복부팽만',
 '칼슘 보충제(특히 탄산칼슘) 복용 시 변비, 가스, 복부팽만감이 흔하게 나타난다.',
 'mild', 'rct', 'common', NULL,
 '구연산칼슘로 전환하거나 분할 복용(1회 500mg 이하). 수분·식이섬유 섭취 병행.'),

(9, 'adverse_effect', '신장결석 위험 증가',
 '칼슘 보충제가 신장 옥살산칼슘 결석 위험을 높일 수 있다(WHI 연구 HR 1.17). 식품 유래 칼슘은 오히려 보호 효과.',
 'moderate', 'rct', 'uncommon', '신장결석 병력자',
 '결석 병력 시 식품 칼슘 우선, 보충제는 식사와 함께 분할 복용. 충분한 수분 섭취.'),

(9, 'drug_interaction', '레보티록신 흡수 감소',
 '칼슘이 갑상선 호르몬제(레보티록신)와 킬레이트를 형성해 흡수를 유의하게 감소시킨다.',
 'serious', 'rct', 'common', '갑상선 호르몬제 복용자',
 '레보티록신 복용 후 최소 4시간 간격을 두고 칼슘 보충제 복용.'),

(9, 'drug_interaction', '비스포스포네이트 흡수 감소',
 '칼슘이 알렌드로네이트 등 비스포스포네이트계 골다공증 약물의 흡수를 현저히 감소시킨다.',
 'serious', 'rct', 'common', '비스포스포네이트 복용자',
 '비스포스포네이트 복용 후 최소 30분~2시간 간격 후 칼슘 복용.'),

(9, 'precaution', '상한섭취량(UL) 2,500mg/일',
 '한국 2020 영양소 섭취기준 성인(19~49세) UL 2,500mg/일. 50세 이상은 2,000mg/일. 초과 시 고칼슘혈증, 신장결석 위험.',
 'mild', 'guideline', NULL, '일반 성인',
 '보충제 + 식품(유제품 등) 합산량 확인. 1회 500mg 이하 분할 복용이 흡수율도 높음.');


-- ── 셀레늄 (id=16) ───────────────────────────────────────────────────────
INSERT INTO safety_items (ingredient_id, safety_type, title, description, severity_level, evidence_level, frequency_text, applies_to_population, management_advice) VALUES
(16, 'adverse_effect', '셀레늄 중독(selenosis)',
 '400μg/일 초과 만성 섭취 시 탈모, 조갑 변형·취약, 마늘냄새 호흡, 피로, 과민, 신경장애가 나타날 수 있다.',
 'serious', 'observational', 'uncommon', NULL,
 'UL 초과 즉시 중단. 증상 발현 시 의료진 상담.'),

(16, 'adverse_effect', '2형 당뇨 위험 증가 가능성',
 'SELECT 등 대규모 RCT에서 200μg/일 셀레늄 보충군의 2형 당뇨 발생률 증가가 관찰되었다. 기저 셀레늄 수치가 높은 집단에서 더 뚜렷.',
 'moderate', 'rct', 'rare', '셀레늄 수치가 충분한 사람',
 '결핍이 확인되지 않은 경우 고용량 셀레늄 보충은 권장되지 않음.'),

(16, 'precaution', '상한섭취량(UL) 400μg/일',
 '한국 2020 영양소 섭취기준 성인 UL 400μg/일. 브라질넛 1개에 ~70~90μg 함유되므로 보충제와 식품 합산 주의.',
 'mild', 'guideline', NULL, '일반 성인',
 '보충제 복용 시 식품 셀레늄(브라질넛, 해산물 등) 섭취량 함께 고려.');


-- ── 구리 (id=59) ─────────────────────────────────────────────────────────
INSERT INTO safety_items (ingredient_id, safety_type, title, description, severity_level, evidence_level, frequency_text, applies_to_population, management_advice) VALUES
(59, 'adverse_effect', '소화기 장애',
 '고용량(10mg 이상) 구리 섭취 시 오심, 구토, 복통, 설사가 나타날 수 있다.',
 'mild', 'observational', 'common', NULL,
 '용량 감량 또는 식후 복용. 증상 지속 시 중단.'),

(59, 'adverse_effect', '간독성',
 '만성적 과다 섭취 시 간세포 손상, 간경변이 발생할 수 있다. 윌슨병 환자는 정상 섭취량에서도 구리 축적.',
 'serious', 'observational', 'rare', NULL,
 '간기능 검사 이상 시 구리 보충 즉시 중단. 윌슨병 의심 시 전문의 상담.'),

(59, 'caution', '윌슨병 환자 금기',
 '윌슨병(유전성 구리 대사 장애)은 구리 배설 장애로 간·뇌에 구리가 축적된다. 구리 보충은 절대 금기.',
 'critical', 'guideline', NULL, '윌슨병 환자',
 '윌슨병 진단자는 구리 보충제 절대 금지. 구리 제한 식이 + 킬레이트 치료 필요.'),

(59, 'precaution', '상한섭취량(UL) 10mg/일',
 '한국 2020 영양소 섭취기준 성인 UL 10,000μg(10mg)/일.',
 'mild', 'guideline', NULL, '일반 성인',
 '종합비타민에 포함된 구리 함량(보통 0.5~2mg) 확인. 별도 보충제 병용 시 합산.');


-- ── 망간 (id=185) ────────────────────────────────────────────────────────
INSERT INTO safety_items (ingredient_id, safety_type, title, description, severity_level, evidence_level, frequency_text, applies_to_population, management_advice) VALUES
(185, 'adverse_effect', '신경독성(manganism)',
 '만성적 고용량 노출(주로 직업적) 시 파킨슨병 유사 증상(떨림, 보행장애, 인지기능 저하)이 나타날 수 있다. 경구 보충제에서는 극히 드묾.',
 'serious', 'observational', 'rare', NULL,
 'UL 초과 복용 지양. 떨림·보행 이상 시 즉시 중단 후 의료진 상담.'),

(185, 'caution', '간질환 환자 주의',
 '망간은 주로 담즙으로 배설되므로 간경변·담도폐쇄 환자는 망간 축적 위험이 높아 신경독성 위험 증가.',
 'serious', 'guideline', NULL, '간질환·담도질환 환자',
 '간기능 저하 환자는 망간 보충제 사용 전 반드시 전문가 상담.'),

(185, 'precaution', '상한섭취량(UL) 11mg/일',
 '한국 2020 영양소 섭취기준 성인 UL 11mg/일. 식품에서의 과다 섭취는 거의 보고되지 않으나 보충제 주의.',
 'mild', 'guideline', NULL, '일반 성인',
 '종합비타민의 망간 함량(보통 1~2.3mg) 확인. 별도 보충 불필요한 경우가 많음.');


-- ── 몰리브덴 (id=196) ───────────────────────────────────────────────────
INSERT INTO safety_items (ingredient_id, safety_type, title, description, severity_level, evidence_level, frequency_text, applies_to_population, management_advice) VALUES
(196, 'adverse_effect', '통풍 유사 증상',
 '고용량 몰리브덴이 잔틴 산화효소 활성을 높여 요산 생성을 증가시켜 통풍 유사 관절통을 유발할 수 있다.',
 'moderate', 'observational', 'rare', '통풍 병력자',
 '통풍 병력 시 고용량 몰리브덴 보충 지양. 관절통 발생 시 중단.'),

(196, 'adverse_effect', '구리 대사 간섭',
 '동물 실험에서 고용량 몰리브덴이 구리 흡수를 저해하여 구리 결핍을 유발할 수 있음이 관찰되었다.',
 'moderate', 'observational', 'rare', NULL,
 '장기 고용량 보충 시 구리 수치 모니터링 고려.'),

(196, 'precaution', '상한섭취량(UL) 2,000μg/일',
 '한국 2020 영양소 섭취기준 성인 UL 2,000μg(2mg)/일. 일반 식이에서 결핍·과잉 모두 드묾.',
 'mild', 'guideline', NULL, '일반 성인',
 '종합비타민 포함량(보통 25~75μg) 수준은 안전. 별도 고용량 보충 불필요.');


-- ── 요오드 (id=433) ──────────────────────────────────────────────────────
INSERT INTO safety_items (ingredient_id, safety_type, title, description, severity_level, evidence_level, frequency_text, applies_to_population, management_advice) VALUES
(433, 'adverse_effect', '갑상선 기능 이상',
 '과량 요오드 섭취 시 갑상선 기능항진증(Jod-Basedow) 또는 갑상선 기능저하증이 모두 유발될 수 있다. 기존 갑상선 질환자에서 더 민감.',
 'serious', 'observational', 'uncommon', '갑상선 질환자',
 '갑상선 질환자는 요오드 보충 전 반드시 내분비내과 상담. 해조류 과다 섭취도 주의.'),

(433, 'adverse_effect', '요오드 유발 갑상선염',
 '고용량 요오드가 자가면역 갑상선염(하시모토)을 촉발하거나 악화시킬 수 있다.',
 'moderate', 'observational', 'uncommon', '자가면역 갑상선질환자',
 '갑상선 항체 양성자는 고용량 요오드 보충 지양.'),

(433, 'drug_interaction', '항갑상선제·리튬 상호작용',
 '요오드가 메티마졸·PTU 등 항갑상선제의 효과를 변동시킬 수 있다. 리튬과 병용 시 갑상선 기능저하 위험 증가.',
 'moderate', 'guideline', 'uncommon', '항갑상선제·리튬 복용자',
 '해당 약물 복용 중 요오드 보충제 사용은 처방의 확인 후.'),

(433, 'precaution', '상한섭취량(UL) 2,400μg/일',
 '한국 2020 영양소 섭취기준 성인 UL 2,400μg/일. 한국인은 해조류 섭취로 평균 요오드 섭취가 높은 편.',
 'mild', 'guideline', NULL, '일반 성인',
 '김·미역·다시마 등 해조류 다량 섭취 시 별도 요오드 보충제 불필요한 경우 많음.');


-- ── 인 (id=1586) ─────────────────────────────────────────────────────────
INSERT INTO safety_items (ingredient_id, safety_type, title, description, severity_level, evidence_level, frequency_text, applies_to_population, management_advice) VALUES
(1586, 'adverse_effect', '고인혈증',
 '신장 기능 저하 시 인 배설이 감소하여 고인혈증이 발생하며 혈관 석회화, 심혈관 합병증 위험이 증가한다.',
 'serious', 'observational', 'common', '만성 신장질환 환자',
 'CKD 3기 이상 환자는 인 섭취 제한 필수. 인 결합제 사용 고려.'),

(1586, 'adverse_effect', '칼슘 흡수 저해',
 '인 과다 섭취(Ca:P 비율 불균형) 시 부갑상선호르몬(PTH) 분비 증가로 골밀도 감소 위험.',
 'moderate', 'observational', 'uncommon', NULL,
 '칼슘:인 비율 1:1~1:2 유지 권장. 가공식품(인산염 첨가물) 과다 섭취 주의.'),

(1586, 'precaution', '상한섭취량(UL) 3,500mg/일',
 '한국 2020 영양소 섭취기준 성인(19~64세) UL 3,500mg/일. 70세 이상은 3,000mg/일.',
 'mild', 'guideline', NULL, '일반 성인',
 '가공식품·탄산음료의 인산염 함량 확인. 보충제보다 식이 인 과다가 더 흔한 문제.');


-- ── 불소 (id=1587) ───────────────────────────────────────────────────────
INSERT INTO safety_items (ingredient_id, safety_type, title, description, severity_level, evidence_level, frequency_text, applies_to_population, management_advice) VALUES
(1587, 'adverse_effect', '치아 불소증(dental fluorosis)',
 '영구치 형성기(0~8세) 과량 불소 섭취 시 치아 에나멜에 백색·갈색 반점이 발생한다. 비가역적.',
 'moderate', 'observational', 'uncommon', '8세 이하 소아',
 '소아 불소 보충제는 수돗물 불소 농도 확인 후. 불소 치약 삼킴 주의(완두콩 크기 이하).'),

(1587, 'adverse_effect', '골불소증(skeletal fluorosis)',
 '10mg/일 이상 만성 섭취(10년+) 시 골밀도 이상 증가, 관절 강직, 골절 위험이 높아진다.',
 'serious', 'observational', 'rare', NULL,
 'UL 초과 만성 노출 지양. 고불소 지역 음용수 검사 권장.'),

(1587, 'precaution', '상한섭취량(UL) 10mg/일',
 '한국 2020 영양소 섭취기준 성인 UL 10mg/일. 소아는 체중당 비례 감소.',
 'mild', 'guideline', NULL, '일반 성인',
 '수돗물 불소화 지역 거주 시 추가 보충 불필요. 불소 정제는 의사 처방에 따라.');
