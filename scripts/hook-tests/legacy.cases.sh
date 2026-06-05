# 마이그레이션된 legacy hook 케이스 — stdin 파싱으로 실제 발동하는지 검증(no-op 회귀 차단).

section "legacy: commit-message-check (mode-gated)"
run_hook "commit-message-check.sh" "$(json_bash 'git commit -m "feat: x"')" "FPP_HOOK_COMMIT_MSG=enforce"; assert_code "올바른 형식 통과" 0
run_hook "commit-message-check.sh" "$(json_bash 'git commit -m "blah"')" "FPP_HOOK_COMMIT_MSG=enforce"; assert_code "잘못된 형식 enforce → exit 2" 2
run_hook "commit-message-check.sh" "$(json_bash 'git commit -m "blah"')" "FPP_HOOK_COMMIT_MSG=warn"; assert_code "warn 모드 통과" 0
run_hook "commit-message-check.sh" "$(json_bash 'git commit -m "blah"')" "FPP_HOOK_COMMIT_MSG=warn"; assert_err_has "warn 경고" "WARN"
run_hook "commit-message-check.sh" "$(json_bash 'npm test')" "FPP_HOOK_COMMIT_MSG=enforce"; assert_no_output "git commit 아니면 무시"

section "legacy: branch-name-check (mode-gated)"
run_hook "branch-name-check.sh" "$(json_bash 'git checkout -b feat/WP-1-login')" "FPP_HOOK_BRANCH_NAME=enforce"; assert_code "올바른 브랜치 통과" 0
run_hook "branch-name-check.sh" "$(json_bash 'git checkout -b mybranch')" "FPP_HOOK_BRANCH_NAME=enforce"; assert_code "잘못된 브랜치 enforce → exit 2" 2

section "legacy: advisory PostToolUse hooks 가 실제로 발동(stdin)"
run_hook "console-log-any-check.sh" "$(json_write '/p/Foo.tsx' 'console.log(1)')" ""; assert_out_has "console.log 감지" "console.log"
run_hook "package-json-change-warn.sh" "$(json_write '/p/package.json' '{}')" ""; assert_out_has "package.json 변경 안내" "package-json-change-warn"
run_hook "planner-figma-check.sh" "$(json_write '/p/planner.md' 'x')" ""; assert_out_has "planner.md 안내" "planner-figma-check"
run_hook "console-log-any-check.sh" "$(json_write '/p/Foo.tsx' 'const x = 1;')" ""; assert_no_output "정상 코드 무출력"
