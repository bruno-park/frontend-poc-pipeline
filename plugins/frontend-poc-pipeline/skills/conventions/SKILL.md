---
name: conventions
description: 프로젝트 공통 컨벤션 레퍼런스 — 다른 스킬에서 참조용. 직접 실행 시 전체 컨벤션 출력.
---

# Frontend Project Conventions

프로젝트 전반에서 사용하는 공통 컨벤션 레퍼런스입니다.
다른 스킬(`/planner`, `/code-writer`, `/refactor` 등)에서 이 문서를 참조합니다.

---

## 1. Directory Structure Rules

- **Feature-first organization**: 타입이 아닌 기능 단위로 그룹핑
- **Co-location**: 관련 파일을 가까이 배치 (components, actions, hooks, utils)
- **Atomic Design**: 복잡도에 따라 분류
  - Atoms: 기본 UI 요소 (buttons, inputs, badges)
  - Molecules: 단순 조합 (search bar, card)
  - Organisms: 복합 섹션 (product info, notice section)

---

## 2. Naming Conventions

| 대상 | 규칙 | 예시 |
|------|------|------|
| **Folder** | kebab-case | `event-ranking` |
| **Helper files** | camelCase + dot suffix | `giftProduct.type.ts`, `giftProductTable.column.ts` |
| **Component files** | PascalCase | `GiftProductInfo.tsx` |
| **Components** | PascalCase + parent feature prefix | `EventRanking`, `MediaInventory` |
| **Props interfaces** | `I` prefix | `IEventRankingProps`, `IGiftProductInfoProps` |
| **Types** | `Type` suffix | `EventResponseType`, `GiftOrderResponseType` |
| **Collections** | postfix | `itemList`, `noticeMap`, `userMap`, `tagSet` |
| **Booleans** | `is` or `are` prefix | `isExpanded`, `isLoading`, `areItemsLoaded` |
| **Handlers** | `handle` prefix | `handleClick`, `handleSubmit` |
| **Constants** | `UPPER_CASE` | `API_BASE_URL`, `MAX_ITEMS` |

**Component prefix rule**: section 폴더 하위의 컴포넌트는 feature 이름을 prefix로 사용
- `pageComponents/event/components/ranking/EventRanking.tsx` → `EventRanking`
- `pageComponents/media/components/inventory/MediaInventory.tsx` → `MediaInventory`

---

## 3. File Organization (Pages Router)

**Rule: `pageComponents/` mirrors `pages/` route structure.**

```
# Flat route: pages/event/ → pageComponents/event/
pages/
  └── event/
        ├── index.tsx                   # Route page (/event)
        ├── [id].tsx                    # Dynamic route (/event/123)
        └── ranking.tsx                 # Nested route (/event/ranking)

pageComponents/
  └── event/
        ├── components/                 # Feature components
        │   ├── ranking/                # Section folder (self-contained)
        │   │   ├── EventRanking.tsx
        │   │   ├── EventRankingItem.tsx
        │   │   ├── EventRankingFilter.tsx
        │   │   ├── eventRanking.types.ts
        │   │   └── eventRanking.constants.ts
        │   ├── details/
        │   │   ├── EventDetails.tsx
        │   │   ├── EventDetailsTab.tsx
        │   │   ├── eventDetails.types.ts
        │   │   └── eventDetails.constants.ts
        │   └── common/                 # Components shared across multiple sections
        │       ├── EventSharedCard.tsx
        │       └── EventStatusBadge.tsx
        └── hooks/
            ├── useEventQuery.hook.ts
            └── useEvent.hook.ts
```

```
# Nested route: pages/management/product.tsx → pageComponents/management/product/
pageComponents/
  └── management/
        ├── _shared/                    # Shared across management sub-features
        │   ├── managementTable.utils.ts
        │   └── ManagementColumnSettingsModal.tsx
        ├── product/
        │   ├── planner.md
        │   ├── components/
        │   │   ├── filter/
        │   │   ├── table/
        │   │   └── column-settings/
        │   └── hooks/
        └── order/
            ├── planner.md
            ├── components/
            └── hooks/
```

### Path Matching Rules

- `pageComponents/` 구조는 `pages/` 라우트 구조를 **정확히** 미러링
- `pages/[a]/[b].tsx` → `pageComponents/[a]/[b]/`
- 라우트 경로와 다른 디렉토리 생성 금지 (e.g., `pages/report/daily.tsx` → `pageComponents/report/daily/`, NOT `pageComponents/dailyReport/`)

