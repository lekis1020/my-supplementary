"use client";

import { CTAButton } from "@/components/ui/cta-button";

export default function GlobalError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <div className="mx-auto flex max-w-xl flex-col items-center gap-4 px-4 py-24 text-center">
      <h2 className="text-xl font-bold text-ink">일시적인 오류가 발생했습니다</h2>
      <p className="text-sm text-ink-muted">
        데이터를 불러오는 중 문제가 생겼습니다. 잠시 후 다시 시도해 주세요.
      </p>
      {error.digest && (
        <p className="text-xs text-ink-faint">오류 코드: {error.digest}</p>
      )}
      <CTAButton onClick={reset}>다시 시도</CTAButton>
    </div>
  );
}
