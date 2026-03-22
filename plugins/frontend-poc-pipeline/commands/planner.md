---
allowed-tools: Read, Write, Glob, Grep, Bash(find:\*), Bash(mkdir:*), mcp__figma-dev-mode-mcp-server__get_metadata, mcp__figma-dev-mode-mcp-server__get_screenshot, mcp__figma-dev-mode-mcp-server__get_code, mcp__claude_ai_Figma__get_metadata, mcp__claude_ai_Figma__get_screenshot, mcp__claude_ai_Figma__get_design_context, mcp__claude_ai_Figma__get_variable_defs
argument-hint: [figma-url] [image-path-1] [image-path-2] [optional-context]
description: Plan components from design, analyze URL state needs, and save as planner.md in pageComponents/[feature]/ directory
model: claude-opus-4-6
---

# Design-Based Component Planning (with File Output)

Analyzes a Figma design or screenshots, plans component structure, determines whether URL state synchronization is needed, and **saves the result as `planner.md`** inside `pageComponents/[feature]/`.

## Arguments

- `$1` - **Figma URL** (optional): Full Figma design URL with node-id
- `$2, $3, ...` - **Image paths** (optional): Design screenshot file paths
- **Jira issue key** (optional, any position): e.g. `AX-70`, `WP-1234` — When provided, fetches PRD from Jira and extracts **Implementation Hints (Section 7)** to enrich the plan automatically
- Last argument - **Optional context**: Additional requirements if provided

**Note**: Provide either Figma URL or image paths (or both)

**Examples**:
```bash
/planner "https://figma.com/design/abc?node-id=123-456"
/planner "https://figma.com/design/abc?node-id=123-456" AX-70
/planner AX-70 "/path/to/design.png"
```

## Output File Rules

1. **Directory**: `pageComponents/[feature]/` — colocated with the code that `/plan-implement` will generate
2. **File name**: Always `planner.md`
   - Example: `pageComponents/partner/planner.md`, `pageComponents/event/planner.md`
3. **Feature directory**: Determined during design analysis (Phase 1) based on the feature name
4. **If file already exists**: Overwrite with new plan
5. **If the feature directory doesn't exist yet**: Create it with `mkdir -p pageComponents/[feature]`

---

## Phase 1: Design Analysis + PRD Context Loading

**Step 1A: Parse all arguments in parallel**

Parse ALL arguments to identify:
- Figma URL(s): any arg starting with `http` and containing `figma.com`
- Image paths: any arg that is a local file path
- Jira issue key: any arg matching `[A-Z]+-\d+` pattern (e.g. `AX-70`, `WP-1234`)
- Optional context: last non-URL, non-key, non-path argument

**Step 1B: Load PRD context from Jira (if issue key provided)**

If a Jira issue key is found:
1. Determine Jira MCP tool:
   - `wisebirds.atlassian.net` → `mcp__mcp-atlassian-nestads__jira_get_issue`
   - `heypoll.atlassian.net` → `mcp__mcp-atlassian-heypoll__jira_get_issue`
2. Fetch the issue: `fields: summary, description`
3. Extract **Section 7 — Implementation Hints** from the PRD description:
   - Page type flags: `hasCreate`, `hasList`, `hasDetail`, `isReadOnly`
   - Feature directory: `suggested-name`
   - URL State: `Needed: Yes/No` + parameters
   - Cancel behavior: page → action + modal
   - Empty/Loading/Error states
   - API Hints: endpoint, method, purpose
4. If Section 7 not found, extract what's available from description (User Stories, State Conditions, Field Definitions)
5. Store as `prd_context` — used to enrich Phase 2–6

**Step 1C: Load spec-validator policy context**

Call `spec-validator guide` to load [F]/[P]/[Data] tag policy context.
Store as `spec_policy` — used in Phase 2 when analyzing Figma description nodes.

**Step 1D: Analyze design sources**

**If Figma URL is provided:**
1. Extract node ID from Figma URL
2. Use Figma MCP tools to gather (**run in parallel with Step 1B**):
   - `get_metadata` - Component structure and hierarchy
   - `get_screenshot` - Visual reference
   - `get_code` - Design tokens, spacing, colors, typography
