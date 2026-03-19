---
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, mcp__figma-dev-mode-mcp-server__get_metadata, mcp__figma-dev-mode-mcp-server__get_screenshot, mcp__figma-dev-mode-mcp-server__get_code
argument-hint: [--ui|--api|--all] [planner.md 경로] [figma-url|image-path] [--mock]
description: "구현 커맨드 — --ui: UI 컴포넌트, --api: React Query 훅, --all: 둘 다. planner.md 기반으로 동작합니다."
model: claude-sonnet-4-6
---

# Unified Design-to-Code Implementation

Implements production-ready React components from Figma design or screenshots, following all project conventions. **Auto-detects** URL state needs from planner.md's `## URL State` section.

- If planner says **"Needed: Yes"** → uses `useUrlQuery` hook for pagination/sort/filter in URL
- If planner says **"Needed: No"** → uses regular state management (useState, Zustand, React Query)

## Arguments & Flag Routing

### 플래그별 동작 (가장 먼저 파싱)

| 플래그 | 동작 |
|--------|------|
| `--ui` | UI 컴포넌트만 생성 (이 커맨드 실행) |
| `--api` | React Query 훅만 생성 → `api-integration` 스킬로 위임 |
| `--all` | `--api` 먼저 실행 → 완료 후 `--ui` 실행 |
| (없음) | `--ui` 와 동일하게 동작 |

**`--api` 또는 `--all` 처리:**
```
--api  → api-integration 스킬 가이드를 로드하여 훅 생성 후 종료
--all  → api-integration 스킬로 훅 생성 → 완료 후 아래 UI 구현 Phase 진행
```

### 나머지 인수

- **planner.md 경로** (필수): `pageComponents/[feature]/planner.md`
- `--mock` (선택): API 미완성 시 mock 데이터로 구현. 어느 위치에 넣어도 됨
- **Figma URL** (선택): `http`로 시작하는 인수
- **이미지 경로** (선택): `.png`, `.jpg` 등 파일 경로
- **구현 컨텍스트** (선택): 마지막 문자열 인수 (MD 파일, URL, 이미지 경로 아닌 것)

---

## Phase 0: Plan Analysis

**CRITICAL: Read planner.md first**

1. Identify planner.md path from arguments (second-to-last or last argument ending in .md)
2. Read the planner.md file
3. Extract from planner.md:
   - Component hierarchy and structure
   - File organization plan
   - Data types and interfaces
   - API endpoints
   - Component responsibilities and props specifications
   - State management approach
   - Special requirements or notes

4. **Check the `## URL State` section** (planner.md가 생성하는 섹션명):
   - If `**Needed**: Yes` → set `URL_STATE_MODE = true`, extract the schema table
   - If `**Needed**: No` → set `URL_STATE_MODE = false`, skip URL params setup

5. Use planner.md as the **PRIMARY SOURCE** for directory structure, file names, component names, type definitions, implementation approach

---

## Phase 1: Design Analysis

**If Figma URL provided ($1 starts with http):**
1. Extract node ID from Figma URL ($1)
2. Use Figma MCP tools to gather:
   - `get_metadata` - Component structure and hierarchy
   - `get_screenshot` - Visual reference
   - `get_code` - Design tokens, spacing, colors, typography
3. Cross-reference Figma design with planner.md structure
4. Identify any discrepancies between plan and design

**If image file paths provided (arguments before planner.md path):**
1. Use the Read tool to view each design screenshot
2. Analyze multiple screens if provided (e.g., different states, responsive views)
3. Extract from images:
   - Visual hierarchy (sections, groups, atomic elements)
   - Interactive elements (buttons, inputs, expandable sections, modals)
   - Spacing, colors, typography, layout patterns
   - Different states (loading, error, empty, success) if shown
4. Cross-reference image design with planner.md structure
5. Identify any discrepancies between plan and design

---

## Phase 2: Context Understanding

**CRITICAL: Check shadcn/ui components FIRST**
Before implementing any component, check `packages/ui/src/components/ui/` for existing components:

