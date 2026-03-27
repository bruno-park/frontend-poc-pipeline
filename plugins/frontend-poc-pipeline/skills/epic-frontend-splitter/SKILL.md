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
- 다른 인스턴스 → 도메인 기반으로 판단, 불명확 시 사용자 확인

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

확인 항목:
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

---

## Step 2: AI 분류 — 프론트엔드 작업 추출

에픽 description을 파싱하여 섹션별 파트를 분류합니다.

### 파싱 우선순위 (3계층 폴백)

에픽 description 형식에 따라 순서대로 시도합니다:

1. `##` 헤더 존재 → **섹션 단위** 분류 (기본)
2. `##` 없고 `|` 표(table) 존재 → **행 단위** 키워드 스캔
3. 자유 텍스트 → **단락(`\n\n`) 단위** 분류

### 분류 기준표

| 파트 | 해당 키워드/패턴 |
|------|----------------|
| **Frontend** | 페이지, 모달, 폼, 버튼, 입력, 셀렉트, 토글, 탭, 유효성, 렌더링, 프리뷰, CREATE, MODAL, LIST, DETAIL, UI, 화면, 레이아웃 |
| **Backend** | API, DB, 테이블, 마이그레이션, 엔드포인트, 서버, 쿼리, 배치, 스키마 |
| **SDK** | SDK, 재생, 노출 감지, 자동재생, 음소거, 딤드, 피드형 재생, 팝업 모드, CALLBACK, IntersectionObserver |
| **Deliverer** | 전송, 딜리버러, 트래커, 배포, 게재 |

### 섹션 타입 분류

섹션은 내용 성격에 따라 5가지 타입으로 구분합니다:

| 타입 | 해당 섹션 패턴 | 처리 방식 |
|------|-------------|---------|
| **A — 단일 파트** | CREATE, MODAL, LIST 등 화면 단위 섹션 | 분류 기준표로 파트 판정 → 해당 파트 화면으로 할당 |
| **B — User Stories** | `사용자 스토리`, `User Stories` 섹션 | **분류 대상 제외** — 화면별 PRD 작성 시 US 번호 매핑 소스로만 활용 |
| **C — Validation Rules** | `유효성`, `Validation` 섹션 | FE 해당 항목만 추출 (아래 필터 기준 적용) |
| **D — 참고** | `TBD`, `관련 링크`, `Figma 기획서 참조`, `OVERVIEW`, `스펙 구성` | 화면 PRD의 Dependencies에 이관. References에는 포함하지 않음 |
| **E — User Journey** | `사용자 여정`, `User Journey`, `시나리오` 섹션 | PRD "2. 진입 조건" + "4-3. 상태 조건" 작성 소스로 활용. 시나리오 단계(단계→액션→시스템 응답)를 IF/THEN으로 변환 |

**Validation Rules FE 필터 기준:**

포함 (Frontend):
- FIELDS가 UI 입력 요소인 경우 (텍스트 입력, 이미지, 셀렉트, 토글, 버튼)
- ACTION이 에러 메시지 표시 또는 포커스 이동인 경우
- 폼 저장/제출 시점의 클라이언트 유효성 검증

제외 (Backend):
- DB 중복 체크, 서버 권한 검증, 데이터 정합성 규칙
- 서버에서만 판단 가능한 조건

### 분류 로직

1. 3계층 파싱으로 섹션 분할
2. 각 섹션의 타입 판별 (A/B/C/D/E)
3. **[C2] 헤더 파트명 우선 규칙**: 섹션 헤더에 `SDK`, `Backend`, `Deliverer`, `Android`, `iOS`, `Web SDK` 키워드가 명시된 경우 → 해당 파트로 **즉시 분류** (키워드 카운팅 무시)
4. 타입 A — 헤더 우선 판정 이후: 키워드 60% 이상 다수 파트 → 해당 파트; 60% 미만 → ⚠️ 검토 권장
5. 타입 B: 분류 제외, US 번호 목록만 기록. 여러 화면에 걸치는 US → 관련 화면 모두에 포함 (화면별 스코핑 명시)
6. 타입 C: FE 필터 기준으로 항목 추출
7. 타입 D: 참고 정보로 분리 보관
8. 타입 E: 시나리오의 단계별 액션을 IF/THEN 상태 조건으로 변환
9. `###` 서브 섹션은 부모 `##` 섹션 타입에 포함하여 함께 분류
10. `영향 파트` 테이블이 있으면 참고하되, 실제 섹션 내용 우선

### Figma URL 자동 매핑 — 3단계 알고리즘

에픽의 `Figma 기획서 참조` 테이블에서 FE 화면에 Figma URL을 할당합니다:

1. **정확 일치**: Figma 테이블 `화면명` 컬럼과 분류된 FE 화면명이 완전히 일치하는 경우 → 자동 할당
2. **부분 문자열 포함**: 화면명이 Figma 테이블 항목에 포함(substring)되거나 그 반대인 경우 → 자동 할당 (대소문자 무시)
3. **0개 또는 2개 이상 매칭**: 자동 할당 불가 → PRD에 `TODO: Figma URL 확인 필요` 표시하고 사용자에게 안내

