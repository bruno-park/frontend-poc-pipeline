---
name: figma-jira-prd
description: "Figma UI 화면 + Figma Description 노드 + Jira 티켓을 분석해 AI-friendly PRD(Product Requirements Document)를 작성하고 Jira에 업로드합니다. Triggers: (1) 'PRD 작성해줘' + Figma URL, (2) Figma UI URL + Description URL + Jira URL 동시 제공, (3) '기능 요구사항 정리해줘', '유저 스토리 뽑아줘', '기능 정의서 작성', (4) 'prd', 'PRD', '기획서 작성'"
---

# Figma + Jira → PRD 자동 생성기

Figma **UI 화면 노드**와 **Description(기획 의도) 노드**를 각각 읽어,
User Stories + Functional Spec + AI-friendly 조건문으로 구성된 PRD를 작성하고 Jira 티켓에 업로드합니다.

---

## 사용 가이드 (How to Use)

### 최소 입력 (Jira URL만)
```
PRD 작성해줘

jira: https://wisebirds.atlassian.net/browse/WP-0000
```
→ Jira 티켓 내용만으로 PRD 초안 작성. Figma 정보 없이 TODO 항목 포함 출력.

---

### 기본 입력 (Figma 1개 + Jira)
```
PRD 작성해줘

jira: https://wisebirds.atlassian.net/browse/WP-0000
ui: https://www.figma.com/design/{fileKey}/...?node-id=0000-0000
```
→ UI 노드 1개 기준으로 PRD 작성. Description 정보는 TODO 처리.

---

### 풀 입력 (Figma 2개 + Jira) ← 권장
```
PRD 작성해줘

jira:        https://wisebirds.atlassian.net/browse/WP-0000
ui:          https://www.figma.com/design/{fileKey}/...?node-id=0000-0000
description: https://www.figma.com/design/{fileKey}/...?node-id=0000-0001
```
→ UI + Description 노드를 각각 분석해 가장 정확한 PRD 생성.

---

### 빠른 작업 옵션 (POC / 검토 생략)
```
PRD 작성해서 바로 Jira에 올려줘

jira:        https://wisebirds.atlassian.net/browse/WP-0000
ui:          https://www.figma.com/design/{fileKey}/...?node-id=0000-0000
description: https://www.figma.com/design/{fileKey}/...?node-id=0000-0001
```
→ 사용자 확인 단계 생략, 작성 즉시 Jira 업로드.

---

### 입력 키워드 정리

| 키 | 설명 | 필수 |
|---|---|---|
| `jira:` | Jira 티켓 URL | 권장 |
| `ui:` | Figma UI 화면 노드 URL | 권장 |
| `description:` | Figma 기획 의도/규칙 노드 URL | 선택 |
| `바로 올려줘` | 확인 단계 생략하고 즉시 업로드 | 선택 |

> **키 없이 URL만 붙여넣어도 됩니다.**
> URL이 2개면 자동으로 UI / Description 역할을 판단합니다.

---

## Trigger 조건

아래 중 하나라도 해당되면 이 스킬을 사용합니다:

- `PRD 작성`, `prd 만들어`, `기능 정의서`, `유저 스토리` + Figma URL 조합
- Figma URL이 **2개** 제공되고 하나는 UI, 하나는 Description으로 구분 가능한 경우
- Figma URL + Jira URL + "PRD" 또는 "기획" 키워드 조합
- `figma-to-jira-spec`보다 더 구조화된 요구사항 문서가 필요한 경우

> `figma-to-jira-spec`과의 차이:
> - 이 스킬은 **UI URL과 Description URL을 분리**하여 각각의 역할로 파싱합니다.
> - **User Story + Acceptance Criteria** 형식을 사용합니다.
> - **AI-friendly IF/THEN 조건문**으로 인터랙션을 기술합니다.
> - **Validation Rules**를 코드 블록으로 명시합니다.

---

## Step 0: 입력값 확인 (Template 출력)

**인자(URL)가 없거나 불완전하게 제공된 경우**, 아래 템플릿을 즉시 출력하고 입력을 기다립니다.
URL이 모두 포함된 경우 이 단계를 건너뛰고 Step 1로 진행합니다.