- ✅ **Available components**: accordion, badge, button, calendar, carousel, checkbox, dialog, drawer, form, input, input-password, input-textarea, label, label-badge, notice-text, point-badge, popover, progress, radio-group, rank-checkbox, select, separator, seperator-dot, skeleton, slider, spinner, switch, tabs, textarea, tooltip, upload, sonner
- ✅ **MUST use these** instead of building custom components
- ✅ Import from `@/components/ui/[component-name]` (e.g., `@/components/ui/button`)

Read and apply rules from memory files:
- Project structure from CLAUDE.md
- Naming conventions from CONVENTIONS.md
- Existing similar components for consistency

Parse optional implementation context (last argument) for additional requirements.

---

## Phase 3: URL Params Setup (skip if `URL_STATE_MODE = false`)

### Ensure `useUrlQuery` Hook Exists

Check if `hooks/useUrlQuery.ts` exists.

**If missing, create it with the following implementation:**

```typescript
// hooks/useUrlQuery.ts
import { useCallback, useMemo, useRef } from "react";
import { useRouter } from "next/router";

// --- Types ---

type QueryValueType = string | string[];

type SerializerType<T> = {
  serialize: (value: T) => QueryValueType;
  deserialize: (value: QueryValueType) => T;
};

type UrlQueryConfigType<T> = {
  defaultValue: T;
  serializer?: SerializerType<T>;
};

type UrlQuerySchemaType = Record<string, UrlQueryConfigType<any>>;

type UrlQueryValuesType<S extends UrlQuerySchemaType> = {
  [K in keyof S]: S[K]["defaultValue"];
};

/** Passthrough: schema에 없는 키도 primitive 값으로 URL에 쓸 수 있음 */
type PassthroughUpdates = Record<
  string,
  string | number | boolean | string[] | null | undefined
>;

type UrlQueryReturnType<S extends UrlQuerySchemaType> = {
  urlQuery: UrlQueryValuesType<S>;
  setUrlQuery: (
    updates: Partial<UrlQueryValuesType<S>> & PassthroughUpdates
  ) => void;
  resetUrlQuery: () => void;
};

// --- Default Serializers (primitive types) ---

const DEFAULT_SERIALIZERS: Record<string, SerializerType<any>> = {
  string: {
    serialize: (v: string) => v,
    deserialize: (v: QueryValueType) => (Array.isArray(v) ? v[0] ?? "" : v),
  },
  number: {
    serialize: (v: number) => String(v),
    deserialize: (v: QueryValueType) =>
      Number(Array.isArray(v) ? v[0] ?? "0" : v),
  },
  boolean: {
    serialize: (v: boolean) => String(v),
    deserialize: (v: QueryValueType) =>
      (Array.isArray(v) ? v[0] ?? "false" : v) === "true",
  },
};

// --- Array Serializer (repeated query keys: ?key=a&key=b) ---

const getArraySerializer = <T>(defaultValue: T[]): SerializerType<T[]> => {
  const sample = defaultValue[0];
  const itemType = sample !== undefined ? typeof sample : "string";

  if (itemType === "number") {
    return {
      serialize: (v: T[]) => v.map(String),
      deserialize: (v: QueryValueType) =>
        (Array.isArray(v) ? v : [v]).map(Number) as T[],
    };
  }

  // Default: string array
  return {
    serialize: (v: T[]) => v.map(String),
    deserialize: (v: QueryValueType) => (Array.isArray(v) ? v : [v]) as T[],
  };
};

// --- Comma-Separated Serializer (single key: ?key=a,b,c) ---

export const commaSeparatedSerializer = {
  string: {
    serialize: (v: string[]) => v.join(","),
    deserialize: (v: QueryValueType) => {
      const raw = Array.isArray(v) ? v[0] ?? "" : v;
      return raw ? raw.split(",") : [];
    },
  } as SerializerType<string[]>,
  number: {
    serialize: (v: number[]) => v.map(String).join(","),
    deserialize: (v: QueryValueType) => {
      const raw = Array.isArray(v) ? v[0] ?? "" : v;
      return raw ? raw.split(",").map(Number) : [];
    },
  } as SerializerType<number[]>,
};

// --- Serializer Resolution ---

const getSerializer = <T>(
  defaultValue: T,
  custom?: SerializerType<T>
): SerializerType<T> => {
  if (custom) {
    return custom;
  }

  if (Array.isArray(defaultValue)) {
    return getArraySerializer(defaultValue) as unknown as SerializerType<T>;
  }

  const type = typeof defaultValue;
  if (type in DEFAULT_SERIALIZERS) {
    return DEFAULT_SERIALIZERS[type];
  }

  // Fallback: JSON serialization for objects
  return {
    serialize: (v: T) => JSON.stringify(v),
    deserialize: (v: QueryValueType) => {
      const raw = Array.isArray(v) ? v[0] ?? "" : v;
      return JSON.parse(raw) as T;
    },
  };
};

// --- Deep Equality (key-order independent for objects) ---

const isEqual = (a: unknown, b: unknown): boolean => {
  if (a === b) {
    return true;
  }
  if (a == null || b == null) {
    return false;
  }
  if (Array.isArray(a) && Array.isArray(b)) {
    return a.length === b.length && a.every((v, i) => isEqual(v, b[i]));
  }
  if (typeof a === "object" && typeof b === "object") {
    const objA = a as Record<string, unknown>;
    const objB = b as Record<string, unknown>;
    const keysA = Object.keys(objA);
    const keysB = Object.keys(objB);
    if (keysA.length !== keysB.length) {
      return false;
    }
    return keysA.every((key) => key in objB && isEqual(objA[key], objB[key]));
  }
  return false;
};

// --- Passthrough Serializer (schema에 없는 키) ---

const serializePassthrough = (
  value: string | number | boolean | string[]
): QueryValueType => {
  if (Array.isArray(value)) {
    return value.map(String);
  }
  return String(value);
};

// --- Hook ---

export const useUrlQuery = <S extends UrlQuerySchemaType>(
  schema: S
): UrlQueryReturnType<S> => {
  const router = useRouter();

  const schemaRef = useRef(schema);
  schemaRef.current = schema;

  const routerRef = useRef(router);
  routerRef.current = router;

  const pendingQueryRef = useRef<Record<
    string,
    string | string[] | undefined
  > | null>(null);
  const pushCountRef = useRef(0);

  const urlQuery = useMemo(() => {
    const state = {} as UrlQueryValuesType<S>;
    const { query } = router;

    for (const key of Object.keys(schemaRef.current)) {
      const config = schemaRef.current[key];
      const serializer = getSerializer(config.defaultValue, config.serializer);
      const rawValue = query[key];

      if (rawValue !== undefined) {
        try {
          (state as any)[key] = serializer.deserialize(rawValue);
        } catch {
          (state as any)[key] = config.defaultValue;
        }
      } else {
        (state as any)[key] = config.defaultValue;
      }
    }

    return state;
  }, [router.query]);

  const setUrlQuery = useCallback(
    (updates: Partial<UrlQueryValuesType<S>> & PassthroughUpdates) => {
      const currentQuery = {
        ...(pendingQueryRef.current ?? routerRef.current.query),
      };

      for (const key of Object.keys(updates)) {
        const config = schemaRef.current[key];
        const newValue = (updates as any)[key];

        // null/undefined → remove from URL
        if (newValue == null) {
          delete currentQuery[key];
          continue;
        }

        if (!config) {
          // Passthrough: schema에 없는 키는 그대로 직렬화하여 URL에 반영
          currentQuery[key] = serializePassthrough(newValue);
          continue;
        }

        const serializer = getSerializer(
          config.defaultValue,
          config.serializer
        );

        if (isEqual(newValue, config.defaultValue)) {
          delete currentQuery[key];
        } else {
          currentQuery[key] = serializer.serialize(newValue);
        }
      }

      pendingQueryRef.current = currentQuery;
      const currentPushCount = ++pushCountRef.current;

      routerRef.current
        .push(
          { pathname: routerRef.current.pathname, query: currentQuery },
          undefined,
          { shallow: true }
        )
        .then(() => {
          if (pushCountRef.current === currentPushCount) {
            pendingQueryRef.current = null;
          }
        });
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    []
  );

  const resetUrlQuery = useCallback(() => {
    const currentQuery = {
      ...(pendingQueryRef.current ?? routerRef.current.query),
    };

    for (const key of Object.keys(schemaRef.current)) {
      delete currentQuery[key];
    }

    pendingQueryRef.current = currentQuery;
    const currentPushCount = ++pushCountRef.current;

    routerRef.current
      .push(
        { pathname: routerRef.current.pathname, query: currentQuery },
        undefined,
        { shallow: true }
      )
      .then(() => {
        if (pushCountRef.current === currentPushCount) {
          pendingQueryRef.current = null;
        }
      });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return { urlQuery, setUrlQuery, resetUrlQuery };
};
```

