-- ============================================================================
-- 논문 근거 시드 데이터 — 009_seed_evidence.sql
-- Version: 1.0.0
-- 생성일: 2026-03-16
-- 대상: 25종 원료별 메타분석/체계적 문헌고찰 2건씩 (PubMed)
-- 주의: 001_schema.sql + 003_seed_data.sql + 005_seed_supplementary.sql 이후 실행
-- ============================================================================

-- ============================================================================
-- SECTION 1: evidence_studies (논문 메타데이터)
-- ============================================================================

-- ── vitamin-d ──
INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='vitamin-d'),
  'pubmed', 'Association between vitamin D supplementation and mortality: systematic review and meta-analysis.', 'OBJECTIVE: To investigate whether vitamin D supplementation is associated with lower mortality in adults. DESIGN: Systematic review and meta-analysis of randomised controlled trials. DATA SOURCES: Medline, Embase, and the Cochrane Central Register from their inception to 26 December 2018. ELIGIBILITY CRITERIA FOR SELECTING STUDIES: Randomised controlled trials comparing vitamin D supplementation with a placebo or no treatment for mortality were included. Independent data extraction was conducted and study quality assessed. A meta-analysis was carried out by using fixed effects and random effects models to calculate risk ratio of death in the group receiving vitamin D supplementation and the control group. MAIN OUTCOME MEASURES: All cause mortality. RESULTS: 52 trials with a total of 75 454 participants were identified. Vitamin D supplementation was not associated with all cause mortality (risk ratio 0.98, 95% confidence interval 0.95 to 1.02, I2=0%), cardiovascular mortality (0.98, 0.88 to 1.08, 0%), or non-cancer, non-cardiovascular mortality (1.05, 0.93 to 1.18, 0%). Vitamin D supplementation statistically significantly reduced the risk of cancer death (0.84, 0.74 to 0.95, 0%). In subgroup analyses, all cause mortality was significantly lower in trials with vitamin D3 supplementation than in trials with vitamin D2 supplementation (P for interaction=0.04); neither vitamin D3 nor vitamin D2 was associated with a statistically significant reduction in all cause mortality. CONCLUSIONS: Vitamin D supplementation alone was not associated with all cause mortality in adults compared with placebo or no treatment. Vitamin D supplementation reduced the risk of cancer death by 16%. Additional large clinical studies are needed to determine whether vitamin D3 supplementation is associated with lower all cause mortality. STUDY REGISTRATION: PROSPERO registration number CRD42018117823.', 'Zhang Yu, Fang Fang, Tang Jingjing, Jia Lu, Feng Yuning et al.', 'BMJ (Clinical research ed.)',
  2019, '31405892', '10.1136/bmj.l4673', 'https://pubmed.ncbi.nlm.nih.gov/31405892/', 'meta_analysis',
  'included', true
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='vitamin-d'),
  'pubmed', 'Vitamin D and Risk for Type 2 Diabetes in People With Prediabetes : A Systematic Review and Meta-analysis of Individual Participant Data From 3 Randomized Clinical Trials.', 'BACKGROUND: The role of vitamin D in people who are at risk for type 2 diabetes remains unclear. PURPOSE: To evaluate whether administration of vitamin D decreases risk for diabetes among people with prediabetes. DATA SOURCES: PubMed, Embase, and ClinicalTrials.gov from database inception through 9 December 2022. STUDY SELECTION: Eligible trials that were specifically designed and conducted to test the effects of oral vitamin D versus placebo on new-onset diabetes in adults with prediabetes. DATA EXTRACTION: The primary outcome was time to event for new-onset diabetes. Secondary outcomes were regression to normal glucose regulation and adverse events. Prespecified analyses (both unadjusted and adjusted for key baseline variables) were conducted according to the intention-to-treat principle. DATA SYNTHESIS: Three randomized trials were included, which tested cholecalciferol, 20 000 IU (500 mcg) weekly; cholecalciferol, 4000 IU (100 mcg) daily; or eldecalcitol, 0.75 mcg daily, versus matching placebos. Trials were at low risk of bias. Vitamin D reduced risk for diabetes by 15% (hazard ratio, 0.85 [95% CI, 0.75 to 0.96]) in adjusted analyses, with a 3-year absolute risk reduction of 3.3% (CI, 0.6% to 6.0%). The effect of vitamin D did not differ in prespecified subgroups. Among participants assigned to the vitamin D group who maintained an intratrial mean serum 25-hydroxyvitamin D level of at least 125 nmol/L (≥50 ng/mL) compared with 50 to 74 nmol/L (20 to 29 ng/mL) during follow-up, cholecalciferol reduced risk for diabetes by 76% (hazard ratio, 0.24 [CI, 0.16 to 0.36]), with a 3-year absolute risk reduction of 18.1% (CI, 11.7% to 24.6%). Vitamin D increased the likelihood of regression to normal glucose regulation by 30% (rate ratio, 1.30 [CI, 1.16 to 1.46]). There was no evidence of difference in the rate ratios for adverse events (kidney stones: 1.17 [CI, 0.69 to 1.99]; hypercalcemia: 2.34 [CI, 0.83 to 6.66]; hypercalciuria: 1.65 [CI, 0.83 to 3.28]; death: 0.85 [CI, 0.31 to 2.36]). LIMITATIONS: Studies of people with prediabetes do not apply to the general population. Trials may not have been powered for safety outcomes. CONCLUSION: In adults with prediabetes, vitamin D was effective in decreasing risk for diabetes. PRIMARY FUNDING SOURCE: None. (PROSPERO: CRD42020163522).', 'Pittas Anastassios G, Kawahara Tetsuya, Jorde Rolf, Dawson-Hughes Bess, Vickery Ellen M et al.', 'Annals of internal medicine',
  2023, '36745886', '10.7326/M22-3018', 'https://pubmed.ncbi.nlm.nih.gov/36745886/', 'meta_analysis',
  'included', true
)
ON CONFLICT DO NOTHING;

-- ── vitamin-c ──
INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='vitamin-c'),
  'pubmed', 'Effect of Vitamin C Supplements on Respiratory Tract Infections: A Systematic Review and Meta-Analysis.', 'BACKGROUND: Respiratory tract infections are a primary cause of illness and mortality over the world. OBJECTIVE: This study was aimed to investigate the effectiveness of vitamin C supplementation in preventing and treating respiratory tract infections. METHODS: We used the Cochrane, PubMed, and MEDLINE Ovid databases to conduct our search. The inclusion criteria were placebo-controlled trials. Random effects meta-analyses were performed to measure the pooled effects of vitamin C supplementation on the incidence, severity, and duration of respiratory illness. RESULTS: We found ten studies that met our inclusion criteria out of a total of 2758. The pooled risk ratio (RR) of developing respiratory illness when taking vitamin C regularly across the study period was 0.94 (with a 95% confidence interval of 0.87 to 1.01) which found that supplementing with vitamin C lowers the occurrence of illness. This effect, however, was statistically insignificant (P= 0.09). This study showed that vitamin C supplementation had no consistent effect on the severity of respiratory illness (SMD 0.14, 95% CI -0.02 to 0.30: I2 = 22%, P=0.09). However, our study revealed that vitamin C group had a considerably shorter duration of respiratory infection (SMD -0.36, 95% CI -0.62 to -0.09, P = 0.01). CONCLUSION: Benefits of normal vitamin C supplementation for reducing the duration of respiratory tract illness were supported by our meta-analysis findings. Since few trials have examined the effects of therapeutic supplementation, further research is needed in this area.', 'Keya Tahmina Afrose, Leela Anthony, Fernandez Kevin, Habib Nasrin, Rashid Mumunur', 'Current reviews in clinical and experimental pharmacology',
  2022, '34967304', '10.2174/2772432817666211230100723', 'https://pubmed.ncbi.nlm.nih.gov/34967304/', 'meta_analysis',
  'included', true
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='vitamin-c'),
  'pubmed', 'Therapeutic effects of high-dose vitamin C supplementation in patients with COVID-19: a meta-analysis.', 'CONTEXT: Coronavirus disease 2019 (COVID-19) could induce the "cytokine storm" due to overactivation of immune system and accompanied by acute respiratory distress syndrome as a serious complication. Vitamin C has been effective in improving lung function of patients by reducing inflammation. OBJECTIVE: The aim was to explore the therapeutic effects of high-dose vitamin C supplementation for patients with COVID-19 using meta-analysis. DATA SOURCES: Published studies were searched from PubMed, Cochrane Library, Web of Science, EMBASE, and China National Knowledge Infrastructure databases up to August 2022 using the terms "vitamin C" and "COVID-19". Data analyses were performed independently by 2 researchers using the PRISMA guidelines. DATA EXTRACTION: Heterogeneity between the included studies was assessed using I2 statistics. When I2 ≥50%, the random-effects model was used; otherwise, a fixed-effects model was applied. Stata 14.0 software was used to pool data by standardized mean differences (SMDs) with 95% CIs or odds ratios (ORs) with 95% CIs. DATA ANALYSIS: The 14 studies had a total of 751 patients and 1583 control participants in 7 randomized controlled trials and 7 retrospective studies. The vitamin C supplement significantly increased ferritin (SMD = 0.272; 95% CI: 0.059 to 0.485; P = 0.012) and lymphocyte count levels (SMD = 0.376; 95% CI: 0.153 to 0.599; P = 0.001) in patients with COVID-19. Patients administered vitamin C in the length of intensive care unit staying (SMD = 0.226; 95% CI: 0.073 to 0.379; P = 0.004). Intake of vitamin C prominently alleviate disease aggravation (OR = 0.344, 95%CI: 0.135 to 0.873, P = 0.025). CONCLUSIONS: High-dose vitamin C supplementation can alleviate inflammatory response and hinder the aggravation of COVID-19.', 'Sun Lei, Zhao Jia-Hao, Fan Wen-Yi, Feng Bo, Liu Wen-Wen et al.', 'Nutrition reviews',
  2024, '37682265', '10.1093/nutrit/nuad105', 'https://pubmed.ncbi.nlm.nih.gov/37682265/', 'meta_analysis',
  'included', true
)
ON CONFLICT DO NOTHING;

-- ── vitamin-b12 ──
INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='vitamin-b12'),
  'pubmed', 'Effects of Vitamin B12 Supplementation on Cognitive Function, Depressive Symptoms, and Fatigue: A Systematic Review, Meta-Analysis, and Meta-Regression.', 'Vitamin B12 is often used to improve cognitive function, depressive symptoms, and fatigue. In most cases, such complaints are not associated with overt vitamin B12 deficiency or advanced neurological disorders and the effectiveness of vitamin B12 supplementation in such cases is uncertain. The aim of this systematic review and meta-analysis of randomized controlled trials (RCTs) is to assess the effects of vitamin B12 alone (B12 alone), in addition to vitamin B12 and folic acid with or without vitamin B6 (B complex) on cognitive function, depressive symptoms, and idiopathic fatigue in patients without advanced neurological disorders or overt vitamin B12 deficiency. Medline, Embase, PsycInfo, Cochrane Library, and Scopus were searched. A total of 16 RCTs with 6276 participants were included. Regarding cognitive function outcomes, we found no evidence for an effect of B12 alone or B complex supplementation on any subdomain of cognitive function outcomes. Further, meta-regression showed no significant associations of treatment effects with any of the potential predictors. We also found no overall effect of vitamin supplementation on measures of depression. Further, only one study reported effects on idiopathic fatigue, and therefore, no analysis was possible. Vitamin B12 supplementation is likely ineffective for improving cognitive function and depressive symptoms in patients without advanced neurological disorders.', 'Markun Stefan, Gravestock Isaac, Jäger Levy, Rosemann Thomas, Pichierri Giuseppe et al.', 'Nutrients',
  2021, '33809274', '10.3390/nu13030923', 'https://pubmed.ncbi.nlm.nih.gov/33809274/', 'meta_analysis',
  'included', true
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='vitamin-b12'),
  'pubmed', 'B vitamins and prevention of cognitive decline and incident dementia: a systematic review and meta-analysis.', 'CONTEXT: Elevation of homocysteine (Hcy) levels is well-established as a risk factor for dementia, yet controversy exists regarding whether B-vitamin-mediated reduction of homocysteine levels can benefit cognitive function. OBJECTIVE: To investigate whether B vitamin supplementation can reduce the risk of cognitive decline and incident dementia. DATA SOURCES: The PubMed, EMBASE, Cochrane Library, and Web of Science were systematically searched for articles published from the inception dates to March 1, 2020. Randomized controlled trials (RCT) were included if B vitamins were supplied to investigate their effect on the rate of cognitive decline. Cohort studies investigating dietary intake of B vitamins and the risk of incident dementia were eligible. Cross-sectional studies comparing differences in levels of B vitamins and Hcy were included. DATA EXTRACTION: Two reviewers independently performed data extraction and assessed the study quality. DATA ANALYSIS: Random-effect or fixed-effect models, depending on the degree of heterogeneity, were performed to calculate mean differences (MDs), hazard ratios (HRs), and odds ratios (ORs). RESULTS: A total of 95 studies with 46175 participants (25 RCTs, 20 cohort studies, and 50 cross-sectional studies) were included in this meta-analysis. This meta-analysis supports that B vitamins can benefit cognitive function as measured by Mini-Mental State Examination score changes (6155 participants; MD, 0.14, 95%CI 0.04 to 0.23), and this result was also significant in studies where placebo groups developed cognitive decline (4211 participants; MD, 0.16, 95%CI 0.05 to 0.26), suggesting that B vitamins slow cognitive decline. For the > 12 months interventional period stratum, B vitamin supplementation decreased cognitive decline (3814 participants; MD, 0.15, 95%CI 0.05 to 0.26) compared to placebo; no such outcome was detected for the shorter interventional stratum (806 participants; MD, 0.18, 95%CI -0.25 to 0.61). In the non-dementia population, B vitamin supplementation slowed cognitive decline (3431 participants; MD, 0.15, 95%CI 0.04 to 0.25) compared to placebo; this outcome was not found for the dementia population (642 participants; MD, 0.20, 95%CI -0.35 to 0.75). Lower folate levels (but not B12 or B6 deficiency) and higher Hcy levels were significantly associated with higher risks of dementia (folate: 6654 participants; OR, 1.76, 95%CI 1.24 to 2.50; Hcy: 12665 participants; OR, 2.09, 95%CI 1.60 to 2.74) and cognitive decline (folate: 4336 participants; OR, 1.26, 95%CI 1.02 to 1.55; Hcy: 6149 participants; OR, 1.19, 95%CI 1.05 to 1.34). Among the population without dementia aged 50 years and above, the risk of incident dementia was significantly decreased among individuals with higher intake of folate (13529 participants; HR, 0.61, 95%CI 0.47 to 0.78), whereas higher intake of B12 or B6 was not associated with lower dementia risk. CONCLUSIONS: This meta-analysis suggests that B vitamin supplementation is assoc', 'Wang Zhibin, Zhu Wei, Xing Yi, Jia Jianping, Tang Yi', 'Nutrition reviews',
  2022, '34432056', '10.1093/nutrit/nuab057', 'https://pubmed.ncbi.nlm.nih.gov/34432056/', 'meta_analysis',
  'included', true
)
ON CONFLICT DO NOTHING;

