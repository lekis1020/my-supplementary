/**
 * 제품명 variation 정규화 및 추출.
 *
 * Vision API가 반환할 텍스트 + Naver Shopping title 사이의 차이를
 * 흡수하기 위해 다양한 표기 variations를 추출해 product_aliases에 저장.
 */

/** 기본 정규화: 공백 통일, 괄호 제거, 대소문자 보존. */
export function normalize(text) {
  if (!text) return "";
  return text
    .replace(/\s+/g, " ")
    .replace(/[\u200B-\u200D\uFEFF]/g, "") // zero-width
    .trim();
}

/**
 * Naver title(HTML 제거된 평문)에서 product_aliases 후보 추출.
 * 예: "종근당 칼슘 마그네슘 비타민D 아연 120정 (2개월분)"
 *   → ["종근당 칼슘 마그네슘 비타민D 아연", "칼슘 마그네슘 비타민D 아연", ...]
 */
export function extractAliasCandidates(title, brand) {
  const norm = normalize(title);
  const candidates = new Set();

  candidates.add(norm);

  // 수량·회분 suffix 제거: "120정", "(2개월분)", "30포", "60일분" 등
  const stripped = norm
    .replace(/\(\s*\d+\s*(?:개월분|일분|주분|정|포|캡슐|스틱)\s*\)/g, "")
    .replace(/\s\d+\s*(?:정|포|캡슐|스틱|개월분|일분|주분)$/g, "")
    .replace(/\s+/g, " ")
    .trim();
  if (stripped && stripped !== norm) candidates.add(stripped);

  // 브랜드명으로 시작하면 브랜드 제거 버전도 추가
  if (brand) {
    const brandNorm = normalize(brand);
    if (brandNorm && stripped.startsWith(brandNorm)) {
      const noBrand = stripped.slice(brandNorm.length).trim();
      if (noBrand) candidates.add(noBrand);
    }
  }

  // 특수문자·기호 제거된 단순 버전 (매칭용)
  const simple = stripped.replace(/[\[\]()〈〉<>【】\-·•,]/g, " ").replace(/\s+/g, " ").trim();
  if (simple && simple !== stripped) candidates.add(simple);

  return Array.from(candidates).filter((s) => s.length >= 2 && s.length <= 255);
}

/** 브랜드 추정: Naver title의 첫 단어가 brand 필드와 일치하면 그대로, 아니면 null. */
export function deriveBrand({ title, brand, maker }) {
  if (brand) return normalize(brand);
  if (maker) return normalize(maker);
  // 빈 경우 title 첫 토큰을 브랜드 후보로
  const first = normalize(title).split(/\s+/)[0];
  return first && first.length <= 30 ? first : null;
}
