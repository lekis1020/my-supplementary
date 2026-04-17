"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import {
  useCallback,
  useEffect,
  useId,
  useMemo,
  useRef,
  useState,
  type KeyboardEvent,
} from "react";
import { Search } from "lucide-react";
import { createClient } from "@/lib/supabase/client";
import {
  cn,
  formatProductName,
  getIngredientHref,
  normalizeIngredientNameForDisplay,
} from "@/lib/utils";
import { HighlightMatch } from "@/components/ui/highlight";

const SUGGESTION_LIMIT = 6;
const DEBOUNCE_MS = 250;

type SuggestionKind = "ingredient" | "product";

interface Suggestion {
  kind: SuggestionKind;
  key: string;
  href: string;
  title: string;
  subtitle: string | null;
}

interface Props {
  initialQuery?: string;
  placeholder?: string;
  className?: string;
  inputClassName?: string;
  inputId?: string;
  inputName?: string;
}

function buildSearchHref(q: string): string {
  const params = new URLSearchParams();
  if (q) params.set("q", q);
  const qs = params.toString();
  return qs ? `/search?${qs}` : "/search";
}

export function SearchCombobox({
  initialQuery = "",
  placeholder = "원료명, 제품명, 영문명으로 검색",
  className,
  inputClassName,
  inputId = "search-query",
  inputName = "q",
}: Props) {
  const router = useRouter();
  const listboxId = useId();
  const inputRef = useRef<HTMLInputElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);

  const [value, setValue] = useState(initialQuery);
  const [suggestions, setSuggestions] = useState<Suggestion[]>([]);
  const [open, setOpen] = useState(false);
  const [loading, setLoading] = useState(false);
  const [activeIndex, setActiveIndex] = useState(-1);

  const supabase = useMemo(() => {
    try {
      return createClient();
    } catch {
      return null;
    }
  }, []);

  const trimmed = value.trim();

  useEffect(() => {
    if (!supabase) return;

    let cancelled = false;

    if (trimmed.length < 2) {
      const clearTimer = window.setTimeout(() => {
        if (cancelled) return;
        setSuggestions((prev) => (prev.length === 0 ? prev : []));
        setLoading((prev) => (prev ? false : prev));
      }, 0);
      return () => {
        cancelled = true;
        window.clearTimeout(clearTimer);
      };
    }

    const loadingTimer = window.setTimeout(() => {
      if (!cancelled) setLoading(true);
    }, 0);

    const timer = window.setTimeout(async () => {
      const pattern = `%${trimmed.replace(/[%_]/g, "\\$&")}%`;

      const [ingredientRes, productRes] = await Promise.all([
        supabase
          .from("ingredients")
          .select("id, canonical_name_ko, canonical_name_en, slug")
          .or(
            [
              `canonical_name_ko.ilike.${pattern}`,
              `canonical_name_en.ilike.${pattern}`,
              `display_name.ilike.${pattern}`,
            ].join(","),
          )
          .order("canonical_name_ko")
          .limit(SUGGESTION_LIMIT),
        supabase
          .from("products")
          .select("id, product_name, brand_name")
          .or(
            [
              `product_name.ilike.${pattern}`,
              `brand_name.ilike.${pattern}`,
            ].join(","),
          )
          .order("product_name")
          .limit(SUGGESTION_LIMIT),
      ]);

      if (cancelled) return;

      const ingredientItems: Suggestion[] = (ingredientRes.data ?? []).map(
        (row) => ({
          kind: "ingredient" as const,
          key: `ing-${row.id}`,
          href: getIngredientHref({ id: row.id, slug: row.slug }),
          title: normalizeIngredientNameForDisplay(
            row.canonical_name_ko ?? "",
          ),
          subtitle: row.canonical_name_en ?? null,
        }),
      );

      const productItems: Suggestion[] = (productRes.data ?? []).map((row) => ({
        kind: "product" as const,
        key: `prd-${row.id}`,
        href: `/products/${row.id}`,
        title: formatProductName(row.product_name),
        subtitle: row.brand_name ?? null,
      }));

      setSuggestions([...ingredientItems, ...productItems]);
      setActiveIndex(-1);
      setLoading(false);
    }, DEBOUNCE_MS);

    return () => {
      cancelled = true;
      window.clearTimeout(loadingTimer);
      window.clearTimeout(timer);
    };
  }, [supabase, trimmed]);

  useEffect(() => {
    function onDocClick(event: MouseEvent) {
      if (!containerRef.current) return;
      if (!containerRef.current.contains(event.target as Node)) {
        setOpen(false);
      }
    }
    document.addEventListener("mousedown", onDocClick);
    return () => document.removeEventListener("mousedown", onDocClick);
  }, []);

  const showPanel = open && trimmed.length >= 2;

  const go = useCallback(
    (suggestion: Suggestion | null) => {
      setOpen(false);
      if (suggestion) {
        router.push(suggestion.href);
      } else {
        router.push(buildSearchHref(trimmed));
      }
    },
    [router, trimmed],
  );

  const onKeyDown = (event: KeyboardEvent<HTMLInputElement>) => {
    if (!showPanel || suggestions.length === 0) {
      if (event.key === "Escape") setOpen(false);
      return;
    }

    if (event.key === "ArrowDown") {
      event.preventDefault();
      setActiveIndex((prev) => (prev + 1) % suggestions.length);
    } else if (event.key === "ArrowUp") {
      event.preventDefault();
      setActiveIndex((prev) =>
        prev <= 0 ? suggestions.length - 1 : prev - 1,
      );
    } else if (event.key === "Enter") {
      if (activeIndex >= 0 && activeIndex < suggestions.length) {
        event.preventDefault();
        go(suggestions[activeIndex]);
      }
    } else if (event.key === "Escape") {
      setOpen(false);
    }
  };

  const ingredientSuggestions = suggestions.filter(
    (s) => s.kind === "ingredient",
  );
  const productSuggestions = suggestions.filter((s) => s.kind === "product");

  return (
    <div ref={containerRef} className={cn("relative", className)}>
      <label htmlFor={inputId} className="relative block">
        <span className="sr-only">검색어</span>
        <Search className="pointer-events-none absolute left-4 top-1/2 h-5 w-5 -translate-y-1/2 text-slate-400" />
        <input
          ref={inputRef}
          id={inputId}
          name={inputName}
          type="search"
          autoComplete="off"
          role="combobox"
          aria-expanded={showPanel && suggestions.length > 0}
          aria-controls={listboxId}
          aria-autocomplete="list"
          aria-activedescendant={
            activeIndex >= 0 && suggestions[activeIndex]
              ? `${listboxId}-${suggestions[activeIndex].key}`
              : undefined
          }
          value={value}
          onChange={(e) => {
            setValue(e.target.value);
            setOpen(true);
          }}
          onFocus={() => setOpen(true)}
          onKeyDown={onKeyDown}
          placeholder={placeholder}
          className={cn(
            "w-full rounded-2xl border border-slate-300 bg-white py-3 pl-12 pr-4 text-slate-900 placeholder:text-slate-400 focus:border-emerald-500 focus:outline-none focus:ring-4 focus:ring-emerald-100",
            inputClassName,
          )}
        />
      </label>

      {showPanel && (
        <div
          id={listboxId}
          role="listbox"
          aria-label="검색 제안"
          className="absolute left-0 right-0 top-full z-20 mt-2 overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-xl"
        >
          {loading && suggestions.length === 0 && (
            <p className="px-4 py-3 text-sm text-slate-500">검색 중…</p>
          )}

          {!loading && suggestions.length === 0 && (
            <p className="px-4 py-3 text-sm text-slate-500">
              제안이 없습니다. Enter로 전체 검색을 실행하세요.
            </p>
          )}

          {ingredientSuggestions.length > 0 && (
            <SuggestionGroup
              label="원료"
              listboxId={listboxId}
              items={ingredientSuggestions}
              activeKey={
                activeIndex >= 0 ? suggestions[activeIndex]?.key : undefined
              }
              onHover={(key) =>
                setActiveIndex(suggestions.findIndex((s) => s.key === key))
              }
              onSelect={() => setOpen(false)}
              query={trimmed}
            />
          )}

          {productSuggestions.length > 0 && (
            <SuggestionGroup
              label="제품"
              listboxId={listboxId}
              items={productSuggestions}
              activeKey={
                activeIndex >= 0 ? suggestions[activeIndex]?.key : undefined
              }
              onHover={(key) =>
                setActiveIndex(suggestions.findIndex((s) => s.key === key))
              }
              onSelect={() => setOpen(false)}
              query={trimmed}
            />
          )}

          <Link
            href={buildSearchHref(trimmed)}
            onClick={() => setOpen(false)}
            className="flex items-center justify-between border-t border-slate-100 bg-slate-50 px-4 py-2.5 text-xs font-semibold text-emerald-700 hover:bg-emerald-50"
          >
            <span>&ldquo;{trimmed}&rdquo; 전체 검색 결과 보기</span>
            <span aria-hidden>→</span>
          </Link>
        </div>
      )}
    </div>
  );
}

