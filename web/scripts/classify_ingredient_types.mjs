#!/usr/bin/env node
/**
 * ingredient_type "other" 550건을 적절한 타입으로 재분류.
 *
 * 전략:
 *   1단계: 규칙 기반 (regex) — 명확한 패턴 매칭
 *   2단계: LLM (Claude API) — 나머지 일괄 분류
 *   3단계: DB 업데이트
 *
 * 사용법:
 *   cd web
 *   node scripts/classify_ingredient_types.mjs --dry-run   # 미리보기
 *   node scripts/classify_ingredient_types.mjs             # 실제 적용
 */

import { createClient } from "@supabase/supabase-js";
import { loadEnv, requireEnv } from "./lib/env.mjs";

// ── CLI 인자 ────────────────────────────────────────────────────────────────
const DRY_RUN = process.argv.includes("--dry-run");
const SKIP_LLM = process.argv.includes("--skip-llm");

// ── 초기화 ─────────────────────────────────────────────────────────────────
loadEnv();
requireEnv("NEXT_PUBLIC_SUPABASE_URL", "SUPABASE_SERVICE_ROLE_KEY");

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY,
  { auth: { persistSession: false } },
);

// ── 규칙 기반 분류 ──────────────────────────────────────────────────────────
const RULES = [
  // vitamin
  {
    type: "vitamin",
    test: (n) =>
      /^(비타민|vitamin)\s*[A-Z가-힣]|나이아신|니코틴아미드|판토텐산|엽산|폴산|리보플라빈|티아민|피리독신|코발라민|비오틴|레티놀|토코페롤|아스코르빈산|콜레칼시페롤|메나퀴논|필로퀴논|이노시톨/i.test(n),
  },
  // mineral
  {
    type: "mineral",
    test: (n) =>
      /^(칼슘|마그네슘|아연|철분?|셀레늄|셀렌|크롬|구리|망간|요오드|몰리브덴|칼륨|인$|붕소|규소|게르마늄|바나듐|스트론튬|실리카)/i.test(n) ||
      /^(calcium|magnesium|zinc|iron|selenium|chromium|copper|manganese|iodine|potassium|boron|silicon)/i.test(n),
  },
  // fatty_acid
  {
    type: "fatty_acid",
    test: (n) =>
      /오메가.?[369]|DHA|EPA|감마리놀렌산|공액리놀레산|공액리놀렌산|크릴|스쿠알렌|리놀레산|알파리놀렌/i.test(n),
  },
  // probiotic
  {
    type: "probiotic",
    test: (n) =>
      /프로바이오틱|유산균|비피더스|락토바실|Lactobacillus|Bifidobacterium|프리바이오틱/i.test(n),
  },
  // herbal (식물 추출물, 전통 약재)
  {
    type: "herbal",
    test: (n) =>
      /추출물|추출분말|엑기스|엑스$|잎$|열매|뿌리|꽃|종자|줄기|수피|식물스테롤|피크노제놀|밀크씨슬|실리마린|루테인|지아잔틴|커큐민|강황|인삼|홍삼|녹차|카테킨|마카|쏘팔메토|은행잎|아슈와간다|발레리안|세인트존스|감초|당귀|작약|천궁|복분자|오미자|구기자|영지|상황버섯|동충하초|스피루리나|클로렐라|후코이단|알로에|노니|아사이|석류|블루베리|크랜베리|빌베리|포도씨|레스베라트롤|안토시아닌|카카오|코코아|시나몬|계피|마늘|양파|브로콜리|케일|보스웰리아|프로폴리스|로즈힙|감국|감태|가시오|이소플라본|누에|매스틱|로즈마리|자몽|레몬밤|민들레|당조고추|두충|우슬|구절초|홍합/i.test(n),
  },
  // fiber (식이섬유)
  {
    type: "fiber",
    test: (n) =>
      /식이섬유|글루코만난|곤약|구아검|이눌린|프락토올리고|갈락토올리고|차전자|셀룰로오스|폴리덱스트로오스|난소화성|저항전분|알긴산|펙틴|치커리|올리고당|라피노스|말토덱스트린|락추로스/i.test(n),
  },
  // peptide (펩타이드, 콜라겐, 가수분해물)
  {
    type: "peptide",
    test: (n) =>
      /콜라겐|엘라스틴|펩타이드|펩티드|가수분해물|단백질$|단백$|실크아미노산|케라틴|젤라틴|글루타티온|태반|락토페린|난각막|대두단백/i.test(n),
  },
  // functional_compound (단일 기능성 화합물) — amino_acid보다 먼저 체크
  {
    type: "functional_compound",
    test: (n) =>
      /멜라토닌|키토산|키토올리고당|글루코사민|콘드로이친|뮤코다당|MSM|SAMe|포스파티딜세린|레시틴|포스파티딜콜린|시티콜린|옥타코사놀|폴리코사놀|베타인|베타카로틴|라이코펜|아스타잔틴|후코잔틴|감마오리자놀|CoQ10|NAC|NMN|니코틴아마이드|PQQ/i.test(n),
  },
  // enzyme
  {
    type: "enzyme",
    test: (n) =>
      /효소|리파아제|프로테아제|아밀라아제|셀룰라아제|브로멜라인|파파인|나토키나아제|코엔자임|유비퀴놀|유비퀴논/i.test(n),
  },
  // amino_acid
  {
    type: "amino_acid",
    test: (n) =>
      /아르기닌|글루타민|타우린|시스테인|메티오닌|트립토판|라이신|류신|이소류신|발린|트레오닌|히스티딘|페닐알라닌|글리신|알라닌|세린|프롤린|BCAA|아미노산|카르니틴|GABA|테아닌|5-HTP|크레아틴|시트룰린|오르니틴|아스파르트산|글루탐산/i.test(n),
  },
  // functional_blend (복합원료, 개별인정형)
  {
    type: "functional_blend",
    test: (n) =>
      /복합물|복합추출|제\d{4}-\d+호|개별인정형/i.test(n),
  },
];

