# planner-schema-guard + subagent-regate 케이스.
EN="FPP_HOOK_PLANNER_SCHEMA=enforce"
SD="planner-schema-guard.sh"
SR="subagent-regate.sh"

# 완전한 planner.md 작성
_mk_full_planner() {
  cat > "$1" <<'EOF'
# planner: 로그인 화면
## 컴포넌트 구조
- LoginForm
## 데이터 흐름 (Hook Layer)
- useLogin
## URL state
- ?redirect=
## 구현 체크리스트
- [ ] 폼 검증
## 필드 데이터 모델
| 필드 | 타입 |
| --- | --- |
| email | string |
EOF
}
_mk_partial_planner() {  # 필드 표 + URL state 누락
  cat > "$1" <<'EOF'
# planner
## 컴포넌트 구조
- Foo
## Hook Layer
- useFoo
## 구현 체크리스트
- [ ] x
EOF
}

section "planner-schema: PostToolUse(Write planner.md)"
PD="$(mktemp -d)"; PFULL="$PD/planner.md"; PPART="$PD/planner.md"
_mk_full_planner "$PFULL"
run_hook "$SD" "$(json_write "$PFULL" 'x')" "$EN";  assert_code "완전한 planner.md 통과" 0
run_hook "$SD" "$(json_write "$PFULL" 'x')" "$EN";  assert_no_output "완전 planner 무출력"
_mk_partial_planner "$PPART"
run_hook "$SD" "$(json_write "$PPART" 'x')" "$EN";  assert_code "불완전 planner enforce → exit 2" 2
run_hook "$SD" "$(json_write "$PPART" 'x')" "$EN";  assert_err_has "누락-필드표 보고" "필드 데이터 모델"
run_hook "$SD" "$(json_write "$PPART" 'x')" "$EN";  assert_err_has "누락-URL state 보고" "URL state"
run_hook "$SD" "$(json_write "$PPART" 'x')" "FPP_HOOK_PLANNER_SCHEMA=warn"; assert_code "warn 모드 차단 안 함" 0
run_hook "$SD" "$(json_write "$PPART" 'x')" "FPP_HOOK_PLANNER_SCHEMA=warn"; assert_err_has "warn 경고" "WARN"
run_hook "$SD" "$(json_write "$PPART" 'x')" "FPP_HOOK_PLANNER_SCHEMA=off";  assert_no_output "off 무출력"
run_hook "$SD" "$(json_write "$PD/Foo.tsx" 'const x=1')" "$EN"; assert_no_output "planner.md 아닌 파일 무시"
rm -rf "$PD"

section "subagent-regate: SubagentStop 재게이트 (enforce)"
PROJ="$(mktemp -d)"; mkdir -p "$PROJ/pageComponents/login"
_mk_partial_planner "$PROJ/pageComponents/login/planner.md"
run_hook "$SR" "$(json_subagent 'frontend-poc-pipeline:architect')" "$EN CLAUDE_PROJECT_DIR=$PROJ"
assert_code "설계 에이전트 + 불완전 planner → exit 0(but JSON block)" 0
assert_out_has "decision:block JSON" '"decision":"block"'
assert_json_out "regate stdout 은 순수 JSON"
# 무관한 에이전트는 통과
run_hook "$SR" "$(json_subagent 'executor')" "$EN CLAUDE_PROJECT_DIR=$PROJ"; assert_no_output "비계획 에이전트 무시"
# 완전 planner 면 통과
_mk_full_planner "$PROJ/pageComponents/login/planner.md"
run_hook "$SR" "$(json_subagent 'feature-planner')" "$EN CLAUDE_PROJECT_DIR=$PROJ"; assert_no_output "완전 planner 통과"
rm -rf "$PROJ"