-- ── folate ──
INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='folate'),
  'pubmed', 'Folic acid supplementation and malaria susceptibility and severity among people taking antifolate antimalarial drugs in endemic areas.', 'BACKGROUND: Description of the condition Malaria, an infectious disease transmitted by the bite of female mosquitoes from several Anopheles species, occurs in 87 countries with ongoing transmission (WHO 2020). The World Health Organization (WHO) estimated that, in 2019, approximately 229 million cases of malaria occurred worldwide, with 94% occurring in the WHO''s African region (WHO 2020). Of these malaria cases, an estimated 409,000 deaths occurred globally, with 67% occurring in children under five years of age (WHO 2020). Malaria also negatively impacts the health of women during pregnancy, childbirth, and the postnatal period (WHO 2020). Sulfadoxine/pyrimethamine (SP), an antifolate antimalarial, has been widely used across sub-Saharan Africa as the first-line treatment for uncomplicated malaria since it was first introduced in Malawi in 1993 (Filler 2006). Due to increasing resistance to SP, in 2000 the WHO recommended that one of several artemisinin-based combination therapies (ACTs) be used instead of SP for the treatment of uncomplicated malaria caused by Plasmodium falciparum (Global Partnership to Roll Back Malaria 2001). However, despite these recommendations, SP continues to be advised for intermittent preventive treatment in pregnancy (IPTp) and intermittent preventive treatment in infants (IPTi), whether the person has malaria or not (WHO 2013). Description of the intervention Folate (vitamin B9) includes both naturally occurring folates and folic acid, the fully oxidized monoglutamic form of the vitamin, used in dietary supplements and fortified food. Folate deficiency (e.g. red blood cell (RBC) folate concentrations of less than 305 nanomoles per litre (nmol/L); serum or plasma concentrations of less than 7 nmol/L) is common in many parts of the world and often presents as megaloblastic anaemia, resulting from inadequate intake, increased requirements, reduced absorption, or abnormal metabolism of folate (Bailey 2015; WHO 2015a). Pregnant women have greater folate requirements; inadequate folate intake (evidenced by RBC folate concentrations of less than 400 nanograms per millilitre (ng/mL), or 906 nmol/L) prior to and during the first month of pregnancy increases the risk of neural tube defects, preterm delivery, low birthweight, and fetal growth restriction (Bourassa 2019). The WHO recommends that all women who are trying to conceive consume 400 micrograms (µg) of folic acid daily from the time they begin trying to conceive through to 12 weeks of gestation (WHO 2017). In 2015, the WHO added the dosage of 0.4 mg of folic acid to the essential drug list (WHO 2015c). Alongside daily oral iron (30 mg to 60 mg elemental iron), folic acid supplementation is recommended for pregnant women to prevent neural tube defects, maternal anaemia, puerperal sepsis, low birthweight, and preterm birth in settings where anaemia in pregnant women is a severe public health problem (i.e. where at least 40% of pregnant women have a blood haemoglobin (H', 'Crider Krista, Williams Jennifer, Qi Yan Ping, Gutman Julie, Yeung Lorraine et al.', 'The Cochrane database of systematic reviews',
  2022, '36321557', '10.1002/14651858.CD014217', 'https://pubmed.ncbi.nlm.nih.gov/36321557/', 'meta_analysis',
  'included', true
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='folate'),
  'pubmed', 'Daily oral iron supplementation during pregnancy.', 'BACKGROUND: Iron and folic acid supplementation have been recommended in pregnancy for anaemia prevention, and may improve other maternal, pregnancy, and infant outcomes. OBJECTIVES: To examine the effects of daily oral iron supplementation during pregnancy, either alone or in combination with folic acid or with other vitamins and minerals, as an intervention in antenatal care. SEARCH METHODS: We searched the Cochrane Pregnancy and Childbirth Trials Registry on 18 January 2024 (including CENTRAL, MEDLINE, Embase, CINAHL, ClinicalTrials.gov, WHO''s International Clinical Trials Registry Platform, conference proceedings), and searched reference lists of retrieved studies. SELECTION CRITERIA: Randomised or quasi-randomised trials that evaluated the effects of oral supplementation with daily iron, iron + folic acid, or iron + other vitamins and minerals during pregnancy were included. DATA COLLECTION AND ANALYSIS: Review authors independently assessed trial eligibility, ascertained trustworthiness based on pre-defined criteria, assessed risk of bias, extracted data, and conducted checks for accuracy. We used the GRADE approach to assess the certainty of the evidence for primary outcomes. We anticipated high heterogeneity amongst trials; we pooled trial results using a random-effects model (average treatment effect). MAIN RESULTS: We included 57 trials involving 48,971 women. A total of 40 trials compared the effects of daily oral supplements with iron to placebo or no iron; eight trials evaluated the effects of iron + folic acid compared to placebo or no iron + folic acid. Iron supplementation compared to placebo or no iron Maternal outcomes: Iron supplementation during pregnancy may reduce maternal anaemia (4.0% versus 7.4%; risk ratio (RR) 0.30, 95% confidence interval (CI) 0.20 to 0.47; 14 trials, 13,543 women; low-certainty evidence) and iron deficiency at term (44.0% versus 66.0%; RR 0.51, 95% CI 0.38 to 0.68; 8 trials, 2873 women; low-certainty evidence), and probably reduces maternal iron-deficiency anaemia at term (5.0% versus 18.4%; RR 0.41, 95% CI 0.26 to 0.63; 7 trials, 2704 women; moderate-certainty evidence), compared to placebo or no iron supplementation. There is probably little to no difference in maternal death (2 versus 4 events, RR 0.57, 95% CI 0.12 to 2.69; 3 trials, 14,060 women; moderate-certainty evidence). The evidence is very uncertain for adverse effects (21.6% versus 18.0%; RR 1.29, 95% CI 0.83 to 2.02; 12 trials, 2423 women; very low-certainty evidence) and severe anaemia (Hb < 70 g/L) in the second/third trimester (< 1% versus 3.6%; RR 0.22, 95% CI 0.01 to 3.20; 8 trials, 1398 women; very low-certainty evidence). No trials reported clinical malaria or infection during pregnancy. Infant outcomes: Women taking iron supplements are probably less likely to have infants with low birthweight (5.2% versus 6.1%; RR 0.84, 95% CI 0.72 to 0.99; 12 trials, 18,290 infants; moderate-certainty evidence), compared to placebo or no iron su', 'Finkelstein Julia L, Cuthbert Anna, Weeks Jo, Venkatramanan Sudha, Larvie Doreen Y et al.', 'The Cochrane database of systematic reviews',
  2024, '39145520', '10.1002/14651858.CD004736.pub6', 'https://pubmed.ncbi.nlm.nih.gov/39145520/', 'meta_analysis',
  'included', true
)
ON CONFLICT DO NOTHING;

-- ── omega-3 ──
INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='omega-3'),
  'pubmed', 'The Relationship of Omega-3 Fatty Acids with Dementia and Cognitive Decline: Evidence from Prospective Cohort Studies of Supplementation, Dietary Intake, and Blood Markers.', 'Previous data have linked omega-3 fatty acids with risk of dementia. We aimed to assess the longitudinal relationships of omega-3 polyunsaturated fatty acid intake as well as blood biomarkers with risk of Alzheimer''s disease (AD), dementia, or cognitive decline. Longitudinal data were derived from 1135 participants without dementia (mean age = 73 y) in the Alzheimer''s Disease Neuroimaging Initiative (ADNI) cohort to evaluate the associations of omega-3 fatty acid supplementation and blood biomarkers with incident AD during the 6-y follow-up. A meta-analysis of published cohort studies was further conducted to test the longitudinal relationships of dietary intake of omega-3 and its peripheral markers with all-cause dementia or cognitive decline. Causal dose-response analyses were conducted using the robust error meta-regression model. In the ADNI cohort, long-term users of omega-3 fatty acid supplements exhibited a 64% reduced risk of AD (hazard ratio: 0.36, 95% confidence interval: 0.18, 0.72; P = 0.004). After incorporating 48 longitudinal studies involving 103,651 participants, a moderate-to-high level of evidence suggested that dietary intake of omega-3 fatty acids could lower risk of all-cause dementia or cognitive decline by ∼20%, especially for docosahexaenoic acid (DHA) intake (relative risk [RR]: 0.82, I2 = 63.6%, P = 0.001) and for studies that were adjusted for apolipoprotein APOE ε4 status (RR: 0.83, I2 = 65%, P = 0.006). Each increment of 0.1 g/d of DHA or eicosapentaenoic acid (EPA) intake was associated with an 8% ∼ 9.9% (Plinear < 0.0005) lower risk of cognitive decline. Moderate-to-high levels of evidence indicated that elevated levels of plasma EPA (RR: 0.88, I2 = 38.1%) and erythrocyte membrane DHA (RR: 0.94, I2 = 0.4%) were associated with a lower risk of cognitive decline. Dietary intake or long-term supplementation of omega-3 fatty acids may help reduce risk of AD or cognitive decline.', 'Wei Bao-Zhen, Li Lin, Dong Cheng-Wen, Tan Chen-Chen, Xu Wei', 'The American journal of clinical nutrition',
  2023, '37028557', '10.1016/j.ajcnut.2023.04.001', 'https://pubmed.ncbi.nlm.nih.gov/37028557/', 'meta_analysis',
  'included', true
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='omega-3'),
  'pubmed', 'Omega-3 fatty acids for the primary and secondary prevention of cardiovascular disease.', 'BACKGROUND: Omega-3 polyunsaturated fatty acids from oily fish (long-chain omega-3 (LCn3)), including eicosapentaenoic acid (EPA) and docosahexaenoic acid (DHA)), as well as from plants (alpha-linolenic acid (ALA)) may benefit cardiovascular health. Guidelines recommend increasing omega-3-rich foods, and sometimes supplementation, but recent trials have not confirmed this. OBJECTIVES: To assess the effects of increased intake of fish- and plant-based omega-3 fats for all-cause mortality, cardiovascular events, adiposity and lipids. SEARCH METHODS: We searched CENTRAL, MEDLINE and Embase to February 2019, plus ClinicalTrials.gov and World Health Organization International Clinical Trials Registry to August 2019, with no language restrictions. We handsearched systematic review references and bibliographies and contacted trial authors. SELECTION CRITERIA: We included randomised controlled trials (RCTs) that lasted at least 12 months and compared supplementation or advice to increase LCn3 or ALA intake, or both, versus usual or lower intake. DATA COLLECTION AND ANALYSIS: Two review authors independently assessed trials for inclusion, extracted data and assessed validity. We performed separate random-effects meta-analysis for ALA and LCn3 interventions, and assessed dose-response relationships through meta-regression. MAIN RESULTS: We included 86 RCTs (162,796 participants) in this review update and found that 28 were at low summary risk of bias. Trials were of 12 to 88 months'' duration and included adults at varying cardiovascular risk, mainly in high-income countries. Most trials assessed LCn3 supplementation with capsules, but some used LCn3- or ALA-rich or enriched foods or dietary advice compared to placebo or usual diet. LCn3 doses ranged from 0.5 g a day to more than 5 g a day (19 RCTs gave at least 3 g LCn3 daily). Meta-analysis and sensitivity analyses suggested little or no effect of increasing LCn3 on all-cause mortality (risk ratio (RR) 0.97, 95% confidence interval (CI) 0.93 to 1.01; 143,693 participants; 11,297 deaths in 45 RCTs; high-certainty evidence), cardiovascular mortality (RR 0.92, 95% CI 0.86 to 0.99; 117,837 participants; 5658 deaths in 29 RCTs; moderate-certainty evidence), cardiovascular events (RR 0.96, 95% CI 0.92 to 1.01; 140,482 participants; 17,619 people experienced events in 43 RCTs; high-certainty evidence), stroke (RR 1.02, 95% CI 0.94 to 1.12; 138,888 participants; 2850 strokes in 31 RCTs; moderate-certainty evidence) or arrhythmia (RR 0.99, 95% CI 0.92 to 1.06; 77,990 participants; 4586 people experienced arrhythmia in 30 RCTs; low-certainty evidence). Increasing LCn3 may slightly reduce coronary heart disease mortality (number needed to treat for an additional beneficial outcome (NNTB) 334, RR 0.90, 95% CI 0.81 to 1.00; 127,378 participants; 3598 coronary heart disease deaths in 24 RCTs, low-certainty evidence) and coronary heart disease events (NNTB 167, RR 0.91, 95% CI 0.85 to 0.97; 134,116 participants; 8791 pe', 'Abdelhamid Asmaa S, Brown Tracey J, Brainard Julii S, Biswas Priti, Thorpe Gabrielle C et al.', 'The Cochrane database of systematic reviews',
  2020, '32114706', '10.1002/14651858.CD003177.pub5', 'https://pubmed.ncbi.nlm.nih.gov/32114706/', 'meta_analysis',
  'included', true
)
ON CONFLICT DO NOTHING;

-- ── magnesium ──
INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='magnesium'),
  'pubmed', 'Oral magnesium supplementation for insomnia in older adults: a Systematic Review & Meta-Analysis.', 'BACKGROUND: Magnesium supplementation is often purported to improve sleep; however, as both an over-the-counter sleep aid and a complementary and alternative medicine, there is limited evidence to support this assertion. The aim was to assess the effectiveness and safety of magnesium supplementation for older adults with insomnia. METHODS: A search was conducted in MEDLINE, EMBASE, Allied and Complementary Medicine, clinicaltrials.gov and two grey literature databases comparing magnesium supplementation to placebo or no treatment. Outcomes were sleep quality, quantity, and adverse events. Risk of bias and quality of evidence assessments were carried out using the RoB 2.0 and Grading of Recommendations Assessment, Development and Evaluation (GRADE) approaches. Data was pooled and treatment effects were quantified using mean differences. For remaining outcomes, a modified effects direction plot was used for data synthesis. RESULTS: Three randomized control trials (RCT) were identified comparing oral magnesium to placebo in 151 older adults in three countries. Pooled analysis showed that post-intervention sleep onset latency time was 17.36 min less after magnesium supplementation compared to placebo (95% CI - 27.27 to - 7.44, p = 0.0006). Total sleep time improved by 16.06 min in the magnesium supplementation group but was statistically insignificant. All trials were at moderate-to-high risk of bias and outcomes were supported by low to very low quality of evidence. CONCLUSION: This review confirms that the quality of literature is substandard for physicians to make well-informed recommendations on usage of oral magnesium for older adults with insomnia. However, given that oral magnesium is very cheap and widely available, RCT evidence may support oral magnesium supplements (less than 1 g quantities given up to three times a day) for insomnia symptoms.', 'Mah Jasmine, Pitre Tyler', 'BMC complementary medicine and therapies',
  2021, '33865376', '10.1186/s12906-021-03297-z', 'https://pubmed.ncbi.nlm.nih.gov/33865376/', 'meta_analysis',
  'included', true
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='magnesium'),
  'pubmed', 'The effect of magnesium supplementation on muscle fitness: a meta-analysis and systematic review.', 'Increasing evidence supports a role of magnesium (Mg) in skeletal muscle function. However, no systematic review or meta-analysis has summarized data on Mg supplementation in relation to muscle fitness in humans. Thus, this study aimed to quantitatively assess the effect of Mg supplementation on muscle fitness. A meta-analysis and systematic review. Medline database and other sources were searched for randomized clinical trials through July 2017. Studies that reported results regarding at least one of the following outcomes: leg strength, knee extension strength, peak torque, muscle power, muscle work, jump, handgrip, bench press weights, resistant exercise, lean mass, muscle mass, muscle strength, walking speed, Repeated Chair Stands, and TGUG were included. Measurements of the association were pooled using a fixed-effects model and expressed as weighted mean differences (WMDs) with 95% confidence intervals (95% CIs). Fourteen randomized clinical trials targeting 3 different populations were identified: athletes or physically active individuals (215 participants; mean age: 24.9 years), untrained healthy individuals (95 participants; mean age: 40.2 years), and elderly or alcoholics (232 participants; mean age: 62.7 years). The beneficial effects of Mg supplementation appeared to be more pronounced in the elderly and alcoholics, but were not apparent in athletes and physically active individuals. The results of the meta-analysis suggested that no significant improvements in the supplementation group were observed regarding isokinetic peak torque extension [WMD = 0.87; 95% CI = (-1.43, 3.18)], muscle strength [WMD = 0.87; 95% CI = (-0.12, 1.86)] or muscle power [WMD = 3.28; 95% CI = (-14.94, 21.50)]. Evidence does not support a beneficial effect of Mg supplementation on muscle fitness in most athletes and physically active individuals who have a relatively high Mg status. But Mg supplementation may benefit individuals with Mg deficiency, such as the elderly and alcoholics.', 'Wang Ru, Chen Cheng, Liu Wei, Zhou Tang, Xun Pengcheng et al.', 'Magnesium research',
  2017, '29637897', '10.1684/mrh.2018.0430', 'https://pubmed.ncbi.nlm.nih.gov/29637897/', 'meta_analysis',
  'included', true
)
ON CONFLICT DO NOTHING;

