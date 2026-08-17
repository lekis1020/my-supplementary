# Pipeline Scripts

파이프라인/관리 스크립트 안내. 모든 스크립트는 admin 트랙(service_role 또는
`DATABASE_URL`)으로 실 DB를 만진다. **실행 전 반드시 `--dry-run`(지원 시)으로
확인할 것.** npm wiring의 권위는 `web/package.json`의 scripts 항목.

## 공유 lib (`lib/`)

| 모듈 | 제공 |
|---|---|
| `env.mjs` | `loadEnv()`(web→root 순 .env.local/.env), `requireEnv(...keys)` |
| `supabase.mjs` | `getServiceRoleClient({cliFallback})`, `fetchAllRows()`, resolve* 헬퍼 |
| `batch.mjs` | `chunk(array, size)` |
| `http.mjs` | `fetchJson(url, opts)` — 429/5xx/네트워크/타임아웃 지수 백오프 재시도, `sleep` |
| `jsonl.mjs` | `readJsonl`(스트리밍), `readAllJsonl`, `appendJsonl`, `createJsonlWriter` |

## import 스크립트 멱등성 (scripts-review #10)

supabase-js(REST) 기반 스크립트는 프로토콜상 트랜잭션이 불가하다. 아래 표의
"중단 시" 열을 반드시 숙지할 것.

| 스크립트 | DB 접근 | 쓰기 패턴 | 멱등성 | 중단 시 |
|---|---|---|---|---|
| `import_kr_staging_to_db` | postgres.js | 데이터셋 단위 **트랜잭션**(truncate 옵션+upsert) | ✅ 재실행 안전 | 롤백됨 — 이전 상태 유지 |
| `import_kr_claims_to_supabase` | supabase-js | 순수 upsert (`claim_code`, `ingredient_id,claim_id,approval_country_code`) | ✅ 재실행 안전 | 부분 upsert — 재실행으로 수렴 |
| `import_kr_core_to_supabase` | supabase-js | delete(products, product_ingredients) 후 insert + ingredients upsert | ⚠️ 재실행으로 복구 | 부분 상태 — **완주될 때까지 재실행 필수** |
| `import_kr_dosage_to_supabase` | supabase-js | 전체 delete 후 insert (full refresh) | ⚠️ 재실행으로 복구 | 테이블 비었거나 부분 적재 — 완주 재실행 필수 |
| `import_kr_label_snapshots_to_supabase` | supabase-js | 전체 delete 후 insert | ⚠️ 재실행으로 복구 | 상동 |
| `import_kr_safety_to_supabase` | supabase-js | 전체 delete 후 insert | ⚠️ 재실행으로 복구 | 상동 |
| `enrich_products_from_staging` | supabase-js | row별 update/insert (`--limit`, 기본 50) | ✅ 점진·재실행 안전 | 다음 실행이 이어서 처리 |
| `classify_ingredient_types` | supabase-js | row별 update | ✅ 재실행 안전 | 상동 |

> 주의: staging의 트랜잭션 래핑(2026-08 Phase 3)은 아직 실 DB에서 실행 검증되지 않음 —
> 첫 실 import는 사용자 감독 하에 실행하고 롤백/커밋 동작을 확인할 것.

## 경로 규약

- 스크립트는 `web/scripts/`에서 실행 위치와 무관하게 동작해야 한다:
  `rootDir`는 `import.meta.url` 기준으로 계산하고 `process.cwd()`를 쓰지 않는다.
- 입출력 데이터는 repo 루트의 `tmp/` 아래 (`tmp/kr-gov/`, `tmp/kr-gov-clean/`).
