---
name: unit-test-gen
description: planner.md와 Jira AC를 기반으로 단위 테스트를 TDD 방식으로 먼저 작성합니다. 플랫폼(web/ios/android/web-sdk)별 자동 분기.
---

# Unit Test Generator (TDD)

플랫폼을 감지하여 해당 플랫폼의 테스트 생성 가이드를 로드합니다.

## 플랫폼 감지

아래 순서로 플랫폼을 판단합니다:

1. **사용자 명시**: `--platform=ios` 등 인자가 있으면 해당 플랫폼
2. **프로젝트 파일 감지**:
   | 감지 파일 | 플랫폼 |
   |----------|--------|
   | `package.json` + `vitest` or `vite` | `web` |
   | `*.xcodeproj` or `Package.swift` | `ios` |
   | `build.gradle.kts` or `AndroidManifest.xml` | `android` |
   | `package.json` + SDK 구조 (no React) | `web-sdk` |
3. **판단 불가 시**: 사용자에게 선택 요청

## 플랫폼별 가이드

| 플랫폼 | 파일 | 상태 |
|--------|------|------|
| Web (React + Vitest) | [platforms/web.md](platforms/web.md) | ✅ 완료 |
| iOS | [platforms/ios.md](platforms/ios.md) | 📝 TODO |
| Android | [platforms/android.md](platforms/android.md) | 📝 TODO |
| Web SDK | [platforms/web-sdk.md](platforms/web-sdk.md) | 📝 TODO |

## 실행 흐름

```
1. 플랫폼 감지
2. platforms/{platform}.md 로드
3. 해당 가이드의 Phase 순서대로 실행
```