OVERVIEW, 스펙 구성 등 화면 단위가 아닌 Figma 항목은 자동 매핑 대상에서 제외합니다. References에는 포함하지 않습니다.

### 분류 신뢰도 판정

각 화면 분류에 신뢰도를 표시합니다:

| 신뢰도 | 조건 | 표시 |
|--------|------|------|
| 확실 | Frontend 키워드 3개 이상, 다른 파트 키워드 없음 | ✅ 확실 |
| 검토 권장 | Frontend + 타 파트 키워드 혼재, 또는 키워드 2개 이하 | ⚠️ 검토 권장 |

### 인터랙션 세분화 규칙

에픽의 F(인터랙션) 테이블만으로는 구현에 필요한 상세가 부족할 수 있다.
다음 소스를 **크로스 매핑**하여 인터랙션을 확장한다:

| 소스 | 확장 방법 | 예시 |
|------|---------|------|
| **P 정책 테이블** | 정책이 기존 F 인터랙션의 동작에 영향을 주면 해당 인터랙션 결과에 정책 내용을 병기 | P-xx "조건 충족 시 항목 disable" → 해당 F 인터랙션 결과에 조건부 disable 동작 추가 |
| **User Journey** | 시나리오 단계 중 에픽 F 테이블에 없는 UI 액션이 명시된 항목만 인터랙션으로 추가 | 시나리오 단계 "최종 저장 → 완료" (에픽 F에 없음) → 신규 F-xx로 추가 |
| **Validation Rules** | 유효성 검증 트리거가 되는 UI 액션이 에픽 F에 이미 있으면 결과에 병기, 없으면 추가 | v_required_xxx → 에픽 F의 저장 인터랙션 결과에 "에러 메시지 표시" 병기 |

> **주의**: Data 필드 테이블은 인터랙션으로 확장하지 않는다. Data 필드는 `4-3. 필드 정의` 테이블에만 기술한다.

**인터랙션 테이블 컬럼:**

| ID | 요소 | 액션 | 결과 | 비고 |
|---|---|---|---|---|
| F-{NN} | {UI 요소명} | {사용자 액션} | {시스템 반응} | {출처: 에픽 F 원본 / User Journey 단계 N} |

### 분류 결과 출력 형식

```
## 프론트엔드 작업 분류 결과

### 화면 1: {화면명} ✅ 확실
- 관련 섹션: {섹션 헤더}

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
[m] 매핑 수정 — 어떤 화면을 어떤 티켓에 매핑할지 알려주세요
[r] 전체 재분류 — 처음부터 다시 분류합니다
```

매핑 기준:
- 기존 티켓 summary에서 화면명 추출 후 분류 결과와 부분 문자열 매핑
- 1:1 매핑 불가 시 사용자에게 직접 지정 요청

수정 요청(`m`/`r`) 시 분류를 재조정하고 Step 3을 반복합니다.

**⚠️ 검토 권장 화면이 있는 경우**: Step 3에서 해당 화면을 먼저 강조하고, 사용자가 포함/제외를 명시적으로 결정하도록 안내합니다.

---

## Step 4: 화면별 PRD 작성

확인된 각 화면에 대해 아래 양식으로 PRD를 작성합니다.

```markdown
# PRD — {EPIC_KEY} / {화면명}

**버전:** v1.0 | **작성일:** {today}
**에픽:** [{EPIC_KEY}] {에픽 summary}

### References
| 구분 | URL |
|---|---|
| 에픽 (Jira) | {epic_jira_url} |
| UI 화면 (Figma) | {figma_ui_url 또는 TODO: Figma URL 확인 필요} |
| Description (Figma) | {figma_desc_url 또는 TODO: Figma URL 확인 필요} |

---

## 1. 배경 및 목적

{에픽 배경에서 이 화면과 관련된 부분 추출 — 2~3문장}

---

## 2. 진입 조건

{이 화면에 진입하는 사용자 액션 또는 시스템 상태 — 타입 E 시나리오에서 추출}

---

## 3. 사용자 스토리 (User Stories)

US-{N}. {스토리 제목}  ← 이 화면에 해당하는 US만 포함 (여러 화면 걸치는 US는 화면별 스코프 명시)
As a {역할}
I want to {행동}
So that {목적}

Acceptance Criteria:
  - {조건 1}  ← 에픽 AC가 있으면 그대로 사용
  - {조건 2}  ← 에픽 AC가 없으면 이 화면의 F(인터랙션)/P(정책) 테이블에서 자동 생성
              ← 생성 불가 시: "TODO: AC 작성 필요"

> **AC 자동 생성 규칙**: 에픽 US에 AC가 없는 경우, 해당 화면의 `F-xx` 인터랙션과 `P-xx` 정책 항목을 기반으로 AC를 도출한다.
> 예: F-03 "프리뷰 토글 전환 → 셀렉트박스 활성" → AC: "프리뷰 사용 선택 시 일시정지 시간 셀렉트박스가 활성화된다"

---

## 4. 기능 정의서 (Functional Specification)

### 4-1. 섹션 구조

{화면명}
├── [섹션 1] {섹션명}
├── [섹션 2] {섹션명}
└── ...

### 4-2. 인터랙션 정의

> 에픽의 F(인터랙션) 원본을 기반으로, P(정책)은 결과에 병기하고, User Journey에서 에픽 F에 없는 UI 액션만 추가한다.

| ID | 요소 | 액션 | 결과 | 비고 |
|---|---|---|---|---|
| F-{NN} | {UI 요소명} | {사용자 액션} | {시스템 반응} | {출처: 에픽 F 원본 / User Journey 단계 N} |

### 4-3. 필드 정의

| 필드명 | 타입 | 필수 | 제약 | 비고 |
|--------|------|------|------|------|
| {필드} | {타입} | Y/N | {제약} | {비고} |

### 4-4. 상태 조건 (State Conditions)

IF   {조건}
THEN {결과 상태/동작}
ELSE {대안 동작 — 해당 시}

### 4-5. 버튼 / 액션 정의

| 버튼명 | 트리거 | 동작 |
|--------|--------|------|
| {버튼} | {이벤트} | {결과} |

---

## 5. 유효성 검사 규칙 (Validation Rules)

RULE-01: {규칙명}
  FIELDS: {적용 필드}
  CONSTRAINT: {제약 조건}
  ACTION: {위반 시 동작 — 에러 메시지, 포커스 이동 등}

---

## 6. 의존성 (Dependencies)

| 항목 | 내용 |
|------|------|
| 연관 화면 | {모달, 페이지 등} |
| API | {연동 API 목록 — 있으면} |
| TBD | {미결 항목} |
```

