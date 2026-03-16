# Korean API Endpoint Map

> Version: 1.0.0
> 작성일: 2026-03-13

## 목적

공공데이터포털과 식품안전나라에서 승인받은 건강기능식품 API가 실제로 어떤 엔드포인트로 연결되는지 정리한다. 포털 신청 단위와 실제 호출 단위가 다르기 때문에, 구현 시에는 이 문서를 기준으로 키와 엔드포인트를 매핑한다.

## 엔드포인트 매핑

| 신청 포털 | 포털 데이터셋 / 서비스 | API 유형 | 실제 호출 엔드포인트 | 인증키 |
|---|---|---|---|---|
| 식품안전나라 | `I0030` 건강기능식품 품목제조 신고사항 현황 | REST | `http://openapi.foodsafetykorea.go.kr/api/{FOODSAFETY_KOREA_API_KEY}/I0030/json/{start}/{end}` | `FOODSAFETY_KOREA_API_KEY` |
| 식품안전나라 | `I0760` 건강기능식품 영양DB | REST | `http://openapi.foodsafetykorea.go.kr/api/{FOODSAFETY_KOREA_API_KEY}/I0760/json/{start}/{end}` | `FOODSAFETY_KOREA_API_KEY` |
| 식품안전나라 | `I-0040` 건강기능식품 기능성 원료인정현황 | REST | `http://openapi.foodsafetykorea.go.kr/api/{FOODSAFETY_KOREA_API_KEY}/I-0040/json/{start}/{end}` | `FOODSAFETY_KOREA_API_KEY` |
| 공공데이터포털 | `15056760` 식품의약품안전처_건강기능식품정보 | REST | `https://apis.data.go.kr/1471000/HtfsInfoService03/getHtfsList01` | `DATA_GO_KR_SERVICE_KEY_DECODED` |
| 공공데이터포털 | `15058359` 식품의약품안전처_건강기능식품 기능성 원료인정 현황 | LINK | 식품안전나라 `I-0040` 상세 페이지로 연결 | `FOODSAFETY_KOREA_API_KEY` |

## 호출 검증 결과

| 검증일 | 엔드포인트 | 결과 | 샘플 응답 |
|---|---|---|---|
| 2026-03-13 | 식품안전나라 `I0030` | 성공 | 제품명 `건미의고려인삼`, 업체명 `고려인삼과학주식회사` |
| 2026-03-13 | 식품안전나라 `I0760` | 성공 | 품목군 `프랑스해안송껍질추출물` |
| 2026-03-13 | 식품안전나라 `I-0040` | 성공 | 원료명 `식물스타놀에스테르`, 인정번호 `2006-11` |
| 2026-03-13 | 공공데이터포털 `getHtfsList01` | 성공 | 제품명 `11종 혼합유산균`, 업체명 `일동바이오사이언스(주)` |

## 구현 메모

- 공공데이터포털의 `15058359`는 데이터셋 승인과 계정 추적은 `data.go.kr`에서 하지만, 공개 페이지 기준 `API 유형`이 `LINK`다.
- 따라서 `기능성 원료인정 현황`의 실제 데이터 수집 구현은 식품안전나라 `I-0040` 기준으로 잡는 것이 맞다.
- 식품안전나라 Open API는 동일 키로 동시 요청 시 `현재 접속 중인 인증키입니다` 경고를 반환할 수 있다.
- 초기 수집기에서는 식품안전나라 요청을 순차 처리하거나 짧은 지연을 두는 편이 안전하다.

## 스모크 테스트

로컬에서 실제 호출을 다시 확인하려면 아래 스크립트를 사용한다.

```bash
node scripts/test_korean_gov_apis.mjs
```

필수 환경변수:

```bash
FOODSAFETY_KOREA_API_KEY=
DATA_GO_KR_SERVICE_KEY_DECODED=
```