-- ── zinc ──
INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='zinc'),
  'pubmed', 'Clinician guidelines for the treatment of psychiatric disorders with nutraceuticals and phytoceuticals: The World Federation of Societies of Biological Psychiatry (WFSBP) and Canadian Network for Mood and Anxiety Treatments (CANMAT) Taskforce.', 'OBJECTIVES: The therapeutic use of nutrient-based ''nutraceuticals'' and plant-based ''phytoceuticals'' for the treatment of mental disorders is common; however, despite recent research progress, there have not been any updated global clinical guidelines since 2015. To address this, the World Federation of Societies of Biological Psychiatry (WFSBP) and the Canadian Network for Mood and Anxiety Disorders (CANMAT) convened an international taskforce involving 31 leading academics and clinicians from 15 countries, between 2019 and 2021. These guidelines are aimed at providing a definitive evidence-informed approach to assist clinicians in making decisions around the use of such agents for major psychiatric disorders. We also provide detail on safety and tolerability, and clinical advice regarding prescription (e.g. indications, dosage), in addition to consideration for use in specialised populations. METHODS: The methodology was based on the WFSBP guidelines development process. Evidence was assessed based on the WFSBP grading of evidence (and was modified to focus on Grade A level evidence - meta-analysis or two or more RCTs - due to the breadth of data available across all nutraceuticals and phytoceuticals across major psychiatric disorders). The taskforce assessed both the ''level of evidence'' (LoE) (i.e. meta-analyses or RCTs) and the assessment of the direction of the evidence, to determine whether the intervention was ''Recommended'' (+++), ''Provisionally Recommended'' (++), ''Weakly Recommended'' (+), ''Not Currently Recommended'' (+/-), or ''Not Recommended'' (-) for a particular condition. Due to the number of clinical trials now available in the field, we firstly examined the data from our two meta-reviews of meta-analyses (nutraceuticals conducted in 2019, and phytoceuticals in 2020). We then performed a search of additional relevant RCTs and reported on both these data as the primary drivers supporting our clinical recommendations. Lower levels of evidence, including isolated RCTs, open label studies, case studies, preclinical research, and interventions with only traditional or anecdotal use, were not assessed. RESULTS: Amongst nutraceuticals with Grade A evidence, positive directionality and varying levels of support (recommended, provisionally recommended, or weakly recommended) was found for adjunctive omega-3 fatty acids (+++), vitamin D (+), adjunctive probiotics (++), adjunctive zinc (++), methylfolate (+), and adjunctive s-adenosyl methionine (SAMe) (+) in the treatment of unipolar depression. Monotherapy omega-3 (+/-), folic acid (-), vitamin C (-), tryptophan (+/-), creatine (+/-), inositol (-), magnesium (-), and n-acetyl cysteine (NAC) (+/-) and SAMe (+/-) were not supported for this use. In bipolar disorder, omega-3 had weak support for bipolar depression (+), while NAC was not currently recommended (+/-). NAC was weakly recommended (+) in the treatment of OCD-related disorders; however, no other nutraceutical had sufficient evidence in a', 'Sarris Jerome, Ravindran Arun, Yatham Lakshmi N, Marx Wolfgang, Rucklidge Julia J et al.', 'The world journal of biological psychiatry : the official journal of the World Federation of Societies of Biological Psychiatry',
  2022, '35311615', '10.1080/15622975.2021.2013041', 'https://pubmed.ncbi.nlm.nih.gov/35311615/', 'meta_analysis',
  'included', true
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='zinc'),
  'pubmed', 'Efficacy of Zinc Supplementation in the Management of Primary Dysmenorrhea: A Systematic Review and Meta-Analysis.', 'BACKGROUND/OBJECTIVES: Primary dysmenorrhea (PD) is a common condition affecting up to 90% of menstruating women, which often results in significant pain without an underlying pathology. Zinc, recognized for its anti-inflammatory and antioxidant effects through inhibiting prostaglandin production and superoxide dismutase 1 (SOD1) upregulation, alleviates menstrual pain by preventing uterine spasms and enhancing microcirculation in the endometrium, suggesting its potential as an alternative treatment for primary dysmenorrhea. The goal of this systematic review and meta-analysis was to assess the efficacy and safety of zinc supplementation in reducing pain severity among women with PD and to explore the influence of dosage and treatment duration. METHODS: Following the PRISMA 2020 guidelines, we conducted an extensive search across databases such as PubMed, Embase, Cochrane Library, Web of Science, and Google Scholar, up to May 2024. Randomized controlled trials assessing the effects of zinc supplementation on pain severity in women with PD were included. Pain severity was evaluated with established tools, such as the Visual Analog Scale (VAS). Risk of bias was assessed using the Cochrane Risk of Bias 2 (RoB2) tool. Two reviewers independently performed the data extraction, and a random-effects model was used for meta-analysis. Meta-regressions were conducted to examine the influence of zinc dosage and treatment duration on pain reduction. Adverse events were also analyzed. RESULTS: Six RCTs involving 739 participants met the inclusion criteria. Zinc supplementation significantly reduced pain severity compared to placebo (Hedges''s g = -1.541; 95% CI: -2.268 to -0.814; p < 0.001), representing a clinically meaningful reduction in pain. Meta-regression indicated that longer treatment durations (≥8 weeks) were associated with greater pain reduction (p = 0.003). While higher zinc doses provided additional pain relief, the incremental benefit per additional milligram was modest (regression coefficient = -0.02 per mg; p = 0.005). Adverse event rates did not differ significantly between the zinc and placebo groups (odds ratio = 2.54; 95% CI: 0.78 to 8.26; p = 0.122), suggesting good tolerability. CONCLUSIONS: Zinc supplementation is an effective and well-tolerated option for reducing pain severity in women with primary dysmenorrhea. Doses as low as 7 mg/day of elemental zinc are sufficient to achieve significant pain relief, with longer durations (≥8 weeks) enhancing efficacy. The favorable safety profile and ease of use support the consideration of zinc supplementation as a practical approach to managing primary dysmenorrhea.', 'Hsu Ting-Jui, Hsieh Rong-Hong, Huang Chin-Huan, Chen Chih-Shou, Lin Wei-Yu et al.', 'Nutrients',
  2024, '39683510', '10.3390/nu16234116', 'https://pubmed.ncbi.nlm.nih.gov/39683510/', 'meta_analysis',
  'included', true
)
ON CONFLICT DO NOTHING;

-- ── iron ──
INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='iron'),
  'pubmed', 'The effects of oral ferrous bisglycinate supplementation on hemoglobin and ferritin concentrations in adults and children: a systematic review and meta-analysis of randomized controlled trials.', 'CONTEXT: Iron deficiency and anemia have serious consequences, especially for children and pregnant women. Iron salts are commonly provided as oral supplements to prevent and treat iron deficiency, despite poor bioavailability and frequently reported adverse side effects. Ferrous bisglycinate is a novel amino acid iron chelate that is thought to be more bioavailable and associated with fewer gastrointestinal (GI) adverse events as compared with iron salts. OBJECTIVE: A systematic review and meta-analysis of randomized controlled trials (RCTs) was conducted to evaluate the effects of ferrous bisglycinate supplementation compared with other iron supplements on hemoglobin and ferritin concentrations and GI adverse events. DATA SOURCES: A systematic search of electronic databases and grey literature was performed up to July 17, 2020, yielding 17 RCTs that reported hemoglobin or ferritin concentrations following at least 4 weeks'' supplementation of ferrous bisglycinate compared with other iron supplements in any dose or frequency. DATA EXTRACTION: Random-effects meta-analyses were conducted among trials of pregnant women (n = 9) and children (n = 4); pooled estimates were expressed as standardized mean differences (SMDs). Incidence rate ratios (IRRs) were estimated for GI adverse events, using Poisson generalized linear mixed-effects models. The remaining trials in other populations (n = 4; men and nonpregnant women) were qualitatively evaluated. DATA ANALYSIS: Compared with other iron supplements, supplementation with ferrous bisglycinate for 4-20 weeks resulted in higher hemoglobin concentrations in pregnant women (SMD, 0.54 g/dL; 95% confidence interval [CI], 0.15-0.94; P < 0.01) and fewer reported GI adverse events (IRR, 0.36; 95%CI, 0.17-0.76; P < 0.01). We observed a non-significant trend for higher ferritin concentrations in pregnant women supplemented with ferrous bisglycinate. No significant differences in hemoglobin or ferritin concentrations were detected among children. CONCLUSION: Ferrous bisglycinate shows some benefit over other iron supplements in increasing hemoglobin concentration and reducing GI adverse events among pregnant women. More trials are needed to assess the efficacy of ferrous bisglycinate against other iron supplements in other populations. PROSPERO REGISTRATION NO: CRD42020196984.', 'Fischer Jordie A J, Cherian Arlin M, Bone Jeffrey N, Karakochuk Crystal D', 'Nutrition reviews',
  2023, '36728680', '10.1093/nutrit/nuac106', 'https://pubmed.ncbi.nlm.nih.gov/36728680/', 'meta_analysis',
  'included', true
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='iron'),
  'pubmed', 'Optimal dose and duration of iron supplementation for treating iron deficiency anaemia in children and adolescents: A systematic review and meta-analysis.', 'INTRODUCTION: Iron deficiency anaemia (IDA) accounts for nearly two-thirds of all anaemia cases globally. Despite the widespread use of iron supplementation, the optimal dose and duration for treating IDA remain unclear. In this study, we aimed to determine the most effective dose and duration of iron supplementation for improving haemoglobin (Hb) levels in children and adolescents (≤19 years) with IDA. METHODS: A systematic review and meta-analysis were conducted. We searched MEDLINE, Embase, CINAHL, and the Cochrane Library for peer-reviewed studies published between 2013 and 2024. The interventions included iron supplementation with a defined dose and duration of at least 30 days. Comparators were placebo, no treatment, or alternative regimens. The outcome was the change in Hb levels. Eligible studies included IDA cases diagnosed through ferritin level measurements in healthy individuals. Studies involving pregnant women or children with underlying conditions were excluded. A meta-analysis was performed using standardized mean differences to pool effect sizes for Hb improvement with 95% confidence intervals (CIs). Subgroup analyses were performed for different treatment durations (<3 months, 3-6 months, >6 months) and dosage categories (<5 mg/kg/day, 5-10 mg/kg/day, >10 mg/kg/day). A random-effects meta-regression model was used to determine the optimal dose and duration, accounting for known covariates affecting Hb improvement. RESULTS: A total of 28 studies with 8,829 participants from 16 countries were included. The pooled effect size for Hb improvement was 2.01 gm/dL (95% CI: 1.48-2.54, p < 0.001). Iron supplementation for less than 3 months showed the highest significant effect size (2.39 gm/dL, 95% CI: 0.72-4.07), followed by treatments exceeding 6 months (1.93 gm/dL, 95% CI: 0.09-3.77). The lowest effect size was observed in treatments lasting 3-6 months (1.58 gm/dL, 95% CI: 0.93-2.23). Low-dose iron supplementation (<5 mg/kg/day) demonstrated favourable trends in Hb improvement, particularly in individuals with lower baseline Hb levels. Oral ferrous sulphate had a significant effect (2.03 gm/dL, 95% CI: 1.24-2.82), while parenteral ferric Carboxymaltose showed consistent efficacy. CONCLUSION: Low-dose iron supplementation (<5 mg/kg/day) combined with treatment durations of either less than 3 months or more than 6 months, is optimal for improving Hb levels in children and adolescents with IDA. Tailoring treatment based on baseline Hb levels and anaemia severity is essential. These findings provide evidence to support updated guidelines on iron supplementation in paediatric and adolescent populations and inform national anaemia management programmes. TRIAL REGISTRATION: Prospero registration number: This study was registered with PROSPERO (CRD42024541773).', 'Rehman Tanveer, Agrawal Ritik, Ahamed Farhad, Das Saibal, Mitra Srijeeta et al.', 'PloS one',
  2025, '39951396', '10.1371/journal.pone.0319068', 'https://pubmed.ncbi.nlm.nih.gov/39951396/', 'meta_analysis',
  'included', true
)
ON CONFLICT DO NOTHING;

-- ── calcium ──
INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='calcium'),
  'pubmed', 'Effects of combined calcium and vitamin D supplementation on osteoporosis in postmenopausal women: a systematic review and meta-analysis of randomized controlled trials.', 'OBJECTIVE: The aim of the present study was to explore whether combined calcium and vitamin D supplementation is beneficial for osteoporosis in postmenopausal women. METHODS: We searched the PubMed, Cochrane library, Web of science and Embase databases and reference lists of eligible articles up to Feb, 2020. Randomized controlled trials (RCTs) evaluating the effect of combined calcium and vitamin D on osteoporosis in postmenopausal women were included in the present study. RESULTS: Combined calcium and vitamin D significantly increased total bone mineral density (BMD) (standard mean differences (SMD) = 0.537; 95% confidence interval (CI): 0.227 to 0.847), lumbar spine BMD (SMD = 0.233; 95% CI: 0.073 to 0.392; P < 0.001), arms BMD (SMD = 0.464; 95% CI: 0.186 to 0.741) and femoral neck BMD (SMD = 0.187; 95% CI: 0.010 to 0.364). It also significantly reduced the incidence of hip fracture (RR = 0.864; 95% CI: 0.763 to 0.979). Subgroup analysis showed that combined calcium and vitamin D significantly increased femoral neck BMD only when the dose of the vitamin D intake was no more than 400 IU d-1 (SMD = 0.335; 95% CI: 0.113 to 0.558), but not for a dose more than 400 IU d-1 (SMD = -0.098; 95% CI: -0.109 to 0.305), and calcium had no effect on the femoral neck BMD. Subgroup analysis also showed only dairy products fortified with calcium and vitamin D had a significant influence on total BMD (SMD = 0.784; 95% CI: 0.322 to 1.247) and lumbar spine BMD (SMD = 0.320; 95% CI: 0.146 to 0.494), but not for combined calcium and vitamin D supplement. CONCLUSION: Dairy products fortified with calcium and vitamin D have a favorable effect on bone mineral density. Combined calcium and vitamin D supplementation could prevent osteoporosis hip fracture in postmenopausal women.', 'Liu Chunxiao, Kuang Xiaotong, Li Kelei, Guo Xiaofei, Deng Qingxue et al.', 'Food & function',
  2020, '33237064', '10.1039/d0fo00787k', 'https://pubmed.ncbi.nlm.nih.gov/33237064/', 'meta_analysis',
  'included', true
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='calcium'),
  'pubmed', 'Calcium plus vitamin D supplementation and risk of fractures: an updated meta-analysis from the National Osteoporosis Foundation.', 'UNLABELLED: The aim was to meta-analyze randomized controlled trials of calcium plus vitamin D supplementation and fracture prevention. Meta-analysis showed a significant 15 % reduced risk of total fractures (summary relative risk estimate [SRRE], 0.85; 95 % confidence interval [CI], 0.73-0.98) and a 30 % reduced risk of hip fractures (SRRE, 0.70; 95 % CI, 0.56-0.87). INTRODUCTION: Calcium plus vitamin D supplementation has been widely recommended to prevent osteoporosis and subsequent fractures; however, considerable controversy exists regarding the association of such supplementation and fracture risk. The aim was to conduct a meta-analysis of randomized controlled trials [RCTs] of calcium plus vitamin D supplementation and fracture prevention in adults. METHODS: A PubMed literature search was conducted for the period from July 1, 2011 through July 31, 2015. RCTs reporting the effect of calcium plus vitamin D supplementation on fracture incidence were selected from English-language studies. Qualitative and quantitative information was extracted; random-effects meta-analyses were conducted to generate summary relative risk estimates (SRREs) for total and hip fractures. Statistical heterogeneity was assessed using Cochran''s Q test and the I (2) statistic, and potential for publication bias was assessed. RESULTS: Of the citations retrieved, eight studies including 30,970 participants met criteria for inclusion in the primary analysis, reporting 195 hip fractures and 2231 total fractures. Meta-analysis of all studies showed that calcium plus vitamin D supplementation produced a statistically significant 15 % reduced risk of total fractures (SRRE, 0.85; 95 % confidence interval [CI], 0.73-0.98) and a 30 % reduced risk of hip fractures (SRRE, 0.70; 95 % CI, 0.56-0.87). Numerous sensitivity and subgroup analyses produced similar summary associations. A limitation is that this study utilized data from subgroup analysis of the Women''s Health Initiative. CONCLUSIONS: This meta-analysis of RCTs supports the use of calcium plus vitamin D supplements as an intervention for fracture risk reduction in both community-dwelling and institutionalized middle-aged to older adults.', 'Weaver C M, Alexander D D, Boushey C J, Dawson-Hughes B, Lappe J M et al.', 'Osteoporosis international : a journal established as result of cooperation between the European Foundation for Osteoporosis and the National Osteoporosis Foundation of the USA',
  2016, '26510847', '10.1007/s00198-015-3386-5', 'https://pubmed.ncbi.nlm.nih.gov/26510847/', 'meta_analysis',
  'included', true
)
ON CONFLICT DO NOTHING;

