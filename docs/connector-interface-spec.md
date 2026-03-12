# Connector Interface Spec v1

> Version: 1.0.0
> 작성일: 2026-03-12
> 대상: MVP-Pipeline 수집 프레임워크

---

## 1. 개요

수집 프레임워크는 **다양한 데이터 소스**를 일관된 인터페이스로 접근하기 위한 커넥터 구조를 정의한다.

### 설계 원칙
1. **Raw-first**: 항상 원문을 먼저 저장하고, 이후 파싱/추출
2. **Connector = 소스 접근 단위**: 1개 소스가 여러 커넥터를 가질 수 있음 (API + Browser Agent)
3. **파서와 커넥터 분리**: 커넥터는 원문 수집만, 파서는 구조화 추출만 담당
4. **Confidence-based publishing**: 추출 결과의 신뢰도에 따라 자동/조건부/검수대기 분류

### 계층 구조

```
┌──────────────────────────────────────────────────────┐
│ Layer 4: Publishing / Refresh                        │
│   entity_refresh_states, refresh_policies            │
├──────────────────────────────────────────────────────┤
│ Layer 3: Normalization / Mapping                     │
│   Parser → extraction_results → 서비스 테이블 매핑    │
├──────────────────────────────────────────────────────┤
│ Layer 2: Orchestration                               │
│   collection_jobs, collection_runs                   │
├──────────────────────────────────────────────────────┤
│ Layer 1: Source Access                               │
│   source_connectors → raw_documents                  │
└──────────────────────────────────────────────────────┘
```

---

## 2. Connector 인터페이스

### 2.1 BaseConnector (추상 기본 클래스)

```typescript
// src/collection/connectors/base-connector.ts

export interface ConnectorConfig {
  connectorId: number;
  sourceId: number;
  connectorName: string;
  baseUrl: string;
  accessStrategy: "api" | "browser_agent" | "hybrid" | "file_import";
  authType: "none" | "api_key" | "oauth" | "cookie" | "manual";
  rateLimitPerMinute: number;
  retryPolicy: {
    maxRetries: number;
    backoffSeconds: number[];
  };
}

export interface FetchRequest {
  entityType: string;
  queryParams?: Record<string, string | number>;
  searchTerm?: string;
  dateFrom?: string;
  dateTo?: string;
  pageToken?: string;
  maxResults?: number;
}

export interface FetchResult {
  success: boolean;
  data: RawDocumentPayload[];
  nextPageToken?: string;
  totalCount?: number;
  errorMessage?: string;
  fetchedAt: Date;
}

export interface RawDocumentPayload {
  entityExternalId: string;
  sourceUrl?: string;
  contentType: "text/html" | "application/json" | "application/pdf" | "text/plain";
  rawText?: string;
  rawJson?: Record<string, unknown>;
  filePath?: string;
  checksum: string;
}

export abstract class BaseConnector {
  protected config: ConnectorConfig;
  protected rateLimiter: RateLimiter;

  constructor(config: ConnectorConfig) {
    this.config = config;
    this.rateLimiter = new RateLimiter(config.rateLimitPerMinute);
  }

  /** 헬스 체크: 소스가 접근 가능한지 확인 */
  abstract healthCheck(): Promise<boolean>;

  /** 단건 조회 */
  abstract fetchOne(externalId: string): Promise<FetchResult>;

  /** 목록/검색 조회 (페이지네이션 지원) */
  abstract fetchMany(request: FetchRequest): Promise<FetchResult>;

  /** 변경 감지: 마지막 체크 이후 변경된 항목만 조회 */
  abstract fetchChanges(since: Date): Promise<FetchResult>;

  /** Rate limiting 적용 */
  protected async throttle(): Promise<void> {
    await this.rateLimiter.acquire();
  }

  /** 재시도 로직 */
  protected async withRetry<T>(fn: () => Promise<T>): Promise<T> {
    const { maxRetries, backoffSeconds } = this.config.retryPolicy;
    let lastError: Error | undefined;

    for (let attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        await this.throttle();
        return await fn();
      } catch (err) {
        lastError = err as Error;
        if (attempt < maxRetries) {
          const delay = backoffSeconds[attempt] ?? backoffSeconds.at(-1) ?? 8;
          await sleep(delay * 1000);
        }
      }
    }
    throw lastError;
  }
}
```

