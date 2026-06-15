---
name: api-integration
description: planner.md hooks 기반으로 React Query 훅과 TypeScript 타입을 일괄 생성합니다. 백엔드 스펙이 아직 없으면(흔한 경우) planner.md/PRD 데이터 모델에서 잠정 타입+MSW 목을 만들고, OpenAPI 스펙이 있으면(직접 URL을 curl / 로컬 JSON·YAML / Apidog MCP) 정확 타입을 생성합니다. 기존 API 확장(enum/interface/model 변경)도 지원합니다.
---

# API Integration (OpenAPI 스펙 기반)

`planner.md`의 hooks/data flow 섹션을 분석하여 변경 범위를 판별하고, 필요에 따라 **새 훅 생성** 또는 **기존 데이터 구조 확장**을 수행합니다.

## 트리거

- `/code-writer --api` 호출 시
- `/code-writer --all` 호출 시 (Phase 1)

## 입력 컨텍스트

- `planner.md` 내용 (hooks 섹션 + file structure 섹션)
- Jira AC 목록 (있을 경우)
- 프로젝트 루트 경로

---

## 컨벤션 기준 (SSOT)

> 훅·타입·네이밍은 `conventions` 스킬을 단일 기준으로 따릅니다. 이 스킬은 규칙을 복제하지 않고 참조합니다 (복제본은 SSOT와 어긋나 drift를 만듭니다).
> - **Two-Layer Hook Pattern** (conventions §7) — Layer 1 `use[Feature]Query`(순수 fetch + 타입), Layer 2 `use[Feature]`(비즈니스 로직 + mutation). 목록 페이지는 항상 2-layer.
> - **Naming** (conventions §2, §7) — `I` prefix interface, `~Type` suffix type, API path 상수 `UPPER_CASE`(예: `FEATURE_API_PATH`), 훅 `use[Feature]Query`(Layer 1) / `use[Feature]`(Layer 2).
> - **Type/State 위치** (conventions §7, §12) — API request/response 타입은 **React Query 훅 파일에 co-locate**. 별도 `apis/service/`·`apis/model/`·전역 `types/`·`constants/` 폴더 **생성 금지**.

## 프로젝트 구조 감지 (Structure Detection)

레포마다 데이터 레이어 구조가 다릅니다. **임의로 가정하지 말고 실제 구조를 먼저 감지**합니다 (테스트 러너 감지 §13과 같은 마켓플레이스 비종속 원칙).

```bash
Glob: apis/model/*.ts, apis/service/*.ts        # 레이어드 구조 신호
Glob: pageComponents/**/hooks/*.hook.ts         # co-location 구조 신호
```

| 감지 결과 | 채택 구조 | 타입/모델/상수 위치 |
|---|---|---|
| `apis/model/`·`apis/service/` 존재 (레거시 레이어드) | **레이어드 모드** — 그 프로젝트 구조를 그대로 따름 | 기존 `apis/model/*.ts`, `utils/variables.ts` 확장 |
| 위 없음 + `pageComponents/**/hooks/` 사용 (= conventions 표준) | **co-location 모드 (기본)** | 훅 파일에 co-locate (§7/§12) |

> 신규/그린필드 프로젝트는 **co-location 모드가 기본**입니다 (conventions §12 준수). 레이어드 모드는 이미 `apis/model`을 쓰는 레거시 레포에서만 채택합니다.

---

## 타입 소스 판별 (Spec Availability)

**전제: 프론트 작업 시점에 백엔드 API(OpenAPI 스펙)는 아직 안 나와 있는 게 흔합니다.** FE/BE 병렬 개발에선 스펙이 늦게 확정됩니다. 그래서 이 스킬은 두 모드로 동작하고 — **스펙이 없으면 잠정 모드가 기본 경로**입니다. 스펙을 못 구하는 것은 예외(fallback)가 아니라 정상적인 1급 경로입니다.

먼저 스펙 가용 여부를 다음 순서로 판별합니다:

1. planner.md의 API/Data 섹션에 **스펙 URL/파일 경로**가 명시됨 (예: `OpenAPI: https://.../openapi.json`) → **스펙 모드**
2. 사용자가 이번 요청에서 URL/경로 제공 → **스펙 모드**
3. 프로젝트에 **Apidog MCP 연결됨** → **스펙 모드**
4. 위 어느 것도 없음 (= 흔한 경우) → **잠정 모드 (기본)**

