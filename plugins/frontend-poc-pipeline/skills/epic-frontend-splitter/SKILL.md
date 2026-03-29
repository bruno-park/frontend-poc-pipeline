---
name: epic-frontend-splitter
description: "에픽 Jira 티켓에서 프론트엔드 전용 작업을 AI로 추출하고, 화면 단위로 하위 Jira 티켓을 자동 생성합니다. PRD는 figma-jira-prd 양식(User Story + AC, IF/THEN, Validation Rules)으로 작성됩니다. Triggers: (1) '에픽에서 프론트 티켓 만들어', '에픽 분해', 'epic split', (2) '프론트엔드 작업 추출', 'FE 티켓 생성', (3) 에픽 Jira URL + '프론트' 또는 'FE' 키워드"
---

# Epic Frontend Splitter — 에픽 → 프론트엔드 하위 티켓 자동 생성

여러 파트(Backend, Frontend, Deliverer, SDK)가 혼재된 에픽 티켓에서
**프론트엔드 전용 작업만 AI로 추출**하여 화면 단위 하위 Jira 티켓을 생성합니다.
각 티켓의 PRD는 `figma-jira-prd` 양식으로 자동 작성됩니다.

---

## 사용 가이드

```
에픽에서 프론트 티켓 만들어줘

https://wisebirds.atlassian.net/browse/AX-65
```

또는 이슈 키만:

```
epic split AX-65
```

---

## Step 0: 입력 파싱

사용자 입력에서 에픽 Jira URL 또는 이슈 키를 추출합니다.

| 입력 패턴 | 처리 |
|-----------|------|
| `atlassian.net/browse/{KEY}` | URL에서 이슈 키 추출 |
| `AX-65`, `WP-100` 등 | 이슈 키로 직접 사용 |
| 입력 없음 | 아래 템플릿 출력 후 대기 |

입력이 없으면 출력:

```
에픽 Jira URL을 붙여넣어 주세요

https://{your-instance}.atlassian.net/browse/{EPIC_KEY}
```

**MCP 도구 선택:**
- `wisebirds.atlassian.net` → `mcp-atlassian-nestads`
- `heypoll.atlassian.net` → `mcp-atlassian-heypoll`
- 다른 인스턴스 → 도메인 기반으로 판단, 불명확 시 사용자 확인

> Step 5.5에서 figma-jira-prd를 체이닝 호출할 때도 동일한 MCP를 사용해야 합니다.
> 선택된 MCP 이름을 기록해 두고 이후 단계에서 일관되게 적용합니다.

---

## Step 1: 에픽 데이터 수집 (병렬)

아래 2가지를 동시에 호출합니다:

```
[병렬 실행]
1. mcp-atlassian-*:jira_get_issue
   issue_key: {EPIC_KEY}
   fields: *all
   comment_limit: 0

2. mcp-atlassian-*:jira_search
   jql: "parent = {EPIC_KEY}"
   fields: summary, issuetype, status, assignee
   limit: 50
```

### 하위 이슈 페이지네이션

`jira_search` 결과의 `total`이 50을 초과하면 추가 페이지를 조회합니다:
- `startAt: 50`, `startAt: 100` ... 순서로 `total` 이하까지 반복
- 모든 하위 이슈를 수집한 후 FE 티켓 감지를 진행해야 중복 생성을 방지할 수 있음

### 확인 항목

- `issuetype.name` = `에픽` 인지 검증 → 아니면 경고 출력 후 계속 여부 확인
- **기존 FE 티켓 감지 및 모드 결정**:
  - `[FE]` / `[Frontend]` / `[프론트엔드]` prefix 하위 이슈가 **없음** → **생성 모드** (신규 티켓 생성)
  - `[FE]` / `[Frontend]` / `[프론트엔드]` prefix 하위 이슈가 **있음** → **수정 모드** (기존 티켓 업데이트)
    - 기존 FE 티켓 목록을 표시하고 Step 3에서 사용자 확인 후 `jira_update_issue`로 PRD 덮어쓰기
- **prefix 컨벤션 감지**: 기존 하위 이슈의 summary prefix 패턴을 분석
  - `[백엔드]`, `[전송]` 같은 한국어 패턴 → `[프론트엔드]` 사용
  - `[BE]`, `[DLV]` 같은 영어 패턴 → `[FE]` 사용
  - 하위 이슈 없음 → 기본값 `[FE]`