출력할 템플릿:

```
📋 PRD 작성할 URL을 붙여넣어 주세요

PRD 작성해줘  (← '바로 올려줘'로 변경 시 즉시 업로드)

https://wisebirds.atlassian.net/browse/WP-      ← Jira 티켓
https://www.figma.com/design/.../...?node-id=   ← Figma UI 화면 (선택)
https://www.figma.com/design/.../...?node-id=   ← Figma Description (선택)

💡 URL 순서/키 없이 그냥 붙여넣으면 자동으로 역할을 판단합니다.
```

---

## Step 1: 입력 파싱

### URL 자동 감지 규칙

입력에서 모든 URL을 추출한 후 도메인으로 역할을 자동 판단합니다. `jira:`, `ui:` 같은 키 없이 URL만 붙여넣어도 됩니다.

| URL 패턴 | 역할 |
|---|---|
| `atlassian.net/browse/` | Jira 티켓 → 이슈 키 추출 |
| `figma.com` (첫 번째) | Figma UI 화면 노드 |
| `figma.com` (두 번째) | Figma Description 노드 |

> Figma URL이 1개면 노드 내용을 먼저 확인해 UI / Description 역할을 판단합니다.
> `jira:`, `ui:`, `description:` 키가 있으면 키 우선, 없으면 순서 기준으로 자동 배정합니다.

### Figma URL → 파라미터 추출

```
URL: https://www.figma.com/design/{fileKey}/{name}?node-id={nodeId}
→ fileKey: URL 경로 두 번째 세그먼트
→ nodeId:  node-id 쿼리 파라미터 (예: 1308-6158 → "1308:6158")
```

### Jira 파싱 & MCP 도구 선택

```
URL: https://{instance}.atlassian.net/browse/{ISSUE_KEY}
→ wisebirds.atlassian.net → mcp-atlassian-nestads
→ heypoll.atlassian.net   → mcp-atlassian-heypoll
→ 판단 불가 시 사용자에게 확인
```

---

## Step 1.5: 브랜치 확인 및 자동 생성

Jira 이슈 키가 파싱된 후, **데이터 수집과 병렬로** 브랜치 존재 여부를 확인합니다.

```bash
# 로컬 및 리모트 브랜치에서 티켓 번호 검색
git branch -a | grep -i "{ISSUE_KEY}"
```

| 결과 | 처리 방법 |
|---|---|
| 브랜치 존재 | 브랜치명을 메모하고 다음 단계로 진행 |
| 브랜치 없음 | `branch-from-ticket` 스킬 호출하여 자동 생성 |
| git repo 아님 | 경고 출력 후 건너뜀 (PRD 작업은 계속 진행) |

브랜치가 없으면 `/branch-from-ticket {ISSUE_KEY}` 스킬을 실행합니다:
- 이슈 타입에 따라 prefix 결정 (`feature` / `fix` / `chore`)
- summary에서 영문 kebab-case suffix 생성
- 최종 브랜치명: `{prefix}/{suffix}-{ISSUE_KEY}` 형식으로 생성

> Step 2의 데이터 수집과 **동시에** 실행하여 시간을 절약합니다.

---

## Step 2: 병렬 데이터 수집 + spec-validator 정책 로드

아래 4가지를 **동시에** 호출합니다:

```
[병렬 실행]
1. mcp-atlassian-*:jira_get_issue
   issue_key: {ISSUE_KEY}
   fields: summary, description, issuetype, status, assignee, labels

2. Figma:get_design_context  ← UI 화면 노드
   fileKey: {fileKey}
   nodeId:  {UI_nodeId}
   clientFrameworks: unknown
   clientLanguages:  unknown

3. Figma:get_design_context  ← Description 노드
   fileKey: {fileKey}
   nodeId:  {DESC_nodeId}
   clientFrameworks: unknown
   clientLanguages:  unknown

4. spec-validator guide       ← 디스크립션 정책 컨텍스트 로드
   → 반환된 [F]/[P]/[Data] 정책 규칙을 Step 3 PRD 작성에 주입
```

