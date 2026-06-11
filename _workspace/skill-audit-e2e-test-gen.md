# Skill Audit — e2e-test-gen (2026-06-11)

## 요청
Playwright 공식 Test Agents(https://playwright.dev/docs/test-agents)와 통합.

## 발견 사항 (사실 검증 완료 — playwright v1.60 소스 기준)

### F1. 에이전트 감지 경로가 비공식/유령 컨벤션 (Critical)
- 현재: `Glob: agents/*playwright*.md`, 위임 대상 `agents/[project]-playwright-test-planner.md`
- 실제: `npx playwright init-agents --loop=claude`(v1.56+)는 **`.claude/agents/playwright-test-{planner,generator,healer}.md`** 를 생성
  (소스: `packages/playwright/src/agents/generateAgents.ts` → `ClaudeGenerator.init`)
- 결과: 공식 산출물을 영영 감지 못 함 → 항상 내장 로직으로만 동작

### F2. 공식 산출물 컨벤션 미반영 (High)
- init-agents가 함께 생성하는 것들이 스킬에 없음:
  - `.mcp.json` — `playwright-test` MCP 서버(`npx playwright run-test-mcp-server`). **주의: 기존 .mcp.json을 덮어씀** (ClaudeGenerator는 merge가 아니라 overwrite)
  - `specs/` — planner 산출 테스트 계획 (1 spec ↔ 1 test file)
  - `seed.spec.ts` (testDir 내) — 에이전트 환경 부트스트랩용 시드 테스트
- planner 에이전트는 playwright-test MCP로 **실행 중인 앱을 라이브 탐색**함 — 앱 미실행 시 위임 불가 조건 명시 필요

### F3. healer를 TDD RED에 그대로 쓰면 RED 신호 소실 (High)
- 공식 healer는 "기능이 깨져서 고칠 수 없으면 테스트를 skip 처리"함
- TDD RED 단계의 "구현 없음 FAIL"에 healer를 부르면 RED 테스트가 skip으로 바뀌어 TDD 사이클이 망가짐
- → healer는 selector/타이밍/인프라 오류에만 선별 사용하도록 규칙 추가

### F4. init-agents 자동 실행 금지 (§13.5 정합)
- conventions §13.5(E2E 자동 설치 금지) 정신대로, 에이전트 미생성 시 opt-in 안내만 하고 내장 로직으로 진행

## 적용 수정
- SKILL.md + platforms/web.md 동기 수정 (감지 경로, 위임 대상명, 공식 컨벤션, healer 규칙, opt-in 안내)
- frontmatter description 갱신 (공식 명칭 + init-agents 언급)
- 레거시 `agents/*playwright*.md`는 2순위 fallback으로 유지

## 다음 단계 (validate-request)
- routing-syncer: 키워드 행 변경 없음 — CLAUDE.md 변경 이력 1행 + 버전 bump(0.7.2)만
- marketplace-validator: validate-plugin.py 전체 게이트
