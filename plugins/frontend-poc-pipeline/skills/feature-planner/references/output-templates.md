# Reference — 컴포넌트 문서화 형식 + planner.md 산출 템플릿

> 본 문서는 `feature-planner` SKILL.md **Phase 4** 및 **Deliverable** 단계에서 참조한다.

## Phase 4: 컴포넌트별 문서화 항목

각 컴포넌트에 대해 기록한다:

0. **Source**: `REUSE`(그대로 import, full spec 생략) · `EXTEND`(기존 파일에 분기/enum/기본값 추가 — 대상 파일+변경내용만) · `NEW`(새 파일, full spec) · `NEW` + **Pattern Reference**(기존 패턴 참조)
1. Component Name & Path
2. Memo: React.memo() 여부
3. Purpose (1줄)
4. Props: 5개 초과면 interface
5. Types (optional): API 훅이 안 주는 타입만, `[section].types.ts` co-locate
6. Constants (optional): `[section].constants.ts`
7. State: useState 등
8. Data Fetching: React Query 훅 (데이터 쓰는 컴포넌트에서 fetch)
9. Children Components
10. Styling Notes: Tailwind 클래스
11. Conditional Rendering: PRD State Conditions의 IF/THEN (prd_context 있을 때)
12. UI States: Loading(skeleton/spinner/disabled) · Empty(메시지 or N/A) · Error(toast/inline/page)
13. Cancel Behavior (form/modal): prd_context cancel behavior

## Example Output Format

````markdown
## Page: EventPage
**Path**: `pages/event/index.tsx`
**Source**: NEW
**Components Used**: EventRanking (NEW), EventStatusBadge (REUSE — `pageComponents/event/components/common/EventStatusBadge.tsx`)

---
## Component: EventStatusBadge (REUSE)
**Source**: REUSE `pageComponents/event/components/common/EventStatusBadge.tsx`
**Import**: `import EventStatusBadge from '@/pageComponents/event/components/common/EventStatusBadge'`
**Purpose**: 이벤트 상태 표시 — 기존 컴포넌트 재사용

---
## Component: EventRanking (NEW)
**Path**: `pageComponents/event/components/ranking/EventRanking.tsx`
**Source**: NEW
**Pattern Reference**: `pageComponents/partner/components/list/PartnerList.tsx`
**Memo**: Yes — stable eventId prop
**Props**: `{ eventId: string }`
**State**: `filterType` (useState<string>)
**Data Fetching**: `useEventRankingQuery({ eventId, filterType })` (pure) / `useEventRanking(eventId)` (wrapper)
**Children**: EventRankingItem (NEW), EventRankingFilter (NEW)
**Styling**: Container `flex flex-col gap-4 p-6`, `bg-white border rounded-lg`

---
## Component: FeatureSpecTable (EXTEND)
**Source**: EXTEND `pageComponents/[feature]/components/spec/FeatureSpecTable.tsx`
**변경 내용**: switch에 `NEW_TYPE_A`/`NEW_TYPE_B` case 추가, 조건부 disable 로직 추가
````

Note: 컴포넌트명은 부모 폴더 prefix 포함. REUSE는 Source+Import+Purpose만, EXTEND는 대상 파일+변경 내용만.

---

## Deliverable: planner.md 필수 구성

저장 위치 `pageComponents/[feature]/planner.md`, 항상 overwrite. 포함 항목:

- **Project Context Summary** (Phase 1.5 — discovered features/components/hooks/types)
- File Structure Diagram (pages/ + pageComponents/)
- Component Details Table (name·path·source·memo·props·state·data fetching·purpose)
- Data Flow Diagram (React Query 훅 → 컴포넌트, REUSE 훅 표기)
- URL State (스키마 or "Not needed" + 사유)
- PRD/Spec Context Summary (Jira 키 또는 Confluence 제공 시)
- PRD Field → Component Mapping (제공 시)
- Validation Rules (제공 시)
- TBD / Open Questions (tbd_items 있을 때)
- Implementation Checklist (아래)

### Project Context Summary 템플릿
````markdown
## Project Context (Auto-Discovered)
### Existing Features
- `pageComponents/partner/` — Partner management (has planner.md)
### Reusable Components
| Component | Path | Scope |
|---|---|---|
| StatusBadge | `components/StatusBadge.tsx` | global |
### Reusable Hooks
| Hook | Path | API Path |
|---|---|---|
| useMastersQuery | `hooks/useMastersQuery.hook.ts` | `/api/v1/masters` |
### Pattern References
| Suffix | Existing File | Relevance |
|---|---|---|
| *Table | `pageComponents/partner/components/table/PartnerTable.tsx` | 유사 테이블+페이지네이션 |
````

### PRD Field → Component Mapping 템플릿
````markdown
## PRD Field → Component Mapping
| 필드 | 타입 | 컴포넌트 | 필수 | 제약/비고 |
|---|---|---|---|---|
| 광고상품명 | TEXT | Input | Y | 필수 입력 |
| _videoMediaSpec | VIDEO | VideoUpload | Y | Upload method TBD |
````

### Validation Rules 템플릿
````markdown
## Validation Rules
| Rule | Field | Constraint | Error Message | Zod Hint |
|---|---|---|---|---|
| RULE-01 | 광고상품명 | 필수 입력 | 광고상품명을 입력해 주세요 | `z.string().min(1)` |
````

### TBD / Open Questions 템플릿
````markdown
## TBD / Open Questions
> PRD/스펙에서 미결로 표시된 사항. 구현 전 확인 필요.
- [ ] G-01: 에러 상태 화면 정책 미정
````

### Implementation Checklist 템플릿
```markdown
## Implementation Checklist
### Step 0: Verify Reusable Assets
- [x] Confirmed reusable components / hooks / types (import paths)
### Step 0.5: Verify Extension Points (EXTEND일 때)
- [ ] enum/변수·모델/기본값·조건 분기 확장 포인트, 신규 필요 파일 확인
### Step 1: Types & Constants
- [ ] query 훅 파일에 API 타입 (REUSE면 생략), `[section].types.ts`/`.constants.ts` (필요 시)
### Step 2: API Hooks
- [ ] REUSE 훅 import / NEW `use[Feature]Query.hook.ts` (pure) / `use[Feature].hook.ts` (wrapper)
### Step 3: Page Entry Points
- [ ] `pages/[route].tsx` 최소 레이아웃, Section 컴포넌트 단일 자식
### Step 4: Form Schema (hasCreate || hasDetail)
- [ ] `form/schema/[feature]-form.schema.ts` Zod, [E] 필드 매핑, RULE-XX 반영
### Step 5: Section Components (top-down)
- [ ] root Section (form이면 FormProvider), REUSE import, NEW 하위 섹션, IF/THEN 조건 렌더
### Step 6: UI States
- [ ] loading / empty / error (toast or inline)
### Step 7: Cancel & Post-Save Flow
- [ ] cancel 동작 + 저장 후 네비게이션
### Step 8: URL State (필요 시)
- [ ] `useUrlState` 스키마, 필터/검색/페이지네이션 연결
```

### 저장 후 사용자 안내
```
Plan saved to: pageComponents/[feature]/planner.md
To implement, run: /code-writer --all "pageComponents/[feature]/planner.md"
```
