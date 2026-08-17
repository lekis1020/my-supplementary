# Pipeline Scripts

파이프라인/관리 스크립트 안내. 아래 import/verify 스크립트는 admin 트랙(service_role 또는
`DATABASE_URL`)으로 실 DB를 만진다. **실행 전 반드시 `--dry-run`(지원 시)으로
확인할 것.** npm wiring의 권위는 `web/package.json`의 scripts 항목.

DB에 접근하지 않는 전처리·수집 스크립트는 [맨 아래 섹션](#전처리수집-db-접근-없음생성물)을 참고.

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
- `archive/` 하위는 동결된 구 스크립트로 이 규약(및 공유 lib) 적용 대상이 아니다.

## 전처리·수집 (DB 접근 없음/생성물)

DB를 만지지 않는 파일 변환·외부 API 수집 스크립트. 전처리 체인은
`normalize → map → classify-mentions → promote` 순서로 실행한다(각 단계가
이전 단계의 출력 파일을 입력으로 요구).

| 스크립트 | DB 접근 | 설명 |
|---|---|---|
| `test_korean_gov_apis.mjs` | 없음 | KR 정부 API 연결성 smoke test(read-only fetch) — `npm run gov:smoke:kr` |
| `normalize_kr_gov_dump.mjs` | 없음 | `tmp/kr-gov` → `tmp/kr-gov-clean` 정규화(파일 변환) — `npm run gov:normalize:kr` |
| `map_kr_ingredient_mentions.mjs` | 없음 | 원료 언급(raw label) → canonical 원료 매핑(파일 변환) — `npm run gov:map:kr` |
| `classify_kr_unresolved_mentions.mjs` | 없음 | 미해결 언급을 규칙 기반으로 분류(파일 변환) — `npm run gov:classify-mentions:kr` |
| `promote_kr_active_candidate_mappings.mjs` | 없음 | 고신뢰 active-candidate 매핑을 base 매핑에 승격(파일 변환) — `npm run gov:promote:kr` |
| `fetch_dailymed_labels.mjs` | 없음 | DailyMed API 호출 → `db/011_seed_dailymed_labels.sql` 생성(SQL 시드 생성물) |
| `fetch_pubmed_evidence.py` | 없음 | PubMed E-utilities 호출 → `db/009_seed_evidence.sql` 생성(SQL 시드 생성물, `NCBI_API_KEY` 필요) |
