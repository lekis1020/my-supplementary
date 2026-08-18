# Phase 4 — 스키마 단일화 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 4원화된 스키마 소스(db/*.sql 순번 트리, RUN_THIS_ONLY.sql, supabase/migrations, Drizzle 스키마)를 "supabase/migrations = 유일한 DDL 경로, 원격 스키마 스쿼시 베이스라인 = 재구축 가능한 단일 출발점, db/ = 동결 아카이브, Drizzle = 실DB 기술(descriptive) 미러"로 단일화한다.

**Architecture:** DB 불필요 작업(Drizzle FK 교정, RUN_THIS_ONLY 은퇴)을 먼저, 원격 read-only 덤프 기반 베이스라인 캡처를 그 다음, 규칙 문서화·최종 검증을 마지막에 배치. 원격 DB에는 어떤 쓰기도 하지 않는다 — 마이그레이션 히스토리 정리(`migration repair`)는 런북 산출물로 만들어 사용자 게이트로 넘긴다.

**Tech Stack:** supabase CLI 2.98.2(링크: loqhpykkovwczdckekju, `migration list` 원격 접속 확인됨), Docker Desktop(Task 3 전제 — 사용자 설치 진행 중), drizzle-orm/pg-core

**근거:** `.omc/plans/refactoring-plan-2026-08-10.md` §2-D(F1/F6/F7/F9/F11/F12), §Phase 4. 스키마 서베이(2026-08-18) 확정 사실은 본문 각 태스크에 인라인.

## Global Constraints

- **원격 DB 쓰기 절대 금지** — 이 브랜치에서 허용되는 원격 작업은 read-only뿐(`supabase db dump`, `supabase migration list`). `supabase db push` / `supabase migration repair` / DDL·데이터 변경 금지. repair는 런북 문서로만 산출(실행은 사용자)
- **`drizzle-kit push` 절대 금지** (F12 수정 검증 전까지 잠재 사고 — 근거 계획 §착수 순서)
- 브랜치: `feat/phase4-schema-unification` (main 직접 커밋 금지, 머지는 사용자 PR)
- 커밋: conventional + 마지막 줄 `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`, **`git add -A` 금지** — 명시적 경로만
- 게이트(각 태스크 마지막): `cd /Users/napler/projects/my-supple/web && npm test && npx tsc --noEmit && npm run build && npm run lint` — 기준 **123 테스트**, lint **0 에러/4 경고**
- 자격증명·비밀 값을 출력/커밋하지 말 것(DATABASE_URL, 토큰, .temp 내용 등)
- `docs/superpowers/plans/`·`.omc/`·`.superpowers/` 기존 문서 불변(역사 기록)
- 셸 `cd`가 zoxide 경유 — 절대 경로·단일 복합 명령, cwd가 web/에 남는 함정 주의. macOS에 `timeout` 없음, 대괄호 경로 따옴표
- **범위 제외(후속으로 명시적 이관)**: 4-5의 pgEnum/CHECK 도입(원격 DDL 필요 — 사용자 게이트 별도 건), 4-6 균주 카탈로그·vitamin-side-effects 단일화(독립 서브시스템 — 별도 계획), CI 강제(레포에 CI 인프라 부재 확인 시). RLS "단일 파일 통합"(F11)은 Task 3의 베이스라인 덤프가 현행 정책 전체를 한 파일에 담음으로써 충족됨

---

## 확정 사실 (서베이 2026-08-18, 구현자 참조용)

