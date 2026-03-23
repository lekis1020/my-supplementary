/**
 * track-refresh.mjs
 *
 * Import 스크립트 실행 후 entity_refresh_states에 갱신 이력을 기록하는 공유 헬퍼.
 * entity_id = 0 을 batch-level sentinel로 사용하여 "이 entity_type이
 * 마지막으로 갱신된 시점"을 추적한다.
 *
 * Usage:
 *   import { trackRefresh } from "./lib/track-refresh.mjs";
 *   await trackRefresh(supabase, { entityType: "product", recordsProcessed: 100 });
 */

const BATCH_SENTINEL_ID = 0;

/**
 * @param {import("@supabase/supabase-js").SupabaseClient} supabase
 * @param {Object} opts
 * @param {string} opts.entityType - 'product', 'ingredient', 'claim', etc.
 * @param {number} [opts.recordsProcessed] - 처리된 레코드 수
 * @param {string} [opts.status] - 'success' | 'partial' | 'failed'
 */
export async function trackRefresh(supabase, opts) {
  const {
    entityType,
    recordsProcessed = 0,
    status = "success",
  } = opts;

  const now = new Date().toISOString();

  try {
    const { data: existing } = await supabase
      .from("entity_refresh_states")
      .select("id")
      .eq("entity_type", entityType)
      .eq("entity_id", BATCH_SENTINEL_ID)
      .is("source_connector_id", null)
      .maybeSingle();

    const payload = {
      last_fetched_at: now,
      last_changed_at: recordsProcessed > 0 ? now : undefined,
      last_refresh_status: status,
      last_checksum: String(recordsProcessed),
      refresh_priority: "normal",
    };

    // undefined 필드 제거 (변경 없으면 last_changed_at 유지)
    for (const key of Object.keys(payload)) {
      if (payload[key] === undefined) delete payload[key];
    }

    if (existing) {
      const { error } = await supabase
        .from("entity_refresh_states")
        .update(payload)
        .eq("id", existing.id);

      if (error) throw error;
    } else {
      const { error } = await supabase
        .from("entity_refresh_states")
        .insert({
          entity_type: entityType,
          entity_id: BATCH_SENTINEL_ID,
          source_connector_id: null,
          ...payload,
        });

      if (error) throw error;
    }

    console.log(
      `[refresh-tracker] ${entityType}: status=${status}, records=${recordsProcessed}`,
    );
  } catch (err) {
    // 갱신 추적 실패가 import 전체를 중단시키면 안 됨
    console.warn(
      `[refresh-tracker] ${entityType}: tracking failed — ${err.message}`,
    );
  }
}
