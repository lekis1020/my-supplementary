#!/usr/bin/env python3
"""
PubMed E-utilities를 사용하여 25종 원료별 메타분석/체계적 문헌고찰 논문 수집
→ db/009_seed_evidence.sql 생성 (v2 - 중복 PMID 방지)
"""

import json
import time
import urllib.request
import urllib.parse
import xml.etree.ElementTree as ET
from datetime import datetime

API_KEY = "447eb2e330874c15cf15eaac1a7f6bd0a809"
BASE_SEARCH = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi"
BASE_FETCH = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi"

# 25종 원료: slug → PubMed 검색 쿼리
INGREDIENTS = [
    ("vitamin-d",    '"vitamin D"[MeSH] AND "meta-analysis"[pt] AND supplement'),
    ("vitamin-c",    '"ascorbic acid"[MeSH] AND "meta-analysis"[pt] AND supplement AND immune'),
    ("vitamin-b12",  '"vitamin B 12"[MeSH] AND "meta-analysis"[pt] AND supplement'),
    ("folate",       '"folic acid"[MeSH] AND "meta-analysis"[pt] AND (neural tube OR pregnancy)'),
    ("omega-3",      '"fatty acids, omega-3"[MeSH] AND "meta-analysis"[pt] AND supplement'),
    ("magnesium",    '"magnesium"[MeSH] AND "meta-analysis"[pt] AND supplement'),
    ("zinc",         '"zinc"[MeSH] AND "meta-analysis"[pt] AND supplement'),
    ("iron",         '"iron"[MeSH] AND "meta-analysis"[pt] AND supplement AND (anemia OR deficiency)'),
    ("calcium",      '"calcium"[MeSH] AND "meta-analysis"[pt] AND supplement AND bone'),
    ("probiotics",   '"probiotics"[MeSH] AND "meta-analysis"[pt] AND gut'),
    ("lutein",       '"lutein"[MeSH] AND ("meta-analysis"[pt] OR "systematic review"[pt])'),
    ("coq10",        '"ubiquinone"[MeSH] AND ("meta-analysis"[pt] OR "systematic review"[pt])'),
    ("milk-thistle", '"silymarin"[MeSH] AND ("meta-analysis"[pt] OR "systematic review"[pt] OR "randomized controlled trial"[pt])'),
    ("glucosamine",  '"glucosamine"[MeSH] AND "meta-analysis"[pt]'),
    ("biotin",       '"biotin"[MeSH] AND ("meta-analysis"[pt] OR "systematic review"[pt] OR "randomized controlled trial"[pt])'),
    ("selenium",     '"selenium"[MeSH] AND "meta-analysis"[pt] AND supplement'),
    ("vitamin-a",    '"vitamin A"[MeSH] AND "meta-analysis"[pt] AND supplement AND (child OR mortality)'),
    ("vitamin-e",    '"vitamin E"[MeSH] AND "meta-analysis"[pt] AND supplement AND (cardiovascular OR mortality)'),
    ("curcumin",     '"curcumin"[MeSH] AND "meta-analysis"[pt]'),
    ("melatonin",    '"melatonin"[MeSH] AND "meta-analysis"[pt] AND sleep'),
    ("red-ginseng",  '("panax"[MeSH] OR "red ginseng") AND ("meta-analysis"[pt] OR "systematic review"[pt])'),
    ("msm",          '("methylsulfonylmethane" OR "MSM") AND ("meta-analysis"[pt] OR "systematic review"[pt] OR "randomized controlled trial"[pt])'),
    ("garcinia",     '"garcinia"[MeSH] AND ("meta-analysis"[pt] OR "systematic review"[pt] OR "randomized controlled trial"[pt])'),
    ("collagen",     '"collagen" AND ("meta-analysis"[pt] OR "systematic review"[pt]) AND supplement AND (skin OR joint)'),
    ("creatine",     '"creatine"[MeSH] AND "meta-analysis"[pt]'),
]