/** 규칙 기반 분류 — 첫 매칭 반환 */
function classifyByRules(name) {
  for (const rule of RULES) {
    if (rule.test(name)) return rule.type;
  }
  return null;
}

// ── LLM 분류 ────────────────────────────────────────────────────────────────
const VALID_TYPES = [
  "vitamin",
  "mineral",
  "amino_acid",
  "fatty_acid",
  "probiotic",
  "herbal",
  "enzyme",
  "fiber",
  "peptide",
  "functional_compound",
  "functional_blend",
  "other",
];

async function classifyByLLM(ingredients) {
  if (!process.env.ANTHROPIC_API_KEY) {
    console.warn("  ANTHROPIC_API_KEY 없음 — LLM 분류 건너뜀");
    return ingredients.map((i) => ({ id: i.id, type: "other" }));
  }

  const { default: Anthropic } = await import("@anthropic-ai/sdk");
  const client = new Anthropic();
  const BATCH_SIZE = 80;
  const results = [];

  for (let i = 0; i < ingredients.length; i += BATCH_SIZE) {
    const batch = ingredients.slice(i, i + BATCH_SIZE);
    const list = batch.map((ing) => `${ing.id}: ${ing.display_name || ing.canonical_name_ko}`).join("\n");

    const response = await client.messages.create({
      model: "claude-sonnet-4-20250514",
      max_tokens: 4000,
      messages: [
        {
          role: "user",
          content: `다음 건강기능식품 성분들을 분류하세요. 각 성분에 대해 가장 적합한 타입을 하나만 선택합니다.

가능한 타입:
- vitamin: 비타민류 (A, B군, C, D, E, K 등)
- mineral: 미네랄 (칼슘, 마그네슘, 아연, 철 등)
- amino_acid: 아미노산 (아르기닌, 타우린, BCAA, 카르니틴, 테아닌 등)
- fatty_acid: 지방산 (오메가3, DHA, EPA, 감마리놀렌산 등)
- probiotic: 유산균/프로바이오틱스
- herbal: 식물 추출물, 허브, 전통 약재 (추출물, 잎, 열매, 뿌리 등)
- enzyme: 효소류 (코엔자임Q10 포함)
- fiber: 식이섬유 (글루코만난, 이눌린, 올리고당 등)
- peptide: 펩타이드/단백질 (콜라겐, 가수분해물, 글루타치온 등)
- functional_compound: 기능성 단일 화합물 (멜라토닌, 글루코사민, MSM, NAC 등)
- functional_blend: 복합원료/개별인정형 (여러 원료 조합, "제20XX-XX호" 표기)
- other: 위 어디에도 해당하지 않는 경우

응답 형식 (JSON array만, 다른 텍스트 없이):
[{"id": 123, "type": "herbal"}, ...]

성분 목록:
${list}`,
        },
      ],
    });

    const text = response.content[0].text;
    try {
      const parsed = JSON.parse(text.replace(/```json?\n?|\n?```/g, "").trim());
      for (const item of parsed) {
        if (item.id && VALID_TYPES.includes(item.type)) {
          results.push(item);
        }
      }
    } catch (e) {
      console.error(`  LLM 배치 ${i / BATCH_SIZE + 1} 파싱 실패:`, e.message);
      // fallback: 이 배치는 other 유지
      for (const ing of batch) results.push({ id: ing.id, type: "other" });
    }

    if (i + BATCH_SIZE < ingredients.length) {
      await new Promise((r) => setTimeout(r, 1000));
    }
    console.log(`  LLM 배치 ${Math.floor(i / BATCH_SIZE) + 1}/${Math.ceil(ingredients.length / BATCH_SIZE)} 완료`);
  }

  return results;
}

