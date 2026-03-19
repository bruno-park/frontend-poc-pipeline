---
name: bug-report
description: 테스트 실패 로그 또는 QA 발견 버그를 분석해 Jira 버그 티켓을 자동 생성합니다
---

# Bug Report — 버그 → Jira 자동 티켓팅

테스트 실패 로그, 에러 스택, 또는 QA 발견 내용을 분석하여 재현 가능한 Jira 버그 티켓을 생성합니다.

## 트리거

- 테스트 실패 로그를 붙여넣고 "버그 티켓 만들어줘"
- Playwright 실패 스크린샷 + 설명
- QA 중 발견한 이슈 설명

## 입력 컨텍스트

- 에러 로그 / 스택 트레이스 (필수 또는 선택)
- 재현 스텝 설명 (선택)
- 연관 Jira 티켓 번호 (선택 — Epic 또는 부모 티켓 링크용)
- 프로젝트 키 (기본값: WP)

---

## Phase 1: 버그 분석

### 입력 파싱

사용자 입력에서 다음을 추출:

| 항목 | 추출 방법 |
|------|---------|
| 에러 타입 | 스택 첫 줄 (TypeError, ReferenceError 등) |
| 발생 위치 | 파일 경로 + 라인 번호 |
| 재현 조건 | 사용자 설명 또는 테스트 코드에서 추출 |
| 영향 범위 | 관련 컴포넌트/기능 추정 |

### 심각도 자동 판정

| 조건 | 심각도 |
|------|------|
| 인증/결제/데이터 손실 관련 | Critical |
| 핵심 기능 동작 불가 | High |
| 일부 기능 오동작, 회피 가능 | Medium |
| UI 깨짐, 경미한 오작동 | Low |

### 재현 스텝 구성

에러 로그 또는 사용자 설명을 바탕으로:

```
1. [사전 조건] 로그인 상태 / 특정 데이터 존재
2. [행동] 어떤 버튼 클릭 / 어떤 값 입력
3. [기대 결과] 정상적으로 동작해야 할 내용
4. [실제 결과] 발생한 오류
```

---

## Phase 2: Jira 버그 티켓 생성

### 티켓 초안 작성

사용자에게 확인:

```
## 생성될 버그 티켓

제목: [버그] PartnerTable - 빈 데이터 시 렌더링 에러

심각도: Medium
컴포넌트: pageComponents/partner/components/table/PartnerTable.tsx

재현 스텝:
1. 파트너 목록 페이지 접속 (/partners)
2. 검색 결과가 0건인 조건으로 필터 적용
3. → TypeError: Cannot read properties of undefined (reading 'map')

기대 결과: 빈 상태 컴포넌트 표시
실제 결과: 콘솔 에러 + 화면 크래시

환경: dev / Chrome 120

이 내용으로 Jira에 등록할까요? [y/n]
```

### 티켓 생성

사용자 확인 후:

```
mcp__mcp-atlassian-nestads__jira_create_issue(
  project_key="WP",
  summary="[버그] PartnerTable - 빈 데이터 시 렌더링 에러",
  issue_type="Bug",
  description="""
h2. 버그 설명
빈 검색 결과 시 PartnerTable 컴포넌트에서 TypeError 발생

h2. 재현 환경
- 브라우저: Chrome 120
- 환경: dev
- 역할: master

h2. 재현 스텝
# /partners 페이지 접속
# 결과가 0건인 조건으로 필터 적용

h2. 기대 결과
빈 상태 컴포넌트(EmptyState) 표시

h2. 실제 결과
{code}
TypeError: Cannot read properties of undefined (reading 'map')
  at PartnerTable.tsx:42
{code}

h2. 관련 파일
* pageComponents/partner/components/table/PartnerTable.tsx
  """,
  priority="Medium"
)
```

### 부모 티켓 링크 (연관 티켓 있을 경우)

```
mcp__mcp-atlassian-nestads__jira_create_issue_link(
  issue_key="WP-XXXX (신규 버그)",
  linked_issue_key="WP-YYYY (원본 기능 티켓)",
  link_type="relates to"
)
```

---

## Phase 3: 빠른 수정 시도 (선택)

사용자에게 물음:

```
버그 위치를 파악했습니다.
바로 수정을 시도할까요?

수정 예상:
  PartnerTable.tsx:42 — data?.map() 또는 옵셔널 체이닝 추가

[y] 지금 수정  [n] 티켓만 생성
```

`y` 선택 시 → 해당 파일 Read → 수정 제안 → 사용자 확인 후 Edit

---

## 완료 리포트

```
## Bug Report 완료

Jira 티켓 생성: WP-5678 ([버그] PartnerTable - 빈 데이터 시 렌더링 에러)
심각도: Medium
링크: WP-1234 (원본 기능 티켓)과 연결

다음 단계:
  /test-writer --unit WP-5678  → 버그 재현 테스트 먼저 작성 (TDD)
  수정 후 → npx vitest run 으로 GREEN 확인
```