# 원료별 주요 결과지표 매핑
OUTCOME_MAP = {
    "vitamin-d":    {"name": "골밀도 및 골절 위험",        "type": "efficacy", "dir": "positive", "summary": "비타민 D 보충이 골밀도 유지 및 골절 위험 감소에 기여"},
    "vitamin-c":    {"name": "감기 이환 기간 및 빈도",     "type": "efficacy", "dir": "positive", "summary": "비타민 C 보충이 감기 지속 기간 단축에 소폭 기여"},
    "vitamin-b12":  {"name": "혈중 B12 수치 및 빈혈 개선", "type": "efficacy", "dir": "positive", "summary": "B12 보충이 결핍군에서 혈중 수치 및 빈혈 지표 개선"},
    "folate":       {"name": "신경관 결손 예방",           "type": "efficacy", "dir": "positive", "summary": "엽산 보충이 신경관 결손 위험을 유의하게 감소"},
    "omega-3":      {"name": "혈중 중성지방 감소",         "type": "efficacy", "dir": "positive", "summary": "오메가-3 보충이 혈중 중성지방을 유의하게 감소"},
    "magnesium":    {"name": "혈압 감소 효과",             "type": "efficacy", "dir": "positive", "summary": "마그네슘 보충이 수축기/이완기 혈압을 소폭 감소"},
    "zinc":         {"name": "감기 증상 완화",             "type": "efficacy", "dir": "positive", "summary": "아연 보충이 감기 지속 기간 단축에 효과적"},
    "iron":         {"name": "빈혈 개선 및 헤모글로빈",    "type": "efficacy", "dir": "positive", "summary": "철분 보충이 철 결핍성 빈혈에서 헤모글로빈 수치를 유의하게 개선"},
    "calcium":      {"name": "골밀도 유지",                "type": "efficacy", "dir": "positive", "summary": "칼슘 보충이 폐경 후 여성에서 골밀도 감소 완화에 기여"},
    "probiotics":   {"name": "장 건강 및 소화 기능",       "type": "efficacy", "dir": "positive", "summary": "프로바이오틱스가 항생제 관련 설사 및 장 기능 개선에 효과적"},
    "lutein":       {"name": "황반 색소 밀도 개선",        "type": "efficacy", "dir": "positive", "summary": "루테인 보충이 황반 색소 밀도 증가 및 시각 기능 개선에 기여"},
    "coq10":        {"name": "심부전 증상 개선",           "type": "efficacy", "dir": "positive", "summary": "CoQ10 보충이 심부전 환자의 운동 능력 및 증상 개선에 기여"},
    "milk-thistle": {"name": "간 기능 지표 개선",          "type": "efficacy", "dir": "positive", "summary": "실리마린이 간 효소(ALT, AST) 수치 개선에 기여"},
    "glucosamine":  {"name": "관절 통증 및 기능 개선",     "type": "efficacy", "dir": "positive", "summary": "글루코사민이 골관절염 환자의 통증 감소에 소폭 기여"},
    "biotin":       {"name": "모발 및 손톱 건강",          "type": "efficacy", "dir": "neutral",  "summary": "비오틴 결핍 시 효과가 있으나, 정상 수치에서는 추가 효과 제한적"},
    "selenium":     {"name": "항산화 및 갑상선 기능",      "type": "efficacy", "dir": "positive", "summary": "셀레늄 보충이 갑상선 항체 감소 및 항산화 지표 개선에 기여"},
    "vitamin-a":    {"name": "시각 기능 및 면역 지원",     "type": "efficacy", "dir": "positive", "summary": "비타민 A 보충이 결핍 지역 아동의 사망률 감소에 기여"},
    "vitamin-e":    {"name": "항산화 효과",                "type": "efficacy", "dir": "neutral",  "summary": "비타민 E 보충의 만성질환 예방 효과는 제한적, 고용량 주의"},
    "curcumin":     {"name": "항염 효과",                  "type": "efficacy", "dir": "positive", "summary": "커큐민 보충이 CRP 등 염증 지표 감소에 유의한 효과"},
    "melatonin":    {"name": "수면 잠복기 단축",           "type": "efficacy", "dir": "positive", "summary": "멜라토닌이 수면 잠복기 단축 및 수면 질 개선에 효과적"},
    "red-ginseng":  {"name": "면역 기능 및 피로 개선",     "type": "efficacy", "dir": "positive", "summary": "홍삼이 면역 세포 활성화 및 피로 감소에 기여"},
    "msm":          {"name": "관절 통증 감소",             "type": "efficacy", "dir": "positive", "summary": "MSM이 골관절염 관절 통증 및 기능 개선에 소폭 기여"},
    "garcinia":     {"name": "체중 및 체지방 감소",        "type": "efficacy", "dir": "neutral",  "summary": "가르시니아(HCA)의 체중 감소 효과는 소규모이며 임상적 유의성 논란"},
    "collagen":     {"name": "피부 탄력 및 관절 건강",     "type": "efficacy", "dir": "positive", "summary": "콜라겐 펩타이드 보충이 피부 탄력 개선 및 관절 통증 감소에 기여"},
    "creatine":     {"name": "근력 및 운동 수행능력",      "type": "efficacy", "dir": "positive", "summary": "크레아틴 보충이 고강도 운동 시 근력 및 파워 출력 향상에 효과적"},
}


