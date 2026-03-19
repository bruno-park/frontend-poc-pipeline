---
name: msw-setup
description: Mock Service Worker(MSW)를 설치하고 API 모킹 핸들러를 설정합니다. unit-test-gen에서 axios를 모킹하는 대신 MSW를 사용할 수 있게 합니다.
---

# MSW Setup (Mock Service Worker)

단위 테스트에서 실제 API 응답처럼 동작하는 MSW 핸들러를 설정합니다.
`vi.mock('@/apis')` 방식 대신 더 현실적인 네트워크 레벨 모킹을 제공합니다.

## 트리거

- `/msw-setup` 직접 호출
- unit-test-gen 작성 중 복잡한 API 모킹이 필요한 경우

---

## Phase 1: MSW 설치

```bash
yarn add -D msw@latest
```

---

## Phase 2: 핸들러 구조 생성

### 디렉토리 구조
```
tests/
  mocks/
    handlers/
      index.ts          # 전체 핸들러 export
      [feature].ts      # 기능별 핸들러
    server.ts           # 테스트용 서버
    browser.ts          # 브라우저용 (Storybook 등)
```

### tests/mocks/server.ts
```typescript
import { setupServer } from 'msw/node'
import { handlers } from './handlers'

export const server = setupServer(...handlers)
```

### tests/mocks/handlers/index.ts
```typescript
import { http, HttpResponse } from 'msw'

export const handlers = [
  // 예시 핸들러 (각 feature별로 추가)
  http.get('/api/v1/partners', () => {
    return HttpResponse.json({
      data: [
        { id: '1', name: '테스트 파트너', status: 'ACTIVE' },
      ],
      total: 1,
    })
  }),
]
```

### vitest.setup.ts 업데이트
```typescript
import '@testing-library/jest-dom'
import { server } from './tests/mocks/server'
import { beforeAll, afterEach, afterAll } from 'vitest'

beforeAll(() => server.listen({ onUnhandledRequest: 'warn' }))
afterEach(() => server.resetHandlers())
afterAll(() => server.close())
```

---

## Phase 3: Feature별 핸들러 생성

planner.md 또는 Jira 티켓이 있을 경우, 해당 feature의 API 경로를 분석하여 핸들러 생성:

```typescript
// tests/mocks/handlers/[feature].ts
import { http, HttpResponse } from 'msw'
import type { I[Feature]Response } from '@/pageComponents/[feature]/hooks/use[Feature]Query.hook'

export const [feature]Handlers = [
  // 목록 조회
  http.get('/api/v1/[feature]', ({ request }) => {
    const url = new URL(request.url)
    const page = url.searchParams.get('page') ?? '1'

    return HttpResponse.json({
      data: [/* mock data */],
      total: 10,
      page: Number(page),
    })
  }),

  // 상세 조회
  http.get('/api/v1/[feature]/:id', ({ params }) => {
    return HttpResponse.json({
      id: params.id,
      // ... mock fields
    })
  }),

  // 에러 시뮬레이션 (테스트에서 오버라이드)
  http.get('/api/v1/[feature]/error', () => {
    return HttpResponse.json(
      { message: 'Internal Server Error' },
      { status: 500 }
    )
  }),
]
```

---

## Phase 4: 테스트에서 사용법

```typescript
// 기본 사용 (server가 자동으로 핸들러 적용)
it('파트너 목록 로드', async () => {
  render(<PartnerList />, { wrapper: createWrapper() })
  await waitFor(() => {
    expect(screen.getByText('테스트 파트너')).toBeInTheDocument()
  })
})

// 특정 테스트에서 핸들러 오버라이드
it('API 에러 처리', async () => {
  server.use(
    http.get('/api/v1/partners', () => {
      return HttpResponse.json({ message: 'Error' }, { status: 500 })
    })
  )

  render(<PartnerList />, { wrapper: createWrapper() })
  await waitFor(() => {
    expect(screen.getByText('데이터를 불러올 수 없습니다.')).toBeInTheDocument()
  })
})
```

---

## 완료 보고

```
✅ MSW 설치 완료

생성된 파일:
  tests/mocks/server.ts
  tests/mocks/handlers/index.ts

업데이트된 파일:
  vitest.setup.ts (MSW 서버 연동)

사용 방법:
  - 기본 핸들러: tests/mocks/handlers/index.ts에 추가
  - Feature별 핸들러: tests/mocks/handlers/[feature].ts 생성
  - 테스트 오버라이드: server.use(http.get(...))

다음 단계:
  /unit-test-gen WP-XXXX → MSW 핸들러 자동 생성 포함
```