### 2.2 API Connector

```typescript
// src/collection/connectors/api-connector.ts

export abstract class ApiConnector extends BaseConnector {
  protected apiKey?: string;
  protected headers: Record<string, string> = {};

  constructor(config: ConnectorConfig, apiKey?: string) {
    super(config);
    this.apiKey = apiKey;
    this.headers = this.buildHeaders();
  }

  protected abstract buildHeaders(): Record<string, string>;
  protected abstract buildUrl(request: FetchRequest): string;
  protected abstract parseResponse(response: unknown): RawDocumentPayload[];
}
```

### 2.3 Browser Agent Connector

```typescript
// src/collection/connectors/browser-connector.ts

export interface BrowserConfig extends ConnectorConfig {
  headless: boolean;
  userAgent?: string;
  viewport?: { width: number; height: number };
  waitForSelector?: string;
  screenshotOnError: boolean;
}

export abstract class BrowserConnector extends BaseConnector {
  protected browserConfig: BrowserConfig;

  constructor(config: BrowserConfig) {
    super(config);
    this.browserConfig = config;
  }

  /** 브라우저 세션 시작 */
  protected abstract launchBrowser(): Promise<void>;

  /** 페이지 네비게이션 + HTML 캡처 */
  protected abstract navigateAndCapture(url: string): Promise<{
    html: string;
    screenshot?: Buffer;
  }>;

  /** 브라우저 세션 종료 */
  protected abstract closeBrowser(): Promise<void>;
}
```

---

## 3. Parser 인터페이스

### 3.1 BaseParser (추상 기본 클래스)

```typescript
// src/collection/parsers/base-parser.ts

export interface ParseRequest {
  rawDocumentId: number;
  contentType: string;
  rawText?: string;
  rawJson?: Record<string, unknown>;
  filePath?: string;
}

export interface ParseResult {
  success: boolean;
  extractionVersion: string;
  schemaVersion: string;
  extractionMethod: string;
  extractedFields: Record<string, unknown>;
  confidenceScore: number; // 0.00 ~ 1.00
  errors?: string[];
}

export abstract class BaseParser {
  abstract readonly extractionVersion: string;
  abstract readonly schemaVersion: string;
  abstract readonly extractionMethod: string;

  /** 원문 → 구조화 필드 추출 */
  abstract parse(request: ParseRequest): Promise<ParseResult>;

  /** 추출 결과의 JSON Schema 검증 */
  abstract validate(fields: Record<string, unknown>): boolean;

  /** Confidence score 계산 */
  protected calculateConfidence(
    fields: Record<string, unknown>,
    requiredFields: string[],
    optionalFields: string[]
  ): number {
    const requiredFilled = requiredFields.filter(
      (f) => fields[f] != null && fields[f] !== ""
    ).length;
    const optionalFilled = optionalFields.filter(
      (f) => fields[f] != null && fields[f] !== ""
    ).length;

    const requiredWeight = 0.7;
    const optionalWeight = 0.3;

    const requiredScore =
      requiredFields.length > 0
        ? requiredFilled / requiredFields.length
        : 1.0;
    const optionalScore =
      optionalFields.length > 0
        ? optionalFilled / optionalFields.length
        : 1.0;

    return requiredWeight * requiredScore + optionalWeight * optionalScore;
  }
}
```

---

## 4. 구체 커넥터 구현 (Phase 1 소스)

### 4.1 공공데이터포털 — 건강기능식품 API