**Key capabilities:**
- `string`, `number`, `boolean` — auto-detected from `defaultValue`
- Array (repeated keys: `?key=a&key=b`) — use `defaultValue: [] as string[]`
- Comma-separated (`?key=a,b,c`) — use `serializer: commaSeparatedSerializer.string`
- Passthrough: schema에 없는 키도 `setUrlQuery`로 URL에 직접 쓸 수 있음
- Default values omitted from URL; race-condition-safe writes

### Design URL State Schema
Translate planner.md's URL State schema table into code:

```typescript
import { commaSeparatedSerializer } from '@/hooks/useUrlQuery';

const URL_STATE_SCHEMA = {
  page: { defaultValue: 1 },
  size: { defaultValue: 25 },
  sortColumn: { defaultValue: '' },
  sortType: { defaultValue: '' },
  q: { defaultValue: '' },
  // Array: repeated keys (?d=A&d=B)
  dimensions: { defaultValue: [] as string[] },
  // Comma-separated (?ids=1,2,3)
  'target-ids': { defaultValue: [] as number[], serializer: commaSeparatedSerializer.number },
} as const;
```

---

## Phase 4: File Planning

**Use planner.md structure as the foundation**

Follow the file structure defined in planner.md:
- Respect planned directory organization
- Use planned file names exactly as specified
- Follow component hierarchy from plan
- Implement types and interfaces as planned

