#!/usr/bin/env bash
# _lib.sh — frontend-poc-pipeline hooks 공유 라이브러리 (각 hook이 source).
#
# Claude Code hook I/O 계약 (공식 docs 검증):
#   - 입력: stdin 의 JSON (환경변수가 아니라 stdin 으로 전달됨)
#   - PreToolUse 차단:  exit 2 + stderr  (또는 exit 0 + JSON permissionDecision:deny)
#   - Stop/SubagentStop 차단: exit 0 + JSON {"decision":"block","reason":...}  (stdout은 순수 JSON만)
#   - PostToolUse: 차단 불가. exit 2 + stderr 는 Claude 에게 피드백으로 전달됨
#   - env: CLAUDE_PROJECT_DIR (프로젝트 루트), CLAUDE_PLUGIN_ROOT (플러그인 경로)
#
# 설정 우선순위(높은→낮은): FPP_HOOK_<NAME> env > .fpp-hooks.json hooks[name]
#                           > FPP_HOOKS_MODE env > .fpp-hooks.json mode > 기본 "warn"
# 전역 킬스위치: FPP_HOOKS_DISABLE=1  또는  .fpp-hooks.json {"disable":true}

# 주의: 이 파일은 source 되므로 set -e 를 켜지 않는다(호출 hook 을 죽일 수 있음).

FPP_RAW=""
FPP_SESSION_ID=""

# jq 가용 여부. FPP_FORCE_PY=1 이면 python3 fallback 강제(테스트용).
_fpp_have_jq() { [ "${FPP_FORCE_PY:-}" = "1" ] && return 1; command -v jq >/dev/null 2>&1; }

fpp_project_dir() { printf '%s' "${CLAUDE_PROJECT_DIR:-$PWD}"; }
fpp_config_file() { printf '%s/.fpp-hooks.json' "$(fpp_project_dir)"; }

# stdin 을 1회 읽어 FPP_RAW 에 보관 + session_id 추출.
fpp_read_stdin() {
  if [ -t 0 ]; then FPP_RAW=""; else FPP_RAW="$(cat 2>/dev/null || true)"; fi
  FPP_SESSION_ID="$(fpp_get '.session_id')"
}

# JSON 경로 추출. $1 = jq 스타일 경로(선두 '.'), 예: '.tool_input.file_path'
# jq 우선, 없으면 python3 fallback, 둘 다 없으면 빈 문자열.
fpp_get() {
  local path="$1"
  [ -z "${FPP_RAW:-}" ] && { printf ''; return 0; }
  if _fpp_have_jq; then
    printf '%s' "$FPP_RAW" | jq -r "($path) // empty" 2>/dev/null || printf ''
  elif command -v python3 >/dev/null 2>&1; then
    printf '%s' "$FPP_RAW" | FPP_PYPATH="${path#.}" python3 -c '
import sys, json, os
try:
    d = json.load(sys.stdin)
except Exception:
    print(""); sys.exit(0)
cur = d
for k in os.environ.get("FPP_PYPATH", "").split("."):
    if k == "":
        continue
    if isinstance(cur, dict) and k in cur:
        cur = cur[k]
    else:
        cur = ""; break
if isinstance(cur, (dict, list)):
    cur = json.dumps(cur, ensure_ascii=False)
print("" if cur is None else cur)
' 2>/dev/null || printf ''
  else
    printf ''
  fi
}

# 편의 getter
fpp_event()      { fpp_get '.hook_event_name'; }
fpp_tool_name()  { fpp_get '.tool_name'; }
fpp_agent_type() { fpp_get '.agent_type'; }
# Bash 명령
fpp_bash_cmd()   { fpp_get '.tool_input.command'; }
# Write/Edit/MultiEdit 파일 경로
fpp_file_path()  { fpp_get '.tool_input.file_path'; }
# 쓰여질/수정될 텍스트 (Write=content, Edit=new_string, MultiEdit=edits 직렬화)
fpp_write_text() {
  local t
  t="$(fpp_get '.tool_input.content')"
  [ -z "$t" ] && t="$(fpp_get '.tool_input.new_string')"
  [ -z "$t" ] && t="$(fpp_get '.tool_input.edits')"
  printf '%s' "$t"
}

