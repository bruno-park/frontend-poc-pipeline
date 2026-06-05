#!/bin/bash
# Gate: gh pr create 실행 전 필수 체크리스트 확인
# Trigger: PreToolUse(Bash) — gh pr create 감지 시 발동

set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"
fpp_read_stdin
INPUT="$(fpp_bash_cmd)"

if ! echo "$INPUT" | grep -q 'gh pr create'; then
  exit 0
fi

cat <<'EOF'
[pr-gate-check] PR 생성 전 체크리스트 확인.

다음 항목이 모두 완료되었는지 확인하세요:

  1. /code-review 실행 완료 (Critical/High 이슈 0개)
  2. 모든 테스트 GREEN (프로젝트 러너로 run-once — Jest: npx jest / Vitest: npx vitest run ; conventions §13)
  3. TypeScript 빌드 오류 없음
     npx tsc --noEmit

미완료 항목이 있으면 PR 생성을 중단하고 해당 단계를 먼저 완료하세요.
EOF
