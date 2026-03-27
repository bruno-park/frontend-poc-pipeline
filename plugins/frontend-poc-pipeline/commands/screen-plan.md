---
allowed-tools: Read, Write, Glob, Grep, Bash(find:\*), Bash(mkdir:*), mcp__figma-dev-mode-mcp-server__get_metadata, mcp__figma-dev-mode-mcp-server__get_screenshot, mcp__figma-dev-mode-mcp-server__get_code, mcp__claude_ai_Figma__get_metadata, mcp__claude_ai_Figma__get_screenshot, mcp__claude_ai_Figma__get_design_context, mcp__claude_ai_Figma__get_variable_defs, mcp__mcp-atlassian-nestads__jira_get_issue, mcp__mcp-atlassian-heypoll__jira_get_issue
argument-hint: [figma-url] [jira-issue-key] [image-path-1] [image-path-2] [optional-context]
description: Plan components from design, analyze URL state needs, and save as planner.md in pageComponents/[feature]/ directory
model: claude-opus-4-6
---

# Design-Based Component Planning (with File Output)

Analyzes a Figma design or screenshots, plans component structure, determines whether URL state synchronization is needed, and **saves the result as `planner.md`** inside `pageComponents/[feature]/`.

> **컨벤션 참조**: 디렉토리 구조, 네이밍, 파일 조직, 컴포넌트 정의 패턴, 훅 패턴, 스타일링 규칙은 모두 `conventions` 스킬을 따릅니다.

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
   - On fetch failure: log warning, continue with design-only analysis
2. Fetch the issue: `fields: summary, description, parent, issuetype`
   - `parent` → 에픽 summary를 가져와 feature 도메인 추론에 활용
   - `issuetype` → 작업/버그/스토리 구분
   - **NOTE**: `*all`이나 `expand: renderedFields`는 불필요 — `description`만으로 PRD 마크다운 전문이 충분히 옴
