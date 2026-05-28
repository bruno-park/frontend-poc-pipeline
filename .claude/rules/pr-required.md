# Rule: PR/MR 생성 시 pull-request-description 스킬 필수

PR 또는 MR을 만드는 요청이 들어오면 **반드시** `pull-request-description` 스킬을 사용해야 한다.

## 적용 조건

다음 중 하나라도 해당하면 이 규칙이 발동한다.

- "PR 만들어", "MR 만들어", "PR 올려", "MR 올려"
- "PR 생성", "MR 생성", "pull request", "merge request"
- `gh pr create`, `git push` 후 PR 링크 요청
- 브랜치 작업 완료 후 PR/MR 요청

## 강제 사항

1. `plugins/frontend-poc-pipeline/skills/pull-request-description/SKILL.md` 를 읽고 그 지시를 따른다.
2. 스킬을 거치지 않고 직접 `gh pr create` 만 실행하는 것은 금지한다.
3. PR 본문을 임의로 작성하지 않는다 — 스킬이 정의한 템플릿을 사용한다.
