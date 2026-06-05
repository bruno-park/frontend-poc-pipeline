#!/bin/bash
# Gate: E2E 테스트 파일 작성 후 실행 가이드
# Trigger: PostToolUse(Write) — *.e2e.ts / *.e2e.tsx / playwright 관련 파일 감지 시 발동

set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"
fpp_read_stdin
INPUT="$(fpp_file_path)
$(fpp_write_text)"

if ! echo "$INPUT" | grep -qE '\.e2e\.(ts|tsx)|playwright'; then
  exit 0
fi

cat <<'EOF'
[e2e-test-gate] E2E 테스트 파일 작성 감지.

다음 항목을 확인하세요:

  1. 테스트 목록 확인
     npx playwright test --list

  2. 단건 실행으로 RED 상태 확인
     npx playwright test <파일명> --headed

  3. 품질 기준
     - Page Object Model 패턴 사용 여부
     - data-testid 대신 ARIA role/text 셀렉터 사용
     - 각 AC 항목에 대응하는 시나리오 존재 여부

테스트 통과 후 /code-review → /pull-request-description 순서로 진행하세요.
EOF
