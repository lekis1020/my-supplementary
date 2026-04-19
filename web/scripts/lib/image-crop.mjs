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
    const padding = Math.round(height * paddingPct / 100);
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
    .map((t) => ({
      startPct: Math.max(0, Math.min(100, t.start_pct)),
      endPct: Math.max(0, Math.min(100, t.end_pct)),
      label: t.label || null,
    }))
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

"제품 정보", "제품 상세정보", "영양·기능정보" 같은 제목 아래에 있는 행/열 표(table)를 찾으세요.
표의 첫 행은 보통 "제품명", "식품유형" 등이고, "원재료명 및 함량", "섭취량 및 섭취방법" 행이 포함됩니다.

start_pct는 표 제목("제품 정보" 등) 또는 표의 첫 행이 시작되는 위치입니다.

제외 대상 (표가 아닙니다):
- 제품 사진, 제품 라인업 이미지, 마케팅 문구
- "이렇게 섭취하세요", "이런 분들께 추천", 생애주기 등 홍보 섹션
- 표 아래 "소비자상담", 면책문구

표가 시작·끝나는 위치를 이 이미지 높이 대비 백분율(0~100)로 답하세요.

JSON schema: {"found": boolean, "start_pct": number, "end_pct": number}`,
    },
  ]);

  const text = result.response.text().trim();
  const json = JSON.parse(text.replace(/```json\n?|\n?```/g, "").trim());

  if (!json.found) throw new Error("nutrition table not found");

  const startPct = Math.max(0, Math.min(100, json.start_pct));
  const endPct = Math.max(startPct, Math.min(100, json.end_pct));

  // 하단 30% 내 %를 원본 전체 좌표로 변환
  return {
    top: sectionTop + Math.round((startPct / 100) * sectionHeight),
    bottom: sectionTop + Math.round((endPct / 100) * sectionHeight),
  };
}
