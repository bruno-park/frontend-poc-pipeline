# Routing Request — screen-plan → feature-planner

**변경 유형:** 스킬 리네임 (`screen-plan` → `feature-planner`)

## 새 트리거 키워드 (라우팅 테이블용)
`/feature-planner`, `화면 기획`, `컴포넌트 계획`, `planner.md 작성`, `screen plan`, `feature plan`, `구현 계획`

## 라우팅 doc 갱신 (3종 동일하게)
기존 행:
`| /screen-plan, 화면 기획, 컴포넌트 계획, planner.md 작성, screen plan | plugins/frontend-poc-pipeline/skills/screen-plan/SKILL.md |`
→ 새 행:
`| /feature-planner, 화면 기획, 컴포넌트 계획, planner.md 작성, screen plan, feature plan, 구현 계획 | plugins/frontend-poc-pipeline/skills/feature-planner/SKILL.md |`

## screen-plan → feature-planner 치환 대상 (11개 파일, planner.md 출력파일명은 보존)
- AGENTS.md (라우팅 1)
- CLAUDE.md (라우팅 1 + alias 표에 /feature-planner 추가 + 하네스 변경 이력 신규 행)
- GEMINI.md (라우팅 1)
- README.md (스킬 요약 1)
- CHANGELOG.md (신규 엔트리, 과거 /planner→/screen-plan 히스토리 보존)
- .claude-plugin/marketplace.json (파이프라인 문자열 1)
- plugins/.../agents/architect.md (경로+명령 2)
- plugins/.../agents/executor.md (명령 2)
- plugins/.../skills/spec-validator/SKILL.md (교차참조 2)
- plugins/.../skills/test-writer/SKILL.md (참조 2)
- plugins/.../skills/workflow/SKILL.md (18 — 스킬명만 치환, planner.md 출력파일명 유지)

## CLAUDE.md 하네스 변경 이력 추가 행
| 2026-06-01 | screen-plan → feature-planner 리네임 + 보강: Confluence 기획 스펙 링크 추적(Step 1B-2), 산문형 티켓 의미 기반 폴백, 도메인 비종속화(host→MCP 매핑 일반화), 본문 812→208줄 references/ 분리 | plugins/.../skills/feature-planner/, 라우팅 3종 + 교차참조 8개 파일 | 입력 소스 비종속 이름으로 정정 + 실무 티켓(Confluence 링크·산문형)에서도 고품질 planner.md 생성 |