### Shared Folder Rules

- `common/`: 한 feature 내 2+ section 폴더가 공유하는 컴포넌트
- `_shared/`: 같은 도메인 내 sub-feature 간 공유 코드
- Global (`components/`, `hooks/`, `utils/`): 도메인 무관 전역 공유 코드

---

## 4. Inline Props/State in File Structure

planner.md 파일 구조 다이어그램에서 각 컴포넌트의 props/state를 인라인으로 표기:

```
├── FeatureContainer.tsx
│     props: none
│     state: searchValue
├── components/
│   ├── filter/
│   │   └── FeatureFilter.tsx
│   │         props: none
│   │         state: draftMonth
│   └── table/
│       └── FeatureTable.tsx
│             props: none
│             state: none (URL params via useUrlQuery)
```

**Rules**:
- prop 이름만 나열 (타입은 component details 섹션에)
- state: `useState` 변수명, URL state면 `useUrlQuery` 표시
- props/state 없으면 `"none"`
- `.tsx` 컴포넌트 파일만 표기 (constants/columns/hooks 제외)

---

## 5. Component Definition Pattern

**MUST use arrow functions + export default separately:**

```typescript
// ✅ CORRECT
const MyComponent = () => {
  return <div>Content</div>;
};

export default MyComponent;

// or with memo
export default memo(MyComponent);
```

```typescript
// ❌ INCORRECT
export default function MyComponent() {
  return <div>Content</div>;
}
```

### Props Interface Rules

- **5개 이하 props**: 인라인 타입 사용 (별도 interface 금지)
- **6개 이상 props**: 컴포넌트 위에 별도 interface 추출

```typescript
// 5개 이하 → 인라인
const Card = ({ title, onClick }: { title: string; onClick: () => void }) => { ... };

// 6개 이상 → interface 추출
interface ICardProps {
  title: string;
  description: string;
  imageUrl: string;
  onClick: () => void;
  onDelete: () => void;
  className?: string;
}

const Card = ({ title, description, imageUrl, onClick, onDelete, className }: ICardProps) => { ... };
```

### Hook Order Inside Components

```typescript
// Hook order: useStore/useState → useRef/useMemo → useCallback/useEffect → functions
const [isExpanded, setIsExpanded] = useState(false);
const listRef = useRef<HTMLDivElement>(null);
const filteredList = useMemo(() => ..., [deps]);
const handleClick = useCallback(() => ..., [deps]);
```

---

## 6. Component Type Guidelines (Pages Router)

**All components are Client Components** — Pages Router에서는 Server/Client 구분 없음.

### Data Fetching Strategy

- **Fetch data as deep (leaf) as possible** — 데이터를 사용하는 컴포넌트에서 직접 fetch
- Page 컴포넌트는 layout/composition 역할만
- 페이지 레벨 fetch 후 prop drilling 금지

### React Optimization

**`memo()`** — 불필요한 리렌더 방지:
- Export: `export default memo(ComponentName);` (파일 마지막에 별도)
- planner.md에 **Memo: Yes/No** 명시된 경우 그대로 따름
- Use when: props가 안정적이고 parent가 자주 리렌더
- Skip when: props가 매번 새로 생성되거나 컴포넌트가 단순

**`useMemo`** — 비싼 계산 캐싱:
- Use when: 배열 filter/sort, 복잡한 데이터 변환, 컬럼 정의 생성
- Skip when: 단순 값 할당, primitive 값

```typescript
// ✅ useMemo — column definitions
const columnList = useMemo(() => [
  { key: 'name', label: 'Name', width: 200 },
], []);

// ❌ unnecessary
const isDisabled = useMemo(() => !name, [name]); // → const isDisabled = !name;
```

**`useCallback`** — 함수 참조 안정화:
- Use when: `memo()` 래핑된 자식에게 전달되는 핸들러
- Skip when: memo 안 된 자식에게 전달, 단순 인라인 핸들러

---

## 7. Two-Layer Hook Pattern

### Layer 1: API Query Hook (`use[Feature]Query`)

순수 데이터 fetching layer. API path, request/response 타입을 같은 파일에 정의:

