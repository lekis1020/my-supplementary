#!/usr/bin/env node
/**
 * Cafe24 쇼핑몰 스크레이퍼 (Firecrawl 기반).
 *
 * 사용법:
 *   cd web
 *   node scripts/scrape_cafe24.mjs --store=gnmart.co.kr --cate=328 --limit=20
 *   node scripts/scrape_cafe24.mjs --store=gnmart.co.kr --cate=328 --dry-run
 */

import { createClient } from "@supabase/supabase-js";
import { loadEnv, requireEnv } from "./lib/env.mjs";
import { fetchImage, buildKey, uploadToR2, getPublicUrl } from "./lib/r2-mirror.mjs";
import { cropNutritionLabel } from "./lib/image-crop.mjs";
import pkg from "@mendable/firecrawl-js";

const FirecrawlApp = pkg.default || pkg;

// ── CLI 인자 ────────────────────────────────────────────────────────────────
const args = Object.fromEntries(
  process.argv.slice(2).map((a) => {
    const [k, v] = a.replace(/^--/, "").split("=");
    return [k, v ?? true];
  }),
);

const STORE = args.store ?? "gnmart.co.kr";
const CATE_NO = args.cate ?? "328";
const LIMIT = Number(args.limit ?? 50);
const DRY_RUN = args["dry-run"] === true;
const PAGES = Number(args.pages ?? 10);

// ── 초기화 ─────────────────────────────────────────────────────────────────
loadEnv();
requireEnv("NEXT_PUBLIC_SUPABASE_URL", "SUPABASE_SERVICE_ROLE_KEY", "FIRECRAWL_API_KEY");
if (!DRY_RUN) requireEnv("R2_ACCOUNT_ID", "R2_ACCESS_KEY_ID", "R2_SECRET_ACCESS_KEY", "R2_BUCKET");

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY,
  { auth: { persistSession: false } },
);
const fc = new FirecrawlApp({ apiKey: process.env.FIRECRAWL_API_KEY });

// ── Bigram 매칭 (ckdhc와 동일) ─────────────────────────────────────────────
function bigrams(s) {
  const clean = s.replace(/\s+/g, "").toLowerCase();
  const grams = new Set();
  for (let i = 0; i < clean.length - 1; i++) grams.add(clean.slice(i, i + 2));
  return grams;
}

function jaccard(a, b) {
  const setA = bigrams(a);
  const setB = bigrams(b);
  const inter = new Set([...setA].filter((x) => setB.has(x)));
  const union = new Set([...setA, ...setB]);
  return union.size === 0 ? 0 : inter.size / union.size;
}

function findBestMatch(shopName, dbProducts) {
  let best = null;
  let bestScore = 0;
  const cleaned = shopName.replace(/\[.*?\]/g, "").replace(/\(.*?\)/g, "").replace(/\d+(박스|개월|정|포|캡슐|개|세트)/g, "").trim();

  for (const p of dbProducts) {
    const dbName = (p.product_name ?? "").replace(/\(.*?\)/g, "").trim();
    const score = jaccard(cleaned, dbName);
    if (score > bestScore) {
      bestScore = score;
      best = p;
    }
  }
  return { product: best, score: bestScore };
}

// ── 제품 목록 수집 ─────────────────────────────────────────────────────────
async function fetchProductList() {
  const allProducts = [];
  const baseUrl = `https://${STORE}/product/list.html?cate_no=${CATE_NO}`;

  for (let page = 1; page <= PAGES; page++) {
    const result = await fc.v1.scrapeUrl(`${baseUrl}&page=${page}`, {
      formats: ["extract"],
      extract: {
        schema: {
          type: "object",
          properties: {
            products: {
              type: "array",
              items: {
                type: "object",
                properties: {
                  name: { type: "string", description: "product name, exclude 상품명 : prefix" },
                  product_no: { type: "string", description: "product number from detail URL" },
                  price: { type: "string" },
                },
              },
            },
          },
        },
      },
    });

    const products = result.extract?.products || [];
    if (products.length === 0) break;
    allProducts.push(...products);
    console.log(`  page ${page}: ${products.length}건`);
    if (allProducts.length >= LIMIT) break;
  }

  return allProducts.slice(0, LIMIT);
}

// ── 제품 상세 스크레이핑 ───────────────────────────────────────────────────
async function fetchProductDetail(productNo) {
  const url = `https://${STORE}/product/detail.html?product_no=${productNo}&cate_no=${CATE_NO}`;
  const result = await fc.v1.scrapeUrl(url, {
    formats: ["markdown"],
  });

  if (!result.success || !result.markdown) return { images: [] };

  // 마크다운에서 이미지 URL 추출
  const urlPattern = /https?:\/\/[^\s)"']+\.(?:jpg|jpeg|png|webp)/gi;
  const allUrls = [...new Set(result.markdown.match(urlPattern) || [])];

  // 분류: 메인 이미지 vs 상세 이미지
  const mainImages = allUrls.filter((u) => u.includes("/web/product/big/") || u.includes("/web/product/medium/"));

  // 상세 이미지: 공통 배너/프로모션 제외, 제품 고유 상세만
  // - /web/upload/appfiles/ → Cafe24 공통 배너인 경우가 많으므로 제외
  // - speedgabia, /details/ + 제품 관련 키워드 포함만 허용
  // - /editor/, /board/ 내 큰 이미지는 제품 상세 가능
  const detailImages = allUrls.filter(
    (u) =>
      (u.includes("/details/") || u.includes("speedgabia") || u.includes("/editor/")) &&
      !u.includes("icon") && !u.includes("logo") && !u.includes("banner") &&
      !u.includes("btn_") && !u.includes("event_") && !u.includes("brandstory") &&
      !u.includes("main_info") && !u.includes("qr_notice") &&
      !u.includes("/web/product/") && !u.includes("/appfiles/"),
  );

  return { mainImages, detailImages, allUrls };
}

