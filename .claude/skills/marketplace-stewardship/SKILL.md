---
name: marketplace-stewardship
description: "frontend-poc-pipeline 마켓플레이스의 유지·진화를 자체 조율 가능한 에이전트 팀으로 처리한다. 신규 skill 추가, 기존 skill audit/리팩터, 라우팅 doc(AGENTS/CLAUDE/GEMINI) drift 점검·동기화, hooks/메타 수정, 릴리즈 게이트, 검증 회귀 발견 등 마켓플레이스 자산을 건드리는 모든 요청에 사용. 트리거: '스킬 추가/수정/감사', '라우팅 동기화/점검', '검증 돌려', '릴리즈 준비/버전 bump', '마켓플레이스 점검/유지보수/리뷰', 그리고 후속 요청 — '다시', '재실행', '업데이트', '결과 기반 개선', '이전 결과 보완'. 단순한 한 줄 질문이나 외부 프로젝트 자동화(figma → PR)는 본 스킬 트리거가 아니다 — 후자는 plugins/frontend-poc-pipeline/skills/*의 도메인 스킬을 직접 호출."
---

# Skill — marketplace-stewardship (Orchestrator)

frontend-poc-pipeline 마켓플레이스의 유지·진화를 위한 오케스트레이터. 3명의 에이전트(skill-architect, routing-syncer, marketplace-validator)로 구성된 팀을 조율한다.

**실행 모드:** 에이전트 팀 (Producer-Reviewer 패턴 — architect/syncer가 producer, validator가 reviewer)

## Phase 0: 컨텍스트 확인

워크플로우 시작 시 항상 다음을 확인하고 실행 모드를 결정한다.

1. **`_workspace/` 존재 여부 확인**
   - 없음 → 초기 실행
   - 있음 + 사용자가 부분 수정 요청 → **부분 재실행**: 해당 산출물 파일만 재생성, 다른 에이전트는 건너뜀
   - 있음 + 사용자가 새로운 입력 제공 → **새 실행**: 기존 `_workspace/`를 `_workspace_prev/`로 이동 후 신규 진행
2. **사용자 요청 유형 판별** (Phase 1에서 라우팅 결정)
3. **CLAUDE.md 변경 이력 마지막 항목 확인** — 직전 변경의 사유/대상 파악, 중복 작업 방지

## Phase 1: 작업 유형 라우팅

요청 키워드와 _workspace 상태로 다음 5가지 유형 중 하나로 분류한다. 유형별로 팀 구성과 데이터 흐름이 다르다.

| 유형 | 판별 키워드 | 활성 에이전트 | 산출물 위치 |
|------|------------|--------------|------------|
| A. 신규 스킬 추가 | "스킬 추가", "skill 만들어", "{이름} 스킬 신설" | architect → syncer → validator | `plugins/.../skills/{name}/SKILL.md` + 3 라우팅 doc |
| B. 기존 스킬 audit | "스킬 점검", "audit", "{이름} 리팩터" | architect → validator | `_workspace/skill-audit-{name}.md` + (수정 시) SKILL.md |
| C. 라우팅 동기화 | "라우팅 점검", "drift", "doc 동기화" | syncer → validator | 3 라우팅 doc |
| D. 검증 게이트 | "검증", "validator 돌려", "릴리즈 전 점검" | validator만 | `_workspace/validator-{ts}.log` |
| E. 릴리즈 준비 | "버전 bump", "릴리즈 준비", "0.X.Y로 올려" | syncer + validator (architect는 보조) | marketplace.json + plugin.json + CHANGELOG + 변경 이력 |

복합 요청(예: "스킬 추가하고 릴리즈까지")은 A → E 순차 실행.

## Phase 2: 팀 구성 및 작업 할당

```
TeamCreate(team_name="marketplace-stewards", members=[활성 에이전트들])
TaskCreate(각 에이전트 작업, addBlockedBy로 의존관계 명시)
```

**데이터 전달 (혼합):**
- 메시지 기반(`SendMessage`): 에이전트 간 실시간 피드백·결과 통보
- 태스크 기반(`TaskUpdate`): 진행 상태 추적, 의존성 관리
- 파일 기반(`_workspace/`): 중간 산출물 보존 — 파일명 컨벤션 `{유형}_{agent}_{artifact}.md` (예: `audit_architect_spec-validator.md`)

