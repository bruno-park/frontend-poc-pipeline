---
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
argument-hint: [pageComponents/[feature]/planner.md] [optional-context]
description: TDD REFACTOR phase - GREEN 통과 후 프로젝트 컨벤션에 맞게 코드를 정리합니다. 테스트는 항상 GREEN 유지.
model: claude-sonnet-4-6
---

# Refactor — TDD REFACTOR Phase

**전제 조건: 모든 단위 테스트가 GREEN(통과) 상태여야 합니다.**

> ⚠️ 리팩터링 중 테스트가 RED로 돌아가면 즉시 중단하고 원복하세요.

---

## Arguments

```
/refactor pageComponents/partner/planner.md
/refactor pageComponents/partner/planner.md "URL state 방식으로 변경"
```

---

## Phase 0: 사전 검증

### 1. 테스트 GREEN 확인 (필수)

```bash
npx vitest run pageComponents/[feature] --reporter=verbose 2>&1 | tail -20
```

- 모든 테스트 PASS → 계속
- 실패 테스트 있음 → **STOP**: "GREEN 상태가 아닙니다. /ui-builder로 먼저 구현을 완성하세요."

### 2. 대상 파일 목록 파악

```
Glob: pageComponents/[feature]/**/*.tsx
Glob: pageComponents/[feature]/**/*.ts (hooks, types, constants)
```

planner.md를 읽어 구현 의도와 비교.

---

## Phase 1: 중복 & 불필요 코드 제거

### 체크리스트

| 항목 | 확인 방법 |
|------|---------|
| 사용하지 않는 import | Grep으로 import 목록 vs 실제 사용 비교 |
| 중복된 유틸 함수 | 동일 로직이 2곳 이상인지 확인 |
| 인라인 타입 → interface 분리 | 5개 초과 props는 interface로 추출 |
| TODO/FIXME 주석 처리 | Grep: TODO, FIXME |
| 콘솔 로그 제거 | Grep: console.log |

각 변경 후 즉시 테스트 실행:
```bash
npx vitest run pageComponents/[feature] 2>&1 | tail -5
```

---

## Phase 2: 프로젝트 컨벤션 준수

### 네이밍 규칙 검토

| 규칙 | 올바른 예 | 잘못된 예 |
|------|---------|---------|
| 컬렉션 postfix | `itemList`, `userMap` | `items`, `users` |
| 불리언 prefix | `isLoading`, `isOpen` | `loading`, `open` |
| 핸들러 prefix | `handleClick` | `onClick` (변수명으로) |
| 컴포넌트 arrow function | `const Comp = () => {}` | `function Comp() {}` |
| export default 분리 | 파일 마지막에 별도 export | 인라인 export default |

### 스타일링 규칙 검토

```
Grep: px (arbitrary value 사용 → rem으로 교체)
Grep: cn( (사용 금지)
Grep: <img  (Next.js Image로 교체)
Grep: style={{ (인라인 스타일 → Tailwind로 교체)
```

### shadcn/ui 사용 여부

```
Grep: className.*rounded (→ shadcn/ui Button/Badge 등으로 교체 가능한지 확인)
```

각 수정 후 테스트 실행 확인.

---

## Phase 3: React 최적화

### planner.md의 Memo 스펙 준수

planner.md에서 각 컴포넌트의 `Memo: Yes/No` 확인 후 적용:

```typescript
// Memo: Yes → export default memo(Component)
export default memo(ComponentName)

// Memo: No → export default Component
export default ComponentName
```

### useMemo / useCallback 적용 여부

| 적용 대상 | 기준 |
|---------|------|
| `useMemo` | 배열 filter/sort, 컬럼 정의, 복잡한 데이터 변환 |
| `useCallback` | memo() 래핑된 자식에게 전달되는 핸들러 |
| 불필요한 useMemo | 단순 값 할당 → 제거 |
| 불필요한 useCallback | memo 안 된 자식에게 전달 → 제거 |

각 최적화 후 테스트 실행.

---

## Phase 4: 파일 구조 정리 (co-location)

### 검토 기준

```
- 한 feature에서만 쓰는 코드가 global에 있으면 → feature 폴더로 이동
- 두 feature 이상에서 쓰는 코드가 feature에 있으면 → global로 이동
- section 내부에서만 쓰는 타입이 feature.types.ts에 있으면 → section.types.ts로 이동
```

이동 후 import 경로 업데이트 + 테스트 실행.

---

## Phase 5: 최종 GREEN 검증

```bash
npx vitest run pageComponents/[feature] --reporter=verbose 2>&1 | tail -30
```

**모든 테스트 PASS 확인 후 완료.**

---

## 완료 리포트

```
## Refactor 완료

### 변경 내역
| 파일 | 변경 내용 |
|------|---------|
| PartnerTable.tsx | useMemo 컬럼 정의 추출, console.log 제거 |
| usePartnerQuery.hook.ts | 사용하지 않는 import 제거 |
| partner.types.ts | IPartnerRow interface 추출 (props 6개) |

### 테스트 결과
Tests: 9 passed ✅

### 파이프라인 위치
[test-writer → RED] → [code-writer --ui → GREEN] → [refactor → 지금 여기] → [coverage-report] → [code-review]

### 다음 단계
/coverage-report WP-1234   → 커버리지 Jira 기록
/code-review               → 코드 리뷰
```
