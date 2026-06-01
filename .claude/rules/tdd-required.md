# Rule: 코드 작성 시 TDD 필수

기능 코드를 새로 작성하거나 기존 코드를 수정할 때 **반드시** TDD 순서를 따른다.

**코드 작성 요청을 받으면 다른 어떤 작업보다 TDD를 최우선으로 적용한다.** 구현 코드를 먼저 쓰고 테스트를 나중에 붙이는 것은 예외(아래) 외에는 금지다. planner.md 작성 직후(`planner-required.md`) RED 테스트부터 시작한다.

## TDD 3단계 순서

```
1. RED   → /test-writer  : 실패하는 테스트 먼저 작성, 모든 테스트 FAIL 확인
2. GREEN → /code-writer  : 테스트를 통과하는 최소 구현
3. REFACTOR → /refactor  : 테스트 GREEN 유지하며 코드 정리
```

## 강제 사항

1. 테스트 없이 구현 코드를 먼저 작성하지 않는다.
2. RED 단계에서 테스트가 PASS되면 진행하지 않는다 — 반드시 FAIL 상태를 확인한 후 GREEN 단계로 넘어간다.
3. REFACTOR 단계에서 테스트가 깨지면 해당 리팩터링을 되돌린다.

## 예외

- 설정 파일, 타입 정의만 변경하는 경우
- `planner.md` 작성 등 코드가 아닌 문서 작업
- UI 스타일링만 변경하는 경우 (Tailwind 클래스, CSS 수정 — 로직 변화 없음)
- 긴급 핫픽스: `/hotfix` 스킬 사용 시 별도 fast-path 허용

## 관련 스킬

- `plugins/frontend-poc-pipeline/skills/test-writer/SKILL.md`
- `plugins/frontend-poc-pipeline/skills/code-writer/SKILL.md`
- `plugins/frontend-poc-pipeline/skills/refactor/SKILL.md`
