---
name: coverage-report
description: 프로젝트에 설정된 테스트 러너(Jest/Vitest)로 단위 커버리지 + (있으면) E2E를 실행하고 AC 항목별 커버리지를 분석해 Jira 티켓에 자동 기록합니다
---

# Coverage Report

GREEN 단계 완료 후 테스트 커버리지를 측정하고 Jira AC 합격 기준 충족 여부를 검증합니다.

## 트리거

- `/coverage-report WP-XXXX` 직접 호출
- test-writer 완료 + code-writer GREEN 통과 후 자동 권장

## 입력 컨텍스트

- Jira 티켓 번호 (선택)
- 대상 feature 경로 (없으면 현재 디렉토리에서 탐색)

---

## Phase 1: 커버리지 실행

### 사전 확인: 테스트 러너 감지 (`conventions` §13.1)

> 프로젝트에 설정된 러너를 그대로 따른다. Jest면 Jest로, Vitest면 Vitest로 커버리지를 측정한다.

```
Bash: cat package.json | grep -E "vitest|jest"
Glob: jest.config.*, vitest.config.*, vite.config.ts
```

**Jest/Vitest 둘 다 없으면** → 즉시 중단 후 안내 (설치는 opt-in, §13.4):
```
❌ 테스트 러너가 설치되어 있지 않습니다.

커버리지 측정 전에 먼저 테스트 러너를 설치하세요 (파이프라인 기본값 Vitest):
  /vitest-setup          → Vitest + RTL 자동 설치
  /unit-test-gen WP-XXXX → 단위 테스트 작성

설치 후 다시 /coverage-report WP-XXXX 를 실행하세요.
```

### 커버리지 provider 설정 확인 (감지된 러너 기준)

| 러너 | 확인 | 누락 시 안내 |
|------|------|------|
| **Jest** | `jest.config.*` 의 `collectCoverage`/`coverageThreshold` (next/jest는 기본 내장) | "jest.config에 `coverageThreshold` 추가 권장" |
| **Vitest** | `@vitest/coverage-v8`(또는 istanbul) deps + `vitest.config` 의 `coverage` | "npm i -D @vitest/coverage-v8 후 vitest.config에 coverage 설정 추가" |

### 단위 테스트 커버리지 실행 (§13.2)

```bash
# Jest:   npx jest pageComponents/[feature] --coverage 2>&1
# Vitest: npx vitest run pageComponents/[feature] --coverage --reporter=verbose 2>&1
```

> `scripts.test`(예: `jest --watch`)를 그대로 실행하지 말 것 (§13.2).

---

## Phase 1.5: E2E 테스트 실행

### E2E 러너 존재 여부 확인 (§13.5)

```
Glob: playwright.config.*, cypress.config.*
Glob: e2e/**/*.spec.ts
```

**E2E 러너 config가 없거나 e2e 테스트 파일이 없으면** → E2E 섹션 스킵하고 Phase 2로 진행 (정상 폴백, 자동 설치 안 함). 안내 추가:
```
⚠️ E2E 러너/테스트가 없습니다. E2E 커버리지는 생략합니다.
  /e2e-test-gen WP-XXXX → E2E 테스트 작성 (E2E 러너 도입은 별도 opt-in)
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

> **인스턴스 선택**: `mcp-atlassian-*`는 프로젝트 Jira/Confluence host에 맞는 인스턴스를 의미합니다 (예: `wisebirds.atlassian.net`→`mcp-atlassian-nestads`, `heypoll.atlassian.net`→`mcp-atlassian-heypoll`). 사용 환경에 존재하는 인스턴스를 선택하세요.


```
mcp-atlassian-*:jira_get_issue(issue_key="WP-XXXX")
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
mcp-atlassian-*:jira_add_comment(
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
