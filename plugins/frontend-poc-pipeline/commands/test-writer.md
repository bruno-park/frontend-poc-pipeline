---
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
argument-hint: [--unit|--e2e|--all] [pageComponents/[feature]/planner.md]
description: TDD RED phase - planner.md 기반으로 실패하는 테스트를 먼저 작성하고 RED 상태를 검증합니다
model: claude-sonnet-4-6
---

# Test Writer — TDD RED Phase

**이 커맨드의 유일한 목적: 구현보다 먼저, 반드시 실패하는 테스트를 작성하는 것.**

> ⚠️ TDD의 철칙: 테스트가 RED(실패) 상태임을 확인하기 전까지 이 커맨드는 완료되지 않습니다.

---

## Arguments

```
/test-writer --unit pageComponents/partner/planner.md   → 단위 테스트만 작성 + RED 검증
/test-writer --e2e pageComponents/partner/planner.md    → E2E 테스트만 작성 + RED 검증
/test-writer --all pageComponents/partner/planner.md    → 단위 + E2E 순서대로 (기본값)
/test-writer --unit                                     → planner.md 자동 탐색
```

---

## Phase 0: TDD Pre-flight Check (필수)

> 이 단계를 건너뛰지 마세요. TDD 위반을 사전에 차단합니다.

### 1. planner.md 위치 확인

```
Glob: pageComponents/*/planner.md, pageComponents/*/*/planner.md
```

- 찾으면 → Read로 전체 내용 로드
- 없으면 → **STOP**: "planner.md가 없습니다. /planner 또는 /screen-plan으로 먼저 설계 문서를 작성하세요."

### 2. 구현 파일 사전 존재 체크 (TDD 위반 감지)

planner.md의 컴포넌트 경로 목록을 추출한 뒤 Glob으로 존재 여부 확인:

```
Glob: pageComponents/[feature]/components/**/*.tsx (구현 파일)
Glob: pageComponents/[feature]/hooks/**/*.hook.ts (훅 파일)
```

**판정 기준:**

| 상태 | 조치 |
|------|------|
| 파일 없음 | ✅ TDD 정상 — 계속 진행 |
| 테스트 파일(`.test.ts`)만 있음 | ✅ 이전 세션 작업 — 계속 진행 |
| 구현 파일(`.tsx`, `.hook.ts`)이 이미 있음 | ⚠️ **TDD 위반 경고** 출력 후 사용자 확인 |

**TDD 위반 경고 출력 형식:**
```
⚠️  TDD 위반 감지

이미 구현 파일이 존재합니다:
  - pageComponents/partner/components/table/PartnerTable.tsx
  - pageComponents/partner/hooks/usePartnerQuery.hook.ts

TDD 원칙: 테스트는 구현보다 먼저 작성되어야 합니다.

선택하세요:
  1. 계속 진행 (기존 구현에 맞는 테스트 작성 — TDD 아님, 커버리지 추가)
  2. 중단 (구현 파일을 제거 후 다시 실행)
```

사용자가 계속 진행 선택 시 → 진행하되 완료 리포트에 ⚠️ 표시

### 3. planner.md에서 AC 및 테스트 컨텍스트 추출

planner.md를 Read로 로드한 뒤, 다음 섹션을 순서대로 파싱:

| 섹션 | 추출 내용 | 용도 |
|------|---------|------|
| **PRD Context / User Stories** | Acceptance Criteria 항목 (AC-1, AC-2...) | 테스트 케이스 매핑의 핵심 소스 |
| **Component Details** | 컴포넌트별 Props, State, Data Fetching, UI States | 단위 테스트 대상 및 mock 구조 결정 |
| **Validation Rules** | RULE-XX, 필드별 제약, 에러 메시지 | 폼 유효성 테스트 케이스 |
| **URL State** | Schema (key, type, default, trigger) | URL 상태 동기화 테스트 |
| **PRD Field → Component Mapping** | 필드-컴포넌트 매핑, RBAC 정보 | 역할별 시나리오, 조건부 렌더링 테스트 |
| **TBD / Open Questions** | 미결 항목 | 테스트 제외 범위 명시 (완료 리포트에 기록) |

