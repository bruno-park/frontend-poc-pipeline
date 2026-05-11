# frontend-poc-pipeline — Claude Code Instructions

## Overview

AI-driven frontend PoC pipeline: Figma → PRD → TDD → PR

## Pipeline

```
[1] figma-jira-prd         → Figma + Jira → PRD 자동 작성
    figma-prd-validator    → Figma ↔ PRD 갭 검증 (품질 게이트)
[2] branch-from-ticket     → Jira 티켓 기반 브랜치 생성
    screen-plan            → Figma → planner.md 화면 설계
[3] test-writer            → TDD RED (unit + e2e 테스트 작성)
[4] api-integration        → React Query 훅 생성
    ui-builder             → planner.md → UI 컴포넌트 구현
[5] pull-request-description → PR 자동 생성
```

## Skills (OMC Plugin)

Claude Code는 `/skill-name` 명령어로 스킬을 실행합니다.
스킬 정의: `plugins/frontend-poc-pipeline/skills/<name>/skill.md`

| 명령어 | 설명 |
|--------|------|
| `/figma-jira-prd` | Figma UI + Jira → PRD 작성 |
| `/figma-prd-validator` | Figma ↔ PRD 갭 검증 (누락·불일치 리포트) |
| `/branch-from-ticket` | Jira 티켓 번호로 브랜치 생성 |
| `/screen-plan` | Figma → planner.md 화면 설계 |
| `/test-writer` | TDD RED: 테스트 먼저 작성 |
| `/api-integration` | Apidog MCP → React Query 훅 |
| `/ui-builder` | planner.md → React 컴포넌트 구현 |
| `/pull-request-description` | PR/MR 설명 자동 생성 |
| `/code-review` | 브랜치 diff 또는 PR 코드 리뷰 |
| `/e2e-test-gen` | Playwright E2E 테스트 생성 |
| `/unit-test-gen` | Vitest 단위 테스트 생성 |
| `/coverage-report` | 테스트 커버리지 분석 및 Jira 기록 |
| `/spec-validator` | Figma description 정책 검증 |
| `/component-audit` | pageComponents 파이프라인 준수 감사 |
| `/epic-frontend-splitter` | 에픽에서 프론트엔드 하위 티켓 생성 |
| `/conventions` | 프로젝트 컨벤션 출력 |
| `/release-notes` | 릴리즈 노트 자동 생성 |
| `/vitest-setup` | Vitest + RTL 설치 및 설정 |
| `/msw-setup` | MSW 설치 및 핸들러 설정 |

## Key Conventions

- 컴포넌트 설계는 항상 `planner.md`를 먼저 작성
- TDD: 테스트 먼저(RED) → 구현(GREEN) → 정리(REFACTOR)
- UI: shadcn/ui 우선, rsuite fallback
- API 훅: React Query (TanStack Query)
- 타입: TypeScript strict mode
- 컨벤션 상세: `plugins/frontend-poc-pipeline/skills/conventions/skill.md`
