// Supabase 자동 생성 타입 placeholder
// 실제 운영 시 `supabase gen types typescript` 명령으로 생성
// 현재는 수동 타입 정의 사용

export type Database = {
  public: {
    Tables: {
      ingredients: {
        Row: Ingredient;
        Insert: Omit<Ingredient, "id" | "createdAt" | "updatedAt">;
        Update: Partial<Omit<Ingredient, "id">>;
      };
      products: {
        Row: Product;
        Insert: Omit<Product, "id" | "createdAt" | "updatedAt">;
        Update: Partial<Omit<Product, "id">>;
      };
      product_ingredients: {
        Row: ProductIngredient;
        Insert: Omit<ProductIngredient, "id" | "createdAt" | "updatedAt">;
        Update: Partial<Omit<ProductIngredient, "id">>;
      };
      label_snapshots: {
        Row: LabelSnapshot;
        Insert: Omit<LabelSnapshot, "id" | "createdAt" | "updatedAt">;
        Update: Partial<Omit<LabelSnapshot, "id">>;
      };
      claims: {
        Row: Claim;
        Insert: Omit<Claim, "id" | "createdAt" | "updatedAt">;
        Update: Partial<Omit<Claim, "id">>;
      };
      ingredient_claims: {
        Row: IngredientClaim;
        Insert: Omit<IngredientClaim, "id" | "createdAt" | "updatedAt">;
        Update: Partial<Omit<IngredientClaim, "id">>;
      };
      safety_items: {
        Row: SafetyItem;
        Insert: Omit<SafetyItem, "id" | "createdAt" | "updatedAt">;
        Update: Partial<Omit<SafetyItem, "id">>;
      };
      ingredient_drug_interactions: {
        Row: DrugInteraction;
        Insert: Omit<DrugInteraction, "id" | "createdAt" | "updatedAt">;
        Update: Partial<Omit<DrugInteraction, "id">>;
      };
      dosage_guidelines: {
        Row: DosageGuideline;
        Insert: Omit<DosageGuideline, "id" | "createdAt" | "updatedAt">;
        Update: Partial<Omit<DosageGuideline, "id">>;
      };
      regulatory_statuses: {
        Row: RegulatoryStatus;
        Insert: Omit<RegulatoryStatus, "id" | "createdAt" | "updatedAt">;
        Update: Partial<Omit<RegulatoryStatus, "id">>;
      };
    };
    Views: Record<string, never>;
    Functions: Record<string, never>;
    Enums: Record<string, never>;
  };
};

export interface Ingredient {
  id: number;
  canonical_name_ko: string;
  canonical_name_en: string | null;
  display_name: string | null;
  scientific_name: string | null;
  slug: string | null;
  ingredient_type: string;
  parent_ingredient_id: number | null;
  description: string | null;
  origin_type: string | null;
  form_description: string | null;
  standardization_info: string | null;
  is_active: boolean;
  is_published: boolean;
  last_reviewed_at: string | null;
  last_synced_at: string | null;
  created_at: string;
  updated_at: string;
}

export interface Product {
  id: number;
  product_name: string;
  brand_name: string | null;
  manufacturer_name: string | null;
  distributor_name: string | null;
  country_code: string | null;
  product_type: string | null;
  approval_or_report_no: string | null;
  status: string | null;
  barcode: string | null;
  product_image_url: string | null;
  marketplace_category: string | null;
  official_url: string | null;
  is_published: boolean;
  created_at: string;
  updated_at: string;
}

export interface ProductIngredient {
  id: number;
  product_id: number;
  ingredient_id: number;
  amount_per_serving: string | null;
  amount_unit: string | null;
  daily_amount: string | null;
  daily_amount_unit: string | null;
  ingredient_role: string | null;
  raw_label_name: string | null;
  is_standardized: boolean | null;
  standardization_text: string | null;
  created_at: string;
  updated_at: string;
}

export interface LabelSnapshot {
  id: number;
  product_id: number;
  label_version: string | null;
  source_name: string | null;
  source_url: string | null;
  serving_size_text: string | null;
  servings_per_container: string | null;
  warning_text: string | null;
  storage_text: string | null;
  directions_text: string | null;
  raw_label_text: string | null;
  captured_at: string | null;
  effective_date: string | null;
  is_current: boolean;
  created_at: string;
  updated_at: string;
}

export interface Claim {
  id: number;
  claim_code: string | null;
  claim_name_ko: string;
  claim_name_en: string | null;
  claim_category: string;
  claim_scope: string;
  description: string | null;
  created_at: string;
  updated_at: string;
}

export interface IngredientClaim {
  id: number;
  ingredient_id: number;
  claim_id: number;
  evidence_grade: string | null;
  evidence_summary: string | null;
  is_regulator_approved: boolean;
  approval_country_code: string | null;
  allowed_expression: string | null;
  prohibited_expression: string | null;
  source_priority: number | null;
  created_at: string;
  updated_at: string;
}

export interface SafetyItem {
  id: number;
  ingredient_id: number;
  safety_type: string;
  title: string;
  description: string;
  severity_level: string | null;
  evidence_level: string | null;
  frequency_text: string | null;
  applies_to_population: string | null;
  management_advice: string | null;
  created_at: string;
  updated_at: string;
}

export interface DrugInteraction {
  id: number;
  ingredient_id: number;
  drug_name: string;
  drug_class: string | null;
  interaction_mechanism: string | null;
  clinical_effect: string | null;
  severity_level: string | null;
  recommendation: string | null;
  evidence_level: string | null;
  source_id: number | null;
  created_at: string;
  updated_at: string;
}

export interface DosageGuideline {
  id: number;
  ingredient_id: number;
  population_group: string;
  indication_context: string | null;
  dose_min: string | null;
  dose_max: string | null;
  dose_unit: string | null;
  frequency_text: string | null;
  route: string | null;
  recommendation_type: string | null;
  notes: string | null;
  source_id: number | null;
  created_at: string;
  updated_at: string;
}

export interface RegulatoryStatus {
  id: number;
  ingredient_id: number;
  country_code: string;
  regulatory_category: string;
  status: string;
  authority_name: string | null;
  reference_number: string | null;
  reference_url: string | null;
  notes: string | null;
  effective_date: string | null;
  expiry_date: string | null;
  created_at: string;
  updated_at: string;
}

export interface EvidenceStudy {
  id: number;
  ingredient_id: number;
  source_type: string;
  title: string;
  abstract_text: string | null;
  authors: string | null;
  journal_name: string | null;
  publication_year: number | null;
  pmid: string | null;
  doi: string | null;
  external_url: string | null;
  study_design: string | null;
  population_text: string | null;
  sample_size: number | null;
  duration_text: string | null;
  screening_status: string | null;
  included_in_summary: boolean;
  created_at: string;
  updated_at: string;
}

export interface EvidenceOutcome {
  id: number;
  evidence_study_id: number;
  claim_id: number | null;
  outcome_name: string;
  outcome_type: string | null;
  effect_direction: string | null;
  effect_size_text: string | null;
  p_value_text: string | null;
  confidence_interval_text: string | null;
  conclusion_summary: string | null;
  adverse_event_summary: string | null;
  created_at: string;
  updated_at: string;
}
