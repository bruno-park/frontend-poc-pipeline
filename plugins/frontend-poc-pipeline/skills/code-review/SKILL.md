---
name: code-review
description: "코드 리뷰를 수행합니다. 로컬 브랜치 diff 분석 또는 Bitbucket PR 분석 후 댓글 게시를 지원합니다. Triggers: (1) '/code-review [브랜치명]' - 로컬 git diff 리뷰, (2) '/code-review [Bitbucket PR URL]' - PR 분석 및 댓글 게시, (3) '코드 리뷰해줘', 'PR 리뷰', 'MR 리뷰', '코드 검토해줘'"
---

# Code Review

로컬 브랜치 변경 사항 또는 Bitbucket PR을 분석하여 컨벤션 위반, 버그, 설계 문제를 리뷰합니다.

## 사용법

```
# Mode A: 로컬 git diff 리뷰
/code-review main
/code-review develop

# Mode B: Bitbucket PR 리뷰 & 댓글 게시
/code-review https://bitbucket.org/{workspace}/{repo}/pull-requests/{id}/overview
/code-review 1618    # PR ID만 입력 (workspace/repo는 컨텍스트에서 추론)
```

---

## Trigger 조건 & 모드 결정

| 입력 | 모드 |
|------|------|
| 브랜치명 (main, develop 등) | **Mode A**: 로컬 git diff 리뷰 |
| Bitbucket PR URL 또는 PR ID | **Mode B**: Bitbucket PR 리뷰 |
| 입력 없음 | **Mode A**: `main` 브랜치 기준 |

---

## Mode A: 로컬 Git Diff 리뷰

### Step 1: Diff 추출

```bash
git diff {{arg1:-main}}...HEAD
```

변경된 파일 목록과 내용을 전체 확인합니다.

---

### Step 2: 컨벤션 검사

아래 모든 컨벤션 항목을 대조하여 위반 사항을 식별합니다.

---

## Conventions

### Naming Conventions

**공통**

- Boolean 변수: `is~`, `are~` prefix 사용
- Static/상수 변수: `UPPER_CASE` (예: `UNIT_TYPE`)
- 컬렉션: `~List`, `~Map`, `~Set` postfix 사용
  - Map은 key/value 기준으로 네이밍
  - 예) `{ won: '원', dollar: '달러' }` → `currencyKoreanMap`
- 축약어가 더 유명한 단어 외에는 축약어 지양
  - `id` OK, `cnt`(count) 지양
- 이벤트 핸들러: `on~Event → handle~Event` 패턴
  - 예) `<Component onClick={handleClick} />`

**Web (TypeScript/React)**

- Interface: 앞에 `I` prefix (예: `IUser`)
- Type: `~Type` suffix (예: `UserType`)
- 파일명: kebab-case (예: `home-component.tsx`)
- API Action 함수: `[get|post|put|patch|delete]{PathName}` 형식
  - 예) GET `/users/me` → `getUsersMe`
- Fetch 함수 파라미터: query string은 `params`, request body는 `body`로 구분

### Component Conventions

- Props 5개 초과 시 interface 분리, **해당 컴포넌트 바로 위에 정의**
- 컴포넌트: arrow function 사용
- default export 분리 선언: `export default memo(CommentItem);`
- Hook은 바로 export (별도 분리 없이)
- **Hook 선언 순서** (권장):

  ```
  useStore → useState
  useRef → useMemo
  useCallback → useEffect
  function / variable (필요에 따라 자유)
  ```

### Code Style

- `if/else` 사용 시 반드시 bracket `{}` 사용
- 중첩 삼항 연산자 지양 → `if/else` 또는 `ts-pattern` 사용
- 반복적인 dot operator 대신 destructuring 사용

  ```ts
  // bad:  obj.name, obj.age
  // good: const { name, age } = obj
  ```

- Model(data)과 View 분리: Model 기반으로 dynamic하게 View 구성, 비슷한 View copy-paste 지양

### API & React Query

- API path는 변수에 저장, `~ApiPath` 네이밍:
  ```ts
  export const usersMeApiPath = '/users/me'
  ```
- Action 함수: `[get|post|put|patch|delete]{PathName}`
  - 예) `getUsersMe`, `postUsersMe`
- Query hook: `use{PathName}`
  - 예) `useUsersMe`
- Query key: `~ApiPath` 변수 사용 → `queryKey: [usersMeApiPath, ...]`
- Mutation hook: `use[Method]{PathName}Mutation`
  - 예) `usePostUsersMeMutation`

### UI & Styling

