---
name: pull-request-description
description: >
  Generate a well-balanced PR/MR description explaining changes between branches.
  TRIGGER this skill whenever the user asks to: create MR, make PR, open MR, MR 만들어,
  PR 만들어, MR 올려, PR 올려, MR 생성, PR 생성, merge request 만들어, pull request 만들어.
  ALWAYS run this skill BEFORE creating any MR/PR via GitLab, GitHub, or Bitbucket tools.
---

# Pull Request Description Generator

Generate a comprehensive but concise pull request description by comparing the current branch with the specified target branch (default: `main`).

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
3. Use the generated title and description when calling the appropriate platform tool
4. Do NOT manually write the MR/PR description — always use this skill's output

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
5. If the ticket cannot be found or branch has no ticket ID, use the branch name as a fallback title

### Step 2: Analyze Git Diff

1. Run `git diff <target-branch>...HEAD` to get all changes (use `main` if not specified)
2. Identify modified, added, and deleted files
3. Group changes by feature/area/concern

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

PR 생성 전 아래 항목을 자동으로 검증합니다. **모든 항목 통과 후** PR을 생성합니다.

```bash
# 1. 테스트 전체 PASS 확인
npx vitest run pageComponents/[feature] --reporter=verbose 2>&1 | tail -5

# 2. console.log 잔존 확인
git diff main...HEAD | grep -n "console.log"

# 3. TODO/FIXME 잔존 확인 (의도적인 것 제외)
git diff main...HEAD | grep -n "TODO\|FIXME\|HACK\|XXX"

# 4. px 단위 사용 확인
git diff main...HEAD | grep -n '"[0-9]*px"'

# 5. data-testid 사용 확인
git diff main...HEAD | grep -n "data-testid"

# 6. any 타입 사용 확인
git diff main...HEAD | grep -n ": any"
```

**검증 결과를 PR description에 포함:**

```markdown
### Self-Review 체크리스트
- [ ] 모든 단위 테스트 PASS
- [ ] console.log 없음
- [ ] 의도하지 않은 TODO/FIXME 없음
- [ ] px 단위 없음 (rem 사용)
- [ ] data-testid 셀렉터 없음
- [ ] TypeScript any 타입 없음
- [ ] 인터랙티브 요소에 aria-label 또는 텍스트 있음
```

검증 실패 항목이 있으면 사용자에게 알리고 수정 후 진행할지 확인합니다.

---

## Execution Steps

1. **Get current branch**: `git branch --show-current`
2. **Extract ticket ID**: Parse ticket ID from branch name (e.g., `TILLION-5098` from `fix/TILLION-5098-something`)
3. **Fetch ticket title**: Use Jira MCP tool (`jira_get_issue`) with the ticket ID to get the issue summary
4. **Detect platform**: Run `git remote get-url origin` and parse URL to determine GitLab / Bitbucket / GitHub
5. **Ask for target branch** if not specified (default to `main`)
6. **Run git diff**: `git diff <target-branch>...HEAD`
7. **Analyze changes**: Read modified files to understand context and purpose
8. **Write balanced description**: Follow the template and guidelines above
9. **Output in Korean**: Use professional, clear Korean for the description sections
10. **Leave URL fields empty**: Do not fabricate or guess any URLs — leave them blank for the developer
11. **Create MR/PR** using the detected platform tool — on failure, output description-only fallback

## Example Usage

### Case 1: Explicit skill invocation
User says: `/pull-request-description` or `/pull-request-description dev`

You should:
1. Get branch name and extract ticket ID (e.g., `TILLION-5098`)
2. Fetch ticket title via Jira MCP
3. Run `git diff main...HEAD` (or specified branch)
4. Analyze all changes
5. Generate a well-structured PR description in Korean using the template
6. Present it ready to copy-paste

### Case 2: User asks to create MR/PR (AUTO-TRIGGER)
User says: `MR 만들어줘` or `PR 올려줘` or `MR 생성해줘`

You MUST:
1. **Invoke this skill first** — do NOT skip directly to platform tools
2. Run the full workflow (branch name → Jira ticket → platform detection → git diff → generate description)
3. Call the appropriate platform tool:
   - **GitLab**: `gitlab_create_mr`
   - **Bitbucket**: `bb_post /2.0/repositories/{workspace}/{repo}/pullrequests`
   - **GitHub**: `gh pr create`
4. On failure → output description-only fallback with clear error message
5. Never write the MR/PR description manually — always derive it from this skill's output
