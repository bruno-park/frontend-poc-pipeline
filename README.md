# frontend-poc-pipeline

[![validate](https://github.com/bruno-park/frontend-poc-pipeline/actions/workflows/validate.yml/badge.svg)](https://github.com/bruno-park/frontend-poc-pipeline/actions/workflows/validate.yml)

Claude Code plugin marketplace for an AI-driven frontend PoC pipeline:
**Figma → PRD → Branch → TDD → Implementation → PR**.

## Install

```
/plugin marketplace add bruno-park/frontend-poc-pipeline
/plugin install frontend-poc-pipeline@frontend-poc-pipeline
```

설치 후 `${CLAUDE_PLUGIN_ROOT}` 기반으로 hooks가 자동 등록되며, 별도의 워크스페이스 설정 없이 동작합니다.

## Pipeline

```
[1] figma-jira-prd          → Figma + Jira → PRD 작성
    figma-prd-validator     → Figma ↔ PRD 갭 검증 (품질 게이트)
    spec-validator          → Figma description 정책 검증
[2] branch-from-ticket      → Jira 티켓 → 브랜치 생성
    epic-frontend-splitter  → 에픽 → 프론트 하위 티켓 분해
[3] feature-planner         → planner.md (구현 청사진) 작성
[4] test-writer             → TDD RED (위임: unit-test-gen, e2e-test-gen)
    api-integration         → React Query 훅 생성 (test-writer와 병렬)
[5] code-writer             → TDD GREEN: 구현 (--ui 컴포넌트 / --api → api-integration 위임)
[6] refactor                → TDD REFACTOR: GREEN 유지하며 정리
[7] code-review             → 로컬 diff 또는 PR 코드 리뷰
    coverage-report         → 커버리지 + AC 매핑 리포트
[8] pull-request-description → PR/MR 설명 생성
    release-notes           → git log + Jira → 릴리즈 노트
```

## Skills

| Skill | Phase | Description |
|-------|-------|-------------|
| `figma-jira-prd` | 1 | Figma UI + Description + Jira → PRD |
| `figma-prd-validator` | 1 | Figma ↔ PRD Gap Report |
| `spec-validator` | 1 | Figma description 정책 검증 |
| `branch-from-ticket` | 2 | Jira 티켓 → 브랜치 자동 생성 |
| `epic-frontend-splitter` | 2 | 에픽 Jira → 프론트 하위 티켓 자동 생성 |
| `feature-planner` | 3 | Figma/PRD/티켓 → planner.md 구현 청사진 |
| `test-writer` | 4 | TDD RED orchestrator (위임: unit-test-gen, e2e-test-gen) |
| `unit-test-gen` | 4 | 단위 테스트 작성 (test-writer 위임 대상) |
| `e2e-test-gen` | 4 | Playwright E2E 테스트 작성 (test-writer 위임 대상) |
| `api-integration` | 4 | Apidog MCP → React Query 훅 |
| `code-writer` | 5 | TDD GREEN 구현 (`--ui` 컴포넌트 / `--api` → api-integration) |
| `ui-builder` | — | ⚠️ DEPRECATED → `code-writer --ui`로 통합 |
| `refactor` | 6 | TDD REFACTOR: GREEN 유지하며 정리 |
| `code-review` | 7 | 로컬/PR 코드 리뷰 |
| `coverage-report` | 7 | 단위/E2E 커버리지 리포트 |
| `pull-request-description` | 8 | PR/MR 설명 자동 생성 |
| `release-notes` | 8 | 릴리즈 노트 생성 |
| `component-audit` | — | pageComponents 파이프라인 준수 감사 |
| `conventions` | — | 프로젝트 공통 컨벤션 레퍼런스 |
| `hotfix` | — | 긴급 운영 핫픽스 fast-path |
| `vitest-setup` | setup | Vitest + RTL 환경 구성 |
| `msw-setup` | setup | Mock Service Worker 설치 |

## Slash Commands

`commands/*.md` 로 정의된 슬래시 커맨드입니다.

| Command | Description |
|---------|-------------|
| `/workflow` | 현재 파이프라인 단계 진단 + 다음 커맨드 안내 |
| `/feature-planner` | Figma/PRD/티켓 → planner.md 구현 계획 |
| `/test-writer` | TDD RED 진입 — 실패 테스트 작성 |
| `/code-writer` | UI/API/All 모드 구현 |
| `/refactor` | GREEN 통과 후 리팩터링 |
| `/hotfix` | 긴급 운영 핫픽스 fast-path |

## Hooks

플러그인 활성화 시 자동 등록되는 보조 훅 (`plugins/frontend-poc-pipeline/hooks/`):

- **PreToolUse `mcp__figma-dev-mode-mcp-server__.*`** — Figma MCP 서버 응답 점검
- **PreToolUse `mcp__mcp-atlassian-*__jira_update_issue`** — PRD 필수 섹션 누락 경고 (업로드는 차단하지 않음)
- **PostToolUse `mcp__mcp-atlassian-*__jira_update_issue`** — PRD 업로드 히스토리를 `~/.claude/prd-history.log`에 기록

## Validate

마켓플레이스/플러그인 메타데이터, hooks 스크립트, skills frontmatter, 멀티-에이전트 라우팅 doc(`AGENTS.md`/`CLAUDE.md`/`GEMINI.md`)의 정합성을 검사합니다.

```
python3 scripts/validate-plugin.py
```

CI는 `.github/workflows/validate.yml` 에서 동일 검증 + `shellcheck --severity=error` 를 돌립니다.

## License

MIT
