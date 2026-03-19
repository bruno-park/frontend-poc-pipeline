---
name: component-audit
description: pageComponents 전체를 스캔하여 파이프라인 준수 여부를 분석합니다. planner.md 누락, any 타입, 테스트 부재, 브랜치 컨벤션 위반을 감지합니다.
---

# Component Audit

`pageComponents/` 디렉토리를 전수 분석하여 파이프라인 준수 현황을 리포트합니다.

## 트리거

- `/component-audit` 직접 호출
- `/workflow --status` 전체 현황 확인 시 자동 실행

---

## Phase 1: 모듈 목록 수집

```
Bash: find pageComponents -maxdepth 3 -type d | grep -v node_modules | sort
```

각 모듈에 대해 다음 정보를 병렬 수집:

---

## Phase 2: 각 Phase별 준수 여부 검사 (병렬 실행)

### Phase 2 검사 (planner.md 존재)
```
Glob: pageComponents/**/planner.md
```

### Phase 3 검사 (hook 파일 존재)
```
Glob: pageComponents/**/*.hook.ts
```

### Phase 4 검사 (테스트 파일 존재)
```
Glob: pageComponents/**/*.test.tsx, **/*.test.ts
```

### Phase 5 검사 (컴포넌트 파일 존재)
```
Glob: pageComponents/**/*.tsx (*.test.tsx 제외)
```

### any 타입 감지
```
Grep: ": any" in pageComponents/**/*.ts, **/*.tsx
→ 파일명 + 라인 번호 수집
```

### 브랜치 컨벤션 확인
```
Bash: git branch -a | grep -v "feature/" | grep -v "fix/" | grep -v "chore/" | grep -v "master" | grep -v "main" | grep -v "release" | grep -v "HEAD" | head -20
```

---

## Phase 3: 모듈별 리포트 생성

각 모듈(pageComponents/[module]/)에 대해:

```
## 모듈별 파이프라인 준수 현황

| 모듈 | Phase 2 (planner.md) | Phase 3 (hooks) | Phase 4 (tests) | Phase 5 (components) | any 타입 |
|------|----------------------|-----------------|-----------------|----------------------|---------|
| partner-ad-management | ✅ | ✅ | ❌ | ✅ | ⚠️ 3개 |
| campaign-process      | ⚠️ (다른 이름) | ✅ | ❌ | ✅ | ⚠️ 1개 |
| ad-purchase           | ❌ | ✅ | ❌ | ✅ | ❌ 없음 |
```

---

## Phase 4: 종합 통계 및 우선순위

### 전체 요약
```
총 모듈: N개
planner.md 있음: X개 (X%)
hook 있음: X개 (X%)
테스트 있음: 0개 (0%)   ← 현재 nestads-frontend 현황
any 타입 발견: X개 파일
```

### 우선순위 권고
```
🔴 즉시 조치 필요:
  - 테스트 인프라 설치: /vitest-setup
  - any 타입 top 5: [파일 목록]

🟡 단기 개선:
  - planner.md 누락 모듈: [목록]

🟢 장기 개선:
  - 브랜치 컨벤션 정리
  - E2E 테스트 확장
```

---

## Phase 5: any 타입 자동 수정 제안

any 타입이 감지된 경우, 각 파일에 대해:

```typescript
// 발견된 any 타입
(props: any) → CellProps<IFeatureItem>
axios.post<any> → axios.post<IResponseType>
```

사용자에게 수정 여부 확인 후:
- **승인** → Edit tool로 자동 수정
- **거절** → 목록만 저장

---

## 완료 리포트 형식

```
## Component Audit 완료 — YYYY-MM-DD

### 전체 모듈: N개 분석

Phase 2 (planner.md): X/N ✅
Phase 3 (hooks):       X/N ✅
Phase 4 (테스트):      X/N ❌ ← 가장 시급
Phase 5 (컴포넌트):    X/N ✅

### any 타입 발견: X개 파일
[파일별 목록]

### 권고 명령어:
  /vitest-setup              → 테스트 인프라 설치
  /unit-test-gen WP-XXXX     → 우선 테스트 작성 대상
  /component-audit --fix-any → any 타입 일괄 수정
```
