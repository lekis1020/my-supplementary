// Pure grouping/sorting/merge logic for the probiotic strain comparison page.
// No React or DB dependencies — unit-tested in isolation.

export const PROBIOTIC_BENEFIT_AXES: ReadonlyArray<{ claimCode: string; label: string }> = [
  { claimCode: "GUT_HEALTH", label: "장건강" },
  { claimCode: "IMMUNE_FUNCTION", label: "면역" },
  { claimCode: "MENTAL_HEALTH", label: "정신건강" },
  { claimCode: "WEIGHT_MANAGEMENT", label: "체지방" },
];

const COMBINATION_SLUGS = [
  "lactobacillus-helveticus-r0052",
  "bifidobacterium-longum-r0175",
];
const COMBINATION_CLAIM_CODE = "MENTAL_HEALTH";
const COMBINATION_KEY = "combo-r0052-r0175";
const COMBINATION_NAME = "L. helveticus R0052 + B. longum R0175 (사이코바이오틱스 조합)";

export interface StrainClaimInput {
  ingredientId: number;
  slug: string | null;
  strainName: string;
  scientificName: string | null;
  cfuText: string | null;
  claimCode: string;
  claimNameKo: string | null;
  evidenceGrade: string | null;
  evidenceSummary: string | null;
  allowedExpression: string | null;
  isRegulatorApproved: boolean;
}

export interface StrainRow {
  key: string;
  strainName: string;
  scientificName: string | null;
  href: string | null;
  cfuText: string | null;
  evidenceGrade: string | null;
  evidenceSummary: string | null;
  allowedExpression: string | null;
  isRegulatorApproved: boolean;
  isCombination: boolean;
}

export interface BenefitGroup {
  claimCode: string;
  label: string;
  claimNameKo: string | null;
  rows: StrainRow[];
}

function gradeRank(grade: string | null): number {
  switch (grade) {
    case "A": return 0;
    case "B": return 1;
    case "C": return 2;
    case "D": return 3;
    case "F": return 4;
    default: return 5;
  }
}

function toRow(input: StrainClaimInput): StrainRow {
  return {
    key: input.slug ?? String(input.ingredientId),
    strainName: input.strainName,
    scientificName: input.scientificName,
    href: input.slug ? `/ingredients/${input.slug}` : null,
    cfuText: input.cfuText,
    evidenceGrade: input.evidenceGrade,
    evidenceSummary: input.evidenceSummary,
    allowedExpression: input.allowedExpression,
    isRegulatorApproved: input.isRegulatorApproved,
    isCombination: false,
  };
}

function mergeCombination(inputs: StrainClaimInput[]): StrainRow {
  // Prefer the strongest grade and any regulator approval / non-empty text across the pair.
  const sorted = [...inputs].sort((a, b) => gradeRank(a.evidenceGrade) - gradeRank(b.evidenceGrade));
  const best = sorted[0];
  return {
    key: COMBINATION_KEY,
    strainName: COMBINATION_NAME,
    scientificName: null,
    href: null,
    cfuText: best.cfuText,
    evidenceGrade: best.evidenceGrade,
    evidenceSummary: best.evidenceSummary,
    allowedExpression: inputs.find((i) => i.allowedExpression)?.allowedExpression ?? null,
    isRegulatorApproved: inputs.some((i) => i.isRegulatorApproved),
    isCombination: true,
  };
}

function sortRows(rows: StrainRow[]): StrainRow[] {
  return [...rows].sort((a, b) => {
    if (a.isRegulatorApproved !== b.isRegulatorApproved) {
      return a.isRegulatorApproved ? -1 : 1;
    }
    const gradeDiff = gradeRank(a.evidenceGrade) - gradeRank(b.evidenceGrade);
    if (gradeDiff !== 0) return gradeDiff;
    return a.strainName.localeCompare(b.strainName, "ko");
  });
}

export function buildBenefitGroups(inputs: StrainClaimInput[]): BenefitGroup[] {
  return PROBIOTIC_BENEFIT_AXES.map((axis) => {
    const axisInputs = inputs.filter((i) => i.claimCode === axis.claimCode);

    const comboInputs = axisInputs.filter(
      (i) => axis.claimCode === COMBINATION_CLAIM_CODE && i.slug != null && COMBINATION_SLUGS.includes(i.slug),
    );
    const normalInputs = axisInputs.filter((i) => !comboInputs.includes(i));

    const rows: StrainRow[] = normalInputs.map(toRow);
    if (comboInputs.length > 0) {
      rows.push(mergeCombination(comboInputs));
    }

    const claimNameKo = axisInputs.find((i) => i.claimNameKo)?.claimNameKo ?? null;

    return {
      claimCode: axis.claimCode,
      label: axis.label,
      claimNameKo,
      rows: sortRows(rows),
    };
  }).filter((group) => group.rows.length > 0);
}