```typescript
// src/collection/connectors/kr/data-go-kr-connector.ts

interface DataGoKrConfig extends ConnectorConfig {
  serviceKey: string;  // 공공데이터포털 인증키
}

export class DataGoKrHealthFoodConnector extends ApiConnector {
  // base_url: http://apis.data.go.kr/1471000/HtfsInfoService04
  // rate_limit: 100 req/min (일 10,000건)
  // auth: api_key (query param)
  // 응답: XML (JSON 변환 필요)

  protected buildHeaders() {
    return { Accept: "application/json" };
  }

  protected buildUrl(request: FetchRequest): string {
    const params = new URLSearchParams({
      serviceKey: (this.config as DataGoKrConfig).serviceKey,
      type: "json",
      numOfRows: String(request.maxResults ?? 100),
    });
    if (request.searchTerm) {
      params.set("prdlst_nm", request.searchTerm);
    }
    return `${this.config.baseUrl}/getHtfsItem04?${params}`;
  }

  protected parseResponse(response: unknown): RawDocumentPayload[] {
    // API 응답 → RawDocumentPayload[] 변환
    // checksum: SHA-256(JSON.stringify(item))
    return [];
  }
}
```

### 4.2 PubMed E-utilities

```typescript
// src/collection/connectors/us/pubmed-connector.ts

export class PubMedConnector extends ApiConnector {
  // base_url: https://eutils.ncbi.nlm.nih.gov/entrez/eutils
  // rate_limit: API key 있으면 10/sec, 없으면 3/sec
  // auth: api_key (query param)
  // 2단계 조회: esearch → efetch

  async fetchMany(request: FetchRequest): Promise<FetchResult> {
    // 1단계: esearch — PMID 목록 가져오기
    const searchUrl = `${this.config.baseUrl}/esearch.fcgi`;
    // query: "{ingredient} AND (supplement OR dietary)"

    // 2단계: efetch — 각 PMID의 상세 정보
    const fetchUrl = `${this.config.baseUrl}/efetch.fcgi`;
    // rettype=xml, retmode=xml → PubmedArticle XML

    return { success: true, data: [], fetchedAt: new Date() };
  }
}
```

### 4.3 NIH DSLD (Dietary Supplement Label Database)

```typescript
// src/collection/connectors/us/dsld-connector.ts

export class DsldConnector extends ApiConnector {
  // base_url: https://api.ods.od.nih.gov/dsld/v9
  // rate_limit: 명시 없음 (보수적 30 req/min)
  // auth: none
  // 응답: JSON
  // 주요 엔드포인트:
  //   /browse — 전체 제품 목록
  //   /label/{dsld_id} — 라벨 상세
  //   /ingredient/{dsld_id} — 성분 상세

  protected buildUrl(request: FetchRequest): string {
    if (request.queryParams?.dsldId) {
      return `${this.config.baseUrl}/label/${request.queryParams.dsldId}`;
    }
    const params = new URLSearchParams({
      rows: String(request.maxResults ?? 25),
    });
    if (request.searchTerm) {
      params.set("q", request.searchTerm);
    }
    return `${this.config.baseUrl}/browse?${params}`;
  }
}
```

### 4.4 DailyMed (NLM)

```typescript
// src/collection/connectors/us/dailymed-connector.ts

export class DailyMedConnector extends ApiConnector {
  // base_url: https://dailymed.nlm.nih.gov/dailymed/services/v2
  // rate_limit: 명시 없음 (보수적 30 req/min)
  // auth: none
  // 응답: JSON
  // 주요 엔드포인트:
  //   /spls.json — SPL 문서 검색
  //   /spls/{setId}.json — SPL 상세

  protected buildUrl(request: FetchRequest): string {
    const params = new URLSearchParams({
      pagesize: String(request.maxResults ?? 25),
      drug_class_code: "dietary+supplement",
    });
    if (request.searchTerm) {
      params.set("drug_name", request.searchTerm);
    }
    return `${this.config.baseUrl}/spls.json?${params}`;
  }
}
```

