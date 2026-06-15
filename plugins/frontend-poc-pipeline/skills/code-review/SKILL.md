---
name: code-review
description: "코드 리뷰를 수행합니다. 로컬 브랜치 diff 분석(Mode A) 또는 원격 PR/MR 분석 후 댓글 게시(Mode B — GitLab/Bitbucket/GitHub 자동 감지)를 지원합니다. 판단 기준은 conventions/SKILL.md(SSOT)입니다. Triggers: (1) '/code-review [브랜치명]' - 로컬 git diff 리뷰, (2) '/code-review [PR/MR URL 또는 ID]' - 원격 변경요청 분석 및 댓글 게시, (3) '코드 리뷰해줘', 'PR 리뷰', 'MR 리뷰', '코드 검토해줘'"
---

# Code Review

로컬 브랜치 변경 사항(Mode A) 또는 원격 PR/MR(Mode B)을 분석하여 컨벤션 위반·버그·설계 문제를 리뷰합니다.

두 모드는 **동일한 Analysis Core**(무엇을 볼지)를 공유하고, 실행 방식(local diff vs 원격 API)만 다릅니다.

## 사용법

```
# Mode A: 로컬 git diff 리뷰 (콘솔 출력)
/code-review main
/code-review develop

# Mode B: 원격 PR/MR 리뷰 & 댓글 게시 (host 자동 감지)
/code-review https://gitlab.com/{group}/{repo}/-/merge_requests/{iid}
/code-review https://bitbucket.org/{workspace}/{repo}/pull-requests/{id}
/code-review https://github.com/{owner}/{repo}/pull/{number}
/code-review 1618    # ID만 입력 (host·repo는 git remote / 컨텍스트에서 추론)
```

## Trigger 조건 & 모드 결정

| 입력 | 모드 |
|------|------|
| 브랜치명 (main, develop 등) | **Mode A**: 로컬 git diff 리뷰 |
| PR/MR URL 또는 변경요청 ID | **Mode B**: 원격 PR/MR 리뷰 |
| 입력 없음 | **Mode A**: `main` 브랜치 기준 |

---

## Step 0 — 판단 기준 로드 (필수, 두 모드 공통)

> 리뷰를 시작하기 **전에 반드시** `../conventions/SKILL.md`(프로젝트 컨벤션 SSOT)를 끝까지 읽는다.
> 네이밍·컴포넌트·API·스타일·테스트 러너 규칙은 **그 문서가 단일 기준**이다. 이 스킬에 규칙을 복제하지 않는 이유 — 복제본은 SSOT와 어긋나(drift) 잘못된 지적을 만든다.

컨벤션 위반을 지적할 때는 **어느 조항을 근거로 했는지 명시**한다 (예: "conventions §2 — Component files는 PascalCase").

---

## Analysis Core — 두 모드가 공유하는 리뷰 체크리스트

아래 우선순위 순으로 변경된 코드만 분석한다. **상위 항목일수록 심각도가 높다.**

### 1. Convention Compliance (SSOT 기준)

