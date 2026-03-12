# 운영 정책

> Version: 1.0.0
> 작성일: 2026-03-12

---

## 1. 환경 분리

| 환경 | 웹앱 | DB | 용도 |
|------|------|----|------|
| **dev** | Vercel Preview | Supabase 별도 프로젝트 (Free) | 개발·단위 테스트 |
| **staging** | Vercel Preview Branch | Supabase staging 스키마 | 통합 테스트, 검수 테스트 |
| **production** | Vercel Production | Supabase Pro (도쿄) | 서비스 운영 |

- 브라우저 에이전트: dev/staging/production 분리 (테스트 중 차단 방지)
- API 키: 환경별 별도 발급

---

## 2. 배포 정책

### 배포 흐름
```
feature branch → PR → staging 자동 배포 → 검증 → main merge → production 자동 배포
```

### 승인 절차
- **코드 변경**: PR 리뷰 1명 이상 승인 → main merge → Vercel 자동 배포
- **DB 마이그레이션**: `drizzle-kit` migration → staging 적용·검증 → production 수동 실행
- **검수 규칙 변경**: L1 자동 규칙 변경 시 staging에서 테스트 후 적용
- **수집기 변경**: 파서/selector 변경 시 staging에서 테스트 수집 후 적용

### 롤백 절차
- **웹앱**: Vercel 대시보드에서 이전 배포로 즉시 롤백 (1분 내)
- **DB 스키마**: 역방향 migration 스크립트 준비 필수
- **DB 데이터**: Supabase PITR로 특정 시점 복원 (Pro 플랜)
- **수집 데이터 오류**: `raw_documents` 보존되어 있으므로 재파싱으로 복구

---

## 3. 백업 정책

| 대상 | 방법 | 주기 | 보관 |
|------|------|------|------|
| **PostgreSQL** | Supabase PITR | 연속 (Pro) | 7일 (기본) |
| **PostgreSQL** | `pg_dump` 수동 | 주 1회 | 90일 (R2) |
| **Raw Documents (R2)** | R2 자체 내구성 | - | 1년 (lifecycle rule) |
| **코드** | GitHub | 자동 | 영구 |
| **환경 변수** | Vercel + Supabase Vault | 변경 시 | Git에 포함하지 않음 |

---

## 4. 장애 대응

### 장애 등급

| 등급 | 정의 | 대응 시간 |
|------|------|-----------|
| **P1 긴급** | 서비스 전면 장애, 데이터 유출 | 30분 내 대응 |
| **P2 높음** | 주요 기능 장애 (검색 불가, 제품 비교 불가) | 2시간 내 대응 |
| **P3 보통** | 부분 기능 장애 (특정 소스 수집 실패) | 1일 내 대응 |
| **P4 낮음** | 사소한 UI 이슈, 데이터 지연 | 주간 처리 |

### 대응 절차
1. 장애 감지 (모니터링 알림 또는 사용자 보고)
2. 등급 판정
3. 담당자 할당
4. 원인 분석 + 임시 조치
5. 근본 원인 해결
6. 사후 분석 보고서 (P1/P2만)

---

## 5. 수집기 장애 대응

### scraper 차단 대응
- 1차: User-Agent/헤더 변경
- 2차: 요청 간격 늘리기 (rate limit 조정)
- 3차: IP 차단 시 수집 일시 중지, 수동 확인
- 원칙: robots.txt/이용약관 준수, 과도한 요청 금지

### 소스 사이트 구조 변경
- selector 깨짐 감지: 파서 실패율 > 10% 알림
- 파서 버전 관리: `extraction_version` 으로 추적
- fallback selector 준비 (주요 소스)
- 긴급 시 해당 소스 수집 일시 중지 → 수동 파서 업데이트

### API 변경 대응
- API 응답 포맷 변경 감지: JSON schema 검증
- API 키 만료: 갱신 알림 (만료 30일 전)
- API 서비스 중단: 대체 소스 또는 캐시 데이터 사용

---

## 6. 데이터 품질 정책

### Soft Delete
외부 소스에서 사라진 데이터는 즉시 삭제하지 않음:
- `active` → 정상 운영
- `inactive` → 비활성 (소스에서 미발견, 30일 후 자동)
- `superseded` → 새 버전으로 대체됨
- `source_missing` → 소스 자체가 사라짐

### Stale Data 관리
- `entity_refresh_states.last_fetched_at` 기준
- staleness_days 초과 시 알림
- 90일 미갱신 데이터: `is_published = FALSE` 검토 대상

### 정합성 점검
- 월 1회: 전수 checksum 검증 (full sync)
- 주 1회: 주요 원료 20종 incremental 검증
- 일 1회: 신규/변경 건 자동 검증 (L1)

---

## 7. 모니터링

### 필수 알림

| 항목 | 임계값 | 채널 |
|------|--------|------|
| 수집 job 실패 | 연속 3회 | 즉시 (Slack/Email) |
| 파서 실패율 | > 10% | 즉시 |
| API 응답 지연 | p95 > 500ms | 즉시 |
| DB storage | > 80% | 즉시 |
| 검수 적체 | > 50건 | 일간 |
| 소스 미갱신 | > staleness_days | 일간 |
| SLA 초과 | 건별 | 즉시 (담당자) |

### 대시보드 지표
- 서비스: 페이지뷰, 검색 쿼리, API 응답시간
- 수집: job 성공률, 소스별 상태, raw_documents 증가량
- 검수: 레벨별 대기/처리/반려 건수, 평균 처리시간
- 데이터: 원료/제품/논문 수, stale 비율, 게시율

---

## 8. 보안 정책

### 접근 제어
- 소비자: Supabase RLS → `is_published = TRUE` 자동 강제
- Admin: Supabase Auth → 역할 기반 (QA, scientific_reviewer, regulatory_reviewer, admin)
- 수집 파이프라인: Drizzle (service role key) → 전체 접근

### 민감 데이터
- API 키: Supabase Vault 또는 Vercel 환경 변수
- DB 접속 정보: 환경 변수 (코드에 포함 금지)
- 사용자 데이터: MVP에서는 수집하지 않음 (Phase 3 내 영양제함에서 고려)

### 감사 로그
- `revision_histories`: 모든 데이터 변경 이력
- `review_tasks`: 검수 판정 이력 (승인/반려 사유 포함)
- `collection_runs`: 수집 실행 이력
