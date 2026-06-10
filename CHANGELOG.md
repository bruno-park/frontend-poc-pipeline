# Changelog

이 파일은 [Keep a Changelog](https://keepachangelog.com/) 형식을 따르고
프로젝트는 [Semantic Versioning](https://semver.org/)을 사용합니다.

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