`../conventions/SKILL.md`의 모든 조항을 대조한다. 자주 놓치는 항목:
- 네이밍(§2): Boolean `is/are`, 컬렉션 `~List/~Map/~Set`, 핸들러 `handle~`, 상수 `UPPER_CASE`, Props interface `I` prefix, Type `~Type` suffix
- 파일/폴더(§2~3): **Component 파일 PascalCase**, Helper 파일 camelCase+dot suffix, `pageComponents/`가 `pages/` 미러링
- 훅(§7): 2-layer 패턴, API path 변수화(`~ApiPath`), query key에 path 변수 사용
- 스타일(§9, §12): `px` 금지(rem), `cn()` 금지, 인라인 `style` 금지, `<img>` 대신 next/image
- 구조(§12 DON'T): 별도 service/model 레이어 금지, global type/constant 파일 금지, `data-testid` 금지

### 2. Bugs & Logic Errors

- Null/undefined 체크 누락, 배열/객체 접근 안전성
- **`?? []` / `|| []` 기본값이 의미를 뭉개는지** — `undefined`(미제공)와 `[]`(빈/전체제외)가 다른 의미라면 collapse 금지
- async/await 에러 핸들링, 레이스 컨디션, useEffect cleanup 누락(메모리 누수)
- **렌더 레벨 hide/filter ≠ 데이터 정합** — 화면에서 숨기거나 필터한 값이 **저장·제출 body에는 그대로 남는지** 확인. 숨긴 값이 서버로 전송돼 검증 에러/저장 dead-end를 만들 수 있다. 노출 제어 변경은 반드시 **저장/제출 경로**까지 함께 점검
- **캐시·SSR 경로 일치** — `setQueryData`(SSR 주입)·`staleTime: Infinity` 등으로 queryFn이 재실행되지 않으면, queryFn에서 만든 파생값이 소비처에 도달하지 않을 수 있다. 새 필드는 raw로 소비하거나 캐시 주입 지점도 동기화했는지 확인
- 리팩토링 후 기존 처리 케이스 누락 여부, 함수 반환 타입과 실제 반환값 일치 여부

### 3. Type Safety

- `any` 타입 부적절한 사용, 타입 정의 누락, 잘못된 타입 단언
- Optional chaining / null check 일관성

### 4. Performance

- 불필요한 리렌더링, `memo()` 누락된 리스트 아이템
- `useMemo`/`useCallback` 누락 또는 과도한 사용, 렌더링 중 고비용 연산
- 대형 라이브러리 신규 import(lodash 전체, moment.js 등) → tree-shaking 가능한 방식으로 교체
- `useEffect` 내 API 호출 → React Query로 교체 권장
- 이미지 `<img>` → Next.js `Image`

### 5. Design & Architecture

참고: https://refactoring.guru/design-patterns/catalog

- **Separation of Concerns**: 컴포넌트는 UI 렌더링·이벤트 핸들링에 집중
- **Custom Hook Pattern**: 복잡한 비즈니스 로직(mutation, side effect)은 커스텀 훅으로 분리
- **Composition over Inheritance**, **Dependency Injection**(props/Context로 전달)
- **Semantic HTML**: `div` 대신 `button`, `nav`, `article`, `section`
- Single Responsibility, 코드 중복, 강한 결합, Error Boundary 누락 확인

### 6. Security

- XSS(`dangerouslySetInnerHTML`), 민감 데이터 노출(토큰·비밀번호 로그)
- 인증 헤더 누락, mutation CSRF 토큰 누락
- RBAC 누락 (권한 체크 없는 보호 라우트/API 호출)

### 7. Accessibility (WCAG 2.1)

- 모든 `<img>`에 `alt`, 인터랙티브 요소(`button`/`a`/`input`)에 텍스트 또는 `aria-label`
- `<div onClick>` → `<button>` 또는 `role="button"` + `tabIndex` + `onKeyDown`
- 색상만으로 상태 표현 금지(색맹 접근), 폼 `<input>`에 `<label>`/`aria-label`
- 모달: `role="dialog"`, `aria-modal="true"`, 포커스 트랩
- 키보드 탐색: Tab 순서가 시각적 순서와 일치

### 8. Tests

- 비즈니스 로직에 테스트 존재 여부, 테스트 품질(RED 검증, AC 커버)
- `console.log` / `debugger` 잔존 여부

---

## Severity 분류 (단일 기준 — 두 모드 공통)

| 심각도 | 의미 | 예시 |
|--------|------|------|
| 🔴 **Critical** | 머지 차단. 동작을 깨뜨리는 버그·데이터 손실·보안 취약점 | 로직 오류, 누락 케이스, `any` 남용, RBAC 누락, XSS, `console.log` 잔존 |
| 🟠 **High** | 머지 차단. 핵심 컨벤션 위반·잠재 런타임 에러 | naming 위반, `px` 단위, Props `I` prefix 누락, 미사용 import, 잘못된 async 처리 |
| 🟡 **Medium** | 권고. 품질·성능·설계 개선 | 컴포넌트 500줄 초과, 중복 로직, `memo`/`useMemo` 누락, 하드코딩 문자열 |
| 🟢 **Low** | 제안. 가독성·사소한 최적화·nit | 네이밍 다듬기, 주석, 미세 리팩터 아이디어 |

**합격 기준(PR 게이트)**: Critical/High 0개 → `PASS`, 하나라도 있으면 `BLOCK`.

---

## Mode A: 로컬 Git Diff 리뷰

### A-1: Diff 추출

```bash
git diff {{arg1:-main}}...HEAD
```

변경된 파일 목록과 내용을 전체 확인한다.

### A-2: Analysis Core 적용

위 Analysis Core 1~8 항목을 변경된 코드에 적용해 이슈를 식별하고 Severity로 분류한다.

### A-3: 리뷰 결과 출력

아래 **공통 출력 스키마**로 콘솔에 출력한다.

---

## Mode B: 원격 PR/MR 리뷰 & 댓글 게시

**절대 사용자 확인 없이 댓글을 게시하지 않습니다.**

### B-1: Git host 감지 (URL > git remote > MCP)

`create-pull-request` 스킬과 같은 감지 우선순위(URL > git remote > MCP/CLI)를 따른다.

| 신호 | Host | 메타/Diff 조회 | 인라인 댓글 |
|------|------|---------------|------------|
| `gitlab` in URL/remote | **GitLab** | `gitlab_get_mr`, `gitlab_mr_changes` | `gitlab_create_mr_discussion` (position) / `gitlab_add_mr_note`(일반) |
| `bitbucket` in URL/remote | **Bitbucket** | `bb_get` (pullrequests, diff) | `bb_post` (inline `{to, path}`) |
| `github` in URL/remote | **GitHub** | `gh pr view`, `gh pr diff` | `gh pr review --comment` / `gh api ...comments` |

감지 순서: ① 사용자가 명시한 URL/플랫폼 → ② `git remote get-url origin` → ③ 연결된 MCP/CLI. URL에서 host·repo·변경요청 ID를 파싱한다.

> **report-only fallback**: host 미상 / 해당 MCP·CLI 미연결 / 변경요청 미존재면 댓글 게시를 시도하지 않고, Mode A처럼 분석 결과만 콘솔에 출력하고 그 사유를 명시한다.

### B-2: 변경요청 정보 & diff 수집

감지된 host의 도구로 **병렬 조회**: 변경요청 상세(상태·source/target·`head sha`) + diff.

- 상태가 MERGED/DECLINED/CLOSED면 알림 후 계속 진행 여부를 사용자에게 확인한다.
- diff가 너무 크면 파일별로 나눠 순차 분석한다.

### B-3: Analysis Core 적용

위 Analysis Core 1~8 항목 전체를 기준으로 분석하고, 추가로 확인:
- PR/MR description에 명시된 변경 사항과 실제 코드 일치 여부

### B-4: 리뷰 결과 사용자에게 제시 (승인 대기)

공통 출력 스키마로 출력한 뒤, **게시 후보 댓글 목록을 제시하고 반드시 사용자 승인을 기다린다**:

```
---
### 달고 싶은 댓글 목록 (승인 필요)
| # | 파일:라인 | 내용 요약 | 심각도 |
|---|----------|---------|--------|
| 1 | Foo.tsx:42 | ... | 🔴 Critical |

어떤 댓글을 달까요? (전부 / 번호 선택 / 없음)
```

### B-5: 라인 번호 확인

댓글 게시 전 소스 파일을 직접 조회해 정확한 라인 번호를 확인한다. host별 소스 조회 도구 사용 (예: Bitbucket `GET .../src/{head_sha}/{filepath}`, GitLab `gitlab_mr_changes`의 `new_path`/라인, GitHub `gh api`). 여러 파일이면 파일별로 조회한다.

### B-6: 사용자 승인 후 인라인 댓글 게시

사용자가 승인한 항목만 host 어댑터로 게시한다. **인라인 댓글을 기본**으로, 라인 지정이 불가하면 일반 댓글로.

- GitLab: `gitlab_create_mr_discussion` (position: `new_path` + `new_line` + `base/head/start sha`)
- Bitbucket: `bb_post` `POST .../pullrequests/{id}/comments`, body `{"content":{"raw":"..."},"inline":{"to":<line>,"path":"..."}}`
- GitHub: `gh api .../pulls/{n}/comments` (path + line + commit_id)

**댓글 작성 원칙**: 한국어, 친절한 톤, 심각도 이모지로 시작(🔴/🟠/🟡/🟢), 문제 설명 + 수정 제안 코드 포함, 단정 대신 제안형.

**친절한 댓글 가이드:**

| 상황 | 피해야 할 표현 | 권장 표현 |
|------|-------------|---------|
| 버그 지적 | "이 코드는 버그입니다" | "혹시 이 케이스도 처리가 필요하지 않을까요?" |
| 누락 케이스 | "XX 빠졌습니다" | "리팩토링 과정에서 XX 케이스가 빠진 것 같은데 확인 부탁드려도 될까요?" |
| 타입 오류 | "타입이 틀렸습니다" | "반환 타입이 일부 경로에서 `undefined`가 반환될 수 있을 것 같아서요 :)" |
| 코드 품질 | "Optional chaining 잘못 씀" | "이미 null 체크를 하셨으니 내부에서는 `?.` 없이 써도 될 것 같아요!" |

게시 완료 후 게시된 댓글 목록 요약(파일명 + 라인 번호)을 출력한다.

---

## 공통 출력 스키마 (두 모드)

```
## 코드 리뷰 결과 — [브랜치/PR·MR #id]

### Summary
변경 사항 전체 요약 + 전반적 평가 + PASS/BLOCK 판정

### 🔴 Critical
#### 1. [이슈 제목]
**File**: [filename.ts:42](path/to/filename.ts#L42)
**Problem**: 문제 설명
**Rule**: conventions §X 또는 Analysis Core 항목
**Suggestion**: 수정 방법 (+ 필요 시 코드 예시)

### 🟠 High
...
### 🟡 Medium
...
### 🟢 Low
...

### ✅ 잘된 점
좋은 패턴·코드 명시
```

---

## 주의사항

- 변경된 코드만 리뷰 (영향받지 않는 기존 코드 제외)
- 심각도 기준 우선순위 정렬, 수정 제안에 코드 예시 포함, 좋은 패턴도 명시
- 컨벤션 판단은 **`../conventions/SKILL.md` 근거 조항을 명시** (주관적 취향 금지)
- **(Mode B)** 사용자 승인 없이 댓글 절대 게시 금지
- **(Mode B)** host 미감지/도구 미연결 시 report-only fallback (게시 시도 안 함)
- **(Mode B)** 변경요청이 MERGED/DECLINED/CLOSED면 알림 후 진행 여부 확인
- **(Mode B)** 이슈가 없으면 "특별한 문제점을 발견하지 못했습니다" 출력 후 칭찬 댓글 제안
