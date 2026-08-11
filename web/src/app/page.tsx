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
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { CTAButton } from "@/components/ui/cta-button";
import { SummaryStat } from "@/components/ui/summary-stat";
import { SectionHeader } from "@/components/ui/section-header";

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
    <div className="bg-canvas">
      <section className="overflow-hidden border-b border-stone-200 bg-gradient-to-br from-brand-bg via-canvas to-surface px-4 py-18 sm:py-24">
        <div className="mx-auto grid max-w-6xl gap-14 lg:grid-cols-[minmax(0,1.2fr)_440px] lg:items-center">
          <div>
            <div className="inline-flex items-center gap-2 rounded-full border border-orange-100 bg-surface/90 px-4 py-2 text-xs font-semibold uppercase tracking-[0.18em] text-orange-700 shadow-card">
              <ShieldCheck className="h-4 w-4" />
              Regulatory-first supplement search
            </div>

            <h1 className="mt-6 text-4xl font-extrabold tracking-tight text-ink sm:text-5xl lg:text-6xl">
              영양제 비교를
              <br />
              광고 문구가 아니라
              <br />
              데이터 기준으로
            </h1>

            <p className="mt-5 max-w-2xl text-lg leading-8 text-ink-muted">
              bochoong.com은 제품명 검색만 하는 사이트가 아닙니다. 어떤 원료가 실제로
              들어 있는지, 그 원료가 주성분인지 부원료인지, 규제상 인정된 표현인지까지
              나눠서 읽을 수 있게 설계했습니다.
            </p>

            <div className="mt-8 flex flex-col gap-3 sm:flex-row">
              <CTAButton href="/search" variant="primary">
                통합 검색 시작
                <ArrowRight className="h-4 w-4" />
              </CTAButton>
              <CTAButton href="/products#compare-tool" variant="outline">
                비교 도구 열기
              </CTAButton>
            </div>

            <div className="mt-10 grid gap-3 sm:grid-cols-3">
              {stats.map((stat) => (
                <SummaryStat key={stat.label} value={stat.value} label={stat.label} />
              ))}
            </div>
          </div>

          <Card tone="highlight" className="shadow-[0_24px_80px_rgba(120,80,20,0.12)]">
            <div className="flex items-center justify-between border-b border-orange-100 pb-4">
              <div>
                <p className="text-xs font-semibold uppercase tracking-[0.16em] text-orange-600">
                  Review Flow
                </p>
                <h2 className="mt-2 text-2xl font-bold text-ink">
                  제품을 읽는 순서
                </h2>
              </div>
              <Sparkles className="h-5 w-5 text-orange-500" />
            </div>

            <div className="mt-5 space-y-4">
              {proofPoints.map((point, index) => (
                <div key={point} className="flex gap-4 rounded-2xl bg-surface px-4 py-4 shadow-card">
                  <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-orange-700 text-sm font-bold text-white">
                    {index + 1}
                  </div>
                  <p className="text-sm leading-6 text-ink">{point}</p>
                </div>
              ))}
            </div>

            <div className="mt-6 rounded-2xl border border-orange-100 bg-surface p-4">
              <p className="text-sm font-semibold text-ink">추천 진입 경로</p>
              <p className="mt-1 text-sm leading-6 text-ink-muted">
                특정 원료를 먼저 확인하려면 <strong>원료 사전</strong>, 복용 중인 제품 조합을
                나란히 보고 싶다면 <strong>제품 데이터베이스 상단 비교 도구</strong>가 가장 빠릅니다.
              </p>
            </div>
          </Card>
        </div>
      </section>

      <section className="mx-auto max-w-6xl px-4 py-16">
        <SectionHeader
          icon={<Sparkles className="h-5 w-5" />}
          title="필요한 작업부터 바로 들어가세요"
          description="Core Paths — 원료 사전, 제품 데이터베이스, 통합 검색"
          className="mb-8"
        />

        <div className="grid gap-6 lg:grid-cols-3">
          <FeatureCard
            icon={<FlaskConical className="h-8 w-8 text-orange-600" />}
            tag="Ingredients"
            title="원료 사전"
            description="원료를 카테고리별로 훑고, 기능성·안전성·용량 근거를 먼저 읽습니다."
            href="/ingredients"
          />
          <FeatureCard
            icon={<Package className="h-8 w-8 text-orange-600" />}
            tag="Products"
            title="제품 데이터베이스"
            description="제품 조성, 라벨 정보, 포함 원료를 보고 어떤 제품이 무엇을 중심으로 설계됐는지 확인합니다. 상단에서 비교 도구도 바로 사용할 수 있습니다."
            href="/products"
          />
          <FeatureCard
            icon={<Search className="h-8 w-8 text-orange-600" />}
            tag="Search"
            title="통합 검색"
            description="검색한 원료가 제품의 주성분인지 부원료인지 구분해서 결과를 확인합니다."
            href="/search"
          />
        </div>
      </section>

      <section className="border-y border-stone-200 bg-surface px-4 py-14">
        <div className="mx-auto max-w-6xl">
          <div className="grid gap-8 lg:grid-cols-[minmax(0,0.9fr)_minmax(0,1.1fr)] lg:items-start">
            <div>
              <SectionHeader
                icon={<ShieldCheck className="h-5 w-5" />}
                title="데이터 출처와 검토 원칙"
                description="Why Trust — 규제 기준과 학술 근거를 분리해서 검증합니다"
              />
              <p className="mt-4 text-base leading-7 text-ink-muted">
                식품안전나라, 공공데이터포털, PubMed, NIH DSLD, DailyMed 등 공신력 있는
                출처를 기반으로 수집하고, 원료 기능성 해석과 제품 라벨 표기를 분리해서
                보여줍니다.
              </p>
              <Link
                href="/disclaimer"
                className="mt-5 inline-flex items-center gap-2 text-sm font-semibold text-orange-700 hover:text-orange-800"
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
  tag,
  title,
  description,
  href,
}: {
  icon: ReactNode;
  tag: string;
  title: string;
  description: string;
  href: string;
}) {
  return (
    <Link href={href} className="group block h-full">
      <Card className="h-full transition-all hover:-translate-y-0.5 hover:border-brand hover:shadow-card-hover">
        <div className="mb-5 flex items-center justify-between">
          {icon}
          <Badge variant="tag">{tag}</Badge>
        </div>
        <h3 className="text-xl font-bold text-ink group-hover:text-orange-700">
          {title}
        </h3>
        <p className="mt-3 text-sm leading-6 text-ink-muted">{description}</p>
        <div className="mt-6 inline-flex items-center gap-2 text-sm font-semibold text-orange-700">
          바로 보기
          <ArrowRight className="h-4 w-4" />
        </div>
      </Card>
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
    <Card padding="sm">
      <h3 className="text-base font-bold text-ink">{title}</h3>
      <p className="mt-2 text-sm leading-6 text-ink-muted">{body}</p>
    </Card>
  );
}
