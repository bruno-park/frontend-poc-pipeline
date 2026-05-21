#!/bin/bash
# Jira PRD 업로드 히스토리 기록
input=$(cat)

issue_key=$(echo "$input" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(data.get('tool_input', {}).get('issue_key', 'unknown'))
" 2>/dev/null)

log_dir="$HOME/.claude"
mkdir -p "$log_dir"
echo "$(date '+%Y-%m-%d %H:%M') [PRD] uploaded: $issue_key" >> "$log_dir/prd-history.log"