- 로컬·원격 마이그레이션 히스토리 **완전 동기**: 22개 = placeholder 6(`00010`~`00015`, 각 57B) + `20260316181119_remote_schema.sql`(**0바이트** — F7의 원인) + 타임스탬프 15개(20260317060000 ~ 20260724120000)
- db/0NN 중 **036~040은 supabase/migrations에 미러 없음**(SQL editor/apply_migration으로만 적용됨), 역방향으로 `20260327110000_add_staging_regulatory_standards`는 db/에 없음 → 어느 트리도 단독 완전하지 않음
- `db/RUN_THIS_ONLY.sql`(1,838줄, 172KB)은 **020까지만 반영** — "올인원" 역할 상실(F9). 번호 중복: 015~019 각 2개(F6)
- `db/004_patch_v1.sql` 헤더가 요구 실행 순서 `001 → 004 → 002 → 003`을 문서화(F1: 002가 001에 없는 products.is_published 참조)
- Drizzle: 비-PK `bigserial` **32개**(FK 26 + polymorphic 6) + PK이지만 FK 의미인 `operations.ts:82` 1개 = **총 33개 수정 대상**. `db/drizzle/migrations` out 디렉터리 부재(생성물 없음 — 순수 기술 문서). drizzle-kit ^0.31.9는 web devDependencies
- `web/scripts/map_kr_ingredient_mentions.mjs`가 `db/00*.sql`을 읽고, `fetch_dailymed_labels.mjs`/`fetch_pubmed_evidence.py`가 `db/011`/`db/009`에 씀 → **db/0NN 파일은 이동 금지, 제자리 동결**
- Docker 미설치였음(사용자가 Docker Desktop 설치 진행) → Task 3 시작 시 반드시 `docker info` 확인

---

### Task 1: Drizzle F12 — 비-PK bigserial 33개 → bigint

**Files:**
- Modify: `db/drizzle/schema/claims.ts`, `code-tables.ts`, `collection.ts`, `evidence.ts`, `ingredients.ts`, `operations.ts`, `products.ts`, `sources.ts` (8개)

**Interfaces:**
- Consumes: drizzle-orm/pg-core `bigint` (기존 `bigserial`과 동일 시그니처: `bigint("col_name", { mode: "number" })`)
- Produces: 없음 (기술 문서 교정 — 런타임 코드 아님. 단, 이후 `drizzle-kit generate/push`가 실행될 때 FK에 시퀀스가 붙는 잠재 사고 제거)

- [ ] **Step 1: 각 파일 import에 `bigint` 추가**

예 (`claims.ts`): `import { pgTable, bigserial, varchar, ... }` 목록에 `bigint` 추가. PK가 전부 bigserial로 남는 파일에서도 bigserial import는 유지된다.

- [ ] **Step 2: 33개 컬럼 치환**

치환 패턴 — 기존:

```ts
    ingredientId: bigserial("ingredient_id", { mode: "number" })
      .notNull()
      .references(() => ingredients.id, { onDelete: "cascade" }),
```

→ 신규 (`bigserial` → `bigint`만, 체인·인자 불변):

```ts
    ingredientId: bigint("ingredient_id", { mode: "number" })
      .notNull()
      .references(() => ingredients.id, { onDelete: "cascade" }),
```

전체 대상(파일:라인은 a0b543e 시점 서베이 기준 — 내용 앵커로 확인):

| 파일:라인 | 컬럼 | 비고 |
|---|---|---|
| claims.ts:50 | ingredientId | FK→ingredients.id |
| claims.ts:53 | claimId | FK→claims.id |
| code-tables.ts:30 | codeTableId | FK→codeTables.id |
| collection.ts:25 | sourceId | FK→sources.id |
| collection.ts:55 | sourceConnectorId | FK→sourceConnectors.id |
| collection.ts:87 | collectionJobId | FK→collectionJobs.id |
| collection.ts:115 | sourceConnectorId | FK→sourceConnectors.id |
| collection.ts:147 | rawDocumentId | FK→rawDocuments.id |
| collection.ts:174 | sourceConnectorId | FK→sourceConnectors.id |
| collection.ts:201 | entityId | polymorphic, `.notNull()` (references 없음) |
| collection.ts:202 | sourceConnectorId | FK→sourceConnectors.id (.references는 :204) |
| evidence.ts:25 | ingredientId | FK→ingredients.id |
| evidence.ts:76 | evidenceStudyId | FK→evidenceStudies.id |
| evidence.ts:79 | claimId | FK→claims.id |
| evidence.ts:109 | ingredientId | FK→ingredients.id |
| evidence.ts:112 | claimId | FK→claims.id |
| ingredients.ts:28 | parentIngredientId | 자기참조 FK |
| ingredients.ts:59 | ingredientId | FK→ingredients.id |
| ingredients.ts:82 | ingredientId | FK→ingredients.id |
| ingredients.ts:113 | ingredientId | FK→ingredients.id |
| ingredients.ts:141 | ingredientId | FK→ingredients.id |
| ingredients.ts:151 | sourceId | 참조 없음(관례상 FK) |
| ingredients.ts:169 | ingredientId | FK→ingredients.id |
| ingredients.ts:181 | sourceId | 참조 없음 |
| operations.ts:22 | entityId | polymorphic, `.notNull()` |
| operations.ts:33 | parentTaskId | 자기참조 FK |
| operations.ts:62 | entityId | polymorphic, `.notNull()` |
| operations.ts:82 | ingredientId | **`.primaryKey()`지만 FK 의미(공유 PK)** — `bigint(...).primaryKey()`로 교체 |
| products.ts:57 | productId | FK→products.id |
| products.ts:60 | ingredientId | FK→ingredients.id |
| products.ts:95 | productId | FK→products.id |
| sources.ts:42 | sourceId | FK→sources.id |
| sources.ts:46 | entityId | polymorphic, `.notNull()` |

