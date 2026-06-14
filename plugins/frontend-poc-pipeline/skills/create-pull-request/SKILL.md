---
name: create-pull-request
description: >
  Generate a well-balanced PR/MR description explaining changes between branches, then
  create the PR/MR — but ONLY after the user explicitly approves.
  TRIGGER this skill whenever the user asks to: create MR, make PR, open MR, MR 만들어,
  PR 만들어, MR 올려, PR 올려, MR 생성, PR 생성, merge request 만들어, pull request 만들어.
  ALWAYS run this skill BEFORE creating any MR/PR via GitLab, GitHub, or Bitbucket tools.
  NEVER create the PR/MR without explicit user approval (see User Approval Gate).
---

# Create Pull Request

Generate a comprehensive but concise pull request description by comparing the current branch with the specified target branch (default: `main`), then create the PR/MR **only after the user explicitly approves** the generated description.

## Auto-Trigger Conditions

**IMPORTANT**: This skill MUST be invoked automatically (before any GitLab/GitHub/Bitbucket MR/PR creation tool call) when the user says any of the following:

- `MR 만들어`, `MR 만들어줘`, `MR 올려`, `MR 올려줘`, `MR 생성`
- `PR 만들어`, `PR 만들어줘`, `PR 올려`, `PR 올려줘`, `PR 생성`
- `merge request 만들어`, `pull request 만들어`
- `MR 열어줘`, `PR 열어줘`
- Any variation of "create MR", "open PR", "make a pull request"

**Mandatory workflow when user requests MR/PR creation:**
1. Run this skill first to generate the description
2. **Detect platform** (see Platform Detection below)
3. **Present the description to the user and obtain explicit approval** (see User Approval Gate) — this step is NON-SKIPPABLE, even on auto-trigger
4. Only after approval, use the generated title and description when calling the appropriate platform tool
5. Do NOT manually write the MR/PR description — always use this skill's output

## Platform Detection

Run `git remote -v` and parse the remote URL to determine the target platform:

| Remote URL contains | Platform | Tool to use |
|---|---|---|
| `gitlab.com` or `gitlab.` | **GitLab** | `gitlab_create_mr` |
| `bitbucket.org` or `bitbucket.` | **Bitbucket** | `bb_post` (Bitbucket MCP) |
| `github.com` | **GitHub** | `gh pr create` (CLI) |

**Detection logic:**
```
remote_url = git remote get-url origin
if "gitlab" in remote_url → use GitLab MCP (gitlab_create_mr)
elif "bitbucket" in remote_url → use Bitbucket MCP (bb_post /2.0/repositories/{workspace}/{repo}/pullrequests)
elif "github" in remote_url → use GitHub CLI (gh pr create)
else → output description only (fallback)
```

If the user explicitly specifies a platform (e.g., "gitlab에 MR 올려", "bitbucket PR"), use that platform regardless of remote URL.

### 생성 가능 여부 선체크 (게이트 진입 전)

승인 게이트로 가기 **전에** PR/MR 생성이 실제로 가능한지 먼저 확인한다:

- 현재 브랜치가 remote에 push됐는지 (`git rev-parse --abbrev-ref --symbolic-full-name @{u}` 성공 여부)
- 플랫폼이 지원되는지 (위 표에 매칭, unknown platform 아님)
- 해당 플랫폼 도구/MCP가 연결됐는지

하나라도 불가하면 **승인을 묻지 않고** `Fallback: Description Only` 경로로 안내한다 (예: 미push면 "`git push -u origin <branch>` 먼저 할까요?" 제안). 승인을 받아놓고 생성 단계에서 실패하는 헛걸음을 막기 위함이다.

## Fallback: Description Only

If MR/PR creation fails for any reason (MCP not connected, branch not pushed, API error, unknown platform), **do NOT retry or error out silently**:

1. Output the generated description as a markdown code block so the user can copy-paste it manually
2. Clearly state **why** creation failed (e.g., "브랜치가 remote에 push되지 않았습니다", "Bitbucket MCP가 연결되지 않았습니다")
3. Suggest the fix (e.g., `git push -u origin <branch>`)

