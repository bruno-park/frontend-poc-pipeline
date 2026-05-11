---
name: figma-prd-validator
description: "Figma UI 화면 노드에서 실제 설계 데이터를 추출하고, 작성된 PRD(Jira 또는 마크다운)와 비교해 누락·불일치·TBD 항목을 Gap Report로 출력합니다. Triggers: 'PRD 검증해줘', 'Figma랑 PRD 맞는지 확인해줘', 'figma prd 차이 확인', 'prd 누락 항목', '/figma-prd-validator'"
---

# Figma ↔ PRD 갭 검증기 (figma-prd-validator)

Figma UI 노드의 실제 설계 데이터와 PRD의 기술 내용을 비교해  
**누락 항목, 불일치, TBD 미결 항목**을 Gap Report로 출력합니다.

PRD 작성(`figma-jira-prd`) 직후 또는 개발 착수 전 품질 게이트로 사용합니다.

---

## 사용법

```
/figma-prd-validator

figma: https://www.figma.com/design/{fileKey}/...?node-id=0000-0000
jira:  https://wisebirds.atlassian.net/browse/WP-0000
```

| 키 | 설명 | 필수 |
|---|---|---|
| `figma:` | Figma UI 화면 노드 URL | 필수 |
| `jira:` | Jira 티켓 URL (description에서 PRD 읽기) | jira/prd 중 1개 필수 |
| `prd:` | PRD 마크다운 직접 붙여넣기 | jira/prd 중 1개 필수 |

### 빠른 실행 (PRD 재작성 없이 현재 Jira description 검증)
```
/figma-prd-validator

figma: https://www.figma.com/design/{fileKey}/...?node-id=0000-0000
jira:  https://wisebirds.atlassian.net/browse/WP-0000
```

---

## Step 0: 입력 확인

Figma URL 또는 PRD 소스(jira/prd) 중 하나라도 없으면 아래 템플릿 출력 후 대기:

```
📋 검증할 URL을 붙여넣어 주세요

https://www.figma.com/design/.../...?node-id=   ← Figma UI 화면 (필수)
https://wisebirds.atlassian.net/browse/WP-      ← Jira 티켓 (PRD 소스)
```

---

## Step 1: 입력 파싱

### URL 자동 감지
| URL 패턴 | 역할 |
|---|---|
| `figma.com` | Figma UI 노드 → fileKey + nodeId 추출 |
| `atlassian.net/browse/` | Jira 티켓 → MCP 선택 (wisebirds → nestads, heypoll → heypoll) |

### Figma URL 파라미터 추출
```
URL: https://www.figma.com/design/{fileKey}/{name}?node-id={nodeId}
→ fileKey: 경로 두 번째 세그먼트
→ nodeId:  node-id 파라미터 (1308-6158 → "1308:6158")
```

---

## Step 2: 병렬 데이터 수집

```
[병렬 실행]
1. Figma:get_design_context
   fileKey: {fileKey}
   nodeId:  {nodeId}

2. mcp-atlassian-*:jira_get_issue   (jira: 입력이 있는 경우)
   fields: description
```

Figma 결과가 너무 큰 경우 핵심 텍스트만 추출:
```bash
python3 -c "
import json, re, sys
data = json.load(sys.stdin)
text = data[0]['text'] if isinstance(data, list) else data.get('text', '')
# 노드명과 텍스트 라벨 추출
labels = re.findall(r'(?:name|characters)=\"([^\"]{1,80})\"', text)
seen = set()
for l in labels:
    l = l.strip()
    if l and l not in seen:
        seen.add(l)
        print(l)
" < {saved_file} | head -200
```

---

## Step 3: ScreenSpec 정규화

Figma 데이터와 PRD를 각각 **공통 스키마(ScreenSpec)**로 변환합니다.

```
ScreenSpec:
  sections:  string[]      # 섹션/구역명 목록
  columns:   string[]      # 테이블 컬럼명 (목록 화면)
  fields:    FieldEntry[]  # {name, editable}
  buttons:   string[]      # 버튼/CTA 라벨
  states:    string[]      # 상태 조건 트리거 키워드
```

### Figma → ScreenSpec 추출 기준
| ScreenSpec 항목 | Figma에서 찾는 패턴 |
|---|---|
| `sections` | 프레임/그룹 노드명, 섹션 헤더 텍스트 |
| `columns` | 테이블 헤더 행 텍스트 |
| `fields` | Input, Textarea, Select, Checkbox, Toggle 컴포넌트명/라벨 |
| `buttons` | Button, IconButton 컴포넌트의 라벨 텍스트 |
| `states` | Chip, Badge, Status 컴포넌트 텍스트; ON/OFF, 활성/비활성 등 |

### PRD → ScreenSpec 추출 기준
| ScreenSpec 항목 | PRD에서 찾는 위치 |
|---|---|
| `sections` | 섹션 4-1 구조 트리 텍스트 |
| `columns` | 섹션 4-2 테이블 필드명 컬럼 |
| `fields` | 섹션 4-2 테이블 전체 필드명 |
| `buttons` | 섹션 4-4 버튼 컬럼 |
| `states` | 섹션 4-3 IF 조건 트리거 |

