# frontend-poc-pipeline

Claude Code plugin marketplace for AI-driven frontend PoC pipeline.

## Pipeline

```
[1단계] figma-jira-prd       → Figma + Jira → PRD 자동 작성
[2단계] branch-from-ticket   → Jira 티켓 기반 브랜치 생성
        screen-plan          → Figma → planner.md 화면 설계
[3단계] test-writer          → TDD RED (unit + e2e 테스트 작성)
[4단계] api-integration      → Scalar MCP → React Query 훅 생성
        ui-builder           → planner.md → UI 컴포넌트 구현
[5단계] pull-request-description → AI 코드리뷰 → PR 자동 생성
```

## Install

```
/plugin marketplace add bruno-park/frontend-poc-pipeline
/plugin install frontend-poc-pipeline@frontend-poc-pipeline
```

## Skills

| Skill | Phase | Description |
|-------|-------|-------------|
| `figma-jira-prd` | 1 | Figma UI + Description + Jira → PRD |
| `branch-from-ticket` | 2 | Jira 티켓 → 브랜치 자동 생성 |
| `screen-plan` | 2 | Figma → planner.md 화면 설계 |
| `test-writer` | 3 | TDD RED: unit + e2e 테스트 |
| `api-integration` | 4 | Scalar MCP → React Query 훅 |
| `ui-builder` | 4 | planner.md → UI 컴포넌트 |
| `pull-request-description` | 5 | PR 설명 자동 생성 |
