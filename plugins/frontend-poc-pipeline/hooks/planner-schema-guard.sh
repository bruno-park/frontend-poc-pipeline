#!/usr/bin/env bash
# planner-schema-guard.sh — planner.md 필수 섹션 검증.
# PostToolUse(Write|Edit|MultiEdit) — file_path basename 이 planner.md 일 때만 발동.
# 키워드 기반(헤딩 strict 아님): 팀마다 섹션명이 달라도 의미로 인식.
# PostToolUse 는 차단 불가 → enforce 는 exit 2(stderr 를 Claude 에 피드백), warn 은 경고.

set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"
fpp_read_stdin

NAME="planner-schema"
MODE="$(fpp_mode "$NAME")"
[ "$MODE" = "off" ] && exit 0

FP="$(fpp_file_path)"
case "$FP" in
  */planner.md|planner.md) : ;;
  *) exit 0 ;;
esac

# 디스크 파일이 정본(이미 기록됨). 없으면 write_text 폴백.
CONTENT=""
if [ -n "$FP" ] && [ -f "$FP" ]; then CONTENT="$(cat "$FP" 2>/dev/null)"; fi
[ -z "$CONTENT" ] && CONTENT="$(fpp_write_text)"
[ -z "$CONTENT" ] && exit 0

MISSING="$(printf '%s' "$CONTENT" | fpp_planner_missing)"
if [ -z "$MISSING" ]; then
  fpp_ledger_clear planner "$FP"   # 이제 유효 → 미해결 표시 제거(self-heal)
  exit 0
fi

REASON="planner.md 필수 섹션 누락:$MISSING"
FIX="누락 섹션을 추가하세요. feature-planner 스킬 형식 참고 (컴포넌트 구조·Hook Layer·URL state·구현 체크리스트·필드|타입 표)."
if [ "$MODE" = "enforce" ]; then
  fpp_ledger_record planner "$FP" "planner.md 필수 섹션 미완성: $FP"
  fpp_feedback "$NAME" "$REASON" "$FIX"
else
  fpp_advise "$NAME" "$REASON" "$FIX"
fi