> 잠정 모드로 만든 잠정 타입은, 나중에 실제 스펙이 나오면 **스펙 모드로 재실행**하여 정합합니다.

### 잠정 모드 (스펙 없음 — 기본 경로)

planner.md가 담은 필드 정보에서 **잠정(provisional) TypeScript 타입**을 생성합니다. 필드 소스(feature-planner가 출력):
- **`필드 | 타입 | 컴포넌트 | 필수 | 제약` 테이블** (PRD Field → Component Mapping) — 응답/요청 필드명·타입의 1차 소스
- **Form Schema** (`form/schema/[feature]-form.schema.ts`, Zod) — create/edit body 필드
- Component Details의 Props/Types, Jira AC 본문

규칙:
- 생성한 인터페이스 상단에 `// TODO(OpenAPI): 백엔드 스펙 확정 시 재정합` 주석을 답니다.
- 응답 데이터는 **MSW 목**으로 채웁니다(`msw-setup` / `unit-test-gen` 연계). **잠정 타입과 목 데이터의 shape를 반드시 일치**시킵니다 — 둘이 어긋나면 스펙 도착 후 재정합 비용이 커집니다.
- 엔드포인트 경로는 planner.md Hook Layer 테이블의 path를 그대로 씁니다 (예: `/api/v1/masters`).
- pagination·공통 응답 래퍼 형태는 추측하지 말고 코드베이스 기존 패턴(최근 `*.hook.ts`) 구조를 복사합니다.
- planner.md에 필드 정보가 전혀 없으면(테이블·스키마·AC 모두 부재) → 사용자에게 데이터 모델을 물어보고 진행합니다.

### 스펙 모드 (스펙 있음 — 정확 타입)

OpenAPI 문서(OpenAPI 3.x / Swagger 2.0, JSON/YAML) **하나**에서 정확한 타입을 생성합니다. 특정 호스트·MCP에 종속되지 않습니다.

- **소스 ① 직접 URL** — raw OpenAPI 문서를 주는 URL이면 `curl`로 받습니다:
  ```bash
  curl -sSL "<OPENAPI_URL>" -o /tmp/openapi.json -w "HTTP %{http_code} | %{content_type}\n"
  ```
  - ⚠️ **`WebFetch` 금지** — 마크다운 변환 중 JSON 본문을 버립니다. 반드시 `curl`. YAML이면 `-o /tmp/openapi.yaml` 후 `yaml.safe_load`.
  - ⚠️ **raw 문서 엔드포인트**여야 합니다 — 문서 UI URL ≠ raw 스펙 URL인 호스트가 있습니다(Swagger UI 등). content-negotiation으로 JSON 직반환하는 곳(예: Scalar registry share URL)도, 별도 `.json`/`.yaml` 엔드포인트가 있는 곳도 있으니 호스트에 맞는 raw URL을 확인.
- **소스 ② 로컬 파일** — 레포에 커밋된 `openapi.json` / `swagger.yaml`을 `Read`/`python`으로 로드.
- **소스 ③ Apidog MCP (선택)** — Apidog 사용 프로젝트만. 도구 `mcp__apidog__read_project_oas_*` / `..._ref_resources_*` / `..._refresh_*` (`*`는 프로젝트별 — `ToolSearch("apidog")`로 확인).

**대형 스펙 + `$ref` 처리 (스펙 모드 공통):**
- **타겟 추출** — 스펙이 크면(수백 KB+) 전체를 context에 올리지 말고 `python`/`jq`로 필요한 path만 뽑습니다:
  ```bash
  python3 -c "import json; d=json.load(open('/tmp/openapi.json')); print(json.dumps(d['paths']['/api/v1/users']['get'], ensure_ascii=False, indent=2))"
  ```
- **`$ref` 해소** — `$ref: '#/components/schemas/User'`는 같은 문서의 `components.schemas`(Swagger 2.0은 `definitions`)에서 스키마를 꺼내 타입을 채웁니다. 안 하면 타입이 절반만 채워집니다. 중첩 `$ref`는 재귀 해소.

---

## Phase 0: 변경 범위 판별

**CRITICAL: planner.md를 먼저 읽고 변경 경로를 결정합니다.**

### Step 0: 모드 확정 및 선언 (mental anchor)

본격 작업 전에 두 직교 축을 확정하고 **반드시 한 줄로 선언**한다. 긴 문서를 진행하며 모드를 잊는 drift를 막는 앵커다.

