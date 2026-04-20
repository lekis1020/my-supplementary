/**
 * 이미지 크롭 유틸리티 — 마케팅 상세 이미지에서 영양정보 영역 추출.
 *
 * 종근당건강 등 한국 건기식 상세 이미지 특성:
 *   - 세로 장문 (1000×10000~20000px)
 *   - 상단: 제품 소개·마케팅 카피
 *   - 하단: 영양·기능정보표, 원료 성분, 주의사항
 *
 * 전략: 이미지 높이가 일정 이상이면 하단 N% 크롭.
 * 향후 OCR 기반 "영양" 키워드 감지로 정밀 크롭 확장 가능.
 */

import sharp from "sharp";
import { createHash } from "node:crypto";
import { GoogleGenerativeAI } from "@google/generative-ai";

/**
 * Gemini Flash Vision으로 영양정보 표 영역을 감지한 뒤 정밀 크롭.
 * API 키 없거나 감지 실패 시 하단 25% 폴백.
 *
 * @param {Buffer} buffer   원본 이미지 버퍼
 * @param {object} opts
 * @param {number} [opts.minHeight=5000]  크롭 적용 최소 높이 (px)
 * @param {number} [opts.paddingPct=2]    감지 영역 위아래 여백 (원본 높이 대비 %)
 * @returns {Promise<{buffer: Buffer, hash: string, width: number, height: number, cropped: boolean, method: string}>}
 */
export async function cropNutritionLabel(buffer, opts = {}) {
  const { minHeight = 5000, paddingPct = 2 } = opts;

  const meta = await sharp(buffer).metadata();
  const { width, height } = meta;

  if (!width || !height || height < minHeight) {
    const hash = createHash("sha256").update(buffer).digest("hex");
    return { buffer, hash, width: width ?? 0, height: height ?? 0, cropped: false, method: "skip" };
  }

  // Vision 감지 시도 → 실패 시 1회 재시도 → 그래도 실패 시 폴백
  let bounds = await detectNutritionBounds(buffer, width, height).catch(() => null);
  if (!bounds || bounds.top >= bounds.bottom) {
    bounds = await detectNutritionBounds(buffer, width, height).catch(() => null);
  }

  let top, cropH;
  let method;

  if (bounds && bounds.top < bounds.bottom) {
    const padding = Math.min(Math.round(height * paddingPct / 100), 100);
    top = Math.max(0, bounds.top - padding);
    cropH = Math.min(height - top, bounds.bottom - top + padding * 2);
    method = "vision";
  } else {
    // 폴백: 하단 20%
    const bottomRatio = 0.20;
    cropH = Math.min(Math.round(height * bottomRatio), 5000);
    top = height - cropH;
    method = "fallback";
  }

  const cropped = await sharp(buffer)
    .extract({ left: 0, top, width, height: cropH })
    .jpeg({ quality: 85 })
    .toBuffer();

  // 크롭 결과 검증 — 실제 제품정보 표가 있는지 확인
  const valid = await validateNutritionCrop(cropped).catch(() => true); // 검증 실패 시 통과
  if (!valid) {
    const hash = createHash("sha256").update(buffer).digest("hex");
    return { buffer, hash, width: width ?? 0, height: height ?? 0, cropped: false, method: "rejected" };
  }

  const hash = createHash("sha256").update(cropped).digest("hex");

  return {
    buffer: cropped,
    hash,
    width,
    height: cropH,
    cropped: true,
    method,
    originalHeight: height,
    cropTop: top,
  };
}

/**
 * 크롭된 이미지에 여러 맛/제품 표가 포함되어 있으면 개별 이미지로 분할.
 * 단일 표면 원본 배열 그대로 반환.
 *
 * @param {Buffer} buffer  cropNutritionLabel로 크롭된 이미지
 * @param {number} width
 * @param {number} height
 * @returns {Promise<Array<{buffer: Buffer, hash: string, width: number, height: number, label: string|null}>>}
 */
