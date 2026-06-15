---
name: e2e-test-gen
description: planner.md와 Jira AC를 기반으로 Playwright E2E 테스트를 TDD 방식으로 작성합니다. Playwright 공식 Test Agents(`npx playwright init-agents --loop=claude` 산출물 — playwright-test-planner → generator → healer)를 감지해 체이닝하고, 없으면 내장 로직으로 직접 생성합니다.
---

# E2E Test Generator (TDD - Playwright)

`planner.md`와 Jira 수용 기준을 기반으로 **Playwright E2E 테스트를 먼저 작성**합니다.
프로젝트에 [Playwright 공식 Test Agents](https://playwright.dev/docs/test-agents)(`.claude/agents/playwright-test-*`)가 생성되어 있으면 3종을 체이닝하고, 없으면 이 스킬의 내장 로직으로 직접 작성합니다.

## 트리거

- `/test-writer --e2e` 호출 시
- `/test-writer --all` 호출 시 (Phase 2)

## 입력 컨텍스트

- `planner.md` 내용 (컴포넌트, URL 상태, 데이터 흐름)
- Jira AC 목록 (있을 경우)
- 앱 로컬 URL (기본값: `http://localhost:3001`)

---

## 동작 검증 원칙 (action · request · response · post-action) — UI보다 우선

> **왜:** E2E의 가치는 "요소가 보이는가"가 아니라 "사용자 action이 올바른 API를 호출하고, 응답에 따라 화면이 올바르게 반응하는가"에 있다. UI 가시성만 단언하면(`toBeVisible`, `tbody tr` count, `toHaveURL`) 요청 파라미터·요청 본문·응답 처리·호출 후 상태 변화 버그를 놓친다. **각 시나리오는 가능한 한 아래 4계층을 함께 단언한다. 특히 mutation(생성/수정/삭제)은 request body → response → post-action까지 필수.**

| 계층 | 단언 대상 | Playwright API |
|------|----------|----------------|
| **action** | 클릭/입력/제출이 일어남 | `click` / `fill` / `getByRole` |
| **request** | 올바른 method·URL·query·body로 API 호출 | `waitForRequest`, `req.method()`, `new URL(req.url()).searchParams`, `req.postDataJSON()` |
| **response** | status·응답 데이터 | `waitForResponse`, `res.status()`, `await res.json()` |
| **post-action** | 호출 후 화면 반응 (목록 refetch·toast·redirect·URL·optimistic·에러 롤백) | `waitForResponse`(refetch GET) + UI 단언 |

**나쁜 예 (UI만 — 약한 단언):**
```typescript
await page.getByPlaceholder(/검색/).fill('테스트')
await expect(page).toHaveURL(/search=테스트/)   // URL만 봄. API가 search 파라미터로 호출됐는지는 검증 안 됨
```
**좋은 예 (action → request):**
```typescript
const reqP = page.waitForRequest(r => r.url().includes('/api/v1/partners') && r.method() === 'GET')
await page.getByPlaceholder(/검색/).fill('테스트')
const req = await reqP
expect(new URL(req.url()).searchParams.get('search')).toBe('테스트')
```
**mutation — request body → response → post-action 전부:**
```typescript
test('[AC] 생성 시 POST 본문 전송 → 201 → 목록 refetch + 토스트', async ({ page }) => {
  await page.getByRole('button', { name: '생성' }).click()
  await page.getByLabel('파트너명').fill('새 파트너')
  const [createReq, createRes, refetchRes] = await Promise.all([
    page.waitForRequest(r => r.url().includes('/api/v1/partners') && r.method() === 'POST'),
    page.waitForResponse(r => r.request().method() === 'POST' && r.url().includes('/api/v1/partners')),
    page.waitForResponse(r => r.request().method() === 'GET' && r.url().includes('/api/v1/partners')), // refetch
    page.getByRole('button', { name: '저장' }).click(),
  ])
  expect(createReq.postDataJSON()).toMatchObject({ name: '새 파트너' }) // request body
  expect(createRes.status()).toBe(201)                                  // response
  expect(refetchRes.status()).toBe(200)                                 // post-action: 목록 refetch
  await expect(page.getByText('생성되었습니다')).toBeVisible()            // post-action: toast
})
```
**에러 응답 동작도 1급 시나리오:** `page.route(...)`로 4xx/5xx를 주입해 "에러 메시지 노출 + 목록 불변/롤백"을 단언한다 (BE 미배포여도 mock으로 작성 가능).

---

## 테스트 제목 컨벤션 — `기능명 (라우트)` (e2e 대시보드 path 노출)

> **왜:** e2e 대시보드는 업로드된 Playwright JSON의 `title`을 표시한다. **최상위 `describe` 제목에 테스트 대상 라우트(URL 경로)** 를 넣으면 대시보드가 `기능명 (라우트) › 시나리오` = **`title(url) - content`** 형태로 "어떤 화면을 검증하는지"를 보여준다. (repo 파일 경로 `file:line`은 JSON에 이미 들어 있어 대시보드가 별도로 노출하므로, **제목에는 파일 경로가 아니라 라우트(URL)** 를 쓴다.)

규칙:
- 라우트는 `planner.md`의 **URL State / 페이지 라우트**에서 가져와 **상수 1곳**(`const ROUTE = '...'`)에 두고 `page.goto`와 describe 제목이 **공유**한다 — 제목과 goto가 따로 놀아 drift 나는 것을 막는다.
- 최상위 describe: `` test.describe(`<기능명> (${ROUTE})`, ...) ``. 시나리오(content)는 개별 `test()` 제목으로.
- 동적 세그먼트는 패턴으로: `/media/ads/partner-ad-management/:id`.

```typescript
const ROUTE = '/media/ads/partner-ad-management'   // planner.md URL State 기준

test.describe(`파트너 광고 관리 (${ROUTE})`, () => {
  test.beforeEach(async ({ page }) => {
    await loginAs(page, 'master')
    await page.goto(ROUTE)
  })
  test('검색 시 search param으로 목록 API 재호출', async ({ page }) => { /* content */ })
})
// → 대시보드 표시: 파트너 광고 관리 (/media/ads/partner-ad-management) - 검색 시 search param으로 목록 API 재호출
```

---

## Phase 0: E2E 러너 설치 게이트 (§13.5)

> **E2E 러너(Playwright)는 자동 설치하지 않는다.** 미설치 상태는 정상 1급 폴백이다 — "단위 테스트만으로 진행"으로 안내한다.

### 0. Playwright 설치 여부 확인 (먼저)
```
deps: @playwright/test 존재?  /  npx playwright --version
```

| 상태 | 조치 |
|------|------|
| 설치됨 | 아래 1번(인프라 파일 확인)으로 진행 |
| **미설치** | ⚠️ **STOP** — 자동 설치/스캐폴딩하지 않는다. 아래 안내 후 종료:<br>"E2E 러너(Playwright)가 설치되어 있지 않습니다. 이 PoC는 단위 테스트(Jest/Vitest)만으로 진행하는 것이 기본입니다. E2E를 도입하려면 별도 opt-in 작업으로 `yarn add -D @playwright/test` + `npx playwright install` + config + `e2e/` 구성을 진행할까요?" |

### 1. 필수 파일 확인 (Playwright 설치된 경우)
```
playwright.config.ts  → 없으면 Phase 1에서 생성 지시
e2e/                  → 없으면 mkdir
e2e/helpers/auth.ts   → 없으면 Phase 2에서 생성
.env.test             → 없으면 템플릿 생성
```

### 2. Playwright Test Agents 확인 (공식 init-agents 산출물)

공식 경로 우선, 레거시 경로는 fallback으로 순서대로 Glob:

```
1순위: .claude/agents/playwright-test-planner.md (+ -generator.md / -healer.md)
        ← `npx playwright init-agents --loop=claude` 산출물 (Playwright v1.56+)
2순위(플러그인 번들): frontend-poc-pipeline:playwright-test-{planner,generator,healer}
        ← 이 플러그인 agents/에 동봉된 공식 정의 스냅샷
3순위(레거시): agents/*playwright*.md
```

| 결과 | 조치 |
|------|------|
| 프로젝트 로컬(1순위) 발견 | **에이전트 위임 모드.** `.mcp.json`에 `playwright-test` MCP 서버(`npx playwright run-test-mcp-server`) 등록 여부도 확인 — 없으면 에이전트가 브라우저 도구를 쓸 수 없으므로 `init-agents` 재실행을 안내 |
| 로컬 없음 + 번들(2순위) 사용 | `.mcp.json`에 `playwright-test` 서버가 **등록돼 있을 때만** 번들 에이전트로 위임. 미등록이면 사용자 동의 후 해당 entry만 **병합 추가**(기존 서버 보존 — init-agents처럼 덮어쓰지 않는다) 하거나 내장 로직으로 진행 |
| 일부만 발견 | 발견된 에이전트만 위임, 나머지 Phase는 내장 로직 |
| MCP 미등록 + 동의 없음 | **opt-in 안내 후 내장 로직으로 진행** (§13.5 정신 — 자동 실행 금지): "공식 도입: `npx playwright init-agents --loop=claude` → `.claude/agents/` 에이전트 3종 + `.mcp.json` + `specs/` + seed 테스트 생성. ⚠️ 기존 `.mcp.json`이 있으면 **덮어쓰므로** 먼저 백업하세요." |

> 번들 에이전트는 Playwright v1.59.1 시점 스냅샷이다. 프로젝트가 직접 `init-agents`를 실행하면 자기 Playwright 버전과 정확히 일치하는 정의를 갖게 되므로 항상 로컬을 우선한다.

**공식 산출물 컨벤션 (에이전트 위임 모드에서 사용):**
- `specs/` — planner가 작성하는 마크다운 테스트 계획. 1 spec ↔ 1 test file 대응이 원칙
- `seed.spec.ts` (testDir 내) — 에이전트가 인증 등 환경 부트스트랩에 쓰는 시드 테스트. `e2e/helpers/auth.ts`의 로그인 플로우를 시드에 반영하면 에이전트가 로그인된 `page` 컨텍스트로 탐색한다
- 에이전트 정의는 Playwright 버전 업데이트 시 `init-agents` 재실행으로 재생성하는 것이 공식 권장

---

## Phase 1: playwright-test-planner 호출

### 에이전트 존재 시
`playwright-test-planner` 서브에이전트에 위임.

> planner는 `playwright-test` MCP로 **실행 중인 앱을 직접 탐색**하며 계획을 세운다.
> 앱이 떠 있지 않으면 위임하지 말고 내장 로직으로 폴백한다 (또는 앱 실행을 먼저 안내).

**전달 컨텍스트:**
```
다음 planner.md를 기반으로 E2E 테스트 계획을 수립해주세요.
산출물은 specs/[feature].md 로 저장해주세요.

[planner.md 전체 내용]

Jira AC:
[AC 항목 목록]

각 시나리오는 UI 가시성만이 아니라 **action → request(method/URL/query/body) → response(status) → post-action(목록 refetch·toast·redirect·에러 롤백)** 을 함께 검증하도록 계획한다 (위 "동작 검증 원칙" 참조).

테스트 우선순위:
1. 인증/권한 (로그인, RBAC)
2. 핵심 CRUD 플로우 — **request 본문/파라미터 + response + 호출 후 동작까지**
3. URL 상태 동기화 (검색·필터·정렬이 올바른 query param으로 API를 호출하는지)
4. 예외 케이스 (빈 상태, 에러 응답 시 동작, 권한 없음)
```

### 에이전트 없을 시 (내장 로직)

planner.md에서 직접 E2E 시나리오 추출 (기대결과는 UI뿐 아니라 request/response/post-action을 포함):

| 시나리오 | 역할 | 사전조건 | 단계 | 기대결과 (동작 검증) |
|---------|------|---------|------|---------|
| 목록 로드 | master | 로그인 | 페이지 이동 | GET 목록 API 호출(200) + 테이블 렌더링 |
| 검색 필터 | master | 로그인 | 검색어 입력 | `search` query param으로 GET 재호출 + URL 업데이트 |
| 생성 CRUD | master | 로그인 | 버튼→폼→저장 | POST(올바른 body)→201→목록 refetch+토스트 |
| 생성 실패 | master | 로그인 | 저장(4xx mock) | 에러 메시지 노출 + 목록 불변 |
| 권한 차단 | finance | 로그인 | 버튼 확인 | 버튼 미표시 |

---

## Phase 2: playwright-test-generator 호출

### 에이전트 존재 시
`playwright-test-generator` 서브에이전트에 위임. generator는 셀렉터·assertion을 라이브 브라우저로 검증하며 코드를 생성한다.

**전달 컨텍스트:**
```
specs/[feature].md 테스트 계획을 기반으로 E2E 테스트 코드를 생성해주세요.

테스트 계획:
[Phase 1 결과 — specs/[feature].md]

생성 규칙:
- 파일 위치: e2e/[feature]/[scenario].spec.ts (playwright.config의 testDir 컨벤션 준수)
- seed 테스트(seed.spec.ts)를 환경 부트스트랩 예시로 사용
- auth helper: e2e/helpers/auth.ts 사용
- data-testid 셀렉터 사용 금지
- 역할별 테스트 포함 (master/finance/CS)
- **UI 단언만으로 끝내지 말 것.** 각 시나리오에서 action이 트리거한 ① request(method·URL·query·body) ② response(status) ③ 호출 후 동작(목록 refetch·toast·redirect·optimistic·에러 롤백)을 `waitForRequest`/`waitForResponse`/`page.route`로 단언한다 (위 "동작 검증 원칙" 4계층)
- **최상위 `describe` 제목 = `기능명 (라우트)`** — 라우트를 `const ROUTE`에 두고 goto와 공유. 대시보드가 `title(url) - content`로 노출 (위 "테스트 제목 컨벤션")
```

### 에이전트 없을 시 (내장 로직)

직접 테스트 코드 생성:

```typescript
// e2e/[feature]/[feature].spec.ts
import { test, expect } from '@playwright/test'
import { loginAs } from '../helpers/auth'

const ROUTE = '/[route]'   // planner.md URL State 기준 — describe 제목·goto가 공유 (대시보드 title(url))

test.describe(`[Feature명] (${ROUTE})`, () => {
  test.beforeEach(async ({ page }) => {
    await loginAs(page, 'master')
    await page.goto(ROUTE)
    await page.waitForResponse('**/api/v1/[endpoint]**')
  })

  // AC 항목별 테스트 — UI + 동작(request/response/post-action) 함께 검증
  test('[AC-1] 목록 GET 응답(200) 후 행이 렌더링된다', async ({ page }) => {
    const res = await page.waitForResponse('**/api/v1/[endpoint]**')
    expect(res.status()).toBe(200)
    await expect(page.locator('tbody tr')).not.toHaveCount(0)
  })

  test('[AC-2] 검색 시 search query param으로 목록 API를 재호출한다', async ({ page }) => {
    const reqP = page.waitForRequest(r => r.url().includes('/api/v1/[endpoint]') && r.method() === 'GET')
    await page.fill('[placeholder*="검색"]', '테스트')
    const req = await reqP
    expect(new URL(req.url()).searchParams.get('search')).toBe('테스트') // request 검증
    await expect(page).toHaveURL(/search=테스트/)                          // URL 동기화도 함께
  })

  test('[AC-3] 생성 시 POST 본문 전송 → 201 → 목록 refetch + 토스트', async ({ page }) => {
    await page.getByRole('button', { name: '생성' }).click()
    await page.getByLabel('[필드 라벨]').fill('새 항목')
    const [createReq, createRes, refetchRes] = await Promise.all([
      page.waitForRequest(r => r.url().includes('/api/v1/[endpoint]') && r.method() === 'POST'),
      page.waitForResponse(r => r.request().method() === 'POST' && r.url().includes('/api/v1/[endpoint]')),
      page.waitForResponse(r => r.request().method() === 'GET' && r.url().includes('/api/v1/[endpoint]')), // refetch
      page.getByRole('button', { name: '저장' }).click(),
    ])
    expect(createReq.postDataJSON()).toMatchObject({ name: '새 항목' }) // request body
    expect(createRes.status()).toBe(201)                                // response
    expect(refetchRes.status()).toBe(200)                               // post-action: refetch
    await expect(page.getByText('생성되었습니다')).toBeVisible()          // post-action: toast
  })

  test('[AC-3-err] 생성 실패(4xx) 시 에러 메시지가 뜨고 목록은 그대로다', async ({ page }) => {
    await page.route('**/api/v1/[endpoint]', route =>
      route.request().method() === 'POST'
        ? route.fulfill({ status: 400, contentType: 'application/json', body: JSON.stringify({ message: '중복된 이름' }) })
        : route.continue(),
    )
    await page.getByRole('button', { name: '생성' }).click()
    await page.getByLabel('[필드 라벨]').fill('중복 항목')
    await page.getByRole('button', { name: '저장' }).click()
    await expect(page.getByText('중복된 이름')).toBeVisible()
  })
})

// 권한 테스트
const roleMatrix = [
  { role: 'master' as const, canCreate: true },
  { role: 'finance' as const, canCreate: false },
  { role: 'CS' as const, canCreate: false },
]

for (const { role, canCreate } of roleMatrix) {
  test(`[RBAC] (${ROUTE}) ${role} 역할 - 생성 버튼 ${canCreate ? '표시' : '숨김'}`, async ({ page }) => {
    await loginAs(page, role)
    await page.goto(ROUTE)
    const createBtn = page.getByRole('button', { name: '생성' })
    if (canCreate) {
      await expect(createBtn).toBeVisible()
    } else {
      await expect(createBtn).not.toBeVisible()
    }
  })
}
```

---

## Phase 3: 인프라 스캐폴딩 (필요 시)

### playwright.config.ts (없을 경우)
```typescript
import { defineConfig } from '@playwright/test'
import dotenv from 'dotenv'

dotenv.config({ path: '.env.test' })

export default defineConfig({
  testDir: './e2e',
  timeout: 30000,
  use: {
    baseURL: process.env.BASE_URL || 'http://localhost:3001',
    headless: true,
  },
  reporter: [['list'], ['html', { outputFolder: 'playwright-report' }]],
})
```

### e2e/helpers/auth.ts (없을 경우)
```typescript
import { Page } from '@playwright/test'

export async function loginAs(page: Page, role: 'master' | 'finance' | 'CS') {
  const credentials = {
    master: { email: process.env.TEST_MASTER_EMAIL!, password: process.env.TEST_MASTER_PASSWORD! },
    finance: { email: process.env.TEST_FINANCE_EMAIL!, password: process.env.TEST_FINANCE_PASSWORD! },
    CS: { email: process.env.TEST_CS_EMAIL!, password: process.env.TEST_CS_PASSWORD! },
  }
  const roleHome = {
    master: '**/dashboard**',
    finance: '**/reports/publishing**',
    CS: '**/accounts/users**',
  }

  await page.goto('http://localhost:3001/login')
  await page.getByPlaceholder('아이디(이메일)').fill(credentials[role].email)
  await page.getByPlaceholder('비밀번호').fill(credentials[role].password)
  await page.getByRole('button', { name: '로그인' }).click()
  await page.waitForURL(roleHome[role])
}
```

### .env.test 템플릿 (없을 경우)
```
TEST_MASTER_EMAIL=master@example.com
TEST_MASTER_PASSWORD=
TEST_FINANCE_EMAIL=finance@example.com
TEST_FINANCE_PASSWORD=
TEST_CS_EMAIL=cs@example.com
TEST_CS_PASSWORD=
NEXT_PUBLIC_ENV=dev
BASE_URL=http://localhost:3001
```

---

## Phase 4: 실행 + playwright-test-healer (선별 사용)

생성된 테스트를 실행해서 실패 패턴을 확인합니다.

**앱이 실행 중인 경우:**
```bash
npx playwright test e2e/[feature]/ --reporter=list 2>&1 | tail -40
```

실패 유형 분류:
- `FAIL (구현 없음)` → ✅ 정상 (TDD RED 상태). **healer 호출 금지** — 공식 healer는 고칠 수 없는 기능을 `test.skip`으로 바꿔버려 RED 신호가 사라진다. healer는 GREEN(code-writer 구현 완료) 이후의 회귀 수리에만 의미가 있다
- `FAIL (selector/타이밍 오류)` → `playwright-test-healer` 서브에이전트에 위임 (에이전트 없으면 직접 수정)
- `FAIL (auth 오류)` → .env.test 확인 필요 → 사용자에게 알림
- `PASS` → ⚠️ 이미 구현이 있거나 테스트가 너무 약함

**앱이 실행 중이 아닌 경우:**
- 테스트 파일 생성만 완료, 실행은 `npm run dev` 후 직접 수행

---

## 완료 리포트 형식

```
✅ E2E 테스트 작성 완료  [모드: 공식 Test Agents 위임 | 내장 로직]

생성된 파일:
  specs/[feature].md               (에이전트 모드 — planner 산출 테스트 계획)
  e2e/[feature]/[feature].spec.ts  (시나리오 N개)
  e2e/helpers/auth.ts              (신규 생성)
  playwright.config.ts             (신규 생성)
  .env.test                        (템플릿 생성)

테스트 케이스:
  ✓ [AC-1] 목록 렌더링
  ✓ [AC-2] 검색 필터링
  ✓ [RBAC] master 권한 확인
  ✓ [RBAC] finance 권한 제한

다음 단계:
  1. .env.test에 실제 테스트 계정 정보 입력
  2. npm run dev (앱 실행)
  3. npx playwright test e2e/[feature]/  (테스트 실행)
```
