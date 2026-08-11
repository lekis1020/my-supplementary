import { describe, expect, it } from "vitest";
import { dedupeSourceLinks, getClaimMeta, getStudyPriority } from "@/lib/data/ingredient-detail";

describe("getStudyPriority", () => {
  // Implementation (ingredient-detail.ts): meta_analysis=5, systematic_review=4,
  // guideline=4, rct=3, cohort=2, case_control=1, default (incl. null/unknown)=0.
  // Callers sort with `getStudyPriority(right) - getStudyPriority(left)`, i.e.
  // descending by this number, so a HIGHER value means HIGHER priority — the
  // opposite of the brief's illustrative draft.
  it("ranks meta_analysis highest and unknown/null lowest", () => {
    expect(getStudyPriority("meta_analysis")).toBeGreaterThan(getStudyPriority("rct"));
    expect(getStudyPriority(null)).toBeLessThan(getStudyPriority("rct"));
  });

  it("assigns exact scores for every known study design", () => {
    expect(getStudyPriority("meta_analysis")).toBe(5);
    expect(getStudyPriority("systematic_review")).toBe(4);
    expect(getStudyPriority("guideline")).toBe(4);
    expect(getStudyPriority("rct")).toBe(3);
    expect(getStudyPriority("cohort")).toBe(2);
    expect(getStudyPriority("case_control")).toBe(1);
  });

  it("falls back to 0 for null and unrecognized designs", () => {
    expect(getStudyPriority(null)).toBe(0);
    expect(getStudyPriority("meta-analysis")).toBe(0); // hyphenated form is not a recognized case
    expect(getStudyPriority("unknown_design")).toBe(0);
  });
});

describe("getClaimMeta", () => {
  // getClaimMeta<T>(input): Array.isArray(input) ? input[0] ?? null : input ?? null
  it("unwraps array to first element and passes object through", () => {
    expect(getClaimMeta([{ a: 1 }, { a: 2 }])).toEqual({ a: 1 });
    expect(getClaimMeta({ a: 1 })).toEqual({ a: 1 });
    expect(getClaimMeta(null)).toBeNull();
  });

  it("returns null for an empty array and for undefined", () => {
    expect(getClaimMeta([])).toBeNull();
    expect(getClaimMeta(undefined)).toBeNull();
  });
});

describe("dedupeSourceLinks", () => {
  // Dedupe key is NOT the url: it's
  // `[entity_type, entity_id, sources?.source_name ?? "", source_reference ?? ""].join("|")`
  // (see dedupeSourceLinks in ingredient-detail.ts). First occurrence per key is kept.
  type Row = {
    entity_type: string;
    entity_id: number;
    source_reference: string | null;
    sources?: { source_name: string } | Array<{ source_name: string }> | null;
    label?: string;
  };

  it("dedupes by (entity_type, entity_id, source_name, source_reference), keeping the first occurrence", () => {
    const rows: Row[] = [
      {
        entity_type: "ingredient",
        entity_id: 1,
        source_reference: "ref-1",
        sources: { source_name: "MFDS" },
        label: "first",
      },
      {
        entity_type: "ingredient",
        entity_id: 1,
        source_reference: "ref-1",
        sources: { source_name: "MFDS" },
        label: "duplicate",
      },
      {
        entity_type: "ingredient",
        entity_id: 2,
        source_reference: "ref-1",
        sources: { source_name: "MFDS" },
        label: "different-entity-id",
      },
    ];

    const result = dedupeSourceLinks(rows);

    expect(result).toHaveLength(2);
    expect(result.map((r) => r.label)).toEqual(["first", "different-entity-id"]);
  });

  it("treats different source_name or source_reference as distinct keys even for the same entity", () => {
    const rows: Row[] = [
      {
        entity_type: "claim",
        entity_id: 5,
        source_reference: "ref-a",
        sources: { source_name: "MFDS" },
      },
      {
        entity_type: "claim",
        entity_id: 5,
        source_reference: "ref-a",
        sources: { source_name: "NIH" }, // different source_name -> different key
      },
      {
        entity_type: "claim",
        entity_id: 5,
        source_reference: "ref-b", // different source_reference -> different key
        sources: { source_name: "MFDS" },
      },
    ];

    expect(dedupeSourceLinks(rows)).toHaveLength(3);
  });

  it("unwraps a `sources` array (via getClaimMeta) using its first element's source_name for the key", () => {
    const rows: Row[] = [
      {
        entity_type: "evidence_study",
        entity_id: 9,
        source_reference: null,
        sources: [{ source_name: "PubMed" }, { source_name: "OtherSource" }],
      },
      {
        entity_type: "evidence_study",
        entity_id: 9,
        source_reference: null,
        sources: { source_name: "PubMed" }, // same effective key as first element above
      },
    ];

    expect(dedupeSourceLinks(rows)).toHaveLength(1);
  });

  it("treats missing sources/source_reference as empty-string key segments", () => {
    const rows: Row[] = [
      { entity_type: "ingredient", entity_id: 3, source_reference: null, sources: null },
      { entity_type: "ingredient", entity_id: 3, source_reference: null, sources: null },
    ];

    expect(dedupeSourceLinks(rows)).toHaveLength(1);
  });
});
