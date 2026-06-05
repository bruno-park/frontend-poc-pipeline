#!/bin/bash
# Gate: planner.md 작성 후 Figma 내용 일치 검증 요청
# Trigger: PostToolUse(Write) — planner.md 또는 screen-plan.md 감지 시 발동

set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"
fpp_read_stdin
# 입력은 stdin JSON (환경변수 입력이 아님)
INPUT="$(fpp_file_path)
$(fpp_write_text)"

if echo "$INPUT" | grep -qE 'planner\.md|screen-plan\.md'; then
  cat <<'EOF'
[planner-figma-check] planner.md 작성 감지.

다음 단계로 진행하기 전에 반드시 Figma 원본과의 갭을 검증하세요:

  /figma-prd-validator

검증 통과 기준:
  - planner.md 컴포넌트 목록이 Figma 화면 구성과 일치
  - URL State 섹션이 Figma URL/query 파라미터와 일치
  - 누락된 AC 항목 없음

갭이 발견되면 planner.md를 수정한 후 Phase 3/4로 진행하세요.
EOF
fi
