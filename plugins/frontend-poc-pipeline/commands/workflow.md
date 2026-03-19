---
allowed-tools: Read, Glob, Grep, Bash, mcp__mcp-atlassian-nestads__jira_get_issue, mcp__mcp-atlassian-nestads__jira_get_issue_development_info
argument-hint: [JIRA-TICKET] [--status] [--hotfix]
description: AI 개발 파이프라인 가이드 — 현재 단계를 진단하고 다음 커맨드를 안내합니다
model: claude-sonnet-4-6
---

# Frontend AI Pipeline — Workflow Guide

```
/workflow WP-1234          → 티켓 기준 현재 단계 진단 + 다음 커맨드 안내
/workflow WP-1234 --status → 전체 단계 진행 상태 표시
/workflow                  → 전체 파이프라인 참고 문서 출력
/workflow --hotfix         → 긴급 핫픽스 fast-path 안내
```

---

## 전체 파이프라인 한눈에 보기

```
┌─────────────────────────────────────────────────────────────────────┐
│                  STANDARD PIPELINE (11 Phases)                      │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  [0] PRD          figma-jira-prd        Figma+Jira → AC 작성        │
│  [1] 브랜치        branch-from-ticket    feature 브랜치 생성          │
│  [2] 화면 설계     /planner              planner.md 생성             │
│                                                                     │
│  ┌──────────────────────────────┐                                   │
│  │  [3] API 훅   api-integration │ ← 병렬 시작 가능                  │
│  │  [4] 테스트   /test-writer    │ ← Phase 2 완료 후 동시 진행 OK    │
│  └──────────────────────────────┘                                   │
│                                                                     │
│  [5] 구현 GREEN   /code-writer --ui     테스트 GREEN 목표            │
│  [6] 리팩터       /refactor             코드 정리 + 테스트 유지       │
│  [7] 커버리지     coverage-report       ≥ 80% 달성                  │
│  [8] 코드 리뷰    code-review           Critical 이슈 0개            │
│  [9] 문서화       confluence-update     기술 문서 업데이트             │
│  [10] PR 작성    pull-request-description  MR/PR 생성               │
│                                                                     │
├─────────────────────────────────────────────────────────────────────┤
│                  HOTFIX PIPELINE (5 Phases)                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  [H1] 브랜치      branch-from-ticket --hotfix                        │
│  [H2] 최소 테스트  /test-writer --unit                               │
│  [H3] 수정        /code-writer                                       │
│  [H4] 코드 리뷰   code-review                                        │
│  [H5] PR 작성     pull-request-description                           │
│                                                                     │
│  → /hotfix WP-XXXX  으로 전체 fast-path 안내                         │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Quality Gate — 각 Phase 합격 기준

각 Phase는 아래 기준을 **모두 충족**해야 다음 단계로 진행합니다.

| Phase | 합격 기준 | 실패 시 |
|-------|----------|---------|
| **[2] planner.md** | 파일 존재 + URL State 섹션 포함 + 구현 체크리스트 완성 | `/planner` 재실행 |
| **[3] API 훅** | `.hook.ts` 파일 존재 + TypeScript 타입 정의 + API path 상수 export | `api-integration` 재실행 |
| **[4] 테스트 RED** | AC 100% 커버 + 모든 테스트 FAIL + `data-testid` 없음 + RBAC 시나리오 포함 | 테스트 강화 후 재실행 |
| **[6] 리팩터** | 모든 테스트 PASS + `console.log` 없음 + `px` 단위 없음 + 미사용 import 없음 | 리팩터 후 재실행 |
| **[7] 커버리지** | Statements/Branches/Functions/Lines ≥ 80% + AC 커버리지 100% | 테스트 보강 후 재실행 |
| **[8] 코드 리뷰** | Critical/High 이슈 0개 + 컨벤션 위반 0개 | 수정 후 재실행 |

---

## Phase 진단 (티켓 번호 있을 경우)

Jira 티켓 번호가 주어지면 아래 기준으로 현재 단계를 자동 진단합니다.

### 1. Jira 티켓 정보 조회

```
mcp__mcp-atlassian-nestads__jira_get_issue(issue_key="WP-XXXX")
```

### 2. 로컬 파일 상태 확인 (병렬 실행)

```
Glob: pageComponents/*/planner.md           → Phase 2 완료 여부
Glob: pageComponents/*/hooks/*.hook.ts      → Phase 3 완료 여부
Glob: pageComponents/**/*.test.tsx          → Phase 4 완료 여부
Glob: pageComponents/**/*.tsx (구현 파일)    → Phase 5 완료 여부
Glob: e2e/**/*.spec.ts                      → E2E 테스트 존재 여부
Bash: git branch --show-current             → 브랜치 생성 여부 (Phase 1)
```

### 3. 테스트 상태 확인

```bash
npx vitest run pageComponents/[feature] --reporter=verbose 2>&1 | tail -5
```

- 파일 없음 (import error) → Phase 4 완료, Phase 5 미완료
- 모두 FAIL → RED 상태 (Phase 5 진행 필요)
- 모두 PASS → GREEN 상태 (Phase 6 이상)

### 4. 진단 결과 출력

```
## 현재 단계 진단 — WP-1234