`id: bigserial({ mode: "number" }).primaryKey()` 형태의 **진짜 PK(테이블당 1개)는 그대로 둔다** (operations.ts:82만 예외 — 위 표 참조).

- [ ] **Step 3: grep 감사**

```bash
cd /Users/napler/projects/my-supple && grep -n "bigserial(" db/drizzle/schema/*.ts | grep -v "primaryKey" ; echo "EXIT:$?"
```

Expected: 출력 없음, `EXIT:1` (남은 bigserial은 전부 같은 줄에 `.primaryKey()`가 있는 진짜 PK). 추가 감사: `grep -c "bigint(" db/drizzle/schema/*.ts` 합계 = 33.

- [ ] **Step 4: (best-effort) drizzle-kit 파싱 확인**

```bash
cd /Users/napler/projects/my-supple/web && npx drizzle-kit generate --config ../db/drizzle/drizzle.config.ts --name f12_parse_check 2>&1 | tail -5
```

목적은 스키마 파일 **파싱 성공 확인뿐**이다. 성공 시 `db/drizzle/migrations/`에 생성물이 생기는데 **절대 커밋하지 말고 즉시 삭제**(`rm -rf /Users/napler/projects/my-supple/db/drizzle/migrations`) — 이 생성물은 "초기 마이그레이션"으로 오인될 수 있는 팬텀이다. 모듈 해석/환경 문제로 실패하면 실패 출력만 기록하고 넘어간다(감사는 Step 3이 담당). **`drizzle-kit push`는 어떤 경우에도 금지.**

- [ ] **Step 5: 전체 게이트 + 커밋**

```bash
cd /Users/napler/projects/my-supple/web && npm test && npx tsc --noEmit && npm run build && npm run lint
cd /Users/napler/projects/my-supple && git status --short -- db/drizzle && git add db/drizzle/schema/claims.ts db/drizzle/schema/code-tables.ts db/drizzle/schema/collection.ts db/drizzle/schema/evidence.ts db/drizzle/schema/ingredients.ts db/drizzle/schema/operations.ts db/drizzle/schema/products.ts db/drizzle/schema/sources.ts && git commit -m "fix(drizzle): use bigint for FK/polymorphic id columns (33 cols, F12)

bigserial on non-PK columns would mint a phantom sequence per column
if drizzle-kit ever generated DDL. Descriptive-only change; no runtime code.

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

(`git status --short`에서 `db/drizzle/migrations/` 잔존물이 보이면 커밋 전에 삭제)

---

### Task 2: RUN_THIS_ONLY 은퇴 + db/ 동결 선언

**Files:**
- Move(git mv): `db/RUN_THIS_ONLY.sql` → `db/archive/RUN_THIS_ONLY.sql`
- Create: `db/README.md`

**Interfaces:**
- Consumes: 없음
- Produces: `db/README.md` (Task 4의 CLAUDE.md 갱신이 이 파일을 참조)

**주의:** db/0NN 순번 파일은 **이동하지 않는다**(제자리 동결) — `web/scripts/map_kr_ingredient_mentions.mjs`가 `db/00*.sql`을 읽고, `fetch_dailymed_labels.mjs`·`fetch_pubmed_evidence.py`가 `db/011`·`db/009`를 재생성하기 때문.

- [ ] **Step 1: RUN_THIS_ONLY 아카이브 이동**

```bash
cd /Users/napler/projects/my-supple && mkdir -p db/archive && git mv db/RUN_THIS_ONLY.sql db/archive/RUN_THIS_ONLY.sql
```

- [ ] **Step 2: `db/README.md` 작성** (아래 내용 verbatim)

```markdown
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
- `web/scripts/fetch_dailymed_labels.mjs` → `db/011_seed_us_labels...` 계열,
  `web/scripts/fetch_pubmed_evidence.py` → `db/009_seed_evidence.sql`은
  시드 **생성물**을 여기에 쓴다(스키마 DDL 아님 — 허용).
