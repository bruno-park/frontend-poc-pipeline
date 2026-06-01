#!/bin/bash
# Gate: 테스트 작성 후 완전성 검증 요청
# Trigger: PostToolUse(Write) — *.test.tsx 또는 *.spec.ts 감지 시 발동

set -euo pipefail

INPUT="${CLAUDE_TOOL_INPUT:-}"

if echo "$INPUT" | grep -qE '\.test\.tsx|\.spec\.ts'; then
  cat <<'EOF'
[test-completeness-check] 테스트 파일 작성 감지.

다음 항목을 반드시 확인하세요:

  1. RED 상태 확인 (모든 테스트가 FAIL이어야 함)
     # 프로젝트에 설정된 러너로 run-once (conventions §13). scripts.test(watch) 직접 실행 금지.
     # Jest:   npx jest --reporter=... 또는 npx jest 2>&1 | grep -E 'PASS|FAIL|✓|✗'
     # Vitest: npx vitest run --reporter=verbose 2>&1 | grep -E 'PASS|FAIL'

  2. AC 커버리지 확인
     - Jira 티켓의 AC 항목이 모두 테스트로 존재하는지 대조
     - RBAC 시나리오(권한별 분기) 포함 여부 확인

  3. 품질 기준
     - data-testid 셀렉터 미사용 (ARIA role/text 기반으로)
     - 접근성 시나리오(키보드 탐색, aria-label) 포함 여부 확인

RED 확인 후 /code-writer 로 GREEN 단계로 진행하세요.
EOF
fi
