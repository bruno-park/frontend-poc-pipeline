#!/bin/bash
# Figma Dev Mode MCP 서버 응답 확인
if ! curl -s --max-time 2 http://127.0.0.1:3845/mcp > /dev/null 2>&1; then
  echo "⚠️  Figma MCP 서버 미응답"
  echo "   → Figma 데스크탑 앱을 열고 /mcp 로 재연결해 주세요"
  echo "   → 또는 description: URL을 직접 제공해 주세요"
fi
