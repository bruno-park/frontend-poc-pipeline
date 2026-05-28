#!/bin/bash
# Gate: git commit 시 Conventional Commit 형식 강제
# Trigger: PreToolUse(Bash) — git commit 감지 시 발동

set -euo pipefail

INPUT="${CLAUDE_TOOL_INPUT:-}"

if ! echo "$INPUT" | grep -q 'git commit'; then
  exit 0
fi

# --amend / --no-edit 는 메시지 재사용이므로 통과
if echo "$INPUT" | grep -qE 'git commit.*(--amend|--no-edit)'; then
  exit 0
fi

PATTERN='(feat|fix|chore|docs|style|refactor|test|perf|ci|build|revert)(\([^)]+\))?!?:'

if ! echo "$INPUT" | grep -qE "$PATTERN"; then
  cat <<'EOF'
[commit-message-check] Conventional Commit 형식이 아닙니다.

올바른 형식:
  <type>(<scope>): <subject>

  type: feat | fix | chore | docs | style | refactor | test | perf | ci | build | revert

예시:
  feat(auth): 로그인 폼 구현
  fix(api): useUserList null 처리 추가
  chore: vitest 설정 업데이트

커밋 메시지를 올바른 형식으로 수정한 후 다시 시도하세요.
EOF
  exit 1
fi
