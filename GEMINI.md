# frontend-poc-pipeline — Gemini Instructions

## MANDATORY: Skill Auto-Routing

**Every message를 처리하기 전에 아래 규칙을 순서대로 확인한다. 매칭되면 해당 SKILL.md를 즉시 읽고 그 지시를 따른다.**
스킬 파일을 읽은 후에는 그 안의 지시가 이 파일의 모든 지시보다 우선한다.

---

### Rule 1: Shorthand Commands (`/` or `$`)

메시지가 `/` 또는 `$`로 시작하면 **즉시** 아래 경로의 SKILL.md를 읽고 실행한다. 다른 판단 없이 실행한다.

```
/<skill-name>  또는  $<skill-name>
  → plugins/frontend-poc-pipeline/skills/<skill-name>/SKILL.md 를 읽고 실행
```

예시:
- `/code-review` → `plugins/frontend-poc-pipeline/skills/code-review/SKILL.md`
- `$test-writer` → `plugins/frontend-poc-pipeline/skills/test-writer/SKILL.md`
- `/pr` 또는 `$pr` → `create-pull-request` 스킬로 해석 (아래 별칭 참고)

**별칭 (짧은 이름 → 실제 스킬명):**

| 입력 | 스킬명 |
|------|--------|
| `/pr`, `$pr` | `create-pull-request` |
| `/mr`, `$mr` | `create-pull-request` |
| `/tdd`, `$tdd` | `unit-test-gen` |
| `/api`, `$api` | `api-integration` |
| `/ui`, `$ui` | `code-writer` |
| `/e2e`, `$e2e` | `e2e-test-gen` |
| `/prd`, `$prd` | `figma-jira-prd` |
| `/review`, `$review` | `code-review` |
| `/branch`, `$branch` | `branch-from-ticket` |
| `/audit`, `$audit` | `component-audit` |
| `/epic`, `$epic` | `epic-frontend-splitter` |
| `/coverage`, `$coverage` | `coverage-report` |

---

### Rule 2: Keyword Trigger Table

