import type { ReactNode } from "react";
import { cn } from "@/lib/utils";

function escapeRegExp(input: string): string {
  return input.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

export interface HighlightMatchProps {
  text: string | null | undefined;
  query: string | null | undefined;
  className?: string;
  fallback?: ReactNode;
}

/**
 * Wraps case-insensitive matches of `query` inside `text` with a <mark>.
 * Falls back to raw text when query is empty.
 */
export function HighlightMatch({
  text,
  query,
  className,
  fallback,
}: HighlightMatchProps) {
  if (!text) return <>{fallback ?? null}</>;
  const trimmed = (query ?? "").trim();
  if (!trimmed) return <>{text}</>;

  const pattern = new RegExp(`(${escapeRegExp(trimmed)})`, "gi");
  const lowerQuery = trimmed.toLowerCase();
  const parts = text.split(pattern);

  return (
    <>
      {parts.map((part, index) =>
        part.toLowerCase() === lowerQuery ? (
          <mark
            key={index}
            className={cn(
              "rounded bg-amber-100 px-0.5 text-amber-900",
              className,
            )}
          >
            {part}
          </mark>
        ) : (
          <span key={index}>{part}</span>
        ),
      )}
    </>
  );
}
