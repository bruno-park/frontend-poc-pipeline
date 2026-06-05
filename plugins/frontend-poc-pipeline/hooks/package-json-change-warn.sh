#!/bin/bash
# Gate: package.json 변경 시 패키지 추가 컨벤션 안내
# Trigger: PostToolUse(Write) — package.json 감지 시 발동

set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"
fpp_read_stdin
INPUT="$(fpp_file_path)
$(fpp_write_text)"

if ! echo "$INPUT" | grep -q 'package\.json'; then
  exit 0
fi

cat <<'EOF'
[package-json-change-warn] package.json 변경 감지.

패키지 추가 시 컨벤션을 확인하세요:

  UI 컴포넌트:    shadcn/ui 우선 → rsuite fallback
  서버 상태 관리: TanStack Query (React Query)
  스타일:         Tailwind CSS (CSS-in-JS 추가 금지)
  HTTP:           axios 또는 fetch (별도 클라이언트 추가 금지)

불필요한 패키지는 번들 사이즈를 증가시킵니다.
추가 전 plugins/frontend-poc-pipeline/skills/conventions/SKILL.md 를 확인하세요.
EOF
