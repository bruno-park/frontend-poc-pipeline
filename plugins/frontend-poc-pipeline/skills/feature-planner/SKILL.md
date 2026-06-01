---
name: feature-planner
description: "Figma 화면 / Jira PRD / 평범한 Jira 티켓 / 디자인 이미지 — 어느 입력이든 받아 컴포넌트 구조·데이터 흐름·URL state·구현 체크리스트를 담은 planner.md(구현 청사진)를 pageComponents/[feature]/에 생성합니다. Jira description에 박힌 Confluence 기획 스펙 링크를 자동 추적하고, 번호 섹션이 없는 산문형 티켓도 의미 기반으로 추출합니다. Triggers: (1) '화면 기획', '컴포넌트 계획', 'planner.md 작성', 'feature plan', 'screen plan', (2) '/feature-planner' + Figma URL 또는 Jira 이슈 키, (3) 'PRD/티켓에서 구현 계획 뽑아줘', '이 화면 어떻게 짤지 계획해줘', (4) 구현(TDD) 직전 설계 산출물이 필요할 때. 단순 PRD 작성(figma-jira-prd)이나 Figma↔PRD 갭 검증(figma-prd-validator)과는 다릅니다 — 이 스킬은 '구현 계획'을 만듭니다."
---

# Feature Planner — 입력 무관 구현 계획 생성기 (with File Output)

Figma 디자인 / Jira PRD / 평범한 Jira 티켓 / 디자인 스크린샷을 분석해 컴포넌트 구조를 계획하고, URL state 동기화 필요 여부를 판단하며, 결과를 **`planner.md`로 `pageComponents/[feature]/`에 저장**한다. TDD 구현(`/test-writer` → `/code-writer`) 직전의 설계 산출물이다.

> **컨벤션 참조**: 디렉토리 구조, 네이밍, 파일 조직, 컴포넌트/훅 패턴, 스타일링은 모두 `conventions` 스킬을 따른다.
> **상세 절차는 `references/`로 분리**: 구조화 PRD 추출 → [[prd-extraction.md]], 산문형 티켓 추출 → [[plain-ticket-extraction.md]], 출력 형식·템플릿 → [[output-templates.md]].

## Arguments

- `$1` — **Figma URL** (optional): node-id 포함 Figma 디자인 URL
- `$2, $3, …` — **Image paths** (optional): 디자인 스크린샷 파일 경로
- **Jira issue key** (optional, 위치 무관): `AX-70`, `WP-1234` 등 — 제공 시 Jira에서 스펙을 가져와 plan을 자동 보강
- 마지막 인자 — **Optional context**: 추가 요구사항

Figma URL 또는 이미지 중 최소 하나(또는 Jira 키만)면 동작한다.

```bash
/feature-planner "https://figma.com/design/abc?node-id=123-456"
/feature-planner "https://figma.com/design/abc?node-id=123-456" WP-9137
/feature-planner WP-9137                     # Jira-only (Figma 없이 PRD/티켓만)
/feature-planner WP-9137 "/path/to/design.png"
```

## Output File Rules

1. **디렉토리**: `pageComponents/[feature]/` — `/code-writer`가 생성할 코드와 colocate
2. **파일명**: 항상 `planner.md`
3. **feature 디렉토리**: Phase 1 분석에서 결정 (Jira `suggested-name` 우선)
4. 이미 존재하면 overwrite, 없으면 `mkdir -p pageComponents/[feature]`

---

## Phase 1: Design Analysis + Spec Context Loading

### Step 1A: 인자 파싱

모든 인자를 분류한다: Figma URL(`http` + `figma.com`) · 이미지 경로(로컬 파일) · Jira 키(`[A-Z]+-\d+`) · optional context(나머지 마지막 인자).

### Step 1B: Jira에서 스펙 컨텍스트 로드 (이슈 키 제공 시)

