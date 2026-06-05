#!/usr/bin/env bash
# commit-message-check.sh — PreToolUse(Bash) git commit 메시지 Conventional Commit 강제.
# 입력은 stdin JSON. enforce → 차단(exit 2) / warn → 경고 / off → 통과.

set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"
fpp_read_stdin

NAME="commit-msg"
[ "$(fpp_tool_name)" = "Bash" ] || exit 0
MODE="$(fpp_mode "$NAME")"
[ "$MODE" = "off" ] && exit 0

INPUT="$(fpp_bash_cmd)"
printf '%s' "$INPUT" | grep -q 'git commit' || exit 0
# --amend / --no-edit 는 메시지 재사용 → 통과
printf '%s' "$INPUT" | grep -qE 'git commit.*(--amend|--no-edit)' && exit 0

PATTERN='(feat|fix|chore|docs|style|refactor|test|perf|ci|build|revert)(\([^)]+\))?!?:'
printf '%s' "$INPUT" | grep -qE "$PATTERN" && exit 0

REASON="Conventional Commit 형식이 아닙니다 — <type>(<scope>): <subject>"
FIX="type: feat|fix|chore|docs|style|refactor|test|perf|ci|build|revert. 예) feat(auth): 로그인 폼 구현"
if [ "$MODE" = "enforce" ]; then fpp_deny "$NAME" "$REASON" "$FIX"; else fpp_advise "$NAME" "$REASON" "$FIX"; fi