Figma 결과가 너무 커서 파일로 저장되면 Bash로 핵심 노드명/텍스트만 추출합니다:
```bash
python3 -c "
import json, re
with open('{saved_file}') as f:
    data = json.load(f)
text = data[0]['text']
labels = re.findall(r'name=\"([^\"]+)\"', text)
seen = set()
for l in labels:
    if l not in seen:
        seen.add(l)
        print(l)
" | head -150
```

---

## Step 3: PRD 작성

### 작성 원칙

1. **UI 노드** → 섹션 구조, 필드 목록, 인터랙션 파악
2. **Description 노드** → 진입 조건, 정책 규칙, 연동 모달 파악. [F]/[P]/[Data] 태그 정책 준수
3. **Jira 티켓** → 화면 맥락, 담당자, 기존 내용 확인
4. **AI-friendly**: 조건은 IF/THEN/ELSE, Validation은 코드 블록으로 명시
5. **User Story**: As a / I want to / So that + Acceptance Criteria
6. **spec-validator 정책 준수**: Step 2에서 로드한 정책 기준으로 description 작성

### PRD 양식

```markdown
# PRD — {ISSUE_KEY}
## {화면명}

**버전:** v1.0 | **작성일:** {today}
**담당:** {assignee} | **상태:** {status}

### References
| 구분 | URL |
|---|---|
| UI 화면 (Figma) | {ui_figma_url} |
| Description (Figma) | {desc_figma_url} |
| Jira | {jira_url} |
| 에픽 (Jira) | {epic_url 또는 `-` (에픽 없는 경우)} |

> **이번 티켓 범위**: {이번 스프린트/티켓에서 구현하는 것}
> **이번 티켓 제외 범위**: {에픽의 다른 티켓에서 처리하는 것 — 명시적으로 나열}

---

## 1. 배경 및 목적

{이 기능이 무엇인지, 어떤 맥락에서 진입하는지 2-3문장}

---

## 2. 진입 조건

{어떤 사용자 액션 또는 상태에서 이 화면에 진입하는지}

---

## 3. 사용자 스토리 (User Stories)

\`\`\`
US-01. {스토리 제목}
As a {역할}
I want to {행동}
So that {목적}

Acceptance Criteria:
  - {조건 1}
  - {조건 2}
\`\`\`

---

## 4. 기능 정의서 (Functional Specification)

### 4-1. 섹션 구조

\`\`\`
{화면명}
├── [섹션 1] {섹션명}
├── [섹션 2] {섹션명}
└── ...
\`\`\`

### 4-2. 필드 정의 (섹션별)

> [R] = 읽기 전용 (disabled / 텍스트 표시)  [E] = 편집 가능

#### [섹션 N] {섹션명}

| 필드명 | 타입 | 편집 | 필수 | 기본값 | 제약 | 비고 |
|---|---|---|---|---|---|---|
| {필드} | {타입} | [E]/[R] | ✅/- | {기본값 또는 `-`} | {제약} | {비고} |

> **기본값 출처 표기 규칙**:
> - 서버에서 내려오는 값: `서버 기본값` 또는 API 응답 필드명 명시
> - 클라이언트에서 초기화: `useState 초기값: {값}` 또는 구체적인 값 (예: `#EDEDED`)
> - 없는 경우: `-`
>
> **파일/미디어 타입 필드** (VIDEO, IMAGE, FILE)는 반드시 업로드 방식을 비고에 명시:
> - 예: `multipart/form-data`, `pre-signed URL`, `직접 URL 입력`, `[TBD]`
>
> **조건부 상태 필드** (예: ADBADGE)는 기본 상태와 조건 변화 후 상태를 모두 명시합니다.
> 예: `[E] → [R] (리모트 무료 조건 충족 시)`

### 4-3. 상태 조건 (State Conditions)

