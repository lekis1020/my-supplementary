#!/usr/bin/env node
/**
 * 종근당건강 (ckdhc.com) 공식 사이트 스크레이퍼.
 *
 * 제품 상세 페이지에서:
 *   - 메인 이미지 (/upload/images/...)
 *   - 라벨/상세 이미지 (/upload/editor/...) ← 성분표·영양정보 포함
 *
 * DB 매칭:
 *   products.product_name에 '종근당' 포함 + Jaccard bigram 유사도로 최적 매칭.
 *
 * 사용법:
 *   cd web
 *   node scripts/scrape_ckdhc.mjs --limit=10
 *   node scripts/scrape_ckdhc.mjs --dry-run
 */

import * as cheerio from "cheerio";
import { createClient } from "@supabase/supabase-js";
import { loadEnv, requireEnv } from "./lib/env.mjs";
import { fetchImage, buildKey, uploadToR2, getPublicUrl } from "./lib/r2-mirror.mjs";
import { cropNutritionLabel } from "./lib/image-crop.mjs";
import { throttle } from "./lib/naver-client.mjs";

// ── CLI 인자 ────────────────────────────────────────────────────────────────
const args = Object.fromEntries(
  process.argv.slice(2).map((a) => {
    const [k, v] = a.replace(/^--/, "").split("=");
    return [k, v ?? true];
  }),
);
const LIMIT = Number(args.limit ?? 50);
const DRY_RUN = args["dry-run"] === true;
const THROTTLE_MS = Number(args.throttle ?? 1500);

const BASE = "https://www.ckdhc.com";
const UA = "bochoong-scraper/1.0 (+https://bochoong.com/about)";

// ── 초기화 ─────────────────────────────────────────────────────────────────
loadEnv();
requireEnv("NEXT_PUBLIC_SUPABASE_URL", "SUPABASE_SERVICE_ROLE_KEY");
if (!DRY_RUN) requireEnv("R2_ACCOUNT_ID", "R2_ACCESS_KEY_ID", "R2_SECRET_ACCESS_KEY", "R2_BUCKET");

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY,
  { auth: { persistSession: false } },
);

// ── 종근당 사이트 크롤링 ───────────────────────────────────────────────────
async function fetchHtml(url) {
  const res = await fetch(url, { headers: { "User-Agent": UA } });
  if (!res.ok) throw new Error(`HTTP ${res.status}: ${url}`);
  return await res.text();
}

/** 제품 목록 + 범위 열거로 prodCode 수집 */
async function fetchProductCodes() {
  const codes = new Set();

  // 1) 제품 목록 페이지에서 수집
  try {
    const html = await fetchHtml(`${BASE}/product/productList.do?category=`);
    const $ = cheerio.load(html);
    $("a[href*='prodCode=']").each((_, el) => {
      const href = $(el).attr("href") ?? "";
      const m = href.match(/prodCode=([A-Z0-9]+)/);
      if (m) codes.add(m[1]);
    });
  } catch (e) {
    console.warn("  제품 목록 페이지 실패:", e.message);
  }

  // 2) 범위 열거 — CHC0000100~CHC0000270, HL0000100~HL0000200
  const ranges = [
    { prefix: "CHC", start: 100, end: 320 },
    { prefix: "HL", start: 100, end: 200 },
  ];
  for (const { prefix, start, end } of ranges) {
    for (let i = start; i <= end; i++) {
      const code = prefix + String(i).padStart(7, "0");
      if (codes.has(code)) continue;
      try {
        const res = await fetch(`${BASE}/product/productView.do?prodCode=${code}`, {
          headers: { "User-Agent": UA },
          signal: AbortSignal.timeout(5000),
        });
        const html = await res.text();
        if (html.includes("pro_title") && html.includes("/upload/")) {
          codes.add(code);
        }
      } catch {}
      await throttle(200);
    }
  }

  return [...codes];
}

