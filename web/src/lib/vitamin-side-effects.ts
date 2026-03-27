import { getVitaminSubgroups } from "@/lib/utils";

export interface VitaminSideEffectInfo {
  subgroup: string;
  summary: string;
  caution: string;
  referenceUrl: string;
}

const VITAMIN_SIDE_EFFECTS: Record<string, Omit<VitaminSideEffectInfo, "subgroup">> = {
  "비타민 A": {
    summary: "과다 섭취 시 두통, 어지러움, 간독성, 임신 중 태아 위험이 보고됩니다.",
    caution: "UL 초과 복용을 피하고, 임신·수유 중에는 의료진과 용량을 확인하세요.",
    referenceUrl: "https://ods.od.nih.gov/factsheets/VitaminA-HealthProfessional/#h8",
  },
  "비타민 B군": {
    summary: "일반적으로 안전하지만 고용량에서는 위장 불편, 홍조(니아신), 말초신경 이상(B6) 가능성이 있습니다.",
    caution: "복합제는 개별 B 비타민 총량을 합산해 확인하세요.",
    referenceUrl: "https://ods.od.nih.gov/factsheets/Niacin-HealthProfessional/#h8",
  },
  "비타민 B1": {
    summary: "경구 보충은 대체로 안전하며 드문 과민반응이 보고됩니다.",
    caution: "주사제 사용 시 과민반응 병력을 확인하세요.",
    referenceUrl: "https://ods.od.nih.gov/factsheets/Thiamin-HealthProfessional/",
  },
  "비타민 B2": {
    summary: "독성 보고가 드물고, 고용량에서 소변이 진한 노란색으로 변할 수 있습니다.",
    caution: "임상적으로 의미 있는 독성은 드물지만 복합제 중복 복용은 피하세요.",
    referenceUrl: "https://ods.od.nih.gov/factsheets/Riboflavin-HealthProfessional/",
  },
  "비타민 B3": {
    summary: "고용량 니아신은 홍조, 가려움, 간효소 상승 및 간독성 위험을 높일 수 있습니다.",
    caution: "지질 조절 목적의 고용량은 의료진 모니터링 하에서만 사용하세요.",
    referenceUrl: "https://ods.od.nih.gov/factsheets/Niacin-HealthProfessional/#h8",
  },
  "비타민 B5": {
    summary: "고용량에서 설사, 위장 불편이 보고됩니다.",
    caution: "지속적 위장 증상이 있으면 용량을 줄이고 복용 간격을 조정하세요.",
    referenceUrl: "https://ods.od.nih.gov/factsheets/PantothenicAcid-HealthProfessional/",
  },
  "비타민 B6": {
    summary: "장기간 고용량 복용 시 감각신경병증(저림, 감각 이상) 위험이 있습니다.",
    caution: "장기 복용 시 총 일일 섭취량을 확인하고 신경 증상 발생 시 중단하세요.",
    referenceUrl: "https://ods.od.nih.gov/factsheets/VitaminB6-HealthProfessional/#h8",
  },
  "비타민 B7": {
    summary: "중대한 독성은 드물지만 일부 검사(갑상선, 심근표지자) 결과를 왜곡할 수 있습니다.",
    caution: "혈액검사 전 비오틴 복용 여부를 의료진·검사실에 반드시 알리세요.",
    referenceUrl: "https://ods.od.nih.gov/factsheets/Biotin-HealthProfessional/",
  },
  "비타민 B9": {
    summary: "고용량 엽산은 비타민 B12 결핍에 의한 혈액학적 이상을 가려 진단을 지연시킬 수 있습니다.",
    caution: "고용량 보충 시 B12 상태를 함께 평가하세요.",
    referenceUrl: "https://ods.od.nih.gov/factsheets/Folate-HealthProfessional/#h8",
  },
  "비타민 B12": {
    summary: "대체로 안전성이 높으나 드물게 피부 반응, 위장 불편이 보고됩니다.",
    caution: "기저 질환 또는 다약제 복용 중이면 상호작용 가능성을 점검하세요.",
    referenceUrl: "https://ods.od.nih.gov/factsheets/VitaminB12-HealthProfessional/#h8",
  },
  "비타민 C": {
    summary: "고용량 복용 시 설사, 복통, 메스꺼움이 흔하며 신장결석 위험이 증가할 수 있습니다.",
    caution: "신장결석 병력이 있으면 고용량 장기 복용을 피하세요.",
    referenceUrl: "https://ods.od.nih.gov/factsheets/VitaminC-HealthProfessional/#h8",
  },
  "비타민 D": {
    summary: "과다 복용 시 고칼슘혈증, 오심, 혼동, 신장 손상 위험이 있습니다.",
    caution: "고용량 복용 시 혈중 25(OH)D 및 칼슘 수치 모니터링이 필요합니다.",
    referenceUrl: "https://ods.od.nih.gov/factsheets/VitaminD-HealthProfessional/#h8",
  },
  "비타민 E": {
    summary: "고용량 복용은 출혈성 위험 증가와 일부 약물(항응고제) 상호작용 가능성이 있습니다.",
    caution: "항응고제 복용 중이라면 의료진 확인 없이 고용량을 피하세요.",
    referenceUrl: "https://ods.od.nih.gov/factsheets/VitaminE-HealthProfessional/#h8",
  },
  "비타민 K": {
    summary: "비타민 K는 와파린 등 항응고제 효과에 영향을 줄 수 있습니다.",
    caution: "항응고제 복용 중이면 섭취량을 급격히 변경하지 마세요.",
    referenceUrl: "https://ods.od.nih.gov/factsheets/VitaminK-HealthProfessional/#h8",
  },
};

export function getVitaminSideEffectInfoBySubgroup(
  subgroup: string,
): VitaminSideEffectInfo | null {
  const info = VITAMIN_SIDE_EFFECTS[subgroup];
  if (!info) {
    return null;
  }

  return {
    subgroup,
    ...info,
  };
}

interface VitaminIdentityInput {
  canonicalNameKo: string;
  canonicalNameEn: string | null;
  scientificName: string | null;
}

export function getVitaminSideEffectInfosForIngredient(
  input: VitaminIdentityInput,
): VitaminSideEffectInfo[] {
  const subgroups = getVitaminSubgroups(input);

  return subgroups
    .map((subgroup) => getVitaminSideEffectInfoBySubgroup(subgroup))
    .filter((item): item is VitaminSideEffectInfo => Boolean(item));
}