Example fallback output:
```
MR 자동 생성에 실패했습니다.
원인: 브랜치가 remote에 push되지 않았습니다. `git push -u origin <branch>` 후 다시 시도해주세요.

아래 description을 복사해서 사용하세요:
---
[생성된 PR description]
---
```

## Workflow

### Step 1: Extract Ticket Info from Branch Name

1. Run `git branch --show-current` to get the current branch name
2. Extract the ticket ID from the branch name (e.g., `fix/TILLION-5098-some-description` → `TILLION-5098`)
3. Use the Jira MCP tool (`jira_get_issue`) to fetch the ticket title for that ticket ID
4. Compose the PR title as: `[TICKET-ID] Ticket Title` (e.g., `[TILLION-5098] Unrecognized action error fix`)
5. 티켓을 못 찾거나 브랜치에 티켓 ID가 없을 때:
   - **Jira MCP가 미연결**인지 **티켓이 존재하지 않는지**를 구분해 한 줄로 알린다.
   - 제목을 임의로 짓지 말고 **사용자에게 제목을 물어본다.** 사용자가 답하지 않으면, 브랜치명을 사람이 읽기 좋게 정리한 임시 제목(prefix·번호 꼬리 제거, 하이픈→공백, Title Case)을 쓴다 — `feat/improve-ui-v2-final` 같은 raw 브랜치명을 제목으로 그대로 쓰지 않는다.

### Step 2: Analyze Git Diff

1. Run `git diff <target-branch>...HEAD` to get all changes (target branch 기본값은 `main`; 인자로 받은 경우 그 값 사용)
2. **빈 diff 가드**: 변경이 하나도 없으면 PR을 만들지 않는다 — "대상 브랜치(`<target>`) 대비 변경 사항이 없습니다"라고 알리고 중단한다. 대상 브랜치가 틀렸을 수 있으니 다른 브랜치를 지정할지 묻는다.
3. Identify modified, added, and deleted files
4. Group changes by feature/area/concern

### Step 3: Understand Changes

For each modified file:

- Read the actual changes (not just diff stats)
- Understand the **purpose** and **impact** of the change
- Identify whether it's:
  - New feature addition
  - Bug fix
  - Refactoring
  - Performance improvement
  - Code cleanup
  - Configuration change
  - Dependency update

### Step 4: Generate PR Description

Use the template below. Fill in what you can infer from the code diff, and leave placeholders for information only the developer knows (like URLs and Figma links).

---

## PR Template

```markdown
## Title
[TICKET-ID] Ticket Title

## Description
[2-3 sentences summarizing the core changes and purpose of this PR]

local url:
vercel url:
figma url:

fix 이유:
[Why this change was needed — the business or technical reason]

as-is:
[What the behavior/state was before this change]

to-be:
[What the behavior/state is after this change]

### 미비사항

- (N/A or list any known incomplete items, deferred work, or follow-up tasks)

### 특이사항

- (N/A or list any special notes, known issues, deployment considerations, or unusual implementation details reviewers should be aware of)

### Reference (optional)

jira:
confluence:
notion:
```

---

## Writing Guidelines

**DO**:

- ✅ Fill in `fix 이유` with the business/product/technical reason for the change
- ✅ Fill in `as-is` with a concise description of the previous behavior or state
- ✅ Fill in `to-be` with a concise description of the new behavior or state
- ✅ Mention **breaking changes** or **migration steps** in 특이사항
- ✅ Use clear, professional Korean

**DON'T**:

- ❌ Fill in URL fields (local url, vercel url, figma url, jira, confluence, notion) — leave them as empty placeholders for the developer to fill in
- ❌ Copy-paste entire code blocks
- ❌ Write "updated X" without explaining what/why
- ❌ Use emojis or icons
- ❌ Write overly technical jargon without explanation
- ❌ Include git commit messages verbatim

**Length Guidelines**:

- **Small PRs** (1-5 files): 5-10 lines of description
- **Medium PRs** (5-15 files): 15-25 lines of description
- **Large PRs** (15+ files): 25-40 lines of description

