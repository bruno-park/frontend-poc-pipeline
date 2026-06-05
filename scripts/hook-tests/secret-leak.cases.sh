# secret-leak-guard 케이스.
EN="FPP_HOOK_SECRET_LEAK=enforce"
S="secret-leak-guard.sh"

section "secret-leak: PreToolUse(Bash) 시크릿 노출 → enforce exit 2"
run_hook "$S" "$(json_bash 'echo "-----BEGIN RSA PRIVATE KEY-----" > id_rsa')" "$EN"; assert_code "private key 블록" 2
run_hook "$S" "$(json_bash 'export AWS=AKIAIOSFODNN7EXAMPLE')" "$EN";              assert_code "AWS access key" 2
run_hook "$S" "$(json_bash 'curl -H "token: ghp_abcdefghijklmnopqrstuvwxyz0123456789"')" "$EN"; assert_code "GitHub 토큰" 2
run_hook "$S" "$(json_bash 'echo xoxb-1234567890-abcdefghijkl')" "$EN";           assert_code "Slack 토큰" 2
run_hook "$S" "$(json_bash 'API_KEY="sk-abcdefghijklmnopqrstuvwxyz"')" "$EN";      assert_code "sk- 키" 2
run_hook "$S" "$(json_bash 'echo hello')" "$EN";                                   assert_code "안전 명령 통과" 0
run_hook "$S" "$(json_bash 'npm install axios')" "$EN";                            assert_no_output "npm install 무출력"

section "secret-leak: PostToolUse(Write) 시크릿 작성 → enforce exit 2(피드백)"
run_hook "$S" "$(json_write '/tmp/.env' 'API_KEY="abcd1234efgh5678ijkl"')" "$EN";  assert_code "key=값 작성" 2
run_hook "$S" "$(json_write '/tmp/.env' 'API_KEY="abcd1234efgh5678ijkl"')" "$EN";  assert_err_has "FIX(로테이트) 안내" "로테이트"
run_hook "$S" "$(json_write '/tmp/key.pem' '-----BEGIN PRIVATE KEY-----')" "$EN";  assert_code "private key 작성" 2
run_hook "$S" "$(json_write '/tmp/Foo.tsx' 'const x = 1;')" "$EN";                  assert_no_output "일반 코드 무출력"

section "secret-leak: 모드 분기"
run_hook "$S" "$(json_bash 'echo ghp_abcdefghijklmnopqrstuvwxyz0123456789')" "FPP_HOOK_SECRET_LEAK=warn"; assert_code "warn 차단 안 함" 0
run_hook "$S" "$(json_bash 'echo ghp_abcdefghijklmnopqrstuvwxyz0123456789')" "FPP_HOOK_SECRET_LEAK=warn"; assert_err_has "warn 경고" "WARN"
run_hook "$S" "$(json_bash 'echo ghp_abcdefghijklmnopqrstuvwxyz0123456789')" "FPP_HOOK_SECRET_LEAK=off"; assert_no_output "off 무출력"
run_hook "$S" "$(json_bash 'echo ghp_abcdefghijklmnopqrstuvwxyz0123456789')" "$EN FPP_FORCE_PY=1"; assert_code "fallback 차단" 2
