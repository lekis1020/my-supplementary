import { type ClassValue, clsx } from "clsx";

export const INGREDIENT_CATEGORY_ORDER = [
  "vitamins",
  "minerals",
  "fatty-acids",
  "probiotics",
  "herbals",
  "others",
] as const;

export type IngredientCategory = (typeof INGREDIENT_CATEGORY_ORDER)[number];

const INGREDIENT_TYPE_LABELS: Record<string, string> = {
  vitamin: "비타민",
  mineral: "미네랄",
  amino_acid: "아미노산",
  fatty_acid: "지방산",
  probiotic: "프로바이오틱스",
  herbal: "허브/식물성",
  enzyme: "효소",
  other: "기타",
};

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
  return getIngredientTypeLabels(type).join(" · ");
}

function normalizeIngredientTypeToken(token: string): string | null {
  switch (token.trim().toLowerCase()) {
    case "vitamin":
    case "비타민":
      return "vitamin";
    case "mineral":
    case "미네랄":
      return "mineral";
    case "amino_acid":
    case "amino-acid":
    case "amino acid":
    case "아미노산":
      return "amino_acid";
    case "fatty_acid":
    case "fatty-acid":
    case "fatty acid":
    case "지방산":
      return "fatty_acid";
    case "probiotic":
    case "probiotics":
    case "프로바이오틱스":
    case "유산균":
      return "probiotic";
    case "herbal":
    case "허브":
    case "식물성":
    case "허브/식물성":
      return "herbal";
    case "enzyme":
    case "효소":
    case "coenzyme":
    case "코엔자임":
      return "enzyme";
    case "other":
    case "기타":
      return "other";
    default:
      return null;
  }
}

export function getIngredientTypeCodes(type: string): string[] {
  const normalized = type
    .split(/[\/,|·]+/)
    .map((token) => normalizeIngredientTypeToken(token))
    .filter((token): token is string => Boolean(token));

  if (normalized.length > 0) {
    return Array.from(new Set(normalized));
  }

  const wholeToken = normalizeIngredientTypeToken(type);
  return wholeToken ? [wholeToken] : [];
}

export function getIngredientTypeLabels(type: string): string[] {
  const codes = getIngredientTypeCodes(type);
  if (codes.length === 0) {
    return [type];
  }

  return codes.map((code) => INGREDIENT_TYPE_LABELS[code] ?? code);
}

export function getIngredientCategories(type: string): IngredientCategory[] {
  const categories = getIngredientTypeCodes(type).map((code) => {
    switch (code) {
      case "vitamin":
        return "vitamins";
      case "mineral":
        return "minerals";
      case "fatty_acid":
        return "fatty-acids";
      case "probiotic":
        return "probiotics";
      case "herbal":
        return "herbals";
      case "amino_acid":
      case "enzyme":
      case "other":
      default:
        return "others";
    }
  });

  return Array.from(new Set(categories));
}

export function getIngredientCategory(type: string): IngredientCategory {
  return getIngredientCategories(type)[0] ?? "others";
}

export function getIngredientCategoryLabel(category: IngredientCategory): string {
  const map: Record<IngredientCategory, string> = {
    vitamins: "비타민",
    minerals: "미네랄",
    "fatty-acids": "지방산",
    probiotics: "프로바이오틱스",
    herbals: "허브/식물성",
    others: "기타",
  };
  return map[category];
}

export function getIngredientCategoryDescription(category: IngredientCategory): string {
  const map: Record<IngredientCategory, string> = {
    vitamins: "비타민 A, B군, C, D, E, K 등 필수 비타민과 복합 비타민 원료",
    minerals: "칼슘, 마그네슘, 아연, 철, 셀레늄 등 주요 미네랄 원료",
    "fatty-acids": "오메가-3, 감마리놀렌산, CLA 등 기능성 지방산 원료",
    probiotics: "장 건강과 면역, 체중, 피부 기능에 쓰이는 프로바이오틱스 및 균주 원료",
    herbals: "홍삼, 밀크씨슬, 루테인, 가르시니아 등 식물성 기능성 원료",
    others: "아미노산, 효소, 단백질, 복합 기능성 원료와 기타 분류",
  };
  return map[category];
}

export function isIngredientCategory(value: string): value is IngredientCategory {
  return (INGREDIENT_CATEGORY_ORDER as readonly string[]).includes(value);
}

export function getIngredientSubgroupLabel(type: string): string {
  return getIngredientTypeLabels(type)[0] ?? type;
}