def search_pubmed(query, retmax=5):
    params = urllib.parse.urlencode({
        "db": "pubmed", "term": query, "retmax": retmax,
        "sort": "relevance", "api_key": API_KEY, "retmode": "json",
    })
    url = f"{BASE_SEARCH}?{params}"
    try:
        with urllib.request.urlopen(url, timeout=15) as resp:
            data = json.loads(resp.read().decode())
            return data.get("esearchresult", {}).get("idlist", [])
    except Exception as e:
        print(f"  [ERROR] esearch: {e}")
        return []


def fetch_articles(pmids):
    if not pmids:
        return {}
    params = urllib.parse.urlencode({
        "db": "pubmed", "id": ",".join(pmids),
        "retmode": "xml", "api_key": API_KEY,
    })
    url = f"{BASE_FETCH}?{params}"
    try:
        with urllib.request.urlopen(url, timeout=30) as resp:
            xml_data = resp.read().decode()
    except Exception as e:
        print(f"  [ERROR] efetch: {e}")
        return {}

    results = {}
    root = ET.fromstring(xml_data)

    for elem in root.findall(".//PubmedArticle"):
        medline = elem.find(".//MedlineCitation")
        if medline is None:
            continue
        pmid_el = medline.find("PMID")
        if pmid_el is None:
            continue
        pmid = pmid_el.text

        article = medline.find("Article")
        if article is None:
            continue

        title_el = article.find("ArticleTitle")
        title = "".join(title_el.itertext()).strip() if title_el is not None else ""

        abstract_el = article.find(".//Abstract")
        abstract = ""
        if abstract_el is not None:
            parts = []
            for at in abstract_el.findall("AbstractText"):
                label = at.get("Label", "")
                text = "".join(at.itertext()).strip()
                parts.append(f"{label}: {text}" if label else text)
            abstract = " ".join(parts)

        authors_list = []
        al = article.find("AuthorList")
        if al is not None:
            for au in al.findall("Author"):
                last = au.find("LastName")
                fore = au.find("ForeName")
                if last is not None:
                    n = last.text or ""
                    if fore is not None and fore.text:
                        n += f" {fore.text}"
                    authors_list.append(n)
        authors = ", ".join(authors_list[:5])
        if len(authors_list) > 5:
            authors += " et al."

        journal_el = article.find(".//Journal/Title")
        journal = (journal_el.text or "") if journal_el is not None else ""

        pub_date = article.find(".//Journal/JournalIssue/PubDate")
        year = None
        if pub_date is not None:
            ye = pub_date.find("Year")
            if ye is not None and ye.text:
                year = int(ye.text)

        doi = ""
        aid_list = elem.find(".//PubmedData/ArticleIdList")
        if aid_list is not None:
            for aid in aid_list.findall("ArticleId"):
                if aid.get("IdType") == "doi":
                    doi = aid.text or ""
                    break

        pub_types = [pt.text.lower() for pt in article.findall(".//PublicationTypeList/PublicationType") if pt.text]
        if "meta-analysis" in pub_types:
            design = "meta_analysis"
        elif "systematic review" in pub_types:
            design = "systematic_review"
        elif "randomized controlled trial" in pub_types:
            design = "rct"
        else:
            design = "systematic_review"

        results[pmid] = {
            "title": title, "abstract": abstract, "authors": authors,
            "journal": journal, "year": year, "doi": doi, "design": design,
        }
    return results


def esc(s):
    if s is None:
        return "NULL"
    return "'" + str(s).replace("'", "''") + "'"


