#!/usr/bin/env node

/**
 * report_ingredient_evidence_gaps.mjs
 *
 * 원료별 효능 근거 공백을 탐지하고 업데이트 우선순위를 출력한다.
 * 필요 시 review_tasks에 자동 등록한다.
 *
 * Usage:
 *   node scripts/report_ingredient_evidence_gaps.mjs
 *   node scripts/report_ingredient_evidence_gaps.mjs --limit=100 --json
 *   node scripts/report_ingredient_evidence_gaps.mjs --enqueue-review-tasks
 */

import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import path from "node:path";
import process from "node:process";
import postgres from "postgres";

const scriptDir = path.dirname(new URL(import.meta.url).pathname);
const webDir = path.resolve(scriptDir, "..");
const rootDir = path.resolve(webDir, "..");

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
    if (!line || line.startsWith("#")) continue;

    const sep = line.indexOf("=");
    if (sep === -1) continue;

    const key = line.slice(0, sep).trim();
    let value = line.slice(sep + 1).trim();

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
  if (!existsSync(envPath)) continue;
  const values = parseEnvFile(envPath);
  for (const [key, value] of Object.entries(values)) {
    if (!process.env[key]) process.env[key] = value;
  }
}

function parseArgs(argv) {
  const args = {
    limit: 50,
    json: false,
    enqueueReviewTasks: false,
    writeMarkdown: true,
  };

  for (const token of argv) {
    if (token === "--json") {
      args.json = true;
      continue;
    }

    if (token === "--enqueue-review-tasks") {
      args.enqueueReviewTasks = true;
      continue;
    }

    if (token === "--no-markdown") {
      args.writeMarkdown = false;
      continue;
    }

    if (token.startsWith("--limit=")) {
      const parsed = Number(token.split("=")[1]);
      if (Number.isInteger(parsed) && parsed > 0) {
        args.limit = parsed;
      }
      continue;
    }
  }

  return args;
}

function formatDate(date = new Date()) {
  const yyyy = String(date.getFullYear());
  const mm = String(date.getMonth() + 1).padStart(2, "0");
  const dd = String(date.getDate()).padStart(2, "0");
  return `${yyyy}${mm}${dd}`;
}

function riskScore(row) {
  return (
    (row.summary_study_count === 0 ? 100 : 0) +
    row.missing_claim_count * 10 +
    (row.ingredient_source_count === 0 ? 5 : 0) +
    (row.evidence_source_count === 0 ? 5 : 0)
  );
}

function gapLevel(row) {
  if (row.claim_count > 0 && row.summary_study_count === 0) return "critical";
  if (row.missing_claim_count > 0) return "high";
  if (row.ingredient_source_count === 0 || row.evidence_source_count === 0) return "medium";
  return "low";
}

