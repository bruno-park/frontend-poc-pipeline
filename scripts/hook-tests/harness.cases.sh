# 하네스 강제 케이스 — pipeline-order-guard(순서) + stop-gate(종착 게이트/ledger).

_full_planner() {
  cat > "$1" <<'EOF'
# planner
## 컴포넌트 구조
- X
## Hook Layer
- useX
## URL state
- ?t=
## 구현 체크리스트
- [ ] a
## 필드 데이터 모델
| 필드 | 타입 |
| a | string |
EOF
}
_partial_planner() { printf '# planner\n## 컴포넌트 구조\n- X\n' > "$1"; }

section "pipeline-order-guard: 새 구현 파일 생성 순서 강제 (PreToolUse:Write)"
PO="pipeline-order-guard.sh"; EN="FPP_HOOK_PIPELINE_ORDER=enforce"
P="$(mktemp -d)"; FEAT="$P/src/pageComponents/login"; mkdir -p "$FEAT"
# planner 없음 + 컴포넌트 생성 → 차단
run_hook "$PO" "$(json_write "$FEAT/LoginForm.tsx" 'x')" "$EN"; assert_code "planner 없이 컴포넌트 → 차단" 2
run_hook "$PO" "$(json_write "$FEAT/LoginForm.tsx" 'x')" "$EN"; assert_err_has "planner 안내" "planner.md"
# planner 생성 후 → 테스트 없으니 여전히 차단(TDD)
_full_planner "$FEAT/planner.md"
run_hook "$PO" "$(json_write "$FEAT/LoginForm.tsx" 'x')" "$EN"; assert_code "planner有/테스트無 컴포넌트 → 차단" 2
run_hook "$PO" "$(json_write "$FEAT/LoginForm.tsx" 'x')" "$EN"; assert_err_has "RED 테스트 안내" "RED"
# 테스트 생성 후 → 통과
: > "$FEAT/LoginForm.test.tsx"
run_hook "$PO" "$(json_write "$FEAT/LoginForm.tsx" 'x')" "$EN"; assert_code "planner+테스트 有 → 통과" 0
# 면제/통과 케이스
run_hook "$PO" "$(json_write "$FEAT/planner.md" 'x')" "$EN";        assert_code "planner.md 자체 면제" 0
run_hook "$PO" "$(json_write "$FEAT/Foo.test.tsx" 'x')" "$EN";      assert_code "테스트 파일 면제" 0
run_hook "$PO" "$(json_write "$FEAT/index.tsx" 'x')" "$EN";         assert_code "index.tsx 면제" 0
run_hook "$PO" "$(json_write "$P/src/utils/helper.ts" 'x')" "$EN";  assert_code "pageComponents 밖 면제" 0
# 기존 파일 편집은 통과
echo x > "$FEAT/Existing.tsx"
run_hook "$PO" "$(json_write "$FEAT/Existing.tsx" 'y')" "$EN";      assert_code "기존 파일(편집) 통과" 0
# warn 모드는 차단 안 함
run_hook "$PO" "$(json_write "$FEAT/Bar.tsx" 'x')" "FPP_HOOK_PIPELINE_ORDER=warn"; assert_code "warn 차단 안 함" 0
rm -rf "$P"

section "stop-gate: ledger 기반 종착 게이트 (PostToolUse 기록 → Stop 차단)"
SG="stop-gate.sh"; PS="planner-schema-guard.sh"
PJ="$(mktemp -d)"
EH="FPP_HOOK_PLANNER_SCHEMA=enforce FPP_HOOK_STOP_GATE=enforce CLAUDE_PROJECT_DIR=$PJ"
# 0) 깨끗하면 Stop 통과
run_hook "$SG" "$(json_stop)" "$EH"; assert_code "ledger 비어있음 → 종료 허용" 0
# 1) 불완전 planner 작성(PostToolUse) → ledger 기록
_partial_planner "$PJ/planner.md"
run_hook "$PS" "$(json_write "$PJ/planner.md" 'x')" "$EH"; assert_code "불완전 planner → feedback(exit2)" 2
# 2) 이제 Stop 이 차단
run_hook "$SG" "$(json_stop)" "$EH"; assert_code "미해결 위반 → Stop 차단(exit0+block)" 0
assert_out_has "decision:block" '"decision":"block"'
assert_json_out "stop-gate stdout 순수 JSON"
# 3) planner 보완 → ledger self-heal
_full_planner "$PJ/planner.md"
run_hook "$PS" "$(json_write "$PJ/planner.md" 'x')" "$EH"; assert_code "완전 planner → 통과" 0
# 4) Stop 이제 통과
run_hook "$SG" "$(json_stop)" "$EH"; assert_no_output "위반 해소 → 종료 허용(무출력)"
rm -rf "$PJ"

section "stop-gate: warn 은 차단 안 함 + 루프가드"
PJ2="$(mktemp -d)"; EW="FPP_HOOK_PLANNER_SCHEMA=enforce CLAUDE_PROJECT_DIR=$PJ2"
_partial_planner "$PJ2/planner.md"
run_hook "$PS" "$(json_write "$PJ2/planner.md" 'x')" "$EW"; assert_code "위반 기록" 2
run_hook "$SG" "$(json_stop)" "FPP_HOOK_STOP_GATE=warn CLAUDE_PROJECT_DIR=$PJ2"; assert_code "warn Stop 차단 안 함" 0
run_hook "$SG" "$(json_stop)" "FPP_HOOK_STOP_GATE=warn CLAUDE_PROJECT_DIR=$PJ2"; assert_err_has "warn 경고" "WARN"
# 루프가드: enforce 로 3회 차단 후 4회째 통과
EG="FPP_HOOK_STOP_GATE=enforce CLAUDE_PROJECT_DIR=$PJ2"
run_hook "$SG" "$(json_stop)" "$EG"; assert_out_has "block 1" '"decision":"block"'
run_hook "$SG" "$(json_stop)" "$EG"; assert_out_has "block 2" '"decision":"block"'
run_hook "$SG" "$(json_stop)" "$EG"; assert_out_has "block 3" '"decision":"block"'
run_hook "$SG" "$(json_stop)" "$EG"; assert_code "4회째 루프가드 통과" 0
rm -rf "$PJ2"
