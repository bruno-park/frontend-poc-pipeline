# Changelog

이 파일은 [Keep a Changelog](https://keepachangelog.com/) 형식을 따르고
프로젝트는 [Semantic Versioning](https://semver.org/)을 사용합니다.

## [0.7.10] - 2026-06-15

### Changed
- **`code-writer` SKILL.md 500줄 초과 → `references/` 분리 (skill-architect 가이드 준수)** — Phase 3에 인라인돼 있던 `useUrlQuery.ts` canonical 구현 전체(~290줄 TypeScript)를 `references/useUrlQuery-implementation.md`로 추출하고, 본문에는 "없으면 reference 구현을 그대로 복사" 포인터만 남김. SKILL.md 688→393줄(한도 내 진입). 동작·지시 내용 변화 없음(순수 구조 분리) — 거대 코드 블록이 본문을 차지해 다른 Phase 지시가 묻히던 가독성 문제 해소.

## [0.7.9] - 2026-06-15

### Fixed
- **`unit-test-gen` 디스패처 플랫폼 라벨 러너 비종속화** — 플랫폼 가이드 표의 `Web (React + Vitest)` 라벨이 Vitest를 고정 표기해, 이미 러너 비종속(Jest/Vitest, `conventions` §13)으로 전환된 `platforms/web.md` 실제 동작과 어긋나던 잔존 stale 라벨을 `Web (React, Jest/Vitest)`로 정정. (점검 결과 `test-writer`·`platforms/web.md`의 §13 앵커는 이미 정합 — drift 없음.)

## [0.7.8] - 2026-06-15

### Fixed
- **stale 파이프라인 메타데이터 정정 (ui-builder cleanup)** — (1) `marketplace.json` 플러그인 설명이 deprecated된 `ui-builder`를 활성 파이프라인 단계로 표기하고 `code-writer`·`refactor`·`code-review`를 누락하던 것을, 실제 파이프라인(`... → test-writer + api-integration → code-writer → refactor → code-review → create-pull-request`)으로 정정. (2) `plugin.json` 설명의 `Screen Plan`(feature-planner 옛 이름) → `Feature Plan`, `Review` 단계 추가. `ui-builder` 묘비 스킬(`/ui-builder` → `code-writer --ui` 리다이렉트)과 라우팅 행은 호환을 위해 유지. 버전 0.7.7→0.7.8

## [0.7.7] - 2026-06-15

### Changed
- **E2E 테스트 생성에 "동작 검증"(action · request · response · post-action)을 1급 원칙으로 도입** (Slack 피드백 반영 — #C04CWNPFFKN, 김동윤: "ui도 중요하지만 action, request, response 관련 동작이 더 중요"). 기존 E2E 템플릿이 UI 가시성(`toBeVisible`·`tbody tr` count·`toHaveURL`)만 단언해 요청 파라미터·요청 본문·응답 처리·호출 후 상태 변화 버그를 놓치던 것을 보강. (1) `e2e-test-gen/SKILL.md`·`platforms/web.md`에 **"동작 검증 원칙" 섹션 신설** — action→request(method/URL/query/body)→response(status)→post-action(목록 refetch·toast·redirect·optimistic·에러 롤백) 4계층 표 + 나쁜 예/좋은 예 + mutation `Promise.all` 패턴 + `page.route`로 4xx/5xx 주입한 에러 동작 시나리오. (2) **planner 위임 우선순위·generator 위임 규칙**에 request/response/post-action 단언 요구 추가. (3) **내장 폴백 템플릿** 3곳(e2e-test-gen SKILL/web.md + test-writer Phase 3)을 UI-only에서 GET 응답 검증·search query param 검증·POST body→201→refetch+토스트·에러 응답 동작 포함으로 교체. (4) `test-writer` Phase 3 위임 노트 + 합격 기준 표에 "E2E 동작 검증" 행 추가(`e2e-test-gen` SSOT 섹션 포인팅). playwright-test-* 번들 에이전트(공식 스냅샷)는 무수정, 라우팅 키워드 무변경.
- **E2E 테스트 제목 컨벤션 `기능명 (라우트)` 도입** (같은 Slack 스레드 — "path도 적혀있으면 좋겠다" → 박준 "title(url) - content로 넣겠다"; 첨부 대시보드 스크린샷은 화면 이름만 노출). e2e 대시보드가 Playwright JSON `title`을 표시하므로 **최상위 `describe` 제목에 라우트(URL)** 를 넣어 `기능명 (라우트) › 시나리오` = `title(url) - content`로 어떤 화면을 검증하는지 노출. 라우트는 `const ROUTE`(planner.md URL State 기준)에 두고 `page.goto`와 제목이 공유해 drift 방지(파일 경로 `file:line`은 JSON에 이미 있어 대시보드 책임 → 제목엔 라우트). `e2e-test-gen/{SKILL.md, platforms/web.md}`에 "테스트 제목 컨벤션" 섹션 신설 + generator 위임 규칙 + 내장 템플릿 3곳(describe·beforeEach goto·RBAC goto)을 ROUTE 공유로 교체, `test-writer` Phase 3 위임 노트 추가.

## [0.7.6] - 2026-06-15

### Changed
- **`api-integration` conventions SSOT 앵커 + 프로젝트 구조 감지 도입** — (1) **conventions 미참조(0회) 해소**: §7 Two-Layer Hook·§2 Naming·§7/§12 타입 위치를 가리키는 "컨벤션 기준(SSOT)" 포인터 블록 신설. 규칙 복제 대신 참조. (2) **Path B가 conventions §12를 위반하던 모순 해소**: Path B(Data Schema Extension)가 §12 DON'T가 금지하는 `apis/model/`·`apis/service/`·전역 `utils/variables.ts`를 무조건 대상으로 삼던 것을, **"프로젝트 구조 감지"**(테스트 러너 감지 §13과 같은 비종속 패턴)로 전환 — `apis/model` 존재 시 **레이어드 모드**(레거시 구조 그대로), 없으면 **co-location 모드(기본)**로 훅 파일에 co-locate. Phase 0 Step 1 테이블·Path B 인트로·공통 주의사항을 두 모드 분기로 갱신, 내부 모순("co-locate 권장 ↔ Path B가 apis/model 편집") 정정.

### Fixed
- **독립 검증(verifier) 반영 4건** — (Critical) Step 2 경로 결정 로직이 `apis/model이 MODIFY`만 조건으로 삼아 **co-location 모드에선 Path B/C 진입 불가**하던 데드락을, "데이터 레이어 MODIFY"를 구조 모드별로 정의해 해소. (High) B2~B5 절차에 레이어드 경로(`utils/variables.ts`·`apis/model/*.ts`)가 하드코딩돼 인트로를 놓치면 co-location 프로젝트에서 §12 위반 파일을 생성하던 것을, 각 Phase에 모드별 대상 인라인 명시. (Medium) SSOT 포인터가 conventions에 없는 `~ApiPath`/`use{PathName}` 규칙을 발명해 가리키던 것을 실제 표기(`UPPER_CASE` `FEATURE_API_PATH`, `use[Feature]Query`/`use[Feature]`)로 정정. (Low) B7 결과 출력 예시에 co-location 모드 경로 표기 안내 추가.
- **CCG(Gemini) 검토 반영 — 실행 신뢰성 보강** — (1) Phase 0에 **Step 0 모드 확정·선언**(`[STRUCTURE_MODE | SPEC_MODE]` 한 줄 선언) 신설 — 긴 문서 진행 중 모드 망각(drift) 방지 앵커, (2) 구조×스펙 **2×2 모드 매트릭스**로 두 직교 축 동작을 한눈에, (3) Phase B1에 **역할변수 매핑**(`ENUM_FILE`/`MODEL_FILE`/`MAPPING_FILE`) 도입 — B2~B5 인라인 모드주석의 재확인 기준을 1곳에 고정. (Codex advisor는 이번 실행에서 산출물 없이 종료 — Gemini + 직전 verifier로 교차검증 충당.)

## [0.7.5] - 2026-06-15

### Changed
- **`code-review` 스킬 SSOT 정합화 + Mode B host 일반화 (CCG 리뷰 반영)** — (1) **인라인 Conventions 블록(약 75줄) 삭제 → `conventions/SKILL.md`(SSOT) 필수 읽기로 대체.** 복제본이 이미 drift: 인라인은 컴포넌트 파일명을 kebab-case로 적었으나 SSOT는 PascalCase → 리뷰가 PascalCase 파일을 위반으로 오지적하던 버그 제거. (2) **Mode A/Mode B 공통 "Analysis Core" 분리** — 분석(무엇을 볼지)과 실행(local diff vs 원격 API)을 분리, 중복되던 Performance 섹션 2개를 1개로 통합. (3) **심각도 단일화** — Mode A(Critical/High/Medium/Low) ↔ Mode B(Critical/Warning/Minor) 불일치를 Critical/High/Medium/Low 단일 표로 통일(에이전트와도 일치). (4) **Mode B Bitbucket 전용 → "원격 PR/MR 리뷰" provider 추상화** — host 감지(URL > git remote > MCP)로 GitLab(`gitlab_create_mr_discussion`/`gitlab_add_mr_note`)·Bitbucket(`bb_post`)·GitHub(`gh`) 어댑터 + report-only fallback. 트리거의 "MR 리뷰"가 실제 GitLab 경로와 정합. (338→251줄)
- **`code-reviewer` 에이전트를 thin gate로 축소** — 체크리스트·심각도 정의 중복을 제거하고 `/code-review` 위임 + PASS/BLOCK 판정만 담당하도록 재작성. **Phase 9(PR/MR 작성) 소유권 제거** — PR/MR 생성은 승인 게이트를 가진 `create-pull-request` 전담임을 명시하고 PASS 시 next step으로 안내만 하도록 변경. 입력 host도 GitLab/Bitbucket/GitHub 일반화.

### Fixed
- **`workflow/SKILL.md` Phase 8 게이트 기준 오기재 정정** (독립 검증 반영) — 파이프라인 다이어그램(라인 38)이 "Critical 이슈 0개"로 표기돼 같은 파일의 Quality Gate 표(Critical/High 0개)·`code-review` 스킬과 어긋나던 것을 "Critical/High 0개"로 통일. High 이슈를 머지해도 된다고 오해할 위험 제거.
- **`code-review` B-1 host 감지 주석 정정** — "create-pull-request와 동일한 감지 로직"이라는 과장 주장을 실제에 맞춰 "같은 감지 우선순위(URL > git remote > MCP/CLI)를 따른다"로 수정.

### Notes
- 라우팅 doc(AGENTS/CLAUDE/GEMINI) 키워드·별칭 테이블은 스킬 리네임/추가/삭제가 아니므로 무변경(기존 "MR 리뷰" 트리거 유지).

## [0.7.4] - 2026-06-14

### Changed
- **`pull-request-description` → `create-pull-request` 리네임** — 이름이 명사구라 "이미 있는 PR의 description을 수정한다"로 오해되던 것을, 실제 동작(새 PR/MR 생성)에 맞춰 동작형 이름으로 정정. 디렉토리 `git mv` + frontmatter `name` + 제목 갱신. `/pr`·`/mr`·`$pr`·`$mr` 별칭은 진입점이라 유지하고 매핑만 새 이름으로 repoint. 라우팅 doc 3종(AGENTS/CLAUDE/GEMINI)의 별칭·키워드 트리거·경로·Pipeline Overview, `.claude/rules/pr-required.md`, `marketplace.json` 파이프라인 설명, `README.md`, `docs/harness-engineering-2026-05.md`, 타 스킬 참조(`hotfix`·`workflow`·`code-reviewer` 에이전트) 동기화.

### Added
- **User Approval Gate (사용자 승인 게이트)** — `create-pull-request`가 description 생성 후 **항상** 사용자에게 선택지를 묻도록 강제. **명시적 승인 없이는 플랫폼 생성 도구(`gitlab_create_mr` / `bb_post` / `gh pr create`)를 절대 호출하지 않음** — auto-trigger(`MR 만들어` 등)로 진입해도 무인 자동 생성 차단. 수정 선택 시 반영 후 재제시·재확인 루프, 취소 시 description만 출력하고 종료. Auto-Trigger Conditions·Execution Steps·Example Usage·frontmatter `description`·`pr-required.md` 강제 사항에 반영.
- **승인 게이트 + 워크플로 견고화 (CCG 리뷰 반영)** — (1) 게이트를 4지선다로 확장(승인 / 수정 / **초안(Draft)** / 취소) — GitHub `--draft`·GitLab `Draft:` 지원, (2) **생성 가능 여부 선체크**(push·플랫폼·MCP 연결)를 게이트 *전*에 수행해 승인 후 실패하는 헛걸음 제거, (3) **빈 diff 가드**(변경 없으면 중단), (4) **티켓 없음** 시 raw 브랜치명 제목 금지 → 사용자에게 제목 문의/정리, (5) Pre-flight를 Execution Steps에 명시 + 결과를 게이트 화면에 함께 표시(이중 확인 제거) + 범위 일반화(`$TEST_CMD`·`pageComponents/[feature]` 등 미정의 토큰 제거, grep을 `<target>` 기준화 + "매치 없음=통과" 명시), (6) target branch 기본값(`main`) 일원화, (7) 모호한 응답은 승인으로 해석 금지 + 단일 턴 "수정+생성 지시"만 승인으로 간주.

## [0.7.3] - 2026-06-11

### Changed
- **파이프라인 에이전트 `test-engineer` → `vitest-test-engineer` 리네임 + 범위 명확화** — 이름이 "테스트 전반"으로 읽혀 E2E 작업이 잘못 라우팅될 위험을 제거. 실제 범위(vitest·jest 단위/통합 + MSW, Phase 4 RED / Phase 7 커버리지)를 이름과 본문에 명시. E2E는 범위 밖(Playwright MCP 도구 기반 `playwright-test-*` / `e2e-test-gen` 담당)임을 경계로 못박음. 본문을 "스킬 포인터" 수준에서 정직하게 재작성: RED phase의 GREEN 침범 금지, 커버리지 자율 루프는 Phase 7에서만, 러너 비종속(`conventions` §13), 컨텍스트 격리 위임 대상으로서의 가치 명시.
- **`test-writer` Phase 3(E2E)를 Playwright 에이전트 위임으로 전환** — 인라인 E2E 로직을 직접 실행하던 것을, `e2e-test-gen` 스킬을 통해 Playwright 공식 Test Agents(`playwright-test-planner`로 계획 → `generator`로 작성)에 **위임하는 것을 1순위**로 재구성. 기존 인라인 템플릿(playwright.config/auth/.env.test/spec)은 에이전트·러너 미설치 시 **2순위 폴백**으로 보존. TDD RED 맥락에서 `playwright-test-healer` 호출 금지 규칙 명시(healer가 `test.skip` 처리해 RED 신호 소실). RED 검증(Step 3)은 어느 경로든 필수 유지.

### Notes
- 라우팅 doc(AGENTS/CLAUDE/GEMINI) 키워드 테이블은 스킬만 등록하므로 무변경. 에이전트 리네임은 `docs/harness-engineering-2026-05.md` 로스터 참조 2곳만 갱신(당시 이름 주석 포함).

## [0.7.2] - 2026-06-11

### Added
- **Playwright 공식 Test Agents 3종 번들** — `agents/playwright-test-{planner,generator,healer}.md` (`init-agents --loop=claude` 산출물의 v1.59.1 스냅샷). 마켓플레이스 설치만으로 `frontend-poc-pipeline:playwright-test-*` 에이전트 사용 가능. 동작 조건: 소비 프로젝트 `.mcp.json`에 `playwright-test` MCP 서버 등록 + `@playwright/test` 설치. 프로젝트가 직접 `init-agents`를 실행한 경우 로컬(`.claude/agents/`)이 항상 우선(버전 정합) — 번들은 fallback.

### Changed
- `e2e-test-gen` Playwright 공식 Test Agents 통합 — 에이전트 감지를 공식 `init-agents` 산출 경로로 정정.
  - 감지 경로: `.claude/agents/playwright-test-{planner,generator,healer}.md`(`npx playwright init-agents --loop=claude`, Playwright v1.56+) 1순위, 레거시 `agents/*playwright*.md` 2순위 fallback. (기존엔 비공식 유령 경로 `agents/[project]-playwright-test-*.md`만 글롭해 공식 산출물을 감지하지 못함)
  - 공식 산출물 컨벤션 반영: `specs/`(planner 테스트 계획, 1 spec ↔ 1 test file), `seed.spec.ts`(환경 부트스트랩 시드), `.mcp.json`의 `playwright-test` MCP 서버(`npx playwright run-test-mcp-server`) 등록 확인.
  - planner 위임 전제 명시: planner는 실행 중인 앱을 라이브 탐색 — 앱 미실행 시 내장 로직 폴백.
  - **healer 선별 사용 규칙**: TDD RED("구현 없음" FAIL)에는 호출 금지 — healer가 고칠 수 없는 기능을 `test.skip` 처리해 RED 신호를 지우기 때문. selector/타이밍 오류에만 위임.
  - 에이전트 미생성 시 §13.5 정신대로 자동 실행 없이 opt-in 안내(`init-agents`가 기존 `.mcp.json`을 덮어쓰는 점 경고 포함) 후 내장 로직 진행.

## [0.7.1] - 2026-06-10

### Added
- `validate-plugin.py` 라우팅 역방향 검증 — 스킬 디렉토리가 존재하는데 AGENTS/CLAUDE/GEMINI 라우팅 테이블에서 누락되면 **fail**. (기존엔 미지 참조만 검출하고 누락은 통과하던 사각지대)
- `code-review`/`code-writer`/`test-writer` 스킬 보강 (WP-9006/WP-9138 학습 반영) — 렌더 레벨 hide/filter ≠ 저장 경로 정합, `?? []` 의미 collapse 금지, 캐시·SSR 주입 경로 일치, E2E 인프라는 명령 출력으로만 판정(주관적 스킵 금지).

### Changed
- 라우팅 doc 3종의 shorthand 예시를 `/<skill-name>` 표기로 정정 — 실존 스킬 경로와 혼동되지 않도록 플레이스홀더임을 명시.

## [0.7.0] - 2026-06-05

### Added
- **Hooks 강화 (WP-8982) — advisory → 강제(enforce) 가능 전환.** 모든 훅을 올바른 Claude Code 계약(stdin JSON / exit 2 / Stop·SubagentStop `decision:block`)으로 재구축.
  - `hooks/_lib.sh` — 공유 라이브러리: stdin JSON 파싱(jq → python3 fallback), `.fpp-hooks.json`+env 모드 판정(`warn`/`enforce`/`off`, 킬스위치), deny/block/advise 출력(remediation 포함), `$TMPDIR` 루프가드, planner 검증 헬퍼.
  - `bash-safety-guard`(PreToolUse:Bash) — 위험/난독화 명령 하이브리드 차단(루트·시스템경로 `rm -rf`·fork bomb·`chmod -R 777`·`curl|sh`·`base64|sh`·`bash <(curl)`·force push/refspec). 완전한 보안 경계가 아닌 defense-in-depth.
  - `secret-leak-guard`(PreToolUse:Bash + PostToolUse:Write) — private key·벤더 토큰(AWS/Slack/GitHub/Google)·하드코딩 크리덴셜 차단/경고.
  - `planner-schema-guard`(PostToolUse:Write|Edit|MultiEdit) — `planner.md` 필수 섹션 키워드 검증.
  - `subagent-regate`(SubagentStop) — 계획/설계 에이전트 종료 시 최근 `planner.md` 재검증(루프가드, enforce 시 `decision:block`).
  - `hooks/fpp-hooks.example.json` 설정 예시 + `scripts/test-hooks.sh` fixture 하네스(78 케이스, jq·python3 fallback 양쪽).
- `scripts/validate-plugin.py` — stdlib-only 마켓플레이스 무결성 검증기 (버전 동기화, hooks 스크립트 실존·문법, SKILL.md frontmatter, AGENTS/CLAUDE/GEMINI 라우팅 ↔ skills 일치 검사).
- `.github/workflows/validate.yml` — push/PR 시 검증기 + `shellcheck --severity=error` 자동 실행.
- harness 메타-스킬 기반 운영 하네스 — `.claude/agents/`에 에이전트 3명(skill-architect, routing-syncer, marketplace-validator), `.claude/skills/marketplace-stewardship/`에 오케스트레이터 스킬. CLAUDE.md에 하네스 포인터 + 변경 이력 등록. 마켓플레이스 자산 자체는 무변경 (공존 노선).
- `validate-plugin.py` 확장 — hooks/ 의 모든 `.sh` 가 `CLAUDE_TOOL_INPUT`(존재하지 않는 env) 을 쓰면 **fail**(no-op 회귀 차단), 비참조 스크립트(`_lib.sh` 등)도 `bash -n` 검사.

### Added
- **하네스 강제력 보강 (linter → harness)** — advisory를 넘어 실제로 행동을 구속하는 두 축 추가.
  - `stop-gate`(Stop) + 위반 ledger(`_lib.sh`) — PostToolUse 훅(planner-schema·secret-leak)이 위반을 세션 ledger에 기록하고, Stop hook이 미해결이면 `decision:block`으로 **턴 종료를 차단**(루프가드). PostToolUse는 차단 불가라는 한계를 종착 게이트로 보완.
  - `pipeline-order-guard`(PreToolUse:Write) — `pageComponents` 신규 구현 파일 생성 시 `planner.md` 선존재 + 컴포넌트면 RED 테스트 선존재 강제. planner-before-code·test-before-code 파이프라인 순서를 hook으로 강제.
  - 기본 모드는 `warn`(가이드). 강제하려면 `.fpp-hooks.json`에서 `stop-gate`/`pipeline-order`를 `enforce`로.

### Changed
- advisory 안내 훅 6종(`planner-figma-check`·`test-completeness-check`·`code-review-gate`·`console-log-any-check`·`package-json-change-warn`·`e2e-test-gate`)을 단일 디스패처 `post-write-advisor`(PostToolUse:Write\|Edit\|MultiEdit)로 통합 — 경로/내용 기반 분기. 구조 중복 제거.

### Fixed
- **기존 9개 hook 이 전부 동작하지 않던 버그 수정** — 입력을 존재하지 않는 `CLAUDE_TOOL_INPUT` 환경변수에서 읽어 항상 no-op(차단·경고 미발동)이었음. stdin JSON 파싱으로 전환해 실제 발동하도록 수정.
- `commit-message-check`·`branch-name-check` 가 `exit 1`(non-blocking) 이라 강제되지 않던 문제 → 모드 기반 `exit 2`(enforce) 차단으로 수정.
- `README.md` Hooks 섹션이 실제 `hooks.json` 과 불일치(figma/jira 훅 기술)하던 drift 정정.

### Changed
- `api-integration` 스킬 Apidog MCP 비종속화 + "스펙 미정" 1급 경로화 — 백엔드 API가 아직 없는 게 흔한 FE/BE 병렬 개발 현실 반영.
  - "타입 소스 판별(Spec Availability)" 섹션 신설 — **모드 A(스펙 없음 = 기본): planner.md/PRD 데이터 모델 → 잠정 타입(`// TODO(OpenAPI)` 재정합 마커) + MSW 목 shape 일치 / 모드 B(스펙 있음): 정확 타입**. 스펙 없음은 예외가 아니라 정상 1급 경로.
  - 모드 B 소스 일반화: ①직접 URL `curl`(raw OpenAPI 수신, `WebFetch` 금지 주의) / ②로컬 JSON·YAML / ③Apidog MCP(선택). 특정 MCP·호스트 종속 제거. Scalar registry share URL은 *예시*로만 기재(하드코딩 안 함).
  - 대형 스펙 타겟 추출(`python`/`jq`) + `$ref` → `components.schemas` 해소 규칙 명문화.
  - frontmatter description·제목·템플릿 주석·Phase A2/A6를 모드 A/B 분기로 갱신. README 스킬 표 1행 갱신. 라우팅 키워드 테이블은 무변경(키워드 동일).
- `screen-plan` → `feature-planner` 리네임 + 보강 — 입력 소스(Figma 화면 / PRD / 평범한 티켓 / 이미지) 비종속 이름으로 정정.
  - Confluence 기획 스펙 링크 자동 추적 추가 (Jira description의 `/wiki/.../pages/{PAGE_ID}` 감지 → `confluence_get_page`).
  - 번호 섹션 없는 산문형 티켓 의미 기반 폴백 추가 (`references/plain-ticket-extraction.md`, WP-9137 worked example).
  - 도메인 비종속화 (host→MCP 인스턴스 매핑 일반화), description Triggers 형식 강화.
  - 본문 812→208줄로 축소 + 상세 절차를 `references/` 3종으로 분리 (skill-architect 500줄 가이드 준수).
  - 라우팅 3종·marketplace.json·README·agents·교차참조 스킬(spec-validator/test-writer/workflow) 동기화. `planner.md` 출력 파일명은 유지.
- `/workflow` 가이드 정합화 — broken reference 5종 제거 및 누락 자산 보강:
  - `/planner` → `/screen-plan` 이름 통일 (실제 슬래시 커맨드명 기준).
  - 자산 없는 4종(`/confluence-update`, `/bug-report`, `/build-fix`, `/security-review`) 삭제. Phase 10 → Phase 9로 축소(총 11 → 10 Phases).
  - Phase 0 품질 게이트에 `/spec-validator`, `/figma-prd-validator` 명시 (README와 일관).
  - 부가 커맨드에 `/epic-frontend-splitter` 등록.
  - frontmatter `allowed-tools`의 `mcp-atlassian-nestads` 하드코드를 `mcp-atlassian-*` 패턴으로 일반화하여 헤이폴/Tillion 등 다른 인스턴스 사용자도 prompt 없이 동작.

## [0.6.0] - 2026-05-21

### Changed
- 훅을 플러그인 내부로 이동 — `plugins/frontend-poc-pipeline/hooks/` + `hooks/hooks.json`에서 `${CLAUDE_PLUGIN_ROOT}` 변수로 호출. 설치한 사용자도 별도 설정 없이 동작.
- `marketplace.json`과 `plugin.json` 버전을 `0.6.0`으로 동기화.
- README를 commands ↔ skills 분리, 실제 존재하는 17개 스킬 + 6개 슬래시 커맨드 기준으로 재작성.
- Jira 훅 matcher를 `mcp-atlassian-nestads` 고정에서 `mcp-atlassian-.*` 범용 패턴으로 확장.

### Added
- MIT LICENSE 파일.
- CHANGELOG.md.
- `.gitignore`: `.claude/settings.local.json`, `.omx/`, `.playwright-mcp/`, `_bmad/` 신규 제외 (`.history/`는 이미 등록되어 있었음). 기존에 추적되던 `.history/`, `.playwright-mcp/` 파일은 untrack.

### Removed
- 비어있던 `plugins/frontend-poc-pipeline/skills/screen-plan/`, `skills/test-writer/` 디렉토리 (둘 다 슬래시 커맨드로 별도 존재).
- 워크스페이스 절대 경로에 묶여 있던 `.claude/hooks/` 와 `.claude/settings.json`의 hooks 블록.

## [0.5.0] - 이전

`plugin.json` 기준 0.5.0 — 파이프라인 스킬 + 슬래시 커맨드 구성. (상세 히스토리는 git log 참조)

## [0.1.0] - 초기

`marketplace.json` 초기 게시 버전.