- 컬러: 디자인 시스템 시맨틱 컬러명 사용 (`text-primary`, `bg-primary` 등)
- 타이포그래피: 커스텀 클래스 사용 (`text-header-00`, `text-body-01-400` 등)
- 단위: arbitrary value는 `px` 대신 `rem` 사용
- 컴포넌트: `shadcn/ui` 우선 사용
- 폼: `React Hook Form` 사용
- 유효성 검사: `Zod` 사용

---

## General Code Quality

### Bugs & Logic Errors

- Null/undefined 체크 누락
- 배열/객체 접근 안전성
- async/await 에러 핸들링
- 레이스 컨디션
- 메모리 누수 (useEffect cleanup 누락)

### Performance

- 불필요한 리렌더링
- useMemo/useCallback 누락 또는 과도한 사용
- 대형 번들 import
- 비효율적인 루프/연산

### Type Safety

- `any` 타입 부적절한 사용
- 타입 정의 누락
- 잘못된 타입 단언

### Design & Architecture

참고: https://refactoring.guru/design-patterns/catalog

- **Separation of Concerns**: 컴포넌트는 UI 렌더링·이벤트 핸들링에 집중
- **Custom Hook Pattern**: 복잡한 비즈니스 로직(mutation, side effect)은 커스텀 훅으로 분리
- **Composition over Inheritance**: 클래스 상속보다 컴포넌트 합성과 props 우선
- **Dependency Injection**: 의존성은 props나 Context로 전달 (하드코딩 금지)
- **Semantic HTML**: `div` 대신 `button`, `nav`, `article`, `section` 등 사용
- **Accessibility**: 인터랙티브 요소에 `aria-label`, `role` 등 ARIA 속성 추가
- Single Responsibility, 코드 중복, 강한 결합, Error Boundary 누락 확인

### Security

- XSS 취약점 (`dangerouslySetInnerHTML` 사용 여부)
- 민감한 데이터 노출 (토큰, 비밀번호 로그 출력)
- 안전하지 않은 API 호출 (인증 헤더 누락)
- CSRF 취약점 (mutation에 CSRF 토큰 없음)

### Accessibility (WCAG 2.1)

- 모든 `<img>`에 `alt` 속성 존재 여부
- 인터랙티브 요소 (`button`, `a`, `input`)에 텍스트 또는 `aria-label` 존재
- `<div onClick>` 패턴 — `<button>` 또는 `role="button"` + `tabIndex` + `onKeyDown` 으로 교체 필요
- 색상만으로 상태를 표현하는 경우 (색맹 사용자 접근 불가)
- 폼 `<input>`에 연결된 `<label>` 또는 `aria-label` 존재 여부
- 모달/다이얼로그: `role="dialog"`, `aria-modal="true"`, 포커스 트랩 구현 여부
- 키보드 탐색: Tab 순서가 시각적 순서와 일치하는지

### Performance & Bundle

- 대형 라이브러리 신규 import (lodash 전체, moment.js 등) — tree-shaking 가능한 방식으로 교체
- 이미지: `<img>` 태그 사용 여부 → Next.js `Image` 컴포넌트로 교체
- `useEffect` 내 API 호출 — React Query로 교체 권장
- 렌더링 중 고비용 연산 (`useMemo` 누락)
- 불필요한 전체 리렌더링 (`memo()` 누락된 리스트 아이템)

---

### Step 3: 리뷰 결과 출력

다음 구조로 출력합니다:

1. **Summary**: 변경 사항 전체 요약 및 전반적 평가
2. **Critical Issues**: 반드시 수정 (버그, 보안, 브레이킹 체인지)
3. **Convention Violations**: 컨벤션 위반 항목 (파일:라인 참조)
4. **Suggestions**: 코드 품질·성능·설계 개선 제안
5. **Positive Notes**: 잘 작성된 코드·패턴

각 이슈 형식:

```
### [Severity: Critical/High/Medium/Low] 이슈 제목

**File**: [filename.ts:42](path/to/filename.ts#L42)
**Problem**: 문제 설명
**Convention/Rule**: 관련 컨벤션 항목
**Suggestion**: 수정 방법
**Example**: (필요 시) 코드 예시
```

---

## Mode B: Bitbucket PR 리뷰 & 댓글 게시

**절대 사용자 확인 없이 댓글을 게시하지 않습니다.**

### Step 1: PR 정보 수집

`bb_get`으로 다음을 병렬로 조회:
- PR 상세 정보: `GET /repositories/{workspace}/{repo}/pullrequests/{id}`
- PR diff: `GET /repositories/{workspace}/{repo}/pullrequests/{id}/diff`

URL에서 workspace, repo, PR ID를 파싱해 사용.

