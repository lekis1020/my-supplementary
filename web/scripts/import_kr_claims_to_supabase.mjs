#!/usr/bin/env node

import { createReadStream, existsSync, readFileSync } from "node:fs";
import path from "node:path";
import process from "node:process";
import readline from "node:readline";
import crypto from "node:crypto";
import { execFileSync } from "node:child_process";
import { createClient } from "@supabase/supabase-js";
import { trackRefresh } from "./lib/track-refresh.mjs";

const scriptDir = path.dirname(new URL(import.meta.url).pathname);
const webDir = path.resolve(scriptDir, "..");
const rootDir = path.resolve(webDir, "..");
const supabaseTempDir = path.join(rootDir, "supabase", ".temp");

const envCandidates = [
  path.join(webDir, ".env.local"),
  path.join(rootDir, ".env.local"),
  path.join(webDir, ".env"),
  path.join(rootDir, ".env"),
];

function parseEnvFile(filePath) {
  const values = {};
  const content = readFileSync(filePath, "utf8");

  for (const rawLine of content.split(/\r?\n/)) {
    const line = rawLine.trim();
    if (!line || line.startsWith("#")) {
      continue;
    }

    const separatorIndex = line.indexOf("=");
    if (separatorIndex === -1) {
      continue;
    }

    const key = line.slice(0, separatorIndex).trim();
    let value = line.slice(separatorIndex + 1).trim();

    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }

    values[key] = value;
  }

  return values;
}

for (const envPath of envCandidates) {
  if (!existsSync(envPath)) {
    continue;
  }

  const values = parseEnvFile(envPath);
  for (const [key, value] of Object.entries(values)) {
    if (!process.env[key]) {
      process.env[key] = value;
    }
  }
}

function parseArgs(argv) {
  const args = {
    dryRun: false,
    batchSize: 500,
  };

  for (const token of argv) {
    if (token === "--dry-run") {
      args.dryRun = true;
      continue;
    }

    if (token.startsWith("--batch-size=")) {
      args.batchSize = Number(token.split("=")[1]);
    }
  }

  return args;
}

const args = parseArgs(process.argv.slice(2));

function readTempValue(filename) {
  const filePath = path.join(supabaseTempDir, filename);
  if (!existsSync(filePath)) {
    return null;
  }

  return readFileSync(filePath, "utf8").trim() || null;
}

function resolveProjectRef() {
  return process.env.SUPABASE_PROJECT_REF ?? readTempValue("project-ref");
}

function resolveSupabaseUrl(projectRef) {
  const envUrl = process.env.NEXT_PUBLIC_SUPABASE_URL ?? process.env.SUPABASE_URL;

  if (envUrl && !envUrl.includes("placeholder.supabase.co")) {
    return envUrl;
  }

  return projectRef ? `https://${projectRef}.supabase.co` : envUrl ?? null;
}

function resolveServiceRoleKey(projectRef) {
  if (process.env.SUPABASE_SERVICE_ROLE_KEY) {
    return process.env.SUPABASE_SERVICE_ROLE_KEY;
  }

  if (!projectRef) {
    return null;
  }

  const output = execFileSync(
    "supabase",
    ["projects", "api-keys", "list", "--project-ref", projectRef, "--output", "json"],
    {
      cwd: rootDir,
      encoding: "utf8",
      stdio: ["ignore", "pipe", "pipe"],
    },
  );

  const keys = JSON.parse(output);
  const serviceRole = keys.find((item) => item.id === "service_role");
  return serviceRole?.api_key ?? null;
}

async function* readJsonl(filePath) {
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

    yield JSON.parse(trimmed);
  }
}

function chunk(array, size) {
  const output = [];
  for (let index = 0; index < array.length; index += size) {
    output.push(array.slice(index, index + size));
  }
  return output;
}

function cleanWhitespace(value) {
  return value
    .replace(/\s+/g, " ")
    .replace(/\u00A0/g, " ")
    .trim();
}

