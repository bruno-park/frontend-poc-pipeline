---
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, mcp__mcp-atlassian-nestads__jira_get_issue, mcp__mcp-atlassian-nestads__jira_add_comment, mcp__mcp-atlassian-heypoll__jira_get_issue, mcp__mcp-atlassian-heypoll__jira_add_comment
argument-hint: [JIRA-TICKET]
description: 긴급 핫픽스 fast-path — 5단계로 운영 버그를 최소 범위로 수정합니다
model: claude-sonnet-4-6
---

# Hotfix — 긴급 버그 수정 Fast-Path

운영 장애, 긴급 보안 패치, 블로킹 버그 수정을 위한 **단축 파이프라인**입니다.
표준 11단계 파이프라인 대신 5단계로 빠르게 처리합니다.

```
/hotfix WP-1234
```

> ⚠️ 핫픽스는 새 기능 추가에 사용하지 않습니다.
> 기능 추가는 반드시 표준 파이프라인(`/workflow`)을 사용하세요.

---

## 핫픽스 vs 표준 파이프라인

| 항목 | 표준 파이프라인 | 핫픽스 |
|------|--------------|--------|
| 단계 수 | 11단계 | 5단계 |
| planner.md | 필수 | 생략 |
| 테스트 범위 | AC 100% + RBAC + E2E | 버그 재현 테스트만 |
| 리팩터 | 필수 | 생략 (별도 티켓으로 추적) |
| Confluence | 필수 | 생략 (PR description으로 대체) |
| 브랜치 prefix | `feature/` | `hotfix/` |
| 커버리지 기준 | ≥ 80% | 버그 재현 케이스만 |

---

## Phase 0: 핫픽스 자격 확인

티켓 번호가 주어지면 먼저 Jira 티켓을 확인합니다.

```
mcp__mcp-atlassian-nestads__jira_get_issue(issue_key="WP-XXXX")
```

**자격 기준 (하나라도 해당하면 핫픽스 적합):**
- Priority: Blocker / Critical
- 운영 환경에서 발생 중인 버그
- 보안 취약점
- 매출/결제에 영향을 주는 오류

**자격 미달 시** (일반 버그, 개선):
```
이 티켓은 핫픽스 기준에 해당하지 않습니다.
표준 파이프라인을 사용하세요: /workflow WP-XXXX
```

---

## Phase H1: 핫픽스 브랜치 생성

```bash
git checkout main
git pull origin main
git checkout -b hotfix/WP-XXXX-[kebab-bug-summary]
```

브랜치 네이밍: `hotfix/WP-1234-login-redirect-broken`

---

## Phase H2: 버그 재현 테스트 작성 (최소 TDD)

> 핫픽스에서도 버그 재현 테스트는 반드시 먼저 작성합니다.
> 수정 후 이 테스트가 PASS되면 버그가 수정된 것입니다.

### Step 1: 기존 테스트 파일 확인

```
Glob: pageComponents/[feature]/**/*.test.tsx
Glob: pageComponents/[feature]/hooks/**/*.hook.test.ts
```

### Step 2: 버그 재현 테스트 추가

기존 테스트 파일이 있으면 버그 케이스를 추가합니다.
없으면 최소한의 새 테스트 파일을 생성합니다.

```typescript
// 버그 재현 테스트 패턴
describe('[HOTFIX] WP-XXXX — [버그 요약]', () => {
  it('버그 시나리오: [구체적인 재현 조건]', async () => {
    // Arrange: 버그가 발생하는 조건 설정
    // Act: 버그를 유발하는 동작
    // Assert: 기대하는 올바른 동작 (현재는 FAIL)
  })
})
```

### Step 3: RED 확인

```bash
npx vitest run pageComponents/[feature] --reporter=verbose 2>&1 | tail -20
```

버그 재현 테스트가 FAIL 상태인지 확인 후 진행합니다.

---

## Phase H3: 최소 범위 수정

> 핫픽스의 핵심: **가장 작은 변경으로 버그만 수정합니다.**
> 리팩터, 코드 정리, 기능 개선은 금지입니다.

### 수정 원칙

- ✅ 버그를 일으키는 코드만 수정
- ✅ 변경 파일 수 최소화 (이상적으로 1-3개 파일)
- ❌ 관련 없는 코드 정리 금지
- ❌ 패턴/구조 변경 금지
- ❌ 의존성 추가 금지
- ❌ 새 기능 추가 금지

### 수정 후 검증

```bash
# 버그 재현 테스트 PASS 확인
npx vitest run pageComponents/[feature] --reporter=verbose 2>&1 | tail -20

# 기존 테스트 회귀 확인
npx vitest run pageComponents/[feature] --reporter=verbose 2>&1 | grep -E "PASS|FAIL"
```

**합격 기준:**
- 버그 재현 테스트: PASS
- 기존 테스트: 모두 PASS (회귀 없음)

---

## Phase H4: 코드 리뷰 (Critical 이슈 집중)

```bash
/code-review
```

핫픽스 코드 리뷰는 Critical 이슈에 집중합니다:

**필수 확인:**
- 🔴 Null/undefined 참조 오류
- 🔴 데이터 손실 가능성
- 🔴 보안 취약점 (XSS, 인증 우회)
- 🔴 기존 기능 회귀

**생략 가능:**
- 🟢 네이밍 컨벤션 (별도 리팩터 티켓으로)
- 🟢 코드 구조 개선 제안
- 🟢 성능 최적화

---

## Phase H5: PR 작성 (핫픽스 명시)

```bash
/pull-request-description
```

PR에 핫픽스임을 명시합니다:

```markdown
## [HOTFIX] WP-XXXX — 버그 요약

### 핫픽스 이유
운영에서 [구체적인 영향]이 발생하여 긴급 수정

### 버그 원인 (as-is)
[버그가 발생한 원인]

### 수정 내용 (to-be)
[수정한 내용과 방법]

### 변경 범위
- 수정 파일: [파일명]
- 영향 범위: [영향받는 기능]
- 회귀 위험: [낮음/중간/높음]

### 검증
- [ ] 버그 재현 테스트 PASS
- [ ] 기존 테스트 전체 PASS (회귀 없음)
- [ ] 운영 환경 배포 전 스테이징 검증 필요

### 후속 작업
- [ ] 리팩터 티켓 생성: [기술 부채 내용]
- [ ] 모니터링: 배포 후 [X]시간 오류율 확인
```

---

## 완료 리포트

```
## 핫픽스 완료 — WP-XXXX

브랜치: hotfix/WP-XXXX-[summary]
수정 파일: [N]개
버그 재현 테스트: ✅ PASS
기존 테스트 회귀: ✅ 없음

다음 단계:
1. PR 리뷰 요청 (최소 1명 승인)
2. 스테이징 배포 후 확인
3. 운영 배포
4. 후속 리팩터 티켓 생성: /branch-from-ticket [리팩터-티켓]
```

---

## 핫픽스 완료 후 Jira 업데이트

```
mcp__mcp-atlassian-nestads__jira_add_comment(
  issue_key="WP-XXXX",
  comment="## 핫픽스 완료\n\n수정 파일: N개\n버그 재현 테스트: ✅\n기존 회귀: ✅ 없음\n\nPR: [PR URL]"
)
```
