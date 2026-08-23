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
