import Link from "next/link";
import type { ReactNode } from "react";
import {
  ArrowRight,
  FlaskConical,
  Package,
  Search,
  ShieldCheck,
  Sparkles,
} from "lucide-react";

const stats = [
  { label: "공개 제품", value: "44,000+" },
  { label: "원료 데이터", value: "700+" },
  { label: "검토 축", value: "기능성 · 안전성 · 용량" },
];

const proofPoints = [
  "식약처 인정 기능성과 학술 근거를 분리해서 표기",
  "원료 포함 제품을 찾아 주성분/부원료 단위로 구분",
  "제품별 라벨 문구와 원료 조성을 한 화면에서 교차 확인",
];

export default function Home() {
  return (
    <div className="bg-white">
      <section className="overflow-hidden border-b border-slate-200 bg-[radial-gradient(circle_at_top_left,#dcfce7,transparent_35%),radial-gradient(circle_at_top_right,#dbeafe,transparent_28%),linear-gradient(180deg,#f8fffb_0%,#ffffff_68%)] px-4 py-18 sm:py-24">
        <div className="mx-auto grid max-w-6xl gap-14 lg:grid-cols-[minmax(0,1.2fr)_440px] lg:items-center">
          <div>
            <div className="inline-flex items-center gap-2 rounded-full border border-emerald-200 bg-white/90 px-4 py-2 text-xs font-semibold uppercase tracking-[0.18em] text-emerald-700 shadow-sm">
              <ShieldCheck className="h-4 w-4" />
              Regulatory-first supplement search
            </div>

            <h1 className="mt-6 text-4xl font-black tracking-tight text-slate-950 sm:text-5xl lg:text-6xl">
              영양제 비교를
              <br />
              광고 문구가 아니라
              <br />
              데이터 기준으로
            </h1>

            <p className="mt-5 max-w-2xl text-lg leading-8 text-slate-600">
              bochoong.com은 제품명 검색만 하는 사이트가 아닙니다. 어떤 원료가 실제로
              들어 있는지, 그 원료가 주성분인지 부원료인지, 규제상 인정된 표현인지까지
              나눠서 읽을 수 있게 설계했습니다.
            </p>

            <div className="mt-8 flex flex-col gap-3 sm:flex-row">
              <Link
                href="/search"
                className="inline-flex items-center justify-center gap-2 rounded-2xl bg-emerald-600 px-6 py-3.5 text-sm font-semibold text-white transition-colors hover:bg-emerald-700"
              >
                통합 검색 시작
                <ArrowRight className="h-4 w-4" />
              </Link>
              <Link
                href="/compare"
                className="inline-flex items-center justify-center gap-2 rounded-2xl border border-slate-300 bg-white px-6 py-3.5 text-sm font-semibold text-slate-700 transition-colors hover:border-emerald-200 hover:text-emerald-700"
              >
                비교 도구 열기
              </Link>
            </div>

            <div className="mt-10 grid gap-3 sm:grid-cols-3">
              {stats.map((stat) => (
                <div key={stat.label} className="rounded-2xl border border-white/80 bg-white/80 p-4 shadow-sm backdrop-blur">
                  <div className="text-xl font-black tracking-tight text-slate-900">{stat.value}</div>
                  <div className="mt-1 text-sm text-slate-500">{stat.label}</div>
                </div>
              ))}
            </div>
          </div>

          <div className="rounded-[28px] border border-slate-200 bg-white p-6 shadow-[0_24px_80px_rgba(15,23,42,0.08)]">
            <div className="flex items-center justify-between border-b border-slate-100 pb-4">
              <div>
                <p className="text-xs font-semibold uppercase tracking-[0.16em] text-emerald-600">
                  Review Flow
                </p>
                <h2 className="mt-2 text-2xl font-bold text-slate-900">
                  제품을 읽는 순서
                </h2>
              </div>
              <Sparkles className="h-5 w-5 text-emerald-500" />
            </div>

            <div className="mt-5 space-y-4">
              {proofPoints.map((point, index) => (
                <div key={point} className="flex gap-4 rounded-2xl bg-slate-50 px-4 py-4">
                  <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-emerald-600 text-sm font-bold text-white">
                    {index + 1}
                  </div>
                  <p className="text-sm leading-6 text-slate-700">{point}</p>
                </div>
              ))}
            </div>

            <div className="mt-6 rounded-2xl border border-emerald-100 bg-emerald-50 p-4">
              <p className="text-sm font-semibold text-emerald-900">추천 진입 경로</p>
              <p className="mt-1 text-sm leading-6 text-emerald-800">
                특정 원료를 먼저 확인하려면 <strong>원료 사전</strong>, 복용 중인 제품 조합을
                나란히 보고 싶다면 <strong>비교 도구</strong>가 가장 빠릅니다.
              </p>
            </div>
          </div>
        </div>
      </section>

      <section className="mx-auto max-w-6xl px-4 py-16">
        <div className="mb-8 max-w-2xl">
          <p className="text-xs font-semibold uppercase tracking-[0.18em] text-slate-500">
            Core Paths
          </p>
          <h2 className="mt-3 text-3xl font-black tracking-tight text-slate-900">
            필요한 작업부터 바로 들어가세요
          </h2>
        </div>

        <div className="grid gap-6 lg:grid-cols-3">
          <FeatureCard
            icon={<FlaskConical className="h-8 w-8 text-emerald-600" />}
            title="원료 사전"
            description="원료를 카테고리별로 훑고, 기능성·안전성·용량 근거를 먼저 읽습니다."
            href="/ingredients"
          />
          <FeatureCard
            icon={<Package className="h-8 w-8 text-blue-600" />}
            title="제품 비교"
            description="제품 조성, 라벨 정보, 포함 원료를 보고 어떤 제품이 무엇을 중심으로 설계됐는지 확인합니다."
            href="/products"
          />
          <FeatureCard
            icon={<Search className="h-8 w-8 text-slate-900" />}
            title="통합 검색"
            description="검색한 원료가 제품의 주성분인지 부원료인지 구분해서 결과를 확인합니다."
            href="/search"
          />
        </div>
      </section>

      <section className="border-y border-slate-200 bg-slate-50 px-4 py-14">
        <div className="mx-auto max-w-6xl">
          <div className="grid gap-8 lg:grid-cols-[minmax(0,0.9fr)_minmax(0,1.1fr)] lg:items-start">
            <div>
              <p className="text-xs font-semibold uppercase tracking-[0.18em] text-emerald-600">
                Why Trust
              </p>
              <h2 className="mt-3 text-3xl font-black tracking-tight text-slate-900">
                데이터 출처와 검토 원칙
              </h2>
              <p className="mt-4 text-base leading-7 text-slate-600">
                식품안전나라, 공공데이터포털, PubMed, NIH DSLD, DailyMed 등 공신력 있는
                출처를 기반으로 수집하고, 원료 기능성 해석과 제품 라벨 표기를 분리해서
                보여줍니다.
              </p>
              <Link
                href="/disclaimer"
                className="mt-5 inline-flex items-center gap-2 text-sm font-semibold text-emerald-700 hover:text-emerald-800"
              >
                의료 면책 조항 보기
                <ArrowRight className="h-4 w-4" />
              </Link>
            </div>

            <div className="grid gap-4 md:grid-cols-2">
              <TrustCard
                title="규제 기준 우선"
                body="식약처 인정 표현과 연구 기반 표현을 한데 섞지 않고 별도로 보여줍니다."
              />
              <TrustCard
                title="원료 역할 구분"
                body="같은 원료라도 제품 안에서 주성분인지 부원료인지 구분해 해석할 수 있습니다."
              />
              <TrustCard
                title="라벨 문구 보존"
                body="정규화된 원료명과 함께 라벨 원문을 남겨서 추적 가능성을 유지합니다."
              />
              <TrustCard
                title="복용 조합 검토"
                body="비교 도구에서 중복 원료와 동일 단위 비교를 빠르게 읽을 수 있습니다."
              />
            </div>
          </div>
        </div>
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
  icon: ReactNode;
  title: string;
  description: string;
  href: string;
}) {
  return (
    <Link
      href={href}
      className="group rounded-[24px] border border-slate-200 bg-white p-6 shadow-sm transition-all hover:-translate-y-0.5 hover:border-emerald-200 hover:shadow-lg"
    >
      <div className="mb-5">{icon}</div>
      <h3 className="text-xl font-bold text-slate-900 group-hover:text-emerald-700">
        {title}
      </h3>
      <p className="mt-3 text-sm leading-6 text-slate-500">{description}</p>
      <div className="mt-6 inline-flex items-center gap-2 text-sm font-semibold text-emerald-700">
        바로 보기
        <ArrowRight className="h-4 w-4" />
      </div>
    </Link>
  );
}

function TrustCard({
  title,
  body,
}: {
  title: string;
  body: string;
}) {
  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
      <h3 className="text-base font-bold text-slate-900">{title}</h3>
      <p className="mt-2 text-sm leading-6 text-slate-500">{body}</p>
    </div>
  );
}
