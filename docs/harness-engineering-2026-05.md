# 하네스 엔지니어링 작업 기록 — 2026년 5월

> `frontend-poc-pipeline` 마켓플레이스를 **사람이 한 곳만 고치고 나머지를 잊는 회귀 없이** 진화시키기 위한 하네스(harness) 구축·정리 작업. 2026-05-08 ~ 2026-05-28 기간 진행분.

---

## 한눈에 보기

| 날짜 | 커밋 | 주제 |
|------|------|------|
| 05-08 | `ba96978` | figma-jira-prd 스킬 문서 명확화 |
| 05-11 | `172f1ca` | figma-jira-prd inference gate + figma-prd-validator 자동 통합 |
| 05-13 | `de862b5` | **Claude Code Hooks 최초 도입** + 단일 Figma 노드 자동 감지 |
| 05-21 | `bdd7be7` | 마켓플레이스 게시용 정리 — 훅 플러그인 내부 이동 + 메타 보강 |
| 05-22 | `9cba0ac` | **마켓플레이스 무결성 검증기 + CI** |
| 05-22 | `b58432f` | **메타-스킬 기반 운영 하네스 도입** (에이전트 3종 + 오케스트레이터) |
| 05-22 | `80f049b` | `/workflow` 가이드 정합화 (broken ref 제거) |
| 05-28 | `6938ca5` | **WP-8981: 파이프라인 에이전트 4종 + 품질 게이트 훅 9종** |

핵심 흐름: **PRD 스킬 보강 → 훅 최초 도입 → 마켓플레이스 패키징 정리 → 검증기/CI로 회귀 차단 → 운영 자동화 에이전트 팀 도입 → 파이프라인 에이전트·품질 게이트 훅 본격 확장**.

---

## 1. PRD 스킬 보강 (05-08 ~ 05-11)

- **`ba96978`** — `figma-jira-prd` 스킬 문서 명확화·정확도 개선.
- **`172f1ca`** — figma-jira-prd에 **inference gate** 추가 + `figma-prd-validator`를 자동 통합.
  - PRD 작성 후 Figma ↔ PRD 갭 검증이 파이프라인 안에서 연결되도록 함.

---

## 2. Claude Code Hooks 최초 도입 (05-13, `de862b5`)

하네스 엔지니어링의 출발점. PRD 업로드 품질을 자동 게이팅하는 훅 3종을 도입.

- **`prd-gate.sh`** — Jira 업로드 전 필수 섹션(4/5/8) 누락 경고 (strict=False newline 파싱 버그 수정).
- **`figma-check.sh`** — Figma MCP 서버 응답 확인 후 재연결 안내.
- **`prd-log.sh`** — Jira PRD 업로드 이력을 `~/.claude/prd-history.log`에 기록.
- `settings.json`에 PreToolUse / PostToolUse hooks 등록.
- figma-jira-prd SKILL: **단일 Figma URL** 입력 시 Phase A(`get_metadata`) → Phase B(child 자동 감지) → Phase C(`design_context`) 플로우 + `inference_mode FULL` 지원.

---

## 3. 마켓플레이스 게시용 정리 (05-21, `bdd7be7`)

설치한 사용자도 별도 워크스페이스 설정 없이 동작하도록 패키징 정리.

- 훅 3종(`figma-check`/`prd-gate`/`prd-log`)을 `plugins/frontend-poc-pipeline/hooks/`로 이동, `hooks.json`에서 `${CLAUDE_PLUGIN_ROOT}` 변수로 호출.
- Jira 훅 matcher를 `mcp-atlassian-nestads` 고정 → `mcp-atlassian-.*` 범용 패턴으로 확장 (heypoll/nestads 공용).
- `marketplace.json` / `plugin.json` 버전을 **0.6.0**으로 동기화.
- README를 commands(6) ↔ skills(17) 표로 분리·재작성.
- `LICENSE`(MIT) + `CHANGELOG.md` 신규 추가.
- 빈 디렉토리·중복 산출물 정리, `.gitignore` 보강 (`.omx/`, `.playwright-mcp/`, `_bmad/` 등).

---

## 4. 무결성 검증기 + CI (05-22, `9cba0ac`)

"한 곳만 고치고 나머지를 잊는" 회귀를 기계적으로 차단하는 게이트.

