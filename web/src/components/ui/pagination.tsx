import Link from "next/link";
import type { ReactNode } from "react";
import { cn } from "@/lib/utils";

export interface PaginationLinkProps {
  href: string;
  children: ReactNode;
  active?: boolean;
  disabled?: boolean;
  ariaLabel?: string;
}

export function PaginationLink({
  href,
  children,
  active = false,
  disabled = false,
  ariaLabel,
}: PaginationLinkProps) {
  return (
    <Link
      href={href}
      aria-disabled={disabled}
      aria-current={active ? "page" : undefined}
      aria-label={ariaLabel}
      tabIndex={disabled ? -1 : undefined}
      className={cn(
        "inline-flex min-w-10 items-center justify-center rounded-xl border px-3 py-2 text-sm font-semibold transition-colors",
        "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-emerald-500 focus-visible:ring-offset-2",
        active
          ? "border-emerald-600 bg-emerald-600 text-white"
          : "border-slate-200 bg-white text-slate-600 hover:border-emerald-200 hover:text-emerald-700",
        disabled && "pointer-events-none opacity-40",
      )}
    >
      {children}
    </Link>
  );
}

export interface PaginationProps {
  currentPage: number;
  totalPages: number;
  buildHref: (page: number) => string;
  pageLinks: number[];
  previousLabel?: ReactNode;
  nextLabel?: ReactNode;
  className?: string;
}

export function Pagination({
  currentPage,
  totalPages,
  buildHref,
  pageLinks,
  previousLabel = "이전",
  nextLabel = "다음",
  className,
}: PaginationProps) {
  if (totalPages <= 1) return null;

  return (
    <nav
      aria-label="페이지네이션"
      className={cn("flex flex-wrap items-center justify-center gap-2", className)}
    >
      <PaginationLink
        href={buildHref(Math.max(1, currentPage - 1))}
        disabled={currentPage <= 1}
        ariaLabel="이전 페이지"
      >
        {previousLabel}
      </PaginationLink>
      {pageLinks.map((page) => (
        <PaginationLink
          key={page}
          href={buildHref(page)}
          active={page === currentPage}
          ariaLabel={`${page}페이지`}
        >
          {page}
        </PaginationLink>
      ))}
      <PaginationLink
        href={buildHref(Math.min(totalPages, currentPage + 1))}
        disabled={currentPage >= totalPages}
        ariaLabel="다음 페이지"
      >
        {nextLabel}
      </PaginationLink>
    </nav>
  );
}