-- ── probiotics ──
INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='probiotics'),
  'pubmed', 'Prebiotics and probiotics for depression and anxiety: A systematic review and meta-analysis of controlled clinical trials.', 'With growing interest in the gut microbiome, prebiotics and probiotics have received considerable attention as potential treatments for depression and anxiety. We conducted a random-effects meta-analysis of 34 controlled clinical trials evaluating the effects of prebiotics and probiotics on depression and anxiety. Prebiotics did not differ from placebo for depression (d = -.08, p = .51) or anxiety (d = .12, p = .11). Probiotics yielded small but significant effects for depression (d = -.24, p < .01) and anxiety (d = -.10, p = .03). Sample type was a moderator for probiotics and depression, with a larger effect observed for clinical/medical samples (d = -.45, p < .001) than community ones. This effect increased to medium-to-large in a preliminary analysis restricted to psychiatric samples (d = -.73, p < .001). There is general support for antidepressant and anxiolytic effects of probiotics, but the pooled effects were reduced by the paucity of trials with clinical samples. Additional randomized clinical trials with psychiatric samples are necessary fully to evaluate their therapeutic potential.', 'Liu Richard T, Walsh Rachel F L, Sheehan Ana E', 'Neuroscience and biobehavioral reviews',
  2019, '31004628', '10.1016/j.neubiorev.2019.03.023', 'https://pubmed.ncbi.nlm.nih.gov/31004628/', 'meta_analysis',
  'included', true
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='probiotics'),
  'pubmed', 'Probiotics fortify intestinal barrier function: a systematic review and meta-analysis of randomized trials.', 'BACKGROUND: Probiotics play a vital role in treating immune and inflammatory diseases by improving intestinal barrier function; however, a comprehensive evaluation is missing. The present study aimed to explore the impact of probiotics on the intestinal barrier and related immune function, inflammation, and microbiota composition. A systematic review and meta-analyses were conducted. METHODS: Four major databases (PubMed, Science Citation Index Expanded, CENTRAL, and Embase) were thoroughly searched. Weighted mean differences were calculated for continuous outcomes with corresponding 95% confidence intervals (CIs), heterogeneity among studies was evaluated utilizing I2 statistic (Chi-Square test), and data were pooled using random effects meta-analyses. RESULTS: Meta-analysis of data from a total of 26 RCTs (n = 1891) indicated that probiotics significantly improved gut barrier function measured by levels of TER (MD, 5.27, 95% CI, 3.82 to 6.72, P < 0.00001), serum zonulin (SMD, -1.58, 95% CI, -2.49 to -0.66, P = 0.0007), endotoxin (SMD, -3.20, 95% CI, -5.41 to -0.98, P = 0.005), and LPS (SMD, -0.47, 95% CI, -0.85 to -0.09, P = 0.02). Furthermore, probiotic groups demonstrated better efficacy over control groups in reducing inflammatory factors, including CRP, TNF-α, and IL-6. Probiotics can also modulate the gut microbiota structure by boosting the enrichment of Bifidobacterium and Lactobacillus. CONCLUSION: The present work revealed that probiotics could improve intestinal barrier function, and alleviate inflammation and microbial dysbiosis. Further high-quality RCTs are warranted to achieve a more definitive conclusion. CLINICAL TRIAL REGISTRATION: https://www.crd.york.ac.uk/PROSPERO/display_record.php?RecordID=281822, identifier CRD42021281822.', 'Zheng Yanfei, Zhang Zengliang, Tang Ping, Wu Yuqi, Zhang Anqi et al.', 'Frontiers in immunology',
  2023, '37168869', '10.3389/fimmu.2023.1143548', 'https://pubmed.ncbi.nlm.nih.gov/37168869/', 'meta_analysis',
  'included', true
)
ON CONFLICT DO NOTHING;

-- ── lutein ──
INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='lutein'),
  'pubmed', 'Antioxidant vitamin and mineral supplements for slowing the progression of age-related macular degeneration.', 'BACKGROUND: Age-related macular degeneration (AMD) is a degenerative condition of the back of the eye that occurs in people over the age of 50 years. Antioxidants may prevent cellular damage in the retina by reacting with free radicals that are produced in the process of light absorption. Higher dietary levels of antioxidant vitamins and minerals may reduce the risk of progression of AMD. This is the third update of the review. OBJECTIVES: To assess the effects of antioxidant vitamin and mineral supplements on the progression of AMD in people with AMD. SEARCH METHODS: We searched CENTRAL, MEDLINE, Embase, one other database, and three trials registers, most recently on 29 November 2022. SELECTION CRITERIA: We included randomised controlled trials (RCTs) that compared antioxidant vitamin or mineral supplementation to placebo or no intervention, in people with AMD. DATA COLLECTION AND ANALYSIS: We used standard methods expected by Cochrane. MAIN RESULTS: We included 26 studies conducted in the USA, Europe, China, and Australia. These studies enroled 11,952 people aged 65 to 75 years and included slightly more women (on average 56% women). We judged the studies that contributed data to the review to be at low or unclear risk of bias. Thirteen studies compared multivitamins with control in people with early and intermediate AMD. Most evidence came from the Age-Related Eye Disease Study (AREDS) in the USA. People taking antioxidant vitamins were less likely to progress to late AMD (odds ratio (OR) 0.72, 95% confidence interval (CI) 0.58 to 0.90; 3 studies, 2445 participants; moderate-certainty evidence). In people with early AMD, who are at low risk of progression, this means there would be approximately four fewer cases of progression to late AMD for every 1000 people taking vitamins (one fewer to six fewer cases). In people with intermediate AMD at higher risk of progression, this corresponds to approximately 78 fewer cases of progression for every 1000 people taking vitamins (26 fewer to 126 fewer). AREDS also provided evidence of a lower risk of progression for both neovascular AMD (OR 0.62, 95% CI 0.47 to 0.82; moderate-certainty evidence) and geographic atrophy (OR 0.75, 95% CI 0.51 to 1.10; moderate-certainty evidence), and a lower risk of losing 3 or more lines of visual acuity (OR 0.77, 95% CI 0.62 to 0.96; moderate-certainty evidence). Low-certainty evidence from one study of 110 people suggested higher quality of life scores (measured with the Visual Function Questionnaire) in treated compared with non-treated people after 24 months (mean difference (MD) 12.30, 95% CI 4.24 to 20.36). In exploratory subgroup analyses in the follow-on study to AREDS (AREDS2), replacing beta-carotene with lutein/zeaxanthin gave hazard ratios (HR) of 0.82 (95% CI 0.69 to 0.96), 0.78 (95% CI 0.64 to 0.94), 0.94 (95% CI 0.70 to 1.26), and 0.88 (95% CI 0.75 to 1.03) for progression to late AMD, neovascular AMD, geographic atrophy, and vision loss, respectively. Si', 'Evans Jennifer R, Lawrenson John G', 'The Cochrane database of systematic reviews',
  2023, '37702300', '10.1002/14651858.CD000254.pub5', 'https://pubmed.ncbi.nlm.nih.gov/37702300/', 'systematic_review',
  'included', true
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='lutein'),
  'pubmed', 'Carotenoids supplementation and inflammation: a systematic review and meta-analysis of randomized clinical trials.', 'The aim of this study was to perform a systematic review and meta-analysis on randomized controlled trials investigating the effects of carotenoids on selected inflammatory parameters. PubMed, SCOPUS, and Web of science were searched from inception until April 2021. The random-effect model was used to analyze data and the overall effect size was computed as weighted mean difference (WMD) and corresponding 95% of confidence interval (CI). A total of 26 trials with 35 effect sizes were included in this meta-analysis. The results indicated significant effects of carotenoids on C-reactive protein (CRP) (WMD: ‒0.54 mg/L, 95% CI: ‒0.71, ‒0.37, P < 0.001), and interleukin-6 (IL-6) (WMD: ‒0.54 pg/mL, 95% CI: ‒1.01, ‒0.06, P = 0.025), however the effect on tumor necrosis factor-alpha (TNF-α) was not significant (WMD: ‒0.97 pg/ml, 95% CI: ‒1.98, 0.03, P = 0.0.059). For the individual carotenoids, astaxanthin, (WMD: ‒0.30 mg/L, 95% CI: ‒0.51, ‒0.09, P = 0.005), lutein/zeaxanthin (WMD: ‒0.30 mg/L, 95% CI: ‒0.45, ‒0.15, P < 0.001), and β-cryptoxanthin (WMD: ‒0.35 mg/L, 95% CI: ‒0.54, ‒0.15, P < 0.001) significantly decreased CRP level. Also, only lycopene (WMD: ‒1.08 pg/ml, 95%CI: ‒2.03, ‒0.12, P = 0.027) led to a significant decrease in IL-6. The overall results supported possible protective effects of carotenoids on inflammatory biomarkers.', 'Hajizadeh-Sharafabad Fatemeh, Zahabi Elham Sharifi, Malekahmadi Mahsa, Zarrin Rasoul, Alizadeh Mohammad', 'Critical reviews in food science and nutrition',
  2022, '33998846', '10.1080/10408398.2021.1925870', 'https://pubmed.ncbi.nlm.nih.gov/33998846/', 'meta_analysis',
  'included', true
)
ON CONFLICT DO NOTHING;

-- ── coq10 ──
INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='coq10'),
  'pubmed', 'Antioxidants and Fertility in Women with Ovarian Aging: A Systematic Review and Meta-Analysis.', 'Ovarian aging is a major factor for female subfertility. Multiple antioxidants have been applied in different clinical scenarios, but their effects on fertility in women with ovarian aging are still unclear. To address this, a meta-analysis was performed to evaluate the effectiveness and safety of antioxidants on fertility in women with ovarian aging. A total of 20 randomized clinical trials with 2617 participants were included. The results showed that use of antioxidants not only significantly increased the number of retrieved oocytes and high-quality embryo rates but also reduced the dose of gonadotropin, contributing to higher clinical pregnancy rates. According to the subgroup analysis of different dose settings, better effects were more pronounced with lower doses; in terms of antioxidant types, coenzyme Q10 (CoQ10) tended to be more effective than melatonin, myo-inositol, and vitamins. When compared with placebo or no treatment, CoQ10 showed more advantages, whereas small improvements were observed with other drugs. In addition, based on subgroup analysis of CoQ10, the optimal treatment regimen of CoQ10 for improving pregnancy rate was 30 mg/d for 3 mo before the controlled ovarian stimulation cycle, and women with diminished ovarian reserve clearly benefited from CoQ10 treatment, especially those aged <35 y. Our study suggests that antioxidant consumption is an effective and safe complementary therapy for women with ovarian aging. Appropriate antioxidant treatment should be offered at a low dose according to the patient''s age and ovarian reserve. This study was registered at PROSPERO as CRD42022359529.', 'Shang Yujie, Song Nannan, He Ruohan, Wu Minghua', 'Advances in nutrition (Bethesda, Md.)',
  2024, '39019217', '10.1016/j.advnut.2024.100273', 'https://pubmed.ncbi.nlm.nih.gov/39019217/', 'meta_analysis',
  'included', true
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='coq10'),
  'pubmed', 'Clinical evidence of coenzyme Q10 pretreatment for women with diminished ovarian reserve undergoing IVF/ICSI: a systematic review and meta-analysis.', 'BACKGROUND: To quantitatively evaluate the effect of coenzyme Q10 (CoQ10) pretreatment on outcomes of IVF or ICSI in women with diminished ovarian reserve (DOR) based on the existing randomized controlled trials (RCTs). METHODS: Nine databases were comprehensively searched from database inception to November 01, 2023, to identify eligible RCTs. Reproductive outcomes of interest consisted of three primary outcomes and six secondary outcomes. The sensitivity analysis was adopted to verify the robustness of pooled results. RESULTS: There were six RCTs in total, which collectively involved 1529 participants with DOR receiving infertility treatment with IVF/ICSI. The review of available evidence suggested that CoQ10 pretreatment was significantly correlated with elevated clinical pregnancy rate (OR = 1.84, 95%CI [1.33, 2.53], p = 0.0002), number of optimal embryos (OR = 0.59, 95%CI [0.21, 0.96], p = 0.002), number of oocytes retrieved (MD = 1.30, 95%CI [1.21, 1.40], p < 0.00001), and E2 levels on the day of hCG (SMD = 0.37, 95%CI [0.07, 0.66], p = 0.01), along with a reduction in cycle cancellation rate (OR = 0.60, 95%CI [0.44, 0.83], p = 0.002), miscarriage rate (OR = 0.38, 95%CI [0.15, 0.98], p = 0.05), total days of Gn applied (MD = -0.89, 95%CI [-1.37, -0.41], p = 0.0003), and total dose of Gn used (MD = -330.44, 95%CI [-373.93, -286.96], p < 0.00001). The sensitivity analysis indicated that our pooled results were robust. CONCLUSIONS: These findings suggested that CoQ10 pretreatment is an effective intervention in improving IVF/ICSI outcomes for women with DOR. Still, this meta-analysis included relatively limited sample sizes with poor descriptions of their methodologies. Rigorously conducted trials are needed in the future.', 'Lin Guangyao, Li Xuanling, Jin Yie Stella Lim, Xu Lianwei', 'Annals of medicine',
  2024, '39129455', '10.1080/07853890.2024.2389469', 'https://pubmed.ncbi.nlm.nih.gov/39129455/', 'meta_analysis',
  'included', true
)
ON CONFLICT DO NOTHING;

-- ── milk-thistle ──
INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='milk-thistle'),
  'pubmed', 'Administration of silymarin in NAFLD/NASH: A systematic review and meta-analysis.', 'INTRODUCTION AND OBJECTIVES: Nonalcoholic fatty liver disease (NAFLD) is a chronic liver disease with a high prevalence worldwide and poses serious harm to human health. There is growing evidence suggesting that the administration of specific supplements or nutrients may slow NAFLD progression. Silymarin is a hepatoprotective extract of milk thistle, but its efficacy in NAFLD remains unclear. MATERIALS AND METHODS: Relevant studies were searched in PubMed, Embase, the Cochrane Library, Web of Science, clinicaltrails.gov, and China National Knowledge Infrastructure and were screened according to the eligibility criteria. Data were analyzed using Revman 5.3. Continuous values and dichotomous values were pooled using the standard mean difference (SMD) and odds ratio (OR). Heterogeneity was evaluated using the Cochran''s Q test (I2 statistic). A P<0.05 was considered statistically significant. RESULTS: A total of 26 randomized controlled trials involving 2,375 patients were included in this study. Administration of silymarin significantly reduced the levels of TC (SMD[95%CI]=-0.85[-1.23, -0.47]), TG (SMD[95%CI]=-0.62[-1.14, -0.10]), LDL-C (SMD[95%CI]=-0.81[-1.31, -0.31]), FI (SMD[95%CI]=-0.59[-0.91, -0.28]) and HOMA-IR (SMD[95%CI]=-0.37[-0.77, 0.04]), and increased the level of HDL-C (SMD[95%CI]=0.46[0.03, 0.89]). In addition, silymarin attenuated liver injury as indicated by the decreased levels of ALT (SMD[95%CI]=-12.39[-19.69, -5.08]) and AST (SMD[95% CI]=-10.97[-15.51, -6.43]). The levels of fatty liver index (SMD[95%CI]=-6.64[-10.59, -2.69]) and fatty liver score (SMD[95%CI]=-0.51[-0.69, -0.33]) were also decreased. Liver histology of the intervention group revealed significantly improved hepatic steatosis (OR[95%CI]=3.25[1.80, 5.87]). CONCLUSIONS: Silymarin can regulate energy metabolism, attenuate liver damage, and improve liver histology in NAFLD patients. However, the effects of silymarin will need to be confirmed by further research.', 'Li Shudi, Duan Fei, Li Suling, Lu Baoping', 'Annals of hepatology',
  2024, '38579127', '10.1016/j.aohep.2023.101174', 'https://pubmed.ncbi.nlm.nih.gov/38579127/', 'meta_analysis',
  'included', true
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='milk-thistle'),
  'pubmed', 'Silymarin as Supportive Treatment in Liver Diseases: A Narrative Review.', 'Silymarin, an extract from milk thistle seeds, has been used for centuries to treat hepatic conditions. Preclinical data indicate that silymarin can reduce oxidative stress and consequent cytotoxicity, thereby protecting intact liver cells or cells not yet irreversibly damaged. Eurosil 85® is a proprietary formulation developed to maximize the oral bioavailability of silymarin. Most of the clinical research on silymarin has used this formulation. Silymarin acts as a free radical scavenger and modulates enzymes associated with the development of cellular damage, fibrosis and cirrhosis. These hepatoprotective effects were observed in clinical studies in patients with alcoholic or non-alcoholic fatty liver disease, including patients with cirrhosis. In a pooled analysis of trials in patients with cirrhosis, silymarin treatment was associated with a significant reduction in liver-related deaths. Moreover, in patients with diabetes and alcoholic cirrhosis, silymarin was also able to improve glycemic parameters. Patients with drug-induced liver injuries were also successfully treated with silymarin. Silymarin is generally very well tolerated, with a low incidence of adverse events and no treatment-related serious adverse events or deaths reported in clinical trials. For maximum benefit, treatment with silymarin should be initiated as early as possible in patients with fatty liver disease and other distinct liver disease manifestations such as acute liver failure, when the regenerative potential of the liver is still high and when removal of oxidative stress, the cause of cytotoxicity, can achieve the best results.', 'Gillessen Anton, Schmidt Hartmut H-J', 'Advances in therapy',
  2020, '32065376', '10.1007/s12325-020-01251-y', 'https://pubmed.ncbi.nlm.nih.gov/32065376/', 'systematic_review',
  'included', true
)
ON CONFLICT DO NOTHING;