**Structure is determined by the design — not by a fixed template.** Use planner.md as the source of truth.

```
pageComponents/feature-name/
├── feature-name.types.ts
├── FeatureContainer.tsx               # layout only
├── components/
│   └── [components based on design]  # determined by planner.md
└── hooks/
    ├── useFeatureQuery.hook.ts        # thin wrapper: only returns useQuery
    └── useFeaturePage.hook.ts         # optional: only create when Container grows complex
```

### Co-location Rules (MUST FOLLOW)

**Principle: Keep related code close to where it is used. Only promote to global when actual reuse occurs.**

| Question | Placement |
|----------|-----------|
| Used only in this feature? | → Place inside `pageComponents/[feature]/` |
| Used across multiple features? | → Place in global (`utils/`, `hooks/`, `components/`) |
| Only one feature now, but might be shared later? | → **Keep in feature folder first, promote to global only when actual reuse happens** |

**Placement by file type:**

| File Type | Feature-specific | Global shared |
|-----------|-----------------|---------------|
| Table column definitions | `pageComponents/[feature]/components/table/featureTable.column.ts` | `components/table/commonTable.column.ts` |
| Utility functions | `pageComponents/[feature]/utils/feature.utils.ts` | `utils/format.utils.ts` |
| Custom Hooks | `pageComponents/[feature]/hooks/useFeature.hook.ts` | `hooks/useCommon.hook.ts` |
| Constants/enums | `pageComponents/[feature]/feature.constants.ts` | `constants/common.constants.ts` |
| Type definitions | `pageComponents/[feature]/feature.types.ts` | `types/common.type.ts` |

**Example — Table column definitions:**