function stripMeta(text) {
  let output = cleanWhitespace(text);
  output = output.replace(/^[-*•\u2022]+\s*/g, "");
  output = output.replace(/^"+|"+$/g, "");
  output = output.replace(/^'+|'+$/g, "");
  output = output.replace(/^\(?국문\)?\s*/g, "");
  output = output.replace(/^\(?영문\)?\s*/g, "");
  output = output.replace(/^\(\s*국문\s*\)\s*/g, "");
  output = output.replace(/^\(\s*영문\s*\)\s*/g, "");
  output = output.replace(/\(생리활성기능\s*\d+등급\)/g, "");
  output = output.replace(/\(기타기능\s*[ⅠⅡⅢⅣⅤIVX0-9]+\)/g, "");
  output = output.replace(/\(기타\s*[ⅠⅡⅢⅣⅤIVX0-9]+\)/g, "");
  output = output.replace(/\(영문\)\s*/g, "");
  output = output.replace(/\(국문\)\s*/g, "");
  output = output.replace(/^"+|"+$/g, "");
  output = output.replace(/^'+|'+$/g, "");
  return cleanWhitespace(output);
}

function extractEvidenceGradeText(text) {
  const match = text.match(/생리활성기능\s*\d+등급/);
  return match ? match[0] : null;
}

function splitRawClaim(text) {
  const normalized = cleanWhitespace(text);
  if (!normalized || normalized === "-") {
    return [];
  }

  const withoutLabels = normalized
    .replace(/\(국문\)/g, "")
    .replace(/\(영문\)/g, "|")
    .replace(/\(영문\)\s*May help/gi, "|May help");

  const preferred = withoutLabels.split("|")[0] ?? normalized;
  const split = preferred
    .split(/[,/]/)
    .map((part) => stripMeta(part))
    .filter(Boolean)
    .filter((part) => part !== "-")
    .filter((part) => !/^(May help|Required for)\b/i.test(part));

  return split.length > 0 ? split : [stripMeta(preferred)].filter(Boolean);
}

function normalizeSubject(subject) {
  return cleanWhitespace(
    subject
      .replace(/^유익한\s+/g, "유익균 ")
      .replace(/유산균 증식/g, "유익균 증식")
      .replace(/피부보습/g, "피부 보습")
      .replace(/장건강/g, "장 건강")
      .replace(/뼈건강/g, "뼈 건강")
      .replace(/관절건강/g, "관절 건강")
      .replace(/연골건강/g, "연골 건강")
      .replace(/관절 및 연골건강/g, "관절 및 연골 건강")
      .replace(/혈액흐름/g, "혈행")
      .replace(/skindamage/gi, "skin damage"),
  );
}

function titleCaseEnglish(value) {
  return value
    .split(" ")
    .filter(Boolean)
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(" ");
}

function translateSubject(subjectKo) {
  const dictionary = new Map([
    ["면역기능 증진", "immune function"],
    ["면역 기능 증진", "immune function"],
    ["면역 기능", "immune function"],
    ["피부 보습", "skin hydration"],
    ["피부 건강", "skin health"],
    ["자외선에 의한 피부손상으로부터 피부건강 유지", "skin health against UV damage"],
    ["지구력 증진", "endurance"],
    ["체지방 감소", "body fat reduction"],
    ["갱년기 여성의 건강", "menopausal health"],
    ["유익균 증식", "beneficial bacteria growth"],
    ["유해균 억제", "suppression of harmful bacteria"],
    ["배변활동 원활", "regular bowel movements"],
    ["장 건강", "gut health"],
    ["혈당 조절", "blood glucose control"],
    ["혈압", "blood pressure"],
    ["혈압이 높은 사람", "blood pressure in people with elevated blood pressure"],
    ["관절 및 연골 건강", "joint and cartilage health"],
    ["항산화", "antioxidant activity"],
    ["혈행 개선", "circulation"],
    ["눈 건강", "eye health"],
    ["간 건강", "liver health"],
    ["뼈 건강", "bone health"],
    ["피로 개선", "fatigue reduction"],
    ["기억력 개선", "memory improvement"],
    ["혈중 콜레스테롤 개선", "blood cholesterol improvement"],
    ["혈중 중성지질 개선", "blood triglyceride improvement"],
    ["정상적인 면역기능", "normal immune function"],
    ["정상적인 세포분열", "normal cell division"],
    ["골다공증발생 위험 감소", "risk reduction of osteoporosis"],
  ]);

  return dictionary.get(subjectKo) ?? null;
}

