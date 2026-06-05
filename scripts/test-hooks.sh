#!/usr/bin/env bash
# test-hooks.sh — frontend-poc-pipeline hooks fixture 하네스.
# 각 hook 에 stdin JSON 을 투입해 exit 코드 / 출력(stderr·stdout JSON)을 단정한다.
# jq 경로와 python3 fallback(FPP_FORCE_PY=1) 양쪽으로 핵심 케이스를 돌린다.
#
# 사용:  bash scripts/test-hooks.sh
# 종료코드: 실패 0건이면 0, 아니면 1.

set -uo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOKS="$REPO/plugins/frontend-poc-pipeline/hooks"
PASS=0; FAIL=0
FAILED_NAMES=""

# run_hook <script> <json> [env "K=V K=V"]  →  전역 OUT/ERR/CODE 설정
run_hook() {
  local script="$1" json="$2" envs="${3:-}"
  local tmp_out tmp_err
  tmp_out="$(mktemp)"; tmp_err="$(mktemp)"
  # shellcheck disable=SC2086
  printf '%s' "$json" | env $envs bash "$HOOKS/$script" >"$tmp_out" 2>"$tmp_err"
  CODE=$?
  OUT="$(cat "$tmp_out")"; ERR="$(cat "$tmp_err")"
  rm -f "$tmp_out" "$tmp_err"
}

ok()   { PASS=$((PASS+1)); printf '  ✓ %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); FAILED_NAMES="$FAILED_NAMES\n   - $1"; printf '  ✗ %s\n     %s\n' "$1" "${2:-}"; }

assert_code()     { [ "$CODE" = "$2" ] && ok "$1" || bad "$1" "expected exit $2, got $CODE (ERR=$ERR OUT=$OUT)"; }
assert_err_has()  { printf '%s' "$ERR" | grep -qF "$2" && ok "$1" || bad "$1" "stderr lacks '$2' (ERR=$ERR)"; }
assert_out_has()  { printf '%s' "$OUT" | grep -qF "$2" && ok "$1" || bad "$1" "stdout lacks '$2' (OUT=$OUT)"; }
assert_no_output(){ [ -z "$OUT$ERR" ] && ok "$1" || bad "$1" "expected no output (OUT=$OUT ERR=$ERR)"; }
assert_json_out() { printf '%s' "$OUT" | python3 -m json.tool >/dev/null 2>&1 && ok "$1" || bad "$1" "stdout not valid JSON (OUT=$OUT)"; }

section() { printf '\n== %s ==\n' "$1"; }

# JSON 빌더 (따옴표/역슬래시 안전하게 python 으로). 값은 env 로 전달.
json_bash()  { J_CMD="$1"  python3 -c 'import json,os;print(json.dumps({"hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":os.environ["J_CMD"]}}))'; }
json_write() { J_FP="$1" J_CT="${2:-}" python3 -c 'import json,os;print(json.dumps({"hook_event_name":"PostToolUse","tool_name":"Write","tool_input":{"file_path":os.environ["J_FP"],"content":os.environ["J_CT"]}}))'; }
json_edit()  { J_FP="$1" J_NS="${2:-}" python3 -c 'import json,os;print(json.dumps({"hook_event_name":"PostToolUse","tool_name":"Edit","tool_input":{"file_path":os.environ["J_FP"],"old_string":"x","new_string":os.environ["J_NS"]}}))'; }
json_subagent() { J_AT="$1" python3 -c 'import json,os;print(json.dumps({"hook_event_name":"SubagentStop","agent_type":os.environ["J_AT"],"session_id":"t-sess"}))'; }
json_stop()     { printf '%s' '{"hook_event_name":"Stop"}'; }

# ─────────────────────────────────────────────────────────────────────────────
# hook 별 케이스 파일을 source (scripts/hook-tests/<hook>.cases.sh).
shopt -s nullglob
for f in "$REPO"/scripts/hook-tests/*.cases.sh; do
  . "$f"
done
shopt -u nullglob

printf '\n────────────────────────────\n'
printf 'PASS=%s  FAIL=%s\n' "$PASS" "$FAIL"
if [ "$FAIL" -gt 0 ]; then printf 'FAILED:%b\n' "$FAILED_NAMES"; exit 1; fi
echo "all hook tests passed"
