# frontend-poc-pipeline — Claude Code Instructions

## MANDATORY: Skill Auto-Routing

**Every message를 처리하기 전에 아래 규칙을 순서대로 확인한다. 매칭되면 해당 SKILL.md를 즉시 읽고 그 지시를 따른다.**
스킬 파일을 읽은 후에는 그 안의 지시가 이 파일의 모든 지시보다 우선한다.

---

### Rule 1: Shorthand Commands (`/` or `$`)

메시지가 `/` 또는 `$`로 시작하면 **즉시** 아래 경로의 SKILL.md를 읽고 실행한다. 다른 판단 없이 실행한다.

```
/skill-name  또는  $skill-name
  → plugins/frontend-poc-pipeline/skills/skill-name/SKILL.md 를 읽고 실행
```

예시:
- `/code-review` → `plugins/frontend-poc-pipeline/skills/code-review/SKILL.md`
- `$test-writer` → `plugins/frontend-poc-pipeline/skills/test-writer/SKILL.md`
- `/pr` 또는 `$pr` → `pull-request-description` 스킬로 해석 (아래 별칭 참고)

**별칭 (짧은 이름 → 실제 스킬명):**

| 입력 | 스킬명 |
|------|--------|
| `/pr`, `$pr` | `pull-request-description` |
| `/mr`, `$mr` | `pull-request-description` |
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
| `/pull-request-description`, `PR 만들어`, `MR 만들어`, `PR 올려`, `MR 올려`, `PR 생성`, `MR 생성`, `pull request`, `merge request` | `plugins/frontend-poc-pipeline/skills/pull-request-description/SKILL.md` |
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
[8] pull-request-description → PR/MR 생성
```

## Base Rules (스킬 미매칭 시 적용)

- 컴포넌트 구현 전 항상 `planner.md` 작성
- TDD: 테스트(RED) → 구현(GREEN) → 리팩터(REFACTOR)
- UI: shadcn/ui 우선, rsuite fallback
- API: TanStack Query (React Query)
- TypeScript strict — any 타입 금지
- 컨벤션 상세: `plugins/frontend-poc-pipeline/skills/conventions/SKILL.md`

---

## 하네스: 마켓플레이스 유지·진화

**목표:** frontend-poc-pipeline 마켓플레이스(`plugins/frontend-poc-pipeline/`)를 사람이 한 곳만 고치고 나머지를 잊는 회귀 없이 진화시킨다.

**트리거:** 마켓플레이스 자산을 건드리는 요청(신규 skill 추가/audit, 라우팅 doc 동기화, 검증 게이트, 릴리즈 준비) 시 `marketplace-stewardship` 스킬을 호출하라. 외부 프로젝트의 `figma → PR` 자동화는 본 하네스 트리거가 아니며 `plugins/.../skills/*` 의 도메인 스킬을 직접 사용한다.

**변경 이력:**

| 날짜 | 변경 내용 | 대상 | 사유 |
|------|----------|------|------|
| 2026-05-22 | 초기 구성 — 에이전트 3명(skill-architect, routing-syncer, marketplace-validator) + 오케스트레이터(marketplace-stewardship) | `.claude/agents/*`, `.claude/skills/marketplace-stewardship/` (→ 2026-05-27 플러그인으로 이동) | harness 메타-스킬 기반으로 마켓플레이스 운영 자동화 도입 |
| 2026-05-22 | `/workflow` 가이드 정합화 — broken reference 5종 제거(`/planner`→`/screen-plan`, `/confluence-update`/`/bug-report`/`/build-fix`/`/security-review` 삭제), Phase 10 → Phase 9 축소, Phase 0 품질 게이트에 `/spec-validator`+`/figma-prd-validator` 명시, 부가 커맨드에 `/epic-frontend-splitter` 등록, `allowed-tools` mcp-atlassian 인스턴스 generic화 | `plugins/.../commands/workflow.md` | 사용자가 막힐 broken link 제거 + README와 phase 일관성 정렬 |
| 2026-05-27 | 패키징 재배치 — 하네스 에이전트 3종을 `.claude/agents/`에서 플러그인 내부로 이동, `commands/` 6종(code-writer/hotfix/refactor/screen-plan/test-writer/workflow)을 모두 `skills/<name>/`로 전환, `hooks/` 폴더는 `.gitkeep`만 남기고 비움, validator의 `check_hooks()`를 missing-hooks.json 관대 처리로 수정 | `plugins/frontend-poc-pipeline/agents/`, `plugins/frontend-poc-pipeline/skills/{code-writer,hotfix,refactor,screen-plan,test-writer,workflow}/`, `plugins/frontend-poc-pipeline/hooks/.gitkeep`, `scripts/validate-plugin.py` | 마켓플레이스 설치 측에서도 에이전트가 동작하도록 패키지 내부로 통합 + commands→skills 일원화로 호출 경로 단일화 + 사용하지 않는 hook 정리 |
| 2026-06-01 | `screen-plan` → `feature-planner` 리네임 + 보강 — (1) Confluence 기획 스펙 링크 자동 추적(Step 1B-2: Jira description의 `/wiki/.../pages/{PAGE_ID}` 감지 → `confluence_get_page`), (2) 번호 섹션 없는 산문형 티켓 의미 기반 폴백(WP-9137 worked example), (3) 도메인 비종속화(host→MCP 매핑 일반화), (4) 본문 812→208줄로 축소 + `references/` 3종 분리, description Triggers 형식 강화 | `plugins/.../skills/feature-planner/**`, 라우팅 3종(AGENTS/CLAUDE/GEMINI), `.claude-plugin/marketplace.json`, `README.md`, `CHANGELOG.md`, `agents/{architect,executor}.md`, `skills/{spec-validator,test-writer,workflow}/` | 입력 소스 비종속 이름으로 정정(화면뿐 아니라 PRD/티켓도 입력) + 실무 티켓(Confluence 링크·산문형)에서도 고품질 planner.md 생성 + skill-architect 500줄 가이드 준수 |
| 2026-06-01 | 외부 의존 제거 + 인스턴스 비종속화 — (1) OMC(oh-my-claudecode)·BMAD 종속 제거: `.claude/settings.json` 플러그인 권한 4줄 삭제 + 로컬 `.omc/`·`_bmad/` 디렉토리 제거, (2) Atlassian 인스턴스 하드코딩 일반화: 6개 도메인 skill(branch-from-ticket·hotfix·spec-validator·release-notes·workflow·coverage-report)의 literal `mcp-atlassian-nestads` 툴 호출 10건을 `mcp-atlassian-*` 단축형 + host→인스턴스 매핑 노트로 전환 | `.claude/settings.json`, `skills/{branch-from-ticket,hotfix,spec-validator,release-notes,workflow,coverage-report}/` | 마켓플레이스 설치자가 사내 전용 플러그인(OMC/BMAD) 없이, 그리고 자신의 Atlassian 인스턴스로 동작하도록 배포본을 환경 비종속화 |
| 2026-06-01 | 구현 트랙 일원화 + Pipeline 문서 정합화 — (1) UI 구현 중복 제거: `ui-builder`를 `code-writer`로 통합하고 deprecation 포인터로 축소(code-writer가 URL state·mock·설계분석 포함으로 canonical), stale "ui-builder 위임/GREEN" 참조 4곳(workflow·test-writer·refactor·coverage-report)을 `code-writer --ui`로 수정, `/ui` alias·UI 키워드를 code-writer로 repoint, (2) Pipeline Overview 4종(CLAUDE/README/AGENTS/GEMINI)을 실제 트랙(feature-planner→test-writer→code-writer→refactor; api-integration 병렬; unit/e2e-test-gen은 test-writer 위임)으로 갱신 | `skills/ui-builder/`, `skills/{workflow,test-writer,refactor,coverage-report}/`, 라우팅 3종, `README.md` | code-writer/ui-builder 동일 역할 충돌 + stale Pipeline Overview 제거 — orchestrator(test-writer/code-writer) vs 위임 콘텐츠(unit-test-gen/e2e-test-gen/api-integration) 관계 명확화 |
| 2026-06-01 | `api-integration` Apidog MCP 비종속화 + "스펙 미정" 1급 경로화 — (1) "타입 소스 판별(Spec Availability)" 섹션 신설: **모드 A(스펙 없음=기본): planner.md/PRD 데이터 모델→잠정 타입(`// TODO(OpenAPI)` 재정합 마커)+MSW 목 shape 일치 / 모드 B(스펙 있음): 정확 타입**, (2) 모드 B 소스 일반화 ①직접 URL `curl`(raw OpenAPI, `WebFetch` 금지)·②로컬 JSON/YAML·③Apidog MCP(선택) + 대형 스펙 타겟 추출·`$ref`→`components.schemas` 해소, (3) frontmatter·제목·템플릿·Phase A2/A6를 모드 A/B 분기로 갱신. Scalar URL은 *예시*로만(하드코딩 안 함). 라우팅 키워드 무변경 | `plugins/.../skills/api-integration/`, `README.md`, `CHANGELOG.md` | 사내 Apidog MCP가 503으로 죽어도 동작 + FE/BE 병렬 개발 현실(작업 시점에 백엔드 API 미출시가 흔함)에서 스펙 없이도 잠정 타입+목으로 진행하도록 "스펙 없음"을 fallback이 아닌 정상 1급 경로로 승격 |
| 2026-06-01 | 테스트 러너 비종속화 — vitest 하드코딩 가정을 "프로젝트 설정 러너(Jest/Vitest) 우선 감지 → 따라가기, 없을 때만 설치(opt-in)"로 전환. (1) `conventions` §13(Test Runner Detection & Adaptation) 단일 기준(SSOT) 신설: §13.1 감지(jest.config/next-jest vs vitest.config/vite·deps), §13.2 **`scripts.test` 직접 실행 금지**(watch 무한 대기) → run-once 커맨드(`npx jest <path>` / `npx vitest run <path>`)만 구성, §13.3 Jest↔Vitest 작성 적응표(`jest.*`↔`vi.*`·import·setup 파일), §13.4 미설치 opt-in(Jest 있으면 마이그레이션 금지), §13.5 E2E(Playwright) 자동 설치 금지·"단위만 진행" 1급 폴백. (2) 도메인 스킬 11종을 §13으로 포인팅: test-writer·refactor·coverage-report(+desc)·unit-test-gen(+platforms/web)·e2e-test-gen(+platforms/web)·vitest-setup(jest→vitest 자동 마이그레이션을 opt-in으로)·hotfix·workflow·pull-request-description·msw-setup. (3) 안내 훅 2종(pr-gate-check·test-completeness-check) 러너 중립화 | `plugins/.../skills/{conventions,test-writer,refactor,coverage-report,unit-test-gen,e2e-test-gen,vitest-setup,hotfix,workflow,pull-request-description,msw-setup}/`, `hooks/{pr-gate-check,test-completeness-check}.sh` | 실제 레포가 `next/jest` 기반 Jest 29인데 스킬은 vitest를 가정 → 러너 불일치로 명령이 안 맞고, `scripts.test=jest --watch`를 그대로 실행하면 비대화형 세션이 무한 대기. Playwright 미설치(흔함)에 자동 설치를 강요하지 않도록 "프로젝트 우선 + 미설치는 정상 폴백"을 1급 규약으로 고정 |