---

## 5. 구체 파서 구현 (Phase 1)

### 5.1 공공데이터포털 원료 파서

```typescript
// src/collection/parsers/kr/data-go-kr-ingredient-parser.ts

export class DataGoKrIngredientParser extends BaseParser {
  readonly extractionVersion = "data_go_kr_ingredient_v1";
  readonly schemaVersion = "ingredient_extract_v1";
  readonly extractionMethod = "api_parser";

  // 추출 필드 스키마:
  // {
  //   canonicalNameKo: string,
  //   ingredientType: string,
  //   regulatoryCategory: string,  // 고시형/개별인정형
  //   approvalNumber: string,
  //   allowedClaims: string[],
  //   dailyDose: string,
  //   precautions: string,
  //   rawMaterial: string
  // }

  async parse(request: ParseRequest): Promise<ParseResult> {
    const json = request.rawJson;
    if (!json) {
      return {
        success: false,
        extractionVersion: this.extractionVersion,
        schemaVersion: this.schemaVersion,
        extractionMethod: this.extractionMethod,
        extractedFields: {},
        confidenceScore: 0,
        errors: ["rawJson is required"],
      };
    }

    const fields = {
      canonicalNameKo: json.PRDLST_NM,
      ingredientType: this.classifyType(json),
      regulatoryCategory: json.PRMS_DT ? "individual_approval" : "notified",
      approvalNumber: json.STDR_STPT_NO,
      allowedClaims: this.extractClaims(json),
      dailyDose: json.DAY_INGST_QY,
      precautions: json.IFTKN_ATNT_MATR_CN,
      rawMaterial: json.RAWMTRL_NM,
    };

    const confidence = this.calculateConfidence(
      fields,
      ["canonicalNameKo", "ingredientType"],
      ["regulatoryCategory", "approvalNumber", "allowedClaims", "dailyDose", "precautions"]
    );

    return {
      success: true,
      extractionVersion: this.extractionVersion,
      schemaVersion: this.schemaVersion,
      extractionMethod: this.extractionMethod,
      extractedFields: fields,
      confidenceScore: confidence,
    };
  }

  validate(fields: Record<string, unknown>): boolean {
    return !!fields.canonicalNameKo && !!fields.ingredientType;
  }

  private classifyType(json: Record<string, unknown>): string {
    // 원료명 기반 분류 로직
    return "other";
  }

  private extractClaims(json: Record<string, unknown>): string[] {
    const primary = json.PRIMARY_FNCLTY as string;
    if (!primary) return [];
    return primary.split(/[,;]/).map((s: string) => s.trim()).filter(Boolean);
  }
}
```

### 5.2 PubMed 논문 파서

```typescript
// src/collection/parsers/us/pubmed-parser.ts

export class PubMedParser extends BaseParser {
  readonly extractionVersion = "pubmed_parser_v1";
  readonly schemaVersion = "evidence_study_v1";
  readonly extractionMethod = "api_parser";

  // 추출 필드 스키마:
  // {
  //   pmid: string,
  //   doi: string,
  //   title: string,
  //   abstractText: string,
  //   authors: string,
  //   journalName: string,
  //   publicationYear: number,
  //   publicationDate: string,
  //   studyDesign: string,    // 제목/초록에서 키워드 매칭
  //   sampleSize: number,     // 초록에서 추출 시도
  //   meshTerms: string[]
  // }

  async parse(request: ParseRequest): Promise<ParseResult> {
    // XML → 구조화 필드
    // PubmedArticle → MedlineCitation → Article
    return {
      success: true,
      extractionVersion: this.extractionVersion,
      schemaVersion: this.schemaVersion,
      extractionMethod: this.extractionMethod,
      extractedFields: {},
      confidenceScore: 0.85,
    };
  }

  validate(fields: Record<string, unknown>): boolean {
    return !!fields.pmid && !!fields.title;
  }
}
```