티켓: [summary]
담당자: [assignee]
상태: In Progress

진행 현황:
  ✅ Phase 0  PRD 작성 완료 (Jira 설명 있음)
  ✅ Phase 1  브랜치 생성 (feature/WP-1234-partner-list)
  ✅ Phase 2  화면 설계 완료 (pageComponents/partner/planner.md)
  ✅ Phase 3  API 훅 생성 완료 (usePartnerQuery.hook.ts)
  ✅ Phase 4  테스트 작성 완료 (RED 상태 확인됨)
  🔄 Phase 5  구현 중 (일부 테스트 PASS)
  ⬜ Phase 6  리팩터링 대기
  ⬜ Phase 7  커버리지 리포트 대기
  ⬜ Phase 8  코드 리뷰 대기
  ⬜ Phase 9  문서화 대기
  ⬜ Phase 10 PR 작성 대기

👉 다음 단계:
  /code-writer --ui pageComponents/partner/planner.md
```

---

## 전체 파이프라인 상세

### Phase 0 — 기획: PRD 작성

**언제**: Figma 디자인 + Jira 티켓이 준비된 시점

**커맨드**:
```bash
/figma-jira-prd [figma-url] [jira-ticket-url]
```

**산출물**: Jira 티켓에 PRD 업로드 (AC, 예외 케이스, 컴포넌트 힌트)

**Quality Gate**: Jira 티켓 description에 AC 목록 존재

---

### Phase 1 — 브랜치 생성

**언제**: 티켓 작업 시작 시

**커맨드**:
```bash
/branch-from-ticket WP-1234
```

**산출물**: `feature/WP-1234-[kebab-summary]` 브랜치

**Quality Gate**: `git branch --show-current` 결과가 feature 브랜치

---

### Phase 2 — 화면 설계: planner.md 생성

**언제**: 브랜치 생성 후, 구현 시작 전

**커맨드**:
```bash
/planner [figma-url]
/planner [screenshot.png]
```

**산출물**: `pageComponents/[feature]/planner.md`
- 컴포넌트 트리 + props/state
- URL State 스키마 (목록 페이지)
- React Query 훅 계획
- 구현 체크리스트
- 접근성 고려사항 (인터랙티브 요소 aria, 키보드 탐색)

**Quality Gate**: `pageComponents/[feature]/planner.md` 파일 존재 + URL State 섹션 포함

---

### Phase 3 — API 훅 생성 ← Phase 2 완료 후 Phase 4와 병렬 진행 가능

**언제**: planner.md 완성 후 (Phase 4와 동시 시작 가능)

**커맨드**:
```bash
/api-integration WP-1234
```

**산출물**: `pageComponents/[feature]/hooks/`
- `use[Feature]Query.hook.ts` — 순수 API 호출 + 타입 정의
- `use[Feature].hook.ts` — 비즈니스 로직 + 뮤테이션 (목록 페이지 필수)

**Quality Gate**: hooks 디렉토리에 `.hook.ts` 파일 존재 + TypeScript 타입 export

**에러 핸들링 원칙**:
- 모든 Query Hook에 `refetchOnWindowFocus: false` 기본 설정
- 네트워크 에러는 React Query의 `retry: 1` 활용
- Mutation 에러는 `onError` 콜백에서 toast 알림

---

### Phase 4 — TDD RED: 테스트 먼저 작성 ← Phase 3와 병렬 진행 가능

**언제**: Phase 2(planner.md) 완성 후 (Phase 3와 동시 진행 가능)

**커맨드**:
```bash
/test-writer --unit WP-1234    # 단위 테스트
/test-writer --e2e WP-1234     # E2E 테스트
/test-writer --all WP-1234     # 둘 다 (권장)
```

**산출물**:
- `pageComponents/[feature]/**/*.test.tsx` (RED 상태)
- `e2e/[feature]/[feature].spec.ts`
- Jira 테스트 케이스 목록 코멘트

**Quality Gate**:
- AC 항목 100% 테스트 커버
- 모든 단위 테스트 FAIL (구현 없음)
- RBAC 시나리오 포함 (master/finance/CS)
- `data-testid` 셀렉터 사용 없음
- 접근성 테스트 포함 (키보드 탐색, ARIA role 검증)

> ⚠️ 이 단계 없이 Phase 5 진행 시 TDD 위반

---

### Phase 5 — TDD GREEN: 구현

**언제**: RED 테스트 작성 후

**커맨드**:
```bash
/code-writer --ui pageComponents/[feature]/planner.md
/code-writer --ui pageComponents/[feature]/planner.md --mock  # API 미완성 시
```

**내부 동작**: `ui-builder` 스킬에 위임

**산출물**: `pageComponents/[feature]/components/**/*.tsx`
- shadcn/ui 우선, rsuite fallback
- URL State 자동 연동 (planner.md 기준)
- memo/useMemo/useCallback 최적화 적용
- 모든 인터랙티브 요소에 aria-label / role 속성 포함
- 키보드 탐색 지원 (Tab, Enter, Esc)

**Quality Gate**:
```bash
npx vitest run pageComponents/[feature]  # 모든 테스트 PASS
```

---

### Phase 6 — TDD REFACTOR: 코드 정리

**언제**: 모든 테스트 GREEN 확인 후

**커맨드**:
```bash
/refactor pageComponents/[feature]/planner.md
```

**체크 항목**:
- 사용하지 않는 import / console.log 제거
- 네이밍 컨벤션 (itemList, handleClick, isLoading)
- `px` → `rem` 단위 교체
- 중복 로직 추출
- memo/useMemo/useCallback 최적화
- 에러 바운더리 누락 확인
- TypeScript any 타입 제거

**Quality Gate**: 리팩터 후에도 모든 테스트 PASS + 코드 스멜 0건

---

### Phase 7 — 커버리지 리포트

**언제**: REFACTOR 완료 후

**커맨드**:
```bash
/coverage-report WP-1234
```

**산출물**: Jira 티켓에 커버리지 수치 + AC 커버리지 코멘트

**Quality Gate**: Statements/Branches/Functions/Lines ≥ 80% AND AC 커버리지 100%

---

### Phase 8 — 코드 리뷰

**언제**: 커버리지 확인 후

**커맨드**:
```bash
/code-review
```

**체크 항목**:
- 로직 결함, SOLID 원칙, 보안, 성능, 컨벤션 준수
- 접근성 (ARIA, 키보드 탐색, 색상 대비)
- 번들 사이즈 영향 (대형 라이브러리 신규 import 여부)
- XSS / 데이터 노출 취약점

**Quality Gate**: Critical/High 이슈 0개 + 컨벤션 위반 0개

---

### Phase 9 — 기술 문서화

**언제**: 코드 리뷰 통과 후

**커맨드**:
```bash
/confluence-update WP-1234
```

**산출물**: Confluence 기술 문서 (컴포넌트 구조, 훅, URL State, 테스트 현황)

---

### Phase 10 — PR 작성

**언제**: 문서화 완료 후

**커맨드**:
```bash
/pull-request-description
```

**산출물**: 변경사항 요약 + self-review 체크리스트 + 테스트 플랜이 포함된 MR/PR

---

## 핫픽스 파이프라인 (긴급 버그 대응)

운영 장애, 긴급 보안 패치, 블로킹 버그 수정 시 사용합니다.

```bash
/hotfix WP-1234
```

5단계로 단축된 fast-path:

```
[H1] 핫픽스 브랜치  → hotfix/WP-1234-[summary]
[H2] 최소 테스트    → /test-writer --unit (버그 재현 테스트만)
[H3] 수정          → /code-writer (가장 작은 변경 범위)
[H4] 코드 리뷰      → /code-review (Critical 이슈만 체크)
[H5] PR 작성       → /pull-request-description (hotfix 표시)
```

> 핫픽스는 TDD를 완화하되, 버그 재현 테스트는 반드시 작성 후 수정합니다.

---

## 부가 커맨드 (언제든 사용)

| 상황 | 커맨드 |
|------|--------|
| QA/테스트 중 버그 발견 | `/bug-report` |
| 버전 릴리즈 | `/release-notes v1.2.0` |
| 빌드/타입 에러 | `/build-fix` |
| 보안 검토 필요 | `/security-review` |
| 테스트 인프라 없을 때 | `/vitest-setup` |
| API 모킹 설정 | `/msw-setup` |
| 전체 파이프라인 준수 현황 확인 | `/component-audit` |
| 긴급 핫픽스 | `/hotfix WP-XXXX` |

---

## 빠른 참조 카드

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 STANDARD PIPELINE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[0] PRD        /figma-jira-prd [figma] [jira]
[1] 브랜치      /branch-from-ticket WP-XXXX
[2] 설계        /planner [figma]
[3] API 훅  ┐  /api-integration WP-XXXX     ← 병렬
[4] 테스트  ┘  /test-writer --all WP-XXXX   ← 병렬
[5] 구현        /code-writer --ui pageComponents/[f]/planner.md
[6] 리팩터      /refactor pageComponents/[f]/planner.md
[7] 커버리지    /coverage-report WP-XXXX
[8] 리뷰        /code-review
[9] 문서        /confluence-update WP-XXXX
[10] PR        /pull-request-description

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 HOTFIX PIPELINE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[hotfix]       /hotfix WP-XXXX

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 초기 설정
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[S1] 테스트 인프라   /vitest-setup
[S2] API 모킹       /msw-setup

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 감사/검토
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[A1] 전체 현황      /component-audit
[A2] 보안 검토      /security-review
```

