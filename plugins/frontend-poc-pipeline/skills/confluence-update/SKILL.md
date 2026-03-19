---
name: confluence-update
description: 구현 완료 후 planner.md와 코드 변경 내역을 기반으로 Confluence 기술 문서를 자동 업데이트합니다
---

# Confluence Update — 기술 문서 자동 업데이트

구현이 완료된 기능의 컴포넌트 구조, API 훅, URL 상태 스키마를 Confluence에 자동으로 기록합니다.

## 트리거

- `/confluence-update WP-XXXX` 직접 호출
- PR 생성 전 기술 문서 동기화 필요 시

## 입력 컨텍스트

- Jira 티켓 번호 (Confluence 페이지 탐색용)
- planner.md 경로
- Confluence 스페이스 키 (기본값: HOME)

---

## Phase 1: 문서화 대상 수집

### planner.md 읽기

```
Read: pageComponents/[feature]/planner.md
```

추출:
- 컴포넌트 계층 구조
- URL State 스키마 (있을 경우)
- 훅 목록 및 역할
- 파일 구조

### 실제 구현 파일 확인 (planner.md와 비교)

```
Glob: pageComponents/[feature]/**/*.tsx
Glob: pageComponents/[feature]/**/*.hook.ts
```

planner.md 계획과 실제 구현의 차이 기록.

---

## Phase 2: Confluence 페이지 탐색

### Jira 티켓에서 Confluence 링크 확인

```
mcp__mcp-atlassian-nestads__jira_get_issue(issue_key="WP-XXXX")
```

### 기존 기술 문서 페이지 탐색

```
mcp__mcp-atlassian-nestads__confluence_search(
  query="[feature명] 기술 문서 OR 화면 설계",
  space_key="HOME"
)
```

- 페이지 있음 → 기존 페이지 업데이트
- 페이지 없음 → 새 페이지 생성

---

## Phase 3: 문서 내용 작성

### 생성/업데이트할 Confluence 내용

```markdown
## [Feature명] 기술 문서

**최종 업데이트**: YYYY-MM-DD
**Jira 티켓**: WP-XXXX
**담당자**: (Jira 티켓 담당자)

---

### 컴포넌트 구조

| 컴포넌트 | 경로 | memo | 역할 |
|---------|------|------|------|
| FeatureContainer | pageComponents/feature/FeatureContainer.tsx | No | 레이아웃 |
| FeatureTable | .../components/table/FeatureTable.tsx | Yes | 목록 테이블 |
| FeatureFilter | .../components/filter/FeatureFilter.tsx | No | 검색 필터 |

---

### React Query 훅

| 훅 | 파일 | 역할 |
|----|------|------|
| useFeatureQuery | hooks/useFeatureQuery.hook.ts | API 호출 (순수) |
| useFeature | hooks/useFeature.hook.ts | 비즈니스 로직 + 뮤테이션 |

**API 엔드포인트**: `GET /api/v1/features`

---

### URL State 스키마 (해당 시)

| 파라미터 | 타입 | 기본값 | 트리거 |
|---------|------|------|------|
| page | number | 1 | 페이지네이션 |
| size | number | 25 | 페이지 크기 변경 |
| q | string | '' | 검색어 입력 |

---

### 테스트

| 종류 | 파일 | 케이스 수 |
|------|------|---------|
| 단위 | FeatureTable.test.tsx | 6개 |
| E2E | e2e/feature/feature.spec.ts | 4개 |

---

### 변경 이력

| 날짜 | 내용 | 작성자 |
|------|------|------|
| YYYY-MM-DD | 최초 작성 | Claude |
```

---

## Phase 4: Confluence 업데이트

```
mcp__mcp-atlassian-nestads__confluence_update_page(
  page_id="[탐색된 페이지 ID]",
  title="[Feature명] 기술 문서",
  content=[Phase 3에서 작성한 내용]
)
```

또는 새 페이지 생성:

```
mcp__mcp-atlassian-nestads__confluence_create_page(
  space_key="HOME",
  title="[Feature명] 기술 문서",
  content=[Phase 3에서 작성한 내용],
  parent_id=[관련 상위 페이지 ID]
)
```

### Jira 티켓에 Confluence 링크 코멘트

```
mcp__mcp-atlassian-nestads__jira_add_comment(
  issue_key="WP-XXXX",
  comment="기술 문서 업데이트 완료: [Confluence 페이지 URL]"
)
```

---

## 완료 리포트

```
## Confluence Update 완료

업데이트된 페이지: [Feature명] 기술 문서
URL: https://wisebirds.atlassian.net/wiki/...

기록된 항목:
  - 컴포넌트 구조 (N개)
  - React Query 훅 (N개)
  - URL State 스키마 (N개 파라미터)
  - 테스트 현황 (단위 N개 / E2E N개)

Jira WP-XXXX 코멘트 등록 완료

다음 단계:
  /pull-request-description  → PR 작성
```
