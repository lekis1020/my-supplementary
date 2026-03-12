// ============================================================================
// Drizzle ORM Schema — 영양제·건강기능식품 비교 분석 플랫폼
// Version: 1.0.0
//
// DDL 001_schema.sql과 1:1 대응
// 사용 패턴:
//   소비자 (anon/authenticated) → Supabase Client → RLS 자동 적용
//   Admin/수집 파이프라인 → Drizzle (service_role key) → RLS 우회
// ============================================================================

// 0. 코드 테이블
export {
  codeTables,
  codeValues,
  codeTablesRelations,
  codeValuesRelations,
} from "./code-tables";

// 1-2, 5-8. 원료 및 관련 엔티티
export {
  ingredients,
  ingredientSynonyms,
  regulatoryStatuses,
  safetyItems,
  ingredientDrugInteractions,
  dosageGuidelines,
  ingredientsRelations,
  ingredientSynonymsRelations,
  regulatoryStatusesRelations,
  safetyItemsRelations,
  ingredientDrugInteractionsRelations,
  dosageGuidelinesRelations,
} from "./ingredients";

// 3-4. 기능성/효능
export {
  claims,
  ingredientClaims,
  claimsRelations,
  ingredientClaimsRelations,
} from "./claims";

// 9-11. 제품/라벨
export {
  products,
  productIngredients,
  labelSnapshots,
  productsRelations,
  productIngredientsRelations,
  labelSnapshotsRelations,
} from "./products";

// 12-14. 근거문헌
export {
  evidenceStudies,
  evidenceOutcomes,
  evidenceGradeHistory,
  evidenceStudiesRelations,
  evidenceOutcomesRelations,
  evidenceGradeHistoryRelations,
} from "./evidence";

// 15-16. 출처관리
export {
  sources,
  sourceLinks,
  sourcesRelations,
  sourceLinksRelations,
} from "./sources";

// 17-19. 운영/검수/검색
export {
  reviewTasks,
  revisionHistories,
  ingredientSearchDocuments,
  reviewTasksRelations,
} from "./operations";

// 22-28. 수집/갱신 계층
export {
  sourceConnectors,
  collectionJobs,
  collectionRuns,
  rawDocuments,
  extractionResults,
  refreshPolicies,
  entityRefreshStates,
  sourceConnectorsRelations,
  collectionJobsRelations,
  collectionRunsRelations,
  rawDocumentsRelations,
  extractionResultsRelations,
  refreshPoliciesRelations,
  entityRefreshStatesRelations,
} from "./collection";
