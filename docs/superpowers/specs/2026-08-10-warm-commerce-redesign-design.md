# NutriCompare 웜 커머스 리디자인 — 디자인 스펙

- 날짜: 2026-08-10
- 상태: 사용자 승인 완료 (브레인스토밍 세션에서 시각 목업으로 검증)
- 관련 문서: `.omc/plans/refactoring-plan-2026-08-10.md` (구조 리팩토링 Phase 0–4 계획)

## 1. 배경과 목표

전체 코드 리팩토링(Phase 0–4)과 함께 UI를 전면 리디자인한다. 사용자가 시각 목업 비교로 확정한 방향:

| 결정 항목 | 선택 | 비고 |
|---|---|---|
| 무드 | **웜 커머스** (토스·컬리 계열) | 클리니컬/데이터캔버스 안 대비 선택 |
| 팔레트 | **선셋 앰버** (오렌지 포인트 + 크림 베이스) | 코랄/그린 안 대비 선택 |
| 성분 상세 레이아웃 | **요약 대시보드 + 펼침 상세** | 롱스크롤/탭 안 대비 선택 |
| 적용 범위 | 소비자 페이지 전체 + admin | admin은 시스템 상속만, 별도 장식 없음 |
| 타이포그래피 | **Pretendard** (variable, next/font/local) | Geist 제거 |
| 테마 | **라이트 전용** | 다크모드 없음 |
| 실행 방식 | **통합 실행** — Phase 2 구조 재편과 리디자인을 페이지당 한 번에 | Phase 1(타입 복구) 선행 필수 |

성공 기준: 모든 페이지가 새 디자인 시스템 토큰·프리미티브만으로 스타일링되고(하드코딩 색상 클래스 제거), 규제/근거 시각 분리가 컴포넌트 수준에서 강제되며, 페이지당 리팩토링+리디자인이 단일 작업으로 완료된다.

## 2. 디자인 시스템 기반 (토큰)

`web/src/app/globals.css`의 Tailwind 4 `@theme`에 시맨틱 토큰을 정의한다. 페이지·컴포넌트는 원색 클래스가 아닌 시맨틱 토큰을 참조한다.

### 2.1 컬러