**AC가 명시적으로 없는 경우:**
- 컴포넌트의 Purpose, Props, UI States에서 테스트 케이스를 자동 도출
- 도출 근거를 매핑 테이블에 명시 (예: "AC 없음 → Component Purpose에서 도출")

---

## Phase 1: AC → 테스트 케이스 매핑 테이블

planner.md의 AC, Validation Rules, Component Spec을 분석하여 테스트 케이스 목록을 먼저 계획합니다.

### 매핑 규칙

| AC 항목 유형 | 생성할 테스트 케이스 |
|-------------|-----------------|
| 목록 렌더링 | 데이터 있을 때 렌더링, 빈 상태, 로딩 스켈레톤 |
| 검색/필터 | 입력 시 API 파라미터 변경, URL 상태 업데이트 |
| CRUD 버튼 | 역할별 표시/숨김 (master/finance/CS) |
| 폼 제출 | 성공 케이스, 유효성 에러, API 에러 |
| 권한 분기 | 각 역할별 시나리오 |

### 매핑 테이블 출력 (필수)

```
## 테스트 계획

| # | 대상 | 테스트 케이스 | 분류 | AC 연결 | 파일 |
|---|------|------------|------|---------|------|
| 1 | PartnerTable | 데이터 로드 시 행 렌더링 | happy | AC-1 | PartnerTable.test.tsx |
| 2 | PartnerTable | 빈 상태 컴포넌트 표시 | edge | - | PartnerTable.test.tsx |
| 3 | PartnerTable | 로딩 시 스켈레톤 표시 | edge | - | PartnerTable.test.tsx |
| 4 | PartnerTable | master만 생성 버튼 표시 | rbac | AC-3 | PartnerTable.test.tsx |
| 5 | usePartnerQuery | 데이터 페칭 성공 | happy | AC-1 | usePartnerQuery.hook.test.ts |
| 6 | usePartnerQuery | id 없으면 쿼리 비활성화 | edge | - | usePartnerQuery.hook.test.ts |
```

**커버리지 체크:**
- AC 항목 총 N개 → 테스트 케이스 매핑 완료 여부 확인
- 매핑 안 된 AC 항목이 있으면 → 테스트 케이스 추가 후 진행

---

## Phase 2: 단위 테스트 작성 (--unit 또는 --all)

> `unit-test-gen` 스킬 가이드를 따르되, TDD RED 검증이 필수입니다.

### Step 1. 프로젝트 테스트 설정 확인

```
Glob: vitest.config.ts, vitest.config.js, vite.config.ts
Glob: **/*.test.tsx (최근 3개 → 패턴 파악)
Grep: renderWithProviders, createWrapper, @testing-library/react
```

기존 헬퍼 패턴이 있으면 반드시 재사용.

### Step 2. 테스트 파일 생성

Phase 1 매핑 테이블 기준으로 파일별 테스트 작성.

**파일 위치 규칙:**
```
컴포넌트 구현 예정: pageComponents/[feature]/components/[section]/Component.tsx
테스트 파일 위치:  pageComponents/[feature]/components/[section]/Component.test.tsx

훅 구현 예정: pageComponents/[feature]/hooks/useFeature.hook.ts
테스트 파일 위치: pageComponents/[feature]/hooks/useFeature.hook.test.ts
```

**테스트 파일 구조:**

