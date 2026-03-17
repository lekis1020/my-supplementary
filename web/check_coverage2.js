const { createClient } = require("@supabase/supabase-js");
const sb = createClient(
  "https://loqhpykkovwczdckekju.supabase.co",
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxvcWhweWtrb3Z3Y3pkY2tla2p1Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MzMzNTgzMCwiZXhwIjoyMDg4OTExODMwfQ.xi8lX2pGrbXKoVTwrNOXQVjMmLtM94M5Xc3ZxlahJ7w"
);

(async () => {
  // All active ingredients with slugs
  const { data: allIngs } = await sb.from("ingredients")
    .select("id, slug, canonical_name_ko, ingredient_type")
    .eq("is_active", true)
    .not("slug", "is", null)
    .is("parent_ingredient_id", null);

  // All evidence studies
  const { data: studies } = await sb.from("evidence_studies")
    .select("id, ingredient_id")
    .eq("included_in_summary", true);

  const ingWithStudies = new Set((studies || []).map(s => s.ingredient_id));

  // Ingredients WITH evidence
  const withEvidence = (allIngs || []).filter(i => ingWithStudies.has(i.id));
  // Ingredients WITHOUT evidence
  const noEvidence = (allIngs || []).filter(i => !ingWithStudies.has(i.id));

  console.log("=== HAS EVIDENCE (" + withEvidence.length + ") ===");
  withEvidence.forEach(i => console.log("  V " + i.canonical_name_ko + " (" + i.slug + ")"));

  console.log("\n=== NO EVIDENCE (" + noEvidence.length + ") ===");
  noEvidence.forEach(i => console.log("  X " + i.canonical_name_ko + " (" + i.slug + ") [" + i.ingredient_type + "]"));
})();
