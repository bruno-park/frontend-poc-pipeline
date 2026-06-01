# Rule: 컴포넌트 구현 전 planner.md 필수

새 화면·컴포넌트·훅을 구현하기 전에 **반드시** `planner.md`(구현 청사진)를 먼저 작성한다. planner.md 없이 곧바로 구현(테스트·코드 작성)에 들어가지 않는다.

## 적용 조건

다음 중 하나라도 해당하면 이 규칙이 발동한다.

- 새 화면/페이지/컴포넌트 구현 요청 ("UI 만들어", "화면 구현", "컴포넌트 구현")
- 새 React Query 훅 / API 연동 구현 요청
- Figma / PRD / Jira 티켓에서 구현 단계로 넘어가는 시점
- `pageComponents/[feature]/` 아래 신규 파일 생성이 필요한 작업

## 강제 사항

1. 구현에 들어가기 전에 `pageComponents/[feature]/planner.md`가 존재해야 한다. 없으면 `feature-planner` 스킬로 먼저 생성한다.
2. planner.md 없이 컴포넌트·훅 코드를 작성하지 않는다.
3. planner.md에는 최소한 컴포넌트 구조, 데이터 흐름(Hook Layer), URL state, 구현 체크리스트, 필드 데이터 모델(`필드 | 타입` 테이블)이 포함돼야 한다.
4. 순서는 **planner.md → RED → GREEN → REFACTOR** 다. planner.md 작성 후 TDD를 시작한다 (`tdd-required.md` 참고).

## 예외

- 긴급 핫픽스: `/hotfix` 스킬 fast-path 허용 (planner.md 생략 가능)
- 단일 파일 버그 수정·스타일 변경 등 구조 변화 없는 소규모 작업
- 설정 파일·타입 정의·문서만 변경하는 경우

## 관련 스킬

- `plugins/frontend-poc-pipeline/skills/feature-planner/SKILL.md`
- `plugins/frontend-poc-pipeline/skills/test-writer/SKILL.md`
- `plugins/frontend-poc-pipeline/skills/code-writer/SKILL.md`
