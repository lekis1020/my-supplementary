---
name: label-crop
description: 건강기능식품 상세 이미지에서 영양정보/제품정보 표를 정밀 크롭하는 에이전트 스킬
triggers:
  - "label crop"
  - "라벨 크롭"
  - "영양정보 크롭"
  - "라벨 이미지"
argument-hint: "<image-path-or-url> [--product-id=N]"
---

# Label Crop Skill

건강기능식품 제조사 상세 이미지(세로 10000~30000px)에서 영양정보/제품정보 표 영역만 정밀 크롭하는 에이전트 워크플로우.

## Purpose

제조사 상세 이미지는 마케팅 콘텐츠 + 제품정보 표 + 면책문구가 혼재. 이 스킬은 **제품정보 표만** 정확히 추출한다.

## When to Activate

- 제조사 사이트에서 스크레이핑한 상세 이미지의 라벨 크롭이 필요할 때
- 기존 자동 크롭 결과의 품질이 불충분할 때
- 새 제조사 레이아웃에 대응이 필요할 때

## Domain Knowledge: 한국 건기식 상세 이미지 구조

```
[상단 0~50%]  마케팅: 제품 사진, 효능 설명, "이런 분들께 추천", 섭취방법 일러스트
[중단 50~75%] 마케팅: 제품 라인업, "건강정보", 그래프, 통계
[하단 75~95%] ★ 제품정보 표: 제품명, 원재료명, 섭취량, 영양정보 ★
[최하단 95~100%] 소비자상담, 면책문구
```

### 제품정보 표 식별 기준

**포함 대상 (반드시 크롭에 포함):**
- "제품 정보", "제품 상세정보", "SPEC" 제목
- 행/열 구조의 테이블: 제품명, 식품유형, 내용량, 원재료명 및 함량
- "섭취량 및 섭취방법", "1일 섭취량" 행
- "영양정보", "영양·기능정보" 표 (성분명, 함량, %기준치)
- "보관방법", "섭취 시 주의사항"

**제외 대상 (크롭에서 제거):**
- 제품 사진, 제품 라인업 썸네일 이미지
- "이렇게 섭취하세요", "이런 분들께 추천 드립니다" 마케팅
- "건강정보", "왜 먹어야 할까요?", 질환 통계 그래프
- "소비자상담", "080-XXX-XXXX", 법적 면책 문구
- 유산균 효능 설명, 장 건강 일러스트 등 홍보 콘텐츠

### 맛/변형별 분할

일부 제품(예: 락토조이 구미젤리)은 복숭아맛·망고맛 등 여러 맛의 제품정보가 한 이미지에 반복.
이 경우 **맛별로 개별 이미지로 분할**해야 한다.

- 같은 제품의 "제품정보 표" + "영양정보 표"는 하나로 (분할하지 않음)
- 맛별로 제품명·원재료·영양정보가 각각 반복되면 여러 개로 분할

## Workflow

### 1. 이미지 분석

이미지를 시각적으로 확인하고 구조를 파악한다:
- 전체 높이/너비 확인
- 마케팅 영역 vs 표 영역 경계 식별
- 표 유형 판별 (단일 제품 vs 다중 맛/변형)

```bash
# sharp로 메타데이터 확인
node -e "
import sharp from 'sharp';
const meta = await sharp('IMAGE_PATH').metadata();
console.log(meta.width + 'x' + meta.height);
"
```

### 2. 크롭 영역 결정

하단 30%를 기준으로 표 위치를 판단하되, 다음 규칙을 따른다:

- **표 시작점**: "제품 정보", "SPEC", "영양·기능정보" 제목이 나오는 위치
- **표 끝점**: 마지막 표 행 (보관방법 또는 주의사항) 끝. "소비자상담" 전
- **패딩**: 표 위아래로 원본 높이의 2% 여백

### 3. 크롭 실행

```javascript
import { cropNutritionLabel, splitNutritionTables } from './scripts/lib/image-crop.mjs';

const crop = await cropNutritionLabel(buffer);
// crop.method: "vision" | "fallback" | "skip" | "rejected"
```

### 4. 결과 검증 (핵심 단계)

크롭된 이미지를 **직접 시각적으로 확인**한다:

1. 크롭 이미지를 `/private/tmp/`에 저장
2. Read 도구로 이미지를 열어 직접 확인
3. 다음 체크리스트로 판단:

| 체크 | 기준 |
|------|------|
| ✅ 표 포함 | "제품명", "원재료명" 등 행 제목이 보이는가? |
| ✅ 표 완전성 | 섭취량, 영양정보까지 포함되었는가? |
| ❌ 마케팅 없음 | "건강정보", 그래프, 홍보 문구가 없는가? |
| ❌ 면책 없음 | "소비자상담", 법적 고지가 제외되었는가? |
| ✅ 깔끔한 경계 | 표 위아래가 잘리지 않았는가? |

### 5. 재크롭 (필요 시)

검증 실패 시 수동으로 sharp extract를 사용해 정밀 크롭:

```javascript
import sharp from 'sharp';

// 예: 원본 이미지에서 80~92% 구간만 추출
const height = 20000;
const top = Math.round(height * 0.80);
const cropH = Math.round(height * 0.12);

await sharp(buffer)
  .extract({ left: 0, top, width: 1000, height: cropH })
  .jpeg({ quality: 85 })
  .toFile('/private/tmp/manual_crop.jpg');
```

### 6. 분할 (다중 맛/변형)

```javascript
const splits = await splitNutritionTables(crop.buffer, crop.width, crop.height);
// splits: [{buffer, hash, width, height, label: "복숭아맛"}, ...]
```

### 7. 저장

R2 업로드 + DB 적재:

```javascript
import { uploadToR2, buildKey, getPublicUrl } from './scripts/lib/r2-mirror.mjs';

const key = buildKey({ productId, source: 'manufacturer_label', hash, ext: 'jpg' });
await uploadToR2({ key, buffer, contentType: 'image/jpeg' });

await supabase.from('product_images').upsert({
  product_id: productId,
  source: 'manufacturer_label',
  r2_key: key,
  r2_public_url: getPublicUrl(key),
  image_hash: hash,
  mime_type: 'image/jpeg',
  size_bytes: buffer.length,
  width, height,
  is_primary: false,
}, { onConflict: 'product_id,image_hash', ignoreDuplicates: true });
```

## Quality Standards

- **정확도**: 제품정보 표가 100% 포함되어야 함
- **깔끔함**: 마케팅 콘텐츠 0% 포함 목표 (약간의 여백은 허용)
- **완전성**: 제품명 ~ 주의사항까지 누락 없이 포함
- **분할**: 다중 맛 제품은 반드시 맛별 분할

## Tools

- `web/scripts/lib/image-crop.mjs` — cropNutritionLabel(), splitNutritionTables()
- `web/scripts/lib/r2-mirror.mjs` — R2 업로드/URL 생성
- `sharp` — 이미지 처리 (extract, resize, metadata)
- `@google/generative-ai` — Gemini Vision (감지/검증)

## Notes

- Gemini `temperature: 0` + `responseMimeType: "application/json"` 필수
- 모델: `gemini-2.5-flash` (gemini-2.0-flash deprecated)
- 긴 이미지(10000px+)는 통째로 리사이즈하면 텍스트 뭉개짐 → 하단 30%만 잘라서 전송
- 어두운 배경(네이비 등) 표는 Gemini 감지 실패율 높음 → 재시도 또는 수동 크롭
- 크롭 전 원본 이미지는 항상 보존 (source: "manufacturer")
