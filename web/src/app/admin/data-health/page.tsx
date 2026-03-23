import { adminDb } from "@/lib/db/admin";
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";

export const dynamic = "force-dynamic";

export const metadata = {
  title: "데이터 건강 현황 | Admin",
};

// ============================================================================
// Data fetching
// ============================================================================

interface FreshnessRow {
  entity_type: string;
  staleness_days: number;
  refresh_mode: string;
  last_fetched_at: string | null;
  last_refresh_status: string | null;
  records_processed: string | null;
  freshness: string;
  days_since_fetch: number | null;
}

async function getFreshness(): Promise<FreshnessRow[]> {
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

interface TableCount {
  table_name: string;
  row_count: number;
}

async function getTableCounts(): Promise<TableCount[]> {
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

interface VerificationRun {
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

async function getRecentVerifications(): Promise<VerificationRun[]> {
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

interface DiscrepancySummary {
  severity: string;
  count: number;
}

async function getDiscrepancySummary(): Promise<DiscrepancySummary[]> {
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
// UI helpers
// ============================================================================

const FRESHNESS_CONFIG: Record<
  string,
  { label: string; bg: string; text: string; dot: string }
> = {
  fresh: {
    label: "정상",
    bg: "bg-emerald-50",
    text: "text-emerald-700",
    dot: "bg-emerald-500",
  },
  aging: {
    label: "주의",
    bg: "bg-amber-50",
    text: "text-amber-700",
    dot: "bg-amber-500",
  },
  stale: {
    label: "갱신 필요",
    bg: "bg-red-50",
    text: "text-red-700",
    dot: "bg-red-500",
  },
  never: {
    label: "미수집",
    bg: "bg-gray-100",
    text: "text-gray-500",
    dot: "bg-gray-400",
  },
};

const ENTITY_LABELS: Record<string, string> = {
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

const SEVERITY_CONFIG: Record<
  string,
  { bg: string; text: string }
> = {
  critical: { bg: "bg-red-100", text: "text-red-800" },
  high: { bg: "bg-orange-100", text: "text-orange-800" },
  medium: { bg: "bg-amber-100", text: "text-amber-800" },
  low: { bg: "bg-gray-100", text: "text-gray-600" },
};

function formatDate(dateStr: string | null): string {
  if (!dateStr) return "-";
  return new Date(dateStr).toLocaleDateString("ko-KR", {
    month: "short",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}

function formatNumber(n: number): string {
  return n.toLocaleString("ko-KR");
}

// ============================================================================
// Page
// ============================================================================

export default async function DataHealthPage() {
  const [freshness, tableCounts, verifications, discrepancies] =
    await Promise.all([
      getFreshness(),
      getTableCounts(),
      getRecentVerifications(),
      getDiscrepancySummary(),
    ]);

  const totalDiscrepancies = discrepancies.reduce(
    (sum, d) => sum + d.count,
    0,
  );

  const freshCounts = {
    fresh: freshness.filter((r) => r.freshness === "fresh").length,
    aging: freshness.filter((r) => r.freshness === "aging").length,
    stale: freshness.filter((r) => r.freshness === "stale").length,
    never: freshness.filter((r) => r.freshness === "never").length,
  };

  return (
    <div className="mx-auto max-w-6xl px-4 py-8">
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-gray-900">
          데이터 건강 현황
        </h1>
        <p className="mt-1 text-sm text-gray-500">
          파이프라인 갱신 상태, 테이블 현황, 검증 결과를 한 눈에 확인합니다.
        </p>
      </div>

      {/* Summary bar */}
      <div className="mb-8 grid grid-cols-2 gap-4 sm:grid-cols-4">
        <SummaryCard
          label="정상"
          value={freshCounts.fresh}
          color="text-emerald-600"
          bg="bg-emerald-50"
        />
        <SummaryCard
          label="주의"
          value={freshCounts.aging}
          color="text-amber-600"
          bg="bg-amber-50"
        />
        <SummaryCard
          label="갱신 필요"
          value={freshCounts.stale + freshCounts.never}
          color="text-red-600"
          bg="bg-red-50"
        />
        <SummaryCard
          label="미해결 불일치"
          value={totalDiscrepancies}
          color="text-purple-600"
          bg="bg-purple-50"
        />
      </div>

      {/* Freshness grid */}
      <Card className="mb-6">
        <CardHeader>
          <CardTitle>데이터 갱신 상태</CardTitle>
        </CardHeader>
        <CardContent>
          {freshness.length === 0 ? (
            <p className="text-sm text-gray-500">
              refresh_policies 데이터 없음 —{" "}
              <code className="rounded bg-gray-100 px-1 text-xs">
                db/022_seed_refresh_policies.sql
              </code>{" "}
              실행 필요
            </p>
          ) : (
            <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
              {freshness.map((row) => {
                const config =
                  FRESHNESS_CONFIG[row.freshness] ??
                  FRESHNESS_CONFIG.never;
                const label =
                  ENTITY_LABELS[row.entity_type] ?? row.entity_type;

                return (
                  <div
                    key={row.entity_type}
                    className={`rounded-lg border p-4 ${config.bg}`}
                  >
                    <div className="flex items-center justify-between">
                      <span className="text-sm font-medium text-gray-900">
                        {label}
                      </span>
                      <Badge className={`${config.bg} ${config.text}`}>
                        <span
                          className={`mr-1.5 inline-block h-1.5 w-1.5 rounded-full ${config.dot}`}
                        />
                        {config.label}
                      </Badge>
                    </div>
                    <div className="mt-2 text-xs text-gray-500">
                      <span className="font-mono">
                        {row.entity_type}
                      </span>
                    </div>
                    <div className="mt-1 flex items-baseline gap-2">
                      <span className={`text-lg font-semibold ${config.text}`}>
                        {row.days_since_fetch !== null
                          ? `${row.days_since_fetch}일 전`
                          : "미갱신"}
                      </span>
                      <span className="text-xs text-gray-400">
                        / {row.staleness_days}일 기준
                      </span>
                    </div>
                    {row.records_processed && (
                      <div className="mt-1 text-xs text-gray-400">
                        {formatNumber(Number(row.records_processed))}건 처리
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Table counts + Verifications side by side */}
      <div className="mb-6 grid gap-6 lg:grid-cols-2">
        {/* Table counts */}
        <Card>
          <CardHeader>
            <CardTitle>테이블 레코드 현황</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              {tableCounts.map((t) => (
                <div
                  key={t.table_name}
                  className="flex items-center justify-between border-b border-gray-100 pb-2 last:border-0"
                >
                  <span className="text-sm text-gray-600">
                    {t.table_name}
                  </span>
                  <span className="font-mono text-sm font-medium text-gray-900">
                    {t.row_count >= 0
                      ? formatNumber(t.row_count)
                      : "-"}
                  </span>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        {/* Discrepancies */}
        <Card>
          <CardHeader>
            <CardTitle>미해결 불일치</CardTitle>
          </CardHeader>
          <CardContent>
            {discrepancies.length === 0 ? (
              <p className="text-sm text-gray-500">
                미해결 불일치 없음
              </p>
            ) : (
              <div className="space-y-3">
                {discrepancies.map((d) => {
                  const config =
                    SEVERITY_CONFIG[d.severity] ??
                    SEVERITY_CONFIG.low;
                  return (
                    <div
                      key={d.severity}
                      className="flex items-center justify-between"
                    >
                      <Badge className={`${config.bg} ${config.text}`}>
                        {d.severity.toUpperCase()}
                      </Badge>
                      <span className="font-mono text-sm font-medium">
                        {d.count}건
                      </span>
                    </div>
                  );
                })}
                <div className="border-t border-gray-200 pt-2">
                  <div className="flex items-center justify-between">
                    <span className="text-sm font-medium text-gray-700">
                      합계
                    </span>
                    <span className="font-mono text-sm font-bold text-gray-900">
                      {totalDiscrepancies}건
                    </span>
                  </div>
                </div>
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Recent verifications */}
      <Card>
        <CardHeader>
          <CardTitle>최근 검증 이력</CardTitle>
        </CardHeader>
        <CardContent>
          {verifications.length === 0 ? (
            <p className="text-sm text-gray-500">
              검증 이력 없음 —{" "}
              <code className="rounded bg-gray-100 px-1 text-xs">
                npm run verify
              </code>{" "}
              실행 후 확인
            </p>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-gray-200 text-left text-xs text-gray-500">
                    <th className="pb-2 pr-4">ID</th>
                    <th className="pb-2 pr-4">모드</th>
                    <th className="pb-2 pr-4">레이어</th>
                    <th className="pb-2 pr-4">통과</th>
                    <th className="pb-2 pr-4">경고</th>
                    <th className="pb-2 pr-4">실패</th>
                    <th className="pb-2">실행 시각</th>
                  </tr>
                </thead>
                <tbody>
                  {verifications.map((v) => {
                    const passRate =
                      v.total_checked > 0
                        ? (
                            (v.total_passed / v.total_checked) *
                            100
                          ).toFixed(0)
                        : "-";
                    return (
                      <tr
                        key={v.id}
                        className="border-b border-gray-50"
                      >
                        <td className="py-2 pr-4 font-mono text-gray-400">
                          #{v.id}
                        </td>
                        <td className="py-2 pr-4">
                          <Badge className="bg-gray-100 text-gray-700">
                            {v.run_mode}
                          </Badge>
                        </td>
                        <td className="py-2 pr-4 font-mono text-gray-600">
                          L{v.layers_checked}
                        </td>
                        <td className="py-2 pr-4 text-emerald-600">
                          {v.total_passed}/{v.total_checked}{" "}
                          <span className="text-gray-400">
                            ({passRate}%)
                          </span>
                        </td>
                        <td className="py-2 pr-4 text-amber-600">
                          {v.total_warnings}
                        </td>
                        <td className="py-2 pr-4 text-red-600">
                          {v.total_failures}
                        </td>
                        <td className="py-2 text-gray-500">
                          {formatDate(v.started_at)}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}
        </CardContent>
      </Card>

      {/* CLI commands reference */}
      <div className="mt-8 rounded-lg border border-dashed border-gray-300 bg-gray-50 p-4">
        <h3 className="mb-2 text-sm font-medium text-gray-700">
          CLI 명령어
        </h3>
        <div className="grid gap-2 text-xs sm:grid-cols-2">
          <code className="rounded bg-white px-2 py-1 text-gray-600">
            npm run freshness
          </code>
          <span className="text-gray-500">갱신 상태 점검</span>
          <code className="rounded bg-white px-2 py-1 text-gray-600">
            npm run verify
          </code>
          <span className="text-gray-500">데이터 무결성 검증</span>
          <code className="rounded bg-white px-2 py-1 text-gray-600">
            npm run verify:source
          </code>
          <span className="text-gray-500">소스 API 대조 검증</span>
          <code className="rounded bg-white px-2 py-1 text-gray-600">
            npm run verify:full
          </code>
          <span className="text-gray-500">전수조사</span>
        </div>
      </div>
    </div>
  );
}

// ============================================================================
// Sub-components
// ============================================================================

function SummaryCard({
  label,
  value,
  color,
  bg,
}: {
  label: string;
  value: number;
  color: string;
  bg: string;
}) {
  return (
    <div className={`rounded-lg border p-4 ${bg}`}>
      <div className="text-xs text-gray-500">{label}</div>
      <div className={`mt-1 text-2xl font-bold ${color}`}>{value}</div>
    </div>
  );
}