-- ── glucosamine ──
INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='glucosamine'),
  'pubmed', 'A 2022 Systematic Review and Meta-Analysis of Enriched Therapeutic Diets and Nutraceuticals in Canine and Feline Osteoarthritis.', 'With osteoarthritis being the most common degenerative disease in pet animals, a very broad panel of natural health products is available on the market for its management. The aim of this systematic review and meta-analysis, registered on PROSPERO (CRD42021279368), was to test for the evidence of clinical analgesia efficacy of fortified foods and nutraceuticals administered in dogs and cats affected by osteoarthritis. In four electronic bibliographic databases, 1578 publications were retrieved plus 20 additional publications from internal sources. Fifty-seven articles were included, comprising 72 trials divided into nine different categories of natural health compound. The efficacy assessment, associated to the level of quality of each trial, presented an evident clinical analgesic efficacy for omega-3-enriched diets, omega-3 supplements and cannabidiol (to a lesser degree). Our analyses showed a weak efficacy of collagen and a very marked non-effect of chondroitin-glucosamine nutraceuticals, which leads us to recommend that the latter products should no longer be recommended for pain management in canine and feline osteoarthritis.', 'Barbeau-Grégoire Maude, Otis Colombe, Cournoyer Antoine, Moreau Maxim, Lussier Bertrand et al.', 'International journal of molecular sciences',
  2022, '36142319', '10.3390/ijms231810384', 'https://pubmed.ncbi.nlm.nih.gov/36142319/', 'meta_analysis',
  'included', true
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='glucosamine'),
  'pubmed', 'Efficacy and safety of the combination of glucosamine and chondroitin for knee osteoarthritis: a systematic review and meta-analysis.', 'AIMS: Though glucosamine and chondroitin have become common practices for treating knee osteoarthritis, the clinical value of these two drugs in combination are still questionable. To evaluate the efficacy and safety of the combination of glucosamine (GS) and chondroitin (CS) in knee osteoarthritis (KOA) treatment. METHODS: We searched electronic databases, including PubMed, Embase, Web of Science, SCOPUS, The Cochrane Central Register of Controlled Trials (CENTRAL), OVID, Chinese Clinical Trial Registry (ChiCTR), CBM, CNKI, WanFang and VIP from their inception to August 20, 2020, for literature concerning the combination of glucosamine and chondroitin in knee osteoarthritis treatment. The Cochrane Collaboration''s tool for assessing risk of bias and Jadad scale were used to evaluate the risk of bias and quality of literature. The meta-analysis was performed using Review Manager 5.3 software. RESULTS: Eight randomized controlled trials (RCTs) were included, including 7 studies in English and 1 study in Chinese. While the number of included papers was quite limited, the number of participants was decent, and quality appraisal result is acceptable. The total number of patients was 3793, with 1067 patients receiving a combination of glucosamine and chondroitin and 2726 patients receiving other treatments. The meta-analysis results revealed the following: (1) Regarding the total Western Ontario and McMaster Universities Arthritis Index (WOMAC) score, compared with the placebo group, the combination group showed a statistically significant advantage [MD = - 12.04 (- 22.33 ~ - 1.75); P = 0.02], while the other groups showed no significance. (2) Regarding the VAS score, none of the comparisons showed significance. (3) In the secondary outcomes, except the comparison of JSN between the combination and placebo groups (MD = - 0.09 (- 0.18 ~ - 0.00); P = 0.04) and the comparison of the WOMAC stiffness score between the combination and CS groups [MD = - 4.70 (- 8.57 ~ - 0.83); P = 0.02], none of the comparisons showed a significant difference. (4)Safety analysis results show that none of the comparisons have significant differences. CONCLUSION: Our study confirmed that the combination of glucosamine and chondroitin is effective and superior to other treatments in knee osteoarthritis to a certain extent. It is worthwhile to popularize and apply the combination in KOA treatment considering the point of effect, tolerability and economic costs. Additionally, regarding the limited number of studies and uneven trial quality, more high-quality trials are required to investigate the accurate clinical advantages of the combination. PROSPERO REGISTRATION ID: CRD42020202093.', 'Meng Zhengyuan, Liu Jiakun, Zhou Nan', 'Archives of orthopaedic and trauma surgery',
  2023, '35024906', '10.1007/s00402-021-04326-9', 'https://pubmed.ncbi.nlm.nih.gov/35024906/', 'meta_analysis',
  'included', true
)
ON CONFLICT DO NOTHING;

-- ── biotin ──
INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='biotin'),
  'pubmed', 'PROVIT: Supplementary Probiotic Treatment and Vitamin B7 in Depression-A Randomized Controlled Trial.', 'Gut microbiota are suspected to affect brain functions and behavior as well as lowering inflammation status. Therefore, an effect on depression has already been suggested by recent research. The aim of this randomized double-blind controlled trial was to evaluate the effect of probiotic treatment in depressed individuals. Within inpatient care, 82 currently depressed individuals were randomly assigned to either receive a multistrain probiotic plus biotin treatment or biotin plus placebo for 28 days. Clinical symptoms as well as gut microbiome were analyzed at the begin of the study, after one and after four weeks. After 16S rRNA analysis, microbiome samples were bioinformatically explored using QIIME, SPSS, R and Piphillin. Both groups improved significantly regarding psychiatric symptoms. Ruminococcus gauvreauii and Coprococcus 3 were more abundant and β-diversity was higher in the probiotics group after 28 days. KEGG-analysis showed elevated inflammation-regulatory and metabolic pathways in the intervention group. The elevated abundance of potentially beneficial bacteria after probiotic treatment allows speculations on the functionality of probiotic treatment in depressed individuals. Furthermore, the finding of upregulated vitamin B6 and B7 synthesis underlines the connection between the quality of diet, gut microbiota and mental health through the regulation of metabolic functions, anti-inflammatory and anti-apoptotic properties. Concluding, four-week probiotic plus biotin supplementation, in inpatient individuals with a major depressive disorder diagnosis, showed an overall beneficial effect of clinical treatment. However, probiotic intervention compared to placebo only differed in microbial diversity profile, not in clinical outcome measures.', 'Reininghaus Eva Z, Platzer Martina, Kohlhammer-Dohr Alexandra, Hamm Carlo, Mörkl Sabrina et al.', 'Nutrients',
  2020, '33171595', '10.3390/nu12113422', 'https://pubmed.ncbi.nlm.nih.gov/33171595/', 'rct',
  'included', true
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='biotin'),
  'pubmed', 'Efficacy of 5% topical minoxidil versus 5 mg oral biotin versus topical minoxidil and oral biotin on hair growth in men: randomized, crossover, clinical trial.', NULL, 'Valentim Flávia de Oliveira, Miola Anna Carolina, Miot Hélio Amante, Schmitt Juliano Vilaverde', 'Anais brasileiros de dermatologia',
  2024, '38688776', '10.1016/j.abd.2023.07.008', 'https://pubmed.ncbi.nlm.nih.gov/38688776/', 'rct',
  'included', true
)
ON CONFLICT DO NOTHING;

-- ── selenium ──
INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='selenium'),
  'pubmed', 'Selenium Supplementation in Patients with Hashimoto Thyroiditis: A Systematic Review and Meta-Analysis of Randomized Clinical Trials.', 'Background: Hashimoto thyroiditis (HT) is the most common cause of hypothyroidism in iodine-sufficient areas. Selenium is an essential trace element required for thyroid hormone synthesis and exerts antioxidant effects. Therefore, it may be of relevance in the management of HT. Methods: We conducted a systematic review and meta-analysis of randomized controlled trials (RCTs) to evaluate the effect of selenium supplementation on thyroid function (thyrotropin [TSH], free and total thyroxine [fT4, T4], free and total triiodothyronine [fT3, T3]), thyroid antibodies (thyroid peroxidase antibodies [TPOAb], thyroglobulin antibodies [TGAb], thyrotropin receptor antibody [TRAb]), ultrasound findings (echogenicity, thyroid volume), immune markers, patient-reported outcomes, and adverse events in HT. The study protocol was registered on PROSPERO (CRD42022308377). We systematically searched MEDLINE, Embase, CINHAL, Web of Science, Google Scholar, and the Cochrane CENTRAL Register of Trials from inception to January 2023 and searched citations of eligible studies. Two independent authors reviewed and coded the identified literature. The primary outcome was TSH in patients without thyroid hormone replacement therapy (THRT); the others were considered secondary outcomes. We synthesized the results as standardized mean differences (SMD) or odds ratio (OR), assessed risk of bias using the Cochrane RoB 2 tool, and rated the evidence using the Grading of Recommendations Assessment, Development, and Evaluation (GRADE) approach. Results: We screened 687 records and included 35 unique studies. Our meta-analysis found that selenium supplementation decreased TSH in patients without THRT (SMD -0.21 [confidence interval, CI -0.43 to -0.02]; 7 cohorts, 869 participants; I2 = 0%). In addition, TPOAb (SMD -0.96 [CI -1.36 to -0.56]; 29 cohorts; 2358 participants; I2 = 90%) and malondialdehyde (MDA; SMD -1.16 [CI -2.29 to -0.02]; 3 cohorts; 248 participants; I2 = 85%) decreased in patients with and without THRT. Adverse effects were comparable between the intervention and control groups (OR 0.89 [CI 0.46 to 1.75]; 16 cohorts; 1339 participants; I2 = 0%). No significant changes were observed in fT4, T4, fT3, T3, TGAb, thyroid volume, interleukin (IL)-2, and IL-10. Overall, certainty of evidence was moderate. Conclusions: In people with HT without THRT, selenium was effective and safe in lowering TSH, TPOAb, and MDA levels. Indications for lowering TPOAb were found independent of THRT.', 'Huwiler Valentina V, Maissen-Abgottspon Stephanie, Stanga Zeno, Mühlebach Stefan, Trepp Roman et al.', 'Thyroid : official journal of the American Thyroid Association',
  2024, '38243784', '10.1089/thy.2023.0556', 'https://pubmed.ncbi.nlm.nih.gov/38243784/', 'meta_analysis',
  'included', true
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='selenium'),
  'pubmed', 'Effects of different supplements on Hashimoto''s thyroiditis: a systematic review and network meta-analysis.', 'Clinicians often consider the use of dietary supplements to assist in lowering thyroid autoantibody titres in patients with Hashimoto''s thyroiditis (HT). Currently, different supplements differ in their ability to reduce autoantibody levels. The purpose of this article is to compare the ability of different supplements to lower autoantibody titres and restore TSH levels through a systematic literature review. We obtained information from the PubMed, Web of Science, Embase, and Cochrane databases, as well as the China National Knowledge Infrastructure (CNKI). Selected studies included those using selenium, Vitamin D, Myo-inositol, and Myo-inositol in combination with selenium for the treatment of HT patients with euthyroidism. These data were combined using standardised mean differences (SMDs) and assessed using a random effects model. A total of 10 quantitative meta-analyses of case-control studies were selected for this meta-analysis. Compared to the placebo group, the use of selenium supplements was able to significantly reduce the levels of thyroid peroxidase autoantibodies (TPOAb) (SMD: -2.44, 95% CI: -4.19, -0.69) and thyroglobulin autoantibodies (TgAb) (SMD: -2.76, 95% CI: -4.50, -1.02). During a 6-month treatment, the use of Myo-inositol, Vitamin D alone, and the combination of selenium, and Myo-inositol did not effectively reduce TPOAb (Myo-inositol: SMD:-1.94, 95% CI: -6.75, 2.87; Vitamin D: SMD: -2.54, 95% CI: -6.51,1.42; Se+Myo-inositol: SMD: -3.01, 95% CI: -8.96,2.93) or TgAb (Myo-inositol: SMD:-2.02, 95% CI: -6.52, 2.48; Vitamin D: SMD: -2.73, 95% CI: -6.44,0.98; Se+Myo-inositol: SMD: -3.64, 95% CI: -9.20,1.92) levels. Therefore, we recommend that patients with HT(Hashimoto''s Thyroiditis) be given an appropriate amount of selenium as an auxiliary treatment during standard-of-care treatment.', 'Peng Bingcong, Wang Weiwei, Gu Qingling, Wang Ping, Teng Weiping et al.', 'Frontiers in endocrinology',
  2024, '39698034', '10.3389/fendo.2024.1445878', 'https://pubmed.ncbi.nlm.nih.gov/39698034/', 'systematic_review',
  'included', true
)
ON CONFLICT DO NOTHING;

-- ── vitamin-a ──
INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='vitamin-a'),
  'pubmed', 'Vitamin A supplementation for preventing morbidity and mortality in children from six months to five years of age.', 'BACKGROUND: Vitamin A deficiency (VAD) is a major public health problem in low- and middle-income countries, affecting 190 million children under five years of age and leading to many adverse health consequences, including death. Based on prior evidence and a previous version of this review, the World Health Organization has continued to recommend vitamin A supplementation (VAS) for children aged 6 to 59 months. The last version of this review was published in 2017, and this is an updated version of that review. OBJECTIVES: To assess the effects of vitamin A supplementation (VAS) for preventing morbidity and mortality in children aged six months to five years. SEARCH METHODS: We searched CENTRAL, MEDLINE, Embase, six other databases, and two trials registers up to March 2021. We also checked reference lists and contacted relevant organisations and researchers to identify additional studies. SELECTION CRITERIA: Randomised controlled trials (RCTs) and cluster-RCTs evaluating the effect of synthetic VAS in children aged six months to five years living in the community. We excluded studies involving children in hospital and children with disease or infection. We also excluded studies evaluating the effects of food fortification, consumption of vitamin A rich foods, or beta-carotene supplementation. DATA COLLECTION AND ANALYSIS: For this update, two review authors independently assessed studies for inclusion resolving discrepancies by discussion. We performed meta-analyses for outcomes, including all-cause and cause-specific mortality, disease, vision, and side effects. We used the GRADE approach to assess the quality of the evidence. MAIN RESULTS: The updated search identified no new RCTs. We identified 47 studies, involving approximately 1,223,856 children. Studies were set in 19 countries: 30 (63%) in Asia, 16 of these in India; 8 (17%) in Africa; 7 (15%) in Latin America, and 2 (4%) in Australia. About one-third of the studies were in urban/periurban settings, and half were in rural settings; the remaining studies did not clearly report settings. Most studies included equal numbers of girls and boys and lasted about one year. The mean age of the children was about 33 months. The included studies were at variable overall risk of bias; however, evidence for the primary outcome was at low risk of bias. A meta-analysis for all-cause mortality included 19 trials (1,202,382 children). At longest follow-up, there was a 12% observed reduction in the risk of all-cause mortality for VAS compared with control using a fixed-effect model (risk ratio (RR) 0.88, 95% confidence interval (CI) 0.83 to 0.93; high-certainty evidence). Nine trials reported mortality due to diarrhoea and showed a 12% overall reduction for VAS (RR 0.88, 95% CI 0.79 to 0.98; 1,098,538 children; high-certainty evidence). There was no evidence of a difference for VAS on mortality due to measles (RR 0.88, 95% CI 0.69 to 1.11; 6 studies, 1,088,261 children; low-certainty evidence), respirato', 'Imdad Aamer, Mayo-Wilson Evan, Haykal Maya R, Regan Allison, Sidhu Jasleen et al.', 'The Cochrane database of systematic reviews',
  2022, '35294044', '10.1002/14651858.CD008524.pub4', 'https://pubmed.ncbi.nlm.nih.gov/35294044/', 'meta_analysis',
  'included', true
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='vitamin-a'),
  'pubmed', 'Vitamin A supplementation and child mortality. A meta-analysis.', 'OBJECTIVE: A two-part meta-analysis of studies examining the relationship of vitamin A supplementation and child mortality. DATA SOURCES: We identified studies by searching the MEDLARS database from 1966 through 1992 and by scanning Current Contents and bibliographies of pertinent articles. STUDY SELECTION: All 12 vitamin A controlled trials with data on mortality identified in the search were used in the analysis. DATA EXTRACTION: Data were independently extracted by two investigators who also assessed the quality of each study using a previously described method. DATA SYNTHESIS: We formally tested for heterogeneity across studies. We pooled studies using the Mantel-Haenszel and the DerSimonian and Laird methods and adjusted for the effect of cluster assignment of treatment groups in community-based studies. Vitamin A supplementation to hospitalized measles patients was highly protective against mortality (DerSimonian and Laird odds ratio, 0.39; 95% confidence interval, 0.22 to 0.66; P = .0004) (part 1 of the meta-analysis). Supplementation was also protective against overall mortality in community-based studies (DerSimonian and Laird odds ratio, 0.70; clustering-adjusted 95% confidence interval, 0.56 to 0.87; P = .001) (part 2 of the meta-analysis). CONCLUSIONS: Vitamin A supplements are associated with a significant reduction in mortality when given periodically to children at the community level. Factors that affect the bioavailability of large doses of Vitamin A need to be studied further. Vitamin A supplements should be given to all measles patients in developing countries whether or not they have symptoms of vitamin A deficiency.', 'Fawzi W W, Chalmers T C, Herrera M G, Mosteller F', 'JAMA',
  1993, '8426449', NULL, 'https://pubmed.ncbi.nlm.nih.gov/8426449/', 'meta_analysis',
  'included', true
)
ON CONFLICT DO NOTHING;