```typescript
// hooks/useFeatureQuery.hook.ts
import { useQuery } from "@tanstack/react-query";
import axios from "@/apis";

export interface IFeatureResponse {
  id: string;
  name: string;
  created_at: string;
}

const FEATURE_API_PATH = "/api/v1/features";

export const useFeatureQuery = (id?: string) => {
  return useQuery({
    queryKey: [FEATURE_API_PATH, id],
    queryFn: async () => {
      const { data } = await axios.get<IFeatureResponse>(`${FEATURE_API_PATH}/${id}`);
      return data;
    },
    enabled: !!id,
    refetchOnWindowFocus: false,
  });
};
```

### Layer 2: Wrapper Hook (`use[Feature]`)

비즈니스 로직 + mutations + 데이터 변환:

```typescript
// hooks/useFeature.hook.ts
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { useFeatureQuery, FEATURE_API_PATH } from "./useFeatureQuery.hook";
import dayjs from "dayjs";

export const useFeature = (id?: string) => {
  const queryClient = useQueryClient();
  const { data: rawData, isFetching } = useFeatureQuery(id);

  const data = rawData ? {
    ...rawData,
    created_at: dayjs(rawData.created_at).format("YYYY-MM-DD HH:mm"),
  } : undefined;

  const { mutate: updateMutate, isLoading: isUpdateLoading } = useMutation({
    mutationFn: async (body: IUpdateFeatureBody) => {
      return axios.put(`${FEATURE_API_PATH}/${id}`, body);
    },
    onSuccess: () => {
      queryClient.invalidateQueries([FEATURE_API_PATH, id]);
    },
  });

  return { data, isFetching, updateMutate, isUpdateLoading };
};
```

### When to Use Each Layer

**목록 페이지(테이블 + 필터 + 정렬 + 페이지네이션)는 항상 2-layer를 사용합니다.**

| Scenario | Hook |
|----------|------|
| 간단한 드롭다운/셀렉트 옵션 조회 | `use[Feature]Query` directly |
| **목록 페이지 (테이블 + 필터/정렬/페이지네이션)** | **Both layers (항상 2-layer)** |
| CRUD operations | `use[Feature]` wrapper hook |
| 데이터 변환 필요 (date format, mapping) | `use[Feature]` wrapper hook |
| 여러 페이지에서 공유하는 쿼리 | `use[Feature]Query` (재사용) |
| Optimistic updates | `use[Feature]` wrapper hook |

### Type & State Definitions

| 타입 | 위치 |
|------|------|
| API request/response types | React Query hook 파일에 정의 |
| Component prop interfaces | 컴포넌트 파일에 인라인 (6개 이상이면 interface) |
| Component-specific types | `[section].types.ts` (필요할 때만) |
| Component-specific constants | `[section].constants.ts` (필요할 때만) |
| Shared/global type files | **생성 금지** — 폴더별 self-contained |

### State Management

- Client-side: `useState`, `useReducer`
- Server state: React Query (queries + mutations)
- Form state: React Hook Form
- Global state: Zustand stores (`store/`)

---

## 8. UI Component Library

**Priority: shadcn/ui first, rsuite if needed**

### shadcn/ui (from `@/components/ui/`)

```typescript
import { Button } from "@/components/ui/button";
import { Separator } from "@/components/ui/separator";
import {
  Accordion, AccordionContent, AccordionItem, AccordionTrigger,
} from "@/components/ui/accordion";
```

Common mappings:
- Buttons → `Button`
- Forms → `Form`, `FormField`, `FormItem`, `FormLabel`, `FormControl`
- Inputs → `Input`, `Textarea`
- Dialogs/Modals → `Dialog`, `Drawer`
- Expandable → `Accordion` (NOT custom state)
- Badges → `Badge`
- Loading → `Skeleton`
- Navigation → `Tabs`
- Tooltips → `Tooltip`, `Popover`
- Selections → `Checkbox`, `RadioGroup`, `Select`, `Switch`

### rsuite (shadcn/ui에 없는 컴포넌트)

```typescript
import { Panel, Stack, Grid, Row, Col, Table } from "rsuite";
```

---

## 9. Styling Pattern

### Tailwind CSS

```typescript
// ✅ CORRECT — rem units
<div className="flex flex-col gap-4 p-[1.5rem] bg-white border rounded-lg">
  <h1 className="text-lg font-semibold text-gray-900">Title</h1>
</div>
```

### Design System Tokens

