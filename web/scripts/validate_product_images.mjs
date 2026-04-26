#!/usr/bin/env node
/**
 * 제품 이미지 품질 검증 — Gemini Vision으로 마케팅/광고 이미지 감지.
 *
 * 사용법:
 *   cd web
 *   node scripts/validate_product_images.mjs --limit=50 --dry-run
 *   node scripts/validate_product_images.mjs --limit=50              # 마케팅 이미지 삭제
 */

import { createClient } from "@supabase/supabase-js";
import { GoogleGenerativeAI } from "@google/generative-ai";
import { loadEnv, requireEnv } from "./lib/env.mjs";

const args = Object.fromEntries(
  process.argv.slice(2).map((a) => {
    const [k, v] = a.replace(/^--/, "").split("=");
    return [k, v ?? true];
  }),
);

const LIMIT = Number(args.limit ?? 50);
const DRY_RUN = args["dry-run"] === true;

loadEnv();
requireEnv("NEXT_PUBLIC_SUPABASE_URL", "SUPABASE_SERVICE_ROLE_KEY", "GOOGLE_GENERATIVE_AI_API_KEY");

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY,
  { auth: { persistSession: false } },
);

const genAI = new GoogleGenerativeAI(process.env.GOOGLE_GENERATIVE_AI_API_KEY);
const model = genAI.getGenerativeModel({ model: "gemini-2.5-flash" });

async function classifyImage(imageUrl) {
  const res = await fetch(imageUrl);
  if (!res.ok) return { type: "error", reason: "fetch_failed" };

  const buffer = Buffer.from(await res.arrayBuffer());
  const mimeType = res.headers.get("content-type") || "image/jpeg";

  const result = await model.generateContent({
    contents: [
      {
        role: "user",
        parts: [
          {
            inlineData: {
              mimeType,
              data: buffer.toString("base64"),
            },
          },
          {
            text: `이 이미지를 분류해주세요. JSON으로만 응답하세요.

분류 기준:
- "product_front": 제품 패키지만 보이는 깔끔한 사진 (박스, 병, 캡슐 등 제품만)
- "product_angle": 제품이 보이지만 각도가 있거나 여러 구성품 함께
- "marketing": 아래 중 하나라도 해당하면 marketing으로 분류:
  · 사람(모델, 연예인, 의사 일러스트)이 포함된 이미지
  · 할인가/판매누적/1+1 등 프로모션 텍스트
  · 제품 외 과일/식재료가 배경 대부분을 차지
  · 제품보다 마케팅 문구가 더 큰 이미지
- "set_gift": 선물세트/묶음 패키지 사진 (선물 박스, 쇼핑백 포함)
- "unrelated": 건강기능식품과 무관한 이미지

응답 형식: {"type": "product_front", "confidence": 0.95, "reason": "깨끗한 흰 배경에 제품 정면"}`,
          },
        ],
      },
    ],
    generationConfig: {
      temperature: 0,
      responseMimeType: "application/json",
    },
  });

  try {
    const text = result.response.text();
    return JSON.parse(text);
  } catch {
    return { type: "unknown", reason: "parse_failed" };
  }
}

async function main() {
  console.log(`=== 이미지 품질 검증 ===`);
  console.log(`  limit: ${LIMIT}, dry-run: ${DRY_RUN}`);

  // Naver 소스 이미지 중 아직 검증되지 않은 것
  const { data: images } = await supabase
    .from("product_images")
    .select("id, product_id, r2_public_url, source")
    .eq("source", "naver")
    .order("id", { ascending: true })
    .limit(LIMIT);

  console.log(`  대상: ${images?.length}건\n`);

  const stats = { product_front: 0, product_angle: 0, marketing: 0, set_gift: 0, unrelated: 0, error: 0 };
  const toRemove = [];

  for (let i = 0; i < (images?.length ?? 0); i++) {
    const img = images[i];
    try {
      const result = await classifyImage(img.r2_public_url);
      const type = result.type || "unknown";
      stats[type] = (stats[type] || 0) + 1;

      const flag = ["marketing", "set_gift", "unrelated"].includes(type) ? "❌" : "✅";
      console.log(
        `  [${i + 1}/${images.length}] #${img.product_id} ${flag} ${type} (${(result.confidence || 0).toFixed(2)}) — ${result.reason?.slice(0, 40) || ""}`,
      );

      if (["marketing", "set_gift", "unrelated"].includes(type)) {
        toRemove.push(img);
      }
    } catch (e) {
      stats.error++;
      console.log(`  [${i + 1}/${images.length}] #${img.product_id} ⚠️ error: ${e.message?.slice(0, 40)}`);
    }
  }

  console.log(`\n=== 결과 ===`);
  console.log(JSON.stringify(stats, null, 2));
  console.log(`제거 대상: ${toRemove.length}건`);

  if (DRY_RUN || toRemove.length === 0) {
    console.log(DRY_RUN ? "DRY-RUN 모드 — 삭제 없음" : "제거 대상 없음");
    return;
  }

  // 마케팅 이미지 삭제
  for (const img of toRemove) {
    await supabase.from("product_images").delete().eq("id", img.id);
    // 다른 이미지가 없으면 product_image_url 초기화
    const { data: remaining } = await supabase
      .from("product_images")
      .select("id")
      .eq("product_id", img.product_id);
    if (!remaining || remaining.length === 0) {
      await supabase.from("products").update({ product_image_url: null }).eq("id", img.product_id);
    }
  }
  console.log(`${toRemove.length}건 삭제 완료`);
}

main().catch((e) => {
  console.error("FATAL:", e);
  process.exit(1);
});
