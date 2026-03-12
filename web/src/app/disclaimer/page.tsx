import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "의료 면책 조항",
  description: "NutriCompare 서비스의 의료 면책 조항 및 이용 안내",
};

export default function DisclaimerPage() {
  return (
    <div className="mx-auto max-w-3xl px-4 py-12">
      <h1 className="mb-8 text-3xl font-bold text-gray-900">의료 면책 조항</h1>

      <div className="space-y-8 text-gray-600 leading-relaxed">
        <section>
          <h2 className="mb-3 text-xl font-semibold text-gray-800">
            1. 정보 제공 목적
          </h2>
          <p>
            NutriCompare(이하 &quot;본 서비스&quot;)에서 제공하는 모든 정보는
            <strong> 일반적인 정보 제공 목적</strong>으로만 제공됩니다.
            본 서비스의 어떠한 내용도 의학적 조언, 진단 또는 치료를
            대체할 수 없으며, 대체하려는 의도가 없습니다.
          </p>
        </section>

        <section>
          <h2 className="mb-3 text-xl font-semibold text-gray-800">
            2. 의료 전문가 상담
          </h2>
          <p>
            건강 상태에 대한 질문이 있거나, 영양제·건강기능식품의 복용을
            시작·변경·중단하려는 경우, <strong>반드시 의사, 약사 또는 자격을
            갖춘 의료 전문가</strong>와 상담하십시오.
          </p>
          <p className="mt-2">
            특히 다음에 해당하는 경우 전문가 상담이 필수적입니다:
          </p>
          <ul className="mt-2 list-inside list-disc space-y-1">
            <li>처방약을 복용 중인 경우</li>
            <li>임신 중이거나 수유 중인 경우</li>
            <li>만성 질환이 있는 경우</li>
            <li>수술을 앞두고 있는 경우</li>
            <li>18세 미만인 경우</li>
          </ul>
        </section>

        <section>
          <h2 className="mb-3 text-xl font-semibold text-gray-800">
            3. 데이터 정확성
          </h2>
          <p>
            본 서비스는 공신력 있는 출처(식품의약품안전처, PubMed, NIH DSLD 등)에서
            정보를 수집하며, 3단계 검수 프로세스를 통해 정확성을 확보하기 위해
            노력합니다. 그러나 다음 사항을 인지해 주십시오:
          </p>
          <ul className="mt-2 list-inside list-disc space-y-1">
            <li>과학적 연구는 지속적으로 업데이트되며, 새로운 발견에 의해 기존 정보가 수정될 수 있습니다.</li>
            <li>제품의 성분 조성은 제조사에 의해 변경될 수 있으며, 본 서비스의 정보가 최신 상태를 반영하지 못할 수 있습니다.</li>
            <li>개인의 건강 상태, 유전적 특성, 복용 중인 약물에 따라 영양소의 효과와 안전성이 달라질 수 있습니다.</li>
          </ul>
        </section>

        <section>
          <h2 className="mb-3 text-xl font-semibold text-gray-800">
            4. 규제 정보와 학술 근거의 구분
          </h2>
          <p>
            본 서비스는 <strong>규제 기관이 인정한 기능성</strong>과
            <strong> 학술 연구에 기반한 효능</strong>을 명확히 구분하여 표시합니다.
          </p>
          <ul className="mt-2 list-inside list-disc space-y-1">
            <li>
              <strong>&quot;식약처 인정&quot;</strong>: 한국 식품의약품안전처가 인정한 건강기능식품의 기능성
            </li>
            <li>
              <strong>&quot;학술 연구&quot;</strong>: 학술 논문에서 보고된 연구 결과로, 규제 기관의 공식 인정을 받지 않은 정보
            </li>
          </ul>
          <p className="mt-2">
            &quot;학술 연구&quot;로 표시된 정보는 규제 기관의 공식 인정을 의미하지 않으며,
            연구 결과가 반드시 개인에게 동일하게 적용되는 것은 아닙니다.
          </p>
        </section>

        <section>
          <h2 className="mb-3 text-xl font-semibold text-gray-800">
            5. 근거 등급 안내
          </h2>
          <p>본 서비스에서 사용하는 근거 등급은 다음과 같은 의미입니다:</p>
          <div className="mt-3 overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b text-left">
                  <th className="pb-2 pr-4">등급</th>
                  <th className="pb-2 pr-4">의미</th>
                  <th className="pb-2">근거 수준</th>
                </tr>
              </thead>
              <tbody>
                <tr className="border-b border-gray-100">
                  <td className="py-2 pr-4 font-medium">A</td>
                  <td className="py-2 pr-4">매우 강함</td>
                  <td className="py-2 text-sm text-gray-500">다수의 대규모 RCT, 메타분석</td>
                </tr>
                <tr className="border-b border-gray-100">
                  <td className="py-2 pr-4 font-medium">B</td>
                  <td className="py-2 pr-4">강함</td>
                  <td className="py-2 text-sm text-gray-500">다수의 소규모 RCT 또는 일부 대규모 연구</td>
                </tr>
                <tr className="border-b border-gray-100">
                  <td className="py-2 pr-4 font-medium">C</td>
                  <td className="py-2 pr-4">보통</td>
                  <td className="py-2 text-sm text-gray-500">제한적 임상 연구 또는 관찰 연구</td>
                </tr>
                <tr className="border-b border-gray-100">
                  <td className="py-2 pr-4 font-medium">D</td>
                  <td className="py-2 pr-4">약함</td>
                  <td className="py-2 text-sm text-gray-500">사례 보고 또는 전문가 의견</td>
                </tr>
                <tr>
                  <td className="py-2 pr-4 font-medium">F</td>
                  <td className="py-2 pr-4">불충분</td>
                  <td className="py-2 text-sm text-gray-500">근거 불충분 또는 상충하는 결과</td>
                </tr>
              </tbody>
            </table>
          </div>
        </section>

        <section>
          <h2 className="mb-3 text-xl font-semibold text-gray-800">
            6. 면책 사항
          </h2>
          <p>
            본 서비스의 정보를 사용하여 발생하는 어떠한 건강상의 문제, 손해 또는
            불이익에 대해 NutriCompare는 책임을 지지 않습니다.
            모든 건강 관련 결정의 최종 책임은 이용자 본인에게 있습니다.
          </p>
        </section>

        <section>
          <h2 className="mb-3 text-xl font-semibold text-gray-800">
            7. 건강기능식품 관련 법적 고지
          </h2>
          <p>
            건강기능식품은 질병의 예방 및 치료를 위한 의약품이 아닙니다.
            &quot;건강기능식품&quot;이라는 표시는 식품의약품안전처장이 정한
            기준과 규격에 적합한 원료나 성분을 사용하여 제조한 식품을 의미하며,
            의약품으로서의 효능·효과가 있는 것은 아닙니다.
          </p>
        </section>

        <div className="rounded-lg border border-gray-200 bg-gray-50 p-4 text-sm text-gray-500">
          <p>
            본 면책 조항은 2026년 3월 12일에 최종 업데이트되었습니다.
          </p>
        </div>
      </div>
    </div>
  );
}
