#!/usr/bin/env bash
# bash-safety-guard.sh — PreToolUse(Bash) 위험 명령 가드.
#
# 포지셔닝: 완전한 보안 경계가 아니라 catastrophic·난독화 사고를 막는 defense-in-depth.
#           1차 경계는 Claude Code 권한 시스템. 난독화(변수 치환·base64 등)는 best-effort.
# 모델: 하드-deny(치명 패턴) + 위험 shell-eval(네트워크 파이프-셸 등) + force push.
# 출력: enforce → exit 2(차단) / warn → 경고만(exit 0) / off → 통과.

set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"
fpp_read_stdin

NAME="bash-safety"
[ "$(fpp_tool_name)" = "Bash" ] || exit 0
MODE="$(fpp_mode "$NAME")"
[ "$MODE" = "off" ] && exit 0

CMD="$(fpp_bash_cmd)"
[ -z "$CMD" ] && exit 0
# 매칭용 정규화: 개행→공백, 연속 공백 1칸
C="$(printf '%s' "$CMD" | tr '\n\t' '  ' | tr -s ' ')"

# 보호 브랜치(설정 가능). 기본 main/master/release/*
PROT="$(fpp_cfg '.protectedBranches' '')"

REASON=""; FIX=""
flag() { REASON="$1"; FIX="${2:-}"; }

# ── 치명 패턴 (hard-deny) ────────────────────────────────────────────────────
# 1) 위험 대상 rm -rf : 루트/홈/와일드카드/.git/프로젝트 루트
if printf '%s' "$C" | grep -Eq '(^|[; &|])(/bin/)?rm +(-[a-zA-Z]*[rR][a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*[rR]|-[rR] +-f|-f +-[rR]|--recursive|--force|--no-preserve-root)\b'; then
  if printf '%s' "$C" | grep -Eq '( /($|[ /])| /\*|~($|[ /])|\$\{?HOME|\$CLAUDE_PROJECT_DIR| /(var|etc|usr|s?bin|lib(64)?|opt|boot|sys|proc|dev|root|Library|System|Applications)($|[ /])|\.git($|[ /])| \*( |$)| \.\.?( |$)|--no-preserve-root)'; then
    flag "위험한 rm -rf (루트/홈/시스템경로/와일드카드/.git 대상) 감지" \
         "삭제 대상을 명시적 하위 경로로 좁히세요. 변수(\$VAR) 경로면 값을 먼저 echo로 확인. (./build·dist 등 프로젝트 산출물 삭제는 허용)"
  fi
fi
# 1b) 변수/우회로 rm 토큰이 안 보여도 recursive-force 플래그가 위험대상을 향하면 차단
if [ -z "$REASON" ] && printf '%s' "$C" | grep -Eq '\-(rf|fr|Rf|fR)\b' \
   && printf '%s' "$C" | grep -Eq '(~($|[ /])|\$HOME| / | /\*)'; then
  flag "recursive-force 삭제 플래그가 홈/루트를 향함 (난독화 가능성)" \
       "명시 경로로 좁히고 위험 대상(~,/) 직접 삭제를 피하세요."
fi
# 2) find ... -exec rm -rf
if [ -z "$REASON" ] && printf '%s' "$C" | grep -Eq 'find .* -exec +(/bin/)?rm +-[a-zA-Z]*[rR]'; then
  flag "find -exec rm -r 대량 삭제 감지" "대상을 검토하고 -delete 대신 범위를 좁히거나 -print 로 먼저 확인."
fi
# 3) forkbomb
if [ -z "$REASON" ] && printf '%s' "$C" | grep -Eq ':\(\) *\{ *:\|: *&? *\} *;? *:'; then
  flag "fork bomb 패턴 감지" "해당 명령을 실행하지 마세요."
fi
# 4) chmod -R 777
if [ -z "$REASON" ] && printf '%s' "$C" | grep -Eq 'chmod +(-[a-zA-Z]*[R][a-zA-Z]*|--recursive) +0?777'; then
  flag "chmod -R 777 (전체 권한 개방) 감지" "필요한 최소 권한만 부여하세요 (예: 755/644)."
fi
# 5) 디스크 파괴
if [ -z "$REASON" ] && printf '%s' "$C" | grep -Eq '(^|[; &|])dd +.*of=/dev/|mkfs(\.|\b)| > */dev/sd|> */dev/disk'; then
  flag "디스크 직접 쓰기/포맷 감지" "장치 경로를 재확인하세요. 거의 항상 의도치 않은 파괴적 작업입니다."
fi

# ── 위험 shell-eval (네트워크 → 셸) ─────────────────────────────────────────
if [ -z "$REASON" ] && printf '%s' "$C" | grep -Eq '(curl|wget|fetch)\b.*\|\s*(sudo +)?(sh|bash|zsh|dash)\b'; then
  flag "원격 스크립트 파이프 실행 (curl|sh) 감지" "스크립트를 먼저 파일로 내려받아 내용을 검토한 뒤 실행하세요."
fi
if [ -z "$REASON" ] && printf '%s' "$C" | grep -Eq '(sh|bash|zsh) +<\(\s*(curl|wget)'; then
  flag "프로세스 치환으로 원격 스크립트 실행 (<(curl)) 감지" "내려받아 검토 후 실행하세요."
fi
if [ -z "$REASON" ] && printf '%s' "$C" | grep -Eq 'base64 +(-[a-zA-Z]*d|--decode)\b.*\|\s*(sh|bash|zsh)\b'; then
  flag "base64 디코드 → 셸 실행 감지 (난독화)" "디코드 결과를 먼저 출력해 검토하세요."
fi
if [ -z "$REASON" ] && printf '%s' "$C" | grep -Eq '(sh|bash|zsh) +-c +"?\$\((curl|wget)'; then
  flag "sh -c \"\$(curl ...)\" 원격 실행 감지" "내려받아 검토 후 실행하세요."
fi

# ── git force push / force refspec ──────────────────────────────────────────
if [ -z "$REASON" ] && printf '%s' "$C" | grep -Eq 'git\b.*\bpush\b'; then
  # --force-with-lease 는 허용
  if printf '%s' "$C" | grep -Eq '(--force([^-]|$)|(^| )-f( |$))' && ! printf '%s' "$C" | grep -Eq -- '--force-with-lease'; then
    flag "git push --force 감지" "히스토리 덮어쓰기 위험. --force-with-lease 사용을 권장."
  elif printf '%s' "$C" | grep -Eq 'push +[^ ]+ +\+'; then
    flag "git push force refspec(+ref) 감지" "force 강제 푸시. --force-with-lease 또는 일반 push 사용."
  fi
fi

# ── git reset --hard 는 경고만 ───────────────────────────────────────────────
WARN_ONLY=""
if [ -z "$REASON" ] && printf '%s' "$C" | grep -Eq 'git +.*reset +--hard'; then
  WARN_ONLY="git reset --hard 는 작업 트리 변경을 되돌립니다 — 미커밋 변경 손실 주의."
fi

# ── 판정 ─────────────────────────────────────────────────────────────────────
if [ -n "$REASON" ]; then
  if [ "$MODE" = "enforce" ]; then fpp_deny "$NAME" "$REASON" "$FIX"; else fpp_advise "$NAME" "$REASON" "$FIX"; fi
fi
if [ -n "$WARN_ONLY" ]; then fpp_advise "$NAME" "$WARN_ONLY"; fi
exit 0