- Colors: `text-primary`, `text-secondary`, `text-tertiary`, `text-disabled`
- Backgrounds: `bg-white`, `bg-off-white`, `bg-primary`
- Typography: `text-header-01`, `text-subtitle-01-600`, `text-body-02-400`
- Borders: `border-divider-primary`, `border-divider-secondary`

### Units

- **`rem` 사용**: `gap-[1.25rem]`, `p-[1.875rem]`
- **`px` 금지**: `p-[24px]` → `p-[1.5rem]` or `p-6`

### Images

```typescript
import Image from 'next/image';

<div className="relative h-10 w-10">
  <Image src={imageUrl} fill alt="Description" className="object-cover" sizes="(max-width: 768px) 100vw, 50vw" />
</div>
```

---

## 10. File/Media Upload Component Pattern

필드 타입이 `VIDEO`, `IMAGE`, `FILE`인 경우:

```markdown
## Component: [Feature]MediaUpload

**Path**: `pageComponents/[feature]/components/[section]/[Feature]MediaUpload.tsx`
**Memo**: No — receives onChange callback
**Purpose**: File/media upload with preview

**Props**: `{ value?: string; onChange: (url: string) => void; accept: string }`

**State**:
- `uploadStatus` (useState<'idle' | 'uploading' | 'done' | 'error'>)

**Upload Method**: [multipart/form-data | pre-signed URL | direct URL input | TBD]

**UI States**:
- Loading: progress indicator during upload
- Error: inline error message below field
- Done: preview thumbnail
```

> Upload method가 `[TBD]`이면 컴포넌트 plan과 Implementation Checklist Step 2에 코멘트 추가.

---

## 11. Co-location Rules

**Principle: 관련 코드를 사용하는 곳 가까이. 실제 재사용이 발생할 때만 global로 승격.**

| Question | Placement |
|----------|-----------|
| 이 feature에서만 사용? | `pageComponents/[feature]/` |
| 여러 feature에서 사용? | global (`utils/`, `hooks/`, `components/`) |
| 지금은 1곳, 나중에 공유될 수도? | **feature 폴더에 우선 배치, 실제 재사용 시 승격** |

| File Type | Feature-specific | Global shared |
|-----------|-----------------|---------------|
| Table column definitions | `pageComponents/[feature]/components/table/featureTable.column.ts` | `components/table/commonTable.column.ts` |
| Utility functions | `pageComponents/[feature]/utils/feature.utils.ts` | `utils/format.utils.ts` |
| Custom Hooks | `pageComponents/[feature]/hooks/useFeature.hook.ts` | `hooks/useCommon.hook.ts` |
| Constants/enums | `pageComponents/[feature]/feature.constants.ts` | `constants/common.constants.ts` |
| Type definitions | `pageComponents/[feature]/feature.types.ts` | `types/common.type.ts` |

---

## 12. DO / DON'T

### DO

- shadcn/ui 우선 사용 (`@/components/ui/`)
- API 로직을 React Query hook 파일에 정의 (types, path 포함)
- 데이터를 사용하는 leaf 컴포넌트에서 fetch
- Tailwind CSS + `rem` units
- 네이밍 컨벤션 준수 (`itemList`, `handleClick`, `isExpanded`)
- Props 5개 이하면 인라인, 6개 이상이면 interface
- Props/objects destructure
- Arrow function 컴포넌트 + 파일 마지막에 separate default export

### DON'T

- ❌ 별도 API 서비스 레이어 (`apis/service/`) 생성 — hook에 정의
- ❌ `apis/model/` 사용 — hook 파일에 타입 정의
- ❌ 페이지 레벨 fetch 후 prop drilling — leaf에서 fetch
- ❌ 이미지/아이콘 포함 — empty div placeholder 사용
- ❌ 중첩 삼항연산자 — if/else 또는 ts-pattern 사용
- ❌ `px` 단위 — `rem` 사용
- ❌ 인라인 스타일 (`style={{}}`) — Tailwind 클래스 사용
- ❌ Global type/constant 파일 생성 (`types/`, `constants/`) — 폴더별 self-contained
- ❌ 불필요한 `[section].types.ts` / `[section].constants.ts` 생성 — 필요할 때만
- ❌ `cn()` 함수 사용 — Tailwind 클래스 직접 작성
- ❌ `<img>` 태그 — Next.js `Image` 컴포넌트 사용
- ❌ `data-testid` 셀렉터 — ARIA role/text 기반 셀렉터 사용
- ❌ Zustand session store로 URL-synced 상태 관리 — `useUrlQuery` 사용
