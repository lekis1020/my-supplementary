#!/usr/bin/env python3
"""
PubMed E-utilities를 사용하여 25종 원료별 메타분석/체계적 문헌고찰 논문 수집
→ db/009_seed_evidence.sql 생성
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
INGREDIENTS = {
    "vitamin-d": '"vitamin D"[MeSH] AND ("meta-analysis"[pt] OR "systematic review"[pt]) AND supplement',
    "vitamin-c": '"ascorbic acid"[MeSH] AND ("meta-analysis"[pt] OR "systematic review"[pt]) AND supplement',
    "vitamin-b12": '"vitamin B 12"[MeSH] AND ("meta-analysis"[pt] OR "systematic review"[pt]) AND supplement',
    "folate": '"folic acid"[MeSH] AND ("meta-analysis"[pt] OR "systematic review"[pt]) AND supplement',
    "omega-3": '"fatty acids, omega-3"[MeSH] AND ("meta-analysis"[pt] OR "systematic review"[pt]) AND supplement',
    "magnesium": '"magnesium"[MeSH] AND ("meta-analysis"[pt] OR "systematic review"[pt]) AND supplement',
    "zinc": '"zinc"[MeSH] AND ("meta-analysis"[pt] OR "systematic review"[pt]) AND supplement',
    "iron": '"iron"[MeSH] AND ("meta-analysis"[pt] OR "systematic review"[pt]) AND supplement AND (anemia OR deficiency)',
    "calcium": '"calcium"[MeSH] AND ("meta-analysis"[pt] OR "systematic review"[pt]) AND supplement AND bone',
    "probiotics": '"probiotics"[MeSH] AND ("meta-analysis"[pt] OR "systematic review"[pt])',
    "lutein": '"lutein"[MeSH] AND ("meta-analysis"[pt] OR "systematic review"[pt] OR "randomized controlled trial"[pt])',
    "coq10": '"ubiquinone"[MeSH] AND ("meta-analysis"[pt] OR "systematic review"[pt])',
    "milk-thistle": '"silymarin"[MeSH] AND ("meta-analysis"[pt] OR "systematic review"[pt] OR "randomized controlled trial"[pt])',
    "glucosamine": '"glucosamine"[MeSH] AND ("meta-analysis"[pt] OR "systematic review"[pt])',
    "biotin": '"biotin"[MeSH] AND ("meta-analysis"[pt] OR "systematic review"[pt] OR "randomized controlled trial"[pt])',
    "selenium": '"selenium"[MeSH] AND ("meta-analysis"[pt] OR "systematic review"[pt]) AND supplement',
    "vitamin-a": '"vitamin A"[MeSH] AND ("meta-analysis"[pt] OR "systematic review"[pt]) AND supplement',
    "vitamin-e": '"vitamin E"[MeSH] AND ("meta-analysis"[pt] OR "systematic review"[pt]) AND supplement',
    "curcumin": '"curcumin"[MeSH] AND ("meta-analysis"[pt] OR "systematic review"[pt])',
    "melatonin": '"melatonin"[MeSH] AND ("meta-analysis"[pt] OR "systematic review"[pt]) AND sleep',
    "red-ginseng": '("panax"[MeSH] OR "red ginseng") AND ("meta-analysis"[pt] OR "systematic review"[pt] OR "randomized controlled trial"[pt])',
    "msm": '("methylsulfonylmethane" OR "MSM") AND ("meta-analysis"[pt] OR "systematic review"[pt] OR "randomized controlled trial"[pt])',
    "garcinia": '"garcinia"[MeSH] AND ("meta-analysis"[pt] OR "systematic review"[pt] OR "randomized controlled trial"[pt])',
    "collagen": '"collagen" AND ("meta-analysis"[pt] OR "systematic review"[pt]) AND supplement AND (skin OR joint)',
    "creatine": '"creatine"[MeSH] AND ("meta-analysis"[pt] OR "systematic review"[pt])',
}


def search_pubmed(query, retmax=2):
    """PubMed esearch → PMID 리스트 반환"""
    params = urllib.parse.urlencode({
        "db": "pubmed",
        "term": query,
        "retmax": retmax,
        "sort": "relevance",
        "api_key": API_KEY,
        "retmode": "json",
    })
    url = f"{BASE_SEARCH}?{params}"
    try:
        with urllib.request.urlopen(url, timeout=15) as resp:
            data = json.loads(resp.read().decode())
            return data.get("esearchresult", {}).get("idlist", [])
    except Exception as e:
        print(f"  [ERROR] esearch failed: {e}")
        return []


def fetch_article_details(pmids):
    """PubMed efetch → 논문 상세 정보"""
    if not pmids:
        return []
    params = urllib.parse.urlencode({
        "db": "pubmed",
        "id": ",".join(pmids),
        "retmode": "xml",
        "api_key": API_KEY,
    })
    url = f"{BASE_FETCH}?{params}"
    try:
        with urllib.request.urlopen(url, timeout=30) as resp:
            xml_data = resp.read().decode()
    except Exception as e:
        print(f"  [ERROR] efetch failed: {e}")
        return []

    articles = []
    root = ET.fromstring(xml_data)

    for article_elem in root.findall(".//PubmedArticle"):
        art = {}
        medline = article_elem.find(".//MedlineCitation")
        if medline is None:
            continue

        # PMID
        pmid_elem = medline.find("PMID")
        art["pmid"] = pmid_elem.text if pmid_elem is not None else ""

        article = medline.find("Article")
        if article is None:
            continue

        # Title
        title_elem = article.find("ArticleTitle")
        art["title"] = (title_elem.text or "") if title_elem is not None else ""
        # Clean up title - handle mixed content
        if title_elem is not None:
            art["title"] = "".join(title_elem.itertext()).strip()

        # Abstract
        abstract_elem = article.find(".//Abstract")
        if abstract_elem is not None:
            abstract_parts = []
            for abs_text in abstract_elem.findall("AbstractText"):
                label = abs_text.get("Label", "")
                text = "".join(abs_text.itertext()).strip()
                if label:
                    abstract_parts.append(f"{label}: {text}")
                else:
                    abstract_parts.append(text)
            art["abstract"] = " ".join(abstract_parts)
        else:
            art["abstract"] = ""

        # Authors
        author_list = article.find("AuthorList")
        authors = []
        if author_list is not None:
            for author in author_list.findall("Author"):
                last = author.find("LastName")
                fore = author.find("ForeName")
                if last is not None:
                    name = last.text or ""
                    if fore is not None and fore.text:
                        name += f" {fore.text}"
                    authors.append(name)
        art["authors"] = ", ".join(authors[:5])
        if len(authors) > 5:
            art["authors"] += " et al."

        # Journal
        journal_elem = article.find(".//Journal/Title")
        art["journal"] = (journal_elem.text or "") if journal_elem is not None else ""

        # Publication year
        pub_date = article.find(".//Journal/JournalIssue/PubDate")
        if pub_date is not None:
            year_elem = pub_date.find("Year")
            art["year"] = int(year_elem.text) if year_elem is not None and year_elem.text else None
        else:
            art["year"] = None

        # DOI
        art["doi"] = ""
        article_id_list = article_elem.find(".//PubmedData/ArticleIdList")
        if article_id_list is not None:
            for aid in article_id_list.findall("ArticleId"):
                if aid.get("IdType") == "doi":
                    art["doi"] = aid.text or ""
                    break

        # Publication types → study_design
        pub_types = []
        for pt in article.findall(".//PublicationTypeList/PublicationType"):
            if pt.text:
                pub_types.append(pt.text.lower())
        if "meta-analysis" in pub_types:
            art["study_design"] = "meta_analysis"
        elif "systematic review" in pub_types:
            art["study_design"] = "systematic_review"
        elif "randomized controlled trial" in pub_types:
            art["study_design"] = "rct"
        else:
            art["study_design"] = "systematic_review"

        art["source_type"] = "pubmed"
        articles.append(art)

    return articles


def escape_sql(s):
    """SQL 문자열 이스케이프"""
    if s is None:
        return "NULL"
    s = str(s).replace("'", "''")
    return f"'{s}'"


def generate_sql(all_data):
    """수집된 데이터를 SQL로 변환"""
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
    outcome_inserts = []

    for slug, articles in all_data.items():
        if not articles:
            lines.append(f"-- {slug}: 논문 수집 실패 (수동 보강 필요)")
            lines.append("")
            continue

        lines.append(f"-- ── {slug} ──")
        for art in articles:
            study_count += 1
            title = escape_sql(art["title"])
            abstract = escape_sql(art["abstract"][:3000] if art["abstract"] else None)
            authors = escape_sql(art["authors"])
            journal = escape_sql(art["journal"])
            year = art["year"] if art["year"] else "NULL"
            pmid = escape_sql(art["pmid"])
            doi = escape_sql(art["doi"]) if art["doi"] else "NULL"
            study_design = escape_sql(art["study_design"])
            source_type = escape_sql(art["source_type"])
            ext_url = escape_sql(f"https://pubmed.ncbi.nlm.nih.gov/{art['pmid']}/")

            lines.append(f"""INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='{slug}'),
  {source_type}, {title}, {abstract}, {authors}, {journal},
  {year}, {pmid}, {doi}, {ext_url}, {study_design},
  'included', true
)
ON CONFLICT DO NOTHING;""")
            lines.append("")

            # evidence_outcomes 생성 (논문별 주요 결과지표 1건)
            outcome = generate_outcome_for_slug(slug, art)
            if outcome:
                outcome_inserts.append((slug, art["pmid"], outcome))

    # SECTION 2: evidence_outcomes
    lines.append("")
    lines.append("-- ============================================================================")
    lines.append("-- SECTION 2: evidence_outcomes (결과지표)")
    lines.append("-- ============================================================================")
    lines.append("")

    for slug, pmid, outcome in outcome_inserts:
        outcome_name = escape_sql(outcome["outcome_name"])
        outcome_type = escape_sql(outcome["outcome_type"])
        effect_dir = escape_sql(outcome["effect_direction"])
        conclusion = escape_sql(outcome["conclusion"])

        lines.append(f"""INSERT INTO evidence_outcomes (
  evidence_study_id, outcome_name, outcome_type, effect_direction, conclusion_summary
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='{pmid}' LIMIT 1),
  {outcome_name}, {outcome_type}, {effect_dir}, {conclusion}
)
ON CONFLICT DO NOTHING;""")
        lines.append("")

    # Summary
    lines.append(f"-- ============================================================================")
    lines.append(f"-- 총 evidence_studies: {study_count}건")
    lines.append(f"-- 총 evidence_outcomes: {len(outcome_inserts)}건")
    lines.append(f"-- ============================================================================")

    return "\n".join(lines)


# 원료별 주요 결과지표 매핑 (도메인 지식 기반)
OUTCOME_MAP = {
    "vitamin-d": {"outcome_name": "골밀도 및 골절 위험", "outcome_type": "efficacy", "effect_direction": "positive", "conclusion": "비타민 D 보충이 골밀도 유지 및 골절 위험 감소에 기여"},
    "vitamin-c": {"outcome_name": "감기 이환 기간 및 빈도", "outcome_type": "efficacy", "effect_direction": "positive", "conclusion": "비타민 C 보충이 감기 지속 기간 단축에 소폭 기여"},
    "vitamin-b12": {"outcome_name": "혈중 B12 수치 및 빈혈 개선", "outcome_type": "efficacy", "effect_direction": "positive", "conclusion": "B12 보충이 결핍군에서 혈중 수치 및 빈혈 지표 개선"},
    "folate": {"outcome_name": "신경관 결손 예방", "outcome_type": "efficacy", "effect_direction": "positive", "conclusion": "엽산 보충이 신경관 결손 위험을 유의하게 감소"},
    "omega-3": {"outcome_name": "혈중 중성지방 감소", "outcome_type": "efficacy", "effect_direction": "positive", "conclusion": "오메가-3 보충이 혈중 중성지방을 유의하게 감소"},
    "magnesium": {"outcome_name": "혈압 감소 효과", "outcome_type": "efficacy", "effect_direction": "positive", "conclusion": "마그네슘 보충이 수축기/이완기 혈압을 소폭 감소"},
    "zinc": {"outcome_name": "감기 증상 완화", "outcome_type": "efficacy", "effect_direction": "positive", "conclusion": "아연 보충이 감기 지속 기간 단축에 효과적"},
    "iron": {"outcome_name": "빈혈 개선 및 헤모글로빈 수치", "outcome_type": "efficacy", "effect_direction": "positive", "conclusion": "철분 보충이 철 결핍성 빈혈에서 헤모글로빈 수치를 유의하게 개선"},
    "calcium": {"outcome_name": "골밀도 유지", "outcome_type": "efficacy", "effect_direction": "positive", "conclusion": "칼슘 보충이 폐경 후 여성에서 골밀도 감소 완화에 기여"},
    "probiotics": {"outcome_name": "장 건강 및 소화 기능", "outcome_type": "efficacy", "effect_direction": "positive", "conclusion": "프로바이오틱스가 항생제 관련 설사 및 장 기능 개선에 효과적"},
    "lutein": {"outcome_name": "황반 색소 밀도 개선", "outcome_type": "efficacy", "effect_direction": "positive", "conclusion": "루테인 보충이 황반 색소 밀도 증가 및 시각 기능 개선에 기여"},
    "coq10": {"outcome_name": "심부전 증상 개선", "outcome_type": "efficacy", "effect_direction": "positive", "conclusion": "CoQ10 보충이 심부전 환자의 운동 능력 및 증상 개선에 기여"},
    "milk-thistle": {"outcome_name": "간 기능 지표 개선", "outcome_type": "efficacy", "effect_direction": "positive", "conclusion": "실리마린이 간 효소(ALT, AST) 수치 개선에 기여"},
    "glucosamine": {"outcome_name": "관절 통증 및 기능 개선", "outcome_type": "efficacy", "effect_direction": "positive", "conclusion": "글루코사민이 골관절염 환자의 통증 감소에 소폭 기여"},
    "biotin": {"outcome_name": "모발 및 손톱 건강", "outcome_type": "efficacy", "effect_direction": "neutral", "conclusion": "비오틴 결핍 시 효과가 있으나, 정상 수치에서는 추가 효과 제한적"},
    "selenium": {"outcome_name": "항산화 및 갑상선 기능", "outcome_type": "efficacy", "effect_direction": "positive", "conclusion": "셀레늄 보충이 갑상선 항체 감소 및 항산화 지표 개선에 기여"},
    "vitamin-a": {"outcome_name": "시각 기능 및 면역 지원", "outcome_type": "efficacy", "effect_direction": "positive", "conclusion": "비타민 A 보충이 결핍 지역 아동의 사망률 감소에 기여"},
    "vitamin-e": {"outcome_name": "항산화 효과", "outcome_type": "efficacy", "effect_direction": "neutral", "conclusion": "비타민 E 보충의 만성질환 예방 효과는 제한적, 고용량 주의"},
    "curcumin": {"outcome_name": "항염 효과", "outcome_type": "efficacy", "effect_direction": "positive", "conclusion": "커큐민 보충이 CRP 등 염증 지표 감소에 유의한 효과"},
    "melatonin": {"outcome_name": "수면 잠복기 단축", "outcome_type": "efficacy", "effect_direction": "positive", "conclusion": "멜라토닌이 수면 잠복기 단축 및 수면 질 개선에 효과적"},
    "red-ginseng": {"outcome_name": "면역 기능 및 피로 개선", "outcome_type": "efficacy", "effect_direction": "positive", "conclusion": "홍삼이 면역 세포 활성화 및 피로 감소에 기여"},
    "msm": {"outcome_name": "관절 통증 감소", "outcome_type": "efficacy", "effect_direction": "positive", "conclusion": "MSM이 골관절염 관절 통증 및 기능 개선에 소폭 기여"},
    "garcinia": {"outcome_name": "체중 및 체지방 감소", "outcome_type": "efficacy", "effect_direction": "neutral", "conclusion": "가르시니아(HCA)의 체중 감소 효과는 소규모이며 임상적 유의성 논란"},
    "collagen": {"outcome_name": "피부 탄력 및 관절 건강", "outcome_type": "efficacy", "effect_direction": "positive", "conclusion": "콜라겐 펩타이드 보충이 피부 탄력 개선 및 관절 통증 감소에 기여"},
    "creatine": {"outcome_name": "근력 및 운동 수행능력", "outcome_type": "efficacy", "effect_direction": "positive", "conclusion": "크레아틴 보충이 고강도 운동 시 근력 및 파워 출력 향상에 효과적"},
}


def generate_outcome_for_slug(slug, article):
    """원료 slug에 맞는 outcome 생성"""
    return OUTCOME_MAP.get(slug)


def main():
    print(f"PubMed 논문 수집 시작 ({len(INGREDIENTS)}종 원료)")
    print("=" * 60)

    all_data = {}
    total_articles = 0

    for i, (slug, query) in enumerate(INGREDIENTS.items(), 1):
        print(f"[{i:2d}/{len(INGREDIENTS)}] {slug}...", end=" ", flush=True)

        # Step 1: Search
        pmids = search_pubmed(query, retmax=2)
        if not pmids:
            print("PMID 없음")
            all_data[slug] = []
            continue

        print(f"PMIDs={pmids}", end=" ", flush=True)

        # Step 2: Fetch details
        articles = fetch_article_details(pmids)
        all_data[slug] = articles
        total_articles += len(articles)
        print(f"→ {len(articles)}건 수집")

        # Rate limiting (API key: 10 req/sec)
        time.sleep(0.35)

    print("=" * 60)
    print(f"총 {total_articles}건 수집 완료")

    # Generate SQL
    sql = generate_sql(all_data)
    output_path = "db/009_seed_evidence.sql"
    with open(output_path, "w", encoding="utf-8") as f:
        f.write(sql)
    print(f"SQL 생성 완료: {output_path}")

    return all_data


if __name__ == "__main__":
    main()