- **이슈 타입 확인**: 기존 하위 이슈가 있으면 그 `issue_type.name`을 티켓 생성에 재사용. 하위 이슈가 없으면 Step 5에서 `jira_get_project`로 확인.
- **서브 에픽 / 링크된 이슈 확인**: 하위 이슈 중 `issuetype.name`이 에픽인 것이 있으면 서브 에픽 목록을 표시하고 개별 처리 여부를 확인. `jira_get_issue` 응답의 `issuelinks` 필드에서 링크된 이슈를 확인하고, FE 관련 링크 이슈가 있으면 안내.
- **description 길이 확인**: description의 Markdown 원문이 3000자 초과 시 (AI 컨텍스트 효율을 위한 기준) Step 2에서 `##` 섹션 헤더 목차를 먼저 출력하고, 사용자에게 FE 관련 섹션을 지정받아 해당 부분만 상세 분류하는 옵션을 제공. 전체 분류도 선택 가능.

---

## Step 2: AI 분류 — 프론트엔드 작업 추출

에픽 description을 파싱하여 섹션별 파트를 분류합니다.

> 분류 기준표, 섹션 타입 정의, 분류 로직, 인터랙션 세분화 규칙, Figma URL 매핑 알고리즘은 `references/classification-rules.md` 참조.

### 분류 결과 출력 형식

```
## 프론트엔드 작업 분류 결과

### 화면 1: {화면명} ✅ 확실
- 관련 섹션: {섹션 헤더}
- 분류 근거: FE 키워드 {N}개 ({키워드1}, {키워드2}, ...) / 타파트 키워드 0개

**인터랙션(F) — 세부:**

| ID | 요소 | 액션 | 결과 | 비고 |
|---|---|---|---|---|
| F-01 | {요소} | {액션} | {결과} | |
| F-02 | {요소} | {액션} | {결과} | User Journey 단계 N |

**정책(P):**
| ID | 정책 내용 | 적용 조건 |
|---|---|---|
| P-01 | {정책} | {조건} |

**Validation (FE):**
| ID | 대상 | 규칙 | 에러 메시지 |
|---|---|---|---|
| v_xxx | {대상} | {규칙} | {메시지} |

- Figma UI: {URL 또는 "없음 — 직접 입력 필요"}
- Figma Description: {URL 또는 "없음"}

### 화면 2: {화면명} ⚠️ 검토 권장
  └─ 이유: {SDK 키워드와 FE 키워드가 동일 섹션에 혼재 등}
  └─ 분류 근거: FE 키워드 {N}개 ({목록}) / SDK 키워드 {M}개 ({목록})
- (동일 형식)

---

### User Stories (PRD 매핑 소스)
- US-01, US-02 → 화면 1 관련
- US-07, US-08 → 화면 2 관련

### 제외된 섹션 (비-Frontend)
- {섹션명} → {파트명} 영역
```

---

## Step 3: 사용자 확인

분류 결과를 출력한 후 확인을 받습니다.

**⚠️ 검토 권장 화면이 있는 경우**: 해당 화면을 먼저 강조하고, 사용자가 포함/제외를 명시적으로 결정하도록 안내합니다.

**생성 모드** (기존 FE 티켓 없음):

```
위 분류로 프론트엔드 하위 티켓을 생성할까요?

[y] 확정 — PRD 작성 후 Jira 티켓 생성
[m] 화면 합치기 — 어떤 화면을 합칠지 알려주세요
[s] 화면 더 쪼개기 — 어떤 화면을 어떻게 분리할지 알려주세요
[a] 섹션 추가/제거 — 포함하거나 제외할 섹션을 알려주세요
[r] 전체 재분류 — 처음부터 다시 분류합니다
```

**수정 모드** (기존 FE 티켓 있음):

기존 FE 티켓 목록과 분류된 화면을 매핑하여 표시합니다:

