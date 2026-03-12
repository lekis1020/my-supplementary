import { type ClassValue, clsx } from "clsx";

export function cn(...inputs: ClassValue[]) {
  return clsx(inputs);
}

/** 근거 등급 배지 색상 */
export function getEvidenceGradeColor(grade: string | null): string {
  switch (grade) {
    case "A":
      return "bg-green-100 text-green-800";
    case "B":
      return "bg-blue-100 text-blue-800";
    case "C":
      return "bg-yellow-100 text-yellow-800";
    case "D":
      return "bg-orange-100 text-orange-800";
    case "F":
      return "bg-red-100 text-red-800";
    default:
      return "bg-gray-100 text-gray-800";
  }
}

/** 안전성 심각도 배지 색상 */
export function getSeverityColor(level: string | null): string {
  switch (level) {
    case "critical":
      return "bg-red-100 text-red-800";
    case "serious":
      return "bg-orange-100 text-orange-800";
    case "moderate":
      return "bg-yellow-100 text-yellow-800";
    case "mild":
      return "bg-green-100 text-green-800";
    default:
      return "bg-gray-100 text-gray-800";
  }
}

/** claim_scope 한글 변환 */
export function getClaimScopeLabel(scope: string): string {
  const map: Record<string, string> = {
    approved_kr: "식약처 인정",
    approved_us: "FDA 인정",
    studied: "학술 연구",
    traditional: "전통적 사용",
    prohibited: "금지 표현",
  };
  return map[scope] || scope;
}

/** ingredient_type 한글 변환 */
export function getIngredientTypeLabel(type: string): string {
  const map: Record<string, string> = {
    vitamin: "비타민",
    mineral: "미네랄",
    amino_acid: "아미노산",
    fatty_acid: "지방산",
    probiotic: "프로바이오틱스",
    herbal: "허브/식물성",
    enzyme: "효소",
    other: "기타",
  };
  return map[type] || type;
}
