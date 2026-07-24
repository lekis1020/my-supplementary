import { createClient } from "@supabase/supabase-js";

/**
 * service_role Supabase 클라이언트 — 서버 전용 (RLS 우회).
 * 파이프라인성 쓰기(실시간 검색 결과 적재, 보강 큐 등록)에만 사용.
 * 소비자 조회는 반드시 lib/supabase/server.ts(RLS 적용)를 사용할 것.
 */
export function createAdminClient() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

  if (!url || !serviceRoleKey) {
    throw new Error("NEXT_PUBLIC_SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY 미설정");
  }

  return createClient(url, serviceRoleKey, {
    auth: { persistSession: false },
  });
}