- `db/drizzle/`은 실DB의 기술(descriptive) 미러다. DDL 생성 경로가 아니며
  `drizzle-kit push`는 금지.
```

- [ ] **Step 3: 잔존 참조 grep + 갱신**

```bash
cd /Users/napler/projects/my-supple && grep -rn "RUN_THIS_ONLY" --include="*.md" --include="*.ts" --include="*.mjs" --include="*.json" . 2>/dev/null | grep -v "docs/superpowers\|.omc/\|.superpowers/\|db/archive\|db/README"
```

나온 것(예상: CLAUDE.md, 가능하면 GEMINI.md) 중 **CLAUDE.md는 Task 4에서 일괄 갱신하므로 여기서 건드리지 않는다**. GEMINI.md 등 다른 문서에 경로 참조가 있으면 `db/archive/RUN_THIS_ONLY.sql`(은퇴 명시)로 갱신.

- [ ] **Step 4: 전체 게이트 + 커밋**

```bash
cd /Users/napler/projects/my-supple/web && npm test && npx tsc --noEmit && npm run build && npm run lint
cd /Users/napler/projects/my-supple && git add db/archive/RUN_THIS_ONLY.sql db/README.md && git status --short && git commit -m "docs(db): retire RUN_THIS_ONLY to archive; declare db/ tree frozen (F6/F9)

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

(git mv rename이 스테이징됐는지 `git status --short`로 확인 — 구경로가 누락이면 `git add db/RUN_THIS_ONLY.sql`도 추가. GEMINI.md를 고쳤다면 경로 추가)

---

### Task 3: 원격 스키마 베이스라인 캡처 + repair 런북 (F7/F9 해소)

**Files:**
- Move(git mv): `supabase/migrations/*.sql` (22개 전부) → `db/archive/supabase-migrations-pre-squash/`
- Create: `supabase/migrations/20260818090000_baseline.sql` (read-only 원격 덤프)
- Create: `db/MIGRATION_REPAIR_RUNBOOK.md`

**Interfaces:**
- Consumes: supabase CLI(링크 loqhpykkovwczdckekju, 로그인 세션 유효 — `migration list`로 확인됨), Docker Desktop(전제)
- Produces: 베이스라인 파일명 `20260818090000_baseline.sql` (Task 4의 CLAUDE.md가 참조)

- [ ] **Step 1: Docker 확인 (실패 시 BLOCKED 보고)**

```bash
docker info >/dev/null 2>&1 && echo DOCKER_OK || echo DOCKER_UNAVAILABLE
```

`DOCKER_UNAVAILABLE`이면 여기서 멈추고 BLOCKED 보고(사용자가 Docker Desktop 설치/실행 중). **다른 대체 경로를 임의로 시도하지 말 것.**

- [ ] **Step 2: 기존 마이그레이션 아카이브**

```bash
cd /Users/napler/projects/my-supple && mkdir -p db/archive/supabase-migrations-pre-squash && git mv supabase/migrations/*.sql db/archive/supabase-migrations-pre-squash/ && ls supabase/migrations/ | wc -l
```

Expected: `0` (빈 디렉터리)

- [ ] **Step 3: read-only 원격 덤프 → 베이스라인**

```bash
cd /Users/napler/projects/my-supple && supabase db dump --linked -f supabase/migrations/20260818090000_baseline.sql 2>&1 | tail -3 && wc -l supabase/migrations/20260818090000_baseline.sql
```

이 명령은 원격을 **읽기만** 한다(pg_dump). 수 분 걸릴 수 있음.