\`\`\`
IF   {조건}
THEN {결과 상태/동작}
ELSE {대안 상태/동작} (해당되는 경우)
\`\`\`

### 4-4. 버튼 / 액션 정의

| 버튼 | 트리거 | 동작 | 모달 여부 |
|---|---|---|---|
| {버튼명} | {이벤트} | {결과} | 있음/없음 |

> **취소 버튼은 반드시 포함**해야 합니다. 미정인 경우 `[TBD]`로 표시.
> 예: `취소 | 클릭 | 딤드 + 확인 모달 → 목록 이동 | 있음`

### 4-5. 저장 후 플로우 (Post-Save Flow)

| 결과 | 동작 |
|---|---|
| 저장 성공 | {목록 이동 / 상세 페이지 이동 / 토스트 후 잔류} |
| 저장 실패 | {에러 메시지 표시 위치 및 방식} |

---

## 5. 유효성 검사 규칙 (Validation Rules)

> **모든 필드(필수/선택 포함)에 대해 Validation Rule을 정의합니다.**
> 별도 규칙 없는 선택 필드는 `CONSTRAINT: 없음`으로 명시합니다.

\`\`\`
RULE-01: {규칙명}
  FIELDS: {적용 필드}
  CONSTRAINT: {제약 조건}
  ACTION: {위반 시 동작 — 에러 메시지 텍스트 포함}
\`\`\`

---

## 6. 의존성 (Dependencies)

| 항목 | 내용 |
|---|---|
| {의존 항목} | {설명} |

> TBD 항목은 별도 표기: `[TBD] {미결 내용} — 결정 필요`

---

## 7. Implementation Hints (for /planner)

> 이 섹션은 /planner 커맨드가 컴포넌트 구조를 자동 생성할 때 사용합니다.

### 페이지 타입
- [ ] hasCreate — 등록 페이지 포함
- [ ] hasList — 목록 페이지 포함
- [ ] hasDetail — 조회/수정 페이지 포함
- [ ] isReadOnly — 편집 기능 없는 순수 조회 페이지

### Feature 디렉토리
- suggested-name: `{영문 kebab-case}` (예: `ad-product`, `video-feed`)
- route: `/{feature-name}/create` 또는 `/{feature-name}`

### URL State
- Needed: Yes / No
- 이유: {목록/검색 페이지이면 Yes, 등록/수정/상세이면 No}
- 파라미터: (Needed=Yes인 경우) `page`, `size`, `q`, `status` 등 열거

### 취소 동작
| 페이지 | 동작 | 모달 |
|---|---|---|
| {페이지명} | {목록 이동 / 이전 페이지 / 잔류} | 있음/없음 |

### 빈 상태 / 로딩 / 에러 UI
| 상태 | 존재 | 동작 |
|---|---|---|
| Loading | Yes/No/TBD | {스피너 / 스켈레톤 / 없음} |
| Empty | Yes/No/N-A | {빈 상태 메시지} |
| Error | Yes/No/TBD | {에러 화면 또는 토스트} |

### API Hints
| 엔드포인트 | 메서드 | 용도 | 비고 |
|---|---|---|---|
| {/api/v1/...} | GET/POST/PUT/DELETE | {용도} | {TBD 여부} |

---

## 8. spec-validator 검증 결과

> Step 4에서 자동 실행된 spec-validator 결과를 여기에 기록합니다.

**검증 기준**: [F]/[P]/[Data] 태그 정책 (내장 규칙 v17 또는 최신 Confluence 버전)

| 항목 | 결과 | 비고 |
|---|---|---|
| 구조 | 통과/오류 | {2컬럼 또는 4컬럼 인식 여부} |
| [F] 형식 | 통과/경고 | {위반 항목} |
| [P] 형식 | 통과/경고 | {위반 항목} |
| [Data] 구조 | 통과/오류 | {위반 항목} |
| setup 태그 금지 | 통과/오류 | {위반 항목} |
| 전체 | **통과/오류/경고** | {요약} |
```

---

## Step 4: spec-validator 자동 검증

PRD 작성 완료 후, **Figma Description 노드에서 추출한 디스크립션 테이블**을 자동 검증합니다.

```
Tool: /spec-validator validate
Input: Figma Description 노드에서 추출한 no/title/setup/rules 테이블
```

### 검증 결과 처리

| 결과 | 처리 방법 |
|---|---|
| 모두 통과 | PRD 섹션 8에 "전체 통과" 기록, Step 5로 진행 |
| 경고 발생 | PRD 섹션 8에 경고 항목 기록, 사용자에게 알림 후 진행 |
| 오류 발생 | PRD 섹션 8에 오류 항목 기록, 오류 내용과 수정 제안 출력 후 사용자 확인 |

