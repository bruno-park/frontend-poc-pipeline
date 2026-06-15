# frontend-poc-pipeline — Claude Code Instructions

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
| 2026-06-05 | Hooks 강화 (WP-8982) — advisory → 강제(enforce) 가능 전환. **헤드라인**: 기존 9개 hook이 모두 존재하지 않는 `CLAUDE_TOOL_INPUT` env를 읽어 항상 no-op(차단·경고 미발동)이던 버그를 발견·수정(공식 docs로 stdin JSON 계약 검증). (1) 공유 `hooks/_lib.sh`(stdin 파싱 jq→python3 fallback, `.fpp-hooks.json`+env 모드 warn/enforce/off+킬스위치, deny/block/advise+remediation, `$TMPDIR` 루프가드, planner 검증 헬퍼). (2) 강제 가능 hook 신규 4종: `bash-safety-guard`(PreToolUse:Bash 위험·난독화 명령 하이브리드 차단, defense-in-depth), `secret-leak-guard`(PreToolUse+PostToolUse 시크릿), `planner-schema-guard`(PostToolUse:Write\|Edit\|MultiEdit planner.md 키워드 검증), `subagent-regate`(SubagentStop planner 재검증). (3) 기존 9종 stdin 마이그레이션 + commit/branch `exit 1`→`exit 2`. (4) `validate-plugin.py`에 `CLAUDE_TOOL_INPUT` 회귀 fail + `_lib.sh` bash -n 추가, `scripts/test-hooks.sh` fixture 하네스 78케이스. (5) README Hooks 섹션 drift 정정, 버전 0.6.0→0.7.0. **B(PostToolUse 포맷/lint/tsc)·C(Stop DS토큰)는 범용 false-positive 위험으로 이번 범위 제외**(사용자 결정). | `plugins/.../hooks/{_lib.sh,bash-safety-guard,secret-leak-guard,planner-schema-guard,subagent-regate,hooks.json,fpp-hooks.example.json, +기존 9종}`, `scripts/{validate-plugin.py,test-hooks.sh,hook-tests/*}`, `README.md`, `CHANGELOG.md`, 버전 2곳 | hook이 advisory로 명세됐으나 실제로는 I/O 계약 오류로 전부 무동작 — "강제 승격" 전에 먼저 "동작"시켜야 했음. 범용 배포(소비 레포마다 도구·DS 상이) 위해 fail-open(품질)/fail-safe(안전) + warn→enforce 토글로 점진 채택 가능하게 설계 |
| 2026-06-05 | Hooks 하네스 강제력 보강 (linter→harness) — advisory 평가에서 "scaffolding은 좋은데 binding이 약하다"는 지적에 따라 실제 구속 2축 추가. (1) `stop-gate`(Stop) + 위반 ledger(`_lib.sh` fpp_ledger_*): PostToolUse 훅(planner-schema·secret-leak)이 차단 불가라는 한계를 보완 — 위반을 세션 ledger($TMPDIR)에 기록하고 Stop에서 미해결이면 `decision:block`으로 턴 종료 차단(루프가드 N=3). self-heal(재작성 시 clear). (2) `pipeline-order-guard`(PreToolUse:Write): pageComponents 신규 구현 파일 생성 시 planner.md 선존재 + 컴포넌트면 RED 테스트 선존재 강제(기존 파일 편집 비차단, index/types/배럴 면제). (3) hooks.json에 Stop·PreToolUse(Write) 그룹 추가, 예시 설정·README·test-hooks.sh(108케이스) 갱신. 기본 warn 유지(팀이 enforce로 승격). | `plugins/.../hooks/{_lib.sh,stop-gate.sh,pipeline-order-guard.sh,planner-schema-guard.sh,secret-leak-guard.sh,hooks.json,fpp-hooks.example.json}`, `scripts/{test-hooks.sh,hook-tests/harness.cases.sh}`, `README.md`, `CHANGELOG.md` | warn-only advisory는 하네스가 아니라 린터 — 실제 강제는 ① 종착(Stop) 게이트로 PostToolUse 강제를 닫고 ② 파이프라인 순서(planner/TDD)를 PreToolUse에서 막아야 성립. 단 범용 배포 안전 위해 기본 warn, 강제는 팀 opt-in |
| 2026-06-11 | `e2e-test-gen` Playwright 공식 Test Agents 통합 — (1) 에이전트 감지를 공식 `npx playwright init-agents --loop=claude` 산출 경로(`.claude/agents/playwright-test-{planner,generator,healer}.md`, v1.56+)로 정정, 레거시 `agents/*playwright*.md`는 2순위 fallback (기존엔 비공식 유령 경로만 글롭해 공식 산출물 영구 미감지), (2) 공식 컨벤션 반영: `specs/`(1 spec ↔ 1 test file)·`seed.spec.ts`·`.mcp.json` `playwright-test` MCP 서버 확인, planner는 라이브 앱 탐색이므로 앱 미실행 시 내장 로직 폴백, (3) healer 선별 사용 규칙 — TDD RED("구현 없음" FAIL)에 호출 금지(healer가 `test.skip` 처리해 RED 신호 소실), selector/타이밍 오류에만 위임, (4) 미생성 시 §13.5 정신 opt-in 안내(`.mcp.json` 덮어쓰기 경고 포함), (5) **공식 에이전트 3종 번들**: `agents/playwright-test-{planner,generator,healer}.md` v1.59.1 스냅샷 동봉 — 감지 우선순위 로컬(1) > 번들(2) > 레거시(3), 번들 사용 시 `.mcp.json`에 `playwright-test` entry를 병합 추가(덮어쓰기 금지). 라우팅 키워드 무변경, 버전 0.7.1→0.7.2 | `plugins/.../skills/e2e-test-gen/{SKILL.md,platforms/web.md}`, `plugins/.../agents/playwright-test-{planner,generator,healer}.md`, `.claude-plugin/marketplace.json`, `plugins/.../.claude-plugin/plugin.json`, `CHANGELOG.md` | 스킬이 가정한 에이전트 경로가 실제 공식 산출물과 달라 에이전트 체이닝이 한 번도 동작할 수 없는 상태였음(playwright v1.60 소스 `generateAgents.ts`로 검증). 공식 init-agents 채택 프로젝트에서 즉시 위임 모드가 켜지도록 정합화 + TDD 파이프라인과 healer의 충돌(RED 신호 소실)을 규칙으로 차단 |
| 2026-06-11 | `test-engineer` → `vitest-test-engineer` 리네임 + 범위 명확화 + `test-writer` E2E를 Playwright 에이전트 위임으로 전환 — (1) 파이프라인 에이전트 이름이 "테스트 전반"으로 읽혀 E2E 오라우팅 위험 → 실제 범위(vitest/jest 단위·통합 + MSW, Phase 4 RED / Phase 7 커버리지)를 이름·본문에 명시, E2E는 범위 밖(`playwright-test-*`/`e2e-test-gen`)으로 못박음, 본문을 스킬 포인터 → 정직 재작성(RED의 GREEN 침범 금지·커버리지 루프는 Phase 7만·러너 비종속 §13·컨텍스트 격리 가치). (2) `test-writer` Phase 3(E2E)를 인라인 직접 작성 → `e2e-test-gen` 경유 Playwright 공식 Test Agents(planner 계획→generator 작성) 위임 **1순위**로 재구성, 인라인 템플릿은 미설치 시 **2순위 폴백** 보존, RED 맥락 healer 호출 금지 규칙 명시. 라우팅 키워드 무변경, 버전 0.7.2→0.7.3 | `plugins/.../agents/vitest-test-engineer.md`(구 `test-engineer.md` 삭제), `plugins/.../skills/test-writer/`, `docs/harness-engineering-2026-05.md`, `.claude-plugin/marketplace.json`, `plugins/.../.claude-plugin/plugin.json`, `CHANGELOG.md` | 고아(어디서도 호출 안 됨)이면서 이름이 범위를 거짓말하던 파이프라인 에이전트를 실제 역할에 정합화 — Playwright(도구 기반 에이전트) vs vitest(스킬 기반) 비대칭을 이름으로 명확화하고, test-writer의 E2E도 도구 기반 Playwright 에이전트로 계획·작성하도록 일원화 |
| 2026-06-14 | `pull-request-description` → `create-pull-request` 리네임 + 사용자 승인 게이트 추가 — (1) 이름이 "기존 PR description 수정"으로 오해되던 스킬을 실제 동작(새 PR/MR 생성)에 맞춰 동사형 `create-pull-request`로 리네임(디렉토리 git mv + frontmatter `name` + 제목). `/pr`·`/mr`·`$pr`·`$mr` 별칭은 진입점 유지하고 매핑만 repoint. (2) **User Approval Gate(필수)** 신설: description 생성 후 항상 사용자에게 3지선다(① 승인 / ② 수정 / ③ 취소)를 묻고, **명시적 ① 승인 없이는 플랫폼 생성 도구(`gitlab_create_mr`/`bb_post`/`gh pr create`)를 절대 호출 금지** — auto-trigger(`MR 만들어`)여도 무인 자동 생성 차단(② 수정 시 반영 후 재확인 루프). Auto-Trigger Conditions·Execution Steps·Example Usage·frontmatter `description`에 게이트 반영. (3) 동기화: 라우팅 3종(CLAUDE/AGENTS/GEMINI) 별칭·키워드·경로·Pipeline Overview, `.claude/rules/pr-required.md`, `marketplace.json`, `README.md`, `docs/harness-engineering-2026-05.md`, 타 스킬 참조(`hotfix`·`workflow`·`code-reviewer` 에이전트), 버전 0.7.3→0.7.4 | `plugins/.../skills/create-pull-request/`(구 `pull-request-description/`), 라우팅 3종, `.claude/rules/pr-required.md`, `.claude-plugin/marketplace.json`, `plugins/.../.claude-plugin/plugin.json`, `plugins/.../skills/{hotfix,workflow}/`, `plugins/.../agents/code-reviewer.md`, `README.md`, `docs/harness-engineering-2026-05.md`, `CHANGELOG.md` | 스킬 이름이 동작을 거짓말(명사구 → "description 수정"으로 읽힘)하던 것을 동작형으로 정합화 + 사용자가 의도치 않게 PR이 자동 생성되는 위험을 명시적 승인 게이트로 차단(사용자 요구) |
| 2026-06-15 | `code-review` 스킬 SSOT 정합화 + Mode B host 일반화 + `code-reviewer` 에이전트 thin gate화 (CCG Codex+Gemini 교차검증) — (1) **인라인 Conventions 블록(~75줄) 삭제 → `conventions/{SKILL.md}` 필수 읽기로 대체**: 복제본이 실제 drift(인라인=컴포넌트 파일명 kebab-case, SSOT=PascalCase) → 리뷰가 PascalCase 파일을 위반으로 오지적하던 버그 제거, 위반 지적 시 §조항 인용 요구. (2) **Mode A/B 공통 "Analysis Core" 분리** + 중복 Performance 섹션 2→1 통합. (3) **심각도 단일화** Critical/High/Medium/Low (Mode B의 Critical/Warning/Minor 제거, 에이전트와 일치). (4) **Mode B Bitbucket 전용 → "원격 PR/MR 리뷰" provider 추상화**: host 감지(URL>git remote>MCP)로 GitLab(`gitlab_create_mr_discussion`/`gitlab_add_mr_note`)·Bitbucket(`bb_post`)·GitHub(`gh`) 어댑터 + report-only fallback (`create-pull-request` 감지 패턴 미러). (5) **에이전트를 `/code-review` 위임 + PASS/BLOCK 판정만** 하도록 축소, **Phase 9(PR 작성) 소유권 제거** → `create-pull-request` 안내만. 라우팅 키워드 무변경(기존 "MR 리뷰" 유지), 독립 검증(verifier)에서 추가 정정 2건: `workflow` 다이어그램 Phase 8 기준 "Critical 0개"→"Critical/High 0개"(게이트 표와 정합), B-1 "동일한 감지 로직" 과장 주석→"같은 우선순위" 정정. 버전 0.7.4→0.7.5 | `plugins/.../skills/code-review/{SKILL.md}`(338→251줄), `plugins/.../agents/code-reviewer.md`, `plugins/.../skills/workflow/`, `.claude-plugin/marketplace.json`, `plugins/.../.claude-plugin/plugin.json`, `CHANGELOG.md` | code-review가 SSOT를 복제해 drift→오지적 버그 발생 + Mode B가 GitLab 주력 환경에서 Bitbucket 전용이라 "MR 리뷰" 트리거가 실동작 불가 + 스킬↔에이전트 심각도/책임 중복. SSOT 단일화로 drift 제거, host 추상화로 실환경 정합, 에이전트는 게이트 본연 역할로 축소 |
| 2026-06-15 | `api-integration` conventions SSOT 앵커 + 프로젝트 구조 감지 — (1) conventions 0회 참조 해소: "컨벤션 기준(SSOT)" 포인터 블록 신설(§7 Two-Layer Hook·§2 Naming·§7/§12 타입 위치). (2) **Path B가 conventions §12 위반하던 모순 해소**: §12 DON'T가 금지하는 `apis/model`·`apis/service`·전역 `utils/variables`를 무조건 대상화하던 Path B를 "프로젝트 구조 감지"(§13 러너 감지와 같은 비종속 패턴)로 전환 — `apis/model` 존재 시 레이어드 모드(레거시 그대로), 없으면 co-location 모드(기본, 훅 파일 co-locate). Phase 0 Step1 테이블·Path B 인트로·공통 주의사항 두 모드 분기화 + 내부 모순(co-locate 권장↔Path B의 apis/model 편집) 정정. 독립 검증(verifier)으로 4건 추가 수정: (Critical) Step2가 apis/model 단독 조건이라 co-location 모드 Path B/C 진입 불가하던 데드락 해소, (High) B2~B5 하드코딩 경로에 모드별 대상 인라인 명시, (Medium) 발명된 `~ApiPath`/`use{PathName}` 포인터를 실제 표기로 정정, (Low) B7 출력 예시 co-location 안내. 라우팅 키워드 무변경, 버전 0.7.5→0.7.6 | `plugins/.../skills/api-integration/`, `.claude-plugin/marketplace.json`, `plugins/.../.claude-plugin/plugin.json`, `CHANGELOG.md` | 코드(훅/타입) 생성 스킬이 정작 SSOT를 안 가리켜 drift 위험 + Path B가 conventions가 금지하는 디렉토리를 표준처럼 박아 SSOT와 정면충돌(같은 스킬 내부에서도 모순). 구조 감지로 레거시·그린필드 양쪽을 비종속 수용하면서 기본값은 conventions 준수로 |