-- ── vitamin-e ──
INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='vitamin-e'),
  'pubmed', 'Meta-analysis: high-dosage vitamin E supplementation may increase all-cause mortality.', 'BACKGROUND: Experimental models and observational studies suggest that vitamin E supplementation may prevent cardiovascular disease and cancer. However, several trials of high-dosage vitamin E supplementation showed non-statistically significant increases in total mortality. PURPOSE: To perform a meta-analysis of the dose-response relationship between vitamin E supplementation and total mortality by using data from randomized, controlled trials. PATIENTS: 135,967 participants in 19 clinical trials. Of these trials, 9 tested vitamin E alone and 10 tested vitamin E combined with other vitamins or minerals. The dosages of vitamin E ranged from 16.5 to 2000 IU/d (median, 400 IU/d). DATA SOURCES: PubMed search from 1966 through August 2004, complemented by a search of the Cochrane Clinical Trials Database and review of citations of published reviews and meta-analyses. No language restrictions were applied. DATA EXTRACTION: 3 investigators independently abstracted study reports. The investigators of the original publications were contacted if required information was not available. DATA SYNTHESIS: 9 of 11 trials testing high-dosage vitamin E (> or =400 IU/d) showed increased risk (risk difference > 0) for all-cause mortality in comparisons of vitamin E versus control. The pooled all-cause mortality risk difference in high-dosage vitamin E trials was 39 per 10,000 persons (95% CI, 3 to 74 per 10,000 persons; P = 0.035). For low-dosage vitamin E trials, the risk difference was -16 per 10,000 persons (CI, -41 to 10 per 10,000 persons; P > 0.2). A dose-response analysis showed a statistically significant relationship between vitamin E dosage and all-cause mortality, with increased risk of dosages greater than 150 IU/d. LIMITATIONS: High-dosage (> or =400 IU/d) trials were often small and were performed in patients with chronic diseases. The generalizability of the findings to healthy adults is uncertain. Precise estimation of the threshold at which risk increases is difficult. CONCLUSION: High-dosage (> or =400 IU/d) vitamin E supplements may increase all-cause mortality and should be avoided.', 'Miller Edgar R, Pastor-Barriuso Roberto, Dalal Darshan, Riemersma Rudolph A, Appel Lawrence J et al.', 'Annals of internal medicine',
  2005, '15537682', '10.7326/0003-4819-142-1-200501040-00110', 'https://pubmed.ncbi.nlm.nih.gov/15537682/', 'meta_analysis',
  'included', true
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='vitamin-e'),
  'pubmed', 'Vitamin E supplementation (alone or with other antioxidants) and stroke: a meta-analysis.', 'CONTEXT: A previous study showed that vitamin E is effective in reducing the incidence of myocardial infarction only when it is taken in the absence of other antioxidants. It is unclear if it also reduces the incidence of stroke. OBJECTIVE: The aim of this meta-analysis is to compare the effect of vitamin E supplementation alone or combined with other antioxidants on the incidence of stroke. DATA SOURCES: A search was performed in the following databases: PubMed, ISI Web of Science, SCOPUS, and Cochrane Library. DATA EXTRACTION: Sixteen randomized controlled trials were selected to evaluate the effect of vitamin E supplementation on stroke. DATA ANALYSIS: The range of vitamin E doses used was 33-800 IU. The follow-up period ranged from 6 months to 9.4 years. Compared with controls, when vitamin E was given alone it did not reduce the incidence of ischemic and hemorrhagic stroke. Conversely, compared with controls, supplementation of vitamin E with other antioxidants reduced ischemic stroke (random effects, RR: 0.91; 95% CI: 0.84-0.99; P = 0.02) but with a significant increase in hemorrhagic stroke (random effects, RR: 1.22; 95% CI: 1.0-1.48; P = 0.04). CONCLUSIONS: Supplementation with vitamin E alone is not associated with stroke reduction. Instead, supplementation of vitamin E with other antioxidants reduces the incidence of ischemic stroke but increases the risk of hemorrhagic stroke, cancelling any beneficial effect derived. Thus, vitamin E is not recommended in stroke prevention. SYSTEMATIC REVIEW REGISTRATION: PROSPERO registration no. CRD42022258259.', 'Maggio Enrico, Bocchini Valeria Proietti, Carnevale Roberto, Pignatelli Pasquale, Violi Francesco et al.', 'Nutrition reviews',
  2024, '37698992', '10.1093/nutrit/nuad114', 'https://pubmed.ncbi.nlm.nih.gov/37698992/', 'meta_analysis',
  'included', true
)
ON CONFLICT DO NOTHING;

-- ── curcumin ──
INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='curcumin'),
  'pubmed', 'Efficacy and Safety of Curcumin and Curcuma longa Extract in the Treatment of Arthritis: A Systematic Review and Meta-Analysis of Randomized Controlled Trial.', 'BACKGROUND: Modern pharmacological research found that the chemical components of Curcuma longa L. are mainly curcumin and turmeric volatile oil. Several recent randomized controlled trials (RCT) have shown that curcumin improves symptoms and inflammation in patients with arthritis. METHODS: Pubmed, Cochran Library, CNKI, and other databases were searched to collect the randomized controlled trials (RCTs). Then, the risk of bias of RCTs were assessed and data of RCTs were extracted. Finally, RevMan 5.3 was utilized for meta-analysis. RESULTS: Twenty-nine (29) RCTs involving 2396 participants and 5 types of arthritis were included. The arthritis included Ankylosing Spondylitis (AS), Rheumatoid Arthritis (RA), Osteoarthritis (OA), Juvenile idiopathic arthritis (JIA) and gout/hyperuricemia. Curcumin and Curcuma longa Extract were administered in doses ranging from 120 mg to 1500 mg for a duration of 4-36 weeks. In general, Curcumin and Curcuma longa Extract showed safety in all studies and improved the severity of inflammation and pain levels in these arthritis patients. However, more RCTs are needed in the future to elucidate the effect of Curcumin and Curcuma longa Extract supplementation in patients with arthritis, including RA, OA, AS and JIA. CONCLUSION: Curcumin and Curcuma longa Extract may improve symptoms and inflammation levels in people with arthritis. However, due to the low quality and small quantity of RCTs, the conclusions need to be interpreted carefully.', 'Zeng Liuting, Yang Tiejun, Yang Kailin, Yu Ganpeng, Li Jun et al.', 'Frontiers in immunology',
  2022, '35935936', '10.3389/fimmu.2022.891822', 'https://pubmed.ncbi.nlm.nih.gov/35935936/', 'meta_analysis',
  'included', true
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='curcumin'),
  'pubmed', 'Antioxidant and anti-inflammatory effects of curcumin/turmeric supplementation in adults: A GRADE-assessed systematic review and dose-response meta-analysis of randomized controlled trials.', 'Turmeric and its prominent bioactive compound, curcumin, have been the subject of many investigations with regard to their impact on inflammatory and oxidative balance in the body. In this systematic review and meta-analysis, we summarized the existing literature on randomized controlled trials (RCTs) which examined this hypothesis. Major databases (PubMed, Scopus, Web of Science, Cochrane Library and Google Scholar) were searched from inception up to October 2022. Relevant studies meeting our eligibility criteria were obtained. Main outcomes included inflammatory markers (i.e. C-reactive protein(CRP), tumour necrosis factorα(TNF-α), interleukin-6(IL-6), and interleukin 1 beta(IL-1β)) and markers of oxidative stress (i.e. total antioxidant capacity (TAC), malondialdehyde(MDA), and superoxide dismutase (SOD) activity). Weighted mean differences (WMDs) were reported. P-values < 0.05 were considered significant. Sixty-six RCTs were included in the final analysis. We observed that turmeric/curcumin supplementation significantly reduces levels of inflammatory markers, including CRP (WMD: -0.58 mg/l, 95 % CI: -0.74, -0.41), TNF-α (WMD: -3.48 pg/ml, 95 % CI: -4.38, -2.58), and IL-6 (WMD: -1.31 pg/ml, 95 % CI: -1.58, -0.67); except for IL-1β (WMD: -0.46 pg/ml, 95 % CI: -1.18, 0.27) for which no significant change was found. Also, turmeric/curcumin supplementation significantly improved anti-oxidant activity through enhancing TAC (WMD = 0.21 mmol/l; 95 % CI: 0.08, 0.33), reducing MDA levels (WMD = -0.33 µmol /l; 95 % CI: -0.53, -0.12), and SOD activity (WMD = 20.51 u/l; 95 % CI: 7.35, 33.67). It seems that turmeric/curcumin supplementation might be used as a viable intervention for improving inflammatory/oxidative status of individuals.', 'Dehzad Mohammad Jafar, Ghalandari Hamid, Nouri Mehran, Askarpour Moein', 'Cytokine',
  2023, '36804260', '10.1016/j.cyto.2023.156144', 'https://pubmed.ncbi.nlm.nih.gov/36804260/', 'meta_analysis',
  'included', true
)
ON CONFLICT DO NOTHING;

-- ── melatonin ──
INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='melatonin'),
  'pubmed', 'Effect of melatonin supplementation on sleep quality: a systematic review and meta-analysis of randomized controlled trials.', 'BACKGROUND: The Present study was conducted to systematically review the effect of the melatonin on sleep quality. We summarized evidence from randomized clinical trials (RCTs) that investigated the effects of melatonin on sleep quality as assessed by the Pittsburgh Sleep Quality Index (PSQI) in adults with various diseases. METHODS: The literature searches of English publications in MEDLINE and EMBASE databases were performed up June 2020. Results were summarized as mean differences (MD) with 95% confidence intervals (CI) using random effects model (DerSimonian-Laird method). Heterogeneity among studies was evaluated by the Cochrane Q test and I-squared (I2). To determine the predefined sources of heterogeneity, subgroup analysis was performed. RESULTS: Of 2642 papers, 23 RCTs met inclusion criteria. Our results indicated that melatonin had significant effect on sleep quality as assessed by the Pittsburgh Sleep Quality Index (PSQI) (WMD: - 1.24; 95% CI - 1.77, - 0.71, p = 0.000). There was significant heterogeneity between studies (I2 = 80.7%, p = 0.000). Subgroup analysis based on health status and kind of intervention were potential between-study heterogeneity. Subgroup analysis based on health status revealed melatonin intervention in subjects with Respiratory diseases (WMD: - 2.20; 95% CI - 2.97, - 1.44, p = 0.000), Metabolic disorders (WMD: - 2.74; 95% CI - 3.48, - 2.00, p = 0.000) and sleep disorders (WMD: - 0.67; 95% CI - 0.98, - 0.37, p = 0.000) has significant effect on sleep quality. CONCLUSION: We found that the treatment with exogenous melatonin has positive effects on sleep quality as assessed by the Pittsburgh Sleep Quality Index (PSQI) in adult. In adults with respiratory diseases, metabolic disorders, primary sleep disorders, not with mental disorders, neurodegenerative diseases and other diseases.', 'Fatemeh Gholami, Sajjad Moradi, Niloufar Rasaei, Neda Soveid, Leila Setayesh et al.', 'Journal of neurology',
  2022, '33417003', '10.1007/s00415-020-10381-w', 'https://pubmed.ncbi.nlm.nih.gov/33417003/', 'meta_analysis',
  'included', true
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='melatonin'),
  'pubmed', 'Comparative effects of pharmacological interventions for the acute and long-term management of insomnia disorder in adults: a systematic review and network meta-analysis.', 'BACKGROUND: Behavioural, cognitive, and pharmacological interventions can all be effective for insomnia. However, because of inadequate resources, medications are more frequently used worldwide. We aimed to estimate the comparative effectiveness of pharmacological treatments for the acute and long-term treatment of adults with insomnia disorder. METHODS: In this systematic review and network meta-analysis, we searched the Cochrane Central Register of Controlled Trials, MEDLINE, PubMed, Embase, PsycINFO, WHO International Clinical Trials Registry Platform, ClinicalTrials.gov, and websites of regulatory agencies from database inception to Nov 25, 2021, to identify published and unpublished randomised controlled trials. We included studies comparing pharmacological treatments or placebo as monotherapy for the treatment of adults (≥18 year) with insomnia disorder. We assessed the certainty of evidence using the confidence in network meta-analysis (CINeMA) framework. Primary outcomes were efficacy (ie, quality of sleep measured by any self-rated scale), treatment discontinuation for any reason and due to side-effects specifically, and safety (ie, number of patients with at least one adverse event) both for acute and long-term treatment. We estimated summary standardised mean differences (SMDs) and odds ratios (ORs) using pairwise and network meta-analysis with random effects. This study is registered with Open Science Framework, https://doi.org/10.17605/OSF.IO/PU4QJ. FINDINGS: We included 170 trials (36 interventions and 47 950 participants) in the systematic review and 154 double-blind, randomised controlled trials (30 interventions and 44 089 participants) were eligible for the network meta-analysis. In terms of acute treatment, benzodiazepines, doxylamine, eszopiclone, lemborexant, seltorexant, zolpidem, and zopiclone were more efficacious than placebo (SMD range: 0·36-0·83 [CINeMA estimates of certainty: high to moderate]). Benzodiazepines, eszopiclone, zolpidem, and zopiclone were more efficacious than melatonin, ramelteon, and zaleplon (SMD 0·27-0·71 [moderate to very low]). Intermediate-acting benzodiazepines, long-acting benzodiazepines, and eszopiclone had fewer discontinuations due to any cause than ramelteon (OR 0·72 [95% CI 0·52-0·99; moderate], 0·70 [0·51-0·95; moderate] and 0·71 [0·52-0·98; moderate], respectively). Zopiclone and zolpidem caused more dropouts due to adverse events than did placebo (zopiclone: OR 2·00 [95% CI 1·28-3·13; very low]; zolpidem: 1·79 [1·25-2·50; moderate]); and zopiclone caused more dropouts than did eszopiclone (OR 1·82 [95% CI 1·01-3·33; low]), daridorexant (3·45 [1·41-8·33; low), and suvorexant (3·13 [1·47-6·67; low]). For the number of individuals with side-effects at study endpoint, benzodiazepines, eszopiclone, zolpidem, and zopiclone were worse than placebo, doxepin, seltorexant, and zaleplon (OR range 1·27-2·78 [high to very low]). For long-term treatment, eszopiclone and lemborexant were more effectiv', 'De Crescenzo Franco, D''Alò Gian Loreto, Ostinelli Edoardo G, Ciabattini Marco, Di Franco Valeria et al.', 'Lancet (London, England)',
  2022, '35843245', '10.1016/S0140-6736(22)00878-9', 'https://pubmed.ncbi.nlm.nih.gov/35843245/', 'systematic_review',
  'included', true
)
ON CONFLICT DO NOTHING;

