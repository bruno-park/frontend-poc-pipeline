---
name: release-notes
description: git log와 Jira 완료 티켓을 분석해 릴리즈 노트를 자동 생성하고 Confluence에 기록합니다
---

# Release Notes — 릴리즈 노트 자동 생성

머지된 브랜치의 커밋 로그와 Jira 완료 티켓을 분석하여 사람이 읽기 좋은 릴리즈 노트를 생성합니다.

## 트리거

- `/release-notes v1.2.0` — 특정 버전 릴리즈 노트
- `/release-notes main..release/1.2.0` — 브랜치 범위 지정
- `/release-notes` — 마지막 태그 이후 변경사항

## 입력 컨텍스트

- 버전 태그 또는 브랜치 범위 (선택, 없으면 자동 탐지)
- Jira 프로젝트 키 (기본값: WP)
- Confluence 스페이스 키 (기본값: HOME)

---

## Phase 1: 변경사항 수집

### git log 파싱

```bash
# 마지막 태그 이후 커밋
git log $(git describe --tags --abbrev=0)..HEAD --oneline --no-merges 2>&1

# 또는 범위 지정
git log [from]..[to] --oneline --no-merges 2>&1
```

### 커밋 메시지에서 Jira 티켓 번호 추출

```
Regex: (WP|NW)-\d+ 패턴으로 티켓 번호 파싱
```

예시:
```
a1b2c3d feat: WP-1234 파트너 목록 페이지 추가
d4e5f6g fix: WP-1235 파트너 검색 필터 버그 수정
g7h8i9j chore: WP-1236 의존성 업데이트
```

---

## Phase 2: Jira 티켓 상세 조회

추출된 티켓 번호 목록에 대해:

```
mcp__mcp-atlassian-nestads__jira_get_issue(issue_key="WP-XXXX")
```

각 티켓에서:
- `summary` → 기능 이름
- `issuetype` → Feature / Bug / Chore 분류
- `status` → Done 여부 확인
- `components` → 영향 영역

---

## Phase 3: 릴리즈 노트 작성

### 분류 기준

| 커밋 prefix | 분류 |
|-----------|------|
| feat | ✨ 새 기능 |
| fix | 🐛 버그 수정 |
| perf | ⚡ 성능 개선 |
| refactor | 🔧 코드 개선 |
| chore | 🔨 기타 |
| docs | 📝 문서 |

### 릴리즈 노트 형식

```markdown
# 릴리즈 노트 — v1.2.0

**릴리즈 날짜**: YYYY-MM-DD
**브랜치**: release/1.2.0
**담당자**: (git log --format="%ae" 기반)

---

## ✨ 새 기능

- **[WP-1234]** 파트너 목록 페이지 추가 — 검색, 정렬, 페이지네이션 지원
- **[WP-1237]** 파트너 상세 페이지 구현 — RBAC 기반 편집 권한

## 🐛 버그 수정

- **[WP-1235]** 파트너 검색 필터 빈 결과 시 렌더링 에러 수정
- **[WP-1238]** 날짜 필터 timezone 오류 수정

## ⚡ 성능 개선

- **[WP-1239]** 파트너 목록 memo() 적용으로 불필요한 리렌더링 제거

## 🔧 코드 개선

- **[WP-1240]** React Query 훅 2-layer 패턴으로 리팩터링

---

## 영향 범위

| 페이지 | 변경 유형 | 티켓 |
|--------|---------|------|
| /partners | 신규 | WP-1234 |
| /partners/[id] | 신규 | WP-1237 |

---

## 테스트 현황

- 단위 테스트: N개 통과
- E2E 테스트: N개 통과

---

## 마이그레이션 가이드

(Breaking change가 있을 경우 작성)
```

---

## Phase 4: Confluence 등록

### 릴리즈 노트 페이지 생성

```
mcp__mcp-atlassian-nestads__confluence_create_page(
  space_key="HOME",
  title="릴리즈 노트 — v1.2.0 (YYYY-MM-DD)",
  content=[Phase 3 릴리즈 노트 내용],
  parent_id=[릴리즈 노트 목록 페이지 ID]
)
```

### 관련 Jira 티켓에 릴리즈 노트 링크 코멘트 (선택)

포함된 티켓들에 일괄 코멘트:

```
mcp__mcp-atlassian-nestads__jira_add_comment(
  issue_key="WP-XXXX",
  comment="v1.2.0 릴리즈 노트에 포함되었습니다: [Confluence URL]"
)
```

---

## Phase 5: 슬랙 알림 (선택)

사용자 확인 후 Slack 채널에 공유:

```
## v1.2.0 릴리즈 완료 🎉

새 기능 2개 / 버그 수정 2개 / 성능 개선 1개

전체 노트: [Confluence URL]
```

---

## 완료 리포트

```
## Release Notes 완료

버전: v1.2.0
분석된 커밋: N개
연결된 Jira 티켓: N개

분류:
  ✨ 새 기능: N개
  🐛 버그 수정: N개
  ⚡ 성능 개선: N개
  🔧 코드 개선: N개

Confluence 페이지: [URL]
```
