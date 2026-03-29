---
name: coverage-report
description: vitest 단위 테스트 + Playwright E2E 커버리지를 실행하고 AC 항목별 커버리지를 분석해 Jira 티켓에 자동 기록합니다
---

# Coverage Report

GREEN 단계 완료 후 테스트 커버리지를 측정하고 Jira AC 합격 기준 충족 여부를 검증합니다.

## 트리거

- `/coverage-report WP-XXXX` 직접 호출
- test-writer 완료 + ui-builder GREEN 통과 후 자동 권장

## 입력 컨텍스트

- Jira 티켓 번호 (선택)
- 대상 feature 경로 (없으면 현재 디렉토리에서 탐색)

---

## Phase 1: 커버리지 실행

### 사전 확인: 테스트 인프라 존재 여부

```
Bash: cat package.json | grep -E "vitest|jest"
```

**vitest/jest가 없으면** → 즉시 중단 후 안내:
```
❌ 테스트 인프라가 설치되어 있지 않습니다.

커버리지 측정 전에 먼저 테스트를 설치하세요:
  /vitest-setup          → Vitest + RTL 자동 설치
  /unit-test-gen WP-XXXX → 단위 테스트 작성

설치 후 다시 /coverage-report WP-XXXX 를 실행하세요.
```

### vitest 커버리지 설정 확인

```
Glob: vitest.config.ts, vite.config.ts
Grep: coverage
```

`@vitest/coverage-v8` 또는 `@vitest/coverage-istanbul` 없으면:
```
사용자에게 알림: "npm install -D @vitest/coverage-v8 후 vitest.config.ts에 coverage 설정 추가 필요"
```

### 단위 테스트 커버리지 실행

```bash
npx vitest run pageComponents/[feature] --coverage --reporter=verbose 2>&1
```

---

## Phase 1.5: E2E 테스트 실행

### Playwright 존재 여부 확인

```
Glob: playwright.config.ts
Glob: e2e/**/*.spec.ts
```

**playwright.config.ts가 없거나 e2e 테스트 파일이 없으면** → E2E 섹션 스킵하고 Phase 2로 진행. 안내 추가:
```
⚠️ E2E 테스트가 없습니다. E2E 커버리지는 생략합니다.
  /e2e-test-gen WP-XXXX → Playwright E2E 테스트 작성
```

### E2E 테스트 실행

```bash
npx playwright test e2e/[feature] --reporter=list 2>&1
```

### E2E 결과 요약

| 항목 | 결과 |
|------|------|
| 총 테스트 | ? |
| 통과 | ? |
| 실패 | ? |
| 스킵 | ? |

---

## Phase 2: AC 커버리지 매핑

### Jira AC 조회 (티켓 있을 경우)

```
mcp__mcp-atlassian-nestads__jira_get_issue(issue_key="WP-XXXX")
```

### 커버리지 결과 분석

| 지표 | 합격 기준 | 결과 |
|------|---------|------|
| Statements | ≥ 80% | ? |
| Branches | ≥ 80% | ? |
| Functions | ≥ 80% | ? |
| Lines | ≥ 80% | ? |

### AC 항목별 테스트 매핑 확인

test-writer에서 작성한 테스트 파일을 읽어 AC 항목이 모두 커버되는지 확인:

```
Grep: [AC- (테스트 파일에서 AC 태그 찾기)
```

| AC 항목 | 연결된 테스트 | 통과 여부 |
|---------|------------|---------|
| AC-1 목록 렌더링 | 2개 | ✅ |
| AC-2 검색 필터 | 1개 | ✅ |
| AC-3 RBAC 버튼 | 3개 | ✅ |

---

## Phase 3: Jira 코멘트 등록

> **필수**: 티켓 번호가 제공된 경우 반드시 이 Phase를 실행해야 합니다. 절대 건너뛰지 마세요.

```
mcp__mcp-atlassian-nestads__jira_add_comment(
  issue_key="WP-XXXX",
  comment="""
## 테스트 커버리지 리포트

**상태**: ✅ 합격 기준 충족

### 커버리지 수치
| 지표 | 수치 | 기준 |
|------|------|------|
| Statements | 87% | ≥80% ✅ |
| Branches | 82% | ≥80% ✅ |
| Functions | 91% | ≥80% ✅ |
| Lines | 85% | ≥80% ✅ |

### AC 커버리지
| AC 항목 | 단위 테스트 | E2E | 상태 |
|---------|-----------|-----|------|
| AC-1 목록 렌더링 | 2개 | 1개 | ✅ |
| AC-2 검색 필터 | 1개 | 1개 | ✅ |
| AC-3 RBAC 버튼 | 3개 | 1개 | ✅ |

### E2E 테스트 (Playwright)
| 항목 | 결과 |
|------|------|
| 총 테스트 | 3개 |
| 통과 | 3개 ✅ |
| 실패 | 0개 |

**총 테스트**: 단위 9개 + E2E 3개 = 12개 통과 / 0개 실패
  """
)
```

---

## 완료 리포트

```
## Coverage Report 완료

단위 테스트 커버리지: Statements 87% / Branches 82% / Functions 91%
E2E 테스트: 3개 통과 / 0개 실패
AC 커버리지: 3/3 항목 (100%) ✅

Jira WP-XXXX 코멘트 등록 완료 (Phase 3 실행 확인)

다음 단계:
  /refactor pageComponents/[feature]/planner.md  → 리팩터링
  /code-review                                   → 코드 리뷰
```