- **`scripts/validate-plugin.py`** — stdlib-only 검증기 (26 checks):
  - `marketplace.json` ↔ `plugin.json` 버전 동기화
  - plugin source 경로 실존
  - hooks 스크립트 실존·실행권한·`bash -n` 문법
  - SKILL.md frontmatter(name/description) + name ↔ 디렉토리 일치
  - 라우팅 doc(AGENTS/CLAUDE/GEMINI) 참조 유효성 + **세 doc 간 drift 검출**
- **`.github/workflows/validate.yml`** — push/PR 시 검증기 + `shellcheck --severity=error`.
- README에 CI 배지 + Validate 섹션 추가.

---

## 5. 메타-스킬 기반 운영 하네스 도입 (05-22, `b58432f`)

마켓플레이스 운영 자체를 자동화하는 에이전트 팀 + 오케스트레이터.

- **에이전트 3종** (`.claude/agents/`):
  - `skill-architect` — 신규 SKILL.md 초안/audit, skill-writing-guide 준수
  - `routing-syncer` — AGENTS/CLAUDE/GEMINI 3-doc 동기화 + CLAUDE.md 변경 이력
  - `marketplace-validator` — `validate-plugin.py` 게이트
- **오케스트레이터** `marketplace-stewardship` SKILL:
  - 후속 작업 키워드(다시/재실행/업데이트) 포함한 pushy description
  - Phase 0 컨텍스트 확인(`_workspace` 존재 여부 → 초기/부분 재실행/새 실행 분기)
  - 5가지 작업 유형 라우팅(신규 스킬 / audit / 라우팅 동기화 / 검증 / 릴리즈)
  - 파일 기반(`_workspace`) 데이터 전달, 에러 핸들링, 테스트 시나리오 포함
- **공존 노선**: 외부 배포본(`plugins/`) + 저장소 운영 자동화(`.claude/`)를 별개 관리. 기존 v0.6.0 마켓플레이스 자산은 무변경, 26/26 checks 여전히 통과.

---

## 6. `/workflow` 가이드 정합화 (05-22, `80f049b`)

- broken reference 5종 제거(`/planner`→`/screen-plan`, `/confluence-update`·`/bug-report`·`/build-fix`·`/security-review` 삭제).
- Phase 10 → Phase 9 축소, Phase 0 품질 게이트에 `/spec-validator`+`/figma-prd-validator` 명시.
- 부가 커맨드에 `/epic-frontend-splitter` 등록, `allowed-tools`의 mcp-atlassian 인스턴스 generic화.

---

## 7. WP-8981: 파이프라인 에이전트 + 품질 게이트 훅 (05-28, `6938ca5`)

도메인 파이프라인(설계→테스트→구현→리뷰)을 에이전트화하고, TDD/PR 규율을 훅으로 강제.

- **파이프라인 에이전트 4종 신규**: `architect`(opus), `test-engineer`, `executor`, `code-reviewer`(sonnet).
- **하네스 OMC 의존성 제거**: 운영 에이전트 3종 + 오케스트레이터를 파일 기반 핸드오프로 교체.
- **강제 규칙 2종** (`.claude/rules/`):
  - `pr-required` — PR/MR 생성 시 `pull-request-description` 스킬 필수
  - `tdd-required` — RED → GREEN → REFACTOR 순서 강제
- **품질 게이트 훅 9종**:
  - PostToolUse 6종 — planner / test-completeness / code-review / console-log·any / package.json 변경 경고 / e2e
  - PreToolUse 3종 — commit message / branch name / PR 게이트 차단
- CI 수정: shellcheck glob 빈 디렉토리 실패 → `find + xargs --no-run-if-empty`.
- 검증기 **39/39 checks passed**.

---

## 누적 결과 (5월 말 기준)

- **훅**: 0개 → 12종 (PRD 게이트 3 + 품질 게이트 9), 모두 플러그인 내부에서 `${CLAUDE_PLUGIN_ROOT}` 기반 동작.
- **에이전트**: 운영 3종(skill-architect/routing-syncer/marketplace-validator) + 파이프라인 4종(architect/test-engineer/executor/code-reviewer).
- **검증/CI**: `validate-plugin.py` 26 → 39 checks, GitHub Actions로 push/PR마다 게이팅.
- **규율**: planner-required(이전부터) + tdd-required + pr-required로 파이프라인 순서 강제.
- **방향성**: OMC 등 외부 의존을 점진적으로 걷어내고 **파일 기반 핸드오프**로 자립화 → 6월 초 Apidog/Atlassian 인스턴스 비종속화로 이어짐.

---

*생성: 2026-06-01 · 범위: git `ba96978`(05-08) ~ `6938ca5`(05-28)*