- [ ] **Step 4: 베이스라인 내용 검증 (F7 해소 증거)**

```bash
cd /Users/napler/projects/my-supple && for pat in "is_published" "scan_events" "product_enrichment_queue" "staging_regulatory_standards" "safety_items" "sale_channel" "is_admin"; do printf "%s: " "$pat"; grep -c "$pat" supabase/migrations/20260818090000_baseline.sql; done; printf "CREATE TABLE: "; grep -c "CREATE TABLE" supabase/migrations/20260818090000_baseline.sql; printf "CREATE POLICY: "; grep -c "CREATE POLICY" supabase/migrations/20260818090000_baseline.sql
```

Expected: 모든 패턴 카운트 ≥ 1 (특히 `staging_regulatory_standards`·`sale_channel`은 양 트리 드리프트가 모두 캡처됐다는 증거), CREATE TABLE ≥ 28, CREATE POLICY ≥ 20. 미달 항목이 있으면 **커밋하지 말고** 해당 grep 결과와 함께 보고(덤프 옵션/스키마 범위 문제 가능성).

- [ ] **Step 5: `db/MIGRATION_REPAIR_RUNBOOK.md` 작성** (아래 verbatim)

```markdown
# 마이그레이션 히스토리 repair 런북 (사용자 실행 전용)

베이스라인 스쿼시(2026-08-18) 후 로컬 마이그레이션은
`20260818090000_baseline.sql` 하나지만, 원격 히스토리 테이블
(`supabase_migrations.schema_migrations`)에는 구 22개 항목이 남아 있다.
이 불일치는 **의도된 중간 상태**다. 아래 repair는 원격의 **메타데이터
테이블만** 고치며 스키마 자체는 건드리지 않는다 — 그래도 원격 쓰기이므로
사용자가 직접 실행한다.

## ⚠️ repair 완료 전 절대 금지

- `supabase db push` — 베이스라인을 "미적용 마이그레이션"으로 오인해
  전체 스키마 재적용을 시도한다. **repair가 끝나기 전까지 push 금지.**

## 실행 순서 (repo 루트에서)

1. 구 항목 22개를 reverted로 마킹:

```bash
supabase migration repair --status reverted 00010 00011 00012 00013 00014 00015 \
  20260316181119 20260317060000 20260317061500 20260317153000 20260317160000 \
  20260317163000 20260324061500 20260327110000 20260412120000 20260412130000 \
  20260412140000 20260412150000 20260412160000 20260413120000 20260413120100 \
  20260724120000
```

2. 베이스라인을 applied로 마킹:

```bash
supabase migration repair --status applied 20260818090000
```

3. 확인 — Local과 Remote가 `20260818090000` 한 줄로 일치해야 한다:

```bash
supabase migration list
```

## 이후

- 신규 DDL은 `supabase migration new <name>`으로 만들고 `supabase db push`로
  적용한다(이 시점부터 push 허용).
- 구 마이그레이션 원본은 `db/archive/supabase-migrations-pre-squash/`에 보존.
```

- [ ] **Step 6: 로컬 히스토리 불일치 상태 기록(정보성)**

```bash
cd /Users/napler/projects/my-supple && supabase migration list 2>&1 | tail -8
```

Expected: Local에 `20260818090000`만, Remote에 구 22개 — **의도된 중간 상태**(런북 실행 전). 출력을 보고서에 첨부.

- [ ] **Step 7: 전체 게이트 + 커밋**

