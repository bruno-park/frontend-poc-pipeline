#!/bin/bash
# Gate: 구현 코드 작성 후 코드 리뷰 강제
# Trigger: PostToolUse(Write) — pageComponents/**/*.tsx (비테스트 파일) 감지 시 발동

set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"
fpp_read_stdin
INPUT="$(fpp_file_path)
$(fpp_write_text)"

if echo "$INPUT" | grep -q 'pageComponents' \
  && echo "$INPUT" | grep -q '\.tsx' \
  && ! echo "$INPUT" | grep -qE '\.test\.tsx|\.spec\.ts'; then
  cat <<'EOF'
[code-review-gate] 구현 코드 작성 감지.

PR 생성 전에 반드시 코드 리뷰를 실행하세요:

  /code-review

통과 기준 (Critical/High 이슈 0개):
  - any 타입 사용 없음
  - console.log / debugger 없음
  - RBAC 누락 없음 (권한 체크 없는 보호 라우트)
  - naming 규칙 준수 (conventions/SKILL.md 기준)
  - px 단위 미사용 (rem/Tailwind 클래스 사용)

코드 리뷰 PASS 후에만 /pull-request-description 을 실행하세요.
EOF
fi
