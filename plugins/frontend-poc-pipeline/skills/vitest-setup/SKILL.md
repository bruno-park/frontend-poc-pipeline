---
name: vitest-setup
description: Next.js Pages Router 프로젝트에 Vitest + React Testing Library를 설치하고 설정합니다. 기존 jest.setup.js가 있는 경우 마이그레이션합니다.
---

# Vitest Setup

Next.js Pages Router + TypeScript 프로젝트에 Vitest 테스트 인프라를 완전히 설치합니다.

## 트리거

- `/vitest-setup` 직접 호출
- unit-test-gen 실행 시 vitest 미설치 감지

---

## Phase 1: 현재 상태 확인

### 기존 테스트 설정 파악 (병렬 실행)
```
Bash: cat package.json | grep -E "jest|vitest|testing-library"
Glob: jest.config.*, jest.setup.*, vitest.config.*
Glob: **/*.test.ts, **/*.spec.ts (최대 5개)
```

분기:
- **jest.setup.js 있음** → 마이그레이션 모드 (Phase 2B)
- **아무것도 없음** → 신규 설치 모드 (Phase 2A)
- **vitest 있음** → "이미 설치됨" 안내 후 config 점검만

---

## Phase 2A: 신규 설치

### 패키지 설치
```bash
yarn add -D vitest @vitest/coverage-v8 @testing-library/react @testing-library/user-event @testing-library/jest-dom jsdom
```

### vitest.config.ts 생성 (프로젝트 루트)

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config'
import path from 'path'

export default defineConfig({
  test: {
    environment: 'jsdom',
    setupFiles: ['./vitest.setup.ts'],
    globals: true,
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html', 'lcov'],
      thresholds: {
        statements: 80,
        branches: 80,
        functions: 80,
        lines: 80,
      },
      exclude: [
        'node_modules/**',
        'pages/**',          // Next.js pages는 E2E로 커버
        '**/*.d.ts',
        '**/*.config.*',
        'coverage/**',
      ],
    },
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, '.'),
    },
  },
})
```

### vitest.setup.ts 생성 (프로젝트 루트)

```typescript
// vitest.setup.ts
import '@testing-library/jest-dom'
```

### package.json scripts 추가

```json
{
  "scripts": {
    "test": "vitest run",
    "test:watch": "vitest",
    "test:coverage": "vitest run --coverage",
    "test:ui": "vitest --ui"
  }
}
```

### tsconfig.json 수정 (types 추가)

```json
{
  "compilerOptions": {
    "types": ["vitest/globals", "@testing-library/jest-dom"]
  }
}
```

---

## Phase 2B: Jest → Vitest 마이그레이션

기존 jest.setup.js가 있는 경우:

### 1. 기존 파일 분석
```
Read: jest.setup.js
Read: jest.config.js (있으면)
```

### 2. 변환 규칙

| Jest | Vitest |
|------|--------|
| `jest.fn()` | `vi.fn()` |
| `jest.mock()` | `vi.mock()` |
| `jest.spyOn()` | `vi.spyOn()` |
| `jest.clearAllMocks()` | `vi.clearAllMocks()` |
| `@jest/globals` import 필요 없음 | `vitest` import |

### 3. vitest.setup.ts에 기존 jest.setup.js 내용 통합

---

## Phase 3: 설치 검증

```bash
# 설치 확인
npx vitest --version

# 간단한 smoke 테스트
echo "import { describe, it, expect } from 'vitest'
describe('setup', () => {
  it('works', () => expect(1 + 1).toBe(2))
})" > /tmp/smoke.test.ts

npx vitest run /tmp/smoke.test.ts
rm /tmp/smoke.test.ts
```

---

## 완료 보고

```
✅ Vitest 설치 완료

설치된 패키지:
  vitest
  @vitest/coverage-v8
  @testing-library/react
  @testing-library/user-event
  @testing-library/jest-dom
  jsdom

생성된 파일:
  vitest.config.ts
  vitest.setup.ts

추가된 스크립트:
  yarn test          → 단위 테스트 실행
  yarn test:watch    → watch 모드
  yarn test:coverage → 커버리지 측정

다음 단계:
  /unit-test-gen WP-XXXX → 테스트 작성 시작
```
