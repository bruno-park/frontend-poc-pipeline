#!/bin/bash
# Jira PRD 업로드 전 필수 섹션 존재 여부 검증
input=$(cat)

description=$(echo "$input" | python3 -c "
import sys, json
data = json.load(sys.stdin)
tool_input = data.get('tool_input', {})
fields_str = tool_input.get('fields', '{}')
try:
    fields = json.loads(fields_str, strict=False)
    print(fields.get('description', ''))
except Exception:
    print('')
" 2>/dev/null)

if [ -z "$description" ]; then
  exit 0
fi

required=("## 4." "## 5." "## 8.")
labels=("4=기능정의서" "5=검증규칙" "8=검증결과")
missing=()

for i in "${!required[@]}"; do
  echo "$description" | grep -q "${required[$i]}" || missing+=("${labels[$i]}")
done

if [ ${#missing[@]} -gt 0 ]; then
  echo "⚠️  PRD 누락 섹션 감지: ${missing[*]}"
  echo "   확인 후 업로드하세요 (경고만 — 업로드는 계속 진행됩니다)"
fi
