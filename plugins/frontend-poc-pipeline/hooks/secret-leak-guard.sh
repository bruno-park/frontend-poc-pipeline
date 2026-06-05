#!/usr/bin/env bash
# secret-leak-guard.sh — 시크릿/크리덴셜 유출 가드 (보너스 hook).
# PreToolUse(Bash): 명령에 시크릿 노출 → enforce 시 차단(exit 2).
# PostToolUse(Write|Edit|MultiEdit): 작성 내용/경로에 시크릿 → enforce 시 피드백(exit 2, 차단 불가).
# 고신호 패턴만(저-false-positive): private key 블록, 벤더 토큰, key=값 형태.

set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"
fpp_read_stdin

NAME="secret-leak"
MODE="$(fpp_mode "$NAME")"
[ "$MODE" = "off" ] && exit 0

EVENT="$(fpp_event)"
TOOL="$(fpp_tool_name)"

# 검사 대상 텍스트 수집
TEXT=""
case "$TOOL" in
  Bash)                   TEXT="$(fpp_bash_cmd)" ;;
  Write|Edit|MultiEdit)   TEXT="$(fpp_write_text)" ;;
  *) exit 0 ;;
esac
FP="$(fpp_file_path)"
[ -z "$TEXT" ] && [ -z "$FP" ] && exit 0

REASON=""
hit() { REASON="$1"; }

# 고신호 시크릿 패턴
if   printf '%s' "$TEXT" | grep -qE -- '-----BEGIN ([A-Z]+ )?PRIVATE KEY-----'; then hit "private key 블록"
elif printf '%s' "$TEXT" | grep -qE 'AKIA[0-9A-Z]{16}'; then hit "AWS access key id"
elif printf '%s' "$TEXT" | grep -qE 'xox[baprs]-[0-9A-Za-z-]{10,}'; then hit "Slack 토큰"
elif printf '%s' "$TEXT" | grep -qE 'gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}'; then hit "GitHub 토큰"
elif printf '%s' "$TEXT" | grep -qE 'AIza[0-9A-Za-z_-]{35}'; then hit "Google API key"
elif printf '%s' "$TEXT" | grep -qE 'sk-[A-Za-z0-9]{20,}'; then hit "API secret key (sk-...)"
elif printf '%s' "$TEXT" | grep -qiE '(api[_-]?key|secret|token|passwd|password|client[_-]?secret|access[_-]?key)["'"'"' ]*[:=][ ]*["'"'"'][A-Za-z0-9_./+-]{16,}["'"'"']'; then hit "하드코딩된 크리덴셜(key=\"...\")"
fi

if [ -z "$REASON" ]; then
  # PostToolUse 깨끗한 재작성 → 이전 시크릿 표시 제거(self-heal)
  case "$EVENT" in PostToolUse) [ -n "$FP" ] && fpp_ledger_clear secret "$FP" ;; esac
  exit 0
fi

FIXMSG="시크릿을 코드/명령에서 제거하고 환경변수·시크릿 매니저로 옮기세요. 이미 노출됐다면 즉시 로테이트(폐기·재발급)하세요."
LOC=""; [ -n "$FP" ] && LOC=" ($FP)"

if [ "$MODE" = "enforce" ]; then
  case "$EVENT" in
    PreToolUse) fpp_deny "$NAME" "$REASON 노출 시도$LOC" "$FIXMSG" ;;
    *)          [ -n "$FP" ] && fpp_ledger_record secret "$FP" "$REASON 작성됨 — 제거+로테이트 필요: $FP"
                fpp_feedback "$NAME" "$REASON 작성 감지$LOC" "$FIXMSG" ;;
  esac
else
  fpp_advise "$NAME" "$REASON 감지$LOC" "$FIXMSG"
fi