export async function splitNutritionTables(buffer, width, height) {
  const apiKey = process.env.GOOGLE_GENERATIVE_AI_API_KEY;
  if (!apiKey) {
    return [{ buffer, hash: createHash("sha256").update(buffer).digest("hex"), width, height, label: null }];
  }

  const resized = await sharp(buffer)
    .resize({ height: 1024, fit: "inside" })
    .jpeg({ quality: 75 })
    .toBuffer();

  const genAI = new GoogleGenerativeAI(apiKey);
  const model = genAI.getGenerativeModel({
    model: process.env.SCAN_VISION_PRIMARY_MODEL || "gemini-2.5-flash",
    generationConfig: { temperature: 0, responseMimeType: "application/json" },
  });

  const result = await model.generateContent([
    {
      inlineData: { mimeType: "image/jpeg", data: resized.toString("base64") },
    },
    {
      text: `이 이미지에 서로 다른 맛(flavor)이나 제품 변형(variant)의 제품정보가 반복되어 있는지 확인하세요.

중요 규칙:
- 같은 제품의 "제품 상세정보" 표와 "영양정보" 표는 하나로 셉니다 (분할하지 마세요).
- "복숭아맛", "망고맛"처럼 맛별로 제품명·원재료·영양정보가 각각 반복될 때만 여러 개로 셉니다.
- 맛/변형 구분이 없으면 count=1 입니다.

각 변형의 전체 영역(제품정보+영양정보 통합) 시작·끝 위치를 이미지 높이 대비 %(0~100)로 답하세요.
label은 맛/변형 이름입니다 (예: "복숭아맛").

JSON schema: {"count": number, "tables": [{"start_pct": number, "end_pct": number, "label": string|null}]}`,
    },
  ]);

  const text = result.response.text().trim();
  const json = JSON.parse(text.replace(/```json\n?|\n?```/g, "").trim());

  if (!json.tables || json.count <= 1) {
    return [{ buffer, hash: createHash("sha256").update(buffer).digest("hex"), width, height, label: null }];
  }

  // 각 표 영역을 개별 이미지로 분할 (표 간 중간점을 경계로 사용)
  const sorted = json.tables
    .map((t) => {
      let sp = t.start_pct, ep = t.end_pct;
      if (sp <= 1 && ep <= 1) { sp *= 100; ep *= 100; }
      return {
        startPct: Math.max(0, Math.min(100, sp)),
        endPct: Math.max(0, Math.min(100, ep)),
        label: t.label || null,
      };
    })
    .sort((a, b) => a.startPct - b.startPct);

  const splits = [];
  for (let i = 0; i < sorted.length; i++) {
    // 시작: 이전 표 끝과 현재 표 시작의 중간점 (첫 번째면 0)
    const prevEnd = i > 0 ? sorted[i - 1].endPct : 0;
    const splitStart = i > 0 ? (prevEnd + sorted[i].startPct) / 2 : 0;
    // 끝: 현재 표 끝과 다음 표 시작의 중간점 (마지막이면 100)
    const nextStart = i < sorted.length - 1 ? sorted[i + 1].startPct : 100;
    const splitEnd = i < sorted.length - 1 ? (sorted[i].endPct + nextStart) / 2 : 100;

    const top = Math.round((splitStart / 100) * height);
    const cropH = Math.max(1, Math.round(((splitEnd - splitStart) / 100) * height));

    const splitBuf = await sharp(buffer)
      .extract({ left: 0, top, width, height: Math.min(cropH, height - top) })
      .jpeg({ quality: 85 })
      .toBuffer();

    splits.push({
      buffer: splitBuf,
      hash: createHash("sha256").update(splitBuf).digest("hex"),
      width,
      height: cropH,
      label: sorted[i].label,
    });
  }

  return splits;
}

/**
 * 크롭된 이미지에 실제 제품정보/영양정보 표가 포함되어 있는지 검증.
 * 마케팅 콘텐츠("건강정보", 홍보 문구)만 있는 크롭을 걸러냄.
 *
 * @param {Buffer} buffer  크롭된 이미지
 * @returns {Promise<boolean>} true=유효한 제품정보 포함, false=마케팅만
 */
async function validateNutritionCrop(buffer) {
  const apiKey = process.env.GOOGLE_GENERATIVE_AI_API_KEY;
  if (!apiKey) return true;

  const resized = await sharp(buffer)
    .resize({ height: 768, fit: "inside" })
    .jpeg({ quality: 75 })
    .toBuffer();

  const genAI = new GoogleGenerativeAI(apiKey);
  const model = genAI.getGenerativeModel({
    model: process.env.SCAN_VISION_PRIMARY_MODEL || "gemini-2.5-flash",
    generationConfig: { temperature: 0, responseMimeType: "application/json" },
  });

  const result = await model.generateContent([
    { inlineData: { mimeType: "image/jpeg", data: resized.toString("base64") } },
    {
      text: `이 이미지에 제품정보가 포함되어 있습니까?
다음 중 하나라도 보이면 true입니다:
- "제품명", "원재료명 및 함량", "섭취량" 등의 행 제목이 있는 표
- "SPEC" 제목 아래 제품 상세정보
- "영양정보", "영양·기능정보" 성분 수치 표

마케팅만 있고 위 내용이 전혀 없으면 false입니다.

JSON: {"has_table": boolean}`,
    },
  ]);

  const text = result.response.text().trim();
  const json = JSON.parse(text.replace(/```json\n?|\n?```/g, "").trim());
  return json.has_table === true;
}

