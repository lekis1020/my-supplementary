"use client";

import { useEffect, useRef, useState } from "react";
import { Card } from "@/components/ui/card";
import { AlertTriangle, Sparkles } from "lucide-react";

interface CompareSummaryProps {
  productIds: number[];
}

interface SummaryResponse {
  summary: string;
  model: string;
  cached: boolean;
  stats: {
    productCount: number;
    commonIngredientCount: number;
    overlapIngredientCount: number;
    uniqueIngredientCount: number;
    duplicateIngredientCount: number;
  };
}

type Status = "idle" | "loading" | "success" | "error";

export function CompareSummary({ productIds }: CompareSummaryProps) {
  const [status, setStatus] = useState<Status>("idle");
  const [data, setData] = useState<SummaryResponse | null>(null);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const abortRef = useRef<AbortController | null>(null);

  const key = [...productIds].sort((a, b) => a - b).join("-");

  useEffect(() => {
    if (productIds.length < 2) {
      setStatus("idle");
      setData(null);
      setErrorMessage(null);
      return;
    }

    abortRef.current?.abort();
    const controller = new AbortController();
    abortRef.current = controller;

    setStatus("loading");
    setErrorMessage(null);

    fetch("/api/compare/summary", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ productIds }),
      signal: controller.signal,
    })
      .then(async (response) => {
        const payload = await response.json().catch(() => ({}));
        if (!response.ok) {
          const message = (payload as { error?: string })?.error || `요약 생성 실패 (${response.status})`;
          throw new Error(message);
        }
        return payload as SummaryResponse;
      })
      .then((payload) => {
        setData(payload);
        setStatus("success");
      })
      .catch((error: unknown) => {
        if ((error as { name?: string })?.name === "AbortError") return;
        setErrorMessage(error instanceof Error ? error.message : String(error));
        setStatus("error");
      });

    return () => {
      controller.abort();
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [key]);

  if (productIds.length < 2) return null;

  return (
    <Card className="mt-6 overflow-hidden border-emerald-100 bg-gradient-to-br from-emerald-50 via-white to-white p-6">
      <div className="flex items-start gap-3">
        <div className="mt-0.5 rounded-full bg-emerald-100 p-2 text-emerald-700">
          <Sparkles className="h-4 w-4" />
        </div>
        <div className="min-w-0 flex-1">
          <div className="flex flex-wrap items-center gap-2">
            <h2 className="text-lg font-bold tracking-tight text-slate-900">AI 비교 요약</h2>
            <span className="rounded-full border border-emerald-200 bg-white px-2 py-0.5 text-[11px] font-semibold uppercase tracking-wider text-emerald-700">
              Beta
            </span>
            {status === "success" && data?.cached && (
              <span className="text-[11px] text-slate-400">캐시됨</span>
            )}
          </div>
          <p className="mt-1 text-xs text-slate-500">
            선택한 제품의 공통·중복·고유 성분을 바탕으로 AI가 핵심을 요약합니다. 세부 비교는 아래에서 확인하세요.
          </p>

          <div className="mt-4">
            {status === "loading" && <SummarySkeleton />}

            {status === "error" && (
              <div className="flex items-start gap-2 rounded-xl border border-amber-200 bg-amber-50 p-4 text-sm text-amber-800">
                <AlertTriangle className="mt-0.5 h-4 w-4 shrink-0" />
                <div>
                  <p className="font-semibold">요약을 불러오지 못했습니다</p>
                  <p className="mt-1 text-xs text-amber-700">{errorMessage}</p>
                </div>
              </div>
            )}

            {status === "success" && data && (
              <>
                <SummaryText text={data.summary} />
                <p className="mt-3 text-[11px] text-slate-400">
                  {data.model} · AI가 생성한 요약으로, 의료 조언이 아닙니다. 복용 전 전문가와 상의하세요.
                </p>
              </>
            )}
          </div>
        </div>
      </div>
    </Card>
  );
}

function SummarySkeleton() {
  return (
    <div className="space-y-2" aria-label="요약 생성 중">
      <div className="h-3 w-4/5 animate-pulse rounded bg-slate-200" />
      <div className="h-3 w-full animate-pulse rounded bg-slate-200" />
      <div className="h-3 w-11/12 animate-pulse rounded bg-slate-200" />
      <div className="h-3 w-2/3 animate-pulse rounded bg-slate-200" />
      <div className="mt-3 h-3 w-3/4 animate-pulse rounded bg-slate-100" />
      <div className="h-3 w-1/2 animate-pulse rounded bg-slate-100" />
    </div>
  );
}

function SummaryText({ text }: { text: string }) {
  const paragraphs = text
    .split(/\n{2,}/)
    .map((block) => block.trim())
    .filter(Boolean);

  return (
    <div className="space-y-3 text-sm leading-7 text-slate-700">
      {paragraphs.map((block, index) => {
        const lines = block.split("\n").map((line) => line.trim()).filter(Boolean);
        const bulletCount = lines.filter((line) => /^[•\-\*·]/.test(line)).length;
        const isBulletBlock = bulletCount > 0 && bulletCount >= lines.length - 1;

        if (isBulletBlock) {
          return (
            <ul key={index} className="list-none space-y-1.5 pl-0">
              {lines.map((line, idx) => (
                <li key={idx} className="flex gap-2">
                  <span className="mt-2 h-1.5 w-1.5 shrink-0 rounded-full bg-emerald-500" />
                  <span>{line.replace(/^[•\-\*·]\s*/, "")}</span>
                </li>
              ))}
            </ul>
          );
        }

        return (
          <p key={index} className="whitespace-pre-line">
            {block}
          </p>
        );
      })}
    </div>
  );
}