---

## 안티패턴 — 하지 말 것

| 안티패턴 | 이유 | 대안 |
|---------|------|------|
| Phase 4 없이 Phase 5 진행 | TDD 위반 — 구현이 테스트를 이기면 품질 보증 불가 | `/test-writer` 먼저 실행 |
| planner.md 없이 코드 작성 | 설계 없는 구현은 리팩터 비용 3배 | `/planner` 먼저 실행 |
| 서비스 레이어(apis/service/) 별도 생성 | 파일 분산으로 응집도 저하 | 훅 파일에 API 로직 co-locate |
| `data-testid` 셀렉터 사용 | 구현 세부사항 결합 — 리팩터 시 테스트 파괴 | ARIA role/text 기반 셀렉터 사용 |
| `px` 단위 사용 | 디자인 토큰 불일치 | `rem` 단위 사용 |
| `cn()` 함수 사용 | 이 프로젝트 컨벤션 위반 | Tailwind 클래스 직접 작성 |
| 핫픽스에 전체 파이프라인 적용 | 긴급 상황에 병목 | `/hotfix` 커맨드 사용 |
| Global type/constant 파일 생성 | 응집도 저하 | feature 폴더 내 co-location |

---

## 온보딩 가이드 (신규 개발자)

**첫 번째 기능 구현 순서:**

1. `git clone` 후 `/vitest-setup` 으로 테스트 환경 구성
2. Jira 티켓 확인 → `/figma-jira-prd` 로 PRD 작성
3. `/branch-from-ticket WP-XXXX` 로 브랜치 생성
4. `/planner [figma-url]` 로 설계 문서 작성 후 팀 리뷰
5. Phase 3+4 병렬: `/api-integration` + `/test-writer --all`
6. `/code-writer --ui pageComponents/[feature]/planner.md`
7. 테스트 GREEN 확인 → `/refactor` → `/coverage-report`
8. `/code-review` 통과 → `/confluence-update` → `/pull-request-description`

**막혔을 때:**
- 현재 단계 확인: `/workflow WP-XXXX`
- 전체 현황 점검: `/component-audit`
- 빌드 에러: `/build-fix`