/** 제품 상세 페이지 파싱 — ckdhc.com 전용 셀렉터 */
async function fetchProductDetail(prodCode) {
  const url = `${BASE}/product/productView.do?prodCode=${prodCode}`;
  const html = await fetchHtml(url);
  const $ = cheerio.load(html);

  // 제품명: .pro_title 내 첫 텍스트 노드 (span 앞)
  const proTitle = $(".pro_title");
  let name = "";
  if (proTitle.length) {
    const contents = proTitle.contents();
    for (let i = 0; i < contents.length; i++) {
      const node = contents[i];
      if (node.type === "text") {
        const t = $(node).text().trim();
        if (t) { name = t; break; }
      }
    }
  }
  // 폴백: img alt, title
  if (!name) {
    name = $(".detail_top .img img").attr("alt")?.trim() || "";
  }
  if (!name) {
    name = $("title").text().replace(/종근당건강/g, "").trim();
  }

  // 메인 이미지: .detail_top .img img
  const mainImages = [];
  $(".detail_top .img img").each((_, el) => {
    const src = $(el).attr("src");
    if (src && src.includes("/upload/")) mainImages.push(src);
  });
  // 추가 /upload/images/ (logo 제외)
  $("img[src*='/upload/images/']").each((_, el) => {
    const src = $(el).attr("src");
    if (src && !src.includes("logo") && !mainImages.includes(src)) mainImages.push(src);
  });

  // 라벨/상세 이미지: /upload/editor/ 경로
  const labelImages = [];
  $("img[src*='/upload/editor/']").each((_, el) => {
    const src = $(el).attr("src");
    if (src) labelImages.push(src);
  });
  $("img[data-src*='/upload/editor/']").each((_, el) => {
    const src = $(el).attr("data-src");
    if (src && !labelImages.includes(src)) labelImages.push(src);
  });

  // 용량·주원료 텍스트
  const description = $(".pro_con, .prd_info").text().trim().slice(0, 500);

  return {
    prodCode,
    name,
    url,
    mainImages: [...new Set(mainImages)],
    labelImages: [...new Set(labelImages)],
    description,
  };
}

// ── DB 매칭 (Jaccard bigram) ───────────────────────────────────────────────
function bigrams(s) {
  const clean = s.replace(/\s+/g, "").toLowerCase();
  const grams = new Set();
  for (let i = 0; i < clean.length - 1; i++) grams.add(clean.slice(i, i + 2));
  return grams;
}

function jaccard(a, b) {
  if (a.size === 0 || b.size === 0) return 0;
  let inter = 0;
  for (const g of a) if (b.has(g)) inter++;
  return inter / (a.size + b.size - inter);
}

let _dbProducts = null;
async function getDbProducts() {
  if (_dbProducts) return _dbProducts;
  const { data } = await supabase
    .from("products")
    .select("id, product_name, brand_name")
    .eq("is_published", true)
    .or("product_name.ilike.%종근당%,product_name.ilike.%CKD%,product_name.ilike.%락토핏%,product_name.ilike.%프로메가%,product_name.ilike.%아임비타%,product_name.ilike.%홍삼정%,product_name.ilike.%베르베린%,product_name.ilike.%천관보%,product_name.ilike.%아이클리어%,product_name.ilike.%코어틴%,product_name.ilike.%올앳미%,product_name.ilike.%콜라겐%,product_name.ilike.%오메가3%,product_name.ilike.%멀티비타민%,product_name.ilike.%유산균%,product_name.ilike.%구미젤리%")
    .limit(2000);
  _dbProducts = data ?? [];
  return _dbProducts;
}

async function findBestMatch(ckdhcName) {
  const products = await getDbProducts();
  const nameGrams = bigrams(ckdhcName);

  let best = null;
  let bestScore = 0;

  for (const p of products) {
    const score = jaccard(nameGrams, bigrams(p.product_name));
    if (score > bestScore) {
      bestScore = score;
      best = p;
    }
  }

  return { product: best, score: bestScore };
}