```typescript
// ✅ Feature-specific: pageComponents/product/components/table/product-table-columns.ts
export const PRODUCT_TABLE_COLUMN_LIST = [
  { key: 'name', label: 'Product Name', width: 200 },
  { key: 'status', label: 'Status', width: 100 },
];

// ✅ Global shared (column renderers reused across multiple features):
// components/table/common-columns.ts
export const renderStatusBadge = (status: string) => { /* ... */ };
```

---

## Phase 5: Implementation

### Naming Rules (MUST FOLLOW):

- **Component files**: PascalCase (`GiftProductInfo.tsx`)
- **Helper files**: camelCase + dot suffix (`giftProduct.type.ts`, `giftProductTable.column.ts`)
- **Interfaces**: `I` prefix (`IGiftProductInfoProps`)
- **Types**: `Type` suffix (`GiftOrderResponseType`)
- **Collections**: postfix (`itemList`, `userMap`, `tagSet`)
- **Booleans**: `is`/`are` prefix (`isExpanded`, `areItemsLoaded`)
- **Handlers**: `handle` prefix (`handleClick`, `handleSubmit`)
- **Constants**: `UPPER_CASE` (`API_BASE_URL`, `MAX_ITEMS`)

### Component Structure (MUST FOLLOW):

**Props Interface Rules**:
- **5 or fewer props**: Use inline type definition (NO separate interface)
- **6 or more props**: Extract to separate interface above component

Example with **6 or more props**:

```typescript
import { useState } from 'react';
import type { IGiftOrder } from '../types';

interface IComponentProps {
  data: IGiftOrder;
  isLoading?: boolean;
  onSubmit?: () => void;
  title?: string;
  description?: string;
  className?: string;
}

export const ComponentName = ({ data, isLoading = false }: IComponentProps) => {
  // Hook order: useStore/useState → useRef/useMemo → useCallback/useEffect → functions
  const [isExpanded, setIsExpanded] = useState(false);

  const handleClick = () => {
    setIsExpanded(!isExpanded);
  };

  if (isLoading) {
    return <div>Loading...</div>;
  }

  return (
    <div className="flex flex-col gap-[1.25rem]">
      {/* Component JSX */}
    </div>
  );
};
```

### React Optimization (MUST FOLLOW):

**`memo()` — Prevent unnecessary component re-renders:**

- **Export pattern**: `export default memo(ComponentName);` (separate at end of file)
- **Most effective**: No props → `memo` always blocks parent re-renders (shallow comparison finds zero differences)
- Use when: Props are stable and parent re-renders frequently (list items, table rows, etc.)
- Do NOT use when: Props are recreated every render, or component is simple
- If planner.md specifies **Memo: Yes/No**, follow it exactly

```typescript
// ✅ Use memo — list item with stable props
const ProductTableRow = ({ product }: { product: IProduct }) => {
  return <tr>...</tr>;
};

export default memo(ProductTableRow);
```

**`useMemo` — Cache expensive computations:**

- Use when: Large array filtering/sorting, complex data transformations, column definition generation
- Do NOT use when: Simple variable assignment, primitive values, JSX creation
- Always specify dependency array precisely

```typescript
// ✅ useMemo — prevent column definitions from being recreated every render
const columnList = useMemo(() => [
  { key: 'name', label: 'Name', width: 200 },
  { key: 'status', label: 'Status', width: 100, cell: renderStatusBadge },
], []);

// ✅ useMemo — filtered data
const filteredList = useMemo(
  () => dataList.filter((item) => item.status === selectedStatus),
  [dataList, selectedStatus],
);

// ❌ useMemo unnecessary — simple value
const isDisabled = useMemo(() => !name, [name]); // just use: const isDisabled = !name;
```

**`useCallback` — Stabilize function references:**

- Use when: Passing handler to `memo()`-wrapped child, or function used in dependency array
- Do NOT use when: Simple inline handler in JSX, or child is NOT wrapped with `memo()`
- Skip `useCallback` when it provides no benefit