function levelOrder(level) {
  switch (level) {
    case "critical":
      return 0;
    case "high":
      return 1;
    case "medium":
      return 2;
    default:
      return 3;
  }
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const databaseUrl = process.env.DATABASE_URL;

  if (!databaseUrl) {
    console.error("ERROR: DATABASE_URL not set");
    process.exit(1);
  }

  const sql = postgres(databaseUrl, {
    max: 1,
    idle_timeout: 5,
    connect_timeout: 30,
  });

  try {
    const rows = await sql`
      WITH published_ingredients AS (
        SELECT id, canonical_name_ko, slug, ingredient_type
        FROM ingredients
        WHERE is_published = TRUE
      ),
      claim_summary AS (
        SELECT
          ic.ingredient_id,
          COUNT(*)::int AS claim_count,
          COALESCE(
            jsonb_agg(DISTINCT c.claim_name_ko) FILTER (WHERE c.claim_name_ko IS NOT NULL),
            '[]'::jsonb
          ) AS claim_names
        FROM ingredient_claims ic
        LEFT JOIN claims c ON c.id = ic.claim_id
        GROUP BY ic.ingredient_id
      ),
      evidence_summary AS (
        SELECT
          es.ingredient_id,
          COUNT(DISTINCT es.id) FILTER (WHERE es.included_in_summary = TRUE)::int AS summary_study_count,
          COUNT(DISTINCT eo.claim_id) FILTER (
            WHERE es.included_in_summary = TRUE AND eo.claim_id IS NOT NULL
          )::int AS covered_claim_count
        FROM evidence_studies es
        LEFT JOIN evidence_outcomes eo ON eo.evidence_study_id = es.id
        GROUP BY es.ingredient_id
      ),
      missing_claims AS (
        SELECT
          ic.ingredient_id,
          COUNT(*)::int AS missing_claim_count,
          COALESCE(
            jsonb_agg(DISTINCT c.claim_name_ko) FILTER (WHERE c.claim_name_ko IS NOT NULL),
            '[]'::jsonb
          ) AS missing_claim_names
        FROM ingredient_claims ic
        LEFT JOIN claims c ON c.id = ic.claim_id
        WHERE NOT EXISTS (
          SELECT 1
          FROM evidence_studies es
          JOIN evidence_outcomes eo ON eo.evidence_study_id = es.id
          WHERE es.ingredient_id = ic.ingredient_id
            AND es.included_in_summary = TRUE
            AND eo.claim_id = ic.claim_id
        )
        GROUP BY ic.ingredient_id
      ),
      ingredient_source_summary AS (
        SELECT entity_id AS ingredient_id, COUNT(*)::int AS ingredient_source_count
        FROM source_links
        WHERE entity_type = 'ingredient'
        GROUP BY entity_id
      ),
      evidence_source_summary AS (
        SELECT
          es.ingredient_id,
          COUNT(DISTINCT sl.id)::int AS evidence_source_count
        FROM evidence_studies es
        LEFT JOIN source_links sl
          ON sl.entity_type = 'evidence_study'
          AND sl.entity_id = es.id
        WHERE es.included_in_summary = TRUE
        GROUP BY es.ingredient_id
      )
      SELECT
        pi.id,
        pi.canonical_name_ko,
        pi.slug,
        pi.ingredient_type,
        COALESCE(cs.claim_count, 0) AS claim_count,
        COALESCE(es.summary_study_count, 0) AS summary_study_count,
        COALESCE(es.covered_claim_count, 0) AS covered_claim_count,
        COALESCE(mc.missing_claim_count, 0) AS missing_claim_count,
        COALESCE(iss.ingredient_source_count, 0) AS ingredient_source_count,
        COALESCE(ess.evidence_source_count, 0) AS evidence_source_count,
        COALESCE(cs.claim_names, '[]'::jsonb) AS claim_names,
        COALESCE(mc.missing_claim_names, '[]'::jsonb) AS missing_claim_names
      FROM published_ingredients pi
      LEFT JOIN claim_summary cs ON cs.ingredient_id = pi.id
      LEFT JOIN evidence_summary es ON es.ingredient_id = pi.id
      LEFT JOIN missing_claims mc ON mc.ingredient_id = pi.id
      LEFT JOIN ingredient_source_summary iss ON iss.ingredient_id = pi.id
      LEFT JOIN evidence_source_summary ess ON ess.ingredient_id = pi.id
      WHERE
        COALESCE(cs.claim_count, 0) > 0
        AND (
          COALESCE(es.summary_study_count, 0) = 0
          OR COALESCE(mc.missing_claim_count, 0) > 0
          OR COALESCE(iss.ingredient_source_count, 0) = 0
          OR COALESCE(ess.evidence_source_count, 0) = 0
        )
    `;

    const enriched = rows
      .map((row) => {
        const level = gapLevel(row);
        return {
          ...row,
          gap_level: level,
          risk_score: riskScore(row),
        };
      })
      .sort((left, right) => {
        const levelDiff = levelOrder(left.gap_level) - levelOrder(right.gap_level);
        if (levelDiff !== 0) return levelDiff;

        if (right.risk_score !== left.risk_score) {
          return right.risk_score - left.risk_score;
        }

        return left.canonical_name_ko.localeCompare(right.canonical_name_ko, "ko");
      });

    const topRows = enriched.slice(0, args.limit);

    if (args.enqueueReviewTasks && topRows.length > 0) {
      let inserted = 0;

      for (const row of topRows) {
        const taskComment = [
          `자동 생성: 효능 근거 보강 필요 (level=${row.gap_level})`,
          `- claim_count=${row.claim_count}, summary_study_count=${row.summary_study_count}`,
          `- missing_claim_count=${row.missing_claim_count}, evidence_source_count=${row.evidence_source_count}`,
        ].join("\n");

        const insertedRows = await sql`
          INSERT INTO review_tasks (
            entity_type,
            entity_id,
            task_type,
            review_level,
            status,
            priority,
            assigned_role,
            reviewer_comment,
            auto_check_passed,
            auto_check_details
          )
          SELECT
            'ingredient',
            ${row.id},
            'content_update',
            'L1',
            'pending',
            ${row.gap_level === "critical" ? "urgent" : row.gap_level === "high" ? "high" : "normal"},
            'scientific_reviewer',
            ${taskComment},
            FALSE,
            ${JSON.stringify({
              generatedBy: "report_ingredient_evidence_gaps.mjs",
              gapLevel: row.gap_level,
              riskScore: row.risk_score,
              missingClaimCount: row.missing_claim_count,
            })}::jsonb
          WHERE NOT EXISTS (
            SELECT 1
            FROM review_tasks rt
            WHERE rt.entity_type = 'ingredient'
              AND rt.entity_id = ${row.id}
              AND rt.task_type = 'content_update'
              AND rt.status IN ('pending', 'in_progress')
          )
          RETURNING id
        `;

        if (insertedRows.length > 0) inserted += 1;
      }

      console.log(`review_tasks 신규 등록: ${inserted}건`);
    }

    if (args.writeMarkdown) {
      const reportDir = path.join(rootDir, ".omx", "reports");
      if (!existsSync(reportDir)) {
        mkdirSync(reportDir, { recursive: true });
      }

      const reportPath = path.join(reportDir, `ingredient-evidence-gaps-${formatDate()}.md`);
      const lines = [
        "# Ingredient Evidence Gap Report",
        "",
        `- generated_at: ${new Date().toISOString()}`,
        `- total_gap_ingredients: ${enriched.length}`,
        `- top_limit: ${args.limit}`,
        "",
        "| priority | ingredient | claims | summary studies | missing claims | evidence sources |",
        "|---|---|---:|---:|---:|---:|",
      ];

      for (const row of topRows) {
        lines.push(
          `| ${row.gap_level} | ${row.canonical_name_ko} | ${row.claim_count} | ${row.summary_study_count} | ${row.missing_claim_count} | ${row.evidence_source_count} |`,
        );
      }

      lines.push("", "## Next actions", "");
      lines.push("1. critical/high 우선으로 PubMed 메타분석/RCT 보강");
      lines.push("2. evidence_studies + evidence_outcomes 연결 후 source_links 추가");
      lines.push("3. 원료 상세 페이지에서 근거 노출 상태 재검증");

      writeFileSync(reportPath, `${lines.join("\n")}\n`, "utf8");
      console.log(`리포트 저장: ${reportPath}`);
    }

    if (args.json) {
      console.log(JSON.stringify(topRows, null, 2));
    } else {
      console.log("=".repeat(72));
      console.log(" Ingredient Evidence Gap Summary");
      console.log("=".repeat(72));
      console.log(`총 갭 원료: ${enriched.length}개`);
      console.log(`출력 상위: ${topRows.length}개`);
      console.log("");

      for (const row of topRows) {
        const missingClaims = (row.missing_claim_names ?? []).slice(0, 3).join(", ");
        console.log(
          `[${row.gap_level.toUpperCase()}] ${row.canonical_name_ko} (claims=${row.claim_count}, studies=${row.summary_study_count}, missing_claims=${row.missing_claim_count})`,
        );
        if (missingClaims) {
          console.log(`  - missing: ${missingClaims}`);
        }
      }
    }

    await sql.end();
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
}

main();
