#!/usr/bin/env node
/**
 * product_enrichment_queue 소비 배치 — 실시간 검색으로 유입된 제품의
 * 성분 구성(product_ingredients)을 식약처 staging 데이터와 매칭해 생성.
 *
 * 매칭 전략 (순서대로):
 *   1. products.approval_or_report_no → staging_product_ingredients_kr.report_no
 *   2. 제품명 정확 일치 (staging.product_name = products.product_name)
 *   3. 퍼지: 검색어 정제 후 ilike 후보 → bigram Jaccard ≥ 0.5 승인
 *
 * 성공: product_ingredients 생성 + queue status='matched' + matched_report_no
 *       + 제품 공개(is_published=true — live_search 유입 제품은 비공개로 적재됨)
 * 실패: status='manual' (staging은 정적 데이터라 재시도 무의미 → 수동 검토)
 *
 * 사용법:
 *   cd web
 *   node scripts/enrich_products_from_staging.mjs --limit=50
 *   node scripts/enrich_products_from_staging.mjs --dry-run
 */

import { createClient } from "@supabase/supabase-js";
import { loadEnv, requireEnv } from "./lib/env.mjs";
import {
  normalize,
  cleanSearchQuery,
  bigrams,
  jaccard,
} from "../src/lib/scraper/naver-match.mjs";

const args = Object.fromEntries(
  process.argv.slice(2).map((a) => {
    const [k, v] = a.replace(/^--/, "").split("=");
    return [k, v ?? true];
  }),
);

const LIMIT = Number(args.limit ?? 50);
const DRY_RUN = args["dry-run"] === true;
const FUZZY_MIN_JACCARD = 0.5;

loadEnv();
requireEnv("NEXT_PUBLIC_SUPABASE_URL", "SUPABASE_SERVICE_ROLE_KEY");

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY,
  { auth: { persistSession: false } },
);