1. **Jira 인스턴스 → MCP 도구 매핑** (도메인 비종속):
   - 이슈가 속한 Jira host를 보고, 사용 가능한 `mcp-atlassian-*` 인스턴스 중 그 host를 다루는 것을 선택한다. **특정 사내 host를 코드에 가정하지 않는다.**
   - 매핑 예시 (환경에 존재하는 인스턴스에 맞춰 사용): `*.atlassian.net` host A → `mcp__mcp-atlassian-<instanceA>__jira_get_issue`, host B → `…-<instanceB>__…`
   - 적합한 인스턴스가 없거나 fetch 실패 → **경고 후 design-only로 진행** (graceful fallback)
2. **이슈 fetch**: `fields: summary, description, parent, issuetype`
   - `parent` → 에픽 summary로 feature 도메인 추론
   - `issuetype` → 작업/버그/스토리 구분
   - `description`만으로 충분 — `*all`/`renderedFields` 불필요
3. **추출 경로 결정** (description 형식에 따라 분기):
   - **번호 섹션(`figma-jira-prd` 양식, Section 4-1~7)이 있으면** → [[prd-extraction.md]]의 고정밀 절차(Step 3a~3g) 수행
   - **번호 섹션이 없는 산문형 티켓이면** → [[plain-ticket-extraction.md]]의 의미 기반 추출 수행 (표·체크박스·팝업 서술·AC 목록에서 `field_component_map`·`state_conditions`·`validation_rules` 추론)
   - 두 경로 모두 동일한 `prd_context` 구조를 채운다
4. 추출 결과를 `prd_context`로 저장 — Phase 2~6 보강에 사용

### Step 1B-2: Confluence 기획 스펙 링크 추적 (NEW)

실무 티켓은 핵심 정책을 **Confluence에 두고 Jira에서 링크만 거는** 경우가 많다. 이를 놓치지 않기 위해:

1. Step 1B에서 가져온 `description`에서 Confluence 링크를 감지: `…/wiki/spaces/{SPACE}/pages/{PAGE_ID}/…` 패턴
2. `{PAGE_ID}`(숫자) 추출 → 해당 host에 맞는 인스턴스의 `confluence_get_page` 호출:
   - `page_id: {PAGE_ID}`, `convert_to_markdown: true`, `include_metadata: true`
   - (인스턴스 선택은 Step 1B의 host→MCP 매핑과 동일 원칙)
3. 가져온 본문을 **Step 1B 추출의 1차 소스로 병합** — Confluence 스펙이 Jira description보다 상세하면 그것을 우선한다
4. 여러 링크가 있으면 "기획 스펙"/"스펙"/"정책" 문구에 가까운 링크부터 시도
5. 실패(접근 불가/페이지 없음) 시 경고 후 Jira description만으로 진행

> Why: Jira description만 읽으면 "📄 기획 스펙: Confluence …" 한 줄 뒤의 진짜 정책 전문을 통째로 놓친다. 이 단계가 planner.md의 충실도를 결정한다.

### Step 1C: spec-validator 정책 컨텍스트 로드

`spec-validator guide`를 호출해 [F]/[P]/[Data] 태그 정책을 로드, `spec_policy`로 저장 (Phase 2에서 Figma description 노드 분석에 사용). Figma URL이 전혀 없으면 스킵.

### Step 1D: 디자인 소스 분석

사용할 Figma URL 결정: CLI 인자(최우선) → PRD References에서 추출한 `figma_ui_url`.

**Figma URL 있으면** (Step 1B와 병렬 실행): `get_metadata`(구조) · `get_screenshot`(시각) · `get_design_context`(토큰) 수집 후 `spec_policy`로 description 노드 검증.
**이미지 경로 있으면**: Read로 스크린샷 분석 — 시각 계층·인터랙티브 요소·재사용 패턴·상태(loading/error/empty)·데이터 흐름·반응형.
**둘 다 없으면 (Jira-only 모드)**: `prd_context`만으로 컴포넌트 구조 생성 — 섹션 구조를 최상위 계층으로, 필드 정의를 폼 필드로, 상태 조건을 조건 렌더로 매핑. planner.md에 `"Design source: Jira/Confluence only — Figma 검증 미수행"` 명시.

### Step 1E: PRD context ↔ 디자인 분석 병합

