#!/usr/bin/env bash
# subagent-regate.sh — SubagentStop 재게이트.
# 계획/설계 계열 서브에이전트가 종료할 때, 최근 수정된 planner.md 를 재검증.
# SubagentStop 은 file_path 를 주지 않으므로 최근(기본 10분) 수정된 planner.md 를 탐색.
# enforce + 누락 → decision:block (루프가드로 N회 후 통과). 그 외 통과.

set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"
fpp_read_stdin

NAME="planner-schema"   # D 와 동일 설정/모드 공유
MODE="$(fpp_mode "$NAME")"
[ "$MODE" = "off" ] && exit 0
[ "$MODE" = "enforce" ] || exit 0   # warn 모드는 stop 을 막지 않음

# 계획/설계 계열 에이전트만
AGENT="$(fpp_agent_type)"
case "$AGENT" in
  *planner*|*architect*|*feature*) : ;;
  *) exit 0 ;;
esac

PROOT="$(fpp_project_dir)"
[ -d "$PROOT" ] || exit 0

# 최근 수정된 planner.md (10분 이내) 중 가장 최신 1개
CAND="$(find "$PROOT" -type f -name planner.md -mmin -10 2>/dev/null \
        -not -path '*/node_modules/*' | head -50)"
[ -z "$CAND" ] && exit 0
# 최신 파일 선택 (mtime 정렬)
TARGET="$(ls -t $CAND 2>/dev/null | head -1)"
[ -z "$TARGET" ] || [ ! -f "$TARGET" ] && exit 0

MISSING="$(cat "$TARGET" | fpp_planner_missing)"
[ -z "$MISSING" ] && { fpp_guard_reset "$NAME"; exit 0; }

# 루프가드: 같은 (target+missing) 으로 N회 차단 후 통과
FP="$(printf '%s|%s' "$TARGET" "$MISSING" | cksum | awk '{print $1}')"
if fpp_guard_should_pass "$NAME" "$FP" 3; then
  exit 0   # 반복 차단 방지 — 통과(개입 한도 도달)
fi

REASON="$TARGET 필수 섹션 누락:$MISSING"
FIX="누락 섹션을 보완한 뒤 다시 진행하세요(컴포넌트·Hook Layer·URL state·체크리스트·필드|타입 표)."
fpp_block_stop "$NAME" "$REASON" "$FIX"
