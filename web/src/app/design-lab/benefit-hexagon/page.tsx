import { BenefitHexagon } from "@/components/benefit/benefit-hexagon";
import type { BenefitClaimDetail, BenefitProfileItem } from "@/lib/benefit-profile";

const MOCK_PROFILE: BenefitProfileItem[] = [
  { key: "immune_antioxidant", state: "active", strength: 2 },
  { key: "gut_digestive", state: "active", strength: 2 },
  { key: "cardiometabolic", state: "possible", strength: 1 },
  { key: "bone_joint_mobility", state: "inactive", strength: 0 },
  { key: "beauty_vision", state: "active", strength: 2 },
  { key: "liver_cognitive_vitality", state: "possible", strength: 1 },
];

const MOCK_CLAIM_DETAILS: BenefitClaimDetail[] = [
  {
    key: "immune_antioxidant",
    claimNameKo: "항산화에 도움을 줄 수 있음",
    claimScope: "approved_kr",
    evidenceGrade: "A",
    isRegulatorApproved: true,
  },
  {
    key: "gut_digestive",
    claimNameKo: "유익균 증식 및 배변 활동 원활에 도움을 줄 수 있음",
    claimScope: "approved_kr",
    evidenceGrade: "A",
    isRegulatorApproved: true,
  },
  {
    key: "beauty_vision",
    claimNameKo: "눈의 피로도 개선에 도움을 줄 수 있음",
    claimScope: "studied",
    evidenceGrade: "B",
    isRegulatorApproved: false,
  },
  {
    key: "cardiometabolic",
    claimNameKo: "식후 혈당 상승 억제에 도움을 줄 가능성",
    claimScope: "studied",
    evidenceGrade: "C",
    isRegulatorApproved: false,
  },
];

export default function BenefitHexagonLabPage() {
  return (
    <div className="mx-auto min-h-screen max-w-5xl px-4 py-12">
      <h1 className="text-2xl font-bold text-slate-900">효능 육각형 테스트 페이지</h1>
      <p className="mt-2 text-sm text-slate-600">
        제품 상세 데이터와 무관하게 UI를 확인할 수 있도록 고정된 샘플 데이터로 렌더링합니다.
      </p>

      <div className="mt-8">
        <BenefitHexagon
          title="제품 효능 육각형 (샘플)"
          description="테스트용 샘플 데이터로 그래프와 텍스트 효능 요약이 함께 표시됩니다."
          profile={MOCK_PROFILE}
          claimDetails={MOCK_CLAIM_DETAILS}
        />
      </div>
    </div>
  );
}
