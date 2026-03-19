---
name: api-integration
description: Scalar MCP로 API 스펙을 조회하고 planner.md hooks 기반으로 React Query 훅과 TypeScript 타입을 일괄 생성합니다.
---

# API Integration (Scalar MCP 기반)

`planner.md`의 hooks 섹션을 분석하여 필요한 API를 파악하고, **Scalar MCP로 스펙을 조회**해 React Query 훅 파일을 생성합니다.

## 트리거

- `/code-writer --api` 호출 시
- `/code-writer --all` 호출 시 (Phase 1)

## 입력 컨텍스트

- `planner.md` 내용 (hooks 섹션 중심)
- Jira AC 목록 (있을 경우)
- 프로젝트 루트 경로

---

## Phase 1: planner.md에서 API 목록 추출

planner.md의 `Data Fetching` 섹션에서 훅 목록 추출:

```
useXxxQuery(params) → GET /api/v1/xxx
useYyyQuery(id)     → GET /api/v1/yyy/{id}
useZzz()            → wrapper hook (mutation 포함)
```

추출 규칙:
- `use*Query` → API Query Hook (Scalar에서 스펙 조회 필요)
- `use*` (wrapper) → Business Logic Hook (Query Hook 래핑)
- 목록 페이지는 항상 2-layer (useXxxQuery + useXxx)

---

## Phase 2: Scalar MCP로 API 스펙 일괄 조회

> ⚠️ Scalar MCP 툴 이름 확인 필요: `mcp__scalar__*` 형태로 설정된 MCP 사용

각 Query Hook에 대해 Scalar MCP로 스펙 조회:

```
useUsersQuery    → GET /api/v1/users    스펙 조회
useMastersQuery  → GET /api/v1/masters  스펙 조회
useCompaniesQuery → GET /api/v1/companies 스펙 조회
```

각 엔드포인트에서 추출:
- **Request**: query params, path params, request body schema
- **Response**: response schema (data 구조, pagination 구조)
- **HTTP method**: GET/POST/PUT/DELETE
- **인증**: 필요 여부

---

## Phase 3: 기존 훅 패턴 파악

```
Glob: pageComponents/**/hooks/*.hook.ts
최근 2-3개 파일 Read → import 방식, 타입 패턴, axios 인스턴스 확인
```

공통 패턴 확인:
- axios import 경로 (`@/apis` 등)
- QueryClient import 방식
- API path 상수 정의 방식
- pagination 응답 구조 (meta? data? total?)

---

## Phase 4: 훅 파일 일괄 생성

### 파일 위치
```
pageComponents/[feature]/hooks/use[Feature]Query.hook.ts  ← API query hook
pageComponents/[feature]/hooks/use[Feature].hook.ts       ← wrapper hook (필요 시)
```

### Layer 1: API Query Hook 템플릿

```typescript
// pageComponents/[feature]/hooks/use[Feature]Query.hook.ts
import { useQuery } from '@tanstack/react-query'
import axios from '@/apis'

// ---- Types (Scalar 스펙 기반으로 생성) ----
export interface I[Feature]Item {
  id: string
  // ... Scalar 스펙의 response schema 필드들
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
  // ... Scalar 스펙의 query params
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

### Layer 2: Wrapper Hook 템플릿 (목록 페이지 - 항상 필요)

```typescript
// pageComponents/[feature]/hooks/use[Feature].hook.ts
import { useMutation, useQueryClient } from '@tanstack/react-query'
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

### 단건 조회 훅 템플릿

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

---

## Phase 5: 타입 변환 규칙 (Scalar 스펙 → TypeScript)

| Scalar/OpenAPI 타입 | TypeScript 타입 |
|---|---|
| `string` | `string` |
| `integer`, `number` | `number` |
| `boolean` | `boolean` |
| `array` | `T[]` |
| `object` | `interface` 분리 |
| nullable field | `T \| null` |
| optional field | `T?` |

---

## Phase 6: 생성 결과 확인

생성된 훅 목록 출력:
```
✅ API Integration 완료

생성된 파일:
  pageComponents/[feature]/hooks/use[Feature]Query.hook.ts
  pageComponents/[feature]/hooks/use[Feature].hook.ts

API 연동 목록:
  GET /api/v1/[feature]        → use[Feature]Query ✓
  GET /api/v1/[feature]/{id}   → use[Feature]DetailQuery ✓
  POST /api/v1/[feature]       → use[Feature].createMutate ✓
```

---

## 주의사항

- API 타입은 훅 파일에 co-locate (별도 `types/` 폴더 생성 금지)
- API path 상수는 export (wrapper hook과 테스트에서 재사용)
- 목록 페이지는 항상 2-layer (Query Hook + Wrapper Hook)
- 단순 셀렉트/드롭다운 옵션 조회는 Query Hook만으로 충분
- `refetchOnWindowFocus: false` 기본 설정
- Scalar MCP 사용 불가 시 → planner.md의 API 경로 주석과 기존 코드베이스 패턴으로 fallback
