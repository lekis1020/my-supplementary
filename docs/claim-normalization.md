# Claim Normalization

## Decision

- `raw_claim_text`는 항상 보존한다.
- `도움`, `도움을 줌`, `도움을 줄 수 있음`은 하나의 canonical support claim으로 통합한다.
- `필요`는 support와 분리한다.
- `위험 감소에 도움을 줌`은 별도 `risk_reduction`으로 분리한다.
- 복합 문구는 분해 저장한다.
- canonical은 `ko/en` 쌍으로 저장하고, 언어 중립 식별자는 `claim_key`로 관리한다.

## Predicate Types

- `supports`
  - 예: `피부 보습에 도움`
  - canonical ko: `피부 보습에 도움을 줄 수 있음`
- `required_for`
  - 예: `정상적인 면역기능에 필요`
- `risk_reduction`
  - 예: `골다공증발생 위험 감소에 도움을 줌`

## Storage Model

### claims

- `claim_key`
- `canonical_claim_ko`
- `canonical_claim_en`
- `claim_subject_ko`
- `claim_subject_en`
- `predicate_type`
- `claim_category`
- `claim_scope`
- `source_language`

### ingredient_claims

- `raw_claim_text`
- `raw_claim_language`
- `recognition_no`
- `evidence_grade_text`
- `claim_scope_note`
- `source_dataset`

## Normalization Rules

1. 원문 앞뒤의 `-`, 번호, `(국문)`, `(영문)` 제거
2. 영문 병기와 국문 병기는 따로 분리하되 같은 `claim_key`에 연결
3. `도움`, `도움을 줌`, `도움을 줄 수 있음`은 `supports`로 통합
4. `필요`는 `required_for`로 유지
5. `위험 감소에 도움을 줌`은 `risk_reduction`으로 유지
6. `생리활성기능 2등급` 같은 표기는 `evidence_grade_text`로 분리
7. `유익균 증식, 유해균 억제, 배변활동 원활`은 3개 claim으로 분리

## Example

### Raw

`- 유익한 유산균 증식, 유해균 억제, 배변활동 원활`

### Canonical Claims

- `beneficial_bacteria_growth_support`
  - ko: `유익균 증식에 도움을 줄 수 있음`
  - en: `May help support beneficial bacteria growth`
- `harmful_bacteria_suppression_support`
  - ko: `유해균 억제에 도움을 줄 수 있음`
  - en: `May help support suppression of harmful bacteria`
- `bowel_movement_support`
  - ko: `배변활동 원활에 도움을 줄 수 있음`
  - en: `May help support regular bowel movements`
