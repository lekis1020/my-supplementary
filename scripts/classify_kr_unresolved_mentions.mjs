#!/usr/bin/env node

import { createReadStream, createWriteStream, existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import path from "node:path";
import process from "node:process";
import readline from "node:readline";

const rootDir = process.cwd();
const mappedDir = path.join(rootDir, "tmp", "kr-gov-clean", "mapped");
const unresolvedFile = path.join(mappedDir, "ingredient_name_unresolved.normalized.jsonl");
const catalogFile = path.join(mappedDir, "ingredient_catalog.merged.jsonl");

if (!existsSync(unresolvedFile) || !existsSync(catalogFile)) {
  console.error("Mapped ingredient files not found. Run scripts/map_kr_ingredient_mentions.mjs first.");
  process.exit(1);
}

const outputDir = path.join(mappedDir, "classified");
mkdirSync(outputDir, { recursive: true });

function cleanText(value) {
  if (value == null) {
    return null;
  }

  const text = String(value)
    .replace(/\r\n/g, "\n")
    .replace(/[“”]/g, '"')
    .replace(/[‘’]/g, "'")
    .replace(/？/g, "~")
    .replace(/&#41/g, ")")
    .replace(/&#40/g, "(")
    .replace(/\u00a0/g, " ")
    .split("\n")
    .map((line) => line.replace(/[ \t]+/g, " ").trim())
    .filter(Boolean)
    .join("\n")
    .trim();

  return text || null;
}

function cleanInlineText(value) {
  const text = cleanText(value);
  return text ? text.replace(/\s+/g, " ").trim() : null;
}

function normalizeKey(value) {
  const text = cleanInlineText(value);
  if (!text) {
    return null;
  }

  return text.toLowerCase().replace(/[^a-z0-9가-힣]/g, "");
}

async function readJsonl(filePath, onRecord) {
  const stream = createReadStream(filePath, { encoding: "utf8" });
  const lineReader = readline.createInterface({
    input: stream,
    crlfDelay: Infinity,
  });

  for await (const line of lineReader) {
    const trimmed = line.trim();
    if (!trimmed) {
      continue;
    }
    onRecord(JSON.parse(trimmed));
  }
}

function includesAny(text, patterns) {
  return patterns.some((pattern) => text.includes(pattern));
}

const capsuleShellPatterns = [
  "히드록시프로필메틸셀룰로스",
  "히드록시프로필메틸셀룰로오스",
  "젤라틴",
  "글리세린",
  "정제수",
  "카라기난",
  "이산화티타늄",
  "D-소비톨액",
  "소르비탄지방산에스테르",
  "염화마그네슘",
  "염화칼륨",
];

const excipientFlowPatterns = [
  "이산화규소",
  "스테아린산마그네슘",
  "결정셀룰로스",
  "카복시메틸셀룰로스칼슘",
  "카르복시메틸셀룰로오스칼슘",
  "가교카복시메틸셀룰로스나트륨",
  "글리세린지방산에스테르",
  "자당지방산에스테르",
  "스테아린산",
  "변성전분",
  "난소화성말토덱스트린",
  "덱스트린",
  "말토덱스트린",
  "혼합유당",
  "유당혼합",
  "유당",
  "전분",
];

const sweetenerPatterns = [
  "효소처리스테비아",
  "스테비아",
  "수크랄로스",
  "에리스리톨",
  "자일리톨",
  "D-소비톨",
  "D-소르비톨",
  "이소말트",
  "포도당",
  "분말결정포도당",
  "결정포도당",
];

const flavorColorPatterns = [
  "색소",
  "향",
  "향분말",
  "치자",
  "안나토",
  "카카오색소",
  "식용색소",
  "바닐린",
  "에틸바닐린",
];

const waxOilPatterns = [
  "밀납",
  "레시틴",
  "콩기름",
  "대두유",
  "포도씨앗유",
  "포도씨유",
  "유지",
];

const genericPatterns = [
  "기타가공품",
  "혼합제제",
  "혼합분말",
  "혼합제제분말",
  "기타식품",
];

const activeHintPatterns = [
  "비타민",
  "홍삼",
  "가르시니아",
  "콜라겐",
  "유산균",
  "프로바이오틱스",
  "밀크씨슬",
  "마리골드",
  "루테인",
  "지아잔틴",
  "아연",
  "철",
  "칼슘",
  "마그네슘",
  "셀레늄",
  "크롬",
  "비오틴",
  "엽산",
  "비타민B",
  "비타민D",
  "코엔자임Q10",
  "타우린",
  "L-아르지닌",
  "건조효모",
  "녹차추출물",
  "프로폴리스",
  "베타카로틴",
  "폴리덱스트로스",
  "프락토올리고당",
  "옥타코사놀",
  "알로에",
  "헤마토코쿠스",
  "홍국",
  "뮤코다당",
  "쏘팔메토",
];

const strainPatterns = [
  "Lactobacillus",
  "Lacticaseibacillus",
  "Lactiplantibacillus",
  "Bifidobacterium",
  "Enterococcus",
  "Leuconostoc",
  "Pediococcus",
];

const catalog = [];
await readJsonl(catalogFile, (row) => {
  catalog.push(row);
});

const aliasTokens = [];
for (const row of catalog) {
  const names = [row.canonicalNameKo, ...(row.aliases ?? [])]
    .map((value) => cleanInlineText(value))
    .filter(Boolean);

  for (const name of names) {
    aliasTokens.push({
      token: name,
      normalized: normalizeKey(name),
      canonicalNameKo: row.canonicalNameKo,
      canonicalSlug: row.slug ?? null,
    });
  }
}

aliasTokens.sort((a, b) => b.token.length - a.token.length);

function candidateCanonicals(rawLabelName) {
  const clean = cleanInlineText(rawLabelName) ?? "";
  const normalized = normalizeKey(clean) ?? "";
  const hits = [];
  const seen = new Set();

  for (const token of aliasTokens) {
    if (!token.normalized) {
      continue;
    }

    const latinOnly = /^[a-z0-9-]+$/i.test(token.token);
    if (latinOnly && token.token.length < 4) {
      continue;
    }

    if (!clean.includes(token.token) && !normalized.includes(token.normalized)) {
      continue;
    }

    const signature = `${token.canonicalNameKo}::${token.canonicalSlug ?? ""}`;
    if (seen.has(signature)) {
      continue;
    }
    seen.add(signature);

    hits.push({
      canonicalNameKo: token.canonicalNameKo,
      canonicalSlug: token.canonicalSlug,
      matchedToken: token.token,
    });

    if (hits.length >= 5) {
      break;
    }
  }

  return hits;
}

function classifyRow(row) {
  const name = cleanInlineText(row.rawLabelName) ?? "";
  const role = cleanInlineText(row.exampleRole) ?? "";
  const candidates = candidateCanonicals(name);

  if (name.length > 500) {
    return {
      classification: "formula_blob",
      reviewPriority: "high",
      rationale: "라벨 전체가 한 줄로 합쳐진 원문 blob 형태",
      candidateCanonicals: candidates,
    };
  }

  if (role === "capsule" || includesAny(name, capsuleShellPatterns)) {
    return {
      classification: "capsule_shell_or_coating",
      reviewPriority: "low",
      rationale: "캡슐 피막/코팅/가소제 성격의 원료 패턴",
      candidateCanonicals: candidates,
    };
  }

  if (includesAny(name, flavorColorPatterns)) {
    return {
      classification: "excipient_flavor_or_color",
      reviewPriority: "low",
      rationale: "향료 또는 색소 패턴",
      candidateCanonicals: candidates,
    };
  }

  if (includesAny(name, sweetenerPatterns)) {
    return {
      classification: "excipient_sweetener_or_bulking",
      reviewPriority: "low",
      rationale: "감미료/당알코올/부형제 패턴",
      candidateCanonicals: candidates,
    };
  }

  if (includesAny(name, waxOilPatterns)) {
    return {
      classification: "excipient_oil_or_wax",
      reviewPriority: "low",
      rationale: "왁스/레시틴/오일 보조성분 패턴",
      candidateCanonicals: candidates,
    };
  }

  if (includesAny(name, excipientFlowPatterns)) {
    return {
      classification: "excipient_flow_or_tableting",
      reviewPriority: "low",
      rationale: "유동화제/결합제/붕해보조제 패턴",
      candidateCanonicals: candidates,
    };
  }

  if (includesAny(name, strainPatterns)) {
    return {
      classification: "active_candidate_probiotic_strain",
      reviewPriority: "high",
      rationale: "프로바이오틱스 균주명 패턴",
      candidateCanonicals: candidates,
    };
  }

  if (role === "main" || role === "individual") {
    return {
      classification: "active_candidate_declared_raw_material",
      reviewPriority: "high",
      rationale: "주원료/개별원료 필드에서 나온 항목",
      candidateCanonicals: candidates,
    };
  }

  if (includesAny(name, genericPatterns)) {
    return {
      classification: "generic_mixture_or_processed_food",
      reviewPriority: "medium",
      rationale: "혼합제제/기타가공품처럼 구체성이 낮은 표현",
      candidateCanonicals: candidates,
    };
  }

  if (includesAny(name, activeHintPatterns) || candidates.length > 0) {
    return {
      classification: "active_candidate_by_alias_hint",
      reviewPriority: "medium",
      rationale: "canonical alias 또는 활성원료 힌트 포함",
      candidateCanonicals: candidates,
    };
  }

  return {
    classification: "review_needed_other",
    reviewPriority: "medium",
    rationale: "규칙 기반 자동 분류 실패",
    candidateCanonicals: candidates,
  };
}

const rows = [];
await readJsonl(unresolvedFile, (row) => {
  const classified = classifyRow(row);
  rows.push({
    ...row,
    ...classified,
  });
});

rows.sort((a, b) => b.mentionCount - a.mentionCount || a.rawLabelName.localeCompare(b.rawLabelName, "ko"));

const classificationCounts = {};
const priorityCounts = {};
const mentionCountsByClass = {};

for (const row of rows) {
  classificationCounts[row.classification] =
    (classificationCounts[row.classification] ?? 0) + 1;
  priorityCounts[row.reviewPriority] =
    (priorityCounts[row.reviewPriority] ?? 0) + 1;
  mentionCountsByClass[row.classification] =
    (mentionCountsByClass[row.classification] ?? 0) + row.mentionCount;
}

function writeJsonl(filePath, items) {
  const stream = createWriteStream(filePath, { encoding: "utf8" });
  for (const item of items) {
    stream.write(`${JSON.stringify(item)}\n`);
  }
  stream.end();
}

writeJsonl(path.join(outputDir, "ingredient_name_unresolved.classified.jsonl"), rows);
writeJsonl(
  path.join(outputDir, "ingredient_name_active_candidates.jsonl"),
  rows.filter((row) => row.classification.startsWith("active_candidate")),
);
writeJsonl(
  path.join(outputDir, "ingredient_name_excipients.jsonl"),
  rows.filter((row) => row.classification.startsWith("excipient") || row.classification === "capsule_shell_or_coating"),
);
writeJsonl(
  path.join(outputDir, "ingredient_name_formula_blobs.jsonl"),
  rows.filter((row) => row.classification === "formula_blob"),
);

const summary = {
  generatedAt: new Date().toISOString(),
  inputFile: unresolvedFile,
  outputDir,
  counts: {
    totalRows: rows.length,
    classificationCounts,
    priorityCounts,
    mentionCountsByClass,
  },
};

writeFileSync(
  path.join(outputDir, "summary.json"),
  `${JSON.stringify(summary, null, 2)}\n`,
);

console.log(JSON.stringify(summary, null, 2));
