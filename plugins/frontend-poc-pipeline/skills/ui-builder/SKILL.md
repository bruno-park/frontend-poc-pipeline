---
name: ui-builder
description: "[DEPRECATED — code-writer로 통합됨] UI 컴포넌트 구현은 이제 code-writer 스킬이 담당합니다. '/ui-builder' 호출 시 '/code-writer --ui'로 안내합니다. 직접 트리거하지 말고 code-writer를 사용하세요."
---

# UI Builder — DEPRECATED ⚠️

이 스킬은 **`code-writer`로 통합**되었습니다 (2026-06-01 트랙 일원화).

`ui-builder`와 `code-writer --ui`는 동일하게 `planner.md` → React 컴포넌트를 구현했고, `code-writer`가 더 풍부한 기능(URL state `useUrlQuery` 자동 셋업, `--mock` 모드, Figma/이미지 설계 분석, 검증 Phase)을 포함하므로 canonical로 채택되었습니다.

## 대신 사용하세요

```bash
# UI 컴포넌트만 구현 (TDD GREEN)
/code-writer --ui pageComponents/[feature]/planner.md

# API 훅(api-integration 위임) + UI 함께
/code-writer --all pageComponents/[feature]/planner.md
```

- UI 컴포넌트 구현 상세(shadcn/ui 우선, bottom-up, 로딩/에러/빈 상태, memo, 스타일링)는 모두 `code-writer` Phase 5 + `conventions` 스킬에 있습니다.
- API 훅 생성은 `code-writer --api`가 `api-integration` 스킬에 위임합니다.

> 이 파일은 기존 `/ui-builder` 호출 경로 호환을 위해 포인터로만 남아 있습니다. 신규 작업은 `code-writer`를 사용하세요.
