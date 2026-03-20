# Evidence Gap Operations

원료 사전에서 **효능 근거가 비어 있거나 불충분한 원료**를 추출하고,
우선순위를 산정해 보강 작업을 자동화하는 운영 절차입니다.

## 1) DB 뷰 생성

먼저 아래 SQL을 실행해 갭 분석 뷰를 생성합니다.

- `db/023_evidence_gap_views.sql`

생성되는 뷰:

- `ingredient_evidence_coverage`
- `ingredient_evidence_gaps`

기본 조회:

```sql
SELECT *
FROM ingredient_evidence_gaps
ORDER BY gap_level, risk_score DESC;
```

## 2) 갭 리포트 생성

```bash
cd web
node scripts/report_ingredient_evidence_gaps.mjs --limit=100
```

출력:

- 콘솔 요약
- `.omx/reports/ingredient-evidence-gaps-YYYYMMDD.md`

JSON 출력:

```bash
node scripts/report_ingredient_evidence_gaps.mjs --limit=100 --json
```

## 3) 검수 태스크 자동 등록 (선택)

```bash
node scripts/report_ingredient_evidence_gaps.mjs --limit=50 --enqueue-review-tasks
```

- `review_tasks`에 `content_update`(L1, pending) 태스크를 생성합니다.
- 이미 pending/in_progress 태스크가 있으면 중복 생성하지 않습니다.

## 갭 우선순위 기준

- `critical`: 클레임은 있는데 요약 논문이 0건
- `high`: 클레임 일부가 evidence_outcomes로 매핑되지 않음
- `medium`: 원료/논문 출처 링크가 비어 있음
- `low`: 나머지

`risk_score`는 위 조건을 가중치로 합산한 값입니다.