// ── DB 적재 ────────────────────────────────────────────────────────────────
async function saveImages(productId, images, imageType) {
  let saved = 0;
  for (const imgUrl of images) {
    try {
      const fullUrl = imgUrl.startsWith("http") ? imgUrl : `${BASE}${imgUrl}`;
      const img = await fetchImage(fullUrl);

      if (imageType === "label") {
        // 에디터 이미지 → 하단 25% 크롭 (영양정보 영역)
        const crop = await cropNutritionLabel(img.buffer);
        if (crop.cropped) {
          const labelKey = buildKey({ productId, source: "manufacturer_label", hash: crop.hash, ext: "jpg" });
          const labelPub = getPublicUrl(labelKey);
          await uploadToR2({ key: labelKey, buffer: crop.buffer, contentType: "image/jpeg" });
          await supabase.from("product_images").upsert(
            {
              product_id: productId,
              source: "manufacturer_label",
              source_url: fullUrl,
              r2_key: labelKey,
              r2_public_url: labelPub,
              image_hash: crop.hash,
              mime_type: "image/jpeg",
              size_bytes: crop.buffer.length,
              width: crop.width,
              height: crop.height,
              is_primary: false,
            },
            { onConflict: "product_id,image_hash", ignoreDuplicates: true },
          );
          saved++;
          continue;
        }
        // 크롭 불필요(짧은 이미지) → 원본 그대로 저장
      }

      // 메인 이미지 또는 크롭 안 된 라벨 이미지
      const key = buildKey({ productId, source: "manufacturer", hash: img.hash, ext: img.ext });
      const pub = getPublicUrl(key);
      await uploadToR2({ key, buffer: img.buffer, contentType: img.contentType });
      await supabase.from("product_images").upsert(
        {
          product_id: productId,
          source: "manufacturer",
          source_url: fullUrl,
          r2_key: key,
          r2_public_url: pub,
          image_hash: img.hash,
          mime_type: img.contentType,
          size_bytes: img.size,
          is_primary: imageType === "main" && saved === 0,
        },
        { onConflict: "product_id,image_hash", ignoreDuplicates: true },
      );
      saved++;
    } catch (e) {
      console.warn(`    image fetch failed: ${e.message}`);
    }
  }
  return saved;
}

// ── 메인 ───────────────────────────────────────────────────────────────────
async function main() {
  console.log(`[scrape_ckdhc] dry_run=${DRY_RUN} limit=${LIMIT}`);

  const prodCodes = await fetchProductCodes();
  console.log(`  종근당건강 사이트: ${prodCodes.length}개 제품 발견`);

  const targets = prodCodes.slice(0, LIMIT);
  const results = { matched: 0, miss: 0, failed: 0, images_saved: 0, labels_saved: 0 };

  for (let i = 0; i < targets.length; i++) {
    const code = targets[i];
    try {
      const detail = await fetchProductDetail(code);
      if (!detail.name) {
        results.miss++;
        console.log(`  [${i + 1}/${targets.length}] ${code} → skip (이름 추출 실패)`);
        continue;
      }

      const { product, score } = await findBestMatch(detail.name);
      const totalImages = detail.mainImages.length + detail.labelImages.length;

      if (!product || score < 0.35) {
        results.miss++;
        console.log(`  [${i + 1}/${targets.length}] ${code} "${detail.name}" → miss (score=${score.toFixed(3)}, imgs=${totalImages})`);
      } else if (DRY_RUN) {
        results.matched++;
        console.log(`  [${i + 1}/${targets.length}] ${code} "${detail.name}" → DRY match #${product.id} "${product.product_name.slice(0, 30)}" (score=${score.toFixed(3)}, main=${detail.mainImages.length}, label=${detail.labelImages.length})`);
      } else {
        const mainSaved = await saveImages(product.id, detail.mainImages.slice(0, 2), "main");
        const labelSaved = await saveImages(product.id, detail.labelImages, "label");
        results.matched++;
        results.images_saved += mainSaved;
        results.labels_saved += labelSaved;

        // scrape_jobs 기록
        await supabase.from("scrape_jobs").upsert(
          {
            target_type: "product",
            target_id: product.id,
            source: "manufacturer",
            status: "done",
            attempts: 1,
            completed_at: new Date().toISOString(),
            result_summary: {
              ckdhc_code: code,
              ckdhc_name: detail.name,
              score: score.toFixed(3),
              main_images: mainSaved,
              label_images: labelSaved,
            },
          },
          { onConflict: "target_type,target_id,source" },
        );

        console.log(`  [${i + 1}/${targets.length}] ${code} "${detail.name}" → done #${product.id} (main=${mainSaved}, label=${labelSaved})`);
      }
    } catch (e) {
      results.failed++;
      console.error(`  [${i + 1}/${targets.length}] ${code} FAILED: ${e.message}`);
    }

    if (i < targets.length - 1) await throttle(THROTTLE_MS);
  }

  console.log("\n=== Summary ===");
  console.log(JSON.stringify(results, null, 2));
}

main().catch((e) => {
  console.error("Fatal:", e);
  process.exit(1);
});