export function getVitaminSubgroups(input: {
  canonicalNameKo?: string | null;
  canonicalNameEn?: string | null;
  scientificName?: string | null;
}): string[] {
  const haystack = [
    input.canonicalNameKo ?? "",
    input.canonicalNameEn ?? "",
    input.scientificName ?? "",
  ]
    .join(" ")
    .toLowerCase();

  const groups = new Set<string>();

  if (
    /비타민\s*a|비타민a|레티놀|retinol|베타카로틴|beta[\s-]?carotene/.test(haystack)
  ) {
    groups.add("비타민 A");
  }

  if (/비타민\s*b군|비타민b군|vitamin b complex|b-complex|b complex/.test(haystack)) {
    groups.add("비타민 B군");
  }

  if (/비타민\s*b1|비타민b1|티아민|thiamin|thiamine/.test(haystack)) {
    groups.add("비타민 B1");
  }

  if (/비타민\s*b2|비타민b2|리보플라빈|riboflavin/.test(haystack)) {
    groups.add("비타민 B2");
  }

  if (/비타민\s*b3|비타민b3|나이아신|niacin/.test(haystack)) {
    groups.add("비타민 B3");
  }

  if (/비타민\s*b5|비타민b5|판토텐|pantothen/.test(haystack)) {
    groups.add("비타민 B5");
  }

  if (/비타민\s*b6|비타민b6|피리독신|pyridox/.test(haystack)) {
    groups.add("비타민 B6");
  }

  if (/비타민\s*b7|비타민b7|비오틴|biotin/.test(haystack)) {
    groups.add("비타민 B7");
  }

  if (/비타민\s*b9|비타민b9|엽산|folate|folic acid/.test(haystack)) {
    groups.add("비타민 B9");
  }

  if (/비타민\s*b12|비타민b12|코발라민|cobalamin|메틸코발라민/.test(haystack)) {
    groups.add("비타민 B12");
  }

  if (/비타민\s*c|비타민c|아스코르브|ascorb/.test(haystack)) {
    groups.add("비타민 C");
  }

  if (/비타민\s*d|비타민d|콜레칼시페롤|cholecalciferol|에르고칼시페롤|ergocalciferol/.test(haystack)) {
    groups.add("비타민 D");
  }

  if (/비타민\s*e|비타민e|토코페롤|tocopherol|토코트리에놀|tocotrienol/.test(haystack)) {
    groups.add("비타민 E");
  }

  if (/비타민\s*k|비타민k|메나퀴논|menaquinone|필로퀴논|phylloquinone/.test(haystack)) {
    groups.add("비타민 K");
  }

  if (/루테인|lutein|지아잔틴|zeaxanthin/.test(haystack)) {
    groups.add("루테인·카로티노이드");
  }

  if (groups.size === 0) {
    groups.add("기타 복합 비타민");
  }

  return Array.from(groups);
}

/** 연구 설계 한글 변환 */
export function getStudyDesignLabel(design: string | null): string {
  const map: Record<string, string> = {
    meta_analysis: "메타분석",
    systematic_review: "체계적 문헌고찰",
    rct: "RCT",
    cohort: "코호트",
    case_control: "사례대조",
    guideline: "가이드라인",
    in_vitro: "시험관 연구",
    animal: "동물 연구",
  };
  return map[design ?? ""] ?? design ?? "";
}

/** 연구 설계 배지 색상 */
export function getStudyDesignColor(design: string | null): string {
  switch (design) {
    case "meta_analysis":
    case "systematic_review":
      return "bg-purple-100 text-purple-800";
    case "rct":
      return "bg-blue-100 text-blue-800";
    case "guideline":
      return "bg-teal-100 text-teal-800";
    default:
      return "bg-gray-100 text-gray-600";
  }
}

/** 효과 방향 한글 변환 */
export function getEffectDirectionLabel(direction: string | null): string {
  switch (direction) {
    case "positive":
      return "긍정적";
    case "negative":
      return "부정적";
    case "neutral":
      return "중립/제한적";
    case "mixed":
      return "혼합";
    default:
      return "";
  }
}

/** 효과 방향 배지 색상 */
export function getEffectDirectionBadgeColor(direction: string | null): string {
  switch (direction) {
    case "positive":
      return "bg-green-50 text-green-700";
    case "negative":
      return "bg-red-50 text-red-700";
    case "neutral":
      return "bg-gray-100 text-gray-600";
    case "mixed":
      return "bg-yellow-50 text-yellow-700";
    default:
      return "bg-gray-50 text-gray-500";
  }
}

export function getProbioticSubgroup(input: {
  canonicalNameKo?: string | null;
  canonicalNameEn?: string | null;
  scientificName?: string | null;
}): string {
  const haystack = [
    input.canonicalNameKo ?? "",
    input.canonicalNameEn ?? "",
    input.scientificName ?? "",
  ]
    .join(" ")
    .toLowerCase();

  if (!haystack.trim()) return "기타 균주";

  if (
    /bifidobacterium|비피도박테리움|비피도박테리움|b\.?\s*lactis|b\.?\s*longum|b\.?\s*bifidum/.test(
      haystack,
    )
  ) {
    return "비피도박테리움 계열";
  }

  if (
    /lactobacillus|lacticaseibacillus|lactiplantibacillus|limosilactobacillus|락토바실러스|락티카세이바실러스|락토플랜티바실러스|리모실락토바실러스/.test(
      haystack,
    )
  ) {
    return "락토바실러스 계열";
  }

  if (/streptococcus|enterococcus|스트렙토코커스|엔테로코커스/.test(haystack)) {
    return "스트렙토코커스/엔테로코커스";
  }

  if (/saccharomyces|bacillus|효모|바실러스/.test(haystack)) {
    return "효모/포자균 계열";
  }

  if (/복합물|혼합|complex|respecta|ckdb|hy7714|bnr17|제20\d{2}-\d+/.test(haystack)) {
    return "기능성·복합 균주";
  }

  if (/프로바이오틱스|유산균/.test(haystack)) {
    return "일반 프로바이오틱스";
  }

  return "기타 균주";
}

export function getIngredientHref(input: {
  id: number | string;
  slug?: string | null;
}): string {
  return input.slug ? `/ingredients/${input.slug}` : `/ingredients/${input.id}`;
}