**최종 산출물만 실제 위치(plugins/, AGENTS.md 등)에 출력하고 중간 파일은 `_workspace/`에 남긴다.**

## Phase 3: 모니터링

리더(오케스트레이터)는 TaskList로 진행을 폴링하지 않고, 팀원들이 완료/실패할 때까지 자체 조율을 신뢰한다. 각 팀원이 task를 `completed`로 마킹하면 결과 수집.

검증 단계(Phase 4)에서 validator의 결과가 fail이면 책임 에이전트에게 자동 재할당 (SendMessage로 원인 전달 + TaskCreate로 fix task).

## Phase 4: 결과 종합

모든 task가 completed가 되면:
1. 산출물 경로와 변경 요약을 사용자에게 보고
2. `routing-syncer`에게 CLAUDE.md 변경 이력 추가 요청 (날짜·변경내용·대상·사유)
3. `marketplace-validator`에게 최종 게이트 호출 (이미 통과했어도 다른 영향 없는지 마지막 확인)
4. 팀 정리 (`TeamDelete`)

## Phase 5: 피드백 수집

종료 후 사용자에게: "결과에서 개선할 부분이 있나요? 에이전트 역할이나 워크플로우에 바꾸고 싶은 점은요?"
강요하지 않되 기회를 반드시 제공. 피드백은 harness Phase 7-2 매핑에 따라 적절한 산출물에 반영.

## 에러 핸들링

| 시나리오 | 대응 |
|---------|------|
| validate-plugin.py 새 false fail | architect에게 SendMessage로 원인 진단 → 스크립트 패치 PR 제안 (사용자 확인 필수) |
| 세 라우팅 doc drift 발견 | syncer가 처리 — 어느 doc이 ground truth인지 사용자 확인 후 정렬 |
| Phase 4에서 두 번 연속 validator fail | 자동 재시도 중단. 팀 정지 + 사용자 보고 ("같은 실패가 반복됨, 수동 개입 필요") |
| 사용자가 도중에 중단 요청 | `_workspace/`는 보존, 팀만 `TeamDelete`. 다음 호출 시 부분 재실행 가능 |

## 테스트 시나리오

**정상 흐름 — 유형 A (신규 스킬 추가):**
```
사용자: "design-token-extractor 스킬 추가해줘 — Figma 노드에서 디자인 토큰만 뽑는 용도"
→ Phase 0: _workspace 없음 → 초기 실행
→ Phase 1: 키워드 매치 → 유형 A
→ Phase 2: team=[architect, syncer, validator], task1=architect 초안, task2=syncer 라우팅(blockedBy=task1), task3=validator(blockedBy=task1+task2)
→ Phase 3: architect가 SKILL.md 작성 → SendMessage(syncer, "추가 완료") → syncer가 3 doc 갱신 → SendMessage(validator) → validator가 26 checks 실행
→ Phase 4: 통과 보고 + CLAUDE.md 변경 이력 추가
→ Phase 5: 피드백 요청
```

**에러 흐름 — 유형 D 중 validator fail:**
```
사용자: "릴리즈 전 검증 돌려"
→ Phase 1: 유형 D
→ Phase 2: team=[validator]만 활성
→ Phase 3: validate-plugin.py 실행 → "routing table drift AGENTS.md vs GEMINI.md" fail
→ Phase 4 대신 에러 핸들링: syncer 자동 호출 → drift 원인 확인 → 사용자에게 ground truth 질문 → 정렬 → 재검증 → 통과
→ Phase 4: 보고 + 변경 이력 추가 (drift 수정 사유 명시)
```

## 참고

- 팀원 정의: `.claude/agents/{skill-architect,routing-syncer,marketplace-validator}.md`
- 검증 게이트 스크립트: `scripts/validate-plugin.py`
- CI: `.github/workflows/validate.yml`
- harness 메타-스킬 (이 오케스트레이터를 만든 도구): `~/.claude/plugins/marketplaces/harness-marketplace/skills/harness/SKILL.md`