function inferClaimCategory(subjectKo, predicateType) {
  const subject = subjectKo ?? "";

  if (predicateType === "risk_reduction") {
    return "risk_reduction";
  }
  if (/면역/.test(subject)) return "immune";
  if (/피부/.test(subject)) return "skin";
  if (/장|배변|유익균|유해균/.test(subject)) return "gut";
  if (/혈당/.test(subject)) return "glycemic";
  if (/혈압|혈행|콜레스테롤|중성지질/.test(subject)) return "cardiometabolic";
  if (/뼈|관절|연골|골다공증/.test(subject)) return "bone_joint";
  if (/눈|황반/.test(subject)) return "eye";
  if (/간/.test(subject)) return "liver";
  if (/체지방/.test(subject)) return "weight";
  if (/피로|지구력/.test(subject)) return "performance";
  if (/기억력/.test(subject)) return "cognitive";
  if (/항산화/.test(subject)) return "antioxidant";
  return "general_health";
}

function derivePredicateAndSubject(claimText) {
  const cleaned = stripMeta(claimText);

  if (!cleaned) {
    return null;
  }

  if (/^(May help|Required for)\b/i.test(cleaned)) {
    return null;
  }

  if (/위험 감소에 도움/.test(cleaned)) {
    const subject = normalizeSubject(cleaned.replace(/에 도움.*$/, ""));
    return {
      predicateType: "risk_reduction",
      subjectKo: subject,
      canonicalKo: `${subject}에 도움을 줄 수 있음`,
    };
  }

  if (/에 필요$/.test(cleaned)) {
    const subject = normalizeSubject(cleaned.replace(/에 필요$/, ""));
    return {
      predicateType: "required_for",
      subjectKo: subject,
      canonicalKo: `${subject}에 필요`,
    };
  }

  if (/을 유지하는데 도움(?:을 줌|을 줄 수 있음|을 줍니다|을 줄 수 있습니다\.?)?$/.test(cleaned)) {
    const subject = normalizeSubject(
      cleaned.replace(
        /을 유지하는데 도움(?:을 줌|을 줄 수 있음|을 줍니다|을 줄 수 있습니다\.?)?$/,
        " 유지",
      ),
    );
    return {
      predicateType: "supports",
      subjectKo: subject,
      canonicalKo: `${subject}에 도움을 줄 수 있음`,
    };
  }

  if (/에게 도움(?:을 줌|을 줄 수 있음|을 줍니다|을 줄 수 있습니다\.?)?$/.test(cleaned)) {
    const subject = normalizeSubject(
      cleaned.replace(
        /에게 도움(?:을 줌|을 줄 수 있음|을 줍니다|을 줄 수 있습니다\.?)?$/,
        "",
      ),
    );
    return {
      predicateType: "supports",
      subjectKo: subject,
      canonicalKo: `${subject}에게 도움을 줄 수 있음`,
    };
  }

  if (/에 도움(?:을 줌|을 줄 수 있음|을 줍니다)?$/.test(cleaned)) {
    const subject = normalizeSubject(
      cleaned.replace(
        /에 도움(?:을 줌|을 줄 수 있음|을 줍니다|을 줄 수 있습니다\.?)?$/,
        "",
      ),
    );
    return {
      predicateType: "supports",
      subjectKo: subject,
      canonicalKo: `${subject}에 도움을 줄 수 있음`,
    };
  }

  const subject = normalizeSubject(cleaned);
  return {
    predicateType: "supports",
    subjectKo: subject,
    canonicalKo: `${subject}에 도움을 줄 수 있음`,
  };
}

function buildCanonicalEnglish(subjectKo, predicateType) {
  const subjectEn = translateSubject(subjectKo);
  if (!subjectEn) {
    return { subjectEn: null, canonicalEn: null };
  }

  if (predicateType === "required_for") {
    return {
      subjectEn,
      canonicalEn: `Required for ${subjectEn}`,
    };
  }

  if (predicateType === "risk_reduction") {
    return {
      subjectEn,
      canonicalEn: `May help reduce the risk of ${subjectEn.replace(/^risk reduction of /, "")}`,
    };
  }

  return {
    subjectEn,
    canonicalEn: `May help support ${subjectEn}`,
  };
}

function buildClaimKey(subjectKo, predicateType) {
  const hash = crypto
    .createHash("sha1")
    .update(`${predicateType}:${subjectKo}`)
    .digest("hex")
    .slice(0, 12);
  return `${predicateType}_${hash}`;
}