### Step 2: Diff 분석

위 Conventions 및 General Code Quality 항목 전체를 기준으로 분석하며, 추가로 아래 항목을 검사합니다:

**심각도 분류:**
- 🔴 **Critical (버그)**: 기존 동작을 깨뜨리는 로직 오류, 누락된 케이스, 데이터 손실 가능성
- 🟡 **Warning (타입/안전성)**: 타입 불일치, 잠재적 런타임 에러, 잘못된 async 처리
- 🟢 **Minor (코드 품질)**: 불필요한 코드, 가독성, 컨벤션 위반

**추가 분석 항목:**
- 기존에 처리되던 케이스가 리팩토링 후 누락되었는지
- 함수 반환 타입과 실제 반환값 일치 여부
- Optional chaining / null check 일관성
- PR description에 명시된 변경 사항과 실제 코드 일치 여부

### Step 3: 리뷰 결과 사용자에게 제시

다음 형식으로 출력하고 **반드시 사용자 확인을 기다림**:

```
## PR #[id] 코드 리뷰 결과

### 🔴 Critical (버그)
#### 1. [이슈 제목]
**파일:** `[파일명]` - `[함수명]`
[문제 설명]
**수정 제안:**
\`\`\`typescript
// 수정 코드
\`\`\`

### 🟡 Warning (타입/안전성)
...

### 🟢 Minor (코드 품질)
...

### ✅ 잘된 점
...

---
### 달고 싶은 댓글 목록 (승인 필요)
| # | 내용 요약 | 심각도 |
|---|---------|--------|
| 1 | ... | 🔴 Critical |

어떤 댓글을 달까요? (전부 / 번호 선택 / 없음)
```

### Step 4: 라인 번호 확인

댓글 게시 전 소스 파일을 직접 조회해 정확한 라인 번호 확인:

```
GET /repositories/{workspace}/{repo}/src/{source_commit_hash}/{filepath}
```

- `source_commit_hash`는 Step 1에서 가져온 PR 정보의 `source.commit.hash` 사용
- 여러 파일에 댓글을 달 경우 파일별로 각각 조회

### Step 5: 사용자 확인 후 인라인 댓글 게시

사용자가 승인한 항목만 `bb_post`로 게시. 인라인 댓글을 기본으로 사용:

- 엔드포인트: `POST /repositories/{workspace}/{repo}/pullrequests/{id}/comments`
- 인라인 댓글 바디:
  ```json
  {
    "content": {"raw": "댓글 내용"},
    "inline": {"to": <라인번호>, "path": "파일/경로.tsx"}
  }
  ```
- 일반 댓글 바디 (라인 지정 불가한 경우):
  ```json
  {"content": {"raw": "댓글 내용"}}
  ```

**댓글 작성 원칙:**
- 한국어, 친절한 톤
- 심각도 이모지로 시작 (🔴/🟡/🟢)
- 문제 설명 + 수정 제안 코드 포함
- 단정적이지 않게, 제안하는 형태로

**친절한 댓글 작성 가이드:**

| 상황 | 피해야 할 표현 | 권장 표현 |
|------|-------------|---------|
| 버그 지적 | "이 코드는 버그입니다" | "혹시 이 케이스도 처리가 필요하지 않을까요?" |
| 누락 케이스 | "XX 빠졌습니다" | "리팩토링 과정에서 XX 케이스가 빠진 것 같은데 확인 부탁드려도 될까요?" |
| 타입 오류 | "타입이 틀렸습니다" | "반환 타입이 일부 경로에서 `undefined`가 반환될 수 있을 것 같아서요 :)" |
| 코드 품질 | "Optional chaining 잘못 씀" | "이미 null 체크를 하셨으니 내부에서는 `?.` 없이 써도 될 것 같아요!" |

댓글 게시 완료 후 게시된 댓글 목록 요약 출력 (파일명 + 라인 번호 포함).

---

## 주의사항

- 변경된 코드만 리뷰 (영향받지 않는 기존 코드 제외)
- 심각도 기준으로 우선순위 정렬
- 수정 제안에는 코드 예시 포함
- 좋은 패턴도 명시적으로 언급
- 건설적이고 구체적인 피드백 제공
- **(Mode B)** 사용자 승인 없이 댓글 절대 게시 금지
- **(Mode B)** PR이 MERGED/DECLINED 상태인 경우 알림 후 계속 진행 여부 확인
- **(Mode B)** diff가 너무 큰 경우 파일별로 나눠서 순차 분석
- **(Mode B)** 이슈가 없는 경우 "특별한 문제점을 발견하지 못했습니다" 출력 후 칭찬 댓글 제안
