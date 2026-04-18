"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { cn } from "@/lib/utils";
import { Search, Menu, X, GitCompare } from "lucide-react";
import { useEffect, useState } from "react";
import {
  COMPARE_STORAGE_KEY,
  COMPARE_MAX_PRODUCTS,
  parseCompareIds,
} from "@/lib/compare";

const navItems = [
  { href: "/ingredients", label: "원료 사전" },
  { href: "/products", label: "제품 데이터베이스" },
];

function useCompareCount() {
  const [count, setCount] = useState(0);

  useEffect(() => {
    if (typeof window === "undefined") return;

    const read = () => {
      try {
        const raw = window.localStorage.getItem(COMPARE_STORAGE_KEY);
        setCount(parseCompareIds(raw).length);
      } catch {
        setCount(0);
      }
    };

    read();
    const onStorage = (event: StorageEvent) => {
      if (event.key === COMPARE_STORAGE_KEY) read();
    };
    const onFocus = () => read();

    window.addEventListener("storage", onStorage);
    window.addEventListener("focus", onFocus);
    return () => {
      window.removeEventListener("storage", onStorage);
      window.removeEventListener("focus", onFocus);
    };
  }, []);

  return count;
}

export function Header() {
  const pathname = usePathname();
  const [menuOpen, setMenuOpen] = useState(false);
  const compareCount = useCompareCount();
  const showCompareBadge = compareCount > 0;

  return (
    <header className="sticky top-0 z-50 border-b border-gray-200 bg-white/80 backdrop-blur-sm">
      <div className="mx-auto flex h-16 max-w-6xl items-center justify-between px-4">
        <Link href="/" className="flex items-center gap-2 font-bold text-lg">
          <span className="text-green-600">NutriCompare</span>
        </Link>

        {/* Desktop Nav */}
        <nav className="hidden items-center gap-6 md:flex">
          {navItems.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              className={cn(
                "text-sm font-medium transition-colors hover:text-green-600",
                pathname.startsWith(item.href)
                  ? "text-green-600"
                  : "text-gray-600"
              )}
            >
              {item.label}
            </Link>
          ))}
          <Link
            href="/compare"
            aria-label={
              showCompareBadge
                ? `비교 도구 (${compareCount}/${COMPARE_MAX_PRODUCTS})`
                : "비교 도구"
            }
            className={cn(
              "relative inline-flex items-center gap-1.5 rounded-full px-3 py-1.5 text-sm font-medium transition-colors",
              pathname.startsWith("/compare")
                ? "bg-emerald-50 text-emerald-700"
                : "text-gray-600 hover:bg-gray-100"
            )}
          >
            <GitCompare className="h-4 w-4" />
            <span>비교</span>
            {showCompareBadge && (
              <span
                aria-hidden
                className="ml-0.5 inline-flex h-5 min-w-5 items-center justify-center rounded-full bg-emerald-600 px-1.5 text-[11px] font-bold text-white"
              >
                {compareCount}
              </span>
            )}
          </Link>
          <Link
            href="/search"
            aria-label="검색"
            className="rounded-full bg-gray-100 p-2 text-gray-500 transition-colors hover:bg-gray-200"
          >
            <Search className="h-4 w-4" />
          </Link>
        </nav>

        {/* Mobile Menu Toggle */}
        <button
          className="md:hidden"
          onClick={() => setMenuOpen(!menuOpen)}
          aria-label={menuOpen ? "메뉴 닫기" : "메뉴 열기"}
          aria-expanded={menuOpen}
          aria-controls="mobile-nav"
        >
          {menuOpen ? <X className="h-6 w-6" /> : <Menu className="h-6 w-6" />}
        </button>
      </div>

      {/* Mobile Nav */}
      {menuOpen && (
        <nav
          id="mobile-nav"
          className="border-t border-gray-200 bg-white px-4 pb-4 md:hidden"
        >
          <form
            action="/search"
            method="get"
            onSubmit={() => setMenuOpen(false)}
            className="pt-3"
          >
            <label htmlFor="mobile-search" className="sr-only">
              검색
            </label>
            <div className="relative">
              <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
              <input
                id="mobile-search"
                type="search"
                name="q"
                placeholder="원료·제품명을 검색하세요"
                className="w-full rounded-xl border border-gray-200 bg-white py-2.5 pl-9 pr-3 text-sm text-gray-900 placeholder:text-gray-400 focus:border-emerald-400 focus:outline-none focus:ring-2 focus:ring-emerald-100"
              />
            </div>
          </form>

          {navItems.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              onClick={() => setMenuOpen(false)}
              className={cn(
                "block py-3 text-sm font-medium",
                pathname.startsWith(item.href)
                  ? "text-green-600"
                  : "text-gray-600"
              )}
            >
              {item.label}
            </Link>
          ))}
          <Link
            href="/compare"
            onClick={() => setMenuOpen(false)}
            className={cn(
              "flex items-center justify-between py-3 text-sm font-medium",
              pathname.startsWith("/compare") ? "text-green-600" : "text-gray-600"
            )}
          >
            <span className="inline-flex items-center gap-2">
              <GitCompare className="h-4 w-4" />
              비교 도구
            </span>
            {showCompareBadge && (
              <span className="inline-flex h-5 min-w-5 items-center justify-center rounded-full bg-emerald-600 px-1.5 text-[11px] font-bold text-white">
                {compareCount}
              </span>
            )}
          </Link>
        </nav>
      )}
    </header>
  );
}