`prd_context`가 있으면 디자인 분석과 병합한다. 병합 규칙 상세는 [[prd-extraction.md]] Step 1E 참조 (page type→구조, suggested-name→디렉토리, field_component_map→컴포넌트, state_conditions→조건 렌더, validation_rules→Zod, actions→데이터 흐름, tbd_items→TBD 섹션).

---

## Phase 1.5: Project Context Discovery

> **목적**: 기존 컴포넌트·훅·타입·페이지를 탐색해 "새로 만들기 vs 재사용" 판단 근거를 만든다. Phase 2~5의 입력.

`pageComponents/`가 없으면 (신규 프로젝트) 전체 스킵, planner.md에 `"No existing project context — new project"` 표기 후 Phase 2로.

**모든 탐색은 병렬 실행:**

- **Step 1.5A 기존 feature/page**: Glob `pageComponents/*/`, `pageComponents/*/planner.md`, `pages/**/*.tsx`
- **Step 1.5B 재사용 컴포넌트**: Glob `pageComponents/*/components/common/*.tsx`, `pageComponents/*/_shared/**/*.tsx`, `components/**/*.tsx`, `packages/ui/src/components/ui/*.tsx`. 파일명에서 컴포넌트명(PascalCase) 추출, 현 feature에 재사용 가능성 있는 것만 Read.
- **Step 1.5C 기존 훅**: Glob `pageComponents/*/hooks/*.hook.ts`, `hooks/*.hook.ts`. Grep으로 `export const use`·`_API_PATH` 추출 → 어떤 엔드포인트에 훅이 이미 있는지 파악(중복 생성 방지).
- **Step 1.5D 타입/상수**: Glob `*.types.ts`, `*.constants.ts`. Grep `export (interface|type)`.
- **Step 1.5E 유사 패턴**: page type별 suffix 검색 — hasList→`*Filter.tsx`/`*Table.tsx`, hasCreate→`*Form.tsx`/`*FormSection.tsx`, hasDetail→`*Detail.tsx`/`*Info.tsx`/`*Tab.tsx`. 상위 1~2개를 Read하여 props·switch/case 타입 분기 파악 → `pattern_references`에 `handled_types`/`extension_points` 저장.
- **Step 1.5F**: 결과를 `project_context`(existing_features, existing_pages, reusable_components, reusable_hooks, existing_types, shadcn_components, pattern_references)로 종합.
- **Step 1.5G Capability Analysis**: `pattern_references`의 handled_types와 PRD `field_component_map` 대조 → `coverage_ratio` 산출. ≥70% **EXTEND** / 40~70% **하이브리드** / <40% **NEW**. `capability_analysis`에 저장.

**Reuse decision rules (Phase 2~5 적용):**
1. 동일 이름 컴포넌트가 common/_shared/components에 존재 → **REUSE**
2. 동일 API 엔드포인트 훅 존재 → **REUSE**
3. 동일 이름 type/interface 존재 → import 참조 (재정의 금지)
4. suffix 매칭 컴포넌트가 타 feature에 존재 → NEW에 **Pattern Reference** 첨부
5. shadcn/ui 대응 컴포넌트 존재 → 커스텀 대신 shadcn/ui
6. 기존 컴포넌트가 switch/조건문으로 타입 분기 중 + 새 타입만 추가 → **EXTEND** (NEW 금지)
7. enum + 모델 기본값 추가만으로 동작 → **EXTEND**
8. **NEW 제안 전 필수: "기존을 EXTEND해서 가능한가?"** — 가능하면 EXTEND 우선, 불가능할 때만 NEW(사유 명시)

---

## Phase 2: Component Structure Planning

> **컨벤션 참조**: Directory Structure, Naming, File Organization(Pages Router), Inline Props/State 표기, common/_shared 규칙은 `conventions` 스킬.
> **Project Context 참조**: `reusable_components`는 REUSE 표기, `shadcn_components`는 shadcn/ui 사용, `pattern_references` 매칭 시 참조 명시.

conventions 규칙 + project_context를 적용해 디자인 분석을 컴포넌트 트리와 파일 구조로 변환한다.