```typescript
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'

// 구현 파일 import — 아직 존재하지 않으므로 RED 상태
import ComponentName from './ComponentName'

const createWrapper = () => {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  })
  return ({ children }: { children: React.ReactNode }) => (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  )
}

describe('ComponentName', () => {
  describe('정상 케이스', () => {
    it('[AC-1] 데이터 로드 시 목록이 렌더링된다', async () => {
      // Arrange: mock data
      // Act: render
      // Assert: expect items to be visible
    })
  })

  describe('예외 케이스', () => {
    it('데이터 없을 때 빈 상태 메시지 표시', () => { /* ... */ })
    it('로딩 중 스켈레톤 표시', () => { /* ... */ })
    it('API 에러 시 에러 메시지 표시', () => { /* ... */ })
  })

  describe('RBAC', () => {
    it('master 역할은 생성 버튼이 표시된다', () => { /* ... */ })
    it('finance 역할은 생성 버튼이 숨겨진다', () => { /* ... */ })
    it('CS 역할은 생성 버튼이 숨겨진다', () => { /* ... */ })
  })
})
```

**금지 사항:**
- `data-testid` 셀렉터 사용 금지 (이 프로젝트에 없음)
- 여러 동작을 하나의 `it`에 묶지 않기
- 구현 세부사항 테스트 금지 (className, 내부 state 직접 접근)

### Step 3. RED 상태 검증 (필수)

테스트 파일 작성 완료 후 즉시 실행:

```bash
npx vitest run pageComponents/[feature] --reporter=verbose 2>&1 | tail -40
```

**판정:**

| 결과 | 판정 | 조치 |
|------|------|------|
| 모든 테스트 FAIL (import 오류 포함) | ✅ RED 정상 | 완료 |
| 일부 테스트 PASS | ⚠️ 테스트 약함 | 해당 테스트 강화 후 재검증 |
| 모든 테스트 PASS | ❌ TDD 위반 | **STOP**: 구현이 먼저 작성된 것 → 사용자에게 알림 |

> **PASS가 나오면 테스트를 더 구체적으로 만들어야 합니다.**
> 예: `expect(screen.getByText('파트너명')).toBeInTheDocument()` 처럼
> 실제 데이터가 없으면 실패하는 단언문으로 교체

---

## Phase 3: E2E 테스트 작성 (--e2e 또는 --all)

> `e2e-test-gen` 스킬 가이드를 따르되, TDD RED 검증이 필수입니다.

### Step 1. Playwright 인프라 확인

```
Glob: playwright.config.ts → 없으면 생성
Glob: e2e/helpers/auth.ts → 없으면 생성
Glob: .env.test → 없으면 템플릿 생성
```

없는 파일은 아래 형식으로 생성:

**playwright.config.ts:**
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

**e2e/helpers/auth.ts:**
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

  await page.goto('/login')
  await page.getByPlaceholder('아이디(이메일)').fill(credentials[role].email)
  await page.getByPlaceholder('비밀번호').fill(credentials[role].password)
  await page.getByRole('button', { name: '로그인' }).click()
  await page.waitForURL(roleHome[role])
}
```

**.env.test 템플릿:**
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

### Step 2. E2E 테스트 파일 생성

Phase 1 매핑 테이블의 E2E 시나리오 기준으로 작성.

**파일 위치:** `e2e/[feature]/[feature].spec.ts`

```typescript
import { test, expect } from '@playwright/test'
import { loginAs } from '../helpers/auth'

test.describe('[Feature명] E2E', () => {
  test.beforeEach(async ({ page }) => {
    await loginAs(page, 'master')
    await page.goto('/[route]')
    await page.waitForResponse('**/api/v1/[endpoint]**')
  })

  // AC 항목별 시나리오
  test('[AC-1] 목록이 정상 렌더링된다', async ({ page }) => {
    await expect(page.locator('tbody tr')).not.toHaveCount(0)
  })

  test('[AC-2] 검색 시 URL query param이 업데이트된다', async ({ page }) => {
    await page.fill('[placeholder*="검색"]', '테스트')
    await page.waitForTimeout(500)
    await expect(page).toHaveURL(/search=테스트/)
  })
})

// RBAC 시나리오
const roleMatrix = [
  { role: 'master' as const, canCreate: true },
  { role: 'finance' as const, canCreate: false },
  { role: 'CS' as const, canCreate: false },
]

