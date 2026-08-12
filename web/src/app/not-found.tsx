import Link from "next/link";

export default function NotFound() {
  return (
    <div className="flex flex-col items-center justify-center px-4 py-32 text-center">
      <h1 className="text-6xl font-bold text-stone-200">404</h1>
      <p className="mt-4 text-lg text-ink-muted">페이지를 찾을 수 없습니다.</p>
      <Link
        href="/"
        className="mt-6 rounded-lg bg-orange-700 px-6 py-2 text-sm font-medium text-white transition-colors hover:bg-orange-800"
      >
        홈으로 돌아가기
      </Link>
    </div>
  );
}
