# Unit Test Generator — Web (Jest 또는 Vitest + React Testing Library)

`planner.md`의 컴포넌트 스펙과 Jira 수용 기준을 분석하여 **구현 전에 실패하는 단위 테스트**를 작성합니다.

> **러너 비종속**: 프로젝트에 설정된 러너(Jest/Vitest)를 그대로 따른다. 감지·실행·파일 작성 규칙은 `conventions` 스킬 §13(Test Runner Detection & Adaptation)을 단일 기준으로 한다. 아래 템플릿은 Vitest 예시이며, **Jest 프로젝트면 §13.3 표대로 치환**한다.

## 트리거

- `/test-writer --unit` 호출 시
- `/test-writer --all` 호출 시 (Phase 1)

## 입력 컨텍스트

- `planner.md` 내용 (컴포넌트 구조, props, state, hooks)
- Jira AC 목록 (있을 경우)
- 현재 프로젝트 루트

---

## Phase 0: 테스트 러너 감지 (§13.1)

### 0-1. 러너 확인
```
Bash: cat package.json | grep -E "vitest|jest|@testing-library"
Glob: jest.config.*, vitest.config.*, vite.config.ts
```

| 감지 결과 | 조치 |
|----------|------|
| **Jest** (jest.config.* / next/jest / deps에 jest) | Jest로 진행 — 템플릿을 §13.3 표대로 치환 (`vi.*`→`jest.*`, vitest import 제거) |
| **Vitest** (vitest.config.* / vite test 블록 / deps에 vitest) | Vitest로 진행 — 아래 템플릿 그대로 |
| **없음** | 설치 안내(opt-in, 아래) 후 테스트 파일은 미리 작성 |

**둘 다 없을 때만** 다음 안내 (이미 Jest가 있으면 마이그레이션하지 않는다, §13.4):

---
⚠️ **테스트 러너가 설치되지 않았습니다.** 파이프라인 기본값은 Vitest입니다.
`/vitest-setup` 스킬을 먼저 실행하거나, 아래 명령어로 직접 설치하세요:

```bash
yarn add -D vitest @vitest/coverage-v8 @testing-library/react @testing-library/user-event @testing-library/jest-dom jsdom
# vitest.config.ts 생성 → /vitest-setup 스킬이 자동 생성합니다
```

테스트 파일은 미리 작성해드릴게요. 설치 후 바로 실행 가능합니다.

---

---

## Phase 1: 프로젝트 설정 확인

### 1. 러너 설정 파일 확인
```
Glob: jest.config.*, vitest.config.*, vite.config.ts
```
- 없으면 → 사용자에게 알림 후 진행 (테스트 파일만 생성)

### 2. 기존 테스트 패턴 파악
```
Glob: **/*.test.ts, **/*.test.tsx, **/*.spec.ts
최근 3개 파일 Read → 러너(Jest/Vitest), import 방식, 모킹 API, 유틸 확인
```

### 3. 테스트 유틸 확인
```
Grep: @testing-library/react, renderWithProviders, createWrapper
→ 기존 헬퍼가 있으면 재사용
```

---

## Phase 2: planner.md 분석 → 테스트 대상 추출

planner.md에서 다음을 추출:

### 컴포넌트별 테스트 대상
```
각 컴포넌트에서:
- Props → prop validation 테스트
- State → state 변화 테스트
- Data Fetching → React Query mock 테스트
- 조건부 렌더링 → 분기 테스트
- 이벤트 핸들러 → 인터랙션 테스트
```

### Jira AC → 테스트 케이스 매핑
```
AC 항목 1 → 테스트 케이스 1개 이상
예외 케이스 → 에러/빈 상태/권한 없음 테스트
```

---

## Phase 3: 테스트 파일 생성

### 파일 위치 규칙
```
컴포넌트: pageComponents/[feature]/components/[section]/Component.tsx
테스트:   pageComponents/[feature]/components/[section]/Component.test.tsx

훅: pageComponents/[feature]/hooks/useFeature.hook.ts
테스트: pageComponents/[feature]/hooks/useFeature.hook.test.ts
```

