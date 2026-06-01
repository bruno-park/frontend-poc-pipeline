# Reference — 평범한 티켓 의미 기반 추출 (폴백)

> 본 문서는 `feature-planner` SKILL.md **Phase 1 Step 1B**에서 참조한다.
> Jira description이 `figma-jira-prd` 번호 섹션(4-1~7)을 **따르지 않는** 산문형 티켓일 때 사용한다.
> 번호 섹션이 있으면 [[prd-extraction.md]]의 고정밀 경로를 우선한다.

## 왜 필요한가

대부분의 실무 티켓은 `## 개요`, `## 작업 범위`, `## 수용 기준(AC)` 같은 **자유 형식 마크다운**으로 쓰인다. 번호 섹션 파서(Step 3c가 "Section 4-2 테이블"을 찾는 식)는 이런 티켓에서 빈손이 된다. 그러나 동일한 정보가 **표·체크박스 서술·팝업 흐름·AC 목록**의 형태로 거의 항상 존재한다. 이 폴백은 섹션 번호 대신 **의미**로 같은 `prd_context`를 채운다.

## 추출 매핑 (의미 → prd_context)

| 티켓에서 찾을 것 | 추출 대상 | 방법 |
|---|---|---|
| "추가 UI 항목" / 표(레이블·컨트롤·기본값) / "체크박스 N개" | `field_component_map` | 표 행·컨트롤 서술을 컴포넌트로 매핑 (체크박스→Checkbox, 입력→Input 등). 매핑 표는 [[prd-extraction.md]] Step 3c 공유 |
| "~할 때 …팝업/노출/disable/이동" 서술 | `state_conditions` | 조건→효과를 IF/THEN으로 재구성, type 분류는 Step 3d와 동일 |
| "확인 팝업" / "저장 시" / 취소·확인 버튼 | `actions` + `cancel_behavior` | mutation 여부·navigation 타입 분류 |
| "수용 기준(AC)" 불릿 목록 | `validation_rules` + AC 제약 | "필수/노출된다/반영된다" 문구 → 검증·렌더 규칙 |
| "선행 의존" / "관련 화면" / "API" | `dependencies` | 의존 티켓·화면·엔드포인트 |
| "TBD" / "미정" / "협의 필요" | `tbd_items` | 미결 항목 |

## page type 추론 (산문형)

title 키워드가 약하면 **본문**에서 보강한다:
- 본문에 "등록 화면"/"신규" → `hasCreate`
- "조회·수정 화면"/"저장된 값 반영" → `hasDetail` (+ 수정 가능 시 `hasCreate`)
- "목록"/"리스트"/"테이블" → `hasList`
- "팝업"/"모달"/"확인 팝업" → `hasModal`

`suggested-name`: title의 대괄호 태그·티켓번호 제거 후 핵심 명사구를 kebab-case로. parent(에픽) summary로 도메인 보조.

## Worked Example — WP-9137

**입력 (산문형, 번호 섹션 없음):**
- title: `[FE-Master] 계약사별 중복 인정 성과 허용 설정 — 운영 어드민 UI 구현`
- parent(에픽): `[운영사 어드민] 중복 인정 성과 계약사별 ON/OFF 설정`
- 본문: "## 개요 / ## 작업 범위(대상 화면: 계약사 등록·조회·수정, 추가 UI 항목 표) / ## 저장 시 확인 팝업 / ## 수용 기준(AC) 7개 / ## 관련 TC"

**추출 결과:**

```
page_type = { hasCreate: true, hasDetail: true, hasModal: true }   // "등록/조회·수정" + "확인 팝업"
suggested_name = "contract-duplicate-conversion"   // 대괄호·"설정/구현" 제거 + 에픽 도메인

field_component_map = [
  { field: "중복 인정 성과 허용", type: "CHECKBOX_GROUP", component: "CheckboxGroup",
    items: ["노출수","클릭수","동영상 재생"], required: false,
    constraint: "3개 독립 선택", note: "툴팁: 체크된 항목만 매체 어드민에서 선택 가능" },
]

state_conditions = [
  { condition: "신규 계약사 진입", effect: "전체 미체크 기본값", type: "conditional_render" },
  { condition: "기존 계약사 진입", effect: "저장된 값 반영", type: "conditional_render" },
  { condition: "OFF→ON 변경 후 저장", effect: "'중복 성과 허용합니다. 저장?' 확인 팝업", type: "validation_error" },
  { condition: "ON→OFF 변경 후 저장", effect: "'중복 성과 허용 안 함. 저장?' 확인 팝업", type: "validation_error" },
  { condition: "팝업 취소", effect: "변경 전 체크 상태로 복원, 저장 취소", type: "modal_close" },
  { condition: "팝업 확인", effect: "저장 완료", type: "submit_success" },
]

actions = [
  { button: "노출수/클릭수/동영상 재생 체크박스", trigger: "선택", behavior: "독립 토글", mutation: false, type: "ui_toggle" },
  { button: "저장", trigger: "클릭", behavior: "변경 있으면 확인 팝업→확인 시 저장", mutation: true, type: "submit" },
]
cancel_behavior = "확인 팝업 취소 → 변경 전 체크 상태 복원"

validation_rules = [   // AC에서 도출
  { id: "AC-01", field: "중복 인정 성과 허용", constraint: "등록/조회 화면에 항시 노출", message: "-" },
  { id: "AC-02", field: "체크박스 3종", constraint: "독립 선택 가능", message: "-" },
  { id: "AC-03", field: "신규 계약사", constraint: "기본값 전체 미체크", message: "-" },
  { id: "AC-04", field: "기존 계약사", constraint: "저장값 반영", message: "-" },
  { id: "AC-05", field: "저장", constraint: "변경 시 확인 팝업 노출", message: "-" },
  { id: "AC-06", field: "팝업 취소", constraint: "변경 전 복원 + 저장 취소", message: "-" },
  { id: "AC-07", field: "팝업 확인", constraint: "저장 완료", message: "-" },
]

dependencies = { related_screens: ["계약사 등록","계약사 조회·수정"], depends_on: ["WP-9136 (BE)"] }
tbd_items = []   // 없음
```

**산출 planner.md에 반영되는 것:** `CheckboxGroup`(3개) 컴포넌트 + 저장 시 확인 팝업 모달 state + 신규/기존 기본값 분기 conditional render + 취소 시 복원 로직 + AC 7개를 동작 제약으로.

**남는 한계 (planner.md에 명시할 것):** Figma URL 없음 → 레이아웃은 Phase 1.5 프로젝트 탐색으로 보강. 본문의 Confluence 기획 스펙 링크(`/wiki/.../pages/{PAGE_ID}`)는 Phase 1 Step 1B의 **Confluence 추적**으로 먼저 가져와 위 추출의 1차 소스로 사용한다.
