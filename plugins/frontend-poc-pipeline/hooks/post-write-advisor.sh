#!/usr/bin/env bash
# post-write-advisor.sh — PostToolUse(Write|Edit|MultiEdit) 안내 디스패처.
# 기존 advisory hook 6종(planner-figma / test-completeness / code-review-gate /
# console-log-any / package-json-warn / e2e-gate)을 하나로 통합.
# 파일 경로·내용을 보고 해당하는 안내를 모두 출력(차단 없음, exit 0). mode=off 면 침묵.

set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"
fpp_read_stdin

NAME="post-advisor"
[ "$(fpp_mode "$NAME")" = "off" ] && exit 0

FP="$(fpp_file_path)"
TEXT="$(fpp_write_text)"
[ -z "$FP" ] && exit 0

OUT=""
add() { OUT="${OUT}$1
"; }
is_test() { printf '%s' "$FP" | grep -qE '\.(test|spec)\.(ts|tsx)$'; }

# 1) planner.md → Figma 갭 검증 안내
if printf '%s' "$FP" | grep -qE 'planner\.md|screen-plan\.md'; then
  add "[planner] planner.md 감지 — 다음 단계 전 Figma 갭 검증: /figma-prd-validator (컴포넌트·URL state·AC 일치 확인)."
fi
# 2) 테스트 파일 → RED·AC 커버리지 안내
if printf '%s' "$FP" | grep -qE '\.(test\.tsx|spec\.ts)'; then
  add "[test] 테스트 작성 감지 — RED 확인(프로젝트 러너 run-once, conventions §13) + AC/RBAC 커버리지 + ARIA role 셀렉터(data-testid 지양) 점검."
fi
# 3) E2E 파일 → 실행 가이드
if printf '%s' "$FP" | grep -qE '\.e2e\.(ts|tsx)|playwright'; then
  add "[e2e] E2E 파일 감지 — npx playwright test --list 로 확인, 단건 RED 확인, POM·ARIA 셀렉터·AC 매핑 점검."
fi
# 4) pageComponents 구현 tsx(비테스트) → 코드 리뷰 안내
if printf '%s' "$FP" | grep -q 'pageComponents' && printf '%s' "$FP" | grep -q '\.tsx' && ! is_test; then
  add "[review] 구현 코드 감지 — PR 전 /code-review (any/console.log/RBAC/naming/px 단위 기준, Critical·High 0개)."
fi
# 5) ts/tsx(비테스트) 내용에 console.log/any → 경고
if printf '%s' "$FP" | grep -qE '\.(ts|tsx)$' && ! is_test; then
  ISSUES=""
  printf '%s' "$TEXT" | grep -q 'console\.log' && ISSUES="${ISSUES} console.log"
  printf '%s' "$TEXT" | grep -qE ': any[^A-Za-z]|as any[^A-Za-z]|<any>' && ISSUES="${ISSUES} any타입"
  [ -n "$ISSUES" ] && add "[lint] Critical 후보 감지:${ISSUES} — PR 전 제거 (/code-review 기준)."
fi
# 6) package.json → 패키지 컨벤션 안내
if printf '%s' "$FP" | grep -qE '(^|/)package\.json$'; then
  add "[deps] package.json 변경 — UI: shadcn/ui→rsuite, 서버상태: TanStack Query, 스타일: Tailwind, HTTP: axios/fetch. 불필요 패키지 지양 (conventions 참고)."
fi

[ -z "$OUT" ] && exit 0
printf '%s' "$OUT"
exit 0