```
기존 프론트엔드 티켓이 발견되었습니다. 새로 생성하지 않고 기존 티켓을 업데이트합니다.

매핑 결과:
  - {KEY-1} "[프론트엔드] {화면명1}" → 분류된 화면 1과 매핑
  - {KEY-2} "[프론트엔드] {화면명2}" → 분류된 화면 2와 매핑
  - (신규) {화면명3} → 기존 티켓 없음, 신규 생성 예정

위 매핑으로 PRD를 업데이트할까요?

[y] 확정 — 기존 티켓 PRD 업데이트 (+ 신규 티켓 생성)
[d] 변경점 보기 — 기존 PRD와 신규 PRD의 주요 차이점 요약 표시
[m] 매핑 수정 — 어떤 화면을 어떤 티켓에 매핑할지 알려주세요
[r] 전체 재분류 — 처음부터 다시 분류합니다
```

매핑 기준:
- 기존 티켓 summary에서 화면명 추출 후 분류 결과와 부분 문자열 매핑
- 1:1 매핑 불가 시 사용자에게 직접 지정 요청

수정 요청(`m`/`r`) 시 분류를 재조정하고 Step 3을 반복합니다.

**수정 모드 변경점 보기** (`[d]` 선택 시):
- 기존 티켓의 description을 `jira_get_issue`로 조회
- 기존 description이 이 스킬의 PRD 양식인 경우: 섹션별로 변경점 비교 (추가/수정/삭제된 US, Validation Rule, IF/THEN 조건 등)
- 기존 description이 자유 텍스트 또는 다른 양식인 경우: "기존 description은 PRD 양식이 아니므로 전체 교체됩니다"라고 안내하고, 기존 내용 요약을 표시
- 변경점 확인 후 `[y]` 확정 또는 `[m]` 매핑 수정으로 진행

### 대규모 에픽 (화면 8개 이상)

화면이 8개 이상으로 분류된 경우 (사용자 검토 부담 경감 + Jira API rate limit 방지):
- 배치 분할 제안: "화면이 {N}개입니다. 4개씩 나눠서 진행할까요?"
- 사용자가 `[y]` 시 4개 단위로 PRD 작성 → 티켓 생성 → 다음 배치 확인 반복
- Jira 티켓 생성 시 1~2초 간격으로 호출 (rate limit 방지)
- Step 5.5 figma-jira-prd 체이닝도 배치 단위로 사용자 확인
- 사용자가 배치 분할을 거부하면 전체를 한번에 진행

---

## Step 4: 화면별 PRD 작성

확인된 각 화면에 대해 PRD를 작성합니다.

> PRD 양식과 자체 검증 체크리스트는 `references/prd-template.md` 참조.
> 이 양식은 figma-jira-prd의 PRD 구조(섹션 1~8)와 번호를 일치시켰으므로,
> Step 5.5 Figma 보강 시 섹션 매핑이 깨지지 않습니다.

---

## Step 5: Jira 하위 티켓 생성

### 이슈 타입 결정

- Step 1에서 기존 하위 이슈가 있었다면 → 그 `issue_type.name`을 그대로 사용
- 기존 하위 이슈가 없다면 → `mcp-atlassian-*:jira_get_project`로 프로젝트 이슈 타입 조회 후:
  - `작업` 존재 → `작업` 사용
  - `작업` 없음 → 사용 가능한 이슈 타입 목록을 사용자에게 제시하고 선택 요청

### 티켓 생성 또는 업데이트

**생성 모드** — 화면별로 순차 생성합니다:

```
mcp-atlassian-*:jira_create_issue(
  project_key: "{PROJECT_KEY}",          // 에픽 이슈 키에서 자동 추출 (예: AX-65 → AX)
  summary: "{PREFIX} {화면명} — {feature_id}",   // PREFIX: Step 1 감지 결과
  issue_type: "{결정된 이슈 타입}",
  description: "{Step 4 PRD (Markdown)}",
  additional_fields: "{\"parent\": \"{EPIC_KEY}\"}"  // 문자열로 전달 — 객체 형식 사용 금지
)
```

> **주의**: `additional_fields`의 `parent` 값은 반드시 **문자열**로 전달해야 합니다.
> 올바른 형식: `{"parent": "AX-65"}`
> 잘못된 형식: `{"parent": {"key": "AX-65"}}` ← API 오류 발생