### 5.3 DSLD 제품 라벨 파서

```typescript
// src/collection/parsers/us/dsld-label-parser.ts

export class DsldLabelParser extends BaseParser {
  readonly extractionVersion = "dsld_label_v1";
  readonly schemaVersion = "product_label_v1";
  readonly extractionMethod = "api_parser";

  // 추출 필드 스키마:
  // {
  //   productName: string,
  //   brandName: string,
  //   manufacturer: string,
  //   servingSize: string,
  //   servingsPerContainer: string,
  //   ingredients: Array<{
  //     name: string,
  //     amount: number,
  //     unit: string,
  //     dailyValuePercent: number
  //   }>,
  //   otherIngredients: string,
  //   warnings: string,
  //   directions: string
  // }
}
```

---

## 6. 오케스트레이션 흐름

### 6.1 수집 파이프라인 실행 순서

```
1. collection_job 생성 (status: pending)
   ↓
2. collection_run 시작 (run_status: running)
   ↓
3. Connector.fetchMany() 호출
   ├─ rate limiting 적용
   ├─ retry with backoff
   └─ raw_documents에 원문 저장
   ↓
4. 변경 감지 (checksum 비교)
   ├─ 새 문서: raw_documents INSERT
   ├─ 변경 문서: raw_documents INSERT (새 버전)
   └─ 미변경: records_unchanged++
   ↓
5. Parser.parse() 호출
   └─ extraction_results에 결과 저장
   ↓
6. Confidence 분류
   ├─ >= 0.95: 서비스 테이블 자동 반영
   ├─ 0.70~0.95: 조건부 반영 + L1 review_task 생성
   └─ < 0.70: L1 review_task 생성 (needs_review)
   ↓
7. collection_run 완료 (run_status: succeeded/failed/partial)
   ↓
8. entity_refresh_states 업데이트
```

### 6.2 서비스 테이블 매핑

추출 결과(`extraction_results.extracted_fields`)를 서비스 테이블에 매핑하는 규칙:

| schema_version | 대상 테이블 | 매핑 책임 |
|---------------|-----------|----------|
| `ingredient_extract_v1` | ingredients, ingredient_claims, dosage_guidelines | IngredientMapper |
| `evidence_study_v1` | evidence_studies, evidence_outcomes | EvidenceMapper |
| `product_label_v1` | products, product_ingredients, label_snapshots | ProductMapper |
| `safety_extract_v1` | safety_items, ingredient_drug_interactions | SafetyMapper |
| `regulatory_extract_v1` | regulatory_statuses | RegulatoryMapper |

```typescript
// src/collection/mappers/base-mapper.ts

export interface MapResult {
  created: number;
  updated: number;
  skipped: number;
  errors: string[];
}

export abstract class BaseMapper {
  abstract readonly schemaVersion: string;

  /** 추출 결과 → 서비스 테이블 매핑 */
  abstract map(
    extractedFields: Record<string, unknown>,
    context: {
      sourceConnectorId: number;
      rawDocumentId: number;
      confidenceScore: number;
    }
  ): Promise<MapResult>;

  /** 원료명 → canonical ingredient 매칭 */
  protected async resolveIngredient(
    name: string,
    type?: string
  ): Promise<number | null> {
    // 1. exact match on canonical_name_ko/en
    // 2. synonym match on ingredient_synonyms
    // 3. fuzzy match (Levenshtein distance)
    // 4. null → L1 review_task 생성 (원료명 매핑 실패)
    return null;
  }
}
```

---

## 7. Rate Limiter

