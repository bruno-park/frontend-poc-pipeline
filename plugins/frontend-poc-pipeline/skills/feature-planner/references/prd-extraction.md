# Reference — 구조화된 PRD 추출 절차 (Step 3a~3g)

> 본 문서는 `feature-planner` SKILL.md **Phase 1 Step 1B**에서 참조한다.
> Jira description이 `figma-jira-prd` 양식(번호 섹션 4-1~7)일 때의 **고정밀 추출 경로**다.
> 번호 섹션이 없는 산문형 티켓은 [[plain-ticket-extraction.md]]를 따른다.

Section 7(Implementation Hints)이 존재하면 그것을 1차로 읽는다(`hasCreate`, `hasList`, `hasDetail`, `isReadOnly`, `suggested-name`, URL State, Cancel behavior, Empty/Loading/Error states, API Hints). 없으면 아래 절차를 순서대로 수행한다.

## Step 3a: Page type 추론 (복합 판단)

title 키워드 + Section 4 내용을 조합하여 page type flags를 결정한다.

**1차: title 키워드 매칭** (case-insensitive)
- `CREATE`/`등록` → `hasCreate: true`
- `LIST`/`목록` → `hasList: true`
- `DETAIL`/`상세` → `hasDetail: true`
- `EDIT`/`수정` → `hasCreate: true, hasDetail: true`

**2차: Section 4 기반 보정** (1차가 불확실할 때)
- 4-1 구조 트리에 `MODAL` → `hasModal: true`
- 4-2 필드 테이블에 필수(Y) 필드 존재 → `hasCreate: true` 보강
- 4-2 필드가 모두 읽기전용 → `hasDetail: true, isReadOnly: true`
- 4-4 버튼에 "저장" → `hasCreate: true` 확정
- 4-4 버튼에 "삭제" → `hasDelete: true`

## Step 3b: suggested-name 추론

```
1. title에서 prefix 제거: [프론트엔드]/[FE] 등 대괄호 태그, CREATE/LIST/DETAIL/EDIT, 티켓번호(— FT-XX-XX)
2. 남은 핵심 명사구를 영문 kebab-case로 변환
3. parent(에픽) summary에서 도메인 키워드 보조 확인
예: "[프론트엔드] CREATE 동영상 광고 상품 등록 — FT-26-05" → "video-ad-product"
```

## Step 3c: Section 4-2 필드 정의 → `prd_context.field_component_map`

| PRD 필드 타입 | 컴포넌트 패턴 | 비고 |
|---|---|---|
| `TEXT` | `Input` / `Textarea` | "여러 줄"/"설명" 있으면 Textarea |
| `IMAGE` | `ImageUpload` | Upload method TBD 표기 |
| `VIDEO` | `VideoUpload` | Upload method TBD 표기 |
| `FILE` | `FileUpload` | Upload method TBD 표기 |
| `ADBADGE` | `BadgeSelector` (custom) | 4-3에서 disable 조건 확인 |
| `CTA_BUTTON` | `ColorPicker` + `ButtonPreview` | 기본값 확인 |
| `SELECT`/`ENUM` | `Select` / `RadioGroup` | 옵션 목록 확인 |
| `CHECKBOX` | `Checkbox` | - |
| `DATE` | `DatePicker` | - |
| `NUMBER` | `NumberInput` | min/max 확인 |

각 필드 저장 예:
```
field_component_map = [
  { field: "광고상품명", type: "TEXT", component: "Input", required: true, constraint: "필수 입력", note: "v_required_adProductName" },
  { field: "_videoMediaSpec", type: "VIDEO", component: "VideoUpload", required: true, constraint: "동영상 소재(메인)", note: "D-01, Upload method TBD" },
]
```

## Step 3d: Section 4-3 상태 조건 → `prd_context.state_conditions`

IF/THEN 블록을 파싱해 `type`으로 분류한다.