-- ── red-ginseng ──
INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='red-ginseng'),
  'pubmed', 'Effects of Ginseng on Cognitive Function: A Systematic Review and Meta-Analysis.', 'Ginseng is a kind of traditional Chinese medicine. It is widely believed that ginseng can improve cognitive function, but its clinical efficacy is still controversial. This study aimed to systematically evaluate the effects of ginseng on cognitive function improvement. This is a systematic review and meta-analysis of the randomized controlled trials (RCTs). Searching PubMed, Web of Science, the Cochrane Library, and Medline databases to collect RCTs of ginseng on the effects of human cognitive function. The time range is from the establishment of the database to December 2023. The main intervention in the trials was ginseng preparation. The Cochrane risk-of-bias tool 2.0 (RoB2.0) and Jadad scale were used to assess the risk of bias and evaluate the quality of the included articles. After data extraction, meta-analysis was performed using Stata 17.0 software. A total of 15 RCTs were included, and 671 patients were analyzed. The subjects included healthy people, patients of cognitive impairment, schizophrenia, hospitalized, and Alzheimer''s disease. The intervention measures were mainly ginseng preparations. The meta-analysis results indicated that ginseng has a significant effect on memory improvement (SMD = 0.19, 95%CI: 0.02-0.36, p < 0.05), especially at high doses (SMD = 0.33, 95%CI: 0.04-0.61, p < 0.05). Ginseng did not have a positive effect on overall cognition, attention, and executive function (SMD = 0.06, 95%CI: -0.64-0.77, p = 0.86; SMD = 0.06, 95%CI: -0.12 to 0.23, p = 0.54; SMD = -0.03, 95%CI: -0.28 to 0.21, p = 0.79). Ginseng has some positive effects on cognitive improvement, especially on memory improvement. But in the future, more high-quality studies are needed to determine the effects of ginseng on cognitive function. Trial Registration: Prospero: CRD42024514231.', 'Zeng Maogui, Zhang Kuan, Yang Juan, Zhang Yu, You Pengcheng et al.', 'Phytotherapy research : PTR',
  2024, '39474788', '10.1002/ptr.8359', 'https://pubmed.ncbi.nlm.nih.gov/39474788/', 'meta_analysis',
  'included', true
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='red-ginseng'),
  'pubmed', 'Ginseng as a Treatment for Fatigue: A Systematic Review.', 'BACKGROUND: Millions of people with chronic illness suffer from fatigue. Fatigue is a complex, multidimensional symptom with poorly understood causes, wide variations in severity among individuals, and negative effects on multiple domains of daily life. Many patients with fatigue report the use of herbal remedies. Ginseng is one of the most widely used because it is believed to improve energy, physical and emotional health, and well-being. OBJECTIVE: To systematically review the published evidence to evaluate the safety and effectiveness of the two types of Panax ginseng (Asian [Panax ginseng] and American [Panax quinquefolius]) as treatments for fatigue. DESIGN: PubMed, CINAHL (Cumulative Index to Nursing and Allied Health), Ovid MEDLINE, and EMBASE databases were searched using Medical Subject Heading and keyword terms, including ginseng, Panax, ginsenosides, ginsenoside* (wild card), fatigue, fatigue syndrome, cancer-related fatigue, and chronic fatigue. Studies were included if participants had fatigue, had used one of the two Panax ginsengs as an intervention, and had scores from a self-report fatigue measure. Two reviewers independently assessed each article at each review phase and met to develop consensus on included studies. Risk of bias was assessed using version 5.3 of the Cochrane Collaboration Review Manager (RevMan), and results were synthesized in a narrative summary. RESULTS: The search strategy resulted in 149 articles, with 1 additional article located through review of references. After titles, abstracts, and full text were reviewed, 139 articles did not meet inclusion criteria. For the 10 studies reviewed, there was a low risk of adverse events associated with the use of ginseng and modest evidence for its efficacy. CONCLUSIONS: Ginseng is a promising treatment for fatigue. Both American and Asian ginseng may be viable treatments for fatigue in people with chronic illness. Because of ginseng''s widespread use, a critical need exists for continued research that is methodologically stronger and that includes more diverse samples before ginseng is adopted as a standard treatment option for fatigue.', 'Arring Noël M, Millstine Denise, Marks Lisa A, Nail Lillian M', 'Journal of alternative and complementary medicine (New York, N.Y.)',
  2018, '29624410', '10.1089/acm.2017.0361', 'https://pubmed.ncbi.nlm.nih.gov/29624410/', 'systematic_review',
  'included', true
)
ON CONFLICT DO NOTHING;

-- ── msm ──
INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='msm'),
  'pubmed', 'Dietary supplements for treating osteoarthritis: a systematic review and meta-analysis.', 'OBJECTIVE: To investigate the efficacy and safety of dietary supplements for patients with osteoarthritis. DESIGN: An intervention systematic review with random effects meta-analysis and meta-regression. DATA SOURCES: MEDLINE, EMBASE, Cochrane Register of Controlled Trials, Allied and Complementary Medicine and Cumulative Index to Nursing and Allied Health Literature were searched from inception to April 2017. STUDY ELIGIBILITY CRITERIA: Randomised controlled trials comparing oral supplements with placebo for hand, hip or knee osteoarthritis. RESULTS: Of 20 supplements investigated in 69 eligible studies, 7 (collagen hydrolysate, passion fruit peel extract, Curcuma longa extract, Boswellia serrata extract, curcumin, pycnogenol and L-carnitine) demonstrated large (effect size >0.80) and clinically important effects for pain reduction at short term. Another six (undenatured type II collagen, avocado soybean unsaponifiables, methylsulfonylmethane, diacerein, glucosamine and chondroitin) revealed statistically significant improvements on pain, but were of unclear clinical importance. Only green-lipped mussel extract and undenatured type II collagen had clinically important effects on pain at medium term. No supplements were identified with clinically important effects on pain reduction at long term. Similar results were found for physical function. Chondroitin demonstrated statistically significant, but not clinically important structural improvement (effect size -0.30, -0.42 to -0.17). There were no differences between supplements and placebo for safety outcomes, except for diacerein. The Grading of Recommendations Assessment, Development and Evaluation suggested a wide range of quality evidence from very low to high. CONCLUSIONS: The overall analysis including all trials showed that supplements provided moderate and clinically meaningful treatment effects on pain and function in patients with hand, hip or knee osteoarthritis at short term, although the quality of evidence was very low. Some supplements with a limited number of studies and participants suggested large treatment effects, while widely used supplements such as glucosamine and chondroitin were either ineffective or showed small and arguably clinically unimportant treatment effects. Supplements had no clinically important effects on pain and function at medium-term and long-term follow-ups.', 'Liu Xiaoqian, Machado Gustavo C, Eyles Jillian P, Ravi Varshini, Hunter David J', 'British journal of sports medicine',
  2018, '29018060', '10.1136/bjsports-2016-097333', 'https://pubmed.ncbi.nlm.nih.gov/29018060/', 'meta_analysis',
  'included', true
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='msm'),
  'pubmed', 'Oral pre-exposure prophylaxis (PrEP) to prevent HIV: a systematic review and meta-analysis of clinical effectiveness, safety, adherence and risk compensation in all populations.', 'OBJECTIVE: To conduct a systematic review and meta-analysis of randomised controlled trials (RCTs) of the effectiveness and safety of oral pre-exposure prophylaxis (PrEP) to prevent HIV. METHODS: Databases (PubMed, Embase and the Cochrane Register of Controlled Trials) were searched up to 5 July 2020. Search terms for ''HIV'' were combined with terms for ''PrEP'' or ''tenofovir/emtricitabine''. RCTs were included that compared oral tenofovir-containing PrEP to placebo, no treatment or alternative medication/dosing schedule. The primary outcome was the rate ratio (RR) of HIV infection using a modified intention-to-treat analysis. Secondary outcomes included safety, adherence and risk compensation. All analyses were stratified a priori by population: men who have sex with men (MSM), serodiscordant couples, heterosexuals and people who inject drugs (PWIDs). The quality of individual studies was assessed using the Cochrane risk-of-bias tool, and the certainty of evidence was assessed using GRADE. RESULTS: Of 2803 unique records, 15 RCTs met our inclusion criteria. Over 25 000 participants were included, encompassing 38 289 person-years of follow-up data. PrEP was found to be effective in MSM (RR 0.25, 95% CI 0.1 to 0.61; absolute rate difference (RD) -0.03, 95% CI -0.01 to -0.05), serodiscordant couples (RR 0.25, 95% CI 0.14 to 0.46; RD -0.01, 95% CI -0.01 to -0.02) and PWID (RR 0.51, 95% CI 0.29 to 0.92; RD -0.00, 95% CI -0.00 to -0.01), but not in heterosexuals (RR 0.77, 95% CI 0.46 to 1.29). Efficacy was strongly associated with adherence (p<0.01). PrEP was found to be safe, but unrecognised HIV at enrolment increased the risk of viral drug resistance mutations. Evidence for behaviour change or an increase in sexually transmitted infections was not found. CONCLUSIONS: PrEP is safe and effective in MSM, serodiscordant couples and PWIDs. Additional research is needed prior to recommending PrEP in heterosexuals. No RCTs reported effectiveness or safety data for other high-risk groups, such as transgender women and sex workers. PROSPERO REGISTRATION NUMBER: CRD42017065937.', 'O Murchu Eamon, Marshall Liam, Teljeur Conor, Harrington Patricia, Hayes Catherine et al.', 'BMJ open',
  2022, '35545381', '10.1136/bmjopen-2020-048478', 'https://pubmed.ncbi.nlm.nih.gov/35545381/', 'meta_analysis',
  'included', true
)
ON CONFLICT DO NOTHING;

-- ── garcinia ──
INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='garcinia'),
  'pubmed', 'The effects of Garcinia cambogia (hydroxycitric acid) on lipid profile: A systematic review and meta-analysis of randomized controlled trials.', 'Garcinia cambogia (GC) has antioxidant, anticancer, antihistamine, and antimicrobial properties. To determine the effect of GC on lipid profiles, a systematic review and meta-analysis was carried out. Up to February 9, 2023, six electronic databases (Web of Science, Cochrane Library, Embase, PubMed, Scopus, and Google Scholar) were searched at any time without limitations. Trials examining the impact of GC on serum levels of total cholesterol (TC), triglycerides (TG), low-density lipoprotein cholesterol, and high-density lipoprotein cholesterol (HDL-C) in adults were included. The total effect was shown as a weighted mean difference (WMD) and 95% confidence interval (CI) in a random-effects meta-analysis approach. This systematic review and meta-analysis included 14 trials involving 623 subjects. Plasma levels of TC (WMD: -6.76 mg/dL; CI: -12.39 to -0.59, p-value = 0.032), and TG (WMD: -24.21 mg/dL; CI: -37.84 to -10.58, p < 0.001) were significantly reduced after GC use, and plasma HDL-C (WMD: 2.95 mg/dL; CI: 2.01 to 3.89, p < 0.001) levels increased. low-density lipoprotein cholesterol levels (WMD: -1.15 mg/dL; CI: -16.08 to 13.78, p-value = 0.880) were not significantly affected. The effects of lowering TC and TG were more pronounced for periods longer than 8 weeks. Consuming GC has a positive impact on TC, TG, and HDL-C concentrations. The limitations of this study include the short duration of analyzed interventions and significant heterogeneity. Nevertheless, it is imperative to conduct well-structured, and high-quality long-term trials to comprehensively evaluate the clinical effectiveness of GC on lipid profile, and validate these findings.', 'Amini Mohammad Reza, Rasaei Niloufar, Jalalzadeh Moharam, Akhgarjand Camellia, Hashemian Maryam et al.', 'Phytotherapy research : PTR',
  2024, '38151892', '10.1002/ptr.8102', 'https://pubmed.ncbi.nlm.nih.gov/38151892/', 'meta_analysis',
  'included', true
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='garcinia'),
  'pubmed', 'The effects of Garcinia cambogia (hydroxycitric acid) on serum leptin concentrations: A systematic review and meta-analysis of randomized controlled trials.', 'OBJECTIVE: The observed impacts of Garcinia cambogia (GC) on serum leptin indicate inconsistency. We performed a systematic review and meta-analysis on randomized controlled trials (RCTs) to evaluate the effectiveness of GC on leptin levels. METHODS: A thorough literature search was carried out using different online databases, including Scopus, Web of Science, PubMed, and Google Scholar, until May 25, 2024. Using random effects, weighted mean differences (WMDs) and corresponding 95 % confidence intervals (CIs) were computed. Standard procedures were followed to account for publication bias, study quality, and statistical heterogeneity. RESULTS: In this meta-analysis, a total of eight eligible trials with 330 participants were ultimately included. Quality assessment showed that half of the included trials were considered to have fair quality, while the other half were deemed to have poor quality. Our analysis, with no indication of publication bias, showed a significantly decreased effect of GC on leptin compared with the placebo (WMD: -5.01 ng/ml; 95 % CI: -9.22 to -0.80, p = 0.02). However, significant heterogeneity was detected between studies (I2 =93.5 %, p < 0.001). The Hartung-Knapp adjustment did not affect our results. Subgroup analysis revealed that GC consumption represents the most effects in trials with sample size ≥ 50 (WMD: -3.63 ng/ml; 95 % CI [-5.51, -1.76], p < 0.001), and mean age of participants ≥ 30 years (WMD: -7.43 ng/ml; 95 % CI [-9.31, -5.56], p < 0.001). CONCLUSIONS: The findings of the present study showed that leptin levels might decline following GC administration. REGISTRATION NUMBER: CRD42023486370.', 'Amini Mohammad Reza, Salavatizadeh Marieh, Kazeminejad Shervin, Javadi Fozhan, Hajiaqaei Mahdi et al.', 'Complementary therapies in medicine',
  2024, '38876392', '10.1016/j.ctim.2024.103060', 'https://pubmed.ncbi.nlm.nih.gov/38876392/', 'meta_analysis',
  'included', true
)
ON CONFLICT DO NOTHING;

-- ── collagen ──
INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='collagen'),
  'pubmed', 'Effects of hydrolyzed collagen supplementation on skin aging: a systematic review and meta-analysis.', 'Skin aging has become a recurring concern even for younger people, mainly owing to increased life expectancy. In this context, the use of nutricosmetics as supplements has increased in recent years. Moreover, numerous scientific studies have shown the benefits of hydrolyzed collagen supplementation in improving the signs of skin aging. The objective of this study was to summarize the evidence on the effects of hydrolyzed collagen supplementation on human skin through a systematic review followed by a meta-analysis of clinical trials focusing on the process of skin aging. A literature search was conducted in the Medline, Embase, Cochrane, LILACS (Latin American and Caribbean Health Sciences Literature), and Journal of Negative Results in BioMedicine databases. Eligible studies were randomized, double-blind, and controlled trials that evaluated oral supplementation with hydrolyzed collagen as an intervention and reported at least one of the following outcomes: skin wrinkles, hydration, elasticity, and firmness. After retrieving articles from the databases, 19 studies were selected, with a total of 1,125 participants aged between 20 and 70 years (95% women). In the meta-analysis, a grouped analysis of studies showed favorable results of hydrolyzed collagen supplementation compared with placebo in terms of skin hydration, elasticity, and wrinkles. The findings of improved hydration and elasticity were also confirmed in the subgroup meta-analysis. Based on results, ingestion of hydrolyzed collagen for 90 days is effective in reducing skin aging, as it reduces wrinkles and improves skin elasticity and hydration.', 'de Miranda Roseane B, Weimer Patrícia, Rossi Rochele C', 'International journal of dermatology',
  2021, '33742704', '10.1111/ijd.15518', 'https://pubmed.ncbi.nlm.nih.gov/33742704/', 'meta_analysis',
  'included', true
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='collagen'),
  'pubmed', 'The effects of collagen peptide supplementation on body composition, collagen synthesis, and recovery from joint injury and exercise: a systematic review.', 'Collagen peptide supplementation (COL), in conjunction with exercise, may be beneficial for the management of degenerative bone and joint disorders. This is likely due to stimulatory effects of COL and exercise on the extracellular matrix of connective tissues, improving structure and load-bearing capabilities. This systematic review aims to evaluate the current literature available on the combined impact of COL and exercise. Following Preferred Reporting Items for Systematic Reviews and Meta-analyses guidelines, a literature search of three electronic databases-PubMed, Web of Science and CINAHL-was conducted in June 2020. Fifteen randomised controlled trials were selected after screening 856 articles. The study populations included 12 studies in recreational athletes, 2 studies in elderly participants and 1 in untrained pre-menopausal women. Study outcomes were categorised into four topics: (i) joint pain and recovery from joint injuries, (ii) body composition, (iii) muscle soreness and recovery from exercise, and (iv) muscle protein synthesis (MPS) and collagen synthesis. The results indicated that COL is most beneficial in improving joint functionality and reducing joint pain. Certain improvements in body composition, strength and muscle recovery were present. Collagen synthesis rates were elevated with 15 g/day COL but did not have a significant impact on MPS when compared to isonitrogenous higher quality protein sources. Exact mechanisms for these adaptations are unclear, with future research using larger sample sizes, elite athletes, female participants and more precise outcome measures such as muscle biopsies and magnetic imagery.', 'Khatri Mishti, Naughton Robert J, Clifford Tom, Harper Liam D, Corr Liam', 'Amino acids',
  2021, '34491424', '10.1007/s00726-021-03072-x', 'https://pubmed.ncbi.nlm.nih.gov/34491424/', 'systematic_review',
  'included', true
)
ON CONFLICT DO NOTHING;