**수정 모드** — 기존 FE 티켓이 있으면 `jira_create_issue` 대신 `jira_update_issue`로 PRD를 덮어씁니다:

```
mcp-atlassian-*:jira_update_issue(
  issue_key: "{EXISTING_KEY}",           // Step 3 매핑에서 확정된 기존 티켓 키
  description: "{Step 4 PRD (Markdown)}" // PRD 전체 덮어쓰기
)
```

- 매핑된 기존 티켓 → `jira_update_issue`로 description 업데이트
- 매핑되지 않은 신규 화면 → `jira_create_issue`로 신규 생성
- summary는 변경하지 않음 (기존 티켓명 유지)

**Summary 네이밍 컨벤션:**
- `{PREFIX} {화면명} — {feature_id}`
- 예 (한국어 컨벤션): `[프론트엔드] 광고 상품 등록 페이지 (CREATE) — FT-26-05`
- 예 (영어 컨벤션): `[FE] 광고 상품 등록 페이지 (CREATE) — FT-26-05`
- `feature_id` 추출: 에픽 summary의 `[FT-xx-xx]` 패턴 → 없으면 에픽 이슈 키 사용 (예: `AX-65`)

**부분 실패 처리:**
- 티켓 생성 실패 시 에러 메시지를 기록하고 다음 화면 티켓 생성을 계속 진행한다
- 모든 생성 완료 후 Step 6 리포트에서 성공/실패를 분리하여 표시
- 실패한 티켓은 재시도 옵션 제공

---

## Step 5.5: figma-jira-prd 자동 체이닝

> **이 단계는 반드시 실제로 실행해야 합니다.** 리포트만 출력하고 건너뛰지 마세요.

생성 성공한 티켓 중 **Figma URL이 매핑된 티켓**에 한해 `figma-jira-prd` 스킬을 실제로 호출합니다.

### 보강 동작의 이해

figma-jira-prd는 Jira 티켓의 기존 description을 읽고 Figma 데이터를 분석하여 **PRD를 재작성**합니다.
이 과정에서 Step 5에서 업로드한 PRD가 figma-jira-prd 양식으로 **전면 교체**됩니다.
이것은 의도된 동작입니다 — Step 4의 PRD는 에픽 정보만으로 작성된 "시드(seed)"이고,
figma-jira-prd가 Figma UI/Description 노드 분석을 통해 더 정확한 필드 정의, 인터랙션, 상태 조건을 채웁니다.

양식 구조(섹션 1~8)는 `references/prd-template.md`와 figma-jira-prd가 일치하므로 정보 손실이 발생하지 않습니다.

| 조건 | 처리 |
|------|------|
| Figma UI URL 확인됨 | `figma-jira-prd` 스킬을 즉시 실행 |
| Figma URL이 `TODO` | 건너뜀 → Step 6 리포트에서 수동 실행 안내 |
| 티켓 생성 실패 | 건너뜀 |

### 실행 전 사용자 확인

Figma URL이 매핑된 티켓 수를 보여주고 확인을 받습니다:

```
Figma URL이 매핑된 티켓 {N}개에 대해 figma-jira-prd로 PRD를 보강할까요?
(보강 대상: {KEY-1}, {KEY-2}, ...)

참고: figma-jira-prd가 Figma 데이터를 분석하여 PRD를 재작성합니다.
기존 PRD의 구조(User Stories, IF/THEN 조건 등)는 유지되면서 Figma 상세가 추가됩니다.

[y] 진행
[n] 건너뜀 — 나중에 수동으로 실행
```

### 실행 방법

`[y]` 선택 시 각 티켓에 대해 Skill 도구를 사용하여 `figma-jira-prd` 스킬을 순차 호출합니다:

```
Skill(skill="figma-jira-prd", args="PRD 작성해서 바로 Jira에 올려줘 jira:{NEW_TICKET_JIRA_URL} ui:{figma_ui_url} description:{figma_desc_url}")
```

인자 형식:
- `바로 올려줘`: 사용자 확인 단계를 건너뛰고 PRD 작성 즉시 Jira 업로드. figma-jira-prd의 "기존 내용 보존" 정책보다 `바로 올려줘`가 우선하여, 기존 description을 읽은 뒤 Figma 데이터와 병합하여 전체 교체합니다.
- `jira:`: 새로 생성된 티켓의 Jira URL (`https://{instance}.atlassian.net/browse/{NEW_KEY}`)
- `ui:`: Figma UI 화면 URL
- `description:`: Figma Description URL (없으면 생략)

