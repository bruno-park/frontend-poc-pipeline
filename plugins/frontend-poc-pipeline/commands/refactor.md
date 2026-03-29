---
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
argument-hint: [pageComponents/[feature]/planner.md] [optional-context]
description: TDD REFACTOR phase - GREEN 통과 후 프로젝트 컨벤션에 맞게 코드를 정리합니다. 테스트는 항상 GREEN 유지.
model: claude-sonnet-4-6
---

# Refactor — TDD REFACTOR Phase

**전제 조건: 모든 테스트(단위 + E2E)가 GREEN(통과) 상태여야 합니다.**

> 리팩터링 중 테스트가 RED로 돌아가면 즉시 중단하고 원복하세요.

> **컨벤션 참조**: 네이밍, 스타일링, shadcn/ui, 컴포넌트 정의, 훅 패턴, co-location 규칙은 `conventions` 스킬을 기준으로 검토합니다.

---

## Arguments

```
/refactor pageComponents/partner/planner.md
/refactor pageComponents/partner/planner.md "URL state 방식으로 변경"
```

---

## Phase 0: 사전 검증

### 1. 단위 테스트 GREEN 확인 (필수)

```bash
npx vitest run pageComponents/[feature] --reporter=verbose 2>&1 | tail -20
```

- 모든 테스트 PASS → 계속
- 실패 테스트 있음 → **STOP**: "GREEN 상태가 아닙니다. /ui-builder로 먼저 구현을 완성하세요."

### 2. E2E 테스트 존재 확인 및 GREEN 검증

**2-1. E2E 파일 존재 확인:**
```
Glob: e2e/[feature]/**/*.spec.ts
```

- E2E 파일 없음 → 단위 테스트만으로 진행 (이하 E2E 단계 스킵)
- E2E 파일 있음 → 2-2로 진행

**2-2. Playwright 설치 확인:**
```bash
npx playwright --version 2>&1 | head -1
```

- 버전 출력됨 → 2-3으로 진행
- 에러 (미설치) → 사용자에게 알림: "Playwright가 설치되지 않았습니다. `npx playwright install`로 설치하거나, E2E 검증 없이 진행합니다." → 단위 테스트만으로 진행

**2-3. 앱 실행 여부 확인:**
```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:3001 2>/dev/null || echo "NOT_RUNNING"
```

| 결과 | 조치 |
|------|------|
| HTTP 200 (앱 실행 중) | Playwright 실행으로 GREEN 확인 (필수) |
| NOT_RUNNING (앱 미실행) | 사용자에게 안내: "`npm run dev` 후 E2E 검증이 필요합니다." → 완료 리포트에 "E2E 검증 보류" 명시 |

**2-4. E2E GREEN 확인 (앱 실행 중인 경우):**
```bash
npx playwright test e2e/[feature]/ --reporter=list 2>&1 | tail -20
```

- 모든 테스트 PASS → 계속
- 실패 테스트 있음 → **STOP**: "E2E GREEN 상태가 아닙니다. 구현을 먼저 완성하세요."

### 3. 대상 파일 목록 파악

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
| 인라인 타입 → interface 분리 | 6개 이상 props는 interface로 추출 (conventions: Component Definition Pattern) |
| TODO/FIXME 주석 처리 | Grep: TODO, FIXME |
| 콘솔 로그 제거 | Grep: console.log |

각 변경 후 즉시 단위 테스트 실행 (E2E는 Phase 5에서 최종 검증):
```bash
npx vitest run pageComponents/[feature] 2>&1 | tail -5
```

---

## Phase 2: 프로젝트 컨벤션 준수

> **기준**: `conventions` 스킬의 전체 규칙을 기준으로 검토합니다.

### 검토 체크리스트

- [ ] **네이밍 규칙** (conventions: Naming Conventions)
  - 컬렉션 postfix (`itemList`, `userMap`), 불리언 prefix (`isLoading`), 핸들러 prefix (`handleClick`)
  - 컴포넌트 arrow function + 파일 마지막 export default 분리
- [ ] **스타일링 규칙** (conventions: Styling Pattern)
  - `px` → `rem` 교체, `cn()` 사용 금지, `<img>` → Next.js Image, 인라인 style 금지
- [ ] **shadcn/ui 사용** (conventions: UI Component Library)
  - 커스텀 컴포넌트 대신 shadcn/ui 사용 가능한지 확인
