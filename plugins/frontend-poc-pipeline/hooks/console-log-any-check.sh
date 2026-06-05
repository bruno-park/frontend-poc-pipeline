#!/bin/bash
# Gate: TypeScript 파일 작성 시 console.log / any 타입 즉시 감지
# Trigger: PostToolUse(Write) — *.ts / *.tsx (비테스트 파일) 감지 시 발동

set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"
fpp_read_stdin
INPUT="$(fpp_file_path)
$(fpp_write_text)"

# TS/TSX 파일인지 확인
if ! echo "$INPUT" | grep -qE '\.(ts|tsx)'; then
  exit 0
fi

# 테스트 파일 제외
if echo "$INPUT" | grep -qE '\.(test|spec)\.(ts|tsx)'; then
  exit 0
fi

ISSUES=""

if echo "$INPUT" | grep -q 'console\.log'; then
  ISSUES="${ISSUES}\n  - console.log 발견 (Critical)"
fi

if echo "$INPUT" | grep -qE ': any[^A-Za-z]|as any[^A-Za-z]|<any>'; then
  ISSUES="${ISSUES}\n  - any 타입 발견 (Critical)"
fi

if [ -n "$ISSUES" ]; then
  printf '[console-log-any-check] Critical 이슈 감지:\n'
  printf '%b\n' "$ISSUES"
  printf '\nPR 생성 전 반드시 수정하세요. (/code-review 기준)\n'
fi