3. Analyze the Figma design using `spec_policy` context:
   - Identify visual hierarchy from metadata
   - Note interactive elements and component structure
   - Extract design tokens (spacing, colors, typography)
   - Map component relationships
   - **Validate any description nodes against [F]/[P]/[Data] policy**

**If image file paths are provided:**
1. **Read design screenshots** from arguments:
   - Use the Read tool to view each screenshot image
   - Analyze multiple screens if provided (e.g., different states, responsive views)

2. **Analyze the design**:
   - Identify visual hierarchy (sections, groups, atomic elements)
   - Note interactive elements (buttons, inputs, expandable sections, modals)
   - Identify reusable patterns vs unique components
   - Identify different states (loading, error, empty, success)
   - Map data flow (what comes from API, what's static)
   - Note responsive behavior if multiple viewports shown

**Step 1E: Merge PRD context with design analysis**

If `prd_context` exists, merge it with design analysis:
- Use `hasCreate/hasList/hasDetail` flags to determine page structure
- Use `suggested-name` as the feature directory name (override design-inferred name if provided)
- Use `cancel behavior` to add cancel button component specs
- Use `API Hints` to pre-populate hook layer planning
- Use `Empty/Loading/Error states` to add state UI components
- Use User Story ACs as additional component behavior constraints

---

## Phase 2: Component Structure Planning

### Directory Structure Rules

- **Feature-first organization**: Group by feature, not by type
- **Co-location**: Keep related files close (components, actions, hooks, utils)
- **Atomic Design**: Classify components by complexity
  - Atoms: Basic UI elements (buttons, inputs, badges)
  - Molecules: Simple combinations (search bar, card)
  - Organisms: Complex sections (product info, notice section)

### Naming Conventions

- **Folder**: kebab-case (e.g., `event-ranking`)
- **Files**: camelCase (e.g., `eventRanking`)
- **Components**: PascalCase with parent feature name prefix
  - **Rule**: If component is in a section folder under `pageComponents/[feature]/components/[section]/`, add the feature name as prefix
  - Example: `pageComponents/event/components/ranking/EventRanking.tsx` → Component name: `EventRanking`
  - Example: `pageComponents/event/components/details/EventDetails.tsx` → Component name: `EventDetails`
  - Example: `pageComponents/media/components/inventory/MediaInventory.tsx` → Component name: `MediaInventory`
- **Props interfaces**: `I` prefix (e.g., `IEventRankingProps`)
- **Types**: `Type` suffix (e.g., `EventResponseType`)
- **Collections**: Use postfix (e.g., `itemList`, `noticeMap`)
- **Booleans**: `is` or `are` prefix (e.g., `isExpanded`, `isLoading`)
- **Handlers**: `handle` prefix (e.g., `handleClick`, `handleSubmit`)

### Inline Props/State in File Structure

In the file structure diagram, **annotate each component with its props and state** directly below the file name. This provides an at-a-glance overview without reading the full component details section.

**Format**:
```
├── ComponentName.tsx
│     props: propA, propB (or "none")
│     state: stateA, stateB (or "none")
```

**Rules**:
- List prop names only (no types) — types are documented in the component details section
- For state, list `useState` variable names and note `useUrlQuery` if URL state is used
- Use `"none"` when a component has no props or state
- Only annotate `.tsx` component files, not constants/columns/hooks

**Example**:
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

### File Organization (Pages Router)

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
        │   │   ├── EventRanking.tsx    # Component with feature prefix "Event"
        │   │   ├── EventRankingItem.tsx
        │   │   ├── EventRankingFilter.tsx
        │   │   ├── eventRanking.types.ts      # Types used by ranking components
        │   │   └── eventRanking.constants.ts  # Constants used by ranking components
        │   ├── details/                # Another section folder (self-contained)
        │   │   ├── EventDetails.tsx    # Component with feature prefix "Event"
        │   │   ├── EventDetailsTab.tsx
        │   │   ├── eventDetails.types.ts
        │   │   └── eventDetails.constants.ts
        │   └── common/                 # Components shared across multiple sections
        │       ├── EventSharedCard.tsx
        │       └── EventStatusBadge.tsx
        └── hooks/                      # Feature-specific hooks
            ├── useEventQuery.hook.ts   # API query hook (types co-located here)
            └── useEvent.hook.ts        # Wrapper hook (business logic + mutations)
```

```
# Nested route: pages/management/product.tsx → pageComponents/management/product/
pages/
  └── management/
        ├── product.tsx                 # Route: /management/product
        ├── order.tsx                   # Route: /management/order
        └── category.tsx               # Route: /management/category

pageComponents/
  └── management/
        ├── _shared/                    # Shared across management sub-features
        │   ├── managementTable.utils.ts
        │   └── ManagementColumnSettingsModal.tsx
        ├── product/                    # /management/product feature
        │   ├── planner.md
        │   ├── components/
        │   │   ├── filter/             # Self-contained: .tsx + .types.ts + .constants.ts
        │   │   ├── table/              # Self-contained: .tsx + .types.ts + .constants.ts
        │   │   └── column-settings/    # Self-contained: .tsx + .types.ts + .constants.ts
        │   └── hooks/
        └── order/                      # /management/order feature
            ├── planner.md
            ├── components/
            └── hooks/
```

**Nested route rules:**
- Mirror `pages/` path in `pageComponents/` (e.g., `pages/management/product.tsx` → `pageComponents/management/product/`)
- Place domain-shared code in `_shared/` folder at the parent level (e.g., `pageComponents/management/_shared/`)
- `_shared/` is only for code shared within that domain, NOT global code (global goes to root `utils/`, `hooks/`, `components/`)

**Common folder rules:**
- When 2+ section folders within a feature share a component, create a `common/` folder under `components/`
  - Example: `pageComponents/event/components/common/EventStatusBadge.tsx`
- `common/` is for components shared **within a single feature**, NOT across features
- Cross-feature shared code goes to `_shared/` (domain level) or root `components/` (global level)

**Page component path matching rules:**
- `pageComponents/` directory structure **MUST** mirror `pages/` route structure exactly
- When creating a new page at `pages/[a]/[b].tsx`, the corresponding component directory **MUST** be `pageComponents/[a]/[b]/`
- Do NOT create pageComponent directories that deviate from the pages route path (e.g., `pages/report/daily.tsx` → `pageComponents/report/daily/`, NOT `pageComponents/dailyReport/`)

```
# Global shared (not domain-specific)
components/                             # Global shared components
  └── shared-component/
        └── SharedComponent.tsx

hooks/                                  # Global shared hooks
  └── useGlobal.hook.ts
```

---

## Phase 3: Component Type Guidelines (Pages Router)

**All components in Pages Router are Client Components by default** - there is no Server/Client component distinction like in App Router.

**Data Fetching Strategy**:

- **Fetch data as deep (leaf) as possible** - data should be fetched in the component that actually uses it
- Use React Query hooks in the deepest components that need the data
- Page components should primarily be layout/composition components
- Avoid fetching all data at the page level and prop drilling

**Memo Usage Guidelines**:

- When planning components, **explicitly state whether to use `memo()` or not**
- **Export pattern**: Use `export default memo(Component)` at the end of file
- Use `memo()` when:
  - Component receives complex props that don't change often
  - Component is rendered frequently with same props
  - Component has expensive rendering logic
  - Parent re-renders frequently but component props remain stable
- Do NOT use `memo()` when:
  - Component always receives new props on parent re-render
  - Component is simple and renders quickly
  - Props include functions or objects created inline in parent

**Example Plan Format**:

```markdown
### EventPage (pages/event/index.tsx)

- **Purpose**: Main page layout, composes sections
- **Components Used**: EventRanking, EventDetails
- **Data Fetching**: None (data fetched in child components)

### EventRanking (pageComponents/event/components/ranking/EventRanking.tsx)

- **Location**: `pageComponents/event/components/ranking/EventRanking.tsx`
- **Memo**: Yes - receives stable props, parent re-renders on other state changes
- **Purpose**: Displays event ranking list with interactive filtering
- **Props**: { eventId: string }
- **Data Fetching**: useEventRankingQuery(eventId) - fetches data where it's used
- **State**: filterType (useState)
- **Hooks**: useState, useEventRankingQuery (React Query)

Note: Component name "EventRanking" includes parent folder prefix "Event"
```

---

## Phase 4: Component Planning Output

For each component, document:

1. **Component Name & Path**
2. **Memo**: Whether to use React.memo()
3. **Purpose**: Brief description (1 line)
4. **Props**: Inline or interface (use interface only if more than 5 props)
5. **Types** (optional): Only if the component needs its own types beyond what API hooks provide. Co-located in `[section].types.ts`. API request/response types stay in hook files.
6. **Constants** (optional): Only if the component needs its own constants/enums/maps. Co-located in `[section].constants.ts`. (e.g., filter options, status mappings, column definitions)
7. **State**: List useState/other hooks
8. **Data Fetching**: React Query hooks (fetch in component that uses data)
9. **Children Components**: List of sub-components
10. **Styling Notes**: Tailwind classes to use
11. **Conditional Rendering**: IF/THEN rules from PRD State Conditions (if `prd_context` available)
    - Example: `IF ADBADGE remote free THEN disable AdBadge field`
12. **UI States**: Document all required states explicitly
    - `Loading`: skeleton / spinner / disabled (specify which)
    - `Empty`: empty state message or N/A for non-list components
    - `Error`: toast / inline error / error page (specify which)
13. **Cancel Behavior** (form/modal components only): From `prd_context` cancel behavior
    - Example: `딤드 + 확인 모달 → 목록 이동` or `즉시 목록 이동`

### Example Output Format

````markdown
## Page: EventPage

**Path**: `pages/event/index.tsx`
**Purpose**: Main event page layout

**Components Used**:
- EventRanking
- EventDetails

---

## Component: EventRanking

**Path**: `pageComponents/event/components/ranking/EventRanking.tsx`
**Memo**: Yes - receives stable eventId prop
**Purpose**: Displays event ranking list with filtering

**Props**: `{ eventId: string }`

**State**:
- `filterType` (useState<string>) - Current filter selection

**Data Fetching**:
- `useEventRankingQuery({ eventId, filterType })` - API query hook (pure fetching)
- `useEventRanking(eventId)` - Wrapper hook (if mutations or data transform needed)

**Children Components**:
- EventRankingItem (for each ranking)
- EventRankingFilter

**Styling**:
- Container: `flex flex-col gap-4 p-6`
- Background: `bg-white`
- Border: `border border-gray-200 rounded-lg`

---

## Component: EventRankingItem (with interface example - more than 5 props)

**Path**: `pageComponents/event/components/ranking/EventRankingItem.tsx`
**Memo**: Yes - receives stable ranking data

**Props**:

```typescript
interface IEventRankingItemProps {
  id: string;
  rank: number;
  userName: string;
  score: number;
  avatarUrl: string;
  timestamp: string;
  onClick: () => void;
}
```

**State**: None

**Data Fetching**: None (receives data via props)

**Styling**:
- Card: `bg-white border rounded-md p-4 shadow-sm hover:shadow-md`
- Rank: `text-lg font-bold text-blue-600`
- UserName: `text-base font-semibold text-gray-900`

Note: Component names include parent folder prefix "Event"
````

---

## Phase 5: Data Flow Planning

### Two-Layer Hook Pattern

Hooks follow a **two-layer architecture**: a pure API query hook and a wrapper hook that adds business logic.

1. **API Query Hook** (`use[Feature]Query`) — Pure data fetching layer:
   - Thin wrapper around `useQuery`
   - Only responsible for API call and basic response mapping
   - Reusable across different components/pages
   - **Define API paths, request/response types in this file** (not in separate type files)
   - Response type interface is exported so wrapper hook and components can use it
   - **Pattern**:
     ```typescript
     // hooks/useFeatureQuery.hook.ts
     import { useQuery } from "@tanstack/react-query";
     import axios from "@/apis";

     // Define types in hook file
     export interface IFeatureResponse {
       id: string;
       name: string;
       status: string;
     }

     // Define API path
     const FEATURE_API_PATH = "/api/v1/features";

     export const useFeatureQuery = (id: string) => {
       return useQuery({
         queryKey: [FEATURE_API_PATH, id],
         queryFn: async () => {
           const { data } = await axios.get<IFeatureResponse>(
             `${FEATURE_API_PATH}/${id}`
           );
           return data;
         },
         enabled: !!id,
         refetchOnWindowFocus: false,
       });
     };
     ```

2. **Wrapper Hook** (`use[Feature]`) — Business logic layer:
   - Wraps the query hook and adds **data transformation, mutations, side effects**
   - Combines query + mutation logic for a specific feature/page
   - Handles date formatting, data mapping, optimistic updates, etc.
   - Returns a clean API for the component (data, loading states, mutation functions)
   - **Pattern**:
     ```typescript
     // hooks/useFeature.hook.ts
     import { useMutation, useQueryClient } from "@tanstack/react-query";
     import { useFeatureQuery } from "./useFeatureQuery.hook";
     import dayjs from "dayjs";

     export const useFeature = (id?: string) => {
       const queryClient = useQueryClient();

       // 1. Use the query hook for data fetching
       const { data: rawData, isFetching } = useFeatureQuery(id);

       // 2. Transform data for the view
       const data = rawData ? {
         ...rawData,
         created_at: dayjs(rawData.created_at).format("YYYY-MM-DD HH:mm"),
       } : undefined;

       // 3. Define mutations
       const { mutate: updateMutate, isLoading: isUpdateLoading } = useMutation({
         mutationFn: async (body: IUpdateFeatureBody) => {
           return updateFeature(id as string, body);
         },
         onSuccess: () => {
           queryClient.invalidateQueries([FEATURE_API_PATH, id]);
         },
       });

       // 4. Return clean API for component
       return {
         data,
         isFetching,
         updateMutate,
         isUpdateLoading,
       };
     };
     ```

### When to Use Each Layer

**IMPORTANT: 목록 페이지(테이블 + 필터 + 정렬 + 페이지네이션)는 항상 2-layer를 사용합니다.**
목록 페이지는 filter string 빌딩, sort 변환 등 비즈니스 로직이 반드시 필요하므로 wrapper hook이 필수입니다.

| Scenario | Hook to Use |
|----------|-------------|
| 간단한 드롭다운/셀렉트 옵션 조회 | `use[Feature]Query` directly |
| **목록 페이지 (테이블 + 필터/정렬/페이지네이션)** | **Both layers (항상 2-layer)** |
| Page with CRUD operations | `use[Feature]` wrapper hook |
| Data needs transformation (date format, mapping) | `use[Feature]` wrapper hook |
| Shared query across multiple pages | `use[Feature]Query` (reuse the query hook) |
| Mutations with optimistic updates | `use[Feature]` wrapper hook |

3. **State Management**:
   - Client-side state (useState, useReducer)
   - Server state (React Query for queries and mutations)
   - Form state (React Hook Form)
   - Global state (Zustand stores in `store/`)

4. **Type Definitions** (co-located per folder):
   - API request/response types: Define in the React Query hook file that uses them
   - Component prop interfaces: Define inline in the component file (use interface if > 5 props)
   - Component-specific types (beyond API types): Co-locate in `[section].types.ts` within the component's folder (only when needed)
   - Component-specific constants/enums/maps: Co-locate in `[section].constants.ts` within the component's folder (only when needed)
   - Do NOT create shared/global type files — each folder should be self-contained

---

## Phase 6: URL State Analysis

Analyze whether the page requires URL query parameter synchronization for state persistence.

### When URL State IS Needed

- **Listing/table pages** with pagination, sorting, and filters (e.g., user list, media list, report table)
- Pages where users might want to **share a URL** that reproduces the same view
- Pages with **search/filter combinations** that should survive page refresh
- Pages with **tabs or view modes** that should be bookmarkable

### When URL State is NOT Needed

- **Detail pages** (e.g., `/users/[id]` — the ID is already in the route)
- **Form/creation pages** (e.g., creating a new item)
- **Dashboard pages** with no user-configurable filters
- **Modal/dialog content** (state lives in parent)

### URL State Output Format

**If URL state IS needed**, include this section in the plan:

````markdown
## URL State

**Needed**: Yes — this is a listing page with pagination, sorting, and filters.

### Schema

| Key | Type | Default Value | Trigger |
|-----|------|---------------|---------|
| page | number | 1 | User clicks pagination |
| size | number | 25 | User changes page size |
| sortColumn | string | 'created_at' | User clicks column header |
| sortType | string | 'desc' | User clicks column header |
| q | string | '' | User submits search |
| status | string | '' | User selects status filter |
| channel | string[] | [] | User selects channel filter |

### Behavior
- Initial page load: clean URL, no query params (defaults used internally)
- Only non-default values appear in URL (e.g., page=1 does NOT appear)
- Filter/size change resets page to 1 (removes page param from URL)
- Direct URL access (e.g., `?page=3&size=50`) restores full state
- Browser back/forward preserves state
````

**If URL state is NOT needed**, include:

````markdown
## URL State

**Needed**: No — this is a [detail/form/dashboard] page. State managed via [useState/React Hook Form/Zustand].
````

---

## Implementation Guidelines

### UI Component Library

**Priority order: Use shadcn/ui first, then rsuite if needed**

**shadcn/ui components** (located in `./components/ui/`):

```typescript
// ✅ PREFERRED - Import shadcn/ui components from local ./components/ui
import { Button } from "@/components/ui/button";
import { Separator } from "@/components/ui/separator";
import {
  Accordion,
  AccordionContent,
  AccordionItem,
  AccordionTrigger,
} from "@/components/ui/accordion";

// Usage:
<Button variant="outline" size="sm" onClick={handleClick}>
  Click me
</Button>
```

**rsuite components** (use when shadcn/ui doesn't have the needed component):

```typescript
// Use rsuite for components not available in shadcn/ui
import { Panel, Stack, Grid, Row, Col, Table } from "rsuite";

// Usage:
<Panel bordered header="Title">
  Content
</Panel>

<Stack spacing={10}>
  <div>Item 1</div>
  <div>Item 2</div>
</Stack>
```

---

### Component Definition Pattern

**MUST use arrow functions for components and export default separately at the end of file:**

```typescript
// ✅ CORRECT
const MyComponent = () => {
  return <div>Content</div>;
};

export default MyComponent;

// or with memo
export default memo(MyComponent);
````

```typescript
// ❌ INCORRECT
export default function MyComponent() {
  return <div>Content</div>;
}
```

### API Integration Pattern (Two-Layer Hooks)

**Layer 1: API Query Hook** — Pure data fetching, reusable:

```typescript
// ✅ hooks/useFeatureQuery.hook.ts — API query hook
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

**Layer 2: Wrapper Hook** — Business logic, mutations, data transformation:

```typescript
// ✅ hooks/useFeature.hook.ts — Wrapper hook
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { useFeatureQuery, FEATURE_API_PATH } from "./useFeatureQuery.hook";
import dayjs from "dayjs";

export const useFeature = (id?: string) => {
  const queryClient = useQueryClient();
  const { data: rawData, isFetching } = useFeatureQuery(id);

  // Transform data for the view
  const data = rawData ? {
    ...rawData,
    created_at: dayjs(rawData.created_at).format("YYYY-MM-DD HH:mm"),
  } : undefined;

  // Mutations
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

```typescript
// ❌ INCORRECT - Don't use separate service layer
// apis/service/featureService.ts
export const getFeature = async (id: string) => { ... }
```

---

### Styling Pattern

**Use Tailwind CSS for styling:**

```typescript
// ✅ CORRECT - Tailwind with rem units
<div className="flex flex-col gap-4 p-[1.5rem] bg-white border rounded-lg">
  <h1 className="text-lg font-semibold text-gray-900">Title</h1>
</div>
```

```typescript
// ❌ INCORRECT - Don't use px in arbitrary values
<div className="p-[24px]" /> // Use p-[1.5rem] or p-6 instead
```

---

### File/Media Upload Component Pattern

When a field has type `VIDEO`, `IMAGE`, or `FILE` (from PRD field definition or design analysis):

```markdown
## Component: [Feature]MediaUpload

**Path**: `pageComponents/[feature]/components/[section]/[Feature]MediaUpload.tsx`
**Memo**: No — receives onChange callback, re-renders on upload state change
**Purpose**: File/media upload with preview

**Props**: `{ value?: string; onChange: (url: string) => void; accept: string }`

**State**:
- `uploadStatus` (useState<'idle' | 'uploading' | 'done' | 'error'>)

**Upload Method**: [multipart/form-data | pre-signed URL | direct URL input | TBD]
- Note: Upload method must be specified from PRD API Hints or marked [TBD]

**UI States**:
- Loading: progress indicator during upload
- Error: inline error message below field
- Done: preview thumbnail

**Data Fetching**: upload mutation hook (POST to upload endpoint)
```

> If upload method is `[TBD]` in PRD, add a comment in the component plan and Implementation Checklist Step 2.

### DO:

- **Use shadcn/ui first**, then rsuite if needed (from `./components/ui/`)
- **Define API logic in React Query hooks** with types and paths in same file
- **Fetch data in leaf components** that use the data
- Use Tailwind CSS for styling
- Use `rem` units for arbitrary Tailwind values (e.g., `p-[1.5rem]` not `p-[24px]`)
- Follow naming conventions (itemList, handleClick, isExpanded)
- Use props interface only if more than 5 props
- Destructure props and objects
- Use arrow functions for components
- Separate default export at the end of file

### DON'T:

- ❌ Create separate API service layer (`apis/service/`) - define in hooks
- ❌ Use `apis/model/` - define types in hook files
- ❌ Fetch data at page level and prop drill - fetch in components that use data
- ❌ Include images/icons (use empty div placeholders)
- ❌ Use nested ternaries (use if/else or ts-pattern)
- ❌ Use `px` units in arbitrary values (use `rem`)
- ❌ Use inline styles for layout (use Tailwind classes)
- ❌ Create shared/global type files (`types/`, `constants/`) - each folder should be self-contained
- ❌ Create `[section].types.ts` or `[section].constants.ts` when not needed - only create when the component has its own types/constants beyond what API hooks provide

---

## Context Priority

If last argument is optional context:

- **Highest Priority**: Follow context instructions
- Override defaults if conflicting
- Document deviations from standard structure

---

## Deliverable & File Save

After completing all phases, **save the plan to a file**:

1. Determine the feature name from the design analysis (e.g., `partner`, `event`, `media`)
2. Create the feature directory if it doesn't exist: `mkdir -p pageComponents/[feature]`
3. Write the complete plan output to `pageComponents/[feature]/planner.md`
4. The saved file must include ALL deliverables:
   - File Structure Diagram (pages/ and pageComponents/ organization)
   - Component Details Table (name, path, memo, props, state, data fetching, purpose)
   - Data Flow Diagram (React Query hooks → Components)
   - URL State (schema with keys/types/defaults/triggers, or "Not needed" with reason)
   - PRD Context Summary (if Jira issue key was provided)
   - Implementation Checklist (ordered steps for coding — see template below)

### Implementation Checklist Template

Include this ordered checklist in every planner.md output:

```markdown
## Implementation Checklist

### Step 1: Types & Constants
- [ ] Define API request/response types in query hook file
- [ ] Define component-specific types in `[section].types.ts` (only if needed)
- [ ] Define constants/enums in `[section].constants.ts` (only if needed)

### Step 2: API Hooks
- [ ] Implement `use[Feature]Query.hook.ts` (pure fetch layer)
- [ ] Implement `use[Feature].hook.ts` (wrapper: mutations + data transform) — only if needed

### Step 3: Page Entry Points
- [ ] Create `pages/[route].tsx` with minimal layout
- [ ] Wire Section component as the only child

### Step 4: Form Schema (hasCreate || hasDetail)
- [ ] Define Zod schema in `form/schema/[feature]-form.schema.ts`
- [ ] Map all [E] fields from PRD field definition table
- [ ] Add validation rules matching PRD RULE-XX entries

### Step 5: Section Components (top-down)
- [ ] Implement root Section component (FormProvider if form page)
- [ ] Implement sub-sections in order: [list section names from design]
- [ ] Add conditional rendering per IF/THEN rules

### Step 6: UI States
- [ ] Add loading state to data-fetching components
- [ ] Add empty state to list/table components
- [ ] Add error handling (toast or inline per PRD spec)

### Step 7: Cancel & Post-Save Flow
- [ ] Implement cancel button behavior (modal / direct navigate per PRD)
- [ ] Implement post-save navigation (per PRD Section 4-5)

### Step 8: URL State (if needed)
- [ ] Implement URL state schema with `useUrlState`
- [ ] Wire filter/search/pagination components to URL state
```

### After saving, inform the user:

```
Plan saved to: pageComponents/[feature]/planner.md
To implement, run: /plan-implement [figma-url-or-images] "pageComponents/[feature]/planner.md"
```

---

## Usage Examples

```bash
# With Figma URL only
/plan "https://figma.com/design/abc?node-id=123-456"

# With image files
/plan "/path/to/design.png"

# With multiple images
/plan "/path/to/design-desktop.png" "/path/to/design-mobile.png"

# With additional context
/plan "https://figma.com/design/abc?node-id=123-456" "Focus on mobile-first approach"
```