# .fpp-hooks.json 값 추출. $1=jq경로, $2=기본값
fpp_cfg() {
  local path="$1" def="${2:-}" f
  f="$(fpp_config_file)"
  [ -f "$f" ] || { printf '%s' "$def"; return 0; }
  local v=""
  if _fpp_have_jq; then
    v="$(jq -r "($path) // empty" "$f" 2>/dev/null)"
  elif command -v python3 >/dev/null 2>&1; then
    v="$(FPP_CFG_FILE="$f" FPP_PYPATH="$path" python3 -c '
import sys, json, os, re
try:
    d = json.load(open(os.environ["FPP_CFG_FILE"]))
except Exception:
    print(""); sys.exit(0)
# jq 스타일 경로 토큰화: .key 와 ["key"] 모두 지원
toks = re.findall(r"\.([A-Za-z0-9_]+)|\[\"([^\"]+)\"\]", os.environ.get("FPP_PYPATH",""))
cur = d
for a, b in toks:
    k = a or b
    if isinstance(cur, dict) and k in cur: cur = cur[k]
    else: cur = ""; break
if isinstance(cur,(dict,list)): cur = json.dumps(cur, ensure_ascii=False)
print("" if cur is None else cur)
' 2>/dev/null)"
  fi
  [ -z "$v" ] && v="$def"
  printf '%s' "$v"
}

# hook 이름 → 대문자 env 토큰 (bash-safety → BASH_SAFETY)
_fpp_env_token() { printf '%s' "$1" | tr 'a-z-' 'A-Z_'; }

# 주어진 hook 의 모드 반환: off | warn | enforce
fpp_mode() {
  local name="$1" tok val
  tok="$(_fpp_env_token "$name")"
  # 전역 킬스위치
  if [ "${FPP_HOOKS_DISABLE:-}" = "1" ] || [ "$(fpp_cfg '.disable' '')" = "true" ]; then
    printf 'off'; return 0
  fi
  # 1) per-hook env
  eval "val=\"\${FPP_HOOK_${tok}:-}\""
  if [ -n "$val" ]; then printf '%s' "$val"; return 0; fi
  # 2) config per-hook
  val="$(fpp_cfg ".hooks[\"$name\"]" '')"
  if [ -n "$val" ]; then printf '%s' "$val"; return 0; fi
  # 3) global env mode
  if [ -n "${FPP_HOOKS_MODE:-}" ]; then printf '%s' "${FPP_HOOKS_MODE}"; return 0; fi
  # 4) config mode
  val="$(fpp_cfg '.mode' '')"
  if [ -n "$val" ]; then printf '%s' "$val"; return 0; fi
  # 5) 기본
  printf 'warn'
}

# ── 출력 헬퍼 ────────────────────────────────────────────────────────────────
# 공통 메시지 본문(헤더/REASON/FIX)을 stderr 로
_fpp_emit_msg() {
  local name="$1" verb="$2" reason="$3" fix="${4:-}"
  {
    printf '\n--- [FPP Hook: %s] %s ---\n' "$name" "$verb"
    printf 'REASON: %s\n' "$reason"
    [ -n "$fix" ] && printf 'FIX: %s\n' "$fix"
  } >&2
}

# 경고만(차단 안 함). warn 모드에서 사용. 항상 exit 0.
fpp_advise() {
  _fpp_emit_msg "$1" "WARN" "$2" "${3:-}"
  exit 0
}

# PreToolUse 차단. enforce 모드에서 사용. exit 2.
fpp_deny() {
  _fpp_emit_msg "$1" "BLOCK" "$2" "${3:-}"
  exit 2
}

# PostToolUse 피드백(차단 불가지만 Claude 에 전달). exit 2.
fpp_feedback() {
  _fpp_emit_msg "$1" "FIX REQUIRED" "$2" "${3:-}"
  exit 2
}

# Stop/SubagentStop 차단. stdout 은 순수 JSON 만. exit 0.
fpp_block_stop() {
  local name="$1" reason="$2" fix="${3:-}" full
  full="[FPP Hook: $name] $reason"
  [ -n "$fix" ] && full="$full | FIX: $fix"
  if _fpp_have_jq; then
    jq -nc --arg r "$full" '{decision:"block", reason:$r}'
  elif command -v python3 >/dev/null 2>&1; then
    FPP_REASON="$full" python3 -c 'import json,os; print(json.dumps({"decision":"block","reason":os.environ["FPP_REASON"]}, ensure_ascii=False))'
  else
    # 최후 수단: 수동 JSON 이스케이프(역슬래시/따옴표). 개행은 본문에 없다고 가정.
    local esc
    esc="$(printf '%s' "$full" | sed 's/\\/\\\\/g; s/"/\\"/g')"
    printf '{"decision":"block","reason":"%s"}' "$esc"
  fi
  exit 0
}

# ── 도구 감지 (fail-open 판단용) ─────────────────────────────────────────────
fpp_has_bin() { command -v "$1" >/dev/null 2>&1; }
fpp_local_bin() {
  # 프로젝트 node_modules/.bin 의 실행파일 경로(있으면) 출력
  local b="$(fpp_project_dir)/node_modules/.bin/$1"
  [ -x "$b" ] && printf '%s' "$b"
}

