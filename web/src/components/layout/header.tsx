"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { cn } from "@/lib/utils";
import { Search, Menu, X, GitCompare } from "lucide-react";
import { useState } from "react";
import { COMPARE_MAX_PRODUCTS } from "@/lib/compare";
import { useCompareStorage } from "@/lib/compare/use-compare-storage";

const navItems = [
  { href: "/ingredients", label: "원료 사전" },
  { href: "/products", label: "제품 데이터베이스" },
];

export function Header() {
  const pathname = usePathname();
  const [menuOpen, setMenuOpen] = useState(false);
  const { ids: compareIds } = useCompareStorage();
  const compareCount = compareIds.length;
  const showCompareBadge = compareCount > 0;

  return (
    <header className="sticky top-0 z-50 border-b border-stone-200 bg-white/80 backdrop-blur-sm">
      <div className="mx-auto flex h-16 max-w-6xl items-center justify-between px-4">
        <Link href="/" className="flex items-center gap-2 font-bold text-lg">
          <span className="text-orange-700">NutriCompare</span>
        </Link>

        {/* Desktop Nav */}
        <nav className="hidden items-center gap-6 md:flex">
          {navItems.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              className={cn(
                "text-sm font-medium transition-colors hover:text-orange-700",
                pathname.startsWith(item.href)
                  ? "text-orange-700"
                  : "text-ink-muted"
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
                ? "bg-brand-bg text-orange-700"
                : "text-ink-muted hover:bg-stone-100"
            )}
          >
            <GitCompare className="h-4 w-4" />
            <span>비교</span>
            {showCompareBadge && (
              <span
                aria-hidden
                className="ml-0.5 inline-flex h-5 min-w-5 items-center justify-center rounded-full bg-orange-700 px-1.5 text-[11px] font-bold text-white"
              >
                {compareCount}
              </span>
            )}
          </Link>
          <Link
            href="/search"
            aria-label="검색"
            className="rounded-full bg-stone-100 p-2 text-ink-muted transition-colors hover:bg-stone-200"
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
          className="border-t border-stone-200 bg-white px-4 pb-4 md:hidden"
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
              <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-ink-faint" />
              <input
                id="mobile-search"
                type="search"
                name="q"
                placeholder="원료·제품명을 검색하세요"
                className="w-full rounded-xl border border-stone-200 bg-white py-2.5 pl-9 pr-3 text-sm text-ink placeholder:text-ink-faint focus:border-brand focus:outline-none focus:ring-2 focus:ring-brand"
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
                  ? "text-orange-700"
                  : "text-ink-muted"
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
              pathname.startsWith("/compare") ? "text-orange-700" : "text-ink-muted"
            )}
          >
            <span className="inline-flex items-center gap-2">
              <GitCompare className="h-4 w-4" />
              비교 도구
            </span>
            {showCompareBadge && (
              <span className="inline-flex h-5 min-w-5 items-center justify-center rounded-full bg-orange-700 px-1.5 text-[11px] font-bold text-white">
                {compareCount}
              </span>
            )}
          </Link>
        </nav>
      )}
    </header>
  );
}