```
state_conditions = [
  { condition: "광고 구분 선택", effect: "구분 탭 표시, 소재 항목 편집 활성화", type: "conditional_render" },
  { condition: "ADBADGE 리모트 무료", effect: "ADBADGE 항목 disable 유지", type: "field_disable" },
  { condition: "레이아웃 버튼 클릭", effect: "MODAL 레이아웃 설정 이동", type: "navigation" },
  { condition: "MODAL 저장 완료", effect: "설정값 저장, MODAL 닫힘, 복귀", type: "modal_close" },
  { condition: "필수 누락 상태 저장", effect: "유효성 검증 실패 메시지", type: "validation_error" },
  { condition: "전체 통과 후 최종 저장", effect: "데이터 저장 성공", type: "submit_success" },
]
```

Type: `conditional_render`(표시/숨김) · `field_disable`(필드 비활성) · `navigation`(페이지/모달 이동) · `modal_close`(모달 닫기+반영) · `validation_error`(검증 실패) · `submit_success`(저장 성공)

## Step 3e: Section 5 검증 규칙 → `prd_context.validation_rules`

RULE-XX 블록 → Implementation Checklist Step 4에서 Zod schema로 매핑.

```
validation_rules = [
  { id: "RULE-01", field: "광고상품명", constraint: "필수 입력", message: "광고상품명을 입력해 주세요" },
  { id: "RULE-02", field: "_videoMediaSpec", constraint: "필수 등록", message: "동영상 소재를 등록해 주세요" },
]
```

Zod 힌트: `필수 입력/등록`→`z.string().min(1,{message})` · `최소 N자`→`.min(N)` · `최대 N자`→`.max(N)` · `숫자만`→`z.number()` · `URL`→`z.string().url()`

## Step 3f: Section 4-4 버튼/액션 → `prd_context.actions`

```
actions = [
  { button: "저장 버튼", trigger: "클릭", behavior: "검증→성공:저장/실패:에러", mutation: true, type: "submit" },
  { button: "레이아웃 버튼", trigger: "클릭", behavior: "MODAL 이동", mutation: false, type: "navigation_modal" },
]
```

Type: `submit`(API mutation) · `navigation_modal`(모달) · `navigation_page`(페이지 이동) · `ui_toggle`(클라 상태만)
Cancel: 버튼명에 "취소/닫기/뒤로" 포함 시 `cancel_behavior`에 별도 저장.

## Step 3g: Section 6 의존성 → `prd_context.dependencies` + `prd_context.tbd_items`

```
dependencies = { related_screens: [...], api_hints: [...] }
tbd_items = [ { id: "G-01", description: "에러 상태 화면 정책 미정" } ]
```

`tbd_items`는 planner.md **TBD / Open Questions** 섹션으로 출력.

## Step: References 섹션에서 Figma URL 자동 추출

PRD References 표(`UI 화면`/`Description (Figma)`/`node-id`)에서:
- `UI 화면`/`Figma` 링크 → `figma_ui_url`
- `Description (Figma)`/`node-id` dev 링크 → `figma_desc_url`

CLI 인자로 받은 Figma URL과 동일하게 취급한다.

## Step 1E: PRD context ↔ 디자인 분석 병합

- `hasCreate/hasList/hasDetail` → 페이지 구조 결정
- `suggested-name` → feature 디렉토리명 (디자인 추론명 override)
- `cancel_behavior` → cancel 버튼 컴포넌트 스펙
- `dependencies.api_hints` → hook 레이어 사전 계획
- Empty/Loading/Error → 상태 UI 컴포넌트
- User Story AC(Section 3) → 컴포넌트 동작 제약
- `field_component_map`(VIDEO/IMAGE/FILE) → File/Media Upload Pattern(conventions 참조)
- `state_conditions` → Phase 4 각 컴포넌트 Conditional Rendering에 type별 매핑
- `validation_rules` → Implementation Checklist Step 4 Zod 매핑
- `actions`(submit→mutation hook, navigation_modal→modal state) → Phase 5 Data Flow
- `tbd_items` → Deliverable TBD 섹션