function SuggestionGroup({
  label,
  items,
  listboxId,
  activeKey,
  onHover,
  onSelect,
  query,
}: {
  label: string;
  items: Suggestion[];
  listboxId: string;
  activeKey: string | undefined;
  onHover: (key: string) => void;
  onSelect: () => void;
  query: string;
}) {
  return (
    <div className="py-1">
      <p className="px-4 pt-2 pb-1 text-[11px] font-semibold uppercase tracking-[0.14em] text-slate-400">
        {label}
      </p>
      <ul>
        {items.map((item) => {
          const active = item.key === activeKey;
          return (
            <li key={item.key}>
              <Link
                id={`${listboxId}-${item.key}`}
                role="option"
                aria-selected={active}
                href={item.href}
                onMouseEnter={() => onHover(item.key)}
                onClick={onSelect}
                className={cn(
                  "flex items-center justify-between gap-3 px-4 py-2 text-sm",
                  active
                    ? "bg-emerald-50 text-emerald-900"
                    : "text-slate-700 hover:bg-slate-50",
                )}
              >
                <div className="min-w-0 flex-1">
                  <p className="truncate font-medium">
                    <HighlightMatch text={item.title} query={query} />
                  </p>
                  {item.subtitle && (
                    <p className="truncate text-xs text-slate-500">
                      <HighlightMatch text={item.subtitle} query={query} />
                    </p>
                  )}
                </div>
              </Link>
            </li>
          );
        })}
      </ul>
    </div>
  );
}