```typescript
// ✅ useCallback — passed to memo-wrapped child
const handleRowClick = useCallback((id: string) => {
  router.push(`/product/${id}`);
}, [router]);

<ProductTableRow onClick={handleRowClick} /> // ProductTableRow is wrapped with memo()

// ❌ useCallback unnecessary — child is not memo-wrapped
const handleClick = useCallback(() => setIsOpen(true), []); // just use arrow function
```

### shadcn/ui Component Usage (HIGHEST PRIORITY):

**Priority order: Use shadcn/ui first, then rsuite if needed**

Common use cases:
- **Buttons**: `Button` from `@/components/ui/button`
- **Forms**: `Form`, `FormField`, `FormItem`, `FormLabel`, `FormControl` from `@/components/ui/form`
- **Inputs**: `Input`, `Textarea` from `@/components/ui/input`
- **Dialogs/Modals**: `Dialog`, `Drawer` from `@/components/ui/dialog`
- **Expandable sections**: `Accordion` from `@/components/ui/accordion` (NOT custom state)
- **Badges**: `Badge` from `@/components/ui/badge`
- **Loading states**: `Skeleton` from `@/components/ui/skeleton`
- **Navigation**: `Tabs` from `@/components/ui/tabs`
- **Tooltips**: `Tooltip`, `Popover` from `@/components/ui/tooltip`
- **Selections**: `Checkbox`, `RadioGroup`, `Select`, `Switch` from their respective `@/components/ui/` paths

