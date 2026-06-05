#!/usr/bin/env bash
# pipeline-order-guard.sh — 파이프라인 순서 강제 (PreToolUse:Write).
# pageComponents 아래 "새 구현 파일"을 만들 때:
#   1) feature 의 planner.md 가 먼저 존재해야 함 (planner-required)
#   2) 컴포넌트(.tsx)면 대응 RED 테스트가 먼저 존재해야 함 (tdd-required)
# 기존 파일 편집(Edit/덮어쓰기)은 건드리지 않음 → 새 파일 생성 순간만 게이트.
# enforce → 차단(exit 2) / warn → 경고 / off → 통과.

set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"
fpp_read_stdin

NAME="pipeline-order"
[ "$(fpp_tool_name)" = "Write" ] || exit 0
MODE="$(fpp_mode "$NAME")"
[ "$MODE" = "off" ] && exit 0

FP="$(fpp_file_path)"
[ -z "$FP" ] && exit 0
[ -f "$FP" ] && exit 0                                  # 이미 존재 = 편집 → 통과
printf '%s' "$FP" | grep -q '/pageComponents/' || exit 0
printf '%s' "$FP" | grep -qE '\.(ts|tsx)$' || exit 0

BASE="$(basename "$FP")"
case "$BASE" in
  *.test.*|*.spec.*|planner.md|*.d.ts|index.ts|index.tsx|types.ts|*.stories.*) exit 0 ;;
esac

emit() {  # <reason> <fix>
  if [ "$MODE" = "enforce" ]; then fpp_deny "$NAME" "$1" "$2"; else fpp_advise "$NAME" "$1" "$2"; fi
}

FEAT_ROOT="$(printf '%s' "$FP" | sed -E 's#(.*/pageComponents/[^/]+)/.*#\1#')"

# 1) planner.md 선존재
if [ ! -f "$FEAT_ROOT/planner.md" ] \
   && [ -z "$(find "$FEAT_ROOT" -maxdepth 2 -name planner.md 2>/dev/null | head -1)" ]; then
  emit "planner.md 없이 구현 파일 생성 시도: $BASE (feature: ${FEAT_ROOT##*/})" \
       "먼저 /feature-planner 로 $FEAT_ROOT/planner.md 를 작성하세요 (planner-required)."
fi

# 2) 컴포넌트(.tsx, PascalCase) → 대응 RED 테스트 선존재
if printf '%s' "$BASE" | grep -qE '^[A-Z][A-Za-z0-9]*\.tsx$'; then
  STEM="${BASE%.tsx}"
  if [ -z "$(find "$FEAT_ROOT" \( -name "$STEM.test.tsx" -o -name "$STEM.spec.tsx" -o -name "$STEM.test.ts" \) -print 2>/dev/null | head -1)" ]; then
    emit "실패 테스트(RED) 없이 컴포넌트 생성 시도: $BASE" \
         "먼저 /test-writer 로 $STEM.test.tsx 를 작성(RED 확인)하세요 (tdd-required)."
  fi
fi
exit 0
