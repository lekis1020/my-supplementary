#!/usr/bin/env node
/**
 * Naver Shopping API로 제품 이미지·가격·alias 수집 → R2 미러링 → DB 적재.
 *
 * 대상 선정:
 *   기본: products.product_image_url IS NULL (상위 N개)
 *   --limit=N  (기본 100)
 *   --dry-run  (DB/R2 쓰기 없이 plan만)
 *   --product-id=123  (특정 제품만)
 *
 * 적재 위치:
 *   - product_images (R2에 미러링, 원본 URL은 source_url에 보존)
 *   - product_aliases (Naver title 정규화 variations)
 *   - scrape_jobs (결과 summary)
 *   - products.product_image_url ← R2 공개 URL로 업데이트 (첫 매칭만)
 *
 * 사용법:
 *   cd web
 *   node scripts/scrape_naver_shopping.mjs --limit=50
 *   node scripts/scrape_naver_shopping.mjs --product-id=42 --dry-run
 */

import { createClient } from "@supabase/supabase-js";
import { loadEnv, requireEnv } from "./lib/env.mjs";
import { searchNaverShopping, throttle } from "./lib/naver-client.mjs";
import {
  fetchImage,
  buildKey,
  uploadToR2,
  getPublicUrl,
} from "./lib/r2-mirror.mjs";
import { extractAliasCandidates, deriveBrand, normalize } from "./lib/alias-extractor.mjs";

// ── CLI 인자 파싱 ───────────────────────────────────────────────────────────
const args = Object.fromEntries(
  process.argv.slice(2).map((a) => {
    const [k, v] = a.replace(/^--/, "").split("=");
    return [k, v ?? true];
  }),
);

const LIMIT = Number(args.limit ?? 100);
const DRY_RUN = args["dry-run"] === true;
const PRODUCT_ID = args["product-id"] ? Number(args["product-id"]) : null;
const THROTTLE_MS = Number(args["throttle"] ?? 1100); // 분당 ~50 호출

// ── 초기화 ─────────────────────────────────────────────────────────────────
loadEnv();
requireEnv(
  "NEXT_PUBLIC_SUPABASE_URL",
  "SUPABASE_SERVICE_ROLE_KEY",
  "NAVER_SHOPPING_CLIENT_ID",
  "NAVER_SHOPPING_CLIENT_SECRET",
);
if (!DRY_RUN) {
  requireEnv("R2_ACCOUNT_ID", "R2_ACCESS_KEY_ID", "R2_SECRET_ACCESS_KEY", "R2_BUCKET");
}

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY,
  { auth: { persistSession: false } },
);

// ── 타겟 로드 ──────────────────────────────────────────────────────────────
async function loadTargets() {
  let query = supabase
    .from("products")
    .select("id, product_name, brand_name, manufacturer_name")
    .eq("is_published", true)
    .order("id", { ascending: true });

  if (PRODUCT_ID) {
    query = query.eq("id", PRODUCT_ID);
  } else {
    // product_image_url NULL 우선
    query = query.is("product_image_url", null).limit(LIMIT);
  }

  const { data, error } = await query;
  if (error) throw error;
  return data ?? [];
}

// ── Naver 매칭 후보 선정 ───────────────────────────────────────────────────
function pickBestItem(product, items) {
  const nameNorm = normalize(product.product_name).toLowerCase();
  const brandNorm = normalize(product.brand_name ?? "").toLowerCase();

  // 점수: 브랜드 일치 +3, 제품명 토큰 교집합 비율 +weighted
  const nameTokens = new Set(nameNorm.split(/\s+/).filter((t) => t.length >= 2));

  let best = null;
  let bestScore = -Infinity;

  for (const item of items) {
    const title = normalize(item.title).toLowerCase();
    const brand = normalize(item.brand ?? item.maker ?? "").toLowerCase();
    const titleTokens = new Set(title.split(/\s+/).filter((t) => t.length >= 2));

    let score = 0;
    if (brandNorm && (brand.includes(brandNorm) || title.includes(brandNorm))) score += 3;

    let overlap = 0;
    for (const t of nameTokens) if (titleTokens.has(t)) overlap++;
    score += overlap * 2;

    if (item.image) score += 1; // 이미지 존재 보너스

    if (score > bestScore) {
      bestScore = score;
      best = item;
    }
  }

  return { item: best, score: bestScore };
}

// ── DB 적재 ────────────────────────────────────────────────────────────────
async function insertProductImage({ productId, source, sourceUrl, r2Key, publicUrl, imageHash, contentType, size }) {
  const { error } = await supabase.from("product_images").upsert(
    {
      product_id: productId,
      source,
      source_url: sourceUrl,
      r2_key: r2Key,
      r2_public_url: publicUrl,
      image_hash: imageHash,
      mime_type: contentType,
      size_bytes: size,
      is_primary: false, // 첫 이미지는 별도 로직으로 primary 지정
    },
    { onConflict: "product_id,image_hash", ignoreDuplicates: true },
  );
  if (error) throw error;
}

