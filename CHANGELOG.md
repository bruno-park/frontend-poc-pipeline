# Changelog

이 파일은 [Keep a Changelog](https://keepachangelog.com/) 형식을 따르고
프로젝트는 [Semantic Versioning](https://semver.org/)을 사용합니다.

## [Unreleased]

### Added
- `scripts/validate-plugin.py` — stdlib-only 마켓플레이스 무결성 검증기 (버전 동기화, hooks 스크립트 실존·문법, SKILL.md frontmatter, AGENTS/CLAUDE/GEMINI 라우팅 ↔ skills 일치 검사).
- `.github/workflows/validate.yml` — push/PR 시 검증기 + `shellcheck --severity=error` 자동 실행.
- harness 메타-스킬 기반 운영 하네스 — `.claude/agents/`에 에이전트 3명(skill-architect, routing-syncer, marketplace-validator), `.claude/skills/marketplace-stewardship/`에 오케스트레이터 스킬. CLAUDE.md에 하네스 포인터 + 변경 이력 등록. 마켓플레이스 자산 자체는 무변경 (공존 노선).

### Changed
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
