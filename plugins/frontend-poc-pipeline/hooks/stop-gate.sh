#!/usr/bin/env bash
# stop-gate.sh — Stop 종착 게이트.
# PostToolUse 훅들이 ledger 에 적어둔 미해결 위반(planner 미완성·시크릿 작성 등)이
# 남아 있으면 턴 종료를 차단(decision:block) → PostToolUse 강제를 실질화.
# 루프가드: 같은 위반으로 N회 차단 후엔 통과시켜 무한루프 방지.

set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"
fpp_read_stdin

NAME="stop-gate"
MODE="$(fpp_mode "$NAME")"
[ "$MODE" = "off" ] && exit 0

MSGS="$(fpp_ledger_messages)"
if [ -z "$MSGS" ]; then
  fpp_guard_reset "$NAME"   # 깨끗 → 카운터 리셋
  exit 0
fi

# warn 모드: 막지 않고 경고만
if [ "$MODE" != "enforce" ]; then
  _fpp_emit_msg "$NAME" "WARN" "미해결 위반(종료 비차단):"$'\n'"$MSGS"
  exit 0
fi

# enforce: 루프가드 — 같은 위반으로 N회 차단 후엔 통과
FP="$(printf '%s' "$MSGS" | cksum | awk '{print $1}')"
if fpp_guard_should_pass "$NAME" "$FP" 3; then
  _fpp_emit_msg "$NAME" "WARN" "미해결 위반이 남았지만 반복 차단 한도 도달 — 통과시킴:"$'\n'"$MSGS"
  exit 0
fi

fpp_block_stop "$NAME" "미해결 위반으로 턴을 종료할 수 없습니다:"$'\n'"$MSGS" "위 항목을 해결(또는 .fpp-hooks.json 에서 해당 hook off)한 뒤 다시 시도하세요."
