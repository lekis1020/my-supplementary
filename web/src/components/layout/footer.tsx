import Link from "next/link";

export function Footer() {
  const projectReadmeHref = "https://github.com/lekis1020/my-supplementary#readme";

  return (
    <footer className="border-t border-gray-200 bg-gray-50">
      <div className="mx-auto max-w-6xl px-4 py-8">
        <div className="flex flex-col gap-6 md:flex-row md:justify-between">
          <div>
            <p className="font-bold text-green-600">NutriCompare</p>
            <p className="mt-1 text-sm text-gray-500">
              신뢰할 수 있는 영양제 비교 분석 플랫폼
            </p>
          </div>
          <div className="flex gap-8 text-sm text-gray-500">
            <div className="flex flex-col gap-2">
              <Link href="/ingredients" className="hover:text-gray-700">
                원료 사전
              </Link>
              <Link href="/products" className="hover:text-gray-700">
                제품 데이터베이스
              </Link>
            </div>
            <div className="flex flex-col gap-2">
              <Link href="/disclaimer" className="hover:text-gray-700">
                의료 면책 조항
              </Link>
              <a
                href={projectReadmeHref}
                target="_blank"
                rel="noreferrer"
                className="hover:text-gray-700"
              >
                서비스 소개
              </a>
            </div>
          </div>
        </div>
        <div className="mt-8 border-t border-gray-200 pt-4 text-xs text-gray-400">
          <p>
            본 서비스는 의학적 조언을 제공하지 않습니다. 건강 관련 결정은 반드시
            의료 전문가와 상담하세요.
          </p>
          <p className="mt-1">&copy; 2026 NutriCompare. All rights reserved.</p>
        </div>
      </div>
    </footer>
  );
}
