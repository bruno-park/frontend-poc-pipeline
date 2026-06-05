#!/usr/bin/env bash
# branch-name-check.sh — PreToolUse(Bash) git 브랜치 생성 네이밍 컨벤션 강제.
# {type}/{TICKET-ID}-{desc}. 입력은 stdin JSON. enforce → 차단(exit 2) / warn → 경고 / off → 통과.

set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"
fpp_read_stdin

NAME="branch-name"
[ "$(fpp_tool_name)" = "Bash" ] || exit 0
MODE="$(fpp_mode "$NAME")"
[ "$MODE" = "off" ] && exit 0

INPUT="$(fpp_bash_cmd)"
printf '%s' "$INPUT" | grep -qE 'git (checkout -b|switch -c)' || exit 0

BRANCH="$(printf '%s' "$INPUT" | grep -oE '(checkout -b|switch -c) [^ ]+' | awk '{print $NF}' | head -1)"
[ -z "$BRANCH" ] && exit 0

PATTERN='^(feat|fix|chore|docs|style|refactor|test|perf|hotfix)/[A-Z]+-[0-9]+-'
printf '%s' "$BRANCH" | grep -qE "$PATTERN" && exit 0

REASON="브랜치 네이밍 컨벤션 미준수: '$BRANCH' — {type}/{TICKET-ID}-{desc}"
FIX="예) feat/WP-1234-login-page. /branch-from-ticket 스킬이 올바른 이름을 자동 생성합니다."
if [ "$MODE" = "enforce" ]; then fpp_deny "$NAME" "$REASON" "$FIX"; else fpp_advise "$NAME" "$REASON" "$FIX"; fi
