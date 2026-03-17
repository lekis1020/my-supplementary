export const BENEFIT_CATEGORY_ORDER = [
  "immune_antioxidant",
  "gut_digestive",
  "cardiometabolic",
  "bone_joint_mobility",
  "beauty_vision",
  "liver_cognitive_vitality",
] as const;

export type BenefitCategoryKey = (typeof BENEFIT_CATEGORY_ORDER)[number];
export type BenefitState = "active" | "possible" | "inactive";

export interface BenefitProfileItem {
  key: BenefitCategoryKey;
  state: BenefitState;
  strength: 0 | 1 | 2;
}

export interface BenefitClaimDetail {
  key: BenefitCategoryKey;
  claimNameKo: string;
  claimScope: string | null;
  evidenceGrade: string | null;
  isRegulatorApproved: boolean;
}

interface ClaimShape {
  evidence_grade?: string | null;
  is_regulator_approved?: boolean | null;
  raw_claim_text?: string | null;
  claims?:
    | {
        claim_category?: string | null;
        claim_scope?: string | null;
        claim_name_ko?: string | null;
      }
    | Array<{
        claim_category?: string | null;
        claim_scope?: string | null;
        claim_name_ko?: string | null;
      }>
    | null;
}

function getClaimMeta(claim: ClaimShape): {
  claim_category?: string | null;
  claim_scope?: string | null;
  claim_name_ko?: string | null;
} | null {
  if (!claim.claims) {
    return null;
  }

  return Array.isArray(claim.claims) ? claim.claims[0] ?? null : claim.claims;
}

function mapClaimCategoryToBenefitCategory(
  claimCategory: string | null | undefined,
): BenefitCategoryKey | null {
  switch (claimCategory) {
    case "immune":
    case "antioxidant":
      return "immune_antioxidant";
    case "gut":
      return "gut_digestive";
    case "cardiometabolic":
    case "glycemic":
    case "weight":
    case "risk_reduction":
      return "cardiometabolic";
    case "bone_joint":
    case "performance":
      return "bone_joint_mobility";
    case "skin":
    case "eye":
      return "beauty_vision";
    case "liver":
    case "cognitive":
    case "general_health":
      return "liver_cognitive_vitality";
    default:
      return null;
  }
}

function getClaimWeight(claim: ClaimShape): number {
  const claimMeta = getClaimMeta(claim);

  if (
    claim.is_regulator_approved ||
    claimMeta?.claim_scope === "approved_kr" ||
    claimMeta?.claim_scope === "approved_us"
  ) {
    return 2;
  }

  if (claim.evidence_grade === "A" || claim.evidence_grade === "B") {
    return 2;
  }

  if (claim.evidence_grade || claimMeta?.claim_scope === "studied") {
    return 1;
  }

  return 1;
}

export function buildBenefitProfile(claims: ClaimShape[]): BenefitProfileItem[] {
  const scoreMap = new Map<BenefitCategoryKey, number>(
    BENEFIT_CATEGORY_ORDER.map((key) => [key, 0]),
  );

  claims.forEach((claim) => {
    const claimMeta = getClaimMeta(claim);
    const category = mapClaimCategoryToBenefitCategory(claimMeta?.claim_category);

    if (!category) {
      return;
    }

    const nextWeight = getClaimWeight(claim);
    const currentWeight = scoreMap.get(category) ?? 0;
    scoreMap.set(category, Math.max(currentWeight, nextWeight));
  });

  return BENEFIT_CATEGORY_ORDER.map((key) => {
    const weight = scoreMap.get(key) ?? 0;

    return {
      key,
      state: weight >= 2 ? "active" : weight === 1 ? "possible" : "inactive",
      strength: weight >= 2 ? 2 : weight === 1 ? 1 : 0,
    };
  });
}

export function buildBenefitClaimDetails(claims: ClaimShape[]): BenefitClaimDetail[] {
  const detailMap = new Map<string, BenefitClaimDetail>();

  claims.forEach((claim) => {
    const claimMeta = getClaimMeta(claim);
    const key = mapClaimCategoryToBenefitCategory(claimMeta?.claim_category);
    if (!key) {
      return;
    }

    const claimNameKo = claimMeta?.claim_name_ko?.trim() || claim.raw_claim_text?.trim();
    if (!claimNameKo) {
      return;
    }

    const mapKey = `${key}:${claimNameKo}`;
    const previous = detailMap.get(mapKey);
    const nextDetail: BenefitClaimDetail = {
      key,
      claimNameKo,
      claimScope: claimMeta?.claim_scope ?? null,
      evidenceGrade: claim.evidence_grade ?? null,
      isRegulatorApproved: Boolean(claim.is_regulator_approved),
    };

    if (!previous) {
      detailMap.set(mapKey, nextDetail);
      return;
    }

    const previousScore =
      Number(previous.isRegulatorApproved) * 10 +
      Number(previous.evidenceGrade === "A") * 3 +
      Number(previous.evidenceGrade === "B") * 2 +
      Number(Boolean(previous.evidenceGrade));
    const nextScore =
      Number(nextDetail.isRegulatorApproved) * 10 +
      Number(nextDetail.evidenceGrade === "A") * 3 +
      Number(nextDetail.evidenceGrade === "B") * 2 +
      Number(Boolean(nextDetail.evidenceGrade));

    if (nextScore > previousScore) {
      detailMap.set(mapKey, nextDetail);
    }
  });

  return Array.from(detailMap.values());
}