# ── planner.md 검증 (D + SubagentStop 재게이트 공용) ─────────────────────────
# stdin = planner 내용. stdout = 누락 섹션 목록(빈 출력이면 통과). 키워드 기반.
fpp_planner_missing() {
  local c m=""
  c="$(cat)"
  printf '%s' "$c" | grep -qiE '컴포넌트|component'                              || m="$m\n  - 컴포넌트 구조(Component)"
  printf '%s' "$c" | grep -qiE 'hook *layer|훅|데이터 ?흐름|data ?flow'          || m="$m\n  - 데이터 흐름/Hook Layer"
  printf '%s' "$c" | grep -qiE 'url *state|url *param|query *param|searchparam'  || m="$m\n  - URL state"
  printf '%s' "$c" | grep -qiE '체크리스트|checklist|구현 ?항목|\[ ?\]'          || m="$m\n  - 구현 체크리스트"
  if ! { printf '%s' "$c" | grep -qE '\|' \
         && printf '%s' "$c" | grep -qiE '필드|field' \
         && printf '%s' "$c" | grep -qiE '타입|type'; }; then
    m="$m\n  - 필드 데이터 모델 표(| 필드 | 타입 |)"
  fi
  printf '%b' "$m"
}

# ── 위반 ledger (PostToolUse 기록 → Stop 게이트가 차단) ──────────────────────
# PostToolUse 는 차단 불가하므로, 위반을 세션 ledger 에 적어두고 Stop hook 이
# 미해결이면 턴 종료를 막는다(진짜 강제). 라인 형식: check<TAB>key<TAB>message.
# key(보통 파일경로) 단위로 upsert/clear → 재작성 시 자동 self-heal.
fpp_ledger_path() {
  local dir; dir="$(fpp_guard_dir)"; mkdir -p "$dir" 2>/dev/null || true
  printf '%s/ledger' "$dir"
}
fpp_ledger_clear() {   # <check> <key>
  local check="$1" key="$2" f; f="$(fpp_ledger_path)"
  [ -f "$f" ] || return 0
  awk -F'\t' -v c="$check" -v k="$key" '!($1==c && $2==k)' "$f" > "$f.tmp" 2>/dev/null \
    && mv "$f.tmp" "$f" 2>/dev/null || true
}
fpp_ledger_record() {  # <check> <key> <message>
  local check="$1" key="$2" msg="$3" f; f="$(fpp_ledger_path)"
  fpp_ledger_clear "$check" "$key"
  printf '%s\t%s\t%s\n' "$check" "$key" "$msg" >> "$f" 2>/dev/null || true
}
fpp_ledger_messages() {  # stdout: "  - <message>" 목록 (없으면 빈 출력)
  local f; f="$(fpp_ledger_path)"
  [ -f "$f" ] || return 0
  awk -F'\t' 'NF>=3{print "  - "$3}' "$f" 2>/dev/null
}
fpp_ledger_reset() { rm -f "$(fpp_ledger_path)" 2>/dev/null || true; }

# ── Stop/SubagentStop 루프가드 ──────────────────────────────────────────────
# 같은 위반(fingerprint)으로 N회 차단 후엔 통과시켜 무한루프 방지.
# 상태는 소비 레포가 아니라 $TMPDIR 하위에 저장.
fpp_guard_dir() {
  local base="${TMPDIR:-/tmp}/fpp-hooks"
  local proj key
  proj="$(cd "$(fpp_project_dir)" 2>/dev/null && pwd -P || fpp_project_dir)"
  key="$(printf '%s|%s' "$proj" "${FPP_SESSION_ID:-nosession}" | cksum | awk '{print $1}')"
  printf '%s/%s' "$base" "$key"
}
# fpp_guard_should_pass <hookname> <fingerprint> <max>
#   반환 0(=pass, 더 막지 말 것) / 1(=계속 막아도 됨). 호출 시 카운터 증가.
fpp_guard_should_pass() {
  local name="$1" fp="$2" max="${3:-3}" dir file prev_fp prev_n
  dir="$(fpp_guard_dir)"; mkdir -p "$dir" 2>/dev/null || true
  file="$dir/$name"
  prev_fp=""; prev_n=0
  if [ -f "$file" ]; then
    prev_fp="$(sed -n '1p' "$file" 2>/dev/null)"
    prev_n="$(sed -n '2p' "$file" 2>/dev/null)"
    case "$prev_n" in ''|*[!0-9]*) prev_n=0 ;; esac
  fi
  local n
  if [ "$prev_fp" = "$fp" ]; then n=$((prev_n + 1)); else n=1; fi
  printf '%s\n%s\n' "$fp" "$n" > "$file" 2>/dev/null || true
  if [ "$n" -gt "$max" ]; then return 0; else return 1; fi
}
# 성공 시 카운터 리셋
fpp_guard_reset() {
  local name="$1" dir; dir="$(fpp_guard_dir)"
  rm -f "$dir/$name" 2>/dev/null || true
}