for (const { role, canCreate } of roleMatrix) {
  test(`[RBAC] ${role} - 생성 버튼 ${canCreate ? '표시' : '숨김'}`, async ({ page }) => {
    await loginAs(page, role)
    await page.goto('/[route]')
    const createBtn = page.getByRole('button', { name: '생성' })
    if (canCreate) {
      await expect(createBtn).toBeVisible()
    } else {
      await expect(createBtn).not.toBeVisible()
    }
  })
}
```

### Step 3. RED 상태 검증

**앱이 실행 중인 경우:**
```bash
npx playwright test e2e/[feature]/ --reporter=list 2>&1 | tail -40
```

**앱이 실행 중이 아닌 경우:**
- 테스트 파일 생성 완료, 실행은 `npm run dev` 후 직접 수행
- 완료 리포트에 "앱 실행 후 RED 검증 필요" 명시

**판정:**

| 결과 | 판정 |
|------|------|
| FAIL (구현 없음 / 페이지 없음) | ✅ RED 정상 |
| FAIL (selector 오류) | 🔧 셀렉터 수정 후 재검증 |
| FAIL (auth 오류) | ⚠️ .env.test 계정 정보 입력 필요 → 사용자에게 알림 |
| PASS | ❌ TDD 위반 → 테스트 강화 |

---

## Phase 4: 완료 리포트

### 리포트 형식

```
## Test Writer 완료 리포트

### TDD 상태
[✅ 정상 TDD | ⚠️ 주의사항 있음]

### 테스트 파일
| 파일 | 테스트 수 | RED 확인 |
|------|---------|---------|
| PartnerTable.test.tsx | 6개 | ✅ |
| usePartnerQuery.hook.test.ts | 3개 | ✅ |
| e2e/partner/partner.spec.ts | 5개 | ✅ (앱 실행 중) |

### AC 커버리지
| AC 항목 | 테스트 케이스 | 상태 |
|---------|------------|------|
| AC-1 목록 렌더링 | #1 정상 렌더링, #2 빈 상태 | ✅ |
| AC-2 검색 필터 | #4 URL 업데이트 | ✅ |
| AC-3 RBAC 버튼 | #5 master 표시, #6 finance 숨김, #7 CS 숨김 | ✅ |

### RED 증거
```
FAIL  pageComponents/partner/components/table/PartnerTable.test.tsx
  × [AC-1] 데이터 로드 시 목록이 렌더링된다 (Cannot find module './PartnerTable')
  × 빈 상태 컴포넌트 표시 (Cannot find module './PartnerTable')
  ...
Tests: 9 failed, 0 passed
```

### 다음 단계
1. 구현 시작: `/code-writer pageComponents/partner/planner.md`
2. GREEN 목표: 모든 단위 테스트 PASS
3. E2E 실행: `npm run dev` 후 `npx playwright test e2e/partner/`
```

---

## 합격 기준 (관리자 검증 통과 조건)

| 항목 | 기준 | 확인 |
|------|------|------|
| AC 커버리지 | planner.md AC 항목 100% 테스트로 커버 | Phase 1 매핑 테이블 |
| 예외 케이스 | 에러/빈 상태/권한 없음/로딩 상태 포함 | Phase 2 테스트 구조 |
| RED 상태 | 단위 테스트 전체 FAIL (구현 코드 없음) | Phase 2 Step 3 |
| RBAC | master/finance/CS 역할별 시나리오 포함 | Phase 1 매핑 테이블 |
| 셀렉터 규칙 | `data-testid` 셀렉터 사용 없음 | 코드 리뷰 |

---

## 아키텍처 위치

```
[1단계] /planner or /screen-plan  → planner.md 생성
[2단계] /api-integration           → React Query 훅 타입 생성
[3단계] /test-writer  ← 지금 여기  → 테스트 코드 (RED)
[4단계] /code-writer or /ui-builder → 구현 코드 (GREEN)
[5단계] 리팩터링                   → 테스트 유지하며 정리
```