### PRD 자체 검증 체크리스트

PRD 작성 후 다음을 확인하고, 미통과 항목은 수정 후 진행합니다:

```
[ ] 에픽 URL이 References에 포함되어 있는가?
[ ] User Story가 최소 1개 이상이고 Acceptance Criteria가 있는가?
[ ] 인터랙션 정의 테이블에 Data 필드, 정책, User Journey가 크로스 매핑되어 있는가?
[ ] 필드 정의 테이블에 필수 필드가 모두 포함되어 있는가?
[ ] 상태 변경이 IF/THEN 형식으로 기술되어 있는가?
[ ] Validation Rules가 코드 블록으로 명시되어 있는가?
[ ] AI가 조건만 읽고 구현 가능한 수준으로 모호한 표현이 없는가?
```

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

> ⚠️ **주의**: `additional_fields`의 `parent` 값은 반드시 **문자열**로 전달해야 합니다.
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

> ⚠️ **이 단계는 반드시 실제로 실행해야 합니다.** 리포트만 출력하고 건너뛰지 마세요.

생성 성공한 티켓 중 **Figma URL이 매핑된 티켓**에 한해 `figma-jira-prd` 스킬을 실제로 호출합니다.

| 조건 | 처리 |
|------|------|
| Figma UI URL 확인됨 | `figma-jira-prd` 스킬을 `--enrich` 모드로 즉시 실행 |
| Figma URL이 `TODO` | 건너뜀 → Step 6 리포트에서 수동 실행 안내 |
| 티켓 생성 실패 | 건너뜀 |

### 실행 전 사용자 확인

Figma URL이 매핑된 티켓 수를 보여주고 확인을 받습니다:

```
Figma URL이 매핑된 티켓 {N}개에 대해 figma-jira-prd로 PRD를 자동 보강할까요?
(보강 대상: {KEY-1}, {KEY-2}, ...)

[y] 진행
[n] 건너뜀 — 나중에 수동으로 실행
```

### 실행 방법

`[y]` 선택 시 각 티켓에 대해 Skill 도구를 사용하여 `figma-jira-prd` 스킬을 순차 호출합니다:

```
Skill("figma-jira-prd", args="--enrich {NEW_TICKET_JIRA_URL} ui:{figma_ui_url} desc:{figma_desc_url}")
```

인자 형식:
- `--enrich`: 브랜치 생성, 사용자 확인 단계를 건너뛰고 기존 PRD의 TODO 항목을 Figma 데이터로 채움
- Jira URL: `https://{instance}.atlassian.net/browse/{NEW_KEY}`
- `ui:`: Figma UI 화면 URL
- `desc:`: Figma Description URL (없으면 생략)

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
  - {NEW_KEY_1}: Figma 보강 완료 (TODO {N}개 채움)
  - {NEW_KEY_2}: Figma 보강 완료 (TODO {N}개 채움)
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
| 이슈 타입 `작업` 없음 | `jira_get_project`로 사용 가능한 이슈 타입 조회 후 사용자 선택 |
| 프로젝트 키 다름 | 에픽 이슈 키에서 프로젝트 키 자동 추출 (예: AX-65 → AX) |
| `additional_fields` parent 오류 | 문자열 형식 `{"parent": "{EPIC_KEY}"}` 확인 후 재시도 |
| figma-jira-prd --enrich 실패 | 에러 로그 출력, 해당 티켓만 건너뜀, 나머지 계속 진행 |