**Detail Level Examples**:

❌ **Too short**:

```
fix 이유: 버그 수정
as-is: 안됨
to-be: 됨
```

✅ **Balanced**:

```
fix 이유: 포인트샵 기프트 카드 UI가 Figma 디자인과 일치하지 않아 수정

as-is: 기프트 카드 아이템에 수량 배지가 없고 타이포그래피가 디자인 시스템 토큰을 사용하지 않았음

to-be: 수량 배지 컴포넌트 추가, 타이포그래피를 디자인 시스템 토큰(text-body-02-400)으로 통일, 간격을 rem 단위로 정리
```

## Pre-flight Self-Review Checklist

PR 생성 전 변경 위생을 자동 점검한다. **결과는 Approval Gate 제시 화면에 함께 표시**한다 — 여기서 따로 "진행할지" 묻지 않는다(확인은 게이트 한 곳에서만).

> 검사 범위는 프로젝트에 맞춰 적응한다. 아래는 이 레포(프론트엔드) 예시이며, 해당 없는 항목(px·data-testid 등)은 건너뛴다. `<target>`은 Step 2에서 선택한 대상 브랜치다 — **하드코딩 금지**.

```bash
# 1. (테스트 러너가 있으면) 테스트 PASS — conventions §13로 러너 감지(Jest: npx jest … / Vitest: npx vitest run …). 러너 없으면 생략.
# 2. console.log 잔존:      git diff <target>...HEAD | grep -n "console.log"
# 3. TODO/FIXME 잔존:       git diff <target>...HEAD | grep -nE "TODO|FIXME|HACK|XXX"
# 4. (해당 시) px 단위:      git diff <target>...HEAD | grep -nE '"[0-9]+px"'
# 5. (해당 시) data-testid:  git diff <target>...HEAD | grep -n "data-testid"
# 6. any 타입:              git diff <target>...HEAD | grep -n ": any"
```

> grep은 **매치 없음이 정상(통과)** 이다 — 종료코드 1을 실패로 해석하지 않는다. 매치가 나온 항목만 "확인 필요"로 표시한다.

**검증 결과는 게이트 화면과 PR description 양쪽에 포함:**

```markdown
### Self-Review 체크리스트
- [ ] 테스트 PASS (러너 있을 때)
- [ ] console.log 없음
- [ ] 의도하지 않은 TODO/FIXME 없음
- [ ] (해당 시) px 단위 없음 / data-testid 셀렉터 없음
- [ ] TypeScript any 타입 없음
```

---

## User Approval Gate (필수)

**PR/MR은 사용자가 명시적으로 승인하기 전에는 절대 생성하지 않는다.** 이 게이트는 auto-trigger(`MR 만들어` 등)로 진입한 경우에도 **건너뛸 수 없다**.

description 생성 + Pre-flight 점검 후 다음을 수행한다:

1. **생성된 description 전문(제목 포함) + Pre-flight 결과를 함께 제시**한다. 사용자가 무엇을 승인하는지 한 화면에서 보게 한다.
2. **항상** 다음을 명시적으로 묻는다:

   ```
   이 내용으로 PR/MR을 생성할까요?
     ① 승인 — 이대로 생성
     ② 수정 — 고칠 내용을 알려주세요 (제목/본문 등)
     ③ 초안 — Draft/WIP 상태로 생성 (리뷰어 알림 없이 CI만)
     ④ 취소 — 생성하지 않음
   ```

3. **분기 처리:**
   - **① 승인**: 플랫폼 생성 도구(`gitlab_create_mr` / `bb_post` / `gh pr create`)를 호출한다.
   - **② 수정**: 반영해 description을 갱신하고 **다시 1번부터 제시**(승인 나올 때까지 루프). 단, 사용자가 한 턴에 "X를 고치고 그대로 올려줘"처럼 **수정+생성 의사를 함께 명시**하면 반영 후 그것을 승인으로 간주해 생성한다(별도 재확인 불필요 — 명시적 생성 지시이므로).
   - **③ 초안**: draft 플래그로 생성한다 (GitHub `gh pr create --draft`, GitLab 제목에 `Draft:` prefix, Bitbucket은 draft 미지원 시 일반 PR + 본문에 WIP 표기).
   - **④ 취소**: 생성을 중단한다. 생성한 description만 출력하고 종료한다 (플랫폼 도구 호출 금지).

