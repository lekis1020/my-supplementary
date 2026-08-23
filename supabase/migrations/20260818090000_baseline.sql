--
-- PostgreSQL database dump
--

\restrict dqsoHggu0tXL2gyfbUbVQakmvlpkzTdU3N4YsnJYLDvtRxAhiiBcwbckNXYXUdN

-- Dumped from database version 17.6
-- Dumped by pg_dump version 18.6

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA public;


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- Name: is_admin(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.is_admin() RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    RETURN (
        current_setting('request.jwt.claims', true)::jsonb
        -> 'app_metadata' ->> 'role'
    ) = 'admin';
EXCEPTION
    WHEN OTHERS THEN RETURN FALSE;
END;
$$;


--
-- Name: is_reviewer(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.is_reviewer() RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    user_role TEXT;
BEGIN
    user_role := (
        current_setting('request.jwt.claims', true)::jsonb
        -> 'app_metadata' ->> 'role'
    );
    RETURN user_role IN ('admin', 'scientific_reviewer', 'regulatory_reviewer', 'qa');
EXCEPTION
    WHEN OTHERS THEN RETURN FALSE;
END;
$$;


--
-- Name: rls_auto_enable(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.rls_auto_enable() RETURNS event_trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public') AND cmd.schema_name NOT IN ('pg_catalog','information_schema') AND cmd.schema_name NOT LIKE 'pg_toast%' AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        EXECUTE format('alter table if exists %s enable row level security', cmd.object_identity);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$$;


--
-- Name: set_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: claims; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.claims (
    id bigint NOT NULL,
    claim_code character varying(100),
    claim_name_ko character varying(255) NOT NULL,
    claim_name_en character varying(255),
    claim_category character varying(100) NOT NULL,
    claim_scope character varying(50) NOT NULL,
    description text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    claim_key character varying(150),
    canonical_claim_ko character varying(255),
    canonical_claim_en character varying(255),
    claim_subject_ko character varying(255),
    claim_subject_en character varying(255),
    predicate_type character varying(50),
    source_language character varying(10) DEFAULT 'ko'::character varying NOT NULL
);


--
-- Name: TABLE claims; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.claims IS '기능성/효능 표현 마스터.';


--
-- Name: COLUMN claims.claim_scope; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.claims.claim_scope IS '기능성 범위. 질병 치료/예방 표현(prohibited_disease_claim)은 금지.';


--
-- Name: claims_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.claims_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: claims_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.claims_id_seq OWNED BY public.claims.id;


--
-- Name: code_tables; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.code_tables (
    id bigint NOT NULL,
    table_code character varying(100) NOT NULL,
    table_name_ko character varying(255) NOT NULL,
    table_name_en character varying(255),
    description text,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE code_tables; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.code_tables IS '코드 테이블 마스터. ENUM 대체용.';


--
-- Name: code_tables_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.code_tables_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: code_tables_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.code_tables_id_seq OWNED BY public.code_tables.id;


--
-- Name: code_values; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.code_values (
    id bigint NOT NULL,
    code_table_id bigint NOT NULL,
    code character varying(100) NOT NULL,
    label_ko character varying(255) NOT NULL,
    label_en character varying(255),
    sort_order integer DEFAULT 0,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE code_values; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.code_values IS '코드 값. code_tables의 자식.';


--
-- Name: code_values_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.code_values_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: code_values_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.code_values_id_seq OWNED BY public.code_values.id;


--
-- Name: collection_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.collection_jobs (
    id bigint NOT NULL,
    source_connector_id bigint NOT NULL,
    job_type character varying(50) NOT NULL,
    entity_type character varying(50) NOT NULL,
    job_name character varying(255) NOT NULL,
    query_payload jsonb,
    priority character varying(20) DEFAULT 'normal'::character varying,
    status character varying(50) DEFAULT 'pending'::character varying NOT NULL,
    scheduled_at timestamp without time zone,
    started_at timestamp without time zone,
    finished_at timestamp without time zone,
    retry_count integer DEFAULT 0 NOT NULL,
    error_message text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE collection_jobs; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.collection_jobs IS '수집 작업 정의. Phase 2에서 Airflow와 연동.';


--
-- Name: collection_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.collection_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: collection_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.collection_jobs_id_seq OWNED BY public.collection_jobs.id;


--
-- Name: collection_runs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.collection_runs (
    id bigint NOT NULL,
    collection_job_id bigint NOT NULL,
    run_status character varying(50) NOT NULL,
    records_fetched integer DEFAULT 0,
    records_created integer DEFAULT 0,
    records_updated integer DEFAULT 0,
    records_unchanged integer DEFAULT 0,
    records_failed integer DEFAULT 0,
    started_at timestamp without time zone DEFAULT now() NOT NULL,
    finished_at timestamp without time zone,
    execution_log text,
    error_details jsonb
);


--
-- Name: TABLE collection_runs; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.collection_runs IS '수집 실행 결과 로그. job 1:N run.';


--
-- Name: collection_runs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.collection_runs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: collection_runs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.collection_runs_id_seq OWNED BY public.collection_runs.id;


--
-- Name: dosage_guidelines; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dosage_guidelines (
    id bigint NOT NULL,
    ingredient_id bigint NOT NULL,
    population_group character varying(100) NOT NULL,
    indication_context character varying(255),
    dose_min numeric(18,4),
    dose_max numeric(18,4),
    dose_unit character varying(50),
    frequency_text character varying(100),
    route character varying(50) DEFAULT 'oral'::character varying,
    recommendation_type character varying(50),
    notes text,
    source_id bigint,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE dosage_guidelines; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.dosage_guidelines IS '원료별 용량 가이드라인. 집단/적응증별 분리.';


--
-- Name: dosage_guidelines_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.dosage_guidelines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dosage_guidelines_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.dosage_guidelines_id_seq OWNED BY public.dosage_guidelines.id;


--
-- Name: entity_refresh_states; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.entity_refresh_states (
    id bigint NOT NULL,
    entity_type character varying(50) NOT NULL,
    entity_id bigint NOT NULL,
    source_connector_id bigint,
    external_id character varying(255),
    last_fetched_at timestamp without time zone,
    last_changed_at timestamp without time zone,
    last_checksum character varying(128),
    last_refresh_status character varying(50),
    next_scheduled_refresh_at timestamp without time zone,
    refresh_priority character varying(20) DEFAULT 'normal'::character varying
);


--
-- Name: TABLE entity_refresh_states; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.entity_refresh_states IS '엔티티별 갱신 상태 추적. targeted refresh 우선순위 결정에 사용.';


--
-- Name: COLUMN entity_refresh_states.refresh_priority; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.entity_refresh_states.refresh_priority IS 'high: 인기/규제변경, normal: 일반, low: 변경빈도 낮음';


--
-- Name: entity_refresh_states_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.entity_refresh_states_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: entity_refresh_states_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.entity_refresh_states_id_seq OWNED BY public.entity_refresh_states.id;


--
-- Name: evidence_grade_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.evidence_grade_history (
    id bigint NOT NULL,
    ingredient_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    old_grade character varying(10),
    new_grade character varying(10),
    change_reason text,
    changed_by character varying(255),
    changed_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE evidence_grade_history; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.evidence_grade_history IS '근거 등급 변경 이력. 변경 시 사람 승인 필수.';


--
-- Name: evidence_grade_history_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.evidence_grade_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: evidence_grade_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.evidence_grade_history_id_seq OWNED BY public.evidence_grade_history.id;


--
-- Name: evidence_outcomes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.evidence_outcomes (
    id bigint NOT NULL,
    evidence_study_id bigint NOT NULL,
    claim_id bigint,
    outcome_name character varying(255) NOT NULL,
    outcome_type character varying(100),
    effect_direction character varying(20),
    effect_size_text text,
    p_value_text character varying(100),
    confidence_interval_text character varying(255),
    conclusion_summary text,
    adverse_event_summary text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE evidence_outcomes; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.evidence_outcomes IS '한 논문의 여러 결과지표. RCT가 피로와 수면을 동시 평가 가능.';


--
-- Name: evidence_outcomes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.evidence_outcomes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: evidence_outcomes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.evidence_outcomes_id_seq OWNED BY public.evidence_outcomes.id;


--
-- Name: evidence_studies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.evidence_studies (
    id bigint NOT NULL,
    ingredient_id bigint NOT NULL,
    source_type character varying(50) NOT NULL,
    title text NOT NULL,
    abstract_text text,
    authors text,
    journal_name character varying(255),
    publication_year integer,
    publication_date date,
    pmid character varying(50),
    doi character varying(255),
    external_url text,
    study_design character varying(100),
    population_text text,
    sample_size integer,
    comparator_text text,
    duration_text character varying(255),
    risk_of_bias character varying(50),
    overall_relevance_score numeric(5,2),
    screening_status character varying(50) DEFAULT 'pending'::character varying,
    included_in_summary boolean DEFAULT false NOT NULL,
    duplicate_group_key character varying(255),
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE evidence_studies; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.evidence_studies IS '논문 또는 근거 문서 기본 정보.';


--
-- Name: COLUMN evidence_studies.screening_status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.evidence_studies.screening_status IS '스크리닝 상태. 수집 후 검수 워크플로우 추적.';


--
-- Name: COLUMN evidence_studies.duplicate_group_key; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.evidence_studies.duplicate_group_key IS '중복 논문 그룹 키. 같은 PMID 중복 수집 차단.';


--
-- Name: evidence_studies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.evidence_studies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: evidence_studies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.evidence_studies_id_seq OWNED BY public.evidence_studies.id;


--
-- Name: extraction_results; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.extraction_results (
    id bigint NOT NULL,
    raw_document_id bigint NOT NULL,
    extraction_version character varying(50) NOT NULL,
    schema_version character varying(50) NOT NULL,
    extraction_method character varying(50) NOT NULL,
    extracted_fields jsonb NOT NULL,
    confidence_score numeric(5,2),
    needs_review boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE extraction_results; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.extraction_results IS '원문에서 추출한 구조화 결과. Confidence-based publishing 적용.';


--
-- Name: COLUMN extraction_results.schema_version; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.extraction_results.schema_version IS 'JSONB 구조의 스키마 버전. 앱 레이어에서 JSON Schema 검증.';


--
-- Name: COLUMN extraction_results.confidence_score; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.extraction_results.confidence_score IS '0.95+: 자동반영, 0.70~0.95: 조건부, <0.70: 검수대기';


--
-- Name: extraction_results_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.extraction_results_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: extraction_results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.extraction_results_id_seq OWNED BY public.extraction_results.id;


--
-- Name: ingredient_claims; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ingredient_claims (
    id bigint NOT NULL,
    ingredient_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    evidence_grade character varying(10),
    evidence_summary text,
    is_regulator_approved boolean DEFAULT false NOT NULL,
    approval_country_code character varying(10),
    allowed_expression text,
    prohibited_expression text,
    source_priority integer DEFAULT 100,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    raw_claim_text text,
    raw_claim_language character varying(10) DEFAULT 'ko'::character varying NOT NULL,
    recognition_no character varying(100),
    evidence_grade_text character varying(100),
    claim_scope_note text,
    source_dataset character varying(100)
);


--
-- Name: TABLE ingredient_claims; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.ingredient_claims IS '원료와 기능성의 M:N 연결. 국가별 허용 여부 분리.';


--
-- Name: COLUMN ingredient_claims.approval_country_code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ingredient_claims.approval_country_code IS 'ISO 3166-1 alpha-2. 같은 claim도 국가별 허용 여부가 다름.';


--
-- Name: ingredient_claims_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ingredient_claims_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ingredient_claims_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ingredient_claims_id_seq OWNED BY public.ingredient_claims.id;


--
-- Name: ingredient_drug_interactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ingredient_drug_interactions (
    id bigint NOT NULL,
    ingredient_id bigint NOT NULL,
    drug_name character varying(255) NOT NULL,
    drug_class character varying(255),
    interaction_mechanism text,
    clinical_effect text,
    severity_level character varying(20),
    recommendation text,
    evidence_level character varying(20),
    source_id bigint,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE ingredient_drug_interactions; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.ingredient_drug_interactions IS '약물 상호작용. safety_items과 별도 분리.';


--
-- Name: ingredient_drug_interactions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ingredient_drug_interactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ingredient_drug_interactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ingredient_drug_interactions_id_seq OWNED BY public.ingredient_drug_interactions.id;


--
-- Name: ingredient_search_documents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ingredient_search_documents (
    ingredient_id bigint NOT NULL,
    search_text text NOT NULL,
    search_vector tsvector,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE ingredient_search_documents; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.ingredient_search_documents IS '검색 인덱스용. 원료명+동의어+기능성+부작용 키워드 통합.';


--
-- Name: ingredient_synonyms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ingredient_synonyms (
    id bigint NOT NULL,
    ingredient_id bigint NOT NULL,
    synonym character varying(255) NOT NULL,
    language_code character varying(10) DEFAULT 'ko'::character varying,
    synonym_type character varying(50) NOT NULL,
    is_preferred boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE ingredient_synonyms; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.ingredient_synonyms IS '원료 동의어/이명/검색어 처리용.';


--
-- Name: ingredient_synonyms_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ingredient_synonyms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ingredient_synonyms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ingredient_synonyms_id_seq OWNED BY public.ingredient_synonyms.id;


--
-- Name: ingredients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ingredients (
    id bigint NOT NULL,
    canonical_name_ko character varying(255) NOT NULL,
    canonical_name_en character varying(255),
    display_name character varying(255),
    scientific_name character varying(255),
    slug character varying(255),
    ingredient_type character varying(50) NOT NULL,
    parent_ingredient_id bigint,
    description text,
    origin_type character varying(50),
    form_description text,
    standardization_info text,
    is_active boolean DEFAULT true NOT NULL,
    is_published boolean DEFAULT false NOT NULL,
    last_reviewed_at timestamp without time zone,
    last_synced_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE ingredients; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.ingredients IS '원료 마스터. 모든 데이터의 중심축.';


--
-- Name: COLUMN ingredients.slug; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ingredients.slug IS 'URL용 슬러그. 예: magnesium-citrate';


--
-- Name: COLUMN ingredients.parent_ingredient_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ingredients.parent_ingredient_id IS '상위 원료 ID. 예: 마그네슘(부모) → 산화마그네슘(자식)';


--
-- Name: COLUMN ingredients.is_published; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ingredients.is_published IS '공개 여부. false면 관리자만 볼 수 있음.';


--
-- Name: ingredients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ingredients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ingredients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ingredients_id_seq OWNED BY public.ingredients.id;


--
-- Name: label_snapshots; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.label_snapshots (
    id bigint NOT NULL,
    product_id bigint NOT NULL,
    label_version character varying(100),
    source_name character varying(255),
    source_url text,
    serving_size_text character varying(255),
    servings_per_container character varying(100),
    warning_text text,
    storage_text text,
    directions_text text,
    raw_label_text text,
    captured_at timestamp without time zone,
    effective_date date,
    is_current boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE label_snapshots; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.label_snapshots IS '제품 라벨 버전 관리. 라벨은 자주 바뀌므로 현재값만 저장하면 안 됨.';


--
-- Name: COLUMN label_snapshots.raw_label_text; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.label_snapshots.raw_label_text IS '원본 라벨 텍스트 보존. 파싱 로직 개선 시 재처리 가능.';


--
-- Name: label_snapshots_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.label_snapshots_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: label_snapshots_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.label_snapshots_id_seq OWNED BY public.label_snapshots.id;


--
-- Name: product_aliases; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_aliases (
    id bigint NOT NULL,
    product_id bigint NOT NULL,
    alias text NOT NULL,
    alias_type character varying(30) NOT NULL,
    language_code character varying(5) DEFAULT 'ko'::character varying,
    source character varying(40),
    confidence numeric(3,2),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE product_aliases; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.product_aliases IS '제품명 variations. Vision 추출 텍스트와 다르게 표기된 경우 매칭 성공률 향상에 사용.';


--
-- Name: product_aliases_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.product_aliases_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_aliases_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.product_aliases_id_seq OWNED BY public.product_aliases.id;


--
-- Name: product_enrichment_queue; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_enrichment_queue (
    id bigint NOT NULL,
    product_id bigint NOT NULL,
    status character varying(20) DEFAULT 'pending'::character varying NOT NULL,
    matched_report_no character varying(255),
    attempts integer DEFAULT 0 NOT NULL,
    last_error text,
    source character varying(40),
    payload jsonb,
    scheduled_for timestamp with time zone DEFAULT now() NOT NULL,
    completed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE product_enrichment_queue; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.product_enrichment_queue IS '실시간 검색으로 유입된 제품의 성분 구성 보강 큐. 식약처 staging 데이터와 매칭해 product_ingredients 생성. 배치 소비.';


--
-- Name: product_enrichment_queue_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.product_enrichment_queue_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_enrichment_queue_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.product_enrichment_queue_id_seq OWNED BY public.product_enrichment_queue.id;


--
-- Name: product_images; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_images (
    id bigint NOT NULL,
    product_id bigint NOT NULL,
    source character varying(40) NOT NULL,
    source_url text,
    r2_key text,
    r2_public_url text,
    image_hash character(64),
    mime_type character varying(50),
    width integer,
    height integer,
    size_bytes integer,
    is_primary boolean DEFAULT false NOT NULL,
    removed_at timestamp with time zone,
    captured_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE product_images; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.product_images IS '제품당 다중 소스 이미지. Cloudflare R2에 미러링된 사본. removed_at 설정 시 서빙 차단.';


--
-- Name: product_images_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.product_images_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_images_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.product_images_id_seq OWNED BY public.product_images.id;


--
-- Name: product_ingredients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_ingredients (
    id bigint NOT NULL,
    product_id bigint NOT NULL,
    ingredient_id bigint NOT NULL,
    amount_per_serving numeric(12,4),
    amount_unit character varying(50),
    daily_amount numeric(12,4),
    daily_amount_unit character varying(50),
    ingredient_role character varying(50),
    raw_label_name character varying(255),
    is_standardized boolean DEFAULT false,
    standardization_text text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE product_ingredients; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.product_ingredients IS '제품과 원료의 M:N 연결. 함량 포함.';


--
-- Name: COLUMN product_ingredients.raw_label_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.product_ingredients.raw_label_name IS '원본 라벨 표기명. 정규화 오류 추적용으로 반드시 보존.';


--
-- Name: product_ingredients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.product_ingredients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_ingredients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.product_ingredients_id_seq OWNED BY public.product_ingredients.id;


--
-- Name: products; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.products (
    id bigint NOT NULL,
    product_name character varying(255) NOT NULL,
    brand_name character varying(255),
    manufacturer_name character varying(255),
    distributor_name character varying(255),
    country_code character varying(10),
    product_type character varying(100),
    approval_or_report_no character varying(255),
    status character varying(50) DEFAULT 'active'::character varying,
    barcode character varying(100),
    product_image_url text,
    marketplace_category character varying(255),
    official_url text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    is_published boolean DEFAULT false NOT NULL,
    sale_verified_at timestamp with time zone,
    sale_channel character varying(50),
    sale_url text
);


--
-- Name: TABLE products; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.products IS '제품 마스터.';


--
-- Name: COLUMN products.is_published; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.products.is_published IS '공개 여부. false면 관리자만 볼 수 있음.';


--
-- Name: COLUMN products.sale_verified_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.products.sale_verified_at IS '실제 판매 확인 시점. NULL이면 신고 정보만 있고 유통 미확인. 소비자 목록/성분 페이지 기본 필터.';


--
-- Name: COLUMN products.sale_channel; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.products.sale_channel IS '판매 확인 채널: naver | manufacturer | cafe24 | live_search';


--
-- Name: COLUMN products.sale_url; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.products.sale_url IS '구매 페이지 URL (Naver 상품 링크 또는 공식몰).';


--
-- Name: products_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.products_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: products_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.products_id_seq OWNED BY public.products.id;


--
-- Name: raw_documents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.raw_documents (
    id bigint NOT NULL,
    source_connector_id bigint NOT NULL,
    entity_type character varying(50) NOT NULL,
    entity_external_id character varying(255),
    source_url text,
    content_type character varying(100),
    raw_text text,
    raw_json jsonb,
    file_path text,
    screenshot_path text,
    html_snapshot_path text,
    checksum character varying(128),
    fetched_at timestamp without time zone DEFAULT now() NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE raw_documents; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.raw_documents IS '수집 원문 저장소. Raw-first 정책: 항상 원문 보존 후 파싱.';


--
-- Name: COLUMN raw_documents.raw_text; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.raw_documents.raw_text IS '소형 텍스트 전용. 대용량(PDF, 전체HTML)은 file_path로 object storage 사용.';


--
-- Name: COLUMN raw_documents.checksum; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.raw_documents.checksum IS 'SHA-256. 변경 감지(checksum diff)에 사용.';


--
-- Name: raw_documents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.raw_documents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: raw_documents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.raw_documents_id_seq OWNED BY public.raw_documents.id;


--
-- Name: refresh_policies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.refresh_policies (
    id bigint NOT NULL,
    entity_type character varying(50) NOT NULL,
    source_connector_id bigint,
    refresh_mode character varying(50) NOT NULL,
    full_sync_cron character varying(100),
    incremental_sync_cron character varying(100),
    staleness_days integer,
    change_detection_method character varying(50),
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE refresh_policies; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.refresh_policies IS '엔티티별 갱신 주기 정책. Airflow가 동적으로 읽어 스케줄 생성.';


--
-- Name: COLUMN refresh_policies.full_sync_cron; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.refresh_policies.full_sync_cron IS 'Airflow/Prefect용 cron. DAG 재배포 없이 런타임 정책 변경.';


--
-- Name: refresh_policies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.refresh_policies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: refresh_policies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.refresh_policies_id_seq OWNED BY public.refresh_policies.id;


--
-- Name: regulatory_statuses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.regulatory_statuses (
    id bigint NOT NULL,
    ingredient_id bigint NOT NULL,
    country_code character varying(10) NOT NULL,
    regulatory_category character varying(100) NOT NULL,
    status character varying(50) NOT NULL,
    authority_name character varying(255),
    reference_number character varying(255),
    reference_url text,
    notes text,
    effective_date date,
    expiry_date date,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE regulatory_statuses; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.regulatory_statuses IS '국가별 규제 상태. 고시형/개별인정형 여부 등.';


--
-- Name: regulatory_statuses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.regulatory_statuses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: regulatory_statuses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.regulatory_statuses_id_seq OWNED BY public.regulatory_statuses.id;


--
-- Name: review_tasks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.review_tasks (
    id bigint NOT NULL,
    entity_type character varying(50) NOT NULL,
    entity_id bigint NOT NULL,
    task_type character varying(50) NOT NULL,
    review_level character varying(10) DEFAULT 'L1'::character varying NOT NULL,
    status character varying(50) DEFAULT 'pending'::character varying NOT NULL,
    priority character varying(20) DEFAULT 'normal'::character varying,
    assigned_to character varying(255),
    assigned_role character varying(50),
    reviewer_comment text,
    rejection_reason text,
    parent_task_id bigint,
    auto_check_passed boolean,
    auto_check_details jsonb,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    reviewed_at timestamp without time zone,
    due_at timestamp without time zone
);


--
-- Name: TABLE review_tasks; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.review_tasks IS '정식 검수 워크플로우. L1(데이터)→L2(과학)→L3(규제) 순차 검수.';


--
-- Name: COLUMN review_tasks.review_level; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.review_tasks.review_level IS 'L1: 자동+QA(1일), L2: 과학감수(3~5일), L3: 규제검수(5~7일)';


--
-- Name: COLUMN review_tasks.parent_task_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.review_tasks.parent_task_id IS 'L1→L2→L3 순차 검수 체인. L2의 parent는 L1 task.';


--
-- Name: COLUMN review_tasks.auto_check_passed; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.review_tasks.auto_check_passed IS 'L1 자동 검증 결과. TRUE면 L2로 자동 에스컬레이션 가능.';


--
-- Name: review_tasks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.review_tasks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: review_tasks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.review_tasks_id_seq OWNED BY public.review_tasks.id;


--
-- Name: revision_histories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.revision_histories (
    id bigint NOT NULL,
    entity_type character varying(50) NOT NULL,
    entity_id bigint NOT NULL,
    field_name character varying(255),
    old_value text,
    new_value text,
    change_type character varying(50),
    changed_by character varying(255),
    change_reason text,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE revision_histories; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.revision_histories IS '모든 변경 이력 저장.';


--
-- Name: revision_histories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.revision_histories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: revision_histories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.revision_histories_id_seq OWNED BY public.revision_histories.id;


--
-- Name: safety_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.safety_items (
    id bigint NOT NULL,
    ingredient_id bigint NOT NULL,
    safety_type character varying(50) NOT NULL,
    title character varying(255) NOT NULL,
    description text NOT NULL,
    severity_level character varying(20),
    evidence_level character varying(20),
    frequency_text character varying(100),
    applies_to_population text,
    management_advice text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE safety_items; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.safety_items IS '부작용, 금기, 상호작용, 경고를 통합 관리.';


--
-- Name: COLUMN safety_items.evidence_level; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.safety_items.evidence_level IS '부작용 3계층: label/guideline(1층), rct/observational/case_report(2층), spontaneous_report(3층)';


--
-- Name: safety_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.safety_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: safety_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.safety_items_id_seq OWNED BY public.safety_items.id;


--
-- Name: scan_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.scan_events (
    id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    tier_hit character varying(20) NOT NULL,
    detected_barcode character varying(14),
    extracted_name text,
    matched_product_id bigint,
    match_confidence numeric(5,4),
    image_sha256 character(64),
    latency_ms integer,
    model_used character varying(40),
    CONSTRAINT scan_events_tier_hit_check CHECK (((tier_hit)::text = ANY ((ARRAY['barcode'::character varying, 'vision'::character varying, 'miss'::character varying])::text[])))
);


--
-- Name: TABLE scan_events; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.scan_events IS '카메라 스캔 이벤트 텔레메트리. 품질/비용/히트율 모니터링과 스크레이핑 피드백 루프 소스. IP·세션 등 개인정보 미저장.';


--
-- Name: scan_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.scan_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scan_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.scan_events_id_seq OWNED BY public.scan_events.id;


--
-- Name: scan_events_weekly; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.scan_events_weekly AS
 SELECT date_trunc('day'::text, created_at) AS day,
    tier_hit,
    count(*) AS n,
    avg(match_confidence) FILTER (WHERE (matched_product_id IS NOT NULL)) AS avg_conf,
    avg(latency_ms) AS avg_ms,
    ((count(*) FILTER (WHERE (matched_product_id IS NULL)))::numeric / (NULLIF(count(*), 0))::numeric) AS miss_rate
   FROM public.scan_events
  WHERE (created_at > (now() - '7 days'::interval))
  GROUP BY (date_trunc('day'::text, created_at)), tier_hit
  ORDER BY (date_trunc('day'::text, created_at)) DESC, tier_hit;


--
-- Name: VIEW scan_events_weekly; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.scan_events_weekly IS '주간 스캔 품질 집계. tier_hit별 건수/평균 신뢰도/평균 지연/미스율.';


--
-- Name: scrape_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.scrape_jobs (
    id bigint NOT NULL,
    target_type character varying(30) NOT NULL,
    target_id bigint NOT NULL,
    target_query text,
    source character varying(40) NOT NULL,
    status character varying(20) DEFAULT 'pending'::character varying NOT NULL,
    attempts integer DEFAULT 0 NOT NULL,
    last_error text,
    scheduled_for timestamp with time zone DEFAULT now() NOT NULL,
    started_at timestamp with time zone,
    completed_at timestamp with time zone,
    result_summary jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE scrape_jobs; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.scrape_jobs IS '스크레이핑 배치 작업 큐. 재시도·백오프·재진입(idempotent) 지원. 야간 cron 소비.';


--
-- Name: scrape_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.scrape_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scrape_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.scrape_jobs_id_seq OWNED BY public.scrape_jobs.id;


--
-- Name: source_connectors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.source_connectors (
    id bigint NOT NULL,
    source_id bigint NOT NULL,
    connector_name character varying(255) NOT NULL,
    source_category character varying(100) NOT NULL,
    base_url text,
    access_strategy character varying(50) NOT NULL,
    auth_type character varying(50) DEFAULT 'none'::character varying,
    is_active boolean DEFAULT true NOT NULL,
    rate_limit_per_minute integer,
    retry_policy jsonb,
    parser_config jsonb,
    schedule_policy jsonb,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE source_connectors; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.source_connectors IS '소스별 기술적 접근 설정. sources(신뢰/권위)와 분리.';


--
-- Name: COLUMN source_connectors.source_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.source_connectors.source_id IS 'sources 테이블 FK. 1개 소스가 여러 커넥터(API+브라우저 등)를 가질 수 있음.';


--
-- Name: COLUMN source_connectors.schedule_policy; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.source_connectors.schedule_policy IS 'Airflow/Prefect가 이 필드를 읽어 동적 스케줄을 생성. DAG 재배포 없이 정책 변경 가능.';


--
-- Name: source_connectors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.source_connectors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: source_connectors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.source_connectors_id_seq OWNED BY public.source_connectors.id;


--
-- Name: source_links; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.source_links (
    id bigint NOT NULL,
    source_id bigint NOT NULL,
    entity_type character varying(50) NOT NULL,
    entity_id bigint NOT NULL,
    source_reference text,
    source_excerpt text,
    retrieved_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_source_links_entity_type CHECK (((entity_type)::text = ANY ((ARRAY['ingredient'::character varying, 'claim'::character varying, 'safety_item'::character varying, 'product'::character varying, 'label_snapshot'::character varying, 'evidence_study'::character varying, 'dosage_guideline'::character varying, 'ingredient_drug_interaction'::character varying, 'regulatory_status'::character varying])::text[])))
);


--
-- Name: TABLE source_links; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.source_links IS '각 엔티티에 출처를 연결하는 범용 테이블. FK 강제 불가, 체크 제약으로 보완.';


--
-- Name: source_links_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.source_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: source_links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.source_links_id_seq OWNED BY public.source_links.id;


--
-- Name: sources; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sources (
    id bigint NOT NULL,
    source_name character varying(255) NOT NULL,
    source_type character varying(50) NOT NULL,
    organization_name character varying(255),
    source_url text,
    country_code character varying(10),
    trust_level character varying(20),
    access_method character varying(50),
    notes text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE sources; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.sources IS '모든 출처 중앙 관리.';


--
-- Name: sources_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sources_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sources_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sources_id_seq OWNED BY public.sources.id;


--
-- Name: staging_regulatory_standards_kr; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.staging_regulatory_standards_kr (
    id bigint NOT NULL,
    source_dataset character varying(100) NOT NULL,
    product_code character varying(100),
    test_name_ko character varying(255) NOT NULL,
    min_value character varying(100),
    max_value character varying(100),
    unit character varying(50),
    valid_start_date character varying(20),
    valid_end_date character varying(20),
    source_text text,
    injury_flag character varying(20),
    import_batch character varying(100),
    imported_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE staging_regulatory_standards_kr; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.staging_regulatory_standards_kr IS 'KR government regulatory standards staging for I0960 (e.g., vitamin content spec rows).';


--
-- Name: staging_regulatory_standards_kr_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.staging_regulatory_standards_kr_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: staging_regulatory_standards_kr_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.staging_regulatory_standards_kr_id_seq OWNED BY public.staging_regulatory_standards_kr.id;


--
-- Name: claims id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.claims ALTER COLUMN id SET DEFAULT nextval('public.claims_id_seq'::regclass);


--
-- Name: code_tables id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.code_tables ALTER COLUMN id SET DEFAULT nextval('public.code_tables_id_seq'::regclass);


--
-- Name: code_values id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.code_values ALTER COLUMN id SET DEFAULT nextval('public.code_values_id_seq'::regclass);


--
-- Name: collection_jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collection_jobs ALTER COLUMN id SET DEFAULT nextval('public.collection_jobs_id_seq'::regclass);


--
-- Name: collection_runs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collection_runs ALTER COLUMN id SET DEFAULT nextval('public.collection_runs_id_seq'::regclass);


--
-- Name: dosage_guidelines id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dosage_guidelines ALTER COLUMN id SET DEFAULT nextval('public.dosage_guidelines_id_seq'::regclass);


--
-- Name: entity_refresh_states id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entity_refresh_states ALTER COLUMN id SET DEFAULT nextval('public.entity_refresh_states_id_seq'::regclass);


--
-- Name: evidence_grade_history id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evidence_grade_history ALTER COLUMN id SET DEFAULT nextval('public.evidence_grade_history_id_seq'::regclass);


--
-- Name: evidence_outcomes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evidence_outcomes ALTER COLUMN id SET DEFAULT nextval('public.evidence_outcomes_id_seq'::regclass);


--
-- Name: evidence_studies id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evidence_studies ALTER COLUMN id SET DEFAULT nextval('public.evidence_studies_id_seq'::regclass);


--
-- Name: extraction_results id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.extraction_results ALTER COLUMN id SET DEFAULT nextval('public.extraction_results_id_seq'::regclass);


--
-- Name: ingredient_claims id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ingredient_claims ALTER COLUMN id SET DEFAULT nextval('public.ingredient_claims_id_seq'::regclass);


--
-- Name: ingredient_drug_interactions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ingredient_drug_interactions ALTER COLUMN id SET DEFAULT nextval('public.ingredient_drug_interactions_id_seq'::regclass);


--
-- Name: ingredient_synonyms id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ingredient_synonyms ALTER COLUMN id SET DEFAULT nextval('public.ingredient_synonyms_id_seq'::regclass);


--
-- Name: ingredients id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ingredients ALTER COLUMN id SET DEFAULT nextval('public.ingredients_id_seq'::regclass);


--
-- Name: label_snapshots id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.label_snapshots ALTER COLUMN id SET DEFAULT nextval('public.label_snapshots_id_seq'::regclass);


--
-- Name: product_aliases id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_aliases ALTER COLUMN id SET DEFAULT nextval('public.product_aliases_id_seq'::regclass);


--
-- Name: product_enrichment_queue id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_enrichment_queue ALTER COLUMN id SET DEFAULT nextval('public.product_enrichment_queue_id_seq'::regclass);


--
-- Name: product_images id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_images ALTER COLUMN id SET DEFAULT nextval('public.product_images_id_seq'::regclass);


--
-- Name: product_ingredients id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_ingredients ALTER COLUMN id SET DEFAULT nextval('public.product_ingredients_id_seq'::regclass);


--
-- Name: products id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products ALTER COLUMN id SET DEFAULT nextval('public.products_id_seq'::regclass);


--
-- Name: raw_documents id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.raw_documents ALTER COLUMN id SET DEFAULT nextval('public.raw_documents_id_seq'::regclass);


--
-- Name: refresh_policies id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refresh_policies ALTER COLUMN id SET DEFAULT nextval('public.refresh_policies_id_seq'::regclass);


--
-- Name: regulatory_statuses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.regulatory_statuses ALTER COLUMN id SET DEFAULT nextval('public.regulatory_statuses_id_seq'::regclass);


--
-- Name: review_tasks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.review_tasks ALTER COLUMN id SET DEFAULT nextval('public.review_tasks_id_seq'::regclass);


--
-- Name: revision_histories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.revision_histories ALTER COLUMN id SET DEFAULT nextval('public.revision_histories_id_seq'::regclass);


--
-- Name: safety_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.safety_items ALTER COLUMN id SET DEFAULT nextval('public.safety_items_id_seq'::regclass);


--
-- Name: scan_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scan_events ALTER COLUMN id SET DEFAULT nextval('public.scan_events_id_seq'::regclass);


--
-- Name: scrape_jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scrape_jobs ALTER COLUMN id SET DEFAULT nextval('public.scrape_jobs_id_seq'::regclass);


--
-- Name: source_connectors id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.source_connectors ALTER COLUMN id SET DEFAULT nextval('public.source_connectors_id_seq'::regclass);


--
-- Name: source_links id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.source_links ALTER COLUMN id SET DEFAULT nextval('public.source_links_id_seq'::regclass);


--
-- Name: sources id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sources ALTER COLUMN id SET DEFAULT nextval('public.sources_id_seq'::regclass);


--
-- Name: staging_regulatory_standards_kr id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staging_regulatory_standards_kr ALTER COLUMN id SET DEFAULT nextval('public.staging_regulatory_standards_kr_id_seq'::regclass);


--
-- Name: claims claims_claim_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.claims
    ADD CONSTRAINT claims_claim_code_key UNIQUE (claim_code);


--
-- Name: claims claims_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.claims
    ADD CONSTRAINT claims_pkey PRIMARY KEY (id);


--
-- Name: code_tables code_tables_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.code_tables
    ADD CONSTRAINT code_tables_pkey PRIMARY KEY (id);


--
-- Name: code_tables code_tables_table_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.code_tables
    ADD CONSTRAINT code_tables_table_code_key UNIQUE (table_code);


--
-- Name: code_values code_values_code_table_id_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.code_values
    ADD CONSTRAINT code_values_code_table_id_code_key UNIQUE (code_table_id, code);


--
-- Name: code_values code_values_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.code_values
    ADD CONSTRAINT code_values_pkey PRIMARY KEY (id);


--
-- Name: collection_jobs collection_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collection_jobs
    ADD CONSTRAINT collection_jobs_pkey PRIMARY KEY (id);


--
-- Name: collection_runs collection_runs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collection_runs
    ADD CONSTRAINT collection_runs_pkey PRIMARY KEY (id);


--
-- Name: dosage_guidelines dosage_guidelines_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dosage_guidelines
    ADD CONSTRAINT dosage_guidelines_pkey PRIMARY KEY (id);


--
-- Name: entity_refresh_states entity_refresh_states_entity_type_entity_id_source_connecto_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entity_refresh_states
    ADD CONSTRAINT entity_refresh_states_entity_type_entity_id_source_connecto_key UNIQUE (entity_type, entity_id, source_connector_id);


--
-- Name: entity_refresh_states entity_refresh_states_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entity_refresh_states
    ADD CONSTRAINT entity_refresh_states_pkey PRIMARY KEY (id);


--
-- Name: evidence_grade_history evidence_grade_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evidence_grade_history
    ADD CONSTRAINT evidence_grade_history_pkey PRIMARY KEY (id);


--
-- Name: evidence_outcomes evidence_outcomes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evidence_outcomes
    ADD CONSTRAINT evidence_outcomes_pkey PRIMARY KEY (id);


--
-- Name: evidence_studies evidence_studies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evidence_studies
    ADD CONSTRAINT evidence_studies_pkey PRIMARY KEY (id);


--
-- Name: extraction_results extraction_results_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.extraction_results
    ADD CONSTRAINT extraction_results_pkey PRIMARY KEY (id);


--
-- Name: ingredient_claims ingredient_claims_ingredient_id_claim_id_approval_country_c_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ingredient_claims
    ADD CONSTRAINT ingredient_claims_ingredient_id_claim_id_approval_country_c_key UNIQUE (ingredient_id, claim_id, approval_country_code);


--
-- Name: ingredient_claims ingredient_claims_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ingredient_claims
    ADD CONSTRAINT ingredient_claims_pkey PRIMARY KEY (id);


--
-- Name: ingredient_drug_interactions ingredient_drug_interactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ingredient_drug_interactions
    ADD CONSTRAINT ingredient_drug_interactions_pkey PRIMARY KEY (id);


--
-- Name: ingredient_search_documents ingredient_search_documents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ingredient_search_documents
    ADD CONSTRAINT ingredient_search_documents_pkey PRIMARY KEY (ingredient_id);


--
-- Name: ingredient_synonyms ingredient_synonyms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ingredient_synonyms
    ADD CONSTRAINT ingredient_synonyms_pkey PRIMARY KEY (id);


--
-- Name: ingredients ingredients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ingredients
    ADD CONSTRAINT ingredients_pkey PRIMARY KEY (id);


--
-- Name: ingredients ingredients_slug_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ingredients
    ADD CONSTRAINT ingredients_slug_key UNIQUE (slug);


--
-- Name: label_snapshots label_snapshots_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.label_snapshots
    ADD CONSTRAINT label_snapshots_pkey PRIMARY KEY (id);


--
-- Name: product_aliases product_aliases_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_aliases
    ADD CONSTRAINT product_aliases_pkey PRIMARY KEY (id);


--
-- Name: product_aliases product_aliases_product_id_alias_alias_type_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_aliases
    ADD CONSTRAINT product_aliases_product_id_alias_alias_type_key UNIQUE (product_id, alias, alias_type);


--
-- Name: product_enrichment_queue product_enrichment_queue_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_enrichment_queue
    ADD CONSTRAINT product_enrichment_queue_pkey PRIMARY KEY (id);


--
-- Name: product_enrichment_queue product_enrichment_queue_product_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_enrichment_queue
    ADD CONSTRAINT product_enrichment_queue_product_id_key UNIQUE (product_id);


--
-- Name: product_images product_images_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_images
    ADD CONSTRAINT product_images_pkey PRIMARY KEY (id);


--
-- Name: product_images product_images_product_id_image_hash_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_images
    ADD CONSTRAINT product_images_product_id_image_hash_key UNIQUE (product_id, image_hash);


--
-- Name: product_ingredients product_ingredients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_ingredients
    ADD CONSTRAINT product_ingredients_pkey PRIMARY KEY (id);


--
-- Name: products products_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (id);


--
-- Name: raw_documents raw_documents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.raw_documents
    ADD CONSTRAINT raw_documents_pkey PRIMARY KEY (id);


--
-- Name: refresh_policies refresh_policies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refresh_policies
    ADD CONSTRAINT refresh_policies_pkey PRIMARY KEY (id);


--
-- Name: regulatory_statuses regulatory_statuses_ingredient_id_country_code_regulatory_c_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.regulatory_statuses
    ADD CONSTRAINT regulatory_statuses_ingredient_id_country_code_regulatory_c_key UNIQUE (ingredient_id, country_code, regulatory_category, status, effective_date);


--
-- Name: regulatory_statuses regulatory_statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.regulatory_statuses
    ADD CONSTRAINT regulatory_statuses_pkey PRIMARY KEY (id);


--
-- Name: review_tasks review_tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.review_tasks
    ADD CONSTRAINT review_tasks_pkey PRIMARY KEY (id);


--
-- Name: revision_histories revision_histories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.revision_histories
    ADD CONSTRAINT revision_histories_pkey PRIMARY KEY (id);


--
-- Name: safety_items safety_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.safety_items
    ADD CONSTRAINT safety_items_pkey PRIMARY KEY (id);


--
-- Name: scan_events scan_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scan_events
    ADD CONSTRAINT scan_events_pkey PRIMARY KEY (id);


--
-- Name: scrape_jobs scrape_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scrape_jobs
    ADD CONSTRAINT scrape_jobs_pkey PRIMARY KEY (id);


--
-- Name: scrape_jobs scrape_jobs_target_type_target_id_source_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scrape_jobs
    ADD CONSTRAINT scrape_jobs_target_type_target_id_source_key UNIQUE (target_type, target_id, source);


--
-- Name: source_connectors source_connectors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.source_connectors
    ADD CONSTRAINT source_connectors_pkey PRIMARY KEY (id);


--
-- Name: source_links source_links_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.source_links
    ADD CONSTRAINT source_links_pkey PRIMARY KEY (id);


--
-- Name: sources sources_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sources
    ADD CONSTRAINT sources_pkey PRIMARY KEY (id);


--
-- Name: staging_regulatory_standards_kr staging_regulatory_standards_kr_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staging_regulatory_standards_kr
    ADD CONSTRAINT staging_regulatory_standards_kr_pkey PRIMARY KEY (id);


--
-- Name: staging_regulatory_standards_kr uq_staging_regulatory_standards_kr_row; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staging_regulatory_standards_kr
    ADD CONSTRAINT uq_staging_regulatory_standards_kr_row UNIQUE (source_dataset, product_code, test_name_ko, valid_start_date, valid_end_date);


--
-- Name: idx_claims_claim_key; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_claims_claim_key ON public.claims USING btree (claim_key);


--
-- Name: idx_claims_claim_subject_ko; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_claims_claim_subject_ko ON public.claims USING btree (claim_subject_ko);


--
-- Name: idx_claims_predicate_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_claims_predicate_type ON public.claims USING btree (predicate_type);


--
-- Name: idx_collection_jobs_connector; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_collection_jobs_connector ON public.collection_jobs USING btree (source_connector_id);


--
-- Name: idx_collection_jobs_scheduled; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_collection_jobs_scheduled ON public.collection_jobs USING btree (scheduled_at);


--
-- Name: idx_collection_jobs_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_collection_jobs_status ON public.collection_jobs USING btree (status);


--
-- Name: idx_collection_runs_job; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_collection_runs_job ON public.collection_runs USING btree (collection_job_id);


--
-- Name: idx_collection_runs_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_collection_runs_status ON public.collection_runs USING btree (run_status);


--
-- Name: idx_dosage_guidelines_ingredient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_dosage_guidelines_ingredient_id ON public.dosage_guidelines USING btree (ingredient_id);


--
-- Name: idx_drug_interactions_drug_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_drug_interactions_drug_name ON public.ingredient_drug_interactions USING btree (drug_name);


--
-- Name: idx_drug_interactions_ingredient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_drug_interactions_ingredient_id ON public.ingredient_drug_interactions USING btree (ingredient_id);


--
-- Name: idx_evidence_grade_history_claim; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_evidence_grade_history_claim ON public.evidence_grade_history USING btree (claim_id);


--
-- Name: idx_evidence_grade_history_ingredient; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_evidence_grade_history_ingredient ON public.evidence_grade_history USING btree (ingredient_id);


--
-- Name: idx_evidence_outcomes_claim_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_evidence_outcomes_claim_id ON public.evidence_outcomes USING btree (claim_id);


--
-- Name: idx_evidence_outcomes_study_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_evidence_outcomes_study_id ON public.evidence_outcomes USING btree (evidence_study_id);


--
-- Name: idx_evidence_studies_doi; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_evidence_studies_doi ON public.evidence_studies USING btree (doi) WHERE (doi IS NOT NULL);


--
-- Name: idx_evidence_studies_ingredient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_evidence_studies_ingredient_id ON public.evidence_studies USING btree (ingredient_id);


--
-- Name: idx_evidence_studies_pmid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_evidence_studies_pmid ON public.evidence_studies USING btree (pmid) WHERE (pmid IS NOT NULL);


--
-- Name: idx_evidence_studies_screening; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_evidence_studies_screening ON public.evidence_studies USING btree (screening_status);


--
-- Name: idx_extraction_results_confidence; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_extraction_results_confidence ON public.extraction_results USING btree (confidence_score);


--
-- Name: idx_extraction_results_needs_review; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_extraction_results_needs_review ON public.extraction_results USING btree (needs_review) WHERE (needs_review = true);


--
-- Name: idx_extraction_results_raw_doc; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_extraction_results_raw_doc ON public.extraction_results USING btree (raw_document_id);


--
-- Name: idx_ingredient_claims_claim_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ingredient_claims_claim_id ON public.ingredient_claims USING btree (claim_id);


--
-- Name: idx_ingredient_claims_ingredient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ingredient_claims_ingredient_id ON public.ingredient_claims USING btree (ingredient_id);


--
-- Name: idx_ingredient_claims_recognition_no; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ingredient_claims_recognition_no ON public.ingredient_claims USING btree (recognition_no);


--
-- Name: idx_ingredient_claims_source_dataset; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ingredient_claims_source_dataset ON public.ingredient_claims USING btree (source_dataset);


--
-- Name: idx_ingredient_search_vector; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ingredient_search_vector ON public.ingredient_search_documents USING gin (search_vector);


--
-- Name: idx_ingredient_synonyms_ingredient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ingredient_synonyms_ingredient_id ON public.ingredient_synonyms USING btree (ingredient_id);


--
-- Name: idx_ingredient_synonyms_synonym; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ingredient_synonyms_synonym ON public.ingredient_synonyms USING btree (synonym);


--
-- Name: idx_ingredients_name_en; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ingredients_name_en ON public.ingredients USING btree (canonical_name_en);


--
-- Name: idx_ingredients_name_ko; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ingredients_name_ko ON public.ingredients USING btree (canonical_name_ko);


--
-- Name: idx_ingredients_name_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_ingredients_name_unique ON public.ingredients USING btree (canonical_name_ko);


--
-- Name: idx_ingredients_parent; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ingredients_parent ON public.ingredients USING btree (parent_ingredient_id);


--
-- Name: idx_ingredients_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ingredients_slug ON public.ingredients USING btree (slug);


--
-- Name: idx_ingredients_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ingredients_type ON public.ingredients USING btree (ingredient_type);


--
-- Name: idx_label_snapshots_is_current; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_label_snapshots_is_current ON public.label_snapshots USING btree (is_current) WHERE (is_current = true);


--
-- Name: idx_label_snapshots_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_label_snapshots_product_id ON public.label_snapshots USING btree (product_id);


--
-- Name: idx_product_aliases_alias_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_aliases_alias_trgm ON public.product_aliases USING gin (alias public.gin_trgm_ops);


--
-- Name: idx_product_aliases_product; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_aliases_product ON public.product_aliases USING btree (product_id);


--
-- Name: idx_product_enrichment_queue_pending; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_enrichment_queue_pending ON public.product_enrichment_queue USING btree (scheduled_for) WHERE ((status)::text = 'pending'::text);


--
-- Name: idx_product_enrichment_queue_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_enrichment_queue_status ON public.product_enrichment_queue USING btree (status, scheduled_for);


--
-- Name: idx_product_images_primary; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_images_primary ON public.product_images USING btree (product_id) WHERE ((is_primary = true) AND (removed_at IS NULL));


--
-- Name: idx_product_images_product; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_images_product ON public.product_images USING btree (product_id) WHERE (removed_at IS NULL);


--
-- Name: idx_product_images_source; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_images_source ON public.product_images USING btree (source);


--
-- Name: idx_product_ingredients_ingredient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ingredients_ingredient_id ON public.product_ingredients USING btree (ingredient_id);


--
-- Name: idx_product_ingredients_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ingredients_product_id ON public.product_ingredients USING btree (product_id);


--
-- Name: idx_product_ingredients_product_ingredient_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_product_ingredients_product_ingredient_unique ON public.product_ingredients USING btree (product_id, ingredient_id);


--
-- Name: idx_product_ingredients_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_product_ingredients_unique ON public.product_ingredients USING btree (product_id, ingredient_id, COALESCE(raw_label_name, 'N/A'::character varying));


--
-- Name: idx_products_barcode; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_products_barcode ON public.products USING btree (barcode);


--
-- Name: idx_products_brand; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_products_brand ON public.products USING btree (brand_name);


--
-- Name: idx_products_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_products_name ON public.products USING btree (product_name);


--
-- Name: idx_products_sale_verified; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_products_sale_verified ON public.products USING btree (sale_verified_at DESC) WHERE (sale_verified_at IS NOT NULL);


--
-- Name: idx_products_unique_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_products_unique_identity ON public.products USING btree (product_name, brand_name, COALESCE(approval_or_report_no, 'N/A'::character varying));


--
-- Name: idx_raw_documents_checksum; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_raw_documents_checksum ON public.raw_documents USING btree (checksum);


--
-- Name: idx_raw_documents_connector; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_raw_documents_connector ON public.raw_documents USING btree (source_connector_id);


--
-- Name: idx_raw_documents_entity; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_raw_documents_entity ON public.raw_documents USING btree (entity_type, entity_external_id);


--
-- Name: idx_raw_documents_fetched; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_raw_documents_fetched ON public.raw_documents USING btree (fetched_at);


--
-- Name: idx_refresh_policies_connector; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_refresh_policies_connector ON public.refresh_policies USING btree (source_connector_id);


--
-- Name: idx_refresh_policies_entity; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_refresh_policies_entity ON public.refresh_policies USING btree (entity_type);


--
-- Name: idx_refresh_states_entity; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_refresh_states_entity ON public.entity_refresh_states USING btree (entity_type, entity_id);


--
-- Name: idx_refresh_states_next; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_refresh_states_next ON public.entity_refresh_states USING btree (next_scheduled_refresh_at);


--
-- Name: idx_refresh_states_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_refresh_states_status ON public.entity_refresh_states USING btree (last_refresh_status);


--
-- Name: idx_regulatory_statuses_country; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_regulatory_statuses_country ON public.regulatory_statuses USING btree (country_code);


--
-- Name: idx_regulatory_statuses_ingredient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_regulatory_statuses_ingredient_id ON public.regulatory_statuses USING btree (ingredient_id);


--
-- Name: idx_review_tasks_assigned; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_review_tasks_assigned ON public.review_tasks USING btree (assigned_to, status);


--
-- Name: idx_review_tasks_due; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_review_tasks_due ON public.review_tasks USING btree (due_at) WHERE ((status)::text = ANY ((ARRAY['pending'::character varying, 'in_progress'::character varying])::text[]));


--
-- Name: idx_review_tasks_entity; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_review_tasks_entity ON public.review_tasks USING btree (entity_type, entity_id);


--
-- Name: idx_review_tasks_level; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_review_tasks_level ON public.review_tasks USING btree (review_level, status);


--
-- Name: idx_review_tasks_parent; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_review_tasks_parent ON public.review_tasks USING btree (parent_task_id);


--
-- Name: idx_review_tasks_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_review_tasks_status ON public.review_tasks USING btree (status);


--
-- Name: idx_revision_histories_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_revision_histories_created ON public.revision_histories USING btree (created_at);


--
-- Name: idx_revision_histories_entity; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_revision_histories_entity ON public.revision_histories USING btree (entity_type, entity_id);


--
-- Name: idx_safety_items_ingredient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_safety_items_ingredient_id ON public.safety_items USING btree (ingredient_id);


--
-- Name: idx_safety_items_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_safety_items_type ON public.safety_items USING btree (safety_type);


--
-- Name: idx_scan_events_barcode; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_scan_events_barcode ON public.scan_events USING btree (detected_barcode) WHERE (detected_barcode IS NOT NULL);


--
-- Name: idx_scan_events_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_scan_events_created ON public.scan_events USING btree (created_at DESC);


--
-- Name: idx_scan_events_matched; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_scan_events_matched ON public.scan_events USING btree (matched_product_id) WHERE (matched_product_id IS NOT NULL);


--
-- Name: idx_scan_events_miss; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_scan_events_miss ON public.scan_events USING btree (created_at DESC) WHERE (matched_product_id IS NULL);


--
-- Name: idx_scrape_jobs_pending; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_scrape_jobs_pending ON public.scrape_jobs USING btree (scheduled_for) WHERE ((status)::text = 'pending'::text);


--
-- Name: idx_scrape_jobs_source; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_scrape_jobs_source ON public.scrape_jobs USING btree (source, status);


--
-- Name: idx_scrape_jobs_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_scrape_jobs_status ON public.scrape_jobs USING btree (status, scheduled_for);


--
-- Name: idx_source_connectors_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_source_connectors_source_id ON public.source_connectors USING btree (source_id);


--
-- Name: idx_source_connectors_strategy; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_source_connectors_strategy ON public.source_connectors USING btree (access_strategy);


--
-- Name: idx_source_links_entity; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_source_links_entity ON public.source_links USING btree (entity_type, entity_id);


--
-- Name: idx_source_links_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_source_links_source_id ON public.source_links USING btree (source_id);


--
-- Name: idx_sources_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sources_type ON public.sources USING btree (source_type);


--
-- Name: idx_staging_regulatory_standards_kr_product_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_staging_regulatory_standards_kr_product_code ON public.staging_regulatory_standards_kr USING btree (product_code);


--
-- Name: idx_staging_regulatory_standards_kr_test_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_staging_regulatory_standards_kr_test_name ON public.staging_regulatory_standards_kr USING btree (test_name_ko);


--
-- Name: uq_claims_claim_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_claims_claim_key ON public.claims USING btree (claim_key) WHERE (claim_key IS NOT NULL);


--
-- Name: uq_product_images_one_primary; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_product_images_one_primary ON public.product_images USING btree (product_id) WHERE ((is_primary = true) AND (removed_at IS NULL));


--
-- Name: product_aliases trg_product_aliases_updated; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_product_aliases_updated BEFORE UPDATE ON public.product_aliases FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: product_enrichment_queue trg_product_enrichment_queue_updated; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_product_enrichment_queue_updated BEFORE UPDATE ON public.product_enrichment_queue FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: product_images trg_product_images_updated; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_product_images_updated BEFORE UPDATE ON public.product_images FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: scrape_jobs trg_scrape_jobs_updated; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_scrape_jobs_updated BEFORE UPDATE ON public.scrape_jobs FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: code_values code_values_code_table_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.code_values
    ADD CONSTRAINT code_values_code_table_id_fkey FOREIGN KEY (code_table_id) REFERENCES public.code_tables(id) ON DELETE CASCADE;


--
-- Name: collection_jobs collection_jobs_source_connector_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collection_jobs
    ADD CONSTRAINT collection_jobs_source_connector_id_fkey FOREIGN KEY (source_connector_id) REFERENCES public.source_connectors(id);


--
-- Name: collection_runs collection_runs_collection_job_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collection_runs
    ADD CONSTRAINT collection_runs_collection_job_id_fkey FOREIGN KEY (collection_job_id) REFERENCES public.collection_jobs(id) ON DELETE CASCADE;


--
-- Name: dosage_guidelines dosage_guidelines_ingredient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dosage_guidelines
    ADD CONSTRAINT dosage_guidelines_ingredient_id_fkey FOREIGN KEY (ingredient_id) REFERENCES public.ingredients(id) ON DELETE CASCADE;


--
-- Name: entity_refresh_states entity_refresh_states_source_connector_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entity_refresh_states
    ADD CONSTRAINT entity_refresh_states_source_connector_id_fkey FOREIGN KEY (source_connector_id) REFERENCES public.source_connectors(id);


--
-- Name: evidence_grade_history evidence_grade_history_claim_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evidence_grade_history
    ADD CONSTRAINT evidence_grade_history_claim_id_fkey FOREIGN KEY (claim_id) REFERENCES public.claims(id) ON DELETE CASCADE;


--
-- Name: evidence_grade_history evidence_grade_history_ingredient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evidence_grade_history
    ADD CONSTRAINT evidence_grade_history_ingredient_id_fkey FOREIGN KEY (ingredient_id) REFERENCES public.ingredients(id) ON DELETE CASCADE;


--
-- Name: evidence_outcomes evidence_outcomes_claim_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evidence_outcomes
    ADD CONSTRAINT evidence_outcomes_claim_id_fkey FOREIGN KEY (claim_id) REFERENCES public.claims(id);


--
-- Name: evidence_outcomes evidence_outcomes_evidence_study_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evidence_outcomes
    ADD CONSTRAINT evidence_outcomes_evidence_study_id_fkey FOREIGN KEY (evidence_study_id) REFERENCES public.evidence_studies(id) ON DELETE CASCADE;


--
-- Name: evidence_studies evidence_studies_ingredient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evidence_studies
    ADD CONSTRAINT evidence_studies_ingredient_id_fkey FOREIGN KEY (ingredient_id) REFERENCES public.ingredients(id) ON DELETE CASCADE;


--
-- Name: extraction_results extraction_results_raw_document_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.extraction_results
    ADD CONSTRAINT extraction_results_raw_document_id_fkey FOREIGN KEY (raw_document_id) REFERENCES public.raw_documents(id) ON DELETE CASCADE;


--
-- Name: dosage_guidelines fk_dosage_guidelines_source; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dosage_guidelines
    ADD CONSTRAINT fk_dosage_guidelines_source FOREIGN KEY (source_id) REFERENCES public.sources(id) ON DELETE SET NULL;


--
-- Name: ingredient_drug_interactions fk_drug_interactions_source; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ingredient_drug_interactions
    ADD CONSTRAINT fk_drug_interactions_source FOREIGN KEY (source_id) REFERENCES public.sources(id) ON DELETE SET NULL;


--
-- Name: ingredient_claims ingredient_claims_claim_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ingredient_claims
    ADD CONSTRAINT ingredient_claims_claim_id_fkey FOREIGN KEY (claim_id) REFERENCES public.claims(id) ON DELETE CASCADE;


--
-- Name: ingredient_claims ingredient_claims_ingredient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ingredient_claims
    ADD CONSTRAINT ingredient_claims_ingredient_id_fkey FOREIGN KEY (ingredient_id) REFERENCES public.ingredients(id) ON DELETE CASCADE;


--
-- Name: ingredient_drug_interactions ingredient_drug_interactions_ingredient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ingredient_drug_interactions
    ADD CONSTRAINT ingredient_drug_interactions_ingredient_id_fkey FOREIGN KEY (ingredient_id) REFERENCES public.ingredients(id) ON DELETE CASCADE;


--
-- Name: ingredient_search_documents ingredient_search_documents_ingredient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ingredient_search_documents
    ADD CONSTRAINT ingredient_search_documents_ingredient_id_fkey FOREIGN KEY (ingredient_id) REFERENCES public.ingredients(id) ON DELETE CASCADE;


--
-- Name: ingredient_synonyms ingredient_synonyms_ingredient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ingredient_synonyms
    ADD CONSTRAINT ingredient_synonyms_ingredient_id_fkey FOREIGN KEY (ingredient_id) REFERENCES public.ingredients(id) ON DELETE CASCADE;


--
-- Name: ingredients ingredients_parent_ingredient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ingredients
    ADD CONSTRAINT ingredients_parent_ingredient_id_fkey FOREIGN KEY (parent_ingredient_id) REFERENCES public.ingredients(id);


--
-- Name: label_snapshots label_snapshots_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.label_snapshots
    ADD CONSTRAINT label_snapshots_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;


--
-- Name: product_aliases product_aliases_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_aliases
    ADD CONSTRAINT product_aliases_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;


--
-- Name: product_enrichment_queue product_enrichment_queue_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_enrichment_queue
    ADD CONSTRAINT product_enrichment_queue_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;


--
-- Name: product_images product_images_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_images
    ADD CONSTRAINT product_images_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;


--
-- Name: product_ingredients product_ingredients_ingredient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_ingredients
    ADD CONSTRAINT product_ingredients_ingredient_id_fkey FOREIGN KEY (ingredient_id) REFERENCES public.ingredients(id);


--
-- Name: product_ingredients product_ingredients_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_ingredients
    ADD CONSTRAINT product_ingredients_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;


--
-- Name: raw_documents raw_documents_source_connector_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.raw_documents
    ADD CONSTRAINT raw_documents_source_connector_id_fkey FOREIGN KEY (source_connector_id) REFERENCES public.source_connectors(id);


--
-- Name: refresh_policies refresh_policies_source_connector_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refresh_policies
    ADD CONSTRAINT refresh_policies_source_connector_id_fkey FOREIGN KEY (source_connector_id) REFERENCES public.source_connectors(id);


--
-- Name: regulatory_statuses regulatory_statuses_ingredient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.regulatory_statuses
    ADD CONSTRAINT regulatory_statuses_ingredient_id_fkey FOREIGN KEY (ingredient_id) REFERENCES public.ingredients(id) ON DELETE CASCADE;


--
-- Name: review_tasks review_tasks_parent_task_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.review_tasks
    ADD CONSTRAINT review_tasks_parent_task_id_fkey FOREIGN KEY (parent_task_id) REFERENCES public.review_tasks(id);


--
-- Name: safety_items safety_items_ingredient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.safety_items
    ADD CONSTRAINT safety_items_ingredient_id_fkey FOREIGN KEY (ingredient_id) REFERENCES public.ingredients(id) ON DELETE CASCADE;


--
-- Name: scan_events scan_events_matched_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scan_events
    ADD CONSTRAINT scan_events_matched_product_id_fkey FOREIGN KEY (matched_product_id) REFERENCES public.products(id) ON DELETE SET NULL;


--
-- Name: source_connectors source_connectors_source_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.source_connectors
    ADD CONSTRAINT source_connectors_source_id_fkey FOREIGN KEY (source_id) REFERENCES public.sources(id) ON DELETE CASCADE;


--
-- Name: source_links source_links_source_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.source_links
    ADD CONSTRAINT source_links_source_id_fkey FOREIGN KEY (source_id) REFERENCES public.sources(id) ON DELETE CASCADE;


--
-- Name: claims Admin: claim 전체 접근; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admin: claim 전체 접근" ON public.claims TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());


--
-- Name: entity_refresh_states Admin: 갱신상태 전체 접근; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admin: 갱신상태 전체 접근" ON public.entity_refresh_states TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());


--
-- Name: refresh_policies Admin: 갱신정책 전체 접근; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admin: 갱신정책 전체 접근" ON public.refresh_policies TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());


--
-- Name: ingredient_search_documents Admin: 검색문서 전체 접근; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admin: 검색문서 전체 접근" ON public.ingredient_search_documents TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());


--
-- Name: review_tasks Admin: 검수 태스크 전체 접근; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admin: 검수 태스크 전체 접근" ON public.review_tasks TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());


--
-- Name: regulatory_statuses Admin: 규제상태 전체 접근; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admin: 규제상태 전체 접근" ON public.regulatory_statuses TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());


--
-- Name: evidence_studies Admin: 논문 전체 접근; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admin: 논문 전체 접근" ON public.evidence_studies TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());


--
-- Name: evidence_outcomes Admin: 논문결과 전체 접근; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admin: 논문결과 전체 접근" ON public.evidence_outcomes TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());


--
-- Name: ingredient_synonyms Admin: 동의어 전체 접근; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admin: 동의어 전체 접근" ON public.ingredient_synonyms TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());


--
-- Name: evidence_grade_history Admin: 등급이력 전체 접근; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admin: 등급이력 전체 접근" ON public.evidence_grade_history TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());


--
-- Name: label_snapshots Admin: 라벨 전체 접근; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admin: 라벨 전체 접근" ON public.label_snapshots TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());


--
-- Name: revision_histories Admin: 변경이력 전체 접근; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admin: 변경이력 전체 접근" ON public.revision_histories TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());


--
-- Name: collection_runs Admin: 수집실행 전체 접근; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admin: 수집실행 전체 접근" ON public.collection_runs TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());


--
-- Name: collection_jobs Admin: 수집작업 전체 접근; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admin: 수집작업 전체 접근" ON public.collection_jobs TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());


--
-- Name: safety_items Admin: 안전성 전체 접근; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admin: 안전성 전체 접근" ON public.safety_items TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());


--
-- Name: ingredient_drug_interactions Admin: 약물상호작용 전체 접근; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admin: 약물상호작용 전체 접근" ON public.ingredient_drug_interactions TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());


--
-- Name: dosage_guidelines Admin: 용량 전체 접근; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admin: 용량 전체 접근" ON public.dosage_guidelines TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());


--
-- Name: ingredients Admin: 원료 전체 접근; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admin: 원료 전체 접근" ON public.ingredients TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());


--
-- Name: ingredient_claims Admin: 원료기능성 전체 접근; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admin: 원료기능성 전체 접근" ON public.ingredient_claims TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());


--
-- Name: raw_documents Admin: 원문 전체 접근; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admin: 원문 전체 접근" ON public.raw_documents TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());


--
-- Name: products Admin: 제품 전체 접근; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admin: 제품 전체 접근" ON public.products TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());


--
-- Name: product_ingredients Admin: 제품성분 전체 접근; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admin: 제품성분 전체 접근" ON public.product_ingredients TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());


--
-- Name: extraction_results Admin: 추출결과 전체 접근; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admin: 추출결과 전체 접근" ON public.extraction_results TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());


--
-- Name: sources Admin: 출처 관리; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admin: 출처 관리" ON public.sources TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());


--
-- Name: source_links Admin: 출처연결 관리; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admin: 출처연결 관리" ON public.source_links TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());


--
-- Name: source_connectors Admin: 커넥터 전체 접근; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admin: 커넥터 전체 접근" ON public.source_connectors TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());


--
-- Name: code_values Admin: 코드값 관리; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admin: 코드값 관리" ON public.code_values TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());


--
-- Name: code_tables Admin: 코드테이블 관리; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admin: 코드테이블 관리" ON public.code_tables TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());


--
-- Name: claims; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.claims ENABLE ROW LEVEL SECURITY;

--
-- Name: code_tables; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.code_tables ENABLE ROW LEVEL SECURITY;

--
-- Name: code_values; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.code_values ENABLE ROW LEVEL SECURITY;

--
-- Name: collection_jobs; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.collection_jobs ENABLE ROW LEVEL SECURITY;

--
-- Name: collection_runs; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.collection_runs ENABLE ROW LEVEL SECURITY;

--
-- Name: dosage_guidelines; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.dosage_guidelines ENABLE ROW LEVEL SECURITY;

--
-- Name: entity_refresh_states; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.entity_refresh_states ENABLE ROW LEVEL SECURITY;

--
-- Name: evidence_grade_history; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.evidence_grade_history ENABLE ROW LEVEL SECURITY;

--
-- Name: evidence_outcomes; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.evidence_outcomes ENABLE ROW LEVEL SECURITY;

--
-- Name: evidence_studies; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.evidence_studies ENABLE ROW LEVEL SECURITY;

--
-- Name: extraction_results; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.extraction_results ENABLE ROW LEVEL SECURITY;

--
-- Name: ingredient_claims; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.ingredient_claims ENABLE ROW LEVEL SECURITY;

--
-- Name: ingredient_drug_interactions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.ingredient_drug_interactions ENABLE ROW LEVEL SECURITY;

--
-- Name: ingredient_search_documents; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.ingredient_search_documents ENABLE ROW LEVEL SECURITY;

--
-- Name: ingredient_synonyms; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.ingredient_synonyms ENABLE ROW LEVEL SECURITY;

--
-- Name: ingredients; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.ingredients ENABLE ROW LEVEL SECURITY;

--
-- Name: label_snapshots; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.label_snapshots ENABLE ROW LEVEL SECURITY;

--
-- Name: product_aliases; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.product_aliases ENABLE ROW LEVEL SECURITY;

--
-- Name: product_aliases product_aliases_public_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY product_aliases_public_read ON public.product_aliases FOR SELECT TO authenticated, anon USING (true);


--
-- Name: product_aliases product_aliases_service_role_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY product_aliases_service_role_all ON public.product_aliases TO service_role USING (true) WITH CHECK (true);


--
-- Name: product_enrichment_queue; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.product_enrichment_queue ENABLE ROW LEVEL SECURITY;

--
-- Name: product_enrichment_queue product_enrichment_queue_service_role_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY product_enrichment_queue_service_role_all ON public.product_enrichment_queue TO service_role USING (true) WITH CHECK (true);


--
-- Name: product_images; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.product_images ENABLE ROW LEVEL SECURITY;

--
-- Name: product_images product_images_public_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY product_images_public_read ON public.product_images FOR SELECT TO authenticated, anon USING ((removed_at IS NULL));


--
-- Name: product_images product_images_service_role_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY product_images_service_role_all ON public.product_images TO service_role USING (true) WITH CHECK (true);


--
-- Name: product_ingredients; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.product_ingredients ENABLE ROW LEVEL SECURITY;

--
-- Name: products; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

--
-- Name: raw_documents; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.raw_documents ENABLE ROW LEVEL SECURITY;

--
-- Name: refresh_policies; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.refresh_policies ENABLE ROW LEVEL SECURITY;

--
-- Name: regulatory_statuses; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.regulatory_statuses ENABLE ROW LEVEL SECURITY;

--
-- Name: review_tasks; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.review_tasks ENABLE ROW LEVEL SECURITY;

--
-- Name: revision_histories; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.revision_histories ENABLE ROW LEVEL SECURITY;

--
-- Name: safety_items; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.safety_items ENABLE ROW LEVEL SECURITY;

--
-- Name: scan_events; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.scan_events ENABLE ROW LEVEL SECURITY;

--
-- Name: scan_events scan_events_service_role_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY scan_events_service_role_all ON public.scan_events TO service_role USING (true) WITH CHECK (true);


--
-- Name: scrape_jobs; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.scrape_jobs ENABLE ROW LEVEL SECURITY;

--
-- Name: scrape_jobs scrape_jobs_service_role_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY scrape_jobs_service_role_all ON public.scrape_jobs TO service_role USING (true) WITH CHECK (true);


--
-- Name: source_connectors; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.source_connectors ENABLE ROW LEVEL SECURITY;

--
-- Name: source_links; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.source_links ENABLE ROW LEVEL SECURITY;

--
-- Name: sources; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.sources ENABLE ROW LEVEL SECURITY;

--
-- Name: staging_regulatory_standards_kr; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.staging_regulatory_standards_kr ENABLE ROW LEVEL SECURITY;

--
-- Name: review_tasks 검수자: 검수 태스크 수정; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "검수자: 검수 태스크 수정" ON public.review_tasks FOR UPDATE TO authenticated USING (public.is_reviewer()) WITH CHECK (public.is_reviewer());


--
-- Name: review_tasks 검수자: 검수 태스크 조회; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "검수자: 검수 태스크 조회" ON public.review_tasks FOR SELECT TO authenticated USING (public.is_reviewer());


--
-- Name: revision_histories 검수자: 변경이력 조회; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "검수자: 변경이력 조회" ON public.revision_histories FOR SELECT TO authenticated USING (public.is_reviewer());


--
-- Name: raw_documents 검수자: 원문 조회; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "검수자: 원문 조회" ON public.raw_documents FOR SELECT TO authenticated USING (public.is_reviewer());


--
-- Name: extraction_results 검수자: 추출결과 조회; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "검수자: 추출결과 조회" ON public.extraction_results FOR SELECT TO authenticated USING (public.is_reviewer());


--
-- Name: claims 공개: claim 조회; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "공개: claim 조회" ON public.claims FOR SELECT TO authenticated, anon USING (true);


--
-- Name: evidence_outcomes 공개: 게시된 논문의 결과; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "공개: 게시된 논문의 결과" ON public.evidence_outcomes FOR SELECT TO authenticated, anon USING ((EXISTS ( SELECT 1
   FROM (public.evidence_studies es
     JOIN public.ingredients i ON ((i.id = es.ingredient_id)))
  WHERE ((es.id = evidence_outcomes.evidence_study_id) AND ((es.screening_status)::text = 'included'::text) AND (i.is_published = true)))));


--
-- Name: ingredient_search_documents 공개: 게시된 원료 검색; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "공개: 게시된 원료 검색" ON public.ingredient_search_documents FOR SELECT TO authenticated, anon USING ((EXISTS ( SELECT 1
   FROM public.ingredients
  WHERE ((ingredients.id = ingredient_search_documents.ingredient_id) AND (ingredients.is_published = true)))));


--
-- Name: ingredients 공개: 게시된 원료 조회; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "공개: 게시된 원료 조회" ON public.ingredients FOR SELECT TO authenticated, anon USING ((is_published = true));


--
-- Name: regulatory_statuses 공개: 게시된 원료의 규제상태; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "공개: 게시된 원료의 규제상태" ON public.regulatory_statuses FOR SELECT TO authenticated, anon USING ((EXISTS ( SELECT 1
   FROM public.ingredients
  WHERE ((ingredients.id = regulatory_statuses.ingredient_id) AND (ingredients.is_published = true)))));


--
-- Name: ingredient_claims 공개: 게시된 원료의 기능성; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "공개: 게시된 원료의 기능성" ON public.ingredient_claims FOR SELECT TO authenticated, anon USING ((EXISTS ( SELECT 1
   FROM public.ingredients
  WHERE ((ingredients.id = ingredient_claims.ingredient_id) AND (ingredients.is_published = true)))));


--
-- Name: ingredient_synonyms 공개: 게시된 원료의 동의어; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "공개: 게시된 원료의 동의어" ON public.ingredient_synonyms FOR SELECT TO authenticated, anon USING ((EXISTS ( SELECT 1
   FROM public.ingredients
  WHERE ((ingredients.id = ingredient_synonyms.ingredient_id) AND (ingredients.is_published = true)))));


--
-- Name: evidence_grade_history 공개: 게시된 원료의 등급이력; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "공개: 게시된 원료의 등급이력" ON public.evidence_grade_history FOR SELECT TO authenticated, anon USING ((EXISTS ( SELECT 1
   FROM public.ingredients
  WHERE ((ingredients.id = evidence_grade_history.ingredient_id) AND (ingredients.is_published = true)))));


--
-- Name: safety_items 공개: 게시된 원료의 안전성; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "공개: 게시된 원료의 안전성" ON public.safety_items FOR SELECT TO authenticated, anon USING ((EXISTS ( SELECT 1
   FROM public.ingredients
  WHERE ((ingredients.id = safety_items.ingredient_id) AND (ingredients.is_published = true)))));


--
-- Name: ingredient_drug_interactions 공개: 게시된 원료의 약물상호작용; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "공개: 게시된 원료의 약물상호작용" ON public.ingredient_drug_interactions FOR SELECT TO authenticated, anon USING ((EXISTS ( SELECT 1
   FROM public.ingredients
  WHERE ((ingredients.id = ingredient_drug_interactions.ingredient_id) AND (ingredients.is_published = true)))));


--
-- Name: dosage_guidelines 공개: 게시된 원료의 용량; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "공개: 게시된 원료의 용량" ON public.dosage_guidelines FOR SELECT TO authenticated, anon USING ((EXISTS ( SELECT 1
   FROM public.ingredients
  WHERE ((ingredients.id = dosage_guidelines.ingredient_id) AND (ingredients.is_published = true)))));


--
-- Name: products 공개: 게시된 제품 조회; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "공개: 게시된 제품 조회" ON public.products FOR SELECT TO authenticated, anon USING ((is_published = true));


--
-- Name: label_snapshots 공개: 게시된 제품의 라벨; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "공개: 게시된 제품의 라벨" ON public.label_snapshots FOR SELECT TO authenticated, anon USING ((EXISTS ( SELECT 1
   FROM public.products
  WHERE ((products.id = label_snapshots.product_id) AND (products.is_published = true)))));


--
-- Name: product_ingredients 공개: 게시된 제품의 성분; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "공개: 게시된 제품의 성분" ON public.product_ingredients FOR SELECT TO authenticated, anon USING ((EXISTS ( SELECT 1
   FROM public.products
  WHERE ((products.id = product_ingredients.product_id) AND (products.is_published = true)))));


--
-- Name: sources 공개: 출처 조회; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "공개: 출처 조회" ON public.sources FOR SELECT TO authenticated, anon USING (true);


--
-- Name: source_links 공개: 출처연결 조회; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "공개: 출처연결 조회" ON public.source_links FOR SELECT TO authenticated, anon USING (true);


--
-- Name: code_values 공개: 코드값 조회; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "공개: 코드값 조회" ON public.code_values FOR SELECT TO authenticated, anon USING (true);


--
-- Name: code_tables 공개: 코드테이블 조회; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "공개: 코드테이블 조회" ON public.code_tables FOR SELECT TO authenticated, anon USING (true);


--
-- Name: evidence_studies 공개: 포함된 논문 조회; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "공개: 포함된 논문 조회" ON public.evidence_studies FOR SELECT TO authenticated, anon USING ((((screening_status)::text = 'included'::text) AND (EXISTS ( SELECT 1
   FROM public.ingredients
  WHERE ((ingredients.id = evidence_studies.ingredient_id) AND (ingredients.is_published = true))))));


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: -
--

GRANT USAGE ON SCHEMA public TO postgres;
GRANT USAGE ON SCHEMA public TO anon;
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA public TO service_role;


--
-- Name: FUNCTION is_admin(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.is_admin() TO anon;
GRANT ALL ON FUNCTION public.is_admin() TO authenticated;
GRANT ALL ON FUNCTION public.is_admin() TO service_role;


--
-- Name: FUNCTION is_reviewer(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.is_reviewer() TO anon;
GRANT ALL ON FUNCTION public.is_reviewer() TO authenticated;
GRANT ALL ON FUNCTION public.is_reviewer() TO service_role;


--
-- Name: FUNCTION rls_auto_enable(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.rls_auto_enable() TO anon;
GRANT ALL ON FUNCTION public.rls_auto_enable() TO authenticated;
GRANT ALL ON FUNCTION public.rls_auto_enable() TO service_role;


--
-- Name: FUNCTION set_updated_at(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.set_updated_at() TO anon;
GRANT ALL ON FUNCTION public.set_updated_at() TO authenticated;
GRANT ALL ON FUNCTION public.set_updated_at() TO service_role;


--
-- Name: TABLE claims; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.claims TO anon;
GRANT ALL ON TABLE public.claims TO authenticated;
GRANT ALL ON TABLE public.claims TO service_role;


--
-- Name: SEQUENCE claims_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.claims_id_seq TO anon;
GRANT ALL ON SEQUENCE public.claims_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.claims_id_seq TO service_role;


--
-- Name: TABLE code_tables; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.code_tables TO anon;
GRANT ALL ON TABLE public.code_tables TO authenticated;
GRANT ALL ON TABLE public.code_tables TO service_role;


--
-- Name: SEQUENCE code_tables_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.code_tables_id_seq TO anon;
GRANT ALL ON SEQUENCE public.code_tables_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.code_tables_id_seq TO service_role;


--
-- Name: TABLE code_values; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.code_values TO anon;
GRANT ALL ON TABLE public.code_values TO authenticated;
GRANT ALL ON TABLE public.code_values TO service_role;


--
-- Name: SEQUENCE code_values_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.code_values_id_seq TO anon;
GRANT ALL ON SEQUENCE public.code_values_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.code_values_id_seq TO service_role;


--
-- Name: TABLE collection_jobs; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.collection_jobs TO anon;
GRANT ALL ON TABLE public.collection_jobs TO authenticated;
GRANT ALL ON TABLE public.collection_jobs TO service_role;


--
-- Name: SEQUENCE collection_jobs_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.collection_jobs_id_seq TO anon;
GRANT ALL ON SEQUENCE public.collection_jobs_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.collection_jobs_id_seq TO service_role;


--
-- Name: TABLE collection_runs; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.collection_runs TO anon;
GRANT ALL ON TABLE public.collection_runs TO authenticated;
GRANT ALL ON TABLE public.collection_runs TO service_role;


--
-- Name: SEQUENCE collection_runs_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.collection_runs_id_seq TO anon;
GRANT ALL ON SEQUENCE public.collection_runs_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.collection_runs_id_seq TO service_role;


--
-- Name: TABLE dosage_guidelines; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.dosage_guidelines TO anon;
GRANT ALL ON TABLE public.dosage_guidelines TO authenticated;
GRANT ALL ON TABLE public.dosage_guidelines TO service_role;


--
-- Name: SEQUENCE dosage_guidelines_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.dosage_guidelines_id_seq TO anon;
GRANT ALL ON SEQUENCE public.dosage_guidelines_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.dosage_guidelines_id_seq TO service_role;


--
-- Name: TABLE entity_refresh_states; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.entity_refresh_states TO anon;
GRANT ALL ON TABLE public.entity_refresh_states TO authenticated;
GRANT ALL ON TABLE public.entity_refresh_states TO service_role;


--
-- Name: SEQUENCE entity_refresh_states_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.entity_refresh_states_id_seq TO anon;
GRANT ALL ON SEQUENCE public.entity_refresh_states_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.entity_refresh_states_id_seq TO service_role;


--
-- Name: TABLE evidence_grade_history; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.evidence_grade_history TO anon;
GRANT ALL ON TABLE public.evidence_grade_history TO authenticated;
GRANT ALL ON TABLE public.evidence_grade_history TO service_role;


--
-- Name: SEQUENCE evidence_grade_history_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.evidence_grade_history_id_seq TO anon;
GRANT ALL ON SEQUENCE public.evidence_grade_history_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.evidence_grade_history_id_seq TO service_role;


--
-- Name: TABLE evidence_outcomes; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.evidence_outcomes TO anon;
GRANT ALL ON TABLE public.evidence_outcomes TO authenticated;
GRANT ALL ON TABLE public.evidence_outcomes TO service_role;


--
-- Name: SEQUENCE evidence_outcomes_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.evidence_outcomes_id_seq TO anon;
GRANT ALL ON SEQUENCE public.evidence_outcomes_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.evidence_outcomes_id_seq TO service_role;


--
-- Name: TABLE evidence_studies; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.evidence_studies TO anon;
GRANT ALL ON TABLE public.evidence_studies TO authenticated;
GRANT ALL ON TABLE public.evidence_studies TO service_role;


--
-- Name: SEQUENCE evidence_studies_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.evidence_studies_id_seq TO anon;
GRANT ALL ON SEQUENCE public.evidence_studies_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.evidence_studies_id_seq TO service_role;


--
-- Name: TABLE extraction_results; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.extraction_results TO anon;
GRANT ALL ON TABLE public.extraction_results TO authenticated;
GRANT ALL ON TABLE public.extraction_results TO service_role;


--
-- Name: SEQUENCE extraction_results_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.extraction_results_id_seq TO anon;
GRANT ALL ON SEQUENCE public.extraction_results_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.extraction_results_id_seq TO service_role;


--
-- Name: TABLE ingredient_claims; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.ingredient_claims TO anon;
GRANT ALL ON TABLE public.ingredient_claims TO authenticated;
GRANT ALL ON TABLE public.ingredient_claims TO service_role;


--
-- Name: SEQUENCE ingredient_claims_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.ingredient_claims_id_seq TO anon;
GRANT ALL ON SEQUENCE public.ingredient_claims_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.ingredient_claims_id_seq TO service_role;


--
-- Name: TABLE ingredient_drug_interactions; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.ingredient_drug_interactions TO anon;
GRANT ALL ON TABLE public.ingredient_drug_interactions TO authenticated;
GRANT ALL ON TABLE public.ingredient_drug_interactions TO service_role;


--
-- Name: SEQUENCE ingredient_drug_interactions_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.ingredient_drug_interactions_id_seq TO anon;
GRANT ALL ON SEQUENCE public.ingredient_drug_interactions_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.ingredient_drug_interactions_id_seq TO service_role;


--
-- Name: TABLE ingredient_search_documents; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.ingredient_search_documents TO anon;
GRANT ALL ON TABLE public.ingredient_search_documents TO authenticated;
GRANT ALL ON TABLE public.ingredient_search_documents TO service_role;


--
-- Name: TABLE ingredient_synonyms; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.ingredient_synonyms TO anon;
GRANT ALL ON TABLE public.ingredient_synonyms TO authenticated;
GRANT ALL ON TABLE public.ingredient_synonyms TO service_role;


--
-- Name: SEQUENCE ingredient_synonyms_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.ingredient_synonyms_id_seq TO anon;
GRANT ALL ON SEQUENCE public.ingredient_synonyms_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.ingredient_synonyms_id_seq TO service_role;


--
-- Name: TABLE ingredients; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.ingredients TO anon;
GRANT ALL ON TABLE public.ingredients TO authenticated;
GRANT ALL ON TABLE public.ingredients TO service_role;


--
-- Name: SEQUENCE ingredients_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.ingredients_id_seq TO anon;
GRANT ALL ON SEQUENCE public.ingredients_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.ingredients_id_seq TO service_role;


--
-- Name: TABLE label_snapshots; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.label_snapshots TO anon;
GRANT ALL ON TABLE public.label_snapshots TO authenticated;
GRANT ALL ON TABLE public.label_snapshots TO service_role;


--
-- Name: SEQUENCE label_snapshots_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.label_snapshots_id_seq TO anon;
GRANT ALL ON SEQUENCE public.label_snapshots_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.label_snapshots_id_seq TO service_role;


--
-- Name: TABLE product_aliases; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.product_aliases TO anon;
GRANT ALL ON TABLE public.product_aliases TO authenticated;
GRANT ALL ON TABLE public.product_aliases TO service_role;


--
-- Name: SEQUENCE product_aliases_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.product_aliases_id_seq TO anon;
GRANT ALL ON SEQUENCE public.product_aliases_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.product_aliases_id_seq TO service_role;


--
-- Name: TABLE product_enrichment_queue; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.product_enrichment_queue TO anon;
GRANT ALL ON TABLE public.product_enrichment_queue TO authenticated;
GRANT ALL ON TABLE public.product_enrichment_queue TO service_role;


--
-- Name: SEQUENCE product_enrichment_queue_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.product_enrichment_queue_id_seq TO anon;
GRANT ALL ON SEQUENCE public.product_enrichment_queue_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.product_enrichment_queue_id_seq TO service_role;


--
-- Name: TABLE product_images; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.product_images TO anon;
GRANT ALL ON TABLE public.product_images TO authenticated;
GRANT ALL ON TABLE public.product_images TO service_role;


--
-- Name: SEQUENCE product_images_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.product_images_id_seq TO anon;
GRANT ALL ON SEQUENCE public.product_images_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.product_images_id_seq TO service_role;


--
-- Name: TABLE product_ingredients; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.product_ingredients TO anon;
GRANT ALL ON TABLE public.product_ingredients TO authenticated;
GRANT ALL ON TABLE public.product_ingredients TO service_role;


--
-- Name: SEQUENCE product_ingredients_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.product_ingredients_id_seq TO anon;
GRANT ALL ON SEQUENCE public.product_ingredients_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.product_ingredients_id_seq TO service_role;


--
-- Name: TABLE products; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.products TO anon;
GRANT ALL ON TABLE public.products TO authenticated;
GRANT ALL ON TABLE public.products TO service_role;


--
-- Name: SEQUENCE products_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.products_id_seq TO anon;
GRANT ALL ON SEQUENCE public.products_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.products_id_seq TO service_role;


--
-- Name: TABLE raw_documents; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.raw_documents TO anon;
GRANT ALL ON TABLE public.raw_documents TO authenticated;
GRANT ALL ON TABLE public.raw_documents TO service_role;


--
-- Name: SEQUENCE raw_documents_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.raw_documents_id_seq TO anon;
GRANT ALL ON SEQUENCE public.raw_documents_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.raw_documents_id_seq TO service_role;


--
-- Name: TABLE refresh_policies; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.refresh_policies TO anon;
GRANT ALL ON TABLE public.refresh_policies TO authenticated;
GRANT ALL ON TABLE public.refresh_policies TO service_role;


--
-- Name: SEQUENCE refresh_policies_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.refresh_policies_id_seq TO anon;
GRANT ALL ON SEQUENCE public.refresh_policies_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.refresh_policies_id_seq TO service_role;


--
-- Name: TABLE regulatory_statuses; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.regulatory_statuses TO anon;
GRANT ALL ON TABLE public.regulatory_statuses TO authenticated;
GRANT ALL ON TABLE public.regulatory_statuses TO service_role;


--
-- Name: SEQUENCE regulatory_statuses_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.regulatory_statuses_id_seq TO anon;
GRANT ALL ON SEQUENCE public.regulatory_statuses_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.regulatory_statuses_id_seq TO service_role;


--
-- Name: TABLE review_tasks; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.review_tasks TO anon;
GRANT ALL ON TABLE public.review_tasks TO authenticated;
GRANT ALL ON TABLE public.review_tasks TO service_role;


--
-- Name: SEQUENCE review_tasks_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.review_tasks_id_seq TO anon;
GRANT ALL ON SEQUENCE public.review_tasks_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.review_tasks_id_seq TO service_role;


--
-- Name: TABLE revision_histories; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.revision_histories TO anon;
GRANT ALL ON TABLE public.revision_histories TO authenticated;
GRANT ALL ON TABLE public.revision_histories TO service_role;


--
-- Name: SEQUENCE revision_histories_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.revision_histories_id_seq TO anon;
GRANT ALL ON SEQUENCE public.revision_histories_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.revision_histories_id_seq TO service_role;


--
-- Name: TABLE safety_items; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.safety_items TO anon;
GRANT ALL ON TABLE public.safety_items TO authenticated;
GRANT ALL ON TABLE public.safety_items TO service_role;


--
-- Name: SEQUENCE safety_items_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.safety_items_id_seq TO anon;
GRANT ALL ON SEQUENCE public.safety_items_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.safety_items_id_seq TO service_role;


--
-- Name: TABLE scan_events; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.scan_events TO anon;
GRANT ALL ON TABLE public.scan_events TO authenticated;
GRANT ALL ON TABLE public.scan_events TO service_role;


--
-- Name: SEQUENCE scan_events_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.scan_events_id_seq TO anon;
GRANT ALL ON SEQUENCE public.scan_events_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.scan_events_id_seq TO service_role;


--
-- Name: TABLE scan_events_weekly; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.scan_events_weekly TO anon;
GRANT ALL ON TABLE public.scan_events_weekly TO authenticated;
GRANT ALL ON TABLE public.scan_events_weekly TO service_role;


--
-- Name: TABLE scrape_jobs; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.scrape_jobs TO anon;
GRANT ALL ON TABLE public.scrape_jobs TO authenticated;
GRANT ALL ON TABLE public.scrape_jobs TO service_role;


--
-- Name: SEQUENCE scrape_jobs_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.scrape_jobs_id_seq TO anon;
GRANT ALL ON SEQUENCE public.scrape_jobs_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.scrape_jobs_id_seq TO service_role;


--
-- Name: TABLE source_connectors; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.source_connectors TO anon;
GRANT ALL ON TABLE public.source_connectors TO authenticated;
GRANT ALL ON TABLE public.source_connectors TO service_role;


--
-- Name: SEQUENCE source_connectors_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.source_connectors_id_seq TO anon;
GRANT ALL ON SEQUENCE public.source_connectors_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.source_connectors_id_seq TO service_role;


--
-- Name: TABLE source_links; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.source_links TO anon;
GRANT ALL ON TABLE public.source_links TO authenticated;
GRANT ALL ON TABLE public.source_links TO service_role;


--
-- Name: SEQUENCE source_links_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.source_links_id_seq TO anon;
GRANT ALL ON SEQUENCE public.source_links_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.source_links_id_seq TO service_role;


--
-- Name: TABLE sources; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.sources TO anon;
GRANT ALL ON TABLE public.sources TO authenticated;
GRANT ALL ON TABLE public.sources TO service_role;


--
-- Name: SEQUENCE sources_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.sources_id_seq TO anon;
GRANT ALL ON SEQUENCE public.sources_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.sources_id_seq TO service_role;


--
-- Name: TABLE staging_regulatory_standards_kr; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.staging_regulatory_standards_kr TO anon;
GRANT ALL ON TABLE public.staging_regulatory_standards_kr TO authenticated;
GRANT ALL ON TABLE public.staging_regulatory_standards_kr TO service_role;


--
-- Name: SEQUENCE staging_regulatory_standards_kr_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.staging_regulatory_standards_kr_id_seq TO anon;
GRANT ALL ON SEQUENCE public.staging_regulatory_standards_kr_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.staging_regulatory_standards_kr_id_seq TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: public; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: public; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES TO service_role;


--
-- PostgreSQL database dump complete
--

\unrestrict dqsoHggu0tXL2gyfbUbVQakmvlpkzTdU3N4YsnJYLDvtRxAhiiBcwbckNXYXUdN