- **STRUCTURE_MODE** ← [프로젝트 구조 감지](#프로젝트-구조-감지-structure-detection): `레이어드` | `co-location`(기본)
- **SPEC_MODE** ← [타입 소스 판별](#타입-소스-판별-spec-availability): `스펙` | `잠정`(기본)

```
선언 예: [STRUCTURE_MODE: co-location | SPEC_MODE: 잠정]
```

두 축의 조합별 동작:

| STRUCTURE \ SPEC | 잠정 (스펙 없음·기본) | 스펙 (OpenAPI) |
|---|---|---|
| **co-location (기본)** | 훅 파일에 잠정 타입 co-locate + MSW 목 | 훅 파일에 스펙 기반 정확 타입 co-locate |
| **레이어드 (레거시)** | `apis/model`·`utils/variables`에 잠정 타입 확장 | `apis/model` 등에 스펙 기반 정확 타입 확장 |

> STRUCTURE_MODE는 **파일을 어디에 두는가**(Path 분기), SPEC_MODE는 **타입을 무엇에서 뽑는가**(타입 소스)를 결정한다 — 서로 독립이다.

### Step 1: planner.md에서 Source 태그 수집

planner.md의 아래 섹션들을 파싱하여 각 항목의 `Source` 태그를 수집합니다:

| 확인 섹션 | 확인 대상 | 태그 |
|---|---|---|
| **Hook Layer 테이블** | 각 훅의 Source 컬럼 | `REUSE` / `NEW` |
| **File Structure** | `apis/model/*.ts` *(레이어드 모드만)* | `MODIFY` / 없음 |
| **File Structure** | `apis/service/*.ts` *(레이어드 모드만)* | `MODIFY` / `NEW` / 없음 |
| **File Structure** | `utils/variables.ts` *(레이어드 모드만)* | `MODIFY` / 없음 |
| **Component Details** | 각 컴포넌트의 Source | `REUSE` / `MODIFY` / `NEW` |

> `apis/model`·`apis/service`·`utils/variables` 행은 **레이어드 모드**(구조 감지 결과)에서만 해당합니다. **co-location 모드**에서는 데이터 타입/enum/상수가 모두 **해당 feature의 훅 파일**에 있으므로, MODIFY 대상도 `pageComponents/[feature]/hooks/*.hook.ts`입니다.

### Step 2: 경로 결정

수집된 태그를 기반으로 변경 경로를 판별합니다:

> **"데이터 레이어 MODIFY" 정의** (구조 모드별):
> - **레이어드 모드**: `apis/model/*.ts` 또는 `utils/variables.ts`가 MODIFY
> - **co-location 모드 (기본)**: 해당 feature의 훅 파일(`pageComponents/[feature]/hooks/*.hook.ts`) 또는 `[section].constants.ts`가 MODIFY (= 타입/enum/상수가 추가되는데 새 엔드포인트는 없음)

```
IF  Hook Layer에 NEW가 하나라도 있음
    → Path A: 새 API 훅 생성 (Phase A1~A6 실행)

IF  Hook Layer가 전부 REUSE
AND 데이터 레이어 MODIFY (위 정의 — 모드별 대상)
    → Path B: Data Schema Extension (Phase B1~B7 실행)

IF  Hook Layer에 NEW + REUSE 혼합
AND 데이터 레이어 MODIFY (위 정의 — 모드별 대상)
    → Path C: A + B 조합 실행
```

### Step 3: 판별 결과 출력

```
📋 변경 범위 판별 결과

Hook Layer:
  useAdProduct                  → REUSE (기존 훅 재사용)
  useCreativeSpecStructureQuery → REUSE (기존 훅 재사용)

Data Layer:
  apis/model/adProductModel.ts  → MODIFY (인터페이스 추가)
  utils/variables.ts            → MODIFY (enum 추가)

→ 판별 결과: Path B (Data Schema Extension)
```

---

## Path A: 새 API 훅 생성

> Hook Layer에 `NEW`가 있을 때 실행합니다.

### Phase A1: planner.md에서 API 목록 추출

planner.md의 `Data Fetching` / `Hook Layer` 섹션에서 `NEW` 훅 목록 추출:

```
useXxxQuery(params) → GET /api/v1/xxx      [NEW]
useYyyQuery(id)     → GET /api/v1/yyy/{id}  [NEW]
useZzz()            → wrapper hook           [NEW]
```

추출 규칙:
- `use*Query` → API Query Hook (타입 소스는 Phase A2에서 모드별로 결정)
- `use*` (wrapper) → Business Logic Hook (Query Hook 래핑)
- 목록 페이지는 항상 2-layer (useXxxQuery + useXxx)

### Phase A2: 타입 소스 확보 (잠정 모드 / 스펙 모드)

먼저 **[타입 소스 판별](#타입-소스-판별-spec-availability)**으로 모드를 정합니다. 엔드포인트 경로(path)는 어느 모드든 planner.md Hook Layer 테이블에서 가져옵니다.

```
예시 (양쪽 모드 공통):
useUsersQuery    → GET /api/v1/users
useMastersQuery  → GET /api/v1/masters
```

**잠정 모드 (스펙 없음 — 기본):** planner.md 데이터 모델 / PRD 필드에서 잠정 타입을 만듭니다. 각 인터페이스에 `// TODO(OpenAPI): 백엔드 스펙 확정 시 재정합` 주석. 응답 shape는 MSW 목과 일치시킵니다. (Request·pagination 형태는 기존 `*.hook.ts` 패턴 복사.)

**스펙 모드 (스펙 있음):** 확보한 OpenAPI 문서에서 엔드포인트별로 아래를 추출하고 `$ref`를 해소합니다(타입 소스 판별 섹션의 "대형 스펙 + `$ref` 처리" 규칙):
- **Request**: query params, path params, request body schema
- **Response**: response schema (data 구조, pagination 구조)
- **HTTP method** / **인증**: 필요 여부

### Phase A3: 기존 훅 패턴 파악

```
Glob: pageComponents/**/hooks/*.hook.ts
최근 2-3개 파일 Read → import 방식, 타입 패턴, axios 인스턴스 확인
```

공통 패턴 확인:
- axios import 경로 (`@/apis` 등)
- QueryClient import 방식
- API path 상수 정의 방식
- pagination 응답 구조 (meta? data? total?)

### Phase A4: 훅 파일 일괄 생성

#### 파일 위치
```
pageComponents/[feature]/hooks/use[Feature]Query.hook.ts  ← API query hook
pageComponents/[feature]/hooks/use[Feature].hook.ts       ← wrapper hook (필요 시)
```

#### Layer 1: API Query Hook 템플릿

```typescript
// pageComponents/[feature]/hooks/use[Feature]Query.hook.ts
import { useQuery } from '@tanstack/react-query'
import axios from '@/apis'

// ---- Types ----
// 스펙 모드: OpenAPI 스펙 기반 / 잠정 모드: planner.md 데이터 모델 기반 (잠정)
// TODO(OpenAPI): (잠정 모드일 때) 백엔드 스펙 확정 시 재정합
export interface I[Feature]Item {
  id: string
  // ... response schema 필드들 (스펙 모드=스펙 / 잠정 모드=planner.md 데이터 모델)
}

export interface I[Feature]ListResponse {
  data: I[Feature]Item[]
  total: number
  page: number
  size: number
}

export interface I[Feature]QueryParams {
  page?: number
  size?: number
  q?: string
  // ... OpenAPI 스펙의 query params
}

// ---- API Path ----
export const [FEATURE]_API_PATH = '/api/v1/[feature]'

// ---- Query Hook ----
export const use[Feature]Query = (params?: I[Feature]QueryParams) => {
  return useQuery({
    queryKey: [[FEATURE]_API_PATH, params],
    queryFn: async () => {
      const { data } = await axios.get<I[Feature]ListResponse>([FEATURE]_API_PATH, {
        params,
      })
      return data
    },
    refetchOnWindowFocus: false,
  })
}
```

#### Layer 2: Wrapper Hook 템플릿 (목록 페이지 - 항상 필요)

```typescript
// pageComponents/[feature]/hooks/use[Feature].hook.ts
import { useMutation, useQueryClient } from '@tanstack/react-query'
import axios from '@/apis'
import { use[Feature]Query, [FEATURE]_API_PATH } from './use[Feature]Query.hook'
import type { I[Feature]QueryParams } from './use[Feature]Query.hook'

export const use[Feature] = (params?: I[Feature]QueryParams) => {
  const queryClient = useQueryClient()
  const { data, isFetching, isError } = use[Feature]Query(params)

  // Mutations
  const { mutate: createMutate, isLoading: isCreateLoading } = useMutation({
    mutationFn: async (body: ICreate[Feature]Body) => {
      const { data } = await axios.post([FEATURE]_API_PATH, body)
      return data
    },
    onSuccess: () => {
      queryClient.invalidateQueries([[FEATURE]_API_PATH])
    },
  })

  return {
    data: data?.data ?? [],
    total: data?.total ?? 0,
    isFetching,
    isError,
    createMutate,
    isCreateLoading,
  }
}
```

#### 단건 조회 훅 템플릿

```typescript
// use[Feature]DetailQuery.hook.ts
export const use[Feature]DetailQuery = (id?: string) => {
  return useQuery({
    queryKey: [[FEATURE]_API_PATH, id],
    queryFn: async () => {
      const { data } = await axios.get<I[Feature]Detail>(`${[FEATURE]_API_PATH}/${id}`)
      return data
    },
    enabled: !!id,
    refetchOnWindowFocus: false,
  })
}
```

### Phase A5: 타입 변환 규칙 (OpenAPI → TypeScript)

| OpenAPI 타입 | TypeScript 타입 |
|---|---|
| `string` | `string` |
| `integer`, `number` | `number` |
| `boolean` | `boolean` |
| `array` | `T[]` |
| `object` | `interface` 분리 |
| nullable field | `T \| null` |
| optional field | `T?` |

### Phase A6: 생성 결과 확인

```
✅ API Integration 완료 (Path A: 새 훅 생성)

타입 소스: 잠정 모드 (잠정 타입 — planner.md 기반, 스펙 미정)
            ↳ 백엔드 스펙 확정 시 스펙 모드로 재실행하여 정합 필요

생성된 파일:
  pageComponents/[feature]/hooks/use[Feature]Query.hook.ts
  pageComponents/[feature]/hooks/use[Feature].hook.ts

API 연동 목록:
  GET /api/v1/[feature]        → use[Feature]Query ✓
  GET /api/v1/[feature]/{id}   → use[Feature]DetailQuery ✓
  POST /api/v1/[feature]       → use[Feature].createMutate ✓
```

> 스펙 모드(스펙 기반)일 때는 "타입 소스: 스펙 모드 (OpenAPI 스펙 — <소스>)"로 표기하고 재정합 안내 줄은 생략합니다.

---

## Path B: Data Schema Extension

> Hook Layer가 전부 `REUSE`이고, 새 데이터 타입/enum/모델이 추가되는 케이스입니다 (엔드포인트는 동일).
>
> **확장 대상 위치는 [프로젝트 구조 감지](#프로젝트-구조-감지-structure-detection) 결과를 따릅니다:**
> - **레이어드 모드** — `apis/model/*.ts`·`utils/variables.ts`가 `MODIFY`일 때. 아래 B2~B5의 `apis/model`/`utils/variables` 예시를 그대로 적용.
> - **co-location 모드 (기본)** — 같은 타입/enum/상수가 **해당 feature 훅 파일**(또는 §11 규칙상 `[section].constants.ts`)에 있을 때. B2~B5를 `pageComponents/[feature]/hooks/*.hook.ts` 대상으로 적용하고, 전역 `apis/model`·`utils/variables` 파일을 새로 만들지 않습니다 (conventions §12).
>
> 아래 절차의 파일 경로는 레이어드 모드 예시입니다. co-location 모드면 위 매핑대로 훅/feature 파일로 치환하세요.

### Phase B1: 변경 대상 파일 목록 수집 + 역할변수 매핑

먼저 STRUCTURE_MODE에 따라 **대상 파일 역할변수를 1회 확정**한다. B2~B5는 이 역할변수를 가리킨다 (각 단계의 인라인 주석은 이 매핑의 재확인용):

| 역할변수 | 레이어드 모드 | co-location 모드 (기본) |
|---|---|---|
| `ENUM_FILE` | `utils/variables.ts` | enum이 선언된 `[section].constants.ts` 또는 훅 파일 |
| `MODEL_FILE` | `apis/model/*.ts` | 타입이 co-locate된 `pageComponents/[feature]/hooks/*.hook.ts` |
| `MAPPING_FILE` | variable 파일 | 매핑이 선언된 feature `[section].constants.ts` |

planner.md의 File Structure에서 `MODIFY` 태그된 파일들을 수집합니다 (아래는 레이어드 모드 예시):

```
예시 (레이어드 모드):
  apis/model/adProductModel.ts  ← MODIFY (레이아웃 인터페이스 추가) = MODEL_FILE
  utils/variables.ts            ← MODIFY (enum 추가)                = ENUM_FILE
  ad-configuration.variable.ts  ← MODIFY (매핑 추가)                = MAPPING_FILE
```

각 파일에 대해:
1. 현재 파일 내용 Read
2. planner.md에서 해당 파일의 변경 사항 추출 (Implementation Checklist, Component Details 등)

### Phase B2: enum 확장

planner.md의 Implementation Checklist에서 enum 변경 항목을 찾아 적용합니다.

**변경 패턴**:

```typescript
// BEFORE (utils/variables.ts)
export enum AdProductType {
  GUARANTEE = "보장형",
  HOUSE = "하우스",
}

// AFTER — 새 값 추가
export enum AdProductType {
  GUARANTEE = "보장형",
  HOUSE = "하우스",
  VIDEO_FEED = "동영상 피드형",    // ← 추가
  VIDEO_POPUP = "동영상 팝업형",   // ← 추가
}
```

**절차**:
1. enum 정의 파일 Read — **레이어드**: `utils/variables.ts` / **co-location**: 해당 enum이 선언된 `pageComponents/[feature]/**/[section].constants.ts` 또는 훅 파일
2. planner.md에서 추가할 enum 값 추출
3. 기존 enum 마지막 항목 뒤에 새 값 추가 (Edit)
4. 관련 enum이 여러 개인 경우 (예: `CreativeSpecType`, `CreativeType`) 모두 처리

### Phase B3: interface / type 확장

planner.md에서 `MODIFY`로 표시된 모델 파일의 변경 사항을 적용합니다.

**변경 유형**:

| 유형 | 설명 | 예시 |
|---|---|---|
| 새 interface 추가 | 기존 파일에 새 인터페이스 정의 | `IVideoFeedLayout`, `IVideoPopupLayout` |
| 기존 interface 필드 추가 | union type 확장 등 | `layout: ... \| IVideoFeedLayout` |
| 기존 type union 확장 | 타입에 새 variant 추가 | `ICreativeLayout<IVideoFeedLayout>` |

**절차**:
1. 타입 정의 파일 Read — **레이어드**: `apis/model/*.ts` / **co-location**: 타입이 co-locate된 `pageComponents/[feature]/hooks/*.hook.ts` (없으면 새 전역 `apis/model` 만들지 말고 훅 파일에 추가, §12)
2. planner.md에서 추가할 인터페이스/타입 추출
3. 기존 관련 인터페이스 근처에 새 인터페이스 추가 (Edit)
4. 기존 union type에 새 타입 추가 (Edit)

**주의**: 기존 인터페이스 구조를 변경하지 않고 **확장만** 합니다.

### Phase B4: default model / factory 확장

모델 팩토리 함수에 새 타입에 대한 분기를 추가합니다.

**변경 패턴**:

```typescript
// BEFORE
export const defaultLayoutModel = (creativeSpecType) => {
  switch (creativeSpecType) {
    case "POPUP_BANNER":
      return { ... };
    case "CARD_BANNER":
      return { ... };
    default:
      return { layout_name: "", creative_layouts: [] };
  }
};

// AFTER — 새 case 추가
export const defaultLayoutModel = (creativeSpecType) => {
  switch (creativeSpecType) {
    case "POPUP_BANNER":
      return { ... };
    case "CARD_BANNER":
      return { ... };
    case "VIDEO_FEED":      // ← 추가
      return { ... };
    case "VIDEO_POPUP":     // ← 추가
      return { ... };
    default:
      return { layout_name: "", creative_layouts: [] };
  }
};
```

**절차**:
1. 모델 팩토리 함수 Read (**레이어드**: `apis/model` 내 / **co-location**: 해당 로직이 있는 훅·feature util 파일 내)
2. planner.md에서 새 타입의 기본값 추출
3. 기존 switch/if-else의 `default` 앞에 새 case 추가 (Edit)
4. 기존 패턴 참고 (`Pattern Reference`가 있으면 해당 파일 Read하여 구조 복사)

### Phase B5: 상수 / 매핑 확장

variable 파일의 매핑 객체에 새 타입 항목을 추가합니다.

**변경 패턴**:

```typescript
// BEFORE
export const landingUrlFieldsMapping = {
  POPUP_BANNER: { BannerImage: true, AdBadge: false },
  CARD_BANNER: { BannerImage: true, AdBadge: false },
};

// AFTER — 새 키 추가
export const landingUrlFieldsMapping = {
  POPUP_BANNER: { BannerImage: true, AdBadge: false },
  CARD_BANNER: { BannerImage: true, AdBadge: false },
  VIDEO_FEED: { _videoMediaSpec: true, ThumbnailImage: false, ... },   // ← 추가
  VIDEO_POPUP: { _videoMediaSpec: true, ThumbnailImage: false, ... },  // ← 추가
};
```

**절차**:
1. 매핑 객체 파일 Read (**레이어드**: variable 파일 / **co-location**: 매핑이 선언된 feature `[section].constants.ts`)
2. planner.md의 PRD Field → Component Mapping 테이블 참조
3. 기존 매핑 패턴과 동일한 구조로 새 키-값 추가 (Edit)
4. 관련 매핑 객체가 여러 개인 경우 (예: `defaultLandingUrlValueMapping`, `helpButtonField`) 모두 처리

### Phase B6: 기존 훅 호환성 검증

REUSE 훅이 새 타입을 정상 처리하는지 검증합니다:

1. REUSE 훅 파일 Read
2. 확인 항목:
   - 새 enum 값에 대한 **하드코딩된 분기**가 있는지 (있으면 추가 필요)
   - `pickKeysByModel` 등 유틸이 새 필드를 자동 포함하는지
   - submit 시 새 타입에 대한 특수 처리가 필요한지
3. 문제 발견 시 → 해당 훅도 수정 (Edit)
4. 문제 없으면 → REUSE 확인 완료

### Phase B7: 생성 결과 확인

```
✅ API Integration 완료 (Path B: Data Schema Extension)

변경된 파일:
  utils/variables.ts                    — enum 추가: VIDEO_FEED, VIDEO_POPUP
  apis/model/adProductModel.ts          — interface 추가: IVideoFeedLayout, IVideoPopupLayout
  apis/model/adProductModel.ts          — defaultLayoutModel 확장
  ad-configuration.variable.ts          — 매핑 추가: landingUrlFieldsMapping, helpButtonField

검증 완료:
  useAdProduct                          — REUSE 호환 ✓ (제네릭 처리)
  useCreativeSpecStructureQuery         — REUSE 호환 ✓ (API 기반 동적)

새 훅 생성: 없음 (기존 훅 재사용)
```

> 위 예시는 **레이어드 모드** 경로다. **co-location 모드**에서는 변경 파일을 `pageComponents/[feature]/hooks/*.hook.ts`·`[section].constants.ts`로 표기한다.

---

## Path C: 혼합 (A + B)

> Hook Layer에 `NEW`와 `REUSE`가 혼합되고, 동시에 모델/변수 파일이 `MODIFY`일 때 실행합니다.

1. **먼저 Path B 실행** — 기존 데이터 구조 확장 (enum, interface, model, 상수)
2. **그다음 Path A 실행** — 새 훅 생성 (확장된 타입을 import하여 사용)

이 순서가 중요합니다: 새 훅이 확장된 타입에 의존하기 때문입니다.

---

## 공통 주의사항

- **co-location 모드(기본)**: API 타입은 훅 파일에 co-locate, 별도 `types/`·`apis/model`·`apis/service` 폴더 생성 금지 (conventions §7/§12). **레이어드 모드**: 이미 존재하는 `apis/model` 구조를 따름 — [구조 감지](#프로젝트-구조-감지-structure-detection) 참고
- API path 상수는 export (wrapper hook과 테스트에서 재사용)
- 목록 페이지는 항상 2-layer (Query Hook + Wrapper Hook)
- 단순 셀렉트/드롭다운 옵션 조회는 Query Hook만으로 충분
- `refetchOnWindowFocus: false` 기본 설정
- **스펙이 없는 것은 fallback이 아니라 잠정 모드(기본 경로)** — planner.md/PRD 데이터 모델로 잠정 타입을 만들고 MSW 목과 shape를 맞춥니다. 스펙이 나오면 스펙 모드로 재실행해 정합 (타입 소스 판별 섹션 참고)
- `$ref` 조회 시 여러 경로를 배열로 전달하여 한 번에 조회 (호출 횟수 최소화)
- Path B에서는 기존 코드를 **확장만** 하고 기존 구조를 변경하지 않습니다
- Edit 시 `replace_all: false`로 정확한 위치에만 삽입합니다
