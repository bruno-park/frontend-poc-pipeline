---
name: branch-from-ticket
description: Jira 티켓 번호로 브랜치를 자동 생성합니다. prefix(feature/fix/chore)를 이슈 타입으로 결정하고, suffix를 티켓 summary에서 영문 kebab-case로 추출합니다.
---

# Branch from Ticket

Jira 티켓 번호를 받아 `feature/partner-list-WP-8118` 형식의 브랜치를 자동 생성합니다.

## 사용법

```
/branch-from-ticket WP-8118
/branch-from-ticket WP-8118 WP-8119 WP-8120
```

---

## Workflow

### Step 1: Jira 티켓 병렬 조회

1. args에서 Jira 이슈 키 파싱 (예: `WP-8118 WP-8119`)
2. **모든 티켓을 병렬로 조회**: `mcp__mcp-atlassian-nestads__jira_get_issue`
   - fields: `summary,issuetype`
3. **오류 처리**:
   - 조회 실패 티켓 → 오류 목록에 추가 후 건너뜀
   - 전체 실패 → "모든 티켓 조회 실패. Jira 키 또는 연결 상태를 확인해주세요." 즉시 종료

### Step 2: Prefix 결정 (이슈 타입 기반)

| Jira 이슈 타입 | prefix |
|---------------|--------|
| Bug, Hotfix   | `fix`  |
| Chore, DevOps, Refactor | `chore` |
| Story, Task, Feature, 그 외 | `feature` |

### Step 3: Suffix 생성 (summary → 영문 kebab-case)

**추출 규칙 (우선순위 순):**

1. `>` 구분자로 계층 표현된 경우 → 최하위 단어만 사용
   - 예: `[운영어드민] 사업자관리 > 파트너사 목록` → `파트너사 목록`
2. `[브라켓]` prefix 제거
3. 남은 한국어 명사를 영문으로 번역 (직역보다 관용 영문 선호)
   - 목록 → `list`, 등록 → `create`, 조회/상세 → `detail`, 수정 → `edit`
   - 파트너사 → `partner`, 캠페인 → `campaign`, 배너 → `banner`
4. 공백 → `-`, 소문자 kebab-case
5. 최대 3단어로 제한 (핵심 명사 + 동작 위주)
6. 티켓 번호를 suffix 끝에 붙임

**예시:**
- `[운영어드민] 사업자관리 > 파트너사 목록` → `partner-list`
- `[운영어드민] 사업자관리 > 파트너사 등록` → `partner-create`
- `[운영어드민] 캠페인 배너 관리` → `campaign-banner`
- `Bug: 로그인 페이지 오류` → `login-page` (prefix: `fix`)

최종 브랜치명: `{prefix}/{suffix}-{TICKET}`
예: `feature/partner-list-WP-8118`

### Step 4: 현재 브랜치 확인 및 브랜치 생성

1. `git branch --show-current`로 현재 브랜치 확인
2. **Base 브랜치 강제 설정**:
   - 현재 브랜치가 `master` 또는 `main`이 아니면 → 경고 후 master로 강제 전환
   ```
   ⚠️ 현재 브랜치가 feature 브랜치입니다. master 기준으로 생성합니다.
   git checkout master
   ```
   - base 브랜치: 항상 `master` (없으면 `main`)
3. master 기준으로 각 티켓에 대해 브랜치 생성:
   ```
   git checkout -b {브랜치명}
   git checkout {원래 브랜치}
   ```
   - 티켓이 1개면 바로 해당 브랜치로 이동
   - 티켓이 2개 이상이면 모두 생성 후 원래 브랜치에 머묾
4. 이미 존재하는 브랜치는 경고 출력 후 건너뜀

### Step 5: 결과 출력

```
✅ 브랜치 생성 완료

Base: master (강제)

  feature/partner-list-WP-8118    ← WP-8118: [운영어드민] 파트너사 목록
  feature/partner-create-WP-8119  ← WP-8119: [운영어드민] 파트너사 등록
  feature/partner-detail-WP-8120  ← WP-8120: [운영어드민] 파트너사 상세

⚠️  WP-9999: 조회 실패 (건너뜀)
```
