#!/bin/bash
# Gate: git 브랜치 생성 시 네이밍 컨벤션 강제
# Trigger: PreToolUse(Bash) — git checkout -b / git switch -c 감지 시 발동

set -euo pipefail

INPUT="${CLAUDE_TOOL_INPUT:-}"

if ! echo "$INPUT" | grep -qE 'git (checkout -b|switch -c)'; then
  exit 0
fi

BRANCH=$(echo "$INPUT" | grep -oE '(checkout -b|switch -c) [^ ]+' | awk '{print $NF}' | head -1)

if [ -z "$BRANCH" ]; then
  exit 0
fi

# {type}/{ticket-id}-{description} 패턴 검증
PATTERN='^(feat|fix|chore|docs|style|refactor|test|perf|hotfix)/[A-Z]+-[0-9]+-'

if ! echo "$BRANCH" | grep -qE "$PATTERN"; then
  cat <<'EOF'
[branch-name-check] 브랜치 네이밍 컨벤션 미준수.

올바른 형식:
  {type}/{ticket-id}-{description}

  type: feat | fix | chore | docs | style | refactor | test | perf | hotfix

예시:
  feat/WP-1234-login-page
  fix/WP-5678-null-pointer-fix
  chore/WP-9999-update-deps

/branch-from-ticket 스킬을 사용하면 올바른 브랜치명이 자동 생성됩니다.
EOF
  exit 1
fi
