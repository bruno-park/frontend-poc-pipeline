# E2E Test Generator — Web (Playwright)

`planner.md`와 Jira 수용 기준을 기반으로 **Playwright E2E 테스트를 먼저 작성**합니다.
프로젝트의 `agents/` 디렉토리에 있는 Playwright 전용 에이전트 3종을 체이닝합니다.

## 트리거

- `/test-writer --e2e` 호출 시
- `/test-writer --all` 호출 시 (Phase 2)

## 입력 컨텍스트

- `planner.md` 내용 (컴포넌트, URL 상태, 데이터 흐름)
- Jira AC 목록 (있을 경우)
- 앱 로컬 URL (기본값: `http://localhost:3001`)

---

## Phase 0: Playwright 인프라 확인

### 1. 필수 파일 확인 (Glob)
```
playwright.config.ts  → 없으면 Phase 1에서 생성 지시
e2e/                  → 없으면 mkdir
e2e/helpers/auth.ts   → 없으면 Phase 2에서 생성
.env.test             → 없으면 템플릿 생성
```

### 2. 프로젝트 playwright agents 확인
```
Glob: agents/*playwright*.md
```
- 찾으면 → 해당 에이전트 파일 경로 기억
- 없으면 → 이 스킬 내장 로직으로 직접 실행

---

## Phase 1: playwright-test-planner 호출

### 에이전트 존재 시
`agents/[project]-playwright-test-planner.md` 에이전트에 위임:

**전달 컨텍스트:**
```
다음 planner.md를 기반으로 E2E 테스트 계획을 수립해주세요.

[planner.md 전체 내용]

Jira AC:
[AC 항목 목록]

테스트 우선순위:
1. 인증/권한 (로그인, RBAC)
2. 핵심 CRUD 플로우
3. URL 상태 동기화 (해당 시)
4. 예외 케이스 (빈 상태, 에러, 권한 없음)
```

### 에이전트 없을 시 (내장 로직)

planner.md에서 직접 E2E 시나리오 추출:

| 시나리오 | 역할 | 사전조건 | 단계 | 기대결과 |
|---------|------|---------|------|---------|
| 목록 로드 | master | 로그인 | 페이지 이동 | 테이블 렌더링 |
| 검색 필터 | master | 로그인 | 검색어 입력 | URL 업데이트 |
| 생성 CRUD | master | 로그인 | 버튼 클릭→폼→저장 | 목록 갱신 |
| 권한 차단 | finance | 로그인 | 버튼 확인 | 버튼 미표시 |

---

## Phase 2: playwright-test-generator 호출

### 에이전트 존재 시
`agents/[project]-playwright-test-generator.md` 에이전트에 위임:

**전달 컨텍스트:**
```
Phase 1에서 수립된 테스트 계획을 기반으로 E2E 테스트 코드를 생성해주세요.

테스트 계획:
[Phase 1 결과]

생성 규칙:
- 파일 위치: e2e/[feature]/[scenario].spec.ts
- auth helper: e2e/helpers/auth.ts 사용
- data-testid 셀렉터 사용 금지
- 역할별 테스트 포함 (master/finance/CS)
```

### 에이전트 없을 시 (내장 로직)

직접 테스트 코드 생성:

```typescript
// e2e/[feature]/[feature].spec.ts
import { test, expect } from '@playwright/test'
import { loginAs } from '../helpers/auth'

test.describe('[Feature명] - [AC 항목]', () => {
  test.beforeEach(async ({ page }) => {
    await loginAs(page, 'master')
    await page.goto('http://localhost:3001/[route]')
    await page.waitForResponse('**/api/v1/[endpoint]**')
  })

  // AC 항목별 테스트
  test('[AC-1] 목록이 정상 렌더링된다', async ({ page }) => {
    await expect(page.locator('tbody tr')).not.toHaveCount(0)
  })

  test('[AC-2] 검색 시 URL query param이 업데이트된다', async ({ page }) => {
    await page.fill('[placeholder*="검색"]', '테스트')
    await page.waitForTimeout(500) // debounce
    await expect(page).toHaveURL(/search=테스트/)
  })
})

// 권한 테스트
const roleMatrix = [
  { role: 'master' as const, canCreate: true },
  { role: 'finance' as const, canCreate: false },
  { role: 'CS' as const, canCreate: false },
]

for (const { role, canCreate } of roleMatrix) {
  test(`[RBAC] ${role} 역할 - 생성 버튼 ${canCreate ? '표시' : '숨김'}`, async ({ page }) => {
    await loginAs(page, role)
    await page.goto('http://localhost:3001/[route]')
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

## Phase 4: playwright-test-healer 대기

생성된 테스트를 실행해서 실패 패턴을 확인합니다.

**앱이 실행 중인 경우:**
```bash
npx playwright test e2e/[feature]/ --reporter=list 2>&1 | tail -40
```

실패 유형 분류:
- `FAIL (구현 없음)` → 정상 (TDD RED 상태)
- `FAIL (selector 오류)` → playwright-test-healer 호출
- `FAIL (auth 오류)` → .env.test 확인 필요 → 사용자에게 알림
- `PASS` → 이미 구현이 있거나 테스트가 너무 약함

**앱이 실행 중이 아닌 경우:**
- 테스트 파일 생성만 완료, 실행은 `npm run dev` 후 직접 수행

---

## 완료 리포트 형식

```
E2E 테스트 작성 완료

생성된 파일:
  e2e/[feature]/[feature].spec.ts  (시나리오 N개)
  e2e/helpers/auth.ts              (신규 생성)
  playwright.config.ts             (신규 생성)
  .env.test                        (템플릿 생성)

테스트 케이스:
  [AC-1] 목록 렌더링
  [AC-2] 검색 필터링
  [RBAC] master 권한 확인
  [RBAC] finance 권한 제한

다음 단계:
  1. .env.test에 실제 테스트 계정 정보 입력
  2. npm run dev (앱 실행)
  3. npx playwright test e2e/[feature]/  (테스트 실행)
```
