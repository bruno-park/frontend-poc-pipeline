# 하네스 재정비 설계서 (W1)

| 항목 | 내용 |
|---|---|
| 작성자 | 박준 (bruno.park@wisebirds.com) |
| 작성일 | 2026-05-22 |
| 주차 | W1 (5/1 ~ 5/9) |
| 관련 티켓 | [WP-8980](https://wisebirds.atlassian.net/browse/WP-8980) — A-1 하네스 아키텍처 재정비 설계 |
| 대상 저장소 | [bruno-park/frontend-poc-pipeline](https://github.com/bruno-park/frontend-poc-pipeline) |
| 기준선 (As-Is) | v0.6.0 게시 직후 (2026-05-21 16:26, `bdd7be7`) |

## 0. TL;DR

1Q 동안 구축된 마켓플레이스(v0.6.0, 17 skill + 6 command + 3 hook)를 W1에 점검한 결과 5개의 결함 클래스가 식별됐다. 본 설계서는 **그 결함을 어떤 순서·어떤 산출물로 수정할지의 계획**을 정의한다. 적용 자체는 단계별로 W1~W3 안에 분산한다.

| 결함 | 영향 | 수정 단계 |
|---|---|---|
| 마켓플레이스 메타 회귀 차단 부재 | marketplace.json ↔ plugin.json 버전 어긋남, SKILL.md frontmatter 누락이 무방비 | Step 1 |
| 자동 검증 게이트 부재 | 사람이 누락을 잊으면 그대로 배포 | Step 2 |
| 라우팅 doc 3-doc drift | AGENTS/CLAUDE/GEMINI 중 하나만 갱신하고 다른 둘을 잊는 회귀 (실제 발생) | Step 3 |
| 운영(skill 추가·audit·릴리즈) 자동화 부재 | 신규 skill 추가 시 사람이 4~5곳 수동 동기화 | Step 4 |
| `/workflow` 가이드 broken reference 5종 + 누락 자산 3종 | 사용자가 명령어 입력 시 막힘. 신규 도입 skill이 가이드에 노출 안 됨 | Step 5 |

## 1. As-Is — 1Q 말 시점 자산 현황 (기준선)

### 1-1. 마켓플레이스 메타
| 자산 | 위치 | 상태 |
|---|---|---|
| 마켓플레이스 매니페스트 | `.claude-plugin/marketplace.json` | v0.6.0 |
| 플러그인 매니페스트 | `plugins/frontend-poc-pipeline/.claude-plugin/plugin.json` | v0.6.0 |
| LICENSE / `.gitignore` | 루트 | MIT / personal allow-paths 제외 |

### 1-2. Phase 0~10 자산 (workflow.md 표기 기준 — broken ref 포함)
| Phase | 자산 (workflow.md) | 실제 |
|---|---|---|
| 0 | `figma-jira-prd` | ✅ 실재 |
| 1 | `branch-from-ticket` | ✅ |
| 2 | `/planner` | ❌ 자산 없음 (실제 슬래시 커맨드는 `/screen-plan`) |
| 3 | `api-integration` | ✅ |
| 4 | `/test-writer` | ✅ |
| 5 | `/code-writer` | ✅ |
| 6 | `/refactor` | ✅ |
| 7 | `coverage-report` | ✅ |
| 8 | `code-review` | ✅ |
| 9 | `/confluence-update` | ❌ 자산 없음 |
| 10 | `pull-request-description` | ✅ |
| 부가 | `/bug-report`, `/build-fix`, `/security-review` | ❌ 자산 없음 (총 3종) |

### 1-3. Hook 3개
| Hook | matcher | 비고 |
|---|---|---|
| `figma-check.sh` | `mcp__figma-dev-mode-mcp-server__.*` | ✅ |
| `prd-gate.sh` | `mcp__mcp-atlassian-.*__jira_update_issue` | ✅ (v0.6.0에서 generic화) |
| `prd-log.sh` | `mcp__mcp-atlassian-.*__jira_update_issue` | ✅ |

### 1-4. Skills 17개 — frontmatter 존재는 확인됨 (description 강도 미측정)
PRD·테스트·UI·검토·릴리즈 등 phase별 분포는 §3 Action Plan에서 활용.

### 1-5. 라우팅 doc 3개
| Doc | figma-prd-validator 라우팅 행 |
|---|---|
| AGENTS.md | ❌ 누락 (1Q 말 시점) |
| CLAUDE.md | ✅ 존재 |
| GEMINI.md | ❌ 누락 |

→ **실제 발생한 drift**. 사람의 부주의로 한 doc만 갱신된 케이스. 본 설계의 핵심 동기 중 하나.

## 2. To-Be — 2Q 운영 안정성 목표

| 능력 | To-Be 상태 |
|---|---|
| 메타 무결성 | marketplace ↔ plugin 버전 불일치 + SKILL.md frontmatter 누락 + hooks 스크립트 깨짐을 사람이 보기 전 자동 차단 |
| 라우팅 3-doc | 한 doc만 갱신하고 다른 둘을 잊는 회귀 자동 차단 |
| 검증 자동화 | 모든 push/PR에서 CI가 자동 검증 |
| 운영 자동화 | 신규 skill 추가/audit/릴리즈가 단일 트리거로 시작 가능, 사람은 검토만 |
| 사용자 가이드 정합성 | `/workflow` 안내 커맨드가 모두 실재하는 자산을 가리킴 |

## 3. Gap & Action Plan — 5 Step

각 step은 **산출물 / 측정 가능 효과 / 의존성 / 진행 상태**를 가진다.

### Step 1 — 마켓플레이스 메타 정합 검증기

**Gap:** 사람이 marketplace.json 버전을 올리고 plugin.json은 잊거나, 신규 skill 디렉토리만 만들고 SKILL.md를 잊을 위험.

**산출물:**
- `scripts/validate-plugin.py` (stdlib-only, 외부 의존 0)
- 검사 항목:
  1. marketplace.json ↔ plugin.json 버전 일치
  2. marketplace.json의 plugins[].source 경로 실존
  3. hooks/hooks.json이 참조하는 *.sh 실존 + 실행권한 + `bash -n` 문법
  4. skills/*/SKILL.md 존재 + YAML frontmatter(name, description) 파싱 + name ↔ 디렉토리명 일치

**측정:** 일부러 plugin.json 버전을 `0.6.99`로 변조 → `✗ version mismatch` + exit 1. 정상 시 통과 메시지.

**진행 상태:** ✅ 적용 완료 (`9cba0ac`, 5/22 10:42)

---

### Step 2 — CI 자동 게이트

**Gap:** Step 1 스크립트가 있어도 로컬에서 안 돌리면 의미 없음. push/PR마다 자동 실행 필요.

**산출물:**
- `.github/workflows/validate.yml`
- 트리거: 모든 branch push + main 대상 PR
- 동작: `python3 scripts/validate-plugin.py` + `shellcheck --severity=error plugins/**/hooks/*.sh`
- 외부 액션 의존 최소화 (apt 직접 설치)

**측정:** GitHub Actions에서 18s 내 success. README에 배지 추가.

**의존성:** Step 1 완료.

**진행 상태:** ✅ 적용 완료 (`9cba0ac`, 5/22 10:42)

---

### Step 3 — 라우팅 doc drift 검증 + 즉시 정렬

**Gap:** §1-5에 적힌 실제 회귀(AGENTS/GEMINI에 figma-prd-validator 누락) 클래스를 차단해야 함.

**산출물:**
- `scripts/validate-plugin.py`에 `check_routing_drift()` 추가:
  - 세 doc에서 `plugins/.../SKILL.md` 참조 라인 set 비교
  - 코드 펜스 안 placeholder는 무시
  - 한 doc만 다르면 어느 doc에 무엇이 있고 없는지 명시 + exit 1
- 1Q 말 시점 drift 즉시 정렬 (AGENTS/GEMINI에 figma-prd-validator 라우팅 행 추가, CLAUDE.md 본문을 다른 두 doc과 같은 Rule 1/2 구조로 통일)
- spec-validator의 fallback 경로 다단화, component-audit 문구 정리

**측정:** 일부러 AGENTS.md에서 figma-prd-validator 행 삭제 → `✗ routing table drift AGENTS.md vs CLAUDE.md / GEMINI.md` + exit 1.

**의존성:** Step 1 검증기 구조.

**진행 상태:** ✅ 적용 완료 (`ec16647`, 5/22 10:42)

---

### Step 4 — 운영 하네스 (Producer-Reviewer 3인 팀 + 오케스트레이터)

**Gap:** 신규 skill 추가 시 사람이 (1) SKILL.md 작성 (2) AGENTS/CLAUDE/GEMINI 3-doc 라우팅 추가 (3) validate-plugin.py 실행 (4) CHANGELOG/변경 이력 갱신을 모두 수동으로 해야 함. 누락 위험 + 시간 소모.

**산출물 (harness 메타-스킬 기반):**
- 에이전트 3명 정의 — `.claude/agents/`:
  - `skill-architect.md` — SKILL.md 초안/audit, skill-writing-guide 준수
  - `routing-syncer.md` — 3-doc 동기화 + CLAUDE.md 변경 이력 갱신
  - `marketplace-validator.md` — Step 1·2 게이트 자동 호출
- 오케스트레이터 스킬 — `.claude/skills/marketplace-stewardship/SKILL.md`:
  - 5가지 작업 유형(신규 스킬 / audit / 라우팅 동기화 / 검증 / 릴리즈) 라우팅
  - Phase 0 컨텍스트 확인(`_workspace/` 분기 — 초기/부분 재실행/새 실행)
  - TeamCreate + TaskCreate + SendMessage (에이전트 팀 + Producer-Reviewer)
  - 파일 기반 데이터 전달, 에러 핸들링, 테스트 시나리오 포함
- CLAUDE.md 하단에 하네스 포인터 + 변경 이력 테이블 등록 (harness 가이드 준수)
- `.claude/commands/` 생성 안 함 (harness 금지 항목)

**측정:** 시스템 프롬프트의 skill 목록에 `marketplace-stewardship` 등장 확인. 트리거 키워드("스킬 추가", "라우팅 점검", "릴리즈 준비")로 호출 시 팀이 자체 조율.

**의존성:** Step 1·2 (validator를 게이트로 사용).

**제약:** 마켓플레이스 자산(plugins/) 무변경. 외부 배포본 / 로컬 운영 자동화 **공존 노선**.

**진행 상태:** ✅ 적용 완료 (`b58432f`, 5/22 15:39)

---

### Step 5 — `/workflow` 가이드 정합화

**Gap:** §1-2에 명시된 broken ref 5종 + 누락 자산 3종. 사용자가 `/planner` 입력 시 동작 안 함.

**산출물 (workflow.md 단일 파일 편집):**
- `/planner` → `/screen-plan` 일괄 치환 (5+곳)
- 자산 없는 4종(`/confluence-update`, `/bug-report`, `/build-fix`, `/security-review`) 삭제
- Phase 10 → Phase 9 번호 축소 (총 11 → 10 Phases)
- Phase 0 품질 게이트에 `/spec-validator` + `/figma-prd-validator` 명시 (README와 일관성 회복)
- 부가 커맨드 + 감사 카드에 `/epic-frontend-splitter` 등록
- frontmatter `allowed-tools` 인스턴스 fixate(`mcp-atlassian-nestads`) → generic(`mcp-atlassian-*`)

**측정:** 정합화 후 `grep -n '/planner\|/confluence-update\|/bug-report\|/build-fix\|/security-review' commands/workflow.md` 결과 0. 신규 자산 3종 등장 11회.

**의존성:** Step 1 (마켓플레이스 자산 무손상 회귀 확인).

**진행 상태:** ✅ 적용 완료 (`80f049b`, 5/22 17:26)

---

## 4. 검증 방법 (정상/회귀 양방향)

| 시나리오 | 기대 |
|---|---|
| 정상 push (변경 없음) | `validate-plugin.py` 26/26 checks pass, CI 18s success |
| `plugin.json` 버전 변조 | `✗ version mismatch` + exit 1 |
| `hooks/*.sh` 권한 제거 | `✗ hook script not executable` + exit 1 |
| `SKILL.md` frontmatter 제거 | `✗ SKILL.md frontmatter missing` + exit 1 |
| 한 라우팅 doc에서 행 삭제 | `✗ routing table drift` + exit 1 + 어느 doc에 없는지 명시 |
| `/workflow` 안의 broken ref | (Step 5 적용 후 회귀하지 않는 한 발생 안 함. 향후 commands/*.md 검증 추가로 보완 — §5 참조) |

## 5. 후속 강화 후보 (W2 이후)

§3에서 다루지 않은 추가 강화 항목. 우선순위는 박준이 결정.

| 우선순위 | 항목 | 근거 |
|---|---|---|
| High | trigger 자동 테스트 (should-trigger vs should-NOT-trigger 각 8~10개) | harness Phase 6-4. description "pushy함" 정량화. |
| High | SKILL.md 본문 500줄 초과 audit + references/ 자동 분리 | harness Lean 원칙. 큰 스킬(`figma-jira-prd`, `code-review` 등) 우선. |
| Medium | `commands/*.md` 존재 검증을 `validate-plugin.py`에 추가 | 현재 SKILL만 검사. Step 5와 같은 broken slash command 회귀 차단. |
| Medium | with/without-skill 비교 실행 | harness Phase 6-3. 스킬 부가가치 정량화 → 후순위 스킬 폐기 결정 근거. |
| Medium | `_workspace/` 산출물 자동 정리 (오래된 audit 파일 archive) | 하네스 누적 후 디렉토리 비대화 방지. |
| Low | `references/` 본문 ToC 자동 생성 | 300줄+ reference 파일 가독성. |
| Low | hooks 확장 — Phase 7 통과 후 자동 coverage PR 코멘트 | 게이트 → 알림 한 단계 확장. |

## 6. Track 의존성

> ⚠️ **TODO (박준 작성):** Track A~G 정의가 본 설계 단계에서 확정되지 않음.

| Track | 의존하는 W1 Step | 의존하는 §5 후속 강화 | 비고 |
|---|---|---|---|
| A | (자기 자신 — 본 설계서) | — | WP-8980 |
| B | ? | ? | TODO |
| C | ? | ? | TODO |
| D | ? | ? | TODO |
| E | ? | ? | TODO |
| F | ? | ? | TODO |
| G | ? | ? | TODO |

## 7. 일정 — W1 실제 진행분 (참고용)

| 시각 (KST) | Step | Git ref |
|---|---|---|
| 5/21 16:26 | (기준선) v0.6.0 게시본 정리 | `bdd7be7` |
| 5/22 10:42 | Step 3 — 라우팅 정렬 + 스킬 문구 보강 | `ec16647` |
| 5/22 10:42 | Step 1 + 2 — validator + CI | `9cba0ac` |
| 5/22 15:39 | Step 4 — 운영 하네스 (.claude/agents + marketplace-stewardship) | `b58432f` |
| 5/22 17:26 | Step 5 — /workflow 정합화 | `80f049b` |

> 의존성 정합상 정상 순서는 1→2→3→5→4였으나, 실제로는 3을 먼저 처리한 뒤 1+2를 묶었다. 산출물 자체에는 영향 없음.

## 8. 박준 다음 액션 체크리스트

- [ ] 본 설계서 검토 + Step 정의에 누락된 결함이 있는지 확인
- [ ] §5의 High 3건(trigger 테스트 / SKILL.md audit / commands 검증) 중 W2 작업화 여부 결정
- [ ] §6의 Track A~G 정의 채우기
- [ ] Confluence 게시 위치 결정 (space + 부모 페이지)
- [ ] WP-8980 상태 전환 (백로그 → 진행 중 / 완료)
- [ ] 본 마크다운 Confluence 업로드 — mcp tool로 가능, 부모 페이지만 알려주면 됨