// ── 메인 ────────────────────────────────────────────────────────────────────
async function main() {
  console.log("=== ingredient_type 재분류 시작 ===");
  console.log(`  모드: ${DRY_RUN ? "DRY-RUN (DB 미수정)" : "LIVE"}`);

  // 1) "other" 타입 전체 로드
  const { data: others, error } = await supabase
    .from("ingredients")
    .select("id, display_name, canonical_name_ko, canonical_name_en, ingredient_type")
    .eq("ingredient_type", "other")
    .order("id");

  if (error) throw error;
  console.log(`  대상: ${others.length}건 (ingredient_type = "other")`);

  // herb → herbal 통합도 처리
  const { data: herbs } = await supabase
    .from("ingredients")
    .select("id")
    .eq("ingredient_type", "herb");
  if (herbs?.length) {
    console.log(`  + herb→herbal 통합: ${herbs.length}건`);
  }

  // 2) 규칙 기반 분류
  const ruleClassified = [];
  const unclassified = [];

  for (const ing of others) {
    const name = ing.display_name || ing.canonical_name_ko || "";
    const type = classifyByRules(name);
    if (type && type !== "other") {
      ruleClassified.push({ id: ing.id, type, name });
    } else {
      unclassified.push(ing);
    }
  }

  console.log(`\n  [1단계] 규칙 기반: ${ruleClassified.length}건 분류됨`);
  const ruleStats = {};
  for (const r of ruleClassified) ruleStats[r.type] = (ruleStats[r.type] || 0) + 1;
  for (const [k, v] of Object.entries(ruleStats).sort((a, b) => b[1] - a[1])) {
    console.log(`    ${k}: ${v}`);
  }
  console.log(`  미분류 잔여: ${unclassified.length}건`);

  // 3) LLM 분류
  let llmClassified = [];
  if (!SKIP_LLM && unclassified.length > 0) {
    console.log(`\n  [2단계] LLM 분류 시작 (${unclassified.length}건)...`);
    llmClassified = await classifyByLLM(unclassified);
    const llmStats = {};
    for (const r of llmClassified) llmStats[r.type] = (llmStats[r.type] || 0) + 1;
    console.log(`  LLM 분류 결과:`);
    for (const [k, v] of Object.entries(llmStats).sort((a, b) => b[1] - a[1])) {
      console.log(`    ${k}: ${v}`);
    }
  }

  // 4) DB 업데이트
  const allUpdates = [
    ...ruleClassified.map((r) => ({ id: r.id, type: r.type })),
    ...llmClassified.filter((r) => r.type !== "other"),
    ...(herbs || []).map((h) => ({ id: h.id, type: "herbal" })),
  ];

  console.log(`\n  [3단계] 총 업데이트 대상: ${allUpdates.length}건`);

  if (DRY_RUN) {
    console.log("  DRY-RUN 모드 — DB 수정 없이 종료");
    // 샘플 출력
    console.log("\n  === 분류 샘플 ===");
    const sample = ruleClassified.slice(0, 15);
    for (const s of sample) {
      console.log(`    #${s.id} ${s.name?.slice(0, 30)} → ${s.type}`);
    }
    return;
  }

  // 타입별로 배치 업데이트
  const byType = {};
  for (const u of allUpdates) {
    if (!byType[u.type]) byType[u.type] = [];
    byType[u.type].push(u.id);
  }

  let updated = 0;
  for (const [type, ids] of Object.entries(byType)) {
    // Supabase .in()은 최대 ~300개씩
    for (let i = 0; i < ids.length; i += 200) {
      const batch = ids.slice(i, i + 200);
      const { error: updateErr } = await supabase
        .from("ingredients")
        .update({ ingredient_type: type })
        .in("id", batch);
      if (updateErr) {
        console.error(`  ERROR updating ${type}:`, updateErr.message);
      } else {
        updated += batch.length;
      }
    }
    console.log(`    ${type}: ${ids.length}건 업데이트`);
  }

  console.log(`\n=== 완료: ${updated}건 업데이트됨 ===`);

  // 최종 분포 확인
  const { data: final } = await supabase.from("ingredients").select("ingredient_type");
  const finalStats = {};
  for (const r of final || []) finalStats[r.ingredient_type] = (finalStats[r.ingredient_type] || 0) + 1;
  console.log("\n  최종 분포:");
  for (const [k, v] of Object.entries(finalStats).sort((a, b) => b[1] - a[1])) {
    console.log(`    ${k}: ${v}`);
  }
}

main().catch((e) => {
  console.error("FATAL:", e);
  process.exit(1);
});