**rsuite components** (use when shadcn/ui doesn't have the needed component):
```typescript
import { Panel, Stack, Grid, Row, Col, Table } from "rsuite";
```

### Styling Rules (MUST FOLLOW):

**Design System Tokens**:
- Colors: `text-primary`, `text-secondary`, `text-tertiary`, `text-disabled`
- Backgrounds: `bg-white`, `bg-off-white`, `bg-primary`
- Typography: `text-header-01`, `text-subtitle-01-600`, `text-body-02-400`
- Borders: `border-divider-primary`, `border-divider-secondary`

**Spacing**: Use `rem` units — `gap-[1.25rem]`, `p-[1.875rem]`. Never use `px`.

**Images**: Use Next.js `Image` component with `fill`, `alt`, and `sizes` props.

```typescript
import Image from 'next/image';

<div className="relative h-10 w-10">
  <Image src={imageUrl} fill alt="Description" className="object-cover" sizes="(max-width: 768px) 100vw, 50vw" />
</div>
```

**DO NOT**:
- ❌ Use `cn` function
- ❌ Use `<img>` tag (use Next.js `Image` component)
- ❌ Use nested ternaries (use if/else or ts-pattern)
- ❌ Use arbitrary colors (#fff, gray-500)
- ❌ Build custom components when shadcn/ui has them

### API Integration (Co-located in Hook Files):

**Define API path, API functions, and React Query hooks together in the same hook file.**

```typescript
// pageComponents/[feature]/hooks/useFeatureQuery.hook.ts
import { useQuery, useMutation } from '@tanstack/react-query';
import axios from '@/apis';
import queryString from 'query-string';

// API path — defined in hook file
const featureApiPath = '/api/v1/features';

// API function — defined in hook file
const getFeatureList = async (params: IFeatureQueryParams) => {
  const query = queryString.stringify(params, { skipEmptyString: true, skipNull: true });
  return await axios.get(`${featureApiPath}?${query}`);
};

// Query hook
export const useFeatureQuery = (params: IFeatureQueryParams) => {
  return useQuery({
    queryKey: [featureApiPath, params],
    queryFn: () => getFeatureList(params),
    refetchOnWindowFocus: false,
  });
};

// Mutation hook
export const useFeatureMutation = () => {
  return useMutation({
    mutationFn: async (data: IFeatureInput) => {
      return await axios.post(featureApiPath, data);
    },
  });
};
```

**DO NOT** create separate `services/` directories or add to `apis/service/` — keep API logic co-located in hook files.

---

## Phase 5-A: URL Params Integration (skip if `URL_STATE_MODE = false`)

**Each component reads and writes URL directly** via `useUrlQuery`. Do NOT centralize URL reads in Container and pass values down as props. Do NOT use Zustand session stores for pagination/sort/filter.

**Cross-cutting validation** (e.g. param change → dependent param reset): Handle **synchronously in the component that triggers the change** (e.g. Filter's `handleSearch`), not via `useEffect` in Container. Use Container `useEffect` only as a last resort.

```typescript
// ✅ Each component owns its URL params
const FeatureFilter = () => {
  const { urlQuery, setUrlQuery } = useUrlQuery(URL_SCHEMA);
  // reads: startDate, endDate / writes on search button click
  const handleSearch = () => setUrlQuery({ startDate: ..., endDate: ..., page: 1 });
};

const FeatureTable = () => {
  const { urlQuery, setUrlQuery } = useUrlQuery(URL_SCHEMA);
  // reads: page, size, sortColumn, sortType / writes on sort/paginate
  const { data, isFetching } = useFeatureQuery({
    page: urlQuery.page,
    size: urlQuery.size,
    sortColumn: urlQuery.sortColumn,
    sortType: urlQuery.sortType,
    startDate: urlQuery.startDate,
    endDate: urlQuery.endDate,
  });

  const handlePageChange = (page: number) => setUrlQuery({ page });
  const handleSizeChange = (size: number) => setUrlQuery({ size, page: 1 });
  const handleSort = (col: string, type: string) => setUrlQuery({ sortColumn: col, sortType: type, page: 1 });
};

// ✅ Container: layout only, no useEffect
// Children read URL directly — do NOT pass urlQuery as props
const FeatureContainer = () => {
  return (
    <>
      {/* components determined by planner.md */}
    </>
  );
};
```

**What to pass as props vs not:**

| Data | How |
|------|-----|
| URL values (`page`, `startDate`, ...) | each component calls `useUrlQuery` directly |
| URL-derived values (constant lookups) | each component computes directly from URL (no prop needed) |
| Local UI state (`isOpen`, `onClose`) | pass as props ✅ |

**URL Behavior Rules:**
1. Initial load: Clean URL, no query params — defaults used internally
2. Only non-default values appear in URL (`page=1` is default → NOT in URL)
3. Filter/size changes reset page to 1
4. Direct URL access with params restores full state
5. Browser back/forward preserved via shallow routing
6. No Zustand session store for URL-synced state

**Page hook (optional):** If Container grows too complex, extract logic to `useFeaturePage.hook.ts`. For simple cases, write directly in Container.

---

## Phase 5-B: Mock Data (skip if `--mock` not present)

When `--mock` is present, hook files return mock data instead of real API calls.

**Rules:**
1. Same hook file, export name, and return type — structure identical to real version
2. Mock data as constant above hook function (15~30 realistic rows from planner.md types)
3. React Query still used — `queryFn` returns mock data
4. Pagination, sorting, filtering work client-side on mock array
5. Mark with `// TODO: Replace with real API call`

```typescript
// TODO: Replace with real API call
const MOCK_DATA: IFeatureRow[] = [
  { id: 1, name: 'Feature A', status: 'active', count: 150 },
  // ... 15~30 rows
];

export const useFeatureQuery = (params: { page: number; size: number }) => {
  return useQuery({
    queryKey: [FEATURE_API_PATH, params],
    // TODO: Replace with real API call
    queryFn: async () => {
      const start = (params.page - 1) * params.size;
      return { content: MOCK_DATA.slice(start, start + params.size), total_elements: MOCK_DATA.length };
    },
    refetchOnWindowFocus: false,
  });
};
```

---

## Phase 6: Code Generation

For each component:

1. **Create directory structure** with `mkdir -p`
2. **Generate files in order**:
   - Types file
   - Hook files (or mock hooks if `--mock`)
   - Component files (parent to child)
   - Page file (last)

3. **Follow conventions**:
   - Destructure props: `const { title, items } = props`
   - Arrow functions for components
   - Separate default export
   - Add comments only for complex logic

4. **Use TodoWrite** to track implementation progress

---

## Phase 7: Verification & Testing

**CRITICAL: Verify implementation matches design**

1. **Visual comparison**:
   - Compare implementation with Figma design screenshot from Phase 1
   - Verify spacing, colors, typography, and layout match exactly
   - Ensure all design tokens are correctly applied

2. **Code review**:
   - Check all shadcn/ui components are used where applicable
   - Verify naming conventions are followed
   - Ensure proper component structure and hook order
   - Validate TypeScript types match planner.md

3. **URL params verification** (only when `URL_STATE_MODE = true`):
   - Initial page load has clean URL (no query params)
   - Changing page/size/sort adds correct params to URL
   - Filter changes reset page
   - Direct URL access with params restores full state
   - No Zustand session store used for URL-synced state

4. **Manual testing recommendations**:
   - Test responsive behavior across breakpoints
   - Verify all interactive elements work correctly
   - Check form validations and error states

---

## Context Priority (Highest to Lowest)

1. **planner.md** — Component structure, files, types, URL state schema
2. **Implementation context** (last arg) — Additional requirements
3. **CLAUDE.md / CONVENTIONS.md** — Project rules and coding standards
4. **Figma/image design** — Visual specifications
5. **Common React patterns** — Framework best practices

**IMPORTANT**: Always defer to planner.md for structural decisions. Use design sources for visual styling only.

---

## Quality Checklist

Before completing, verify:

**planner.md Compliance**:
- ✅ All files and directories match plan
- ✅ All components implemented as specified
- ✅ All interfaces and types match planner.md
- ✅ Component props match specifications

**Component & Code Quality**:
- ✅ shadcn/ui components used from `@repo/ui` (HIGHEST PRIORITY)
- ✅ Naming conventions followed (kebab-case files, PascalCase components, I prefix, Type suffix)
- ✅ Design system tokens used (no arbitrary colors, rem units)
- ✅ No `cn()`, no nested ternaries, no `<img>` tag

**Co-location**:
- ✅ Feature-specific code (columns, utils, hooks, types) placed inside `pageComponents/[feature]/`
- ✅ Only truly shared code placed in global `utils/`, `hooks/`, `components/`
- ✅ No premature extraction to global — promote only when actual reuse occurs

**React Optimization**:
- ✅ Follows planner.md Memo specification (Yes → `export default memo(Component)`)
- ✅ `useMemo` — used for expensive computations, column definitions, filtered lists
- ✅ `useCallback` — used for handlers passed to `memo()`-wrapped children
- ✅ No unnecessary optimization (simple values, non-memo children)

**URL Params** (only when `URL_STATE_MODE = true`):
- ✅ URL schema matches planner.md's URL Params table
- ✅ No Zustand session store for pagination/sort/filter
- ✅ Default values NOT in URL on initial load
- ✅ Page resets to 1 when filter/size changes
- ✅ Direct URL access restores full state

---

## Output Format

Provide:

1. **planner.md compliance** — Confirmation that all plan specifications were followed
2. **URL State mode** — Whether URL state was applied and why (from planner.md)
3. **Summary** of files created with their purposes
4. **Component tree** showing implemented structure
5. **Key decisions** made during implementation
6. **Deviations** from planner.md (if any) with justification
7. **Next steps** (if any manual work needed)

---

## Usage Examples

```bash
# planner.md 기반 구현 (가장 일반적)
/code-writer --ui pageComponents/feature/planner.md

# API 미완성 시 mock 데이터로 구현
/code-writer --ui pageComponents/feature/planner.md --mock

# Figma URL 추가 참조
/code-writer --ui pageComponents/feature/planner.md "https://figma.com/design/abc?node-id=123-456"

# 스크린샷 참조
/code-writer --ui pageComponents/feature/planner.md "/path/to/design.png"

# 여러 스크린샷 + mock
/code-writer --ui pageComponents/feature/planner.md "/path/to/desktop.png" "/path/to/mobile.png" --mock

# 추가 구현 컨텍스트 전달
/code-writer --ui pageComponents/feature/planner.md "optimistic updates 적용"
```