3. **Extract page type flags** — try in this order:
   - **If Section 7 exists**: read `hasCreate`, `hasList`, `hasDetail`, `isReadOnly`, `suggested-name`, URL State, Cancel behavior, Empty/Loading/Error states, API Hints
   - **If Section 7 is absent** (standard PRD format — 대부분의 경우): 아래 **구조화된 추출 절차**를 순서대로 수행

     #### Step 3a: Page type 추론 (복합 판단)

     title 키워드 + Section 4 내용을 조합하여 page type flags를 결정:

     **1차: title 키워드 매칭** (case-insensitive):
       - title contains `CREATE` or `등록` → `hasCreate: true`
       - title contains `LIST` or `목록` → `hasList: true`
       - title contains `DETAIL` or `상세` → `hasDetail: true`
       - title contains `EDIT` or `수정` → `hasCreate: true, hasDetail: true`

     **2차: Section 4 기반 보정** (1차 결과가 불확실하거나 보강 필요 시):
       - Section 4-1 구조 트리에 `MODAL` 키워드 → `hasModal: true`
       - Section 4-2 필드 정의 테이블이 존재하고 필수(Y) 필드가 있으면 → `hasCreate: true` 보강
       - Section 4-2 필드가 있지만 모든 필드가 읽기전용 → `hasDetail: true, isReadOnly: true`
       - Section 4-4 버튼 정의에 "저장" 포함 → `hasCreate: true` 확정
       - Section 4-4 버튼 정의에 "삭제" 포함 → `hasDelete: true`

     #### Step 3b: suggested-name 추론 (구체적 규칙)

     ```
     1. title에서 prefix 패턴 제거:
        - [프론트엔드], [백엔드], [FE], [BE] 등 대괄호 태그
        - CREATE, LIST, DETAIL, EDIT (페이지 타입 키워드)
        - 티켓 번호 패턴 (— FT-XX-XX, AX-XX 등)
     2. 남은 핵심 명사구를 영문 kebab-case로 변환
     3. parent(에픽) summary에서 도메인 키워드 보조 확인
     예: "[프론트엔드] CREATE 동영상 광고 상품 등록 — FT-26-05"
         → prefix 제거: "동영상 광고 상품 등록"
         → 영문 변환: "video-ad-product"
     ```

     #### Step 3c: Section 4-2 필드 정의 → `prd_context.field_component_map`

     Section 4-2 테이블의 각 행을 파싱하여 컴포넌트 매핑 배열로 구조화:

     | PRD 필드 타입 | 컴포넌트 패턴 | 비고 |
     |---|---|---|
     | `TEXT` | `Input` / `Textarea` | 제약에 "여러 줄" 또는 "설명" 있으면 Textarea |
     | `IMAGE` | `ImageUpload` | Upload method TBD 표기 |
     | `VIDEO` | `VideoUpload` | Upload method TBD 표기 |
     | `FILE` | `FileUpload` | Upload method TBD 표기 |
     | `ADBADGE` | `BadgeSelector` (custom) | Section 4-3에서 disable 조건 확인 |
     | `CTA_BUTTON` | `ColorPicker` + `ButtonPreview` | 기본값 확인 (e.g., #EDEDED) |
     | `SELECT` / `ENUM` | `Select` / `RadioGroup` | 옵션 목록 확인 |
     | `CHECKBOX` | `Checkbox` | - |
     | `DATE` | `DatePicker` | - |
     | `NUMBER` | `NumberInput` | min/max 제약 확인 |

     각 필드에 대해 저장:
     ```
     field_component_map = [
       { field: "광고상품명", type: "TEXT", component: "Input", required: true, constraint: "필수 입력", note: "v_required_adProductName" },
       { field: "_videoMediaSpec", type: "VIDEO", component: "VideoUpload", required: true, constraint: "동영상 소재 (메인)", note: "D-01, Upload method TBD" },
       ...
     ]
     ```

     #### Step 3d: Section 4-3 상태 조건 → `prd_context.state_conditions`

     IF/THEN 블록을 파싱하여 구조화된 배열로 변환. 각 조건을 `type`으로 분류:

     ```
     state_conditions = [
       { condition: "광고 구분 선택", effect: "해당 구분 탭 표시, 7개 소재 항목 편집 가능 상태로 전환", type: "conditional_render" },
       { condition: "ADBADGE 리모트 무료", effect: "ADBADGE 항목 편집 불가(disable) 상태 유지", type: "field_disable" },
       { condition: "레이아웃 버튼 클릭", effect: "MODAL 레이아웃 설정 화면으로 이동", type: "navigation" },
       { condition: "MODAL 저장 완료", effect: "레이아웃 설정값 저장, MODAL 닫힘, CREATE 페이지 복귀", type: "modal_close" },
       { condition: "필수 입력값 누락 상태에서 저장 버튼 클릭", effect: "유효성 검증 실패 메시지 표시", type: "validation_error" },
       { condition: "모든 유효성 통과 후 최종 저장", effect: "상품/스펙/레이아웃 데이터 저장 성공", type: "submit_success" },
     ]
     ```

     Type 분류 기준:
     - `conditional_render`: UI 요소의 표시/숨김 전환
     - `field_disable`: 특정 필드 비활성화
     - `navigation`: 페이지/모달 이동
     - `modal_close`: 모달 닫기 + 데이터 반영
     - `validation_error`: 유효성 검증 실패 처리
     - `submit_success`: 최종 저장 성공 처리

     #### Step 3e: Section 5 검증 규칙 → `prd_context.validation_rules`

     RULE-XX 블록을 파싱하여 구조화. Implementation Checklist Step 4에서 Zod schema로 직접 매핑:

     ```
     validation_rules = [
       { id: "RULE-01", field: "광고상품명", constraint: "필수 입력", message: "광고상품명을 입력해 주세요" },
       { id: "RULE-02", field: "_videoMediaSpec", constraint: "필수 등록", message: "동영상 소재를 등록해 주세요" },
       { id: "RULE-03", field: "ThumbnailImage", constraint: "필수 등록", message: "썸네일 이미지를 등록해 주세요" },
     ]
     ```

     Zod 매핑 힌트:
     - `필수 입력` / `필수 등록` → `z.string().min(1, { message })` 또는 `z.string().nonempty(message)`
     - `최소 N자` → `z.string().min(N, { message })`
     - `최대 N자` → `z.string().max(N, { message })`
     - `숫자만` → `z.number()` 또는 `z.string().regex(/^\d+$/)`
     - `URL 형식` → `z.string().url({ message })`

     #### Step 3f: Section 4-4 버튼/액션 → `prd_context.actions`

     버튼 테이블을 파싱하여 구조화. mutation 필요 여부와 navigation 타입을 자동 분류:

     ```
     actions = [
       { button: "광고 구분 선택", trigger: "선택", behavior: "해당 구분 탭 표시, 소재 항목 편집 활성화", mutation: false, type: "ui_toggle" },
       { button: "레이아웃 버튼", trigger: "클릭", behavior: "MODAL 레이아웃 설정 화면 이동", mutation: false, type: "navigation_modal" },
       { button: "서드파티 트래커 체크박스", trigger: "선택", behavior: "해당 행위 허용 상태 반영", mutation: false, type: "ui_toggle" },
       { button: "저장 버튼", trigger: "클릭", behavior: "유효성 검증 → 성공: 저장 완료 / 실패: 에러 표시", mutation: true, type: "submit" },
     ]
     ```

     Type 분류 기준:
     - `submit`: API mutation 호출 (저장/수정/삭제)
     - `navigation_modal`: 모달 열기
     - `navigation_page`: 다른 페이지 이동
     - `ui_toggle`: 클라이언트 상태 전환만

     Cancel behavior 추출: 버튼명에 "취소", "닫기", "뒤로" 포함 시 `cancel_behavior` 필드에 별도 저장

     #### Step 3g: Section 6 의존성 → `prd_context.dependencies` + `prd_context.tbd_items`

     의존성 테이블과 TBD 항목을 분리하여 구조화:

     ```
     dependencies = {
       related_screens: ["MODAL 피드형 레이아웃 설정", "MODAL 팝업형 레이아웃 설정"],
       api_hints: ["상품 저장 API", "소재 스펙 등록 API"],
     }

     tbd_items = [
       { id: "G-01", description: "에러 상태 화면 정책 미정" },
       { id: "G-03", description: "동영상 전달 방식(VAST XML vs 직접 URL) 미결" },
     ]
     ```

     → `tbd_items`는 planner.md에 **TBD / Open Questions** 섹션으로 출력하여 구현 시 확인 필요 사항을 명시
4. **Auto-extract Figma URLs from PRD References section** (look for markdown table with `UI 화면`, `Description` rows):
   - Row containing `UI 화면` or `Figma` link → store as `figma_ui_url`
   - Row containing `Description (Figma)` or `node-id` dev link → store as `figma_desc_url`
   - These are treated identically to Figma URLs passed as CLI arguments
5. Store all extracted data as `prd_context` — used to enrich Phase 2–6

**Step 1C: Load spec-validator policy context**

Call `spec-validator guide` to load [F]/[P]/[Data] tag policy context.
Store as `spec_policy` — used in Phase 2 when analyzing Figma description nodes.
Skip this step if no Figma URL is available (neither from args nor from `figma_desc_url`).

**Step 1D: Analyze design sources**

Determine Figma URLs to use:
- Explicit Figma URL from CLI args (highest priority)
- `figma_ui_url` extracted from PRD References (Step 1B)

**If Figma URL is available:**
1. Extract node ID from Figma URL
2. Use Figma MCP tools to gather (**run in parallel with Step 1B**):
   - `get_metadata` - Component structure and hierarchy
   - `get_screenshot` - Visual reference
   - `get_design_context` - Design tokens, spacing, colors, typography
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

**If neither Figma URL nor images are available (Jira-only mode):**
- Generate component structure entirely from PRD:
  - Use Section 4-1 (섹션 구조 트리) as top-level component hierarchy
  - Use Section 4-2 field definitions to identify form fields and their types
  - Map field types to components: `TEXT` → input, `IMAGE`/`VIDEO` → upload component, `ADBADGE` → badge selector, `CTA_BUTTON` → color picker + button
  - Use Section 4-3 state conditions to identify conditional rendering
  - Note in output: "Design source: PRD only — Figma validation not performed"

**Step 1E: Merge PRD context with design analysis**

If `prd_context` exists, merge it with design analysis:
- Use `hasCreate/hasList/hasDetail` flags to determine page structure
- Use `suggested-name` as the feature directory name (override design-inferred name if provided)
- Use `cancel_behavior` (from Section 4-4 actions or Section 7) to add cancel button component specs
- Use `dependencies.api_hints` to pre-populate hook layer planning
- Use `Empty/Loading/Error states` (from Section 7 if exists, or infer from `state_conditions`) to add state UI components
- Use User Story ACs (Section 3) as additional component behavior constraints
- Use `field_component_map` entries with type VIDEO/IMAGE/FILE to trigger File/Media Upload Component Pattern (see conventions: File/Media Upload Pattern)
- Use `field_component_map` → Phase 2에서 컴포넌트 목록 생성 시, 각 필드에 매핑된 컴포넌트를 section 하위 자식으로 배치
- Use `state_conditions` → Phase 4 각 컴포넌트의 **Conditional Rendering** 항목에 직접 매핑 (type별 분류 유지)
- Use `validation_rules` → Implementation Checklist Step 4에서 Zod schema 필드별 매핑 가이드로 반영
- Use `actions` → Phase 5 Data Flow에서 `type: "submit"` 액션을 mutation hook으로, `type: "navigation_modal"` 액션을 modal state로 계획
- Use `tbd_items` → Deliverable에 **TBD / Open Questions** 섹션으로 출력 (구현 시 확인 필요 사항 명시)

---

## Phase 1.5: Project Context Discovery

> **목적**: 기존 프로젝트의 컴포넌트, 훅, 타입, 페이지를 탐색하여 재사용 가능한 자산을 파악합니다.
> 이 Phase의 결과는 Phase 2–5에서 "새로 만들기" vs "기존 재사용" 판단의 근거가 됩니다.

**`pageComponents/` 디렉토리가 존재하지 않는 경우 (신규 프로젝트):**
Phase 1.5 전체를 스킵하고, planner.md에 `"No existing project context — new project"` 표기 후 Phase 2로 진행.

**Run all discovery scans in parallel:**

### Step 1.5A: Discover existing features and pages

```
[Parallel]
1. Glob: pageComponents/*/                → feature 디렉토리 목록
2. Glob: pageComponents/*/planner.md      → planner.md 보유 feature 파악
3. Glob: pages/**/*.tsx                   → 기존 라우트 구조 파악
```

For each feature directory found, note:
- Feature name (directory name)
- Whether `planner.md` exists (= fully planned feature, useful as pattern reference)
- Sub-directory structure (`components/`, `hooks/`, `common/`, `_shared/`)

### Step 1.5B: Discover reusable components

```
[Parallel]
1. Glob: pageComponents/*/components/common/*.tsx     → feature 내 공유 컴포넌트
2. Glob: pageComponents/*/_shared/**/*.tsx            → 도메인 내 공유 컴포넌트
3. Glob: components/**/*.tsx                          → 전역 공유 컴포넌트
4. Glob: packages/ui/src/components/ui/*.tsx           → shadcn/ui 컴포넌트 목록
```

For each discovered component file, extract the component name from the filename (PascalCase convention).
Do NOT read every file — only Read files whose names suggest potential reuse for the current feature (see Step 1.5E).

### Step 1.5C: Discover existing hooks

```
[Parallel]
1. Glob: pageComponents/*/hooks/*.hook.ts   → feature 훅 목록
2. Glob: hooks/*.hook.ts                    → 전역 훅 목록
```

For each hook file, use Grep to extract:
- Hook export name: `Grep: "export const use" in {file}`
- API path constant: `Grep: "_API_PATH" in {file}`

This identifies which API endpoints already have hooks, preventing duplicate hook creation.

### Step 1.5D: Discover existing types and constants

```
[Parallel]
1. Glob: pageComponents/*/components/**/*.types.ts      → 섹션별 타입
2. Glob: pageComponents/*/components/**/*.constants.ts   → 섹션별 상수
```

For type files, use Grep to extract exported interface/type names:
- `Grep: "export (interface|type)" in {file}`

### Step 1.5E: Discover similar patterns (lightweight similarity)

Based on the page type determined in Phase 1 (`hasCreate`, `hasList`, `hasDetail`), search for existing components with matching functional suffixes:

```
If hasList  → Glob: pageComponents/*/components/**/*Filter.tsx,
                     pageComponents/*/components/**/*Table.tsx
If hasCreate → Glob: pageComponents/*/components/**/*Form.tsx,
                      pageComponents/*/components/**/*FormSection.tsx
If hasDetail → Glob: pageComponents/*/components/**/*Detail.tsx,
                      pageComponents/*/components/**/*Info.tsx,
                      pageComponents/*/components/**/*Tab.tsx
```

For the top 1–2 matches of each suffix:
1. Read the first 30 lines to understand props interface and structure
2. Grep for type-switching patterns (`switch`, `case`, `===.*Type`) within the file
3. If type-switching found, Read those sections to map which types are already handled
4. Store as `pattern_references` with `handled_types: string[]` and `extension_points: string[]` fields

### Step 1.5F: Build Project Context Summary

Compile all discovery results into a structured `project_context`:

```
project_context = {
  existing_features: [...],       // feature names + planner.md presence
  existing_pages: [...],          // route paths from pages/
  reusable_components: [...],     // { name, path, scope: 'common'|'_shared'|'global' }
  reusable_hooks: [...],          // { name, path, apiPath }
  existing_types: [...],          // { name, path }
  shadcn_components: [...],       // available shadcn/ui component names
  pattern_references: [...],      // { suffix, existingFile, propsPreview }
}
```

### Step 1.5G: Capability Analysis (기존 컴포넌트 기능 분석)

`pattern_references`의 `handled_types`/`extension_points`와 PRD `field_component_map`을 대조하여 기존 코드 커버리지를 산출합니다.

**절차**:
1. **조건 분기 탐색** — `pattern_references` 파일들에서 `switch|case`, `===.*Type` 패턴을 Grep
2. **커버리지 판정** — `(기존 처리 항목 수 / PRD 전체 필드 수)` = coverage_ratio
3. **접근법 결정**:
   | 커버리지 | 접근법 | 설명 |
   |---|---|---|
   | ≥70% | **EXTEND** | enum + 조건 분기 추가 위주, 새 파일 최소화 |
   | 40~70% | **하이브리드** | 핵심 섹션만 NEW, 나머지 EXTEND |
   | <40% | **NEW** | 별도 페이지/컴포넌트 트리 구성 |
4. **결과 저장** — `project_context.capability_analysis`에 `coverage_ratio`, `recommended_approach`, `extend_targets[]`, `new_targets[]` 기록

**Reuse decision rules (Phase 2–5에서 적용):**
1. 동일 이름 컴포넌트가 `common/` / `_shared/` / `components/`에 존재 → **REUSE**
2. 동일 API 엔드포인트를 호출하는 훅이 존재 → **REUSE**
3. 동일 이름 type/interface 존재 → import로 참조 (재정의 금지)
4. suffix 매칭 컴포넌트가 다른 feature에 존재 → NEW 컴포넌트에 **Pattern Reference** 첨부
5. shadcn/ui에 대응 컴포넌트 존재 → 커스텀 구현 대신 shadcn/ui 사용
6. **기존 컴포넌트가 switch/조건문으로 타입별 분기 처리 중이고, 새 타입 분기만 추가하면 되는 경우 → EXTEND (NEW 금지)**
   - 예: `SpecTable`이 TYPE_A/TYPE_B를 switch로 처리 → 새 TYPE_C 추가는 EXTEND
7. **enum 추가 + 모델 기본값 추가만으로 기존 흐름이 동작하는 경우 → EXTEND**
   - 예: `ProductType` enum에 새 값 추가 + `defaultModel`에 분기 추가 → 기존 create 페이지가 동작
8. **NEW 제안 전 필수 검증: "기존 컴포넌트를 EXTEND해서 해결 가능한가?"** — 가능하면 EXTEND 우선, 불가능한 경우에만 NEW (사유 명시)

---

## Phase 2: Component Structure Planning

> **컨벤션 참조**: 아래 규칙의 상세 내용은 `conventions` 스킬을 참조합니다.
> - Directory Structure Rules (feature-first, co-location, atomic design)
> - Naming Conventions (폴더 kebab-case, 컴포넌트 PascalCase + feature prefix, I prefix 등)
> - File Organization / Pages Router (`pageComponents/` mirrors `pages/`)
> - Inline Props/State in File Structure (다이어그램 표기법)
> - Common / _shared folder rules

> **Project Context 참조**: Phase 1.5에서 수집한 `project_context`를 기반으로:
> - `reusable_components`에 있는 컴포넌트는 새로 계획하지 않고 **REUSE**로 표기
> - `shadcn_components` 목록의 컴포넌트는 커스텀 구현 대신 shadcn/ui 사용
> - `pattern_references`에 매칭되는 패턴이 있으면 새 컴포넌트의 참조로 명시

이 Phase에서는 conventions 규칙과 project_context를 적용하여 디자인 분석 결과를 컴포넌트 트리와 파일 구조로 변환합니다.

---

## Phase 3: Component Type Guidelines

> **컨벤션 참조**: 아래 규칙의 상세 내용은 `conventions` 스킬을 참조합니다.
> - Component Definition Pattern (arrow function, export default, props interface 5개 기준)
> - Component Type Guidelines (memo, data fetching strategy)
> - React Optimization (memo, useMemo, useCallback)

이 Phase에서는 각 컴포넌트의 memo 사용 여부, 데이터 fetching 위치, 최적화 전략을 결정합니다.

---

## Phase 4: Component Planning Output

For each component, document:

0. **Source**:
   - `REUSE`: 그대로 import, 수정 없음 (import path만 명시, full spec 생략)
   - `EXTEND`: 기존 파일에 조건 분기/enum/기본값 추가 (수정 대상 파일 + 변경 내용 명시)
   - `NEW`: 완전 새 파일 생성 (full spec 작성)
   - `NEW` + **Pattern Reference**: 새 파일이지만 기존 패턴 참조
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
**Source**: NEW
**Purpose**: Main event page layout

**Components Used**:
- EventRanking (NEW)
- EventDetails (NEW)
- EventStatusBadge (REUSE — `pageComponents/event/components/common/EventStatusBadge.tsx`)

---

## Component: EventStatusBadge (REUSE)

**Source**: REUSE `pageComponents/event/components/common/EventStatusBadge.tsx`
**Import**: `import EventStatusBadge from '@/pageComponents/event/components/common/EventStatusBadge'`
**Purpose**: Displays event status — already exists, reuse as-is

---

## Component: EventRanking (NEW)

**Path**: `pageComponents/event/components/ranking/EventRanking.tsx`
**Source**: NEW
**Pattern Reference**: `pageComponents/partner/components/list/PartnerList.tsx` (similar list pattern)
**Memo**: Yes - receives stable eventId prop
**Purpose**: Displays event ranking list with filtering

**Props**: `{ eventId: string }`

**State**:
- `filterType` (useState<string>) - Current filter selection

**Data Fetching**:
- `useEventRankingQuery({ eventId, filterType })` - API query hook (pure fetching)
- `useEventRanking(eventId)` - Wrapper hook (if mutations or data transform needed)

**Children Components**:
- EventRankingItem (NEW)
- EventRankingFilter (NEW)

**Styling**:
- Container: `flex flex-col gap-4 p-6`
- Background: `bg-white`
- Border: `border border-gray-200 rounded-lg`

---

## Component: EventRankingItem (NEW — with interface example - more than 5 props)

**Path**: `pageComponents/event/components/ranking/EventRankingItem.tsx`
**Source**: NEW
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
Note: REUSE components only need Source + Import + Purpose. Full spec is omitted.
Note: EXTEND components list target file + specific changes only. No full spec needed.

---

## Component: FeatureSpecTable (EXTEND)

**Source**: EXTEND `pageComponents/[feature]/components/spec/FeatureSpecTable.tsx`
**변경 내용**: switch에 `NEW_TYPE_A`/`NEW_TYPE_B` case 추가, 특정 조건부 disable 로직 추가

## Enum: variables.ts (EXTEND)

**Source**: EXTEND `utils/variables.ts`
**변경 내용**: `FeatureType.NEW_VALUE`, `SpecType.NEW_A/NEW_B` 추가
````

---

## Phase 5: Data Flow Planning

> **컨벤션 참조**: 아래 규칙의 상세 내용은 `conventions` 스킬을 참조합니다.
> - Two-Layer Hook Pattern (API query hook + wrapper hook)
> - When to Use Each Layer (목록 페이지는 항상 2-layer)
> - Type & State Definitions (co-located per folder)
> - State Management (useState, React Query, React Hook Form, Zustand)

> **Hook 재사용 참조**: Phase 1.5에서 수집한 `reusable_hooks`를 확인하여:
> - 동일 API 엔드포인트를 호출하는 훅이 이미 존재하면 **REUSE**로 표기하고 import 경로만 명시
> - 유사한 패턴의 훅이 있으면 **Pattern Reference**로 명시
> - 전역 `hooks/` 디렉토리의 공통 훅 (예: `useCompaniesQuery`)은 반드시 재사용

이 Phase에서는 conventions의 Two-Layer Hook Pattern과 project_context의 훅 재사용 정보를 적용하여 각 컴포넌트의 데이터 흐름과 훅 구조를 계획합니다.

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
   - **Project Context Summary** (discovered features, reusable components/hooks/types — from Phase 1.5)
   - File Structure Diagram (pages/ and pageComponents/ organization)
   - Component Details Table (name, path, **source**, memo, props, state, data fetching, purpose)
   - Data Flow Diagram (React Query hooks → Components, with **REUSE** hooks marked)
   - URL State (schema with keys/types/defaults/triggers, or "Not needed" with reason)
   - PRD Context Summary (if Jira issue key was provided)
   - **PRD Field → Component Mapping** (if Jira issue key was provided — from `prd_context.field_component_map`)
   - **Validation Rules** (if Jira issue key was provided — from `prd_context.validation_rules`)
   - **TBD / Open Questions** (if Jira issue key was provided — from `prd_context.tbd_items`)
   - Implementation Checklist (ordered steps for coding — see template below)

### Project Context Summary Template

Include this section at the top of every planner.md output (skip if Phase 1.5 was skipped):

````markdown
## Project Context (Auto-Discovered)

### Existing Features
- `pageComponents/partner/` — Partner management (has planner.md)
- `pageComponents/event/` — Event management (has planner.md)

### Reusable Components
| Component | Path | Scope |
|---|---|---|
| StatusBadge | `components/StatusBadge.tsx` | global |
| EventStatusBadge | `pageComponents/event/components/common/EventStatusBadge.tsx` | common |

### Reusable Hooks
| Hook | Path | API Path |
|---|---|---|
| useMastersQuery | `hooks/useMastersQuery.hook.ts` | `/api/v1/masters` |

### Pattern References
| Suffix | Existing File | Relevance |
|---|---|---|
| *Filter | `pageComponents/partner/components/filter/PartnerFilter.tsx` | Similar list filter pattern |
| *Table | `pageComponents/partner/components/table/PartnerTable.tsx` | Similar table with pagination |
````

### PRD Field → Component Mapping Template

Include this section when Jira issue key was provided (from `prd_context.field_component_map`):

````markdown
## PRD Field → Component Mapping

| PRD 필드 | 타입 | 컴포넌트 | 필수 | 제약/비고 |
|---|---|---|---|---|
| 광고상품명 | TEXT | Input | Y | 필수 입력 |
| _videoMediaSpec | VIDEO | VideoUpload | Y | D-01, Upload method TBD |
| ThumbnailImage | IMAGE | ImageUpload | Y | D-02, Upload method TBD |
| AdBadge | ADBADGE | BadgeSelector | N | 리모트 무료 시 disable (P-01) |
| Button | CTA_BUTTON | ColorPicker + ButtonPreview | N | 기본값 #EDEDED (P-02) |
| AdProfile | IMAGE | ImageUpload | N | D-05 |
| Advertiser | TEXT | Input | N | D-06 |
| AdText | TEXT | Input | N | D-07 |
````

### Validation Rules Template

Include this section when Jira issue key was provided (from `prd_context.validation_rules`):

````markdown
## Validation Rules (from PRD)

| Rule | Field | Constraint | Error Message | Zod Hint |
|---|---|---|---|---|
| RULE-01 | 광고상품명 | 필수 입력 | 광고상품명을 입력해 주세요 | `z.string().min(1)` |
| RULE-02 | _videoMediaSpec | 필수 등록 | 동영상 소재를 등록해 주세요 | `z.string().min(1)` |
| RULE-03 | ThumbnailImage | 필수 등록 | 썸네일 이미지를 등록해 주세요 | `z.string().min(1)` |
````

### TBD / Open Questions Template

Include this section when `prd_context.tbd_items` is non-empty:

````markdown
## TBD / Open Questions

> 아래 항목은 PRD에서 미결로 표시된 사항입니다. 구현 전 확인이 필요합니다.

- [ ] G-01: 에러 상태 화면 정책 미정
- [ ] G-03: 동영상 전달 방식(VAST XML vs 직접 URL) 미결
````

### Implementation Checklist Template

Include this ordered checklist in every planner.md output:

```markdown
## Implementation Checklist

### Step 0: Verify Reusable Assets
- [x] Confirmed reusable components: [list from project_context with import paths]
- [x] Confirmed reusable hooks: [list from project_context with import paths]
- [x] Confirmed existing types to import: [list from project_context with import paths]

### Step 0.5: Verify Extension Points (EXTEND 접근법일 때)
- [ ] 기존 enum/변수 파일의 확장 포인트 확인: [파일 목록 + 추가할 값]
- [ ] 기존 모델/기본값의 확장 포인트 확인: [파일 목록 + 추가할 분기]
- [ ] 기존 컴포넌트의 조건 분기 확장 포인트 확인: [파일 목록 + 추가할 case]
- [ ] 새로 생성이 반드시 필요한 파일 확인: [파일 목록 + 필요 사유]

### Step 1: Types & Constants
- [ ] Define API request/response types in query hook file (skip if REUSE hook covers it)
- [ ] Define component-specific types in `[section].types.ts` (only if needed, check existing types first)
- [ ] Define constants/enums in `[section].constants.ts` (only if needed)

### Step 2: API Hooks
- [ ] Import REUSE hooks: [list with import paths]
- [ ] Implement NEW `use[Feature]Query.hook.ts` (pure fetch layer)
- [ ] Implement NEW `use[Feature].hook.ts` (wrapper: mutations + data transform) — only if needed

### Step 3: Page Entry Points
- [ ] Create `pages/[route].tsx` with minimal layout
- [ ] Wire Section component as the only child

### Step 4: Form Schema (hasCreate || hasDetail)
- [ ] Define Zod schema in `form/schema/[feature]-form.schema.ts`
- [ ] Map all [E] fields from PRD field definition table
- [ ] Add validation rules matching PRD RULE-XX entries

### Step 5: Section Components (top-down)
- [ ] Implement root Section component (FormProvider if form page)
- [ ] Import REUSE components: [list with import paths]
- [ ] Implement NEW sub-sections in order: [list section names from design]
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