// ── 이미지 업로드 ──────────────────────────────────────────────────────────
async function saveImage(productId, imageUrl, source) {
  try {
    const img = await fetchImage(imageUrl);
    const key = buildKey({ productId, source, hash: img.hash, ext: img.ext });
    const pub = getPublicUrl(key);

    await uploadToR2({ key, buffer: img.buffer, contentType: img.contentType });

    await supabase.from("product_images").upsert(
      {
        product_id: productId,
        source,
        source_url: imageUrl,
        r2_key: key,
        r2_public_url: pub,
        image_hash: img.hash,
        mime_type: img.contentType,
        size_bytes: img.size,
        width: null,
        height: null,
        is_primary: false,
      },
      { onConflict: "product_id,image_hash", ignoreDuplicates: true },
    );

    return pub;
  } catch (e) {
    console.warn(`    이미지 저장 실패: ${e.message}`);
    return null;
  }
}

async function saveLabelImage(productId, imageUrl) {
  try {
    const img = await fetchImage(imageUrl);

    // 라벨 크롭 시도
    let buffer = img.buffer;
    let hash = img.hash;
    const sharp = (await import("sharp")).default;
    const meta = await sharp(img.buffer).metadata();

    if (meta.height > 2000) {
      const crop = await cropNutritionLabel(img.buffer);
      if (crop.cropped) {
        buffer = crop.buffer;
        hash = crop.hash;
      }
    }

    const key = buildKey({ productId, source: "manufacturer_label", hash, ext: img.ext });
    const pub = getPublicUrl(key);

    await uploadToR2({ key, buffer, contentType: img.contentType });

    await supabase.from("product_images").upsert(
      {
        product_id: productId,
        source: "manufacturer_label",
        source_url: imageUrl,
        r2_key: key,
        r2_public_url: pub,
        image_hash: hash,
        mime_type: img.contentType,
        size_bytes: buffer.length,
        is_primary: false,
      },
      { onConflict: "product_id,image_hash", ignoreDuplicates: true },
    );

    return pub;
  } catch (e) {
    console.warn(`    라벨 저장 실패: ${e.message}`);
    return null;
  }
}

// ── 메인 ────────────────────────────────────────────────────────────────────
async function main() {
  console.log(`=== Cafe24 스크레이퍼 (${STORE}) ===`);
  console.log(`  카테고리: ${CATE_NO}, limit: ${LIMIT}, dry-run: ${DRY_RUN}`);

  // 1) DB 제품 로드
  const { data: dbProducts } = await supabase
    .from("products")
    .select("id, product_name, brand_name, product_image_url")
    .eq("is_published", true);
  console.log(`  DB 제품: ${dbProducts?.length}건`);

  // 2) 쇼핑몰 제품 목록 수집
  console.log("\n[1단계] 제품 목록 수집...");
  const shopProducts = await fetchProductList();
  console.log(`  총 ${shopProducts.length}건`);

  // 3) DB 매칭
  console.log("\n[2단계] DB 매칭...");
  const matched = [];
  for (const sp of shopProducts) {
    const { product, score } = findBestMatch(sp.name, dbProducts);
    if (score >= 0.3 && product) {
      matched.push({ shop: sp, db: product, score });
    }
  }
  console.log(`  매칭: ${matched.length}건 (threshold: 0.3)`);

  for (const m of matched) {
    console.log(
      `    [${m.score.toFixed(2)}] "${m.shop.name?.slice(0, 35)}" → #${m.db.id} "${m.db.product_name?.slice(0, 35)}"`,
    );
  }

  if (DRY_RUN) {
    console.log("\nDRY-RUN 모드 — 종료");
    return;
  }

  // 4) 매칭 제품 상세 스크레이핑 + 이미지 업로드
  console.log(`\n[3단계] 상세 스크레이핑 (${matched.length}건)...`);
  let saved = 0;
  let labels = 0;

  for (let i = 0; i < matched.length; i++) {
    const { shop, db } = matched[i];
    const productNo = shop.product_no;
    if (!productNo) continue;

    console.log(`  [${i + 1}/${matched.length}] #${db.id} ${db.product_name?.slice(0, 40)}`);

    const detail = await fetchProductDetail(productNo);

    // 메인 이미지 저장
    if (detail.mainImages?.length > 0) {
      const pub = await saveImage(db.id, detail.mainImages[0], "manufacturer");
      if (pub) {
        saved++;
        // product_image_url 채우기
        if (!db.product_image_url) {
          await supabase.from("products").update({ product_image_url: pub }).eq("id", db.id);
        }
      }
    }

    // 상세 이미지 중 큰 것 → 라벨 후보
    for (const imgUrl of (detail.detailImages || []).slice(0, 3)) {
      const pub = await saveLabelImage(db.id, imgUrl);
      if (pub) labels++;
    }
  }

  console.log(`\n=== 완료 ===`);
  console.log(`  이미지 저장: ${saved}건`);
  console.log(`  라벨 저장: ${labels}건`);
  console.log(`  Firecrawl 크레딧 사용: ~${6 + matched.length}건 (목록 + 상세)`);
}

main().catch((e) => {
  console.error("FATAL:", e);
  process.exit(1);
});
