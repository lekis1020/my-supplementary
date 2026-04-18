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
 * @param {number} [opts.padding=100]     감지 영역 위아래 여백 (px)
 * @returns {Promise<{buffer: Buffer, hash: string, width: number, height: number, cropped: boolean, method: string}>}
 */
export async function cropNutritionLabel(buffer, opts = {}) {
  const { minHeight = 5000, padding = 100 } = opts;

  const meta = await sharp(buffer).metadata();
  const { width, height } = meta;

  if (!width || !height || height < minHeight) {
    const hash = createHash("sha256").update(buffer).digest("hex");
    return { buffer, hash, width: width ?? 0, height: height ?? 0, cropped: false, method: "skip" };
  }

  // Vision 감지 시도 → 실패 시 폴백
  const bounds = await detectNutritionBounds(buffer, width, height).catch(() => null);

  let top, cropH;
  let method;

  if (bounds && bounds.top < bounds.bottom) {
    top = Math.max(0, bounds.top - padding);
    cropH = Math.min(height - top, bounds.bottom - top + padding * 2);
    method = "vision";
  } else {
    // 폴백: 하단 25%
    const bottomRatio = 0.25;
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
 * Gemini Flash Vision으로 영양정보 표 영역 좌표 감지.
 * @returns {Promise<{top: number, bottom: number}>} 원본 이미지 기준 px 좌표
 */
async function detectNutritionBounds(buffer, imgWidth, imgHeight) {
  const apiKey = process.env.GOOGLE_GENERATIVE_AI_API_KEY;
  if (!apiKey) throw new Error("GOOGLE_GENERATIVE_AI_API_KEY 미설정");

  // 감지용 리사이즈 (비용 절감, 768px 높이로)
  const resized = await sharp(buffer)
    .resize({ height: 768, fit: "inside" })
    .jpeg({ quality: 70 })
    .toBuffer();
  const resizedMeta = await sharp(resized).metadata();
  const scale = imgHeight / (resizedMeta.height ?? 768);

  const genAI = new GoogleGenerativeAI(apiKey);
  const model = genAI.getGenerativeModel({
    model: process.env.SCAN_VISION_PRIMARY_MODEL || "gemini-2.0-flash",
  });

  const result = await model.generateContent([
    {
      inlineData: {
        mimeType: "image/jpeg",
        data: resized.toString("base64"),
      },
    },
    {
      text: `이 이미지는 건강기능식품 상세 페이지 이미지입니다.
"영양·기능정보" 표(성분명, 함량, % 영양성분기준치가 나오는 표)가 있는 영역의 상단 y좌표와 하단 y좌표를 픽셀 단위로 반환하세요.
기능성 원재료 설명 텍스트도 포함하세요.
표가 없으면 {"found": false}를 반환하세요.

반드시 JSON만 반환: {"found": true, "top": 숫자, "bottom": 숫자}`,
    },
  ]);

  const text = result.response.text().trim();
  const json = JSON.parse(text.replace(/```json\n?|\n?```/g, "").trim());

  if (!json.found) throw new Error("nutrition table not found");

  return {
    top: Math.round(json.top * scale),
    bottom: Math.round(json.bottom * scale),
  };
}