```typescript
// src/collection/utils/rate-limiter.ts

export class RateLimiter {
  private tokens: number;
  private maxTokens: number;
  private refillIntervalMs: number;
  private lastRefill: number;

  constructor(requestsPerMinute: number) {
    this.maxTokens = requestsPerMinute;
    this.tokens = requestsPerMinute;
    this.refillIntervalMs = 60_000 / requestsPerMinute;
    this.lastRefill = Date.now();
  }

  async acquire(): Promise<void> {
    this.refill();
    if (this.tokens <= 0) {
      const waitMs = this.refillIntervalMs - (Date.now() - this.lastRefill);
      await new Promise((resolve) => setTimeout(resolve, Math.max(0, waitMs)));
      this.refill();
    }
    this.tokens--;
  }

  private refill(): void {
    const now = Date.now();
    const elapsed = now - this.lastRefill;
    const tokensToAdd = Math.floor(elapsed / this.refillIntervalMs);
    if (tokensToAdd > 0) {
      this.tokens = Math.min(this.maxTokens, this.tokens + tokensToAdd);
      this.lastRefill = now;
    }
  }
}
```

---

## 8. 변경 감지 전략

| 단계 | 방법 | 비용 | 정확도 |
|------|------|------|--------|
| **1차: 메타데이터** | HTTP ETag, Last-Modified, API updated_at | 최저 | 보통 |
| **2차: Checksum** | SHA-256(raw content) 비교 | 낮음 | 높음 |
| **3차: Semantic Diff** | 추출 필드 값 비교 | 중간 | 최고 |

```typescript
// src/collection/utils/change-detector.ts

export class ChangeDetector {
  /** 1차: 메타데이터 기반 변경 감지 */
  async checkMetadata(url: string, lastEtag?: string): Promise<{
    changed: boolean;
    etag?: string;
  }> {
    // HEAD request → ETag/Last-Modified 비교
    return { changed: true };
  }

  /** 2차: Checksum 비교 */
  checkChecksum(newContent: string, lastChecksum?: string): {
    changed: boolean;
    checksum: string;
  } {
    const checksum = createHash("sha256").update(newContent).digest("hex");
    return {
      changed: checksum !== lastChecksum,
      checksum,
    };
  }

  /** 3차: 추출 필드 레벨 비교 */
  semanticDiff(
    oldFields: Record<string, unknown>,
    newFields: Record<string, unknown>
  ): {
    changed: boolean;
    changedFields: string[];
  } {
    const changedFields: string[] = [];
    for (const key of new Set([...Object.keys(oldFields), ...Object.keys(newFields)])) {
      if (JSON.stringify(oldFields[key]) !== JSON.stringify(newFields[key])) {
        changedFields.push(key);
      }
    }
    return { changed: changedFields.length > 0, changedFields };
  }
}
```

---

## 9. 디렉토리 구조

```
src/collection/
├── connectors/
│   ├── base-connector.ts       # BaseConnector 추상 클래스
│   ├── api-connector.ts        # ApiConnector 추상 클래스
│   ├── browser-connector.ts    # BrowserConnector 추상 클래스
│   ├── kr/
│   │   ├── data-go-kr-connector.ts      # 공공데이터포털
│   │   └── foodsafety-connector.ts      # 식품안전나라
│   └── us/
│       ├── pubmed-connector.ts          # PubMed E-utilities
│       ├── dsld-connector.ts            # NIH DSLD
│       ├── dailymed-connector.ts        # DailyMed
│       └── openfda-connector.ts         # openFDA
├── parsers/
│   ├── base-parser.ts          # BaseParser 추상 클래스
│   ├── kr/
│   │   ├── data-go-kr-ingredient-parser.ts
│   │   └── foodsafety-parser.ts
│   └── us/
│       ├── pubmed-parser.ts
│       ├── dsld-label-parser.ts
│       └── dailymed-parser.ts
├── mappers/
│   ├── base-mapper.ts          # BaseMapper 추상 클래스
│   ├── ingredient-mapper.ts
│   ├── evidence-mapper.ts
│   ├── product-mapper.ts
│   ├── safety-mapper.ts
│   └── regulatory-mapper.ts
├── utils/
│   ├── rate-limiter.ts
│   ├── change-detector.ts
│   └── checksum.ts
└── orchestrator.ts             # 수집 파이프라인 오케스트레이터
```