### 테스트 파일 구조 (Vitest 예시 — Jest면 §13.3 치환: import 제거 + `vi`→`jest`)

```typescript
import { describe, it, expect, vi, beforeEach } from 'vitest' // Jest: 제거(전역), vi → jest
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'

// 테스트 대상 import (아직 구현 안 됨 → RED 상태)
import ComponentName from './ComponentName'

// React Query 래퍼
const createWrapper = () => {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  })
  return ({ children }: { children: React.ReactNode }) => (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  )
}

describe('ComponentName', () => {
  // Happy path
  describe('정상 케이스', () => {
    it('[AC 항목] - [기대 동작]', async () => {
      // Arrange
      // Act
      // Assert
    })
  })

  // Edge cases
  describe('예외 케이스', () => {
    it('데이터 없을 때 빈 상태 표시', () => { ... })
    it('로딩 중 스켈레톤 표시', () => { ... })
    it('API 에러 시 에러 메시지 표시', () => { ... })
  })

  // RBAC (권한이 있는 경우)
  describe('권한 테스트', () => {
    it('권한 없는 역할은 버튼 미표시', () => { ... })
  })
})
```

### React Query Hook 테스트 구조

```typescript
import { renderHook, waitFor } from '@testing-library/react'
import { vi } from 'vitest' // Jest: 이 줄 제거 (전역 jest 사용)
import axios from '@/apis'

vi.mock('@/apis')          // Jest: jest.mock('@/apis')
const mockAxios = vi.mocked(axios) // Jest: jest.mocked(axios)

describe('useFeatureQuery', () => {
  it('데이터 페칭 성공', async () => {
    mockAxios.get.mockResolvedValue({ data: { id: '1', name: 'test' } })

    const { result } = renderHook(() => useFeatureQuery('1'), {
      wrapper: createWrapper(),
    })

    await waitFor(() => expect(result.current.isSuccess).toBe(true))
    expect(result.current.data).toEqual({ id: '1', name: 'test' })
  })

  it('id 없으면 쿼리 비활성화', () => {
    const { result } = renderHook(() => useFeatureQuery(undefined), {
      wrapper: createWrapper(),
    })
    expect(result.current.fetchStatus).toBe('idle')
  })
})
```

---

## Phase 4: 테스트 케이스 목록 (표 형식)

각 컴포넌트에 대해 아래 형식으로 테스트 케이스 목록 작성:

| # | 컴포넌트 | 테스트 케이스 | 분류 | AC 연결 |
|---|---------|------------|------|---------|
| 1 | ComponentA | 정상 렌더링 | happy | AC-1 |
| 2 | ComponentA | 빈 상태 표시 | edge | - |
| 3 | ComponentA | 로딩 스켈레톤 | edge | - |

---

## Phase 5: RED 상태 검증

테스트 파일 작성 후 (`$TEST_CMD`, §13.2 — `scripts.test` 직접 실행 금지):

```bash
# Jest:   npx jest [생성된 파일] 2>&1 | tail -30
# Vitest: npx vitest run [생성된 파일] --reporter=verbose 2>&1 | tail -30
```

**기대 결과**: 모든 테스트 FAIL (구현이 없으므로)

- FAIL → 정상 (TDD RED 상태)
- PASS → 이미 구현이 있거나 테스트가 잘못됨 → 사용자에게 알림

---

## 테스트 작성 원칙

### DO
- `describe` 블록으로 happy path / edge case / RBAC 분리
- 각 `it`은 하나의 동작만 검증
- `waitFor`로 비동기 상태 검증
- `vi.mock`으로 외부 의존성 격리
- AC 항목마다 최소 1개 테스트

### DON'T
- 구현 세부사항 테스트 금지 (className, 내부 state 직접 접근)
- `setTimeout`/`sleep` 사용 금지 → `waitFor` 사용
- 여러 동작을 하나의 `it`에 넣지 않기
- `data-testid` 셀렉터 사용 금지 (이 프로젝트에 없음)