- **브랜드/액션**: `--color-brand` #f97316 (orange-500 계열), `--color-brand-soft` #fdba74, `--color-brand-bg` #fff7ed
- **캔버스/서피스**: `--color-canvas` #fffbf5 (크림 배경), `--color-surface` #ffffff (카드)
- **텍스트**: stone 스케일로 통일 — `--color-ink` #292524, `--color-ink-muted` #78716c, `--color-ink-faint` #a8a29e. 기존 gray/slate 혼용을 stone으로 일원화한다.
- **분리 보존 토큰(팔레트 독립, 변경 금지)**:
  - `--color-regulatory` 블루 계열 (#1d4ed8 / bg #eff6ff) — 식약처 인정 효능 전용
  - `--color-evidence-a` ~ `--color-evidence-i` — 학술 근거 등급 스케일
  - `--color-danger` 레드 계열 — 주의·경고·상호작용
- 그림자: 웜 톤 `rgba(120,80,20,…)` 2단계 (`--shadow-card`, `--shadow-card-hover`)

### 2.2 타이포그래피

- Pretendard Variable을 `next/font/local`로 로드, `--font-sans`에 연결. Geist 폰트 로드 제거.
- 스케일: 페이지 제목 `text-2xl font-800`, 섹션 제목 `text-lg font-700`, 본문 `text-sm`, 메타 `text-xs`.

### 2.3 형태

- 라운드: 카드 `rounded-2xl`, 버튼·입력 `rounded-xl`, 배지 `rounded-full`(태그형) / `rounded-md`(규제형 — 형태로도 구분).
- 라이트 테마 전용. 다크모드 토큰은 만들지 않는다.

## 3. 컴포넌트 계층 (`web/src/components/ui/`)

리팩토링 리뷰에서 확인된 공용 프리미티브 부재·Badge variant 미구현·Card 색상 하드코딩 문제를 여기서 해소한다.

### 3.1 Badge 재구축
- `variant` prop 실제 구현: `regulatory` | `evidence` | `severity` | `tag` | `promo`.
- 도메인 래퍼: `<RegulatoryBadge>`(식약처 인정, 블루 + 공식 아이콘), `<EvidenceGradeBadge grade>`(등급별 색), `<SeverityBadge level>`. 라벨 문자열과 색상 클래스를 한 파일에서 co-locate — 기존 `utils.ts`의 라벨/색상 분리 유지보수 문제 해소.

### 3.2 Card 재정의
- 레이아웃 전용으로 축소. `tone`(surface/highlight)과 `padding` variant. gray 하드코딩 제거, 토큰 참조.

### 3.3 신규 프리미티브
- `<SummaryStat>` — 요약 대시보드 지표 타일 (값 + 라벨, 강조색 지정 가능)
- `<CollapsibleSection>` — 네이티브 `<details>/<summary>` 기반 펼침 섹션 (JS 최소화, 서버 컴포넌트 호환)
- `<SectionHeader>` — 아이콘 + 제목 + 카운트 배지 (compare-workbench에서 4회 반복되던 패턴)
- `<CTAButton>` — 앰버 주 버튼 / 아웃라인 보조 버튼

## 4. 페이지별 적용

- **성분 상세 (`/ingredients/[slug]`)**: 상단 히어로(성분명 + 규제 배지 + `<SummaryStat>` 3종: 근거등급·인정효능 수·주의사항 수) → `<CollapsibleSection>`으로 효능(기본 펼침)·안전성·상호작용·용량·근거연구·관련제품(기본 접힘). Phase 2-2 페이지 분해와 동시 진행.
- **홈/성분목록/제품목록**: 새 `ProductCard`/`IngredientCard` — design-lab 프로토타입의 함량 프로그레스 바·가성비 아이디어를 앰버 팔레트로 이식.
- **비교 (`/compare`)**: 분해된 비교 컴포넌트에 적용. 비교표 헤더 스티키, 차이 나는 값에 앰버 하이라이트.
- **검색 (`/search`)**: 새 프리미티브로 결과 카드·페이지네이션 교체.
- **프로바이오틱스 (`/probiotics`)**: 균주 비교 테이블에 동일 시스템 적용.
- **admin (`/admin/*`)**: 토큰·프리미티브 상속만. 밀도 높은 테이블 유지, 장식 최소.

## 5. 실행 통합 — 리팩토링 계획과의 결합

`.omc/plans/refactoring-plan-2026-08-10.md`의 Phase 2를 다음과 같이 수정한다:

- **Phase 2-0 (신설, 선행)**: 디자인 시스템 구축 — §2 토큰 + Pretendard + §3 프리미티브. 기존 페이지 무변경, 독립 PR.
- **Phase 2-2~2-7**: 각 페이지 분해 시 새 프리미티브로 조립해 구조+디자인을 페이지당 한 번에 완료. 적용 순서: 성분 상세 → 홈/목록 → 비교 → 검색 → admin.
- Phase 0(보안)·1(타입)·3(스크립트)·4(스키마)는 디자인과 무관하게 기존 계획 유지. **Phase 1 완료 전 Phase 2-2 이후 착수 금지** (타입 안전망 선행).

## 6. 규제 준수 시각 규칙 (불변 요건)

1. 식약처 인정 효능: `<RegulatoryBadge>` 블루 + 공식 아이콘으로만 표시.
2. 학술 근거: `<EvidenceGradeBadge>` 등급색으로만 표시. 규제 배지와 시각적으로 혼동 불가해야 함(색+형태 이중 구분).
3. 비인정 표현: 효능으로 렌더링 금지 (기존 규칙 유지).
4. 위 3분리는 도메인 배지 컴포넌트에 캡슐화해 페이지가 임의 스타일로 우회할 수 없게 한다.

## 7. 검증

- 페이지 적용 시마다 `npm run build` 통과 + 주요 페이지 스크린샷 확인.
- 대비: 앰버/크림 조합 WCAG AA — `#f97316` 배경 위 흰 텍스트는 큰/굵은 텍스트에만 허용, 본문 텍스트는 `--color-ink` 계열.
- 추출된 순수 로직(비교 계산, 단위 변환 등)은 vitest 테스트 동반 (리팩토링 계획 2-8과 공유).
- 규제 분리: 성분 상세·비교 페이지에서 규제 배지와 근거 배지가 동시에 보이는 화면을 육안 검증 체크리스트에 포함.

## 8. 범위 제외 (YAGNI)

- 다크모드, 애니메이션 라이브러리 도입, 일러스트/캐릭터 자산, 마케팅 랜딩 리뉴얼, 모바일 앱 셸.
