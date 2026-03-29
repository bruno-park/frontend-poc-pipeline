# PRD 양식 — Epic Frontend Splitter

확인된 각 화면에 대해 아래 양식으로 PRD를 작성합니다.

> **figma-jira-prd 양식과의 관계**: 이 양식은 figma-jira-prd의 PRD 구조와 섹션 번호를 의도적으로 일치시켰습니다.
> Step 5.5에서 figma-jira-prd가 Figma 데이터로 보강할 때 섹션 매핑이 깨지지 않도록 하기 위함입니다.
> figma-jira-prd에만 있는 섹션(7. Implementation Hints, 8. spec-validator)은 Figma 보강 시 채워지므로,
> epic-frontend-splitter 단계에서는 빈 템플릿 또는 TODO로 남깁니다.

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

> **이번 티켓 범위**: {에픽 중 이 화면에서 구현하는 것}
> **이번 티켓 제외 범위**: {에픽의 다른 화면 티켓에서 처리하는 것 — 명시적으로 나열}

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

### 4-2. 필드 정의 (섹션별)

> [R] = 읽기 전용 (disabled / 텍스트 표시)  [E] = 편집 가능

#### [섹션 N] {섹션명}

| 필드명 | 타입 | 편집 | 필수 | 기본값 | 제약 | 비고 |
|---|---|---|---|---|---|---|
| {필드} | {타입} | [E]/[R] | Y/N | {기본값 또는 `-`} | {제약} | {비고} |

> **기본값 출처 표기 규칙**:
> - 서버에서 내려오는 값: `서버 기본값` 또는 API 응답 필드명 명시
> - 클라이언트에서 초기화: 구체적인 값 (예: `#EDEDED`)
> - 없는 경우: `-`
>
> **조건부 상태 필드**는 기본 상태와 조건 변화 후 상태를 모두 명시합니다.
> 예: `[E] → [R] (리모트 무료 조건 충족 시)`

### 4-3. 인터랙션 정의

> 에픽의 F(인터랙션) 원본을 기반으로, P(정책)은 결과에 병기하고, User Journey에서 에픽 F에 없는 UI 액션만 추가한다.

| ID | 요소 | 액션 | 결과 | 비고 |
|---|---|---|---|---|
| F-{NN} | {UI 요소명} | {사용자 액션} | {시스템 반응} | {출처: 에픽 F 원본 / User Journey 단계 N} |

### 4-4. 상태 조건 (State Conditions)

IF   {조건}
THEN {결과 상태/동작}
ELSE {대안 동작 — 해당 시}

### 4-5. 버튼 / 액션 정의

| 버튼명 | 트리거 | 동작 | 모달 여부 |
|---|---|---|---|
| {버튼} | {이벤트} | {결과} | 있음/없음 |

> **취소 버튼은 반드시 포함**해야 합니다. 미정인 경우 `[TBD]`로 표시.

### 4-6. 저장 후 플로우 (Post-Save Flow)

| 결과 | 동작 |
|---|---|
| 저장 성공 | {목록 이동 / 상세 페이지 이동 / 토스트 후 잔류} |
| 저장 실패 | {에러 메시지 표시 위치 및 방식} |

---

## 5. 유효성 검사 규칙 (Validation Rules)

> **모든 필드(필수/선택 포함)에 대해 Validation Rule을 정의합니다.**
> 별도 규칙 없는 선택 필드는 `CONSTRAINT: 없음`으로 명시합니다.

RULE-01: {규칙명}
  FIELDS: {적용 필드}
  CONSTRAINT: {제약 조건}
  ACTION: {위반 시 동작 — 에러 메시지 텍스트 포함}

---

## 6. 의존성 (Dependencies)

| 항목 | 내용 |
|------|------|
| 연관 화면 | {모달, 페이지 등} |
| API | {연동 API 목록 — 있으면} |
| TBD | {미결 항목 — `[TBD] {내용} — 결정 필요` 형식} |

---

## 7. Implementation Hints (for /planner)

> 이 섹션은 에픽 분류 단계에서 알 수 있는 범위만 채웁니다.
> Figma 보강(Step 5.5) 시 figma-jira-prd가 상세 내용을 추가합니다.

### 페이지 타입
- [ ] hasCreate — 등록 페이지 포함
- [ ] hasList — 목록 페이지 포함
- [ ] hasDetail — 조회/수정 페이지 포함
- [ ] isReadOnly — 편집 기능 없는 순수 조회 페이지

### Feature 디렉토리
- suggested-name: `{영문 kebab-case}` (예: `ad-product`)
- route: `/{feature-name}/create` 또는 `/{feature-name}`

### URL State
- Needed: Yes / No / TODO
- 파라미터: (Needed=Yes인 경우) `page`, `size`, `q`, `status` 등 열거

### 취소 동작
| 페이지 | 동작 | 모달 |
|---|---|---|
| {페이지명} | {목록 이동 / 이전 페이지 / 잔류} | 있음/없음/[TBD] |

### 빈 상태 / 로딩 / 에러 UI
| 상태 | 존재 | 동작 |
|---|---|---|
| Loading | Yes/No/TBD | {스피너 / 스켈레톤 / 없음} |
| Empty | Yes/No/N-A | {빈 상태 메시지} |
| Error | Yes/No/TBD | {에러 화면 또는 토스트} |

### API Hints
| 엔드포인트 | 메서드 | 용도 | 비고 |
|---|---|---|---|
| {/api/v1/... 또는 [TBD]} | GET/POST/PUT/DELETE | {용도} | {TBD 여부} |

---

## 8. spec-validator 검증 결과

> Figma 보강 전에는 이 섹션을 `TODO: Figma 보강 후 검증 예정`으로 남깁니다.
> figma-jira-prd Step 4에서 spec-validator 자동 검증 후 결과를 채웁니다.

| 항목 | 결과 | 비고 |
|---|---|---|
| 전체 | TODO | Figma 보강 후 검증 예정 |
```

## PRD 자체 검증 체크리스트

PRD 작성 후 다음을 확인하고, 미통과 항목은 수정 후 진행합니다:

```
[ ] 에픽 URL이 References에 포함되어 있는가?
[ ] 이번 티켓 범위 / 제외 범위가 명시되어 있는가?
[ ] User Story가 최소 1개 이상이고 Acceptance Criteria가 있는가?
[ ] 필드 정의 테이블에 [R]/[E] 편집 구분이 모든 필드에 명시되어 있는가?
[ ] 조건부 필드의 기본 상태와 조건 후 상태가 모두 명시되어 있는가?
[ ] 인터랙션 정의 테이블에 P(정책), User Journey가 크로스 매핑되어 있는가?
[ ] 상태 변경이 IF/THEN 형식으로 기술되어 있는가?
[ ] 취소 버튼 동작(모달 여부, 이동 대상)이 4-5에 명시되어 있는가?
[ ] 저장 성공/실패 후 플로우(4-6)가 명시되어 있는가?
[ ] 모든 필드에 대한 Validation Rule이 있는가? (선택 필드는 "없음"으로라도 명시)
[ ] Validation Rules의 에러 메시지 텍스트가 구체적으로 기재되어 있는가?
[ ] 의존 모달/페이지가 Dependencies에 기재되어 있는가?
[ ] TBD 항목이 있는 경우 Dependencies에 "[TBD]"로 명시되어 있는가?
[ ] 섹션 7 Implementation Hints에 페이지 타입, feature 디렉토리명이 채워져 있는가?
[ ] AI가 조건만 읽고 구현 가능한 수준으로 모호한 표현이 없는가?
```