/**
 * Gemini Flash Vision으로 '1일 섭취량' 표 위치를 감지.
 *
 * 긴 이미지(10000px+)를 통째로 리사이즈하면 텍스트가 뭉개져서 감지 실패.
 * → 하단 50%만 잘라서 보내면 해상도 2배 향상, 감지 정확도 대폭 개선.
 *
 * @returns {Promise<{top: number, bottom: number}>} 원본 이미지 기준 px 좌표
 */
async function detectNutritionBounds(buffer, imgWidth, imgHeight) {
  const apiKey = process.env.GOOGLE_GENERATIVE_AI_API_KEY;
  if (!apiKey) throw new Error("GOOGLE_GENERATIVE_AI_API_KEY 미설정");

  // 하단 30%만 추출 — 마케팅 텍스트 노이즈를 줄이고 표 해상도를 높임
  const cropRatio = 0.3;
  const sectionTop = Math.round(imgHeight * (1 - cropRatio));
  const sectionHeight = imgHeight - sectionTop;
  const section = await sharp(buffer)
    .extract({ left: 0, top: sectionTop, width: imgWidth, height: sectionHeight })
    .resize({ height: 1024, fit: "inside" })
    .jpeg({ quality: 75 })
    .toBuffer();

  const genAI = new GoogleGenerativeAI(apiKey);
  const model = genAI.getGenerativeModel({
    model: process.env.SCAN_VISION_PRIMARY_MODEL || "gemini-2.5-flash",
    generationConfig: { temperature: 0, responseMimeType: "application/json" },
  });

  const result = await model.generateContent([
    {
      inlineData: {
        mimeType: "image/jpeg",
        data: section.toString("base64"),
      },
    },
    {
      text: `이 이미지는 건강기능식품 상세페이지 하단부입니다.

## STEP 1: 표 시작 찾기
"제품 정보", "제품 상세정보", "SPEC", "영양·기능정보" 같은 제목 아래에 있는 행/열 표(table)를 찾으세요.
표의 첫 행은 보통 "제품명", "식품유형" 등입니다.

## STEP 2: 표 끝 찾기
아래 기준점 중 먼저 나오는 것이 표의 끝입니다:
1. "건강정보" 제목 또는 주황/빨간 배너
2. 인포그래픽, 그래프, 아이콘 그리드, 건강 통계 시작
3. "소비자상담" 또는 전화번호 (080-XXX-XXXX)
4. 표의 격자(grid line) 패턴이 끝나고 자유 형태 레이아웃으로 전환되는 지점

## 제외 대상 (end_pct에 포함하지 마세요):
- "건강정보" 섹션 (건강 통계, 그래프, "왜 먹어야 할까요?")
- 제품 사진, 제품 라인업 이미지
- "이렇게 섭취하세요", "이런 분들께 추천" 마케팅
- Q&A 섹션, 섭취량 비교 그래픽
- 면책 문구, 법적 고지

## 중요:
- 확신이 없으면 좁게 잡으세요. 마케팅 포함보다 표가 약간 잘리는 게 낫습니다.

JSON schema: {"found": boolean, "start_pct": number, "end_pct": number}`,
    },
  ]);

  const text = result.response.text().trim();
  const json = JSON.parse(text.replace(/```json\n?|\n?```/g, "").trim());

  if (!json.found) throw new Error("nutrition table not found");

  // Gemini가 0~1 소수로 응답하는 경우 보정 (0~100 정수 기대)
  let startPct = json.start_pct;
  let endPct = json.end_pct;
  if (startPct <= 1 && endPct <= 1) {
    startPct *= 100;
    endPct *= 100;
  }
  startPct = Math.max(0, Math.min(100, startPct));
  endPct = Math.max(startPct, Math.min(100, endPct));

  // 하단 30% 내 %를 원본 전체 좌표로 변환
  return {
    top: sectionTop + Math.round((startPct / 100) * sectionHeight),
    bottom: sectionTop + Math.round((endPct / 100) * sectionHeight),
  };
}