/** 수량·회분 suffix 제거한 매칭용 핵심 이름 */
function coreName(name) {
  return cleanSearchQuery(normalize(name ?? ""))
    .replace(/\d+\s*(?:정|포|캡슐|스틱|개월분|일분|주분|병|박스|매|환)/g, " ")
    .replace(/\d+\s*(?:x|X|\*)\s*\d+/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

/** staging rows(동일 report_no)를 product_ingredients payload로 변환 */
async function buildIngredientRows(productId, stagingRows) {
  // 원료 resolve: canonical_slug 우선, 없으면 canonical_name_ko
  const rows = [];
  for (const st of stagingRows) {
    let ingredient = null;

    if (st.canonical_slug) {
      const { data } = await supabase
        .from("ingredients")
        .select("id")
        .eq("slug", st.canonical_slug)
        .limit(1)
        .maybeSingle();
      ingredient = data;
    }

    if (!ingredient && st.canonical_name_ko) {
      const { data } = await supabase
        .from("ingredients")
        .select("id")
        .eq("canonical_name_ko", st.canonical_name_ko)
        .limit(1)
        .maybeSingle();
      ingredient = data;
    }

    if (!ingredient) continue;

    rows.push({
      product_id: productId,
      ingredient_id: ingredient.id,
      amount_per_serving: st.amount_per_serving,
      amount_unit: st.amount_unit,
      daily_amount: st.daily_amount,
      daily_amount_unit: st.daily_amount_unit,
      ingredient_role: st.proposed_ingredient_role ?? "active",
      raw_label_name: st.raw_label_name?.slice(0, 255) ?? null,
    });
  }

  // 동일 ingredient 중복 제거 (staging에 role별 중복 행 존재 가능)
  const seen = new Set();
  return rows.filter((r) => {
    const key = `${r.ingredient_id}|${r.ingredient_role}`;
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });
}

/** report_no로 staging 성분 행 로드 */
async function stagingRowsByReportNo(reportNo) {
  const { data, error } = await supabase
    .from("staging_product_ingredients_kr")
    .select(
      "report_no, product_name, canonical_name_ko, canonical_slug, raw_label_name, amount_per_serving, amount_unit, daily_amount, daily_amount_unit, proposed_ingredient_role",
    )
    .eq("report_no", reportNo);
  if (error) throw error;
  return data ?? [];
}

/** 제품명 기반 staging report_no 탐색 (정확 일치 → 퍼지) */
async function findReportNoByName(product) {
  const name = normalize(product.product_name);
  if (!name) return null;

  // 2. 정확 일치
  const { data: exact } = await supabase
    .from("staging_product_ingredients_kr")
    .select("report_no, product_name")
    .eq("product_name", name)
    .limit(1);
  if (exact && exact.length > 0) return exact[0].report_no;

  // 3. 퍼지: 핵심 이름으로 후보 조회 → Jaccard 검증
  const core = coreName(name);
  if (core.length < 4) return null;

  const probe = core.split(/\s+/).slice(0, 3).join(" ");
  const { data: candidates } = await supabase
    .from("staging_product_ingredients_kr")
    .select("report_no, product_name")
    .ilike("product_name", `%${probe}%`)
    .limit(30);

  if (!candidates || candidates.length === 0) return null;

  const nameGrams = bigrams(core);
  let best = null;
  let bestSim = 0;
  const seenReportNos = new Set();
  for (const cand of candidates) {
    if (seenReportNos.has(cand.report_no)) continue;
    seenReportNos.add(cand.report_no);
    const sim = jaccard(nameGrams, bigrams(coreName(cand.product_name)));
    if (sim > bestSim) {
      bestSim = sim;
      best = cand;
    }
  }

  return bestSim >= FUZZY_MIN_JACCARD ? best.report_no : null;
}

async function updateQueue(queueId, patch) {
  if (DRY_RUN) return;
  await supabase
    .from("product_enrichment_queue")
    .update(patch)
    .eq("id", queueId);
}

async function processQueueItem(item) {
  const { data: product, error } = await supabase
    .from("products")
    .select("id, product_name, brand_name, manufacturer_name, approval_or_report_no")
    .eq("id", item.product_id)
    .maybeSingle();
  if (error) throw error;
  if (!product) {
    await updateQueue(item.id, {
      status: "failed",
      last_error: "product_not_found",
      attempts: item.attempts + 1,
      completed_at: new Date().toISOString(),
    });
    return { status: "failed", reason: "product_not_found" };
  }

  // 이미 성분이 연결돼 있으면 종료
  const { count: existingCount } = await supabase
    .from("product_ingredients")
    .select("id", { count: "exact", head: true })
    .eq("product_id", product.id);
  if ((existingCount ?? 0) > 0) {
    if (!DRY_RUN) {
      await supabase
        .from("products")
        .update({ is_published: true })
        .eq("id", product.id);
    }
    await updateQueue(item.id, {
      status: "matched",
      matched_report_no: product.approval_or_report_no,
      attempts: item.attempts + 1,
      completed_at: new Date().toISOString(),
    });
    return { status: "matched", reason: "already_enriched" };
  }

  // 1. report_no 직접 매칭 → 2·3. 이름 매칭
  let reportNo = product.approval_or_report_no ?? null;
  let stagingRows = reportNo ? await stagingRowsByReportNo(reportNo) : [];

  if (stagingRows.length === 0) {
    // Naver title(payload)이 원제품명보다 정보가 많을 수 있음 — 둘 다 시도
    reportNo = await findReportNoByName(product);
    if (!reportNo && item.payload?.naver_title) {
      reportNo = await findReportNoByName({ product_name: item.payload.naver_title });
    }
    if (reportNo) stagingRows = await stagingRowsByReportNo(reportNo);
  }

  if (stagingRows.length === 0) {
    await updateQueue(item.id, {
      status: "manual",
      last_error: "no_staging_match",
      attempts: item.attempts + 1,
      completed_at: new Date().toISOString(),
    });
    return { status: "manual", reason: "no_staging_match" };
  }

  const rows = await buildIngredientRows(product.id, stagingRows);
  if (rows.length === 0) {
    await updateQueue(item.id, {
      status: "manual",
      last_error: "no_ingredient_resolved",
      attempts: item.attempts + 1,
      completed_at: new Date().toISOString(),
    });
    return { status: "manual", reason: "no_ingredient_resolved" };
  }

  if (!DRY_RUN) {
    const { error: insertError } = await supabase
      .from("product_ingredients")
      .insert(rows);
    if (insertError) throw insertError;

    // 매칭 성공 → 공개 전환 + 매칭된 report_no 보존
    const productPatch = { is_published: true };
    if (!product.approval_or_report_no && reportNo) {
      productPatch.approval_or_report_no = reportNo;
    }
    await supabase.from("products").update(productPatch).eq("id", product.id);
  }

  await updateQueue(item.id, {
    status: "matched",
    matched_report_no: reportNo,
    attempts: item.attempts + 1,
    completed_at: new Date().toISOString(),
  });

  return { status: "matched", ingredients: rows.length, reportNo };
}

async function main() {
  console.log(`[enrich_products_from_staging] dry_run=${DRY_RUN} limit=${LIMIT}`);

  const { data: queue, error } = await supabase
    .from("product_enrichment_queue")
    .select("id, product_id, status, attempts, payload")
    .eq("status", "pending")
    .order("scheduled_for", { ascending: true })
    .limit(LIMIT);
  if (error) throw error;

  console.log(`  queue: ${queue?.length ?? 0} pending items`);

  const results = { matched: 0, manual: 0, failed: 0 };

  for (const [i, item] of (queue ?? []).entries()) {
    try {
      const r = await processQueueItem(item);
      results[r.status] = (results[r.status] ?? 0) + 1;
      console.log(
        `  [${i + 1}/${queue.length}] queue#${item.id} product#${item.product_id} → ${r.status}` +
          (r.ingredients ? ` (${r.ingredients} ingredients, ${r.reportNo})` : "") +
          (r.reason ? ` [${r.reason}]` : ""),
      );
    } catch (e) {
      results.failed += 1;
      console.error(`  [${i + 1}/${queue.length}] queue#${item.id} FAILED: ${e.message}`);
      await updateQueue(item.id, {
        status: "failed",
        last_error: e.message?.slice(0, 500),
        attempts: item.attempts + 1,
      }).catch(() => {});
    }
  }

  console.log("\n=== Summary ===");
  console.log(JSON.stringify(results, null, 2));
}

main().catch((e) => {
  console.error("Fatal:", e);
  process.exit(1);
});