async function setPrimaryIfNone(productId, imageHash) {
  // 이 product에 primary가 없으면 방금 넣은 row를 primary로
  const { data: existing } = await supabase
    .from("product_images")
    .select("id")
    .eq("product_id", productId)
    .eq("is_primary", true)
    .is("removed_at", null)
    .limit(1);

  if (existing && existing.length > 0) return;

  await supabase
    .from("product_images")
    .update({ is_primary: true })
    .eq("product_id", productId)
    .eq("image_hash", imageHash);
}

async function fillProductImageUrl(productId, publicUrl) {
  // products.product_image_url이 비어있을 때만 채움 (기존 값 덮어쓰지 않음)
  await supabase
    .from("products")
    .update({ product_image_url: publicUrl })
    .eq("id", productId)
    .is("product_image_url", null);
}

async function insertAliases(productId, aliases, source) {
  if (aliases.length === 0) return;
  const rows = aliases.map((alias) => ({
    product_id: productId,
    alias,
    alias_type: source === "naver" ? "naver_display" : source,
    language_code: "ko",
    source: "naver_shopping_api",
    confidence: 0.8,
  }));
  const { error } = await supabase.from("product_aliases").upsert(rows, {
    onConflict: "product_id,alias,alias_type",
    ignoreDuplicates: true,
  });
  if (error) throw error;
}

async function recordScrapeJob({ productId, status, summary, error }) {
  await supabase.from("scrape_jobs").upsert(
    {
      target_type: "product",
      target_id: productId,
      source: "naver",
      status,
      attempts: 1,
      last_error: error ?? null,
      completed_at: status === "done" || status === "failed" ? new Date().toISOString() : null,
      result_summary: summary ?? null,
    },
    { onConflict: "target_type,target_id,source" },
  );
}

// ── 단일 제품 처리 ─────────────────────────────────────────────────────────
async function processProduct(product) {
  const query = normalize(product.product_name);
  if (!query) return { status: "skipped", reason: "empty_name" };

  const { items, total } = await searchNaverShopping(query, { display: 10 });
  if (items.length === 0) {
    return { status: "miss", reason: "no_results", total };
  }

  const { item: best, score } = pickBestItem(product, items);
  if (!best || score < 3) {
    return { status: "miss", reason: "low_score", score, total };
  }

  const summary = {
    matched_title: best.title,
    matched_brand: best.brand || best.maker,
    score,
    lprice: best.lprice,
    total_results: total,
  };

  if (DRY_RUN) return { status: "dry_run", summary, best };

  // 이미지 수집 + R2 업로드
  let imageUrl = null;
  let imageHash = null;
  if (best.image) {
    try {
      const img = await fetchImage(best.image);
      const key = buildKey({ productId: product.id, source: "naver", hash: img.hash, ext: img.ext });
      const pub = getPublicUrl(key);

      await uploadToR2({ key, buffer: img.buffer, contentType: img.contentType });
      await insertProductImage({
        productId: product.id,
        source: "naver",
        sourceUrl: best.image,
        r2Key: key,
        publicUrl: pub,
        imageHash: img.hash,
        contentType: img.contentType,
        size: img.size,
      });
      await setPrimaryIfNone(product.id, img.hash);
      if (pub) await fillProductImageUrl(product.id, pub);

      imageUrl = pub;
      imageHash = img.hash;
    } catch (e) {
      summary.image_error = e.message;
    }
  }

  // Aliases 추출
  const aliases = extractAliasCandidates(best.title, deriveBrand(best));
  await insertAliases(product.id, aliases, "naver");
  summary.aliases_added = aliases.length;
  summary.image_mirrored = imageUrl;

  return { status: "done", summary };
}

// ── 메인 ───────────────────────────────────────────────────────────────────
async function main() {
  console.log(`[scrape_naver_shopping] dry_run=${DRY_RUN} limit=${LIMIT} product_id=${PRODUCT_ID ?? "ALL"}`);

  const targets = await loadTargets();
  console.log(`  targets: ${targets.length} products`);

  const results = { done: 0, miss: 0, skipped: 0, failed: 0, dry_run: 0 };

  for (let i = 0; i < targets.length; i++) {
    const p = targets[i];
    try {
      const r = await processProduct(p);
      results[r.status] = (results[r.status] ?? 0) + 1;
      console.log(
        `  [${i + 1}/${targets.length}] #${p.id} ${p.product_name.slice(0, 40)} → ${r.status}` +
          (r.summary ? ` (${JSON.stringify(r.summary).slice(0, 120)})` : "") +
          (r.reason ? ` [${r.reason}]` : ""),
      );

      if (!DRY_RUN) {
        await recordScrapeJob({
          productId: p.id,
          status: r.status === "done" ? "done" : r.status === "miss" ? "skipped" : "failed",
          summary: r.summary,
        });
      }
    } catch (e) {
      results.failed = (results.failed ?? 0) + 1;
      console.error(`  [${i + 1}/${targets.length}] #${p.id} FAILED: ${e.message}`);
      if (!DRY_RUN) {
        await recordScrapeJob({
          productId: p.id,
          status: "failed",
          error: e.message,
        }).catch(() => {});
      }
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