---

## Step 6: 완료 리포트

```
## 프론트엔드 티켓 생성 완료

에픽: {EPIC_KEY} — {에픽 summary}
prefix 컨벤션: {감지된 prefix} ([프론트엔드] 또는 [FE])

생성 성공:
  1. {NEW_KEY_1}: {PREFIX} {화면명1} → https://{instance}/browse/{NEW_KEY_1}
  2. {NEW_KEY_2}: {PREFIX} {화면명2} → https://{instance}/browse/{NEW_KEY_2}

생성 실패 (있을 경우):
  - {화면명3}: {에러 메시지} → [재시도] 원하시면 알려주세요

figma-jira-prd 자동 보강:
  - {NEW_KEY_1}: Figma 보강 완료 (PRD 재작성됨)
  - {NEW_KEY_2}: Figma 보강 완료 (PRD 재작성됨)
  - {NEW_KEY_3}: Figma URL 없음 — 수동 실행 필요
  - (건너뜀): 사용자 요청으로 생략

PRD 구성 (총):
  - User Stories: {합계}개 (AC 자동 생성: {N}개, TODO: {N}개)
  - IF/THEN 조건: {합계}개
  - Validation Rules: {합계}개
  - Figma 매핑: {성공}개 / {전체}개 (TODO: {N}개)

다음 단계:
  /branch-from-ticket {NEW_KEY_1}  → 브랜치 생성
  /figma-jira-prd {NEW_KEY_3}      → Figma URL이 TODO인 티켓 수동 보강
  /unit-test-gen {NEW_KEY_1}       → TDD 단위 테스트 작성
```

---

## 엣지 케이스

| 상황 | 처리 |
|------|------|
| 에픽이 아닌 이슈 입력 | 경고 출력 후 계속 진행 여부 확인 |
| 이미 `[FE]` / `[프론트엔드]` 하위 티켓 존재 | **수정 모드**로 전환 — 신규 생성 없이 기존 티켓 PRD를 `jira_update_issue`로 업데이트 |
| Frontend 섹션이 없음 | "프론트엔드 작업이 식별되지 않았습니다" 출력 |
| Figma URL이 에픽에 없음 | PRD에 `TODO: Figma URL 입력 필요` 표시, Step 5.5 건너뜀, `/figma-jira-prd`로 보강 안내 |
| 에픽 description이 비어있음 | summary만으로 1개 통합 티켓 생성 제안 |
| 에픽 description이 3000자 초과 | `##` 섹션 헤더 목차를 먼저 출력하고 FE 관련 섹션 지정 요청 (전체 분류도 선택 가능) |
| 이슈 타입 `작업` 없음 | `jira_get_project`로 사용 가능한 이슈 타입 조회 후 사용자 선택 |
| 프로젝트 키 다름 | 에픽 이슈 키에서 프로젝트 키 자동 추출 (예: AX-65 → AX) |
| `additional_fields` parent 오류 | 문자열 형식 `{"parent": "{EPIC_KEY}"}` 확인 후 재시도 |
| figma-jira-prd 실행 실패 | 에러 로그 출력, 해당 티켓만 건너뜀, 나머지 계속 진행 |
| 하위에 서브 에픽 존재 | 서브 에픽 목록을 표시하고 개별/통합 처리 여부 확인 |
| 링크된 이슈 존재 | `issuelinks` 필드에서 확인 후 관련 FE 작업 여부 안내 |
| 화면 8개 이상 (대규모 에픽) | 4개씩 배치 분할 제안, Jira API 호출 간 1~2초 간격 |
| 수정 모드에서 기존 PRD 확인 요청 | `[d]` 옵션으로 기존 vs 신규 PRD 변경점 요약 표시 |
| 수정 모드에서 기존 description이 비정형 | 전체 교체 안내 + 기존 내용 요약 표시 |
| 하위 이슈 50개 초과 | `jira_search` 페이지네이션으로 전체 수집 후 FE 감지 |
