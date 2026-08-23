# db/ — 동결된 스키마 역사 아카이브 (2026-08-18)

**이 디렉터리는 동결되었다. 새 DDL을 여기에 추가하지 말 것.**
신규 DDL의 유일한 경로는 repo 루트의 `supabase/migrations/`(timestamped)다.

## 왜 동결인가

`db/0NN_*.sql`(001~041)은 2026-03~07의 실제 적용 이력이지만, 단독으로 DB를
재구축할 수 없다:

- `002_rls_policies.sql`이 `001_schema.sql`에 없는 `products.is_published`를
  참조한다(당시 요구 순서는 `001 → 004 → 002 → 003`, `004_patch_v1.sql` 헤더 참조).
- 번호 중복: 015~019가 각각 2개씩 존재한다(두 작업 트랙의 번호 충돌).
  중복 쌍: 015 enrich_evidence_phase2 / expand_dosage_precision,
  016 cleanup_duplicates / probiotic_strains,
  017 fix_evidence_mappings / smart_ingredient_cleanup,
  018 aggressive_ingredient_cleanup_test / seed_missing_evidence,
  019 global_aggressive_cleanup / seed_final_evidence.
- `archive/RUN_THIS_ONLY.sql`(구 "올인원")은 020까지만 반영되어 은퇴했다.
- 036~040은 supabase/migrations에 미러가 없고, 역으로
  `20260327110000_add_staging_regulatory_standards`는 db/에 없다 —
  어느 트리도 단독 완전하지 않았다.

현행 스키마의 단일 출발점은 `supabase/migrations/`의 **베이스라인 스쿼시**
(원격 스키마 read-only 덤프)다. 베이스라인은 스키마·RLS·함수를 담고,
시드 데이터는 담지 않는다(역사적 시드는 이 디렉터리의 003~020에 남아 있다).

## 여전히 살아 있는 것

- `web/scripts/map_kr_ingredient_mentions.mjs`가 `db/00*.sql` 시드를 **읽는다**
  (성분 카탈로그 파싱) — 그래서 0NN 파일은 이동이 아니라 제자리 동결이다.
- `web/scripts/fetch_dailymed_labels.mjs`의 스크립트 출력은
  `db/011_seed_dailymed_labels.sql`(신규 생성)이며, 트리의 기존
  `011_seed_us_labels.sql`은 과거 산출물로 동결(둘은 다른 파일).
  `web/scripts/fetch_pubmed_evidence.py` → `db/009_seed_evidence.sql`은
  시드 **생성물**을 여기에 쓴다(스키마 DDL 아님 — 허용).
- `db/drizzle/`은 실DB의 기술(descriptive) 미러다. DDL 생성 경로가 아니며
  `drizzle-kit push`는 금지.

## 베이스라인 재실행(replay) 주의

베이스라인은 원격 스키마의 **기록**이며, 히스토리 repair(메타데이터)에는 실행이
필요 없다. 새 환경 부트스트랩 등으로 **직접 재실행할 경우** 다음을 먼저 처리할 것:

1. `CREATE EXTENSION` 문이 덤프에 없음 — 최소 `pg_trgm`을 `public` 스키마에
   설치해야 함(`idx_product_aliases_alias_trgm`이 요구).
2. `CREATE SCHEMA public;`이 IF NOT EXISTS 없이 포함 — Supabase 환경에서는
   해당 줄이 에러를 내므로 skip 필요.
3. `rls_auto_enable()` 함수는 덤프에 있으나 이를 바인딩하는 `CREATE EVENT TRIGGER`는
   pg_dump 범위 밖(DB 전역 객체) — 재실행 후 이벤트 트리거를 별도 재생성하지 않으면
   RLS 자동 활성화 안전망이 사라진다.
4. 덤프 첫/끝 줄의 `\restrict`/`\unrestrict`는 pg_dump 18 지시어 — psql 18+ 필요.