async function fetchAllRows(supabase, tableName, columns, batchSize) {
  const rows = [];
  let from = 0;

  while (true) {
    const to = from + batchSize - 1;
    const { data, error } = await supabase
      .from(tableName)
      .select(columns)
      .order("id", { ascending: true })
      .range(from, to);

    if (error) {
      throw error;
    }

    if (!data || data.length === 0) {
      break;
    }

    rows.push(...data);

    if (data.length < batchSize) {
      break;
    }

    from += batchSize;
  }

  return rows;
}

function buildClaimPayload(claim) {
  return {
    claim_key: claim.claimKey,
    claim_code: claim.claimCode,
    claim_name_ko: claim.canonicalClaimKo,
    claim_name_en: claim.canonicalClaimEn,
    canonical_claim_ko: claim.canonicalClaimKo,
    canonical_claim_en: claim.canonicalClaimEn,
    claim_subject_ko: claim.claimSubjectKo,
    claim_subject_en: claim.claimSubjectEn,
    predicate_type: claim.predicateType,
    claim_category: claim.claimCategory,
    claim_scope: claim.claimScope,
    source_language: "ko",
    description: claim.description,
  };
}

async function main() {
  const projectRef = resolveProjectRef();
  const supabaseUrl = resolveSupabaseUrl(projectRef);
  const serviceRoleKey = resolveServiceRoleKey(projectRef);

  if (!supabaseUrl) {
    throw new Error("Missing Supabase URL");
  }
  if (!serviceRoleKey) {
    throw new Error("Missing SUPABASE_SERVICE_ROLE_KEY and could not resolve via Supabase CLI");
  }

  const inputPath = path.join(rootDir, "tmp", "kr-gov-clean", "ingredient_profiles.normalized.jsonl");
  if (!existsSync(inputPath)) {
    throw new Error(`Missing input file: ${inputPath}`);
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const ingredients = await fetchAllRows(
    supabase,
    "ingredients",
    "id, canonical_name_ko, slug",
    args.batchSize,
  );
  const ingredientIdByName = new Map();
  for (const row of ingredients) {
    if (row.canonical_name_ko) {
      ingredientIdByName.set(row.canonical_name_ko, row.id);
    }
  }

  const claimByKey = new Map();
  const ingredientClaimPayloads = [];

  for await (const ingredientProfile of readJsonl(inputPath)) {
    const ingredientId = ingredientIdByName.get(ingredientProfile.canonicalNameKo);
    if (!ingredientId) {
      continue;
    }

    const rawItems = ingredientProfile.functionalityItems ?? [];
    const recognitionNo = ingredientProfile.recognitionNos?.[0] ?? null;

    for (const rawItem of rawItems) {
      const rawClaimText = cleanWhitespace(String(rawItem ?? ""));
      if (!rawClaimText || rawClaimText === "-") {
        continue;
      }

      const evidenceGradeText = extractEvidenceGradeText(rawClaimText);
      const splitClaims = splitRawClaim(rawClaimText);

      for (const splitClaim of splitClaims) {
        const normalized = derivePredicateAndSubject(splitClaim);
        if (!normalized) {
          continue;
        }

        const { subjectEn, canonicalEn } = buildCanonicalEnglish(
          normalized.subjectKo,
          normalized.predicateType,
        );
        const claimKey = buildClaimKey(normalized.subjectKo, normalized.predicateType);
        const claimCategory = inferClaimCategory(
          normalized.subjectKo,
          normalized.predicateType,
        );

        if (!claimByKey.has(claimKey)) {
          claimByKey.set(claimKey, {
            claimKey,
            claimCode: claimKey.toUpperCase(),
            canonicalClaimKo: normalized.canonicalKo,
            canonicalClaimEn: canonicalEn,
            claimSubjectKo: normalized.subjectKo,
            claimSubjectEn: subjectEn ? titleCaseEnglish(subjectEn) : null,
            predicateType: normalized.predicateType,
            claimCategory,
            claimScope: "approved_kr",
            description: rawClaimText,
          });
        }

        ingredientClaimPayloads.push({
          ingredientId,
          claimKey,
          rawClaimText,
          rawClaimLanguage: /May help|required for/i.test(rawClaimText) ? "en" : "ko",
          evidenceGradeText,
          recognitionNo,
          sourceDataset: ingredientProfile.sourceDatasets?.[0] ?? "foodsafety-unknown",
          claimScopeNote: splitClaim !== rawClaimText ? "split_from_compound_claim" : null,
          allowedExpression: normalized.canonicalKo,
        });
      }
    }
  }

  const claimRows = Array.from(claimByKey.values());

  if (args.dryRun) {
    console.log(
      JSON.stringify(
        {
          projectRef,
          claimCount: claimRows.length,
          ingredientClaimCount: ingredientClaimPayloads.length,
          examples: claimRows.slice(0, 10),
        },
        null,
        2,
      ),
    );
    return;
  }

  for (const batch of chunk(claimRows, args.batchSize)) {
    const { error } = await supabase
      .from("claims")
      .upsert(batch.map(buildClaimPayload), {
        onConflict: "claim_code",
        ignoreDuplicates: false,
      });

    if (error) {
      throw error;
    }
  }

  const claims = await fetchAllRows(
    supabase,
    "claims",
    "id, claim_key",
    args.batchSize,
  );
  const claimIdByKey = new Map();
  for (const row of claims) {
    if (row.claim_key) {
      claimIdByKey.set(row.claim_key, row.id);
    }
  }

  const ingredientClaimsRows = ingredientClaimPayloads
    .map((row) => {
      const claimId = claimIdByKey.get(row.claimKey);
      if (!claimId) {
        return null;
      }

      return {
        ingredient_id: row.ingredientId,
        claim_id: claimId,
        evidence_grade: null,
        evidence_summary: null,
        is_regulator_approved: true,
        approval_country_code: "KR",
        raw_claim_text: row.rawClaimText,
        raw_claim_language: row.rawClaimLanguage,
        allowed_expression: row.allowedExpression,
        prohibited_expression: null,
        recognition_no: row.recognitionNo,
        evidence_grade_text: row.evidenceGradeText,
        claim_scope_note: row.claimScopeNote,
        source_dataset: row.sourceDataset,
        source_priority: 10,
      };
    })
    .filter(Boolean);

  const mergedIngredientClaims = Array.from(
    ingredientClaimsRows
      .reduce((map, row) => {
        const key = `${row.ingredient_id}:${row.claim_id}:${row.approval_country_code}`;
        const current = map.get(key);

        if (!current) {
          map.set(key, row);
          return map;
        }

        if (
          row.raw_claim_text &&
          current.raw_claim_text &&
          row.raw_claim_text !== current.raw_claim_text &&
          !current.raw_claim_text.includes(row.raw_claim_text)
        ) {
          current.raw_claim_text = `${current.raw_claim_text}\n${row.raw_claim_text}`;
        }

        current.raw_claim_language ??= row.raw_claim_language;
        current.allowed_expression ??= row.allowed_expression;
        current.recognition_no ??= row.recognition_no;
        current.evidence_grade_text ??= row.evidence_grade_text;
        current.claim_scope_note ??= row.claim_scope_note;
        current.source_dataset ??= row.source_dataset;

        return map;
      }, new Map())
      .values(),
  );

  for (const batch of chunk(mergedIngredientClaims, args.batchSize)) {
    const { error } = await supabase
      .from("ingredient_claims")
      .upsert(batch, {
        onConflict: "ingredient_id,claim_id,approval_country_code",
        ignoreDuplicates: false,
      });

    if (error) {
      throw error;
    }
  }

  const [{ count: claimCount }, { count: ingredientClaimCount }] = await Promise.all([
    supabase.from("claims").select("id", { count: "exact", head: true }),
    supabase
      .from("ingredient_claims")
      .select("id", { count: "exact", head: true }),
  ]);

  console.log(
    JSON.stringify(
      {
        projectRef,
        insertedClaims: claimRows.length,
        insertedIngredientClaims: mergedIngredientClaims.length,
        counts: {
          claims: claimCount ?? null,
          ingredient_claims: ingredientClaimCount ?? null,
        },
      },
      null,
      2,
    ),
  );

  await Promise.all([
    trackRefresh(supabase, { entityType: "claim", recordsProcessed: claimRows.length }),
    trackRefresh(supabase, { entityType: "ingredient_claim", recordsProcessed: mergedIngredientClaims.length }),
  ]);
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