def main():
    print(f"PubMed 논문 수집 v2 ({len(INGREDIENTS)}종 원료, 중복 방지)")
    print("=" * 60)

    used_pmids = set()
    collected = {}  # slug -> [(pmid, article_dict), ...]
    all_fetch_pmids = []

    # Phase 1: Search and select unique PMIDs
    for i, (slug, query) in enumerate(INGREDIENTS, 1):
        print(f"[{i:2d}/{len(INGREDIENTS)}] {slug}...", end=" ", flush=True)
        candidates = search_pubmed(query, retmax=8)
        unique = [p for p in candidates if p not in used_pmids][:2]
        if len(unique) < 2:
            print(f"WARNING: only {len(unique)} unique PMIDs")
        used_pmids.update(unique)
        collected[slug] = unique
        all_fetch_pmids.extend(unique)
        print(f"PMIDs={unique}")
        time.sleep(0.35)

    # Phase 2: Batch fetch all articles
    print("\nFetching article details...", flush=True)
    all_articles = {}
    # Fetch in batches of 20
    for batch_start in range(0, len(all_fetch_pmids), 20):
        batch = all_fetch_pmids[batch_start:batch_start+20]
        arts = fetch_articles(batch)
        all_articles.update(arts)
        time.sleep(0.35)
    print(f"Fetched {len(all_articles)} articles")

    # Phase 3: Generate SQL
    lines = []
    lines.append("-- ============================================================================")
    lines.append("-- 논문 근거 시드 데이터 — 009_seed_evidence.sql")
    lines.append("-- Version: 1.0.0")
    lines.append(f"-- 생성일: {datetime.now().strftime('%Y-%m-%d')}")
    lines.append("-- 대상: 25종 원료별 메타분석/체계적 문헌고찰 2건씩 (PubMed)")
    lines.append("-- 주의: 001_schema.sql + 003_seed_data.sql + 005_seed_supplementary.sql 이후 실행")
    lines.append("-- ============================================================================")
    lines.append("")
    lines.append("-- ============================================================================")
    lines.append("-- SECTION 1: evidence_studies (논문 메타데이터)")
    lines.append("-- ============================================================================")
    lines.append("")

    study_count = 0
    outcome_data = []  # (pmid, outcome_map_entry)

    for slug, pmids in collected.items():
        lines.append(f"-- ── {slug} ──")
        for pmid in pmids:
            art = all_articles.get(pmid)
            if not art:
                lines.append(f"-- PMID {pmid}: fetch 실패")
                continue

            study_count += 1
            abstract_trunc = art["abstract"][:3000] if art["abstract"] else None
            year_val = art["year"] if art["year"] else "NULL"
            doi_val = esc(art["doi"]) if art["doi"] else "NULL"

            lines.append(f"""INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='{slug}'),
  'pubmed', {esc(art['title'])}, {esc(abstract_trunc)}, {esc(art['authors'])}, {esc(art['journal'])},
  {year_val}, '{pmid}', {doi_val}, {esc(f'https://pubmed.ncbi.nlm.nih.gov/{pmid}/')}, {esc(art['design'])},
  'included', true
)
ON CONFLICT DO NOTHING;""")
            lines.append("")

            if slug in OUTCOME_MAP:
                outcome_data.append((pmid, OUTCOME_MAP[slug]))

    # SECTION 2: evidence_outcomes
    lines.append("")
    lines.append("-- ============================================================================")
    lines.append("-- SECTION 2: evidence_outcomes (결과지표)")
    lines.append("-- ============================================================================")
    lines.append("")

    for pmid, om in outcome_data:
        lines.append(f"""INSERT INTO evidence_outcomes (
  evidence_study_id, outcome_name, outcome_type, effect_direction, conclusion_summary
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='{pmid}' LIMIT 1),
  {esc(om['name'])}, {esc(om['type'])}, {esc(om['dir'])}, {esc(om['summary'])}
)
ON CONFLICT DO NOTHING;""")
        lines.append("")

    lines.append(f"-- ============================================================================")
    lines.append(f"-- 총 evidence_studies: {study_count}건")
    lines.append(f"-- 총 evidence_outcomes: {len(outcome_data)}건")
    lines.append(f"-- ============================================================================")

    sql = "\n".join(lines)
    with open("db/009_seed_evidence.sql", "w", encoding="utf-8") as f:
        f.write(sql)

    print(f"\n총 {study_count} studies, {len(outcome_data)} outcomes")
    print("db/009_seed_evidence.sql 생성 완료")


if __name__ == "__main__":
    main()
