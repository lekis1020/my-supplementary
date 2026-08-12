import { adminDb } from "@/lib/db/admin";

// ============================================================================
// Data fetching
// ============================================================================

export interface FreshnessRow {
  entity_type: string;
  staleness_days: number;
  refresh_mode: string;
  last_fetched_at: string | null;
  last_refresh_status: string | null;
  records_processed: string | null;
  freshness: string;
  days_since_fetch: number | null;
}

export async function getFreshness(): Promise<FreshnessRow[]> {
  try {
    return await adminDb<FreshnessRow[]>`
      SELECT
        rp.entity_type,
        rp.staleness_days,
        rp.refresh_mode,
        ers.last_fetched_at::text,
        ers.last_refresh_status,
        ers.last_checksum AS records_processed,
        CASE
          WHEN ers.last_fetched_at IS NULL THEN 'never'
          WHEN ers.last_fetched_at < NOW() - (rp.staleness_days || ' days')::interval THEN 'stale'
          WHEN ers.last_fetched_at < NOW() - (rp.staleness_days * 0.7 || ' days')::interval THEN 'aging'
          ELSE 'fresh'
        END AS freshness,
        CASE
          WHEN ers.last_fetched_at IS NOT NULL
          THEN EXTRACT(DAY FROM NOW() - ers.last_fetched_at)::int
          ELSE NULL
        END AS days_since_fetch
      FROM refresh_policies rp
      LEFT JOIN entity_refresh_states ers
        ON rp.entity_type = ers.entity_type
        AND ers.entity_id = 0
        AND ers.source_connector_id IS NULL
      WHERE rp.is_active = TRUE
      ORDER BY
        CASE
          WHEN ers.last_fetched_at IS NULL THEN 0
          WHEN ers.last_fetched_at < NOW() - (rp.staleness_days || ' days')::interval THEN 1
          WHEN ers.last_fetched_at < NOW() - (rp.staleness_days * 0.7 || ' days')::interval THEN 2
          ELSE 3
        END,
        rp.staleness_days ASC
    `;
  } catch {
    return [];
  }
}

export interface TableCount {
  table_name: string;
  row_count: number;
}

export async function getTableCounts(): Promise<TableCount[]> {
  const tables = [
    "products",
    "ingredients",
    "product_ingredients",
    "claims",
    "ingredient_claims",
    "safety_items",
    "dosage_guidelines",
    "label_snapshots",
    "evidence_studies",
    "evidence_outcomes",
  ];

  const results: TableCount[] = [];

  for (const table of tables) {
    try {
      const [row] = await adminDb`
        SELECT count(*)::int AS cnt FROM ${adminDb(table)}
      `;
      results.push({ table_name: table, row_count: row.cnt });
    } catch {
      results.push({ table_name: table, row_count: -1 });
    }
  }

  return results;
}

export interface VerificationRun {
  id: number;
  run_mode: string;
  layers_checked: string;
  total_checked: number;
  total_passed: number;
  total_warnings: number;
  total_failures: number;
  started_at: string;
  finished_at: string | null;
}

export async function getRecentVerifications(): Promise<VerificationRun[]> {
  try {
    return await adminDb<VerificationRun[]>`
      SELECT
        id, run_mode, layers_checked,
        total_checked, total_passed, total_warnings, total_failures,
        started_at::text, finished_at::text
      FROM verification_runs
      ORDER BY started_at DESC
      LIMIT 10
    `;
  } catch {
    return [];
  }
}

export interface DiscrepancySummary {
  severity: string;
  count: number;
}

export async function getDiscrepancySummary(): Promise<DiscrepancySummary[]> {
  try {
    return await adminDb<DiscrepancySummary[]>`
      SELECT severity, count(*)::int AS count
      FROM verification_discrepancies
      WHERE is_resolved = FALSE
      GROUP BY severity
      ORDER BY
        CASE severity
          WHEN 'critical' THEN 0
          WHEN 'high' THEN 1
          WHEN 'medium' THEN 2
          WHEN 'low' THEN 3
          ELSE 4
        END
    `;
  } catch {
    return [];
  }
}

// ============================================================================
// UI config
// ============================================================================

export const FRESHNESS_CONFIG: Record<
  string,
  { label: string; bg: string; text: string; dot: string }
> = {
  fresh: {
    label: "정상",
    bg: "bg-success-bg",
    text: "text-success",
    dot: "bg-success",
  },
  aging: {
    label: "주의",
    bg: "bg-amber-50",
    text: "text-amber-700",
    dot: "bg-amber-500",
  },
  stale: {
    label: "갱신 필요",
    bg: "bg-danger-bg",
    text: "text-danger",
    dot: "bg-danger",
  },
  never: {
    label: "미수집",
    bg: "bg-stone-100",
    text: "text-ink-muted",
    dot: "bg-stone-400",
  },
};

export const ENTITY_LABELS: Record<string, string> = {
  product: "제품",
  ingredient: "원료",
  product_ingredient: "제품-원료",
  claim: "기능성",
  ingredient_claim: "원료-기능성",
  dosage_guideline: "용량 가이드",
  label_snapshot: "라벨",
  safety_item: "안전성",
  evidence_study: "근거문헌",
};

export const SEVERITY_CONFIG: Record<string, { bg: string; text: string }> = {
  critical: { bg: "bg-red-100", text: "text-red-800" },
  high: { bg: "bg-orange-100", text: "text-orange-800" },
  medium: { bg: "bg-amber-100", text: "text-amber-800" },
  low: { bg: "bg-stone-100", text: "text-ink-muted" },
};