```bash
cd /Users/napler/projects/my-supple/web && npm test && npx tsc --noEmit && npm run build && npm run lint
cd /Users/napler/projects/my-supple && git add supabase/migrations/20260818090000_baseline.sql "db/archive/supabase-migrations-pre-squash" db/MIGRATION_REPAIR_RUNBOOK.md && git status --short && git commit -m "feat(db): squash remote schema into single baseline migration (F7/F9)

- capture remote schema via read-only supabase db dump
- archive 22 legacy migrations (6 placeholders + 0-byte baseline + 15 real)
- add user-gated migration repair runbook; db push forbidden until repaired

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

(rename 누락이 `git status --short`에 보이면 해당 경로 명시 add)

---

### Task 4: 규칙 확립(CLAUDE.md) + 최종 검증

**Files:**
- Modify: `CLAUDE.md` (프로젝트 루트)

**Interfaces:**
- Consumes: Task 2의 `db/README.md`, Task 3의 베이스라인 파일명·런북
- Produces: 없음

- [ ] **Step 1: CLAUDE.md Database 섹션 교체**

기존:

```markdown
### Database
- **Schema DDL**: `db/001_schema.sql` (28+ tables, canonical source of truth)
- **All-in-one migration**: `db/RUN_THIS_ONLY.sql` (consolidated: schema + seeds + enrichments)
- **RLS policies**: `db/002_rls_policies.sql`
- **Drizzle config**: `db/drizzle/drizzle.config.ts` (schema at `db/drizzle/schema/`)
```

→ 신규:

```markdown
### Database
- **신규 DDL 단일 경로**: `supabase/migrations/` (timestamped). 다른 어디에도 DDL을 추가하지 말 것
- **베이스라인**: `supabase/migrations/20260818090000_baseline.sql` — 원격 스키마 스쿼시(RLS·함수 포함, 시드 제외). 히스토리 repair 전 `supabase db push` 금지 — `db/MIGRATION_REPAIR_RUNBOOK.md` 참조
- **동결 아카이브**: `db/0NN_*.sql`(제자리 동결) + `db/archive/` — 역사 기록, 실행·수정 금지. 배경은 `db/README.md`
- **Drizzle**: `db/drizzle/schema/` — 실DB 기술(descriptive) 미러. 스키마 변경 시 함께 갱신하되 `drizzle-kit push` 금지
```

- [ ] **Step 2: CLAUDE.md Key Conventions의 SQL migrations 불릿 교체**

기존: `- **SQL migrations**: Numbered sequentially (\`001_\`, \`002_\`, ...). Drizzle schema in \`db/drizzle/schema/\` mirrors the SQL DDL.`

→ 신규: `- **SQL migrations**: 신규 DDL은 \`supabase/migrations/\`의 timestamped 파일로만 (\`supabase migration new <name>\`). \`db/\`의 순번 파일(001~041)은 동결. Drizzle 스키마는 실DB 미러로 함께 갱신.`

(Key Conventions의 "Seed data files" 불릿도 `RUN_THIS_ONLY.sql consolidates everything` 문구가 있으므로 `- **Seed data files**: \`003\`-\`020\`에 역사적 시드 보존(동결). 신규 시드는 스크립트 생성물(\`db/009\`, \`db/011\`)만 갱신.`으로 교체)

- [ ] **Step 3: 최종 정합 grep**

```bash
cd /Users/napler/projects/my-supple && echo "--- RUN_THIS_ONLY 잔존(허용 목록 밖):" && (grep -rn "RUN_THIS_ONLY" --include="*.md" --include="*.mjs" --include="*.ts" . 2>/dev/null | grep -v "docs/superpowers\|.omc/\|.superpowers/\|db/archive\|db/README" || echo NONE) && echo "--- 비-PK bigserial:" && (grep -n "bigserial(" db/drizzle/schema/*.ts | grep -v primaryKey || echo NONE) && echo "--- supabase/migrations 내용:" && ls supabase/migrations/
```

Expected: 두 grep 모두 `NONE`, migrations에는 `20260818090000_baseline.sql` 하나.

- [ ] **Step 4: 전체 게이트 + 커밋**

```bash
cd /Users/napler/projects/my-supple/web && npm test && npx tsc --noEmit && npm run build && npm run lint
cd /Users/napler/projects/my-supple && git add CLAUDE.md && git commit -m "docs: establish supabase/migrations as the single DDL path (4-4)

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

## 최종 검증 (finishing 전, 컨트롤러)

1. Task 4 Step 3의 정합 grep 재실행 — 전부 NONE/기대값
2. 게이트 전체 통과(123 테스트, lint 0/4)
3. `supabase migration list` 상태(로컬 1개 vs 원격 22개 — 런북 실행 전 의도 상태) 캡처
4. PR 설명에 명기: (a) 원격 DB 무변경 — repair는 사용자 런북, (b) repair 전 `db push` 금지 경고, (c) 4-5 enum/CHECK·4-6 균주 카탈로그·CI 강제는 명시적 범위 제외