> Figma Description 노드가 없는 경우 이 단계를 건너뜁니다.

---

## Step 5: PRD 자체 검증 (Quality Gate)

```
[ ] Figma UI URL과 Description URL이 References에 각각 명시되어 있는가?
[ ] User Story가 최소 1개 이상, Acceptance Criteria가 각 스토리에 있는가?
[ ] 필드 정의 테이블에 [R]/[E] 편집 구분이 모든 필드에 명시되어 있는가?
[ ] 조건부 필드(예: disable 조건 있는 필드)의 기본 상태와 조건 후 상태가 모두 명시되어 있는가?
[ ] 상태 변경 인터랙션이 IF/THEN/ELSE 형식으로 기술되어 있는가?
[ ] 취소 버튼 동작(모달 여부, 이동 대상)이 4-4에 명시되어 있는가?
[ ] 저장 성공/실패 후 플로우(4-5)가 명시되어 있는가?
[ ] 모든 필드에 대한 Validation Rule이 있는가? (선택 필드는 "없음"으로라도 명시)
[ ] Validation Rules의 에러 메시지 텍스트가 구체적으로 기재되어 있는가?
[ ] 의존 모달/페이지가 Dependencies에 기재되어 있는가?
[ ] TBD 항목이 있는 경우 Dependencies에 "[TBD]"로 명시되어 있는가?
[ ] 섹션 7 Implementation Hints에 페이지 타입, feature 디렉토리명, URL State 여부가 채워져 있는가?
[ ] 섹션 7 API Hints에 엔드포인트가 최소 1개 이상 명시되어 있는가?
[ ] 섹션 8 spec-validator 검증 결과가 기록되어 있는가?
[ ] AI가 조건만 읽고 구현 가능할 수준으로 모호한 표현이 없는가?
```

미충족 항목이 있으면 보완 후 재검증합니다.

> **TBD 항목이 3개 이상인 경우** 사용자에게 알림:
> "미결 항목이 {N}개 있습니다. PRD를 업로드하시겠습니까? (TBD 항목은 개발 착수 전 확인 필요)"

---

## Step 6: 사용자 확인

`바로 올려줘` 옵션이 있으면 이 단계를 건너뜁니다.
그렇지 않으면 PRD 초안을 출력하고 수정 여부를 확인합니다.

---

## Step 7: Jira 티켓 업데이트

```
Tool: mcp-atlassian-*:jira_update_issue
  issue_key: {ISSUE_KEY}
  fields:
    description: {작성된 PRD (Markdown)}
```

기존 description이 있는 경우 기존 내용을 보존하고, 충돌 시 사용자에게 확인합니다.

---

## Step 8: 결과 보고

```
✅ PRD 업로드 완료: {Jira URL}

주요 구성:
- User Stories: {개수}개
- 섹션: {섹션명 목록}
- 핵심 인터랙션: {IF/THEN 조건 개수}개
- Validation Rules: {개수}개
- spec-validator: {통과/경고 N개/오류 N개}

🌿 브랜치: {브랜치명} (신규 생성 / 기존 사용)

🔲 TODO / TBD (미확인 항목): {있을 경우 목록}
```

---

## 엣지 케이스

| 상황 | 처리 방법 |
|---|---|
| Figma URL 1개만 제공 | 노드 역할 판단 후 가능한 범위에서 PRD 작성 |
| Jira URL 없음 | PRD만 작성하여 출력, 업로드 생략 |
| Figma 결과가 너무 큰 경우 | Bash로 라벨/텍스트 추출 후 구조 파악 |
| 기존 Jira description 존재 | 기존 내용 보존, 신규 정보만 보완 |
| Description 노드 정보 부족 | UI 노드에서 유추, TODO로 표시 |
| spec-validator 오류 발생 | 오류 내용을 섹션 8에 기록 + 수정 제안 출력, 사용자 확인 후 진행 |
| TBD 항목 3개 이상 | 업로드 전 사용자에게 확인 요청 |
| 취소 버튼 정책 미정 | `[TBD] 취소 동작 미결`로 표시 + Dependencies에 추가 |
| API 엔드포인트 미정 | API Hints에 `[TBD]`로 표시 |
