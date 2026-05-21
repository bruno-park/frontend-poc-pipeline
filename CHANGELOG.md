# Changelog

이 파일은 [Keep a Changelog](https://keepachangelog.com/) 형식을 따르고
프로젝트는 [Semantic Versioning](https://semver.org/)을 사용합니다.

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