---

## 10. MVP Phase 1 구현 우선순위

| 순위 | 커넥터 | 파서 | 매퍼 | 데이터 |
|------|--------|------|------|--------|
| **1** | DataGoKrHealthFoodConnector | DataGoKrIngredientParser | IngredientMapper | 원료 20종 기본 정보 |
| **2** | PubMedConnector | PubMedParser | EvidenceMapper | 원료별 핵심 논문 5~10편 |
| **3** | DsldConnector | DsldLabelParser | ProductMapper | US 제품 라벨 |
| **4** | DailyMedConnector | DailyMedParser | ProductMapper | US 제품 SPL |

Phase 1.5 추가:
- FoodsafetyConnector (식품안전나라 — 브라우저 에이전트)
- openFDA Connector (부작용 FAERS)
- USDA FDC Connector (영양소 데이터)

---

## 11. 에러 처리 정책

| 에러 유형 | 대응 | 기록 |
|-----------|------|------|
| **네트워크 오류** | 재시도 (backoff) → 실패 시 job 상태 failed | collection_runs.error_details |
| **인증 실패** | 즉시 중단, 알림 발송 | error_message + 모니터링 |
| **Rate limit 초과** | 자동 대기 → 재시도 | execution_log |
| **파서 오류** | records_failed++, 개별 문서 건너뜀 | extraction_results (confidence=0) |
| **스키마 변경** | 파서 실패율 > 10% → 알림 → 수집 중지 | 모니터링 |
| **원료명 매핑 실패** | L1 review_task 생성 | review_tasks |

---

## 12. source_connectors 시드 데이터

MVP Phase 1 커넥터 초기 설정:

```sql
INSERT INTO source_connectors
  (source_id, connector_name, source_category, base_url,
   access_strategy, auth_type, rate_limit_per_minute,
   retry_policy, parser_config, schedule_policy)
VALUES
  -- 공공데이터포털: 건강기능식품 정보
  (2, 'data-go-kr-health-food-api', 'regulator',
   'http://apis.data.go.kr/1471000/HtfsInfoService04',
   'api', 'api_key', 100,
   '{"maxRetries": 3, "backoffSeconds": [2, 4, 8]}',
   '{"parserName": "data_go_kr_ingredient_v1", "responseFormat": "json"}',
   '{"fullSyncCron": "0 3 1 * *", "incrementalCron": "0 6 * * 1"}'),

  -- PubMed E-utilities
  (5, 'pubmed-eutils', 'literature',
   'https://eutils.ncbi.nlm.nih.gov/entrez/eutils',
   'api', 'api_key', 600,
   '{"maxRetries": 3, "backoffSeconds": [1, 2, 4]}',
   '{"parserName": "pubmed_parser_v1", "rettype": "xml"}',
   '{"fullSyncCron": "0 4 1 * *", "incrementalCron": "0 7 * * *"}'),

  -- NIH DSLD
  (4, 'nih-dsld-api', 'label_db',
   'https://api.ods.od.nih.gov/dsld/v9',
   'api', 'none', 30,
   '{"maxRetries": 3, "backoffSeconds": [2, 4, 8]}',
   '{"parserName": "dsld_label_v1", "responseFormat": "json"}',
   '{"fullSyncCron": "0 5 1 * *", "incrementalCron": "0 8 * * 1"}'),

  -- DailyMed
  (6, 'dailymed-api', 'label_db',
   'https://dailymed.nlm.nih.gov/dailymed/services/v2',
   'api', 'none', 30,
   '{"maxRetries": 3, "backoffSeconds": [2, 4, 8]}',
   '{"parserName": "dailymed_parser_v1", "responseFormat": "json"}',
   '{"fullSyncCron": "0 6 1 * *", "incrementalCron": "0 9 * * 1"}');
```
