import Link from "next/link";
import { Search, FlaskConical, Package, ArrowRight } from "lucide-react";

export default function Home() {
  return (
    <div>
      {/* Hero */}
      <section className="bg-gradient-to-b from-green-50 to-white px-4 py-20 text-center">
        <h1 className="text-4xl font-bold tracking-tight text-gray-900 sm:text-5xl">
          영양제, 제대로 비교하세요
        </h1>
        <p className="mx-auto mt-4 max-w-2xl text-lg text-gray-600">
          식약처 인정 기능성과 학술 근거를 분리하여 보여드립니다.
          <br />
          규제 정보, 안전성, 용량까지 한눈에 확인하세요.
        </p>
        <div className="mx-auto mt-8 flex max-w-md gap-3">
          <Link
            href="/ingredients"
            className="flex-1 rounded-lg bg-green-600 px-6 py-3 text-sm font-medium text-white transition-colors hover:bg-green-700"
          >
            원료 사전
          </Link>
          <Link
            href="/products"
            className="flex-1 rounded-lg border border-gray-300 px-6 py-3 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50"
          >
            제품 비교
          </Link>
        </div>
      </section>

      {/* Features */}
      <section className="mx-auto max-w-6xl px-4 py-16">
        <div className="grid gap-8 md:grid-cols-3">
          <FeatureCard
            icon={<FlaskConical className="h-8 w-8 text-green-600" />}
            title="원료 사전"
            description="20종 핵심 원료의 기능성, 안전성, 약물 상호작용, 권장 용량을 확인하세요."
            href="/ingredients"
          />
          <FeatureCard
            icon={<Package className="h-8 w-8 text-blue-600" />}
            title="제품 비교"
            description="인기 제품의 원료 조성, 라벨 정보를 나란히 비교하고 성분 중복을 확인하세요."
            href="/products"
          />
          <FeatureCard
            icon={<Search className="h-8 w-8 text-purple-600" />}
            title="통합 검색"
            description="원료명, 제품명, 기능성으로 검색하세요. 동의어와 영문명도 지원합니다."
            href="/search"
          />
        </div>
      </section>

      {/* Trust Banner */}
      <section className="border-t border-gray-200 bg-gray-50 px-4 py-12 text-center">
        <h2 className="text-lg font-semibold text-gray-900">
          데이터 출처와 신뢰성
        </h2>
        <p className="mx-auto mt-2 max-w-2xl text-sm text-gray-500">
          식품안전나라 · 공공데이터포털 · PubMed · NIH DSLD · DailyMed 등 공신력
          있는 출처에서 수집하며, 3단계 검수(자동 QA → 과학 검수 → 규제 검수)를
          거쳐 게시합니다.
        </p>
        <Link
          href="/disclaimer"
          className="mt-4 inline-flex items-center gap-1 text-sm text-green-600 hover:underline"
        >
          의료 면책 조항 보기
          <ArrowRight className="h-3 w-3" />
        </Link>
      </section>
    </div>
  );
}

function FeatureCard({
  icon,
  title,
  description,
  href,
}: {
  icon: React.ReactNode;
  title: string;
  description: string;
  href: string;
}) {
  return (
    <Link
      href={href}
      className="group rounded-xl border border-gray-200 bg-white p-6 transition-shadow hover:shadow-md"
    >
      <div className="mb-4">{icon}</div>
      <h3 className="text-lg font-semibold text-gray-900 group-hover:text-green-600">
        {title}
      </h3>
      <p className="mt-2 text-sm text-gray-500">{description}</p>
    </Link>
  );
}
