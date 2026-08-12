import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import {
  getFreshness,
  getTableCounts,
  getRecentVerifications,
  getDiscrepancySummary,
  FRESHNESS_CONFIG,
  ENTITY_LABELS,
  SEVERITY_CONFIG,
} from "@/lib/admin/data-health";

export const dynamic = "force-dynamic";

export const metadata = {
  title: "데이터 건강 현황 | Admin",
};

// ============================================================================
// UI helpers
// ============================================================================

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

  const totalDiscrepancies = discrepancies.reduce((sum, d) => sum + d.count, 0);

  const freshCounts = {
    fresh: freshness.filter((r) => r.freshness === "fresh").length,
    aging: freshness.filter((r) => r.freshness === "aging").length,
    stale: freshness.filter((r) => r.freshness === "stale").length,
    never: freshness.filter((r) => r.freshness === "never").length,
  };

  return (
    <div className="mx-auto max-w-6xl px-4 py-8">
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-ink">데이터 건강 현황</h1>
        <p className="mt-1 text-sm text-ink-muted">
          파이프라인 갱신 상태, 테이블 현황, 검증 결과를 한 눈에 확인합니다.
        </p>
      </div>

      {/* Summary bar */}
      <div className="mb-8 grid grid-cols-2 gap-4 sm:grid-cols-4">
        <SummaryCard
          label="정상"
          value={freshCounts.fresh}
          color="text-success"
          bg="bg-success-bg"
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
          color="text-danger"
          bg="bg-danger-bg"
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
            <p className="text-sm text-ink-muted">
              refresh_policies 데이터 없음 —{" "}
              <code className="rounded bg-stone-100 px-1 text-xs">
                db/022_seed_refresh_policies.sql
              </code>{" "}
              실행 필요
            </p>
          ) : (
            <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
              {freshness.map((row) => {
                const config =
                  FRESHNESS_CONFIG[row.freshness] ?? FRESHNESS_CONFIG.never;
                const label = ENTITY_LABELS[row.entity_type] ?? row.entity_type;

                return (
                  <div
                    key={row.entity_type}
                    className={`rounded-lg border p-4 ${config.bg}`}
                  >
                    <div className="flex items-center justify-between">
                      <span className="text-sm font-medium text-ink">
                        {label}
                      </span>
                      <Badge className={`${config.bg} ${config.text}`}>
                        <span
                          className={`mr-1.5 inline-block h-1.5 w-1.5 rounded-full ${config.dot}`}
                        />
                        {config.label}
                      </Badge>
                    </div>
                    <div className="mt-2 text-xs text-ink-muted">
                      <span className="font-mono">{row.entity_type}</span>
                    </div>
                    <div className="mt-1 flex items-baseline gap-2">
                      <span className={`text-lg font-semibold ${config.text}`}>
                        {row.days_since_fetch !== null
                          ? `${row.days_since_fetch}일 전`
                          : "미갱신"}
                      </span>
                      <span className="text-xs text-ink-faint">
                        / {row.staleness_days}일 기준
                      </span>
                    </div>
                    {row.records_processed && (
                      <div className="mt-1 text-xs text-ink-faint">
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
                  className="flex items-center justify-between border-b border-stone-100 pb-2 last:border-0"
                >
                  <span className="text-sm text-ink-muted">{t.table_name}</span>
                  <span className="font-mono text-sm font-medium text-ink">
                    {t.row_count >= 0 ? formatNumber(t.row_count) : "-"}
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
              <p className="text-sm text-ink-muted">미해결 불일치 없음</p>
            ) : (
              <div className="space-y-3">
                {discrepancies.map((d) => {
                  const config =
                    SEVERITY_CONFIG[d.severity] ?? SEVERITY_CONFIG.low;
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
                <div className="border-t border-stone-200 pt-2">
                  <div className="flex items-center justify-between">
                    <span className="text-sm font-medium text-ink-muted">
                      합계
                    </span>
                    <span className="font-mono text-sm font-bold text-ink">
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
            <p className="text-sm text-ink-muted">
              검증 이력 없음 —{" "}
              <code className="rounded bg-stone-100 px-1 text-xs">
                npm run verify
              </code>{" "}
              실행 후 확인
            </p>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-stone-200 text-left text-xs text-ink-muted">
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
                        ? ((v.total_passed / v.total_checked) * 100).toFixed(0)
                        : "-";
                    return (
                      <tr key={v.id} className="border-b border-stone-50">
                        <td className="py-2 pr-4 font-mono text-ink-faint">
                          #{v.id}
                        </td>
                        <td className="py-2 pr-4">
                          <Badge variant="neutral">{v.run_mode}</Badge>
                        </td>
                        <td className="py-2 pr-4 font-mono text-ink-muted">
                          L{v.layers_checked}
                        </td>
                        <td className="py-2 pr-4 text-success">
                          {v.total_passed}/{v.total_checked}{" "}
                          <span className="text-ink-faint">({passRate}%)</span>
                        </td>
                        <td className="py-2 pr-4 text-amber-600">
                          {v.total_warnings}
                        </td>
                        <td className="py-2 pr-4 text-danger">
                          {v.total_failures}
                        </td>
                        <td className="py-2 text-ink-muted">
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
      <div className="mt-8 rounded-lg border border-dashed border-stone-300 bg-stone-50 p-4">
        <h3 className="mb-2 text-sm font-medium text-ink-muted">CLI 명령어</h3>
        <div className="grid gap-2 text-xs sm:grid-cols-2">
          <code className="rounded bg-white px-2 py-1 text-ink-muted">
            npm run freshness
          </code>
          <span className="text-ink-muted">갱신 상태 점검</span>
          <code className="rounded bg-white px-2 py-1 text-ink-muted">
            npm run verify
          </code>
          <span className="text-ink-muted">데이터 무결성 검증</span>
          <code className="rounded bg-white px-2 py-1 text-ink-muted">
            npm run verify:source
          </code>
          <span className="text-ink-muted">소스 API 대조 검증</span>
          <code className="rounded bg-white px-2 py-1 text-ink-muted">
            npm run verify:full
          </code>
          <span className="text-ink-muted">전수조사</span>
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
      <div className="text-xs text-ink-muted">{label}</div>
      <div className={`mt-1 text-2xl font-bold ${color}`}>{value}</div>
    </div>
  );
}