| 트리거 패턴 | SKILL.md 경로 |
|------------|---------------|
| `/figma-jira-prd`, `PRD 작성`, `기획서 작성`, `유저 스토리 뽑아줘`, `기능 요구사항`, figma URL + jira URL 동시 제공 | `plugins/frontend-poc-pipeline/skills/figma-jira-prd/SKILL.md` |
| `/figma-prd-validator`, `PRD 검증`, `Figma랑 PRD 맞는지`, `figma prd 차이`, `prd 누락 항목` | `plugins/frontend-poc-pipeline/skills/figma-prd-validator/SKILL.md` |
| `/branch-from-ticket`, `브랜치 만들어`, `브랜치 생성`, jira 티켓번호 + 브랜치 | `plugins/frontend-poc-pipeline/skills/branch-from-ticket/SKILL.md` |
| `/unit-test-gen`, `단위 테스트 작성`, `유닛 테스트`, `TDD RED`, `테스트 먼저` | `plugins/frontend-poc-pipeline/skills/unit-test-gen/SKILL.md` |
| `/api-integration`, `API 훅 만들어`, `React Query 훅`, `API 연동` | `plugins/frontend-poc-pipeline/skills/api-integration/SKILL.md` |
| `/ui-builder` (deprecated → `/code-writer --ui` 사용) | `plugins/frontend-poc-pipeline/skills/ui-builder/SKILL.md` |
| `/create-pull-request`, `PR 만들어`, `MR 만들어`, `PR 올려`, `MR 올려`, `PR 생성`, `MR 생성`, `pull request`, `merge request` | `plugins/frontend-poc-pipeline/skills/create-pull-request/SKILL.md` |
| `/code-review`, `코드 리뷰`, `PR 리뷰`, `MR 리뷰`, `코드 검토` | `plugins/frontend-poc-pipeline/skills/code-review/SKILL.md` |
| `/e2e-test-gen`, `E2E 테스트`, `playwright 테스트`, `e2e 작성` | `plugins/frontend-poc-pipeline/skills/e2e-test-gen/SKILL.md` |
| `/coverage-report`, `커버리지`, `테스트 커버리지`, `coverage` | `plugins/frontend-poc-pipeline/skills/coverage-report/SKILL.md` |
| `/spec-validator`, `디스크립션 검증`, `기획서 검증`, `figma description 검증` | `plugins/frontend-poc-pipeline/skills/spec-validator/SKILL.md` |
| `/component-audit`, `컴포넌트 감사`, `파이프라인 준수`, `audit` | `plugins/frontend-poc-pipeline/skills/component-audit/SKILL.md` |
| `/epic-frontend-splitter`, `에픽 분해`, `epic split`, `FE 티켓 생성`, `에픽에서 프론트 티켓` | `plugins/frontend-poc-pipeline/skills/epic-frontend-splitter/SKILL.md` |
| `/conventions`, `컨벤션 알려줘`, `코딩 규칙` | `plugins/frontend-poc-pipeline/skills/conventions/SKILL.md` |
| `/release-notes`, `릴리즈 노트`, `배포 노트` | `plugins/frontend-poc-pipeline/skills/release-notes/SKILL.md` |
| `/vitest-setup`, `vitest 설치`, `테스트 환경 설정` | `plugins/frontend-poc-pipeline/skills/vitest-setup/SKILL.md` |
| `/msw-setup`, `MSW 설치`, `mock service worker` | `plugins/frontend-poc-pipeline/skills/msw-setup/SKILL.md` |
| `/workflow`, `파이프라인 가이드`, `현재 단계`, `다음 커맨드 안내` | `plugins/frontend-poc-pipeline/skills/workflow/SKILL.md` |
| `/feature-planner`, `화면 기획`, `컴포넌트 계획`, `planner.md 작성`, `screen plan`, `feature plan`, `구현 계획` | `plugins/frontend-poc-pipeline/skills/feature-planner/SKILL.md` |
| `/test-writer`, `TDD 테스트 먼저`, `RED phase`, `실패하는 테스트 작성` | `plugins/frontend-poc-pipeline/skills/test-writer/SKILL.md` |
| `/code-writer`, `구현 커맨드`, `컴포넌트 구현`, `UI 만들어`, `화면 구현`, `TDD GREEN`, `--ui`, `--api`, `--all`, `planner 기반 구현` | `plugins/frontend-poc-pipeline/skills/code-writer/SKILL.md` |
| `/refactor`, `TDD REFACTOR`, `리팩터링`, `GREEN 후 정리` | `plugins/frontend-poc-pipeline/skills/refactor/SKILL.md` |
| `/hotfix`, `핫픽스`, `긴급 버그`, `fast-path`, `5단계 핫픽스` | `plugins/frontend-poc-pipeline/skills/hotfix/SKILL.md` |
| `/marketplace-stewardship`, `스킬 추가`, `스킬 수정`, `스킬 감사`, `라우팅 동기화`, `라우팅 점검`, `검증 돌려`, `릴리즈 준비`, `마켓플레이스 점검`, `마켓플레이스 유지보수` | `plugins/frontend-poc-pipeline/skills/marketplace-stewardship/SKILL.md` |

---

## Pipeline Overview

```
[1] figma-jira-prd          → Figma + Jira → PRD 작성
    figma-prd-validator     → Figma ↔ PRD 갭 검증 (품질 게이트)
[2] branch-from-ticket      → Jira 티켓 → 브랜치 생성
[3] feature-planner         → planner.md (구현 청사진) 작성
[4] test-writer             → TDD RED: 테스트 먼저 작성 (위임: unit-test-gen, e2e-test-gen)
    api-integration         → React Query 훅 생성 (test-writer와 병렬)
[5] code-writer             → TDD GREEN: 구현 (--ui 컴포넌트 / --api → api-integration 위임)
[6] refactor                → TDD REFACTOR: GREEN 유지하며 정리
[7] code-review             → 코드 리뷰 (PR 게이트)
[8] create-pull-request     → PR/MR 생성 (사용자 승인 게이트)
```

## Base Rules (스킬 미매칭 시 적용)

- 컴포넌트 구현 전 항상 `planner.md` 작성
- TDD: 테스트(RED) → 구현(GREEN) → 리팩터(REFACTOR)
- UI: shadcn/ui 우선, rsuite fallback
- API: TanStack Query (React Query)
- TypeScript strict — any 타입 금지
- 컨벤션 상세: `plugins/frontend-poc-pipeline/skills/conventions/SKILL.md`