-- ── creatine ──
INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='creatine'),
  'pubmed', 'Effects of Creatine Supplementation on Renal Function: A Systematic Review and Meta-Analysis.', 'Creatine supplements are intended to improve performance, but there are indications that it can overwhelm liver and kidney functions, reduce the quality of life, and increase mortality. Therefore, this is the first systematic review and meta-analysis study that aimed to investigate creatine supplements and their possible renal function side effects. After evaluating 290 non-duplicated studies, 15 were included in the qualitative analysis and 6 in the quantitative analysis. The results of the meta-analysis suggest that creatine supplementation did not significantly alter serum creatinine levels (standardized mean difference = 0.48, 95% confidence interval 0.24-0.73, P = .001, I2 = 22%), and did not alter plasma urea values (standardized mean difference = 1.10, 95% confidence interval 0.34-1.85, P = .004, I2 = 28%). The findings indicate that creatine supplementation does not induce renal damage in the studied amounts and durations.', 'de Souza E Silva Alexandre, Pertille Adriana, Reis Barbosa Carolina Gabriela, Aparecida de Oliveira Silva Jasiele, de Jesus Diego Vilela et al.', 'Journal of renal nutrition : the official journal of the Council on Renal Nutrition of the National Kidney Foundation',
  2019, '31375416', '10.1053/j.jrn.2019.05.004', 'https://pubmed.ncbi.nlm.nih.gov/31375416/', 'meta_analysis',
  'included', true
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='creatine'),
  'pubmed', 'Effects of creatine supplementation on memory in healthy individuals: a systematic review and meta-analysis of randomized controlled trials.', 'CONTEXT: From an energy perspective, the brain is very metabolically demanding. It is well documented that creatine plays a key role in brain bioenergetics. There is some evidence that creatine supplementation can augment brain creatine stores, which could increase memory. OBJECTIVE: A systematic review and meta-analysis of randomized controlled trials (RCTs) was conducted to determine the effects of creatine supplementation on memory performance in healthy humans. DATA SOURCES: The literature was searched through the PubMed, Web of Science, Cochrane Library, and Scopus databases from inception until September 2021. DATA EXTRACTION: Twenty-three eligible RCTs were initially identified. Ten RCTs examining the effect of creatine supplementation compared with placebo on measures of memory in healthy individuals met the inclusion criteria for systematic review, 8 of which were included in the meta-analysis. DATA ANALYSIS: Overall, creatine supplementation improved measures of memory compared with placebo (standard mean difference [SMD] = 0.29, 95%CI, 0.04-0.53; I2 = 66%; P = 0.02). Subgroup analyses revealed a significant improvement in memory in older adults (66-76 years) (SMD = 0.88; 95%CI, 0.22-1.55; I2 = 83%; P = 0.009) compared with their younger counterparts (11-31 years) (SMD = 0.03; 95%CI, -0.14 to 0.20; I2 = 0%; P = 0.72). Creatine dose (≈ 2.2-20 g/d), duration of intervention (5 days to 24 weeks), sex, or geographical origin did not influence the findings. CONCLUSION: Creatine supplementation enhanced measures of memory performance in healthy individuals, especially in older adults (66-76 years). SYSTEMATIC REVIEW REGISTRATION: PROSPERO registration no. 42021281027.', 'Prokopidis Konstantinos, Giannos Panagiotis, Triantafyllidis Konstantinos K, Kechagias Konstantinos S, Forbes Scott C et al.', 'Nutrition reviews',
  2023, '35984306', '10.1093/nutrit/nuac064', 'https://pubmed.ncbi.nlm.nih.gov/35984306/', 'meta_analysis',
  'included', true
)
ON CONFLICT DO NOTHING;


-- ============================================================================
-- SECTION 2: evidence_outcomes (결과지표)
-- ============================================================================

INSERT INTO evidence_outcomes (
  evidence_study_id, outcome_name, outcome_type, effect_direction, conclusion_summary
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='31405892' LIMIT 1),
  '골밀도 및 골절 위험', 'efficacy', 'positive', '비타민 D 보충이 골밀도 유지 및 골절 위험 감소에 기여'
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, outcome_name, outcome_type, effect_direction, conclusion_summary
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='36745886' LIMIT 1),
  '골밀도 및 골절 위험', 'efficacy', 'positive', '비타민 D 보충이 골밀도 유지 및 골절 위험 감소에 기여'
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, outcome_name, outcome_type, effect_direction, conclusion_summary
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='34967304' LIMIT 1),
  '감기 이환 기간 및 빈도', 'efficacy', 'positive', '비타민 C 보충이 감기 지속 기간 단축에 소폭 기여'
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, outcome_name, outcome_type, effect_direction, conclusion_summary
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='37682265' LIMIT 1),
  '감기 이환 기간 및 빈도', 'efficacy', 'positive', '비타민 C 보충이 감기 지속 기간 단축에 소폭 기여'
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, outcome_name, outcome_type, effect_direction, conclusion_summary
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='33809274' LIMIT 1),
  '혈중 B12 수치 및 빈혈 개선', 'efficacy', 'positive', 'B12 보충이 결핍군에서 혈중 수치 및 빈혈 지표 개선'
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, outcome_name, outcome_type, effect_direction, conclusion_summary
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='34432056' LIMIT 1),
  '혈중 B12 수치 및 빈혈 개선', 'efficacy', 'positive', 'B12 보충이 결핍군에서 혈중 수치 및 빈혈 지표 개선'
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, outcome_name, outcome_type, effect_direction, conclusion_summary
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='36321557' LIMIT 1),
  '신경관 결손 예방', 'efficacy', 'positive', '엽산 보충이 신경관 결손 위험을 유의하게 감소'
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, outcome_name, outcome_type, effect_direction, conclusion_summary
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='39145520' LIMIT 1),
  '신경관 결손 예방', 'efficacy', 'positive', '엽산 보충이 신경관 결손 위험을 유의하게 감소'
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, outcome_name, outcome_type, effect_direction, conclusion_summary
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='37028557' LIMIT 1),
  '혈중 중성지방 감소', 'efficacy', 'positive', '오메가-3 보충이 혈중 중성지방을 유의하게 감소'
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, outcome_name, outcome_type, effect_direction, conclusion_summary
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='32114706' LIMIT 1),
  '혈중 중성지방 감소', 'efficacy', 'positive', '오메가-3 보충이 혈중 중성지방을 유의하게 감소'
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, outcome_name, outcome_type, effect_direction, conclusion_summary
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='33865376' LIMIT 1),
  '혈압 감소 효과', 'efficacy', 'positive', '마그네슘 보충이 수축기/이완기 혈압을 소폭 감소'
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, outcome_name, outcome_type, effect_direction, conclusion_summary
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='29637897' LIMIT 1),
  '혈압 감소 효과', 'efficacy', 'positive', '마그네슘 보충이 수축기/이완기 혈압을 소폭 감소'
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, outcome_name, outcome_type, effect_direction, conclusion_summary
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='35311615' LIMIT 1),
  '감기 증상 완화', 'efficacy', 'positive', '아연 보충이 감기 지속 기간 단축에 효과적'
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, outcome_name, outcome_type, effect_direction, conclusion_summary
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='39683510' LIMIT 1),
  '감기 증상 완화', 'efficacy', 'positive', '아연 보충이 감기 지속 기간 단축에 효과적'
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, outcome_name, outcome_type, effect_direction, conclusion_summary
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='36728680' LIMIT 1),
  '빈혈 개선 및 헤모글로빈', 'efficacy', 'positive', '철분 보충이 철 결핍성 빈혈에서 헤모글로빈 수치를 유의하게 개선'
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, outcome_name, outcome_type, effect_direction, conclusion_summary
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='39951396' LIMIT 1),
  '빈혈 개선 및 헤모글로빈', 'efficacy', 'positive', '철분 보충이 철 결핍성 빈혈에서 헤모글로빈 수치를 유의하게 개선'
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, outcome_name, outcome_type, effect_direction, conclusion_summary
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='33237064' LIMIT 1),
  '골밀도 유지', 'efficacy', 'positive', '칼슘 보충이 폐경 후 여성에서 골밀도 감소 완화에 기여'
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, outcome_name, outcome_type, effect_direction, conclusion_summary
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='26510847' LIMIT 1),
  '골밀도 유지', 'efficacy', 'positive', '칼슘 보충이 폐경 후 여성에서 골밀도 감소 완화에 기여'
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, outcome_name, outcome_type, effect_direction, conclusion_summary
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='31004628' LIMIT 1),
  '장 건강 및 소화 기능', 'efficacy', 'positive', '프로바이오틱스가 항생제 관련 설사 및 장 기능 개선에 효과적'
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, outcome_name, outcome_type, effect_direction, conclusion_summary
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='37168869' LIMIT 1),
  '장 건강 및 소화 기능', 'efficacy', 'positive', '프로바이오틱스가 항생제 관련 설사 및 장 기능 개선에 효과적'
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, outcome_name, outcome_type, effect_direction, conclusion_summary
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='37702300' LIMIT 1),
  '황반 색소 밀도 개선', 'efficacy', 'positive', '루테인 보충이 황반 색소 밀도 증가 및 시각 기능 개선에 기여'
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, outcome_name, outcome_type, effect_direction, conclusion_summary
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='33998846' LIMIT 1),
  '황반 색소 밀도 개선', 'efficacy', 'positive', '루테인 보충이 황반 색소 밀도 증가 및 시각 기능 개선에 기여'
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, outcome_name, outcome_type, effect_direction, conclusion_summary
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='39019217' LIMIT 1),
  '심부전 증상 개선', 'efficacy', 'positive', 'CoQ10 보충이 심부전 환자의 운동 능력 및 증상 개선에 기여'
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, outcome_name, outcome_type, effect_direction, conclusion_summary
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='39129455' LIMIT 1),
  '심부전 증상 개선', 'efficacy', 'positive', 'CoQ10 보충이 심부전 환자의 운동 능력 및 증상 개선에 기여'
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, outcome_name, outcome_type, effect_direction, conclusion_summary
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='38579127' LIMIT 1),
  '간 기능 지표 개선', 'efficacy', 'positive', '실리마린이 간 효소(ALT, AST) 수치 개선에 기여'
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, outcome_name, outcome_type, effect_direction, conclusion_summary
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='32065376' LIMIT 1),
  '간 기능 지표 개선', 'efficacy', 'positive', '실리마린이 간 효소(ALT, AST) 수치 개선에 기여'
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, outcome_name, outcome_type, effect_direction, conclusion_summary
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='36142319' LIMIT 1),
  '관절 통증 및 기능 개선', 'efficacy', 'positive', '글루코사민이 골관절염 환자의 통증 감소에 소폭 기여'
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, outcome_name, outcome_type, effect_direction, conclusion_summary
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='35024906' LIMIT 1),
  '관절 통증 및 기능 개선', 'efficacy', 'positive', '글루코사민이 골관절염 환자의 통증 감소에 소폭 기여'
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, outcome_name, outcome_type, effect_direction, conclusion_summary
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='33171595' LIMIT 1),
  '모발 및 손톱 건강', 'efficacy', 'neutral', '비오틴 결핍 시 효과가 있으나, 정상 수치에서는 추가 효과 제한적'
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, outcome_name, outcome_type, effect_direction, conclusion_summary
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='38688776' LIMIT 1),
  '모발 및 손톱 건강', 'efficacy', 'neutral', '비오틴 결핍 시 효과가 있으나, 정상 수치에서는 추가 효과 제한적'
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, outcome_name, outcome_type, effect_direction, conclusion_summary
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='38243784' LIMIT 1),
  '항산화 및 갑상선 기능', 'efficacy', 'positive', '셀레늄 보충이 갑상선 항체 감소 및 항산화 지표 개선에 기여'
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, outcome_name, outcome_type, effect_direction, conclusion_summary
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='39698034' LIMIT 1),
  '항산화 및 갑상선 기능', 'efficacy', 'positive', '셀레늄 보충이 갑상선 항체 감소 및 항산화 지표 개선에 기여'
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, outcome_name, outcome_type, effect_direction, conclusion_summary
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='35294044' LIMIT 1),
  '시각 기능 및 면역 지원', 'efficacy', 'positive', '비타민 A 보충이 결핍 지역 아동의 사망률 감소에 기여'
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, outcome_name, outcome_type, effect_direction, conclusion_summary
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='8426449' LIMIT 1),
  '시각 기능 및 면역 지원', 'efficacy', 'positive', '비타민 A 보충이 결핍 지역 아동의 사망률 감소에 기여'
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, outcome_name, outcome_type, effect_direction, conclusion_summary
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='15537682' LIMIT 1),
  '항산화 효과', 'efficacy', 'neutral', '비타민 E 보충의 만성질환 예방 효과는 제한적, 고용량 주의'
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, outcome_name, outcome_type, effect_direction, conclusion_summary
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='37698992' LIMIT 1),
  '항산화 효과', 'efficacy', 'neutral', '비타민 E 보충의 만성질환 예방 효과는 제한적, 고용량 주의'
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, outcome_name, outcome_type, effect_direction, conclusion_summary
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='35935936' LIMIT 1),
  '항염 효과', 'efficacy', 'positive', '커큐민 보충이 CRP 등 염증 지표 감소에 유의한 효과'
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, outcome_name, outcome_type, effect_direction, conclusion_summary
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='36804260' LIMIT 1),
  '항염 효과', 'efficacy', 'positive', '커큐민 보충이 CRP 등 염증 지표 감소에 유의한 효과'
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, outcome_name, outcome_type, effect_direction, conclusion_summary
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='33417003' LIMIT 1),
  '수면 잠복기 단축', 'efficacy', 'positive', '멜라토닌이 수면 잠복기 단축 및 수면 질 개선에 효과적'
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, outcome_name, outcome_type, effect_direction, conclusion_summary
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='35843245' LIMIT 1),
  '수면 잠복기 단축', 'efficacy', 'positive', '멜라토닌이 수면 잠복기 단축 및 수면 질 개선에 효과적'
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, outcome_name, outcome_type, effect_direction, conclusion_summary
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='39474788' LIMIT 1),
  '면역 기능 및 피로 개선', 'efficacy', 'positive', '홍삼이 면역 세포 활성화 및 피로 감소에 기여'
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, outcome_name, outcome_type, effect_direction, conclusion_summary
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='29624410' LIMIT 1),
  '면역 기능 및 피로 개선', 'efficacy', 'positive', '홍삼이 면역 세포 활성화 및 피로 감소에 기여'
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, outcome_name, outcome_type, effect_direction, conclusion_summary
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='29018060' LIMIT 1),
  '관절 통증 감소', 'efficacy', 'positive', 'MSM이 골관절염 관절 통증 및 기능 개선에 소폭 기여'
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, outcome_name, outcome_type, effect_direction, conclusion_summary
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='35545381' LIMIT 1),
  '관절 통증 감소', 'efficacy', 'positive', 'MSM이 골관절염 관절 통증 및 기능 개선에 소폭 기여'
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, outcome_name, outcome_type, effect_direction, conclusion_summary
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='38151892' LIMIT 1),
  '체중 및 체지방 감소', 'efficacy', 'neutral', '가르시니아(HCA)의 체중 감소 효과는 소규모이며 임상적 유의성 논란'
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, outcome_name, outcome_type, effect_direction, conclusion_summary
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='38876392' LIMIT 1),
  '체중 및 체지방 감소', 'efficacy', 'neutral', '가르시니아(HCA)의 체중 감소 효과는 소규모이며 임상적 유의성 논란'
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, outcome_name, outcome_type, effect_direction, conclusion_summary
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='33742704' LIMIT 1),
  '피부 탄력 및 관절 건강', 'efficacy', 'positive', '콜라겐 펩타이드 보충이 피부 탄력 개선 및 관절 통증 감소에 기여'
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, outcome_name, outcome_type, effect_direction, conclusion_summary
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='34491424' LIMIT 1),
  '피부 탄력 및 관절 건강', 'efficacy', 'positive', '콜라겐 펩타이드 보충이 피부 탄력 개선 및 관절 통증 감소에 기여'
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, outcome_name, outcome_type, effect_direction, conclusion_summary
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='31375416' LIMIT 1),
  '근력 및 운동 수행능력', 'efficacy', 'positive', '크레아틴 보충이 고강도 운동 시 근력 및 파워 출력 향상에 효과적'
)
ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, outcome_name, outcome_type, effect_direction, conclusion_summary
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='35984306' LIMIT 1),
  '근력 및 운동 수행능력', 'efficacy', 'positive', '크레아틴 보충이 고강도 운동 시 근력 및 파워 출력 향상에 효과적'
)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 총 evidence_studies: 50건
-- 총 evidence_outcomes: 50건
-- ============================================================================