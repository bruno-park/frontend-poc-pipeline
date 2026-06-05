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

section "post-write-advisor: 통합 안내 디스패처 (stdin, 경로별 분기)"
A="post-write-advisor.sh"
run_hook "$A" "$(json_write '/p/Foo.tsx' 'console.log(1)')" "";        assert_out_has "console.log 감지" "console.log"
run_hook "$A" "$(json_write '/p/package.json' '{}')" "";               assert_out_has "package.json 안내" "[deps]"
run_hook "$A" "$(json_write '/p/planner.md' 'x')" "";                  assert_out_has "planner.md 안내" "[planner]"
run_hook "$A" "$(json_write '/p/Login.test.tsx' 'x')" "";              assert_out_has "테스트 안내" "[test]"
run_hook "$A" "$(json_write '/p/flow.e2e.ts' 'x')" "";                 assert_out_has "e2e 안내" "[e2e]"
run_hook "$A" "$(json_write '/p/pageComponents/x/View.tsx' 'const x=1')" ""; assert_out_has "리뷰 안내" "[review]"
run_hook "$A" "$(json_write '/p/Foo.tsx' 'const x = 1;')" "";          assert_no_output "정상 코드 무출력"
run_hook "$A" "$(json_write '/p/README.md' 'hi')" "";                  assert_no_output "무관 파일 무출력"
run_hook "$A" "$(json_write '/p/planner.md' 'x')" "FPP_HOOK_POST_ADVISOR=off"; assert_no_output "off 침묵"
