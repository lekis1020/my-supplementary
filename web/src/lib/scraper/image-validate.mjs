/**
 * Gemini Vision 제품 이미지 검증 공용 모듈.
 *
 * marketing / set_gift / unrelated 이미지를 저장 전에 차단한다.
 * GOOGLE_GENERATIVE_AI_API_KEY 미설정 시 검증 없이 통과(ok=true).
 */

import { GoogleGenerativeAI } from "@google/generative-ai";

let geminiModel = null;

function getGeminiModel() {
  if (geminiModel) return geminiModel;
  if (!process.env.GOOGLE_GENERATIVE_AI_API_KEY) return null;
  const genAI = new GoogleGenerativeAI(process.env.GOOGLE_GENERATIVE_AI_API_KEY);
  geminiModel = genAI.getGenerativeModel({ model: "gemini-2.5-flash" });
  return geminiModel;
}

const VALIDATION_PROMPT = `이 건강기능식품 이미지를 분류하세요. JSON만 응답.
- "product_front": 제품 패키지만 보이는 깔끔한 사진 (박스, 병, 캡슐 등 제품만)
- "product_angle": 제품이 보이지만 각도가 있거나 여러 구성품 함께
- "marketing": 아래 중 하나라도 해당하면 marketing으로 분류:
  · 사람(모델, 연예인, 의사 일러스트)이 포함된 이미지
  · 할인가/판매누적/1+1 등 프로모션 텍스트
  · 제품 외 과일/식재료가 배경 대부분을 차지
  · 제품보다 마케팅 문구가 더 큰 이미지
- "set_gift": 선물세트/묶음 (선물 박스, 쇼핑백 포함)
- "unrelated": 건강기능식품과 무관
응답: {"type": "product_front"}`;

/**
 * @param {Buffer} buffer 이미지 바이너리
 * @param {string} mimeType
 * @param {{ skip?: boolean }} [opts]
 * @returns {Promise<{ ok: boolean, type: string }>}
 */
export async function validateProductImage(buffer, mimeType, opts = {}) {
  const model = getGeminiModel();
  if (!model || opts.skip) return { ok: true, type: "skipped" };
  try {
    const result = await model.generateContent({
      contents: [
        {
          role: "user",
          parts: [
            { inlineData: { mimeType, data: buffer.toString("base64") } },
            { text: VALIDATION_PROMPT },
          ],
        },
      ],
      generationConfig: { temperature: 0, responseMimeType: "application/json" },
    });
    const parsed = JSON.parse(result.response.text());
    const ok = !["marketing", "set_gift", "unrelated"].includes(parsed.type);
    return { ok, type: parsed.type };
  } catch {
    return { ok: true, type: "validation_error" }; // 검증 실패 시 허용
  }
}