4. **모호한 응답**(승인/거절이 불명확)은 승인으로 해석하지 않고 위 선택지를 다시 묻는다.
5. **명시적 승인(① 또는 ③, 또는 ②의 수정+생성 지시) 없이는 플랫폼 생성 도구를 절대 호출하지 않는다.** "MR 만들어줘"라는 최초 요청은 게이트 진입 트리거일 뿐, 생성 승인이 아니다.

---

## Execution Steps

1. **Get current branch**: `git branch --show-current`
2. **Determine target branch**: 인자로 받았으면 그 값, 없으면 `main`을 기본값으로 사용하고 그 사실을 한 줄로 알린다(되묻지 않음).
3. **Extract ticket ID**: 브랜치명에서 파싱. 없으면 Step 1의 "티켓 없음" 폴백 적용.
4. **Fetch ticket title**: Jira MCP(`jira_get_issue`). 미연결 vs 티켓 없음을 구분해 알린다.
5. **Detect platform & feasibility**: remote URL로 플랫폼 판별 + push/MCP 연결 선체크 (생성 불가면 게이트에서 description-only로 라우팅).
6. **Run git diff**: `git diff <target>...HEAD` — 빈 diff면 중단(Step 2 가드).
7. **Analyze changes**: 변경 파일을 읽어 목적·영향 파악.
8. **Write balanced description**: 템플릿·가이드라인 따름. URL 필드는 비운다(developer가 채움, 추측 금지).
9. **Pre-flight Self-Review**: 위생 점검 실행, 결과 수집.
10. **User Approval Gate**: description + Pre-flight 결과 제시, 4지선다(승인 / 수정 / 초안 / 취소). 수정은 루프, 취소는 종료. See User Approval Gate.
11. **Create MR/PR (승인 필수)**: 명시적 승인(① 승인 / ③ 초안 / ②의 수정+생성 지시) 후에만 감지된 플랫폼 도구 호출 — 실패 시 description-only 폴백.
    - 공통 파라미터: source = 현재 브랜치, target = 선택 브랜치, title, description, (초안 시) draft 플래그. Bitbucket/GitLab은 remote URL에서 workspace·repo(·project)를 파싱.

## Example Usage

### Case 1: Explicit skill invocation
User says: `/create-pull-request` or `/create-pull-request dev`

You should:
1. Get branch name and extract ticket ID (e.g., `TILLION-5098`)
2. Fetch ticket title via Jira MCP
3. Run `git diff <target>...HEAD` (target 기본값 `main`, 인자로 지정 가능) — 빈 diff면 중단
4. Analyze all changes
5. Generate a well-structured PR description in Korean using the template
6. Run Pre-flight Self-Review, then present it and run the User Approval Gate (승인 / 수정 / 초안 / 취소) before creating anything

### Case 2: User asks to create MR/PR (AUTO-TRIGGER)
User says: `MR 만들어줘` or `PR 올려줘` or `MR 생성해줘`

You MUST:
1. **Invoke this skill first** — do NOT skip directly to platform tools
2. Run the full workflow (branch name → Jira ticket → platform detection → git diff → generate description)
3. **Run the User Approval Gate** — present the description + Pre-flight 결과 and ask 승인 / 수정 / 초안 / 취소. Do NOT create the PR/MR yet.
4. Only after explicit approval (① 승인 / ③ 초안 / ②의 수정+생성 지시), call the appropriate platform tool:
   - **GitLab**: `gitlab_create_mr`
   - **Bitbucket**: `bb_post /2.0/repositories/{workspace}/{repo}/pullrequests`
   - **GitHub**: `gh pr create`
5. On failure → output description-only fallback with clear error message
6. Never write the MR/PR description manually — always derive it from this skill's output
7. Never create the PR/MR without explicit approval — the initial "MR 만들어줘" is not approval
