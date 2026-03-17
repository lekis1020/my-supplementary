#!/usr/bin/env node
/**
 * DailyMed API v2를 사용하여 US 보충제 라벨 데이터 수집
 * → label_snapshots SQL 생성 + 콘솔 리포트
 *
 * 사용법: node scripts/fetch_dailymed_labels.mjs
 * 출력:   db/011_seed_dailymed_labels.sql
 */

import { writeFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const OUTPUT_PATH = path.join(__dirname, "..", "db", "011_seed_dailymed_labels.sql");

const BASE_URL = "https://dailymed.nlm.nih.gov/dailymed/services/v2";

// US 제품 15개 (008_seed_products_additional.sql 기준) + 003 기존 4개
const US_PRODUCTS = [
  // 008 US 제품
  { dbName: "NOW Vitamin D3 5000 IU", searchTerm: "vitamin d3 5000", brand: "NOW" },
  { dbName: "Citracal Calcium Citrate + D3", searchTerm: "citracal calcium", brand: "Citracal" },
  { dbName: "Doctor's Best Magnesium Glycinate 400mg", searchTerm: "magnesium glycinate", brand: "Doctor" },
  { dbName: "Thorne Zinc Picolinate 30mg", searchTerm: "zinc picolinate", brand: "Thorne" },
  { dbName: "Thorne Iron Bisglycinate 25mg", searchTerm: "iron bisglycinate", brand: "Thorne" },
  { dbName: "Nature Made Super B-Complex", searchTerm: "super b-complex", brand: "Nature Made" },
  { dbName: "Nature's Bounty Milk Thistle 250mg", searchTerm: "milk thistle", brand: "Nature" },
  { dbName: "Qunol Ultra CoQ10 200mg", searchTerm: "coq10", brand: "Qunol" },
  { dbName: "Vital Proteins Collagen Peptides", searchTerm: "collagen peptides", brand: "Vital Proteins" },
  { dbName: "Optimum Nutrition Creatine Monohydrate", searchTerm: "creatine monohydrate", brand: "Optimum" },
  { dbName: "Nature Made Turmeric Curcumin 500mg", searchTerm: "turmeric curcumin", brand: "Nature Made" },
  { dbName: "Culturelle Daily Probiotic", searchTerm: "culturelle probiotic", brand: "Culturelle" },
  { dbName: "CheongKwanJang Korean Red Ginseng Extract", searchTerm: "korean red ginseng", brand: "CheongKwanJang" },
  { dbName: "Doctor's Best OptiMSM 1500mg", searchTerm: "optimsm", brand: "Doctor" },
  { dbName: "Nature's Bounty Garcinia Cambogia 1000mg", searchTerm: "garcinia cambogia", brand: "Nature" },
  // 003 US 제품
  { dbName: "솔가 비타민 D3 1000IU", searchTerm: "vitamin d3 1000", brand: "Solgar" },
  { dbName: "나우푸드 오메가-3 1000mg", searchTerm: "omega-3 fish oil", brand: "NOW" },
  { dbName: "네이처메이드 종합비타민", searchTerm: "multivitamin", brand: "Nature Made" },
  { dbName: "GNC 트리플 스트렝스 피쉬오일", searchTerm: "triple strength fish oil", brand: "GNC" },
];

// ── 유틸리티 ──────────────────────────────────────────────────────────────

async function fetchJSON(url) {
  const res = await fetch(url);
  if (!res.ok) {
    throw new Error(`HTTP ${res.status}: ${url}`);
  }
  return res.json();
}

async function fetchText(url) {
  const res = await fetch(url);
  if (!res.ok) {
    throw new Error(`HTTP ${res.status}: ${url}`);
  }
  return res.text();
}

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

function escapeSQL(str) {
  if (!str) return "";
  return str.replace(/'/g, "''").replace(/\n/g, " ").trim();
}

function truncate(str, maxLen = 2000) {
  if (!str) return "";
  return str.length > maxLen ? str.slice(0, maxLen) + "..." : str;
}

// ── HTML에서 텍스트 추출 (간이 파서) ────────────────────────────────────

function stripHTML(html) {
  if (!html) return "";
  return html
    .replace(/<br\s*\/?>/gi, " ")
    .replace(/<\/?(p|div|li|tr|td|th|h\d)[^>]*>/gi, " ")
    .replace(/<[^>]+>/g, "")
    .replace(/&nbsp;/g, " ")
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/\s+/g, " ")
    .trim();
}

// ── DailyMed API 호출 ──────────────────────────────────────────────────

/**
 * DailyMed 보충제 검색
 * @returns {{ setid, title, published_date }[]}
 */
async function searchDailyMed(searchTerm, brand) {
  const params = new URLSearchParams({
    drug_name: searchTerm,
    labeltype: "DIETARY_SUPPLEMENT",
    pagesize: "10",
    page: "1",
  });

  const url = `${BASE_URL}/spls.json?${params}`;
  try {
    const data = await fetchJSON(url);
    const results = data?.data || [];

    // 브랜드명으로 필터링
    if (brand && results.length > 0) {
      const brandLower = brand.toLowerCase();
      const filtered = results.filter((r) =>
        r.title?.toLowerCase().includes(brandLower)
      );
      if (filtered.length > 0) return filtered;
    }

    return results;
  } catch (err) {
    console.error(`  ✗ 검색 실패: ${searchTerm} — ${err.message}`);
    return [];
  }
}

/**
 * SPL 상세 정보 조회 (HTML 라벨 페이지에서 주요 섹션 추출)
 */
async function fetchLabelDetails(setid) {
  const labelUrl = `https://dailymed.nlm.nih.gov/dailymed/drugInfo.cfm?setid=${setid}`;

  try {
    const html = await fetchText(labelUrl);

    // 주요 섹션 추출 (정규식 기반 간이 파서)
    const sections = {};

    // Supplement Facts / Serving Size
    const servingMatch = html.match(
      /Serving\s+Size[:\s]*([^<]+)/i
    );
    sections.servingSize = servingMatch
      ? stripHTML(servingMatch[1]).trim()
      : null;

    const servingsPerMatch = html.match(
      /Servings?\s+Per\s+Container[:\s]*([^<]+)/i
    );
    sections.servingsPerContainer = servingsPerMatch
      ? stripHTML(servingsPerMatch[1]).trim()
      : null;

    // Warnings
    const warningPatterns = [
      /class="[^"]*Warning[^"]*"[^>]*>([\s\S]*?)<\/div>/i,
      /(<h\d[^>]*>.*?Warning.*?<\/h\d>[\s\S]*?)(?=<h\d|<div class="(?!Warning))/i,
      /Warning[s]?:\s*([\s\S]*?)(?=<\/p>|<\/div>|<br\s*\/?>.*?<br\s*\/?>)/i,
    ];
    for (const pattern of warningPatterns) {
      const match = html.match(pattern);
      if (match) {
        sections.warnings = truncate(stripHTML(match[1] || match[0]), 1000);
        break;
      }
    }

    // Directions / Suggested Use
    const directionPatterns = [
      /(?:Directions|Suggested\s+Use|Dosage)[:\s]*([\s\S]*?)(?=<\/p>|<\/div>|Warning|<h\d)/i,
      /class="[^"]*[Dd]irection[^"]*"[^>]*>([\s\S]*?)<\/div>/i,
    ];
    for (const pattern of directionPatterns) {
      const match = html.match(pattern);
      if (match) {
        sections.directions = truncate(stripHTML(match[1] || match[0]), 500);
        break;
      }
    }

    // Ingredients (Other Ingredients 포함)
    const ingredientMatch = html.match(
      /Other\s+Ingredients?[:\s]*([\s\S]*?)(?=<\/p>|<\/div>|Warning|Directions|<h\d)/i
    );
    sections.otherIngredients = ingredientMatch
      ? truncate(stripHTML(ingredientMatch[1]), 500)
      : null;

    // 전체 라벨 텍스트 (간략)
    const bodyMatch = html.match(/<body[^>]*>([\s\S]*?)<\/body>/i);
    if (bodyMatch) {
      sections.rawLabelText = truncate(stripHTML(bodyMatch[1]), 3000);
    }

    sections.sourceUrl = labelUrl;
    return sections;
  } catch (err) {
    console.error(`  ✗ 라벨 조회 실패: ${setid} — ${err.message}`);
    return null;
  }
}

// ── 메인 ────────────────────────────────────────────────────────────────

async function main() {
  console.log("═══════════════════════════════════════════════════════");
  console.log(" DailyMed US 보충제 라벨 수집기");
  console.log(" 대상: US 제품 " + US_PRODUCTS.length + "개");
  console.log("═══════════════════════════════════════════════════════\n");

  const results = [];
  let found = 0;
  let notFound = 0;

  for (const product of US_PRODUCTS) {
    console.log(`▶ ${product.dbName}`);
    console.log(`  검색: "${product.searchTerm}" (brand: ${product.brand})`);

    const matches = await searchDailyMed(product.searchTerm, product.brand);
    await sleep(300); // 예의 바른 rate limiting

    if (matches.length === 0) {
      console.log(`  ✗ 검색 결과 없음\n`);
      notFound++;
      continue;
    }

    const best = matches[0];
    console.log(`  ✓ 매칭: ${best.title} (setid: ${best.setid})`);

    // 라벨 상세 가져오기
    const label = await fetchLabelDetails(best.setid);
    await sleep(500);

    if (label) {
      results.push({
        product,
        setid: best.setid,
        splTitle: best.title,
        publishedDate: best.published_date,
        ...label,
      });
      found++;
      console.log(
        `  ✓ 라벨 수집 완료 (serving: ${label.servingSize || "N/A"})\n`
      );
    } else {
      notFound++;
      console.log(`  ✗ 라벨 파싱 실패\n`);
    }
  }

  // ── SQL 생성 ──────────────────────────────────────────────────────────

  const sqlLines = [
    "-- ============================================================================",
    "-- DailyMed 라벨 데이터 — 011_seed_dailymed_labels.sql",
    "-- Version: 1.0.0",
    `-- 생성일: ${new Date().toISOString().slice(0, 10)}`,
    `-- 수집 건수: ${found}/${US_PRODUCTS.length}`,
    "-- 소스: DailyMed API v2 (https://dailymed.nlm.nih.gov/)",
    "-- 실행 순서: 001 → 003 → 008 → 이 파일(011)",
    "-- ============================================================================",
    "",
  ];

  if (results.length > 0) {
    // label_snapshots INSERT
    sqlLines.push(
      "-- ============================================================================"
    );
    sqlLines.push("-- SECTION 1: US 제품 라벨 스냅샷 (DailyMed 수집)");
    sqlLines.push(
      "-- ============================================================================"
    );
    sqlLines.push("");

    for (const r of results) {
      const productNameEscaped = escapeSQL(r.product.dbName);
      // LIKE 패턴: 처음 10자 사용
      const likePattern = escapeSQL(
        r.product.dbName.length > 15
          ? r.product.dbName.slice(0, 15)
          : r.product.dbName
      ) + "%";

      sqlLines.push(`-- ${r.product.dbName} (DailyMed setid: ${r.setid})`);
      sqlLines.push(
        `INSERT INTO label_snapshots (product_id, label_version, source_name, serving_size_text, servings_per_container, warning_text, directions_text, raw_label_text, is_current) VALUES`
      );
      sqlLines.push(
        `((SELECT id FROM products WHERE product_name LIKE '${likePattern}' LIMIT 1),` +
          ` 'v1',` +
          ` 'DailyMed (${escapeSQL(r.setid)})',` +
          ` '${escapeSQL(r.servingSize || "See label")}',` +
          ` '${escapeSQL(r.servingsPerContainer || "See label")}',` +
          ` '${escapeSQL(truncate(r.warnings || "See product label for complete warnings.", 800))}',` +
          ` '${escapeSQL(truncate(r.directions || "See product label for directions.", 500))}',` +
          ` '${escapeSQL(truncate(r.rawLabelText || "", 2000))}',` +
          ` true)`
      );
      sqlLines.push("ON CONFLICT DO NOTHING;");
      sqlLines.push("");
    }

    // source_links for DailyMed labels
    sqlLines.push(
      "-- ============================================================================"
    );
    sqlLines.push("-- SECTION 2: DailyMed 라벨 → source_links 연결");
    sqlLines.push(
      "-- ============================================================================"
    );
    sqlLines.push("");
    sqlLines.push(
      "-- DailyMed 소스가 없으면 US 제품의 source_links를 DailyMed로 추가"
    );
    sqlLines.push(
      `INSERT INTO source_links (source_id, entity_type, entity_id, source_reference, retrieved_at)`
    );
    sqlLines.push(
      `SELECT (SELECT id FROM sources WHERE source_name = 'DailyMed'),`
    );
    sqlLines.push(`       'label_snapshot', ls.id,`);
    sqlLines.push(
      `       'https://dailymed.nlm.nih.gov/dailymed/drugInfo.cfm?setid=' || SPLIT_PART(ls.source_name, '(', 2),`
    );
    sqlLines.push(`       NOW()`);
    sqlLines.push(
      `FROM label_snapshots ls WHERE ls.source_name LIKE 'DailyMed%';`
    );
    sqlLines.push("");
  }

  // 결과 저장
  const sql = sqlLines.join("\n");
  writeFileSync(OUTPUT_PATH, sql, "utf8");

  // ── 리포트 ────────────────────────────────────────────────────────────

  console.log("\n═══════════════════════════════════════════════════════");
  console.log(" 수집 결과 요약");
  console.log("═══════════════════════════════════════════════════════");
  console.log(` 전체 대상:   ${US_PRODUCTS.length}개`);
  console.log(` 수집 성공:   ${found}개`);
  console.log(` 수집 실패:   ${notFound}개`);
  console.log(` 출력 파일:   ${OUTPUT_PATH}`);
  console.log("═══════════════════════════════════════════════════════\n");

  if (results.length > 0) {
    console.log("수집된 제품 목록:");
    for (const r of results) {
      console.log(
        `  ✓ ${r.product.dbName} → ${r.splTitle?.slice(0, 60)}...`
      );
    }
  }

  if (notFound > 0) {
    console.log("\n미수집 제품:");
    const foundNames = new Set(results.map((r) => r.product.dbName));
    for (const p of US_PRODUCTS) {
      if (!foundNames.has(p.dbName)) {
        console.log(`  ✗ ${p.dbName}`);
      }
    }
  }
}

main().catch((err) => {
  console.error("Fatal error:", err);
  process.exit(1);
});
