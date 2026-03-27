---
name: api-integration
description: Apidog MCP로 API 스펙을 조회하고 planner.md hooks 기반으로 React Query 훅과 TypeScript 타입을 일괄 생성합니다. 기존 API 확장(enum/interface/model 변경)도 지원합니다.
---

# API Integration (Apidog MCP 기반)

`planner.md`의 hooks/data flow 섹션을 분석하여 변경 범위를 판별하고, 필요에 따라 **새 훅 생성** 또는 **기존 데이터 구조 확장**을 수행합니다.

## 트리거

- `/code-writer --api` 호출 시
- `/code-writer --all` 호출 시 (Phase 1)

## 입력 컨텍스트

- `planner.md` 내용 (hooks 섹션 + file structure 섹션)
- Jira AC 목록 (있을 경우)
- 프로젝트 루트 경로

---

## Phase 0: 변경 범위 판별

**CRITICAL: planner.md를 먼저 읽고 변경 경로를 결정합니다.**

### Step 1: planner.md에서 Source 태그 수집

planner.md의 아래 섹션들을 파싱하여 각 항목의 `Source` 태그를 수집합니다:

| 확인 섹션 | 확인 대상 | 태그 |
|---|---|---|
| **Hook Layer 테이블** | 각 훅의 Source 컬럼 | `REUSE` / `NEW` |
| **File Structure** | `apis/model/*.ts` | `MODIFY` / 없음 |
| **File Structure** | `apis/service/*.ts` | `MODIFY` / `NEW` / 없음 |
| **File Structure** | `utils/variables.ts` | `MODIFY` / 없음 |
| **Component Details** | 각 컴포넌트의 Source | `REUSE` / `MODIFY` / `NEW` |

### Step 2: 경로 결정

수집된 태그를 기반으로 변경 경로를 판별합니다:

```
IF  Hook Layer에 NEW가 하나라도 있음
    → Path A: 새 API 훅 생성 (Phase A1~A6 실행)

IF  Hook Layer가 전부 REUSE
AND (apis/model이 MODIFY OR utils/variables.ts가 MODIFY)
    → Path B: Data Schema Extension (Phase B1~B7 실행)

IF  Hook Layer에 NEW + REUSE 혼합
AND apis/model이 MODIFY
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
- `use*Query` → API Query Hook (Apidog에서 스펙 조회 필요)
- `use*` (wrapper) → Business Logic Hook (Query Hook 래핑)
- 목록 페이지는 항상 2-layer (useXxxQuery + useXxx)

### Phase A2: Apidog MCP로 API 스펙 일괄 조회

Apidog MCP 도구 3종을 사용하여 OpenAPI 스펙을 조회합니다:

| 도구 | 용도 |
|---|---|
| `mcp__apidog__read_project_oas_*` | OAS 전체 구조 읽기 (엔드포인트 목록, `$ref` 경로 파악) |
| `mcp__apidog__read_project_oas_ref_resources_*` | `$ref`로 참조된 개별 path/schema JSON 일괄 조회 |
| `mcp__apidog__refresh_project_oas_*` | 최신 스펙으로 갱신 (스펙 변경이 의심될 때) |

> **Tool ID 참고**: `*` 부분은 프로젝트별로 다릅니다. `ToolSearch("apidog")` 또는 `Glob`으로 실제 tool 이름을 확인하세요.

#### 조회 절차

1. **OAS 읽기** — `read_project_oas`로 전체 OpenAPI 스펙 구조를 확인합니다.
2. **필요 엔드포인트 `$ref` 경로 추출** — planner.md 훅에 매핑되는 path를 찾고 `$ref` 값을 수집합니다.
3. **상세 스펙 일괄 조회** — `read_project_oas_ref_resources`의 `path` 배열에 `$ref` 경로들을 전달하여 한 번에 조회합니다.

```
예시:
useUsersQuery    → $ref: /paths/_api_v1_users-GET.json    → 일괄 조회
useMastersQuery  → $ref: /paths/_api_v1_masters-GET.json   → 일괄 조회
```

각 엔드포인트에서 추출:
- **Request**: query params, path params, request body schema
- **Response**: response schema (data 구조, pagination 구조)
- **HTTP method**: GET/POST/PUT/DELETE
- **인증**: 필요 여부

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

// ---- Types (Apidog OAS 스펙 기반으로 생성) ----
export interface I[Feature]Item {
  id: string
  // ... Apidog 스펙의 response schema 필드들
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
  // ... Apidog 스펙의 query params
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

### Phase A5: 타입 변환 규칙 (Apidog OAS → TypeScript)

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

생성된 파일:
  pageComponents/[feature]/hooks/use[Feature]Query.hook.ts
  pageComponents/[feature]/hooks/use[Feature].hook.ts

API 연동 목록:
  GET /api/v1/[feature]        → use[Feature]Query ✓
  GET /api/v1/[feature]/{id}   → use[Feature]DetailQuery ✓
  POST /api/v1/[feature]       → use[Feature].createMutate ✓
```

---

## Path B: Data Schema Extension

> Hook Layer가 전부 `REUSE`이고, `apis/model/` 또는 `utils/variables.ts`가 `MODIFY`일 때 실행합니다.
> 기존 API 엔드포인트는 동일하지만 새 데이터 타입/enum/모델이 추가되는 케이스입니다.

### Phase B1: 변경 대상 파일 목록 수집

planner.md의 File Structure에서 `MODIFY` 태그된 파일들을 수집합니다:

```
예시:
  apis/model/adProductModel.ts  ← MODIFY (레이아웃 인터페이스 추가)
  utils/variables.ts            ← MODIFY (enum 추가)
  ad-configuration.variable.ts  ← MODIFY (매핑 추가)
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
1. `utils/variables.ts` Read
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
1. 대상 모델 파일 Read (`apis/model/*.ts`)
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
1. 모델 팩토리 함수 Read
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
1. 대상 variable 파일 Read
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

---

## Path C: 혼합 (A + B)

> Hook Layer에 `NEW`와 `REUSE`가 혼합되고, 동시에 모델/변수 파일이 `MODIFY`일 때 실행합니다.

1. **먼저 Path B 실행** — 기존 데이터 구조 확장 (enum, interface, model, 상수)
2. **그다음 Path A 실행** — 새 훅 생성 (확장된 타입을 import하여 사용)

이 순서가 중요합니다: 새 훅이 확장된 타입에 의존하기 때문입니다.

---

## 공통 주의사항

- API 타입은 훅 파일에 co-locate (별도 `types/` 폴더 생성 금지) — Path A에만 해당
- API path 상수는 export (wrapper hook과 테스트에서 재사용)
- 목록 페이지는 항상 2-layer (Query Hook + Wrapper Hook)
- 단순 셀렉트/드롭다운 옵션 조회는 Query Hook만으로 충분
- `refetchOnWindowFocus: false` 기본 설정
- Apidog MCP 사용 불가 시 → planner.md의 API 경로 주석과 기존 코드베이스 패턴으로 fallback
- `$ref` 조회 시 여러 경로를 배열로 전달하여 한 번에 조회 (호출 횟수 최소화)
- Path B에서는 기존 코드를 **확장만** 하고 기존 구조를 변경하지 않습니다
- Edit 시 `replace_all: false`로 정확한 위치에만 삽입합니다