---

## Step 4: 집합 diff 비교

각 카테고리별로 집합 차이를 계산합니다.

```
for category in [columns, fields, buttons, states]:
    figma_set = normalize(figmaSpec[category])   # 공백 제거, 소문자화
    prd_set   = normalize(prdSpec[category])

    missing_in_prd  = figma_set - prd_set        # Figma에만 있음
    extra_in_prd    = prd_set - figma_set         # PRD에만 있음
    matched         = figma_set & prd_set
```

### 정규화 규칙
- 공백 trim, 소문자 변환
- 괄호 내용 제거: `연결된 광고 상품 (아이콘)` → `연결된 광고 상품`
- 단위 제거: `25/page` → `25`

---

## Step 5: 시맨틱 해소 (Near-match 처리)

Step 4의 미매칭 항목 중 **표현 차이로 실제로는 같은 항목**을 식별합니다.

```
미매칭 예시 → 시맨틱 동일 판단:
  "ON/OFF"       ↔ "상태 토글"          → MATCH (상태 제어 컴포넌트)
  "Placement Code" ↔ "게재위치 코드"    → MATCH (동일 필드, 언어 차이)
  "다운로드"     ↔ "Download"           → MATCH (번역 차이)
  "등록 버튼"    ↔ "게재위치 등록"      → POSSIBLE MATCH (확인 필요)
```

| 판단 결과 | 처리 |
|---|---|
| MATCH | 일치 항목으로 이동 |
| POSSIBLE MATCH | 경고로 표시 (사용자 확인 요청) |
| NO MATCH | 갭 항목으로 확정 |

---

## Step 6: Gap Report 출력

```markdown
## Figma ↔ PRD Gap Report — {ISSUE_KEY}
**검증일:** {today} | **Figma:** {figma_url} | **PRD 소스:** Jira {issue_key}

---

### 📊 요약

| 카테고리 | Figma | PRD | 일치 | 누락 | 초과 |
|---|---|---|---|---|---|
| 테이블 컬럼 | N | N | N | N | N |
| 필드 | N | N | N | N | N |
| 버튼/CTA | N | N | N | N | N |
| 상태 조건 | N | N | N | N | N |
| **전체** | **N** | **N** | **N** | **N** | **N** |

**종합 판정:** ✅ 통과 / ⚠️ 경고 {N}개 / ❌ 오류 {N}개

---

### ✅ 일치 항목

<카테고리별 일치 목록>

---

### ❌ PRD에 누락된 항목 (Figma에 있으나 PRD에 없음)

> 이 항목들은 개발 착수 전 PRD에 추가되어야 합니다.

| 카테고리 | 항목 | 권장 추가 위치 |
|---|---|---|
| {카테고리} | {항목명} | PRD 섹션 {N} |

---

### ⚠️ PRD에만 있는 항목 (Figma에 없음)

> Figma 디자인에서 확인되지 않았습니다. 의도된 항목인지 확인이 필요합니다.

| 카테고리 | 항목 | 비고 |
|---|---|---|
| {카테고리} | {항목명} | {TBD 여부} |

---

### 🔲 TBD 미결 항목

PRD에 `[TBD]`로 표시된 항목 목록:

| 항목 | 위치 |
|---|---|
| {TBD 내용} | PRD 섹션 {N} |

---

### 💡 권장 액션

1. {누락 항목 N개} → PRD 섹션 {N}에 추가
2. {TBD 항목 N개} → 개발 착수 전 확인 필요
3. {초과 항목 N개} → Figma에 반영 여부 기획팀 확인
```

---

## Step 7: Jira 코멘트 등록 (선택)

`jira에 올려줘` 옵션이 있을 때만 실행합니다.

```
Tool: mcp-atlassian-*:jira_add_comment
  issue_key: {ISSUE_KEY}
  body: {Gap Report 전문}
```

---

## Quality Gate 판정 기준

| 판정 | 조건 |
|---|---|
| ✅ **통과** | 누락 항목 0개, TBD 2개 이하 |
| ⚠️ **경고** | 누락 항목 1-2개 또는 TBD 3개 이상 |
| ❌ **오류** | 누락 항목 3개 이상 또는 핵심 섹션 전체 누락 |

오류 판정 시 `figma-jira-prd` 스킬을 재실행해 PRD를 보완하도록 안내합니다.

---

## 엣지 케이스

| 상황 | 처리 |
|---|---|
| Figma 노드가 목록이 아닌 경우 (폼, 모달 등) | columns 카테고리 생략, fields 중심 비교 |
| PRD에 섹션 4-2, 4-4가 없는 경우 | 해당 카테고리 "PRD 미작성"으로 표시 |
| Figma 데이터 추출 실패 | 추출 가능한 카테고리만 비교, 나머지 TBD 표시 |
| 동일 라벨이 여러 섹션에 중복 | 중복 제거 후 비교 |
| PRD에 `[TBD]` 항목이 있는 경우 | 갭 판단 제외, TBD 섹션에 별도 분류 |