## Phase 3: Component Type Guidelines

> **컨벤션 참조**: Component Definition Pattern, memo 사용 기준, data fetching 위치, React 최적화(memo/useMemo/useCallback)는 `conventions` 스킬.

각 컴포넌트의 memo 여부·데이터 fetching 위치·최적화 전략을 결정한다.

## Phase 4: Component Planning Output

컴포넌트별 문서화 항목(Source/Memo/Props/State/Data Fetching/Conditional Rendering/UI States/Cancel Behavior)과 Example Output 형식은 **[[output-templates.md]]** 참조.

## Phase 5: Data Flow Planning

> **컨벤션 참조**: Two-Layer Hook Pattern, When to Use Each Layer, Type/State 정의, State Management(useState/React Query/RHF/Zustand)는 `conventions` 스킬.
> **Hook 재사용**: `reusable_hooks`에 동일 엔드포인트 훅 있으면 REUSE + import 경로만. 전역 `hooks/` 공통 훅(예: `useCompaniesQuery`)은 반드시 재사용.

conventions의 Two-Layer Hook Pattern + project_context 훅 재사용 정보를 적용해 데이터 흐름을 계획한다.

---

## Phase 6: URL State Analysis

페이지가 URL query param 동기화(상태 영속)를 필요로 하는지 판단한다.

**필요한 경우**: 페이지네이션·정렬·필터가 있는 목록/테이블, URL 공유로 동일 뷰 재현, 새로고침 후에도 살아야 하는 검색/필터, 북마크 가능한 탭/뷰 모드.
**불필요한 경우**: 상세 페이지(ID가 라우트에 있음), 폼/생성 페이지, 필터 없는 대시보드, 모달/다이얼로그(부모가 상태 보유).

**필요 시 출력 형식:**
````markdown
## URL State
**Needed**: Yes — 페이지네이션·정렬·필터가 있는 목록 페이지.
### Schema
| Key | Type | Default | Trigger |
|-----|------|---------|---------|
| page | number | 1 | 페이지네이션 클릭 |
| size | number | 25 | 페이지 크기 변경 |
| sortColumn | string | 'created_at' | 컬럼 헤더 클릭 |
| q | string | '' | 검색 제출 |
| status | string | '' | 상태 필터 |
### Behavior
- 초기 로드: clean URL (기본값은 내부 사용). 비기본값만 URL에 노출.
- 필터/size 변경 시 page=1 리셋(page param 제거). 직접 URL 접근/뒤로가기 시 상태 복원.
````
**불필요 시:**
````markdown
## URL State
**Needed**: No — [detail/form/dashboard] 페이지. 상태는 [useState/RHF/Zustand]로 관리.
````

---

## Context Priority

마지막 인자가 optional context면 **최우선** — context 지시를 따르고, 충돌 시 기본값 override, 표준 구조에서 벗어난 점은 문서화한다.

---

## Deliverable & File Save

모든 Phase 완료 후 plan을 파일로 저장한다:

1. 디자인/스펙 분석에서 feature명 결정 (`suggested-name` 우선)
2. `mkdir -p pageComponents/[feature]`
3. 전체 plan을 `pageComponents/[feature]/planner.md`에 작성
4. 필수 구성 항목과 모든 템플릿(Project Context Summary, PRD Field Mapping, Validation Rules, TBD, Implementation Checklist)은 **[[output-templates.md]]** 참조

### 저장 후 안내
```
Plan saved to: pageComponents/[feature]/planner.md
To implement, run: /code-writer --all "pageComponents/[feature]/planner.md"
```

---

## Usage Examples

```bash
/feature-planner "https://figma.com/design/abc?node-id=123-456"          # Figma만
/feature-planner WP-9137                                                 # Jira-only (PRD/티켓)
/feature-planner "https://figma.com/design/abc?node-id=123-456" WP-9137  # Figma + Jira (권장)
/feature-planner "/path/to/design-desktop.png" "/path/to/design-mobile.png"
/feature-planner "https://figma.com/design/abc?node-id=123-456" "모바일 우선으로"
```