- [ ] **co-location** (conventions: Co-location Rules)
  - feature에서만 쓰는 코드가 global에 있으면 이동, 반대도 확인

### Grep 검증 명령

```
Grep: px (arbitrary value 사용 → rem으로 교체)
Grep: cn( (사용 금지)
Grep: <img  (Next.js Image로 교체)
Grep: style={{ (인라인 스타일 → Tailwind로 교체)
```

각 수정 후 단위 테스트 실행 확인 (E2E는 Phase 5에서 최종 검증).

---

## Phase 3: React 최적화

> **기준**: `conventions` 스킬의 "Component Type Guidelines" 섹션을 따릅니다.

### planner.md의 Memo 스펙 준수

planner.md에서 각 컴포넌트의 `Memo: Yes/No` 확인 후 적용:

```typescript
// Memo: Yes → export default memo(Component)
export default memo(ComponentName)

// Memo: No → export default Component
export default ComponentName
```

### useMemo / useCallback 적용 여부

- `useMemo`: 배열 filter/sort, 컬럼 정의, 복잡한 데이터 변환에 적용
- `useCallback`: memo() 래핑된 자식에게 전달되는 핸들러에 적용
- 불필요한 useMemo (단순 값 할당) → 제거
- 불필요한 useCallback (memo 안 된 자식에게 전달) → 제거

각 최적화 후 단위 테스트 실행 (E2E는 Phase 5에서 최종 검증).

---

## Phase 4: 파일 구조 정리 (co-location)

> **기준**: `conventions` 스킬의 "Co-location Rules" 섹션을 따릅니다.

### 검토 기준

```
- 한 feature에서만 쓰는 코드가 global에 있으면 → feature 폴더로 이동
- 두 feature 이상에서 쓰는 코드가 feature에 있으면 → global로 이동
- section 내부에서만 쓰는 타입이 feature.types.ts에 있으면 → section.types.ts로 이동
```

이동 후 import 경로 업데이트 + 단위 테스트 실행.

> **E2E 주의**: 파일을 이동하면 E2E 테스트(`e2e/[feature]/**/*.spec.ts`)의 import 경로나 selector도 영향받을 수 있습니다. E2E 파일이 존재하면 Grep으로 이동된 파일명이 E2E에서 참조되는지 확인하세요.

---

## Phase 5: 최종 GREEN 검증

### 1. 단위 테스트

```bash
npx vitest run pageComponents/[feature] --reporter=verbose 2>&1 | tail -30
```

**모든 단위 테스트 PASS 확인.**

### 2. E2E 테스트 (E2E 파일이 존재하는 경우)

**2-1. E2E 파일 재확인:**
```
Glob: e2e/[feature]/**/*.spec.ts
```

- E2E 파일 없음 → 단위 테스트만으로 완료
- E2E 파일 있음 → 2-2로 진행

**2-2. 앱 실행 확인 + E2E 실행:**
```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:3001 2>/dev/null || echo "NOT_RUNNING"
```

앱 실행 중인 경우:
```bash
npx playwright test e2e/[feature]/ --reporter=list 2>&1 | tail -20
```

| 결과 | 판정 | 조치 |
|------|------|------|
| 모든 E2E PASS | ✅ 리팩터링이 외부 동작에 영향 없음 확인 | 완료 |
| E2E FAIL (1회차) | 🔄 flaky 가능성 | 1회 재실행 후 재판정 |
| E2E FAIL (재실행 후) | ❌ 리팩터링이 외부 동작을 변경함 | 원복 후 원인 분석 |
| 앱 미실행 | ⚠️ 검증 보류 | 완료 리포트에 "E2E 검증 보류 — `npm run dev` 후 수동 확인 필요" 명시 |

**단위 + E2E 모든 테스트 PASS 확인 후 완료.**

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
Unit Tests: 9 passed
E2E Tests: 5 passed (또는 "E2E 없음" / "⚠️ 앱 미실행 — 수동 확인 필요")

### 파이프라인 위치
[test-writer → RED] → [code-writer --ui → GREEN] → [refactor → 지금 여기] → [coverage-report] → [code-review]

### 다음 단계
/coverage-report WP-1234   → 커버리지 Jira 기록
/code-review               → 코드 리뷰
```
