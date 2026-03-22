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

jira: https://{your-instance}.atlassian.net/browse/ISSUE-0000
```
→ Jira 티켓 내용만으로 PRD 초안 작성. Figma 정보 없이 TODO 항목 포함 출력.

---

### 기본 입력 (Figma 1개 + Jira)
```
PRD 작성해줘

jira: https://{your-instance}.atlassian.net/browse/ISSUE-0000
ui: https://www.figma.com/design/{fileKey}/...?node-id=0000-0000
```
→ UI 노드 1개 기준으로 PRD 작성. Description 정보는 TODO 처리.

---

### 풀 입력 (Figma 2개 + Jira) ← 권장
```
PRD 작성해줘

jira:        https://{your-instance}.atlassian.net/browse/ISSUE-0000
ui:          https://www.figma.com/design/{fileKey}/...?node-id=0000-0000
description: https://www.figma.com/design/{fileKey}/...?node-id=0000-0001
```
→ UI + Description 노드를 각각 분석해 가장 정확한 PRD 생성.

---

### 빠른 작업 옵션 (POC / 검토 생략)
```
PRD 작성해서 바로 Jira에 올려줘

jira:        https://{your-instance}.atlassian.net/browse/ISSUE-0000
ui:          https://www.figma.com/design/{fileKey}/...?node-id=0000-0000
description: https://www.figma.com/design/{fileKey}/...?node-id=0000-0001
```
→ 사용자 확인 단계 생략, 작성 즉시 Jira 업로드.

---

### enrich 모드 (epic-frontend-splitter 체이닝용)

`epic-frontend-splitter`에서 자동 호출될 때 사용합니다.

```
mode: --enrich
jira:        https://{your-instance}.atlassian.net/browse/ISSUE-0000
ui:          https://www.figma.com/design/{fileKey}/...?node-id=0000-0000
description: https://www.figma.com/design/{fileKey}/...?node-id=0000-0001
```

→ 기존 PRD 보존, Figma 데이터로 TODO 항목만 채움. 브랜치 생성/사용자 확인 건너뜀.

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

https://{your-instance}.atlassian.net/browse/      ← Jira 티켓
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
→ {your-instance}.atlassian.net → mcp-atlassian-{your-mcp-name}
→ {other-instance}.atlassian.net   → mcp-atlassian-{other-mcp-name}
→ 판단 불가 시 사용자에게 확인
```

---

## Step 1.5: 브랜치 확인 및 자동 생성

> **enrich 모드(`--enrich`)인 경우 이 단계를 건너뜁니다.**
> 브랜치는 `epic-frontend-splitter`에서 이미 생성되었거나 별도로 관리됩니다.

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

## Step 2: 병렬 데이터 수집

아래 3가지를 **동시에** 호출합니다:

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
2. **Description 노드** → 진입 조건, 정책 규칙, 연동 모달 파악
3. **Jira 티켓** → 화면 맥락, 담당자, 기존 내용 확인
4. **AI-friendly**: 조건은 IF/THEN/ELSE, Validation은 코드 블록으로 명시
5. **User Story**: As a / I want to / So that + Acceptance Criteria

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

#### [섹션 N] {섹션명}

| 필드명 | 타입 | 필수 | 제약 | 비고 |
|---|---|---|---|---|
| {필드} | {타입} | ✅/- | {제약} | {비고} |

### 4-3. 상태 조건 (State Conditions)

\`\`\`
IF   {조건}
THEN {결과 상태/동작}
\`\`\`

### 4-4. 버튼 / 액션 정의

| 버튼 | 트리거 | 동작 |
|---|---|---|
| {버튼명} | {이벤트} | {결과} |

---

## 5. 유효성 검사 규칙 (Validation Rules)

\`\`\`
RULE-01: {규칙명}
  FIELDS: {적용 필드}
  CONSTRAINT: {제약 조건}
  ACTION: {위반 시 동작}
\`\`\`

---

## 6. 의존성 (Dependencies)

| 항목 | 내용 |
|---|---|
| {의존 항목} | {설명} |
```

---

## Step 4: PRD 자체 검증 (Quality Gate)

```
[ ] Figma UI URL과 Description URL이 References에 각각 명시되어 있는가?
[ ] User Story가 최소 1개 이상, Acceptance Criteria가 각 스토리에 있는가?
[ ] 필수 필드(*)가 모두 필드 정의 테이블에 포함되어 있는가?
[ ] 상태 변경 인터랙션이 IF/THEN 형식으로 기술되어 있는가?
[ ] Validation Rules가 코드 블록으로 명시되어 있는가?
[ ] 의존 모달/페이지가 있다면 Dependencies에 기재되어 있는가?
[ ] AI가 조건만 읽고 구현 가능할 수준으로 모호한 표현이 없는가?
```

미충족 항목이 있으면 보완 후 재검증합니다.

---

## Step 5: 사용자 확인

> **enrich 모드(`--enrich`)인 경우 이 단계를 건너뜁니다.** 자동 체이닝 흐름을 끊지 않습니다.

`바로 올려줘` 옵션이 있으면 이 단계를 건너뜁니다.
그렇지 않으면 PRD 초안을 출력하고 수정 여부를 확인합니다.

---

## Step 6: Jira 티켓 업데이트

```
Tool: mcp-atlassian-*:jira_update_issue
  issue_key: {ISSUE_KEY}
  fields:
    description: {작성된 PRD (Markdown)}
```

**일반 모드**: 기존 description이 있는 경우 기존 내용을 보존하고, 충돌 시 사용자에게 확인합니다.

**enrich 모드 (`--enrich`)**: 사용자 확인 없이 아래 병합 전략을 적용합니다.
- 기존 PRD의 구조(섹션 순서, References)를 유지합니다
- `TODO:` 로 표시된 항목을 Figma 데이터로 채웁니다
- Figma에서 새로 파악된 필드/조건/Validation은 해당 섹션에 추가합니다
- 기존 에픽 기반 내용(User Story, AC, IF/THEN)은 Figma 데이터와 충돌하지 않는 한 그대로 보존합니다
- 충돌 항목(내용이 다른 경우) → 기존 내용을 유지하고 `[Figma 보강: {내용}]` 주석으로 병기합니다

---

## Step 7: 결과 보고

```
✅ PRD 업로드 완료: {Jira URL}

주요 구성:
- User Stories: {개수}개
- 섹션: {섹션명 목록}
- 핵심 인터랙션: {IF/THEN 조건 개수}개
- Validation Rules: {개수}개

🌿 브랜치: {브랜치명} (신규 생성 / 기존 사용)

🔲 TODO (미확인 항목): {있을 경우 목록}
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
