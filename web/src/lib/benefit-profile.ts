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

interface ClaimShape {
  evidence_grade?: string | null;
  is_regulator_approved?: boolean | null;
  claims?: {
    claim_category?: string | null;
    claim_scope?: string | null;
  } | null;
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
  if (
    claim.is_regulator_approved ||
    claim.claims?.claim_scope === "approved_kr" ||
    claim.claims?.claim_scope === "approved_us"
  ) {
    return 2;
  }

  if (claim.evidence_grade === "A" || claim.evidence_grade === "B") {
    return 2;
  }

  if (claim.evidence_grade || claim.claims?.claim_scope === "studied") {
    return 1;
  }

  return 1;
}

export function buildBenefitProfile(claims: ClaimShape[]): BenefitProfileItem[] {
  const scoreMap = new Map<BenefitCategoryKey, number>(
    BENEFIT_CATEGORY_ORDER.map((key) => [key, 0]),
  );

  claims.forEach((claim) => {
    const category = mapClaimCategoryToBenefitCategory(claim.claims?.claim_category);

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
