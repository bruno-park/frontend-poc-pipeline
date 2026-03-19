# UI Builder — Web (React + shadcn/ui + rsuite)

`planner.md`의 컴포넌트 스펙과 `api-integration`에서 생성된 훅을 기반으로 **React 컴포넌트를 구현**합니다.

## 트리거

- `/code-writer --ui` 호출 시
- `/code-writer --all` 호출 시 (Phase 2, api-integration 완료 후)

## 입력 컨텍스트

- `planner.md` 내용 (components, URL state 섹션)
- 생성된 훅 파일 목록 (api-integration 결과)
- Jira AC 목록 (있을 경우)

---

## Phase 1: 구현 순서 결정

planner.md의 컴포넌트 트리에서 구현 순서 결정:

```
Bottom-up 원칙: 자식 컴포넌트 → 부모 컴포넌트
1. Atom 컴포넌트 (Badge, Button 등)
2. 공통 컴포넌트 (common/)
3. 기능 컴포넌트 (filter/, table/, form/ 등)
4. 컨테이너 컴포넌트 (Feature.tsx)
```

---

## Phase 2: 기존 코드 패턴 파악

```
Glob: pageComponents/**/components/**/*.tsx (최근 2-3개)
Read → import 패턴, shadcn/ui 사용 방식, 스타일 패턴 확인
```

확인 항목:
- shadcn/ui 컴포넌트 import 경로 (`@/components/ui/*`)
- rsuite 사용 패턴
- Tailwind 클래스 규칙 (rem 단위 사용 등)
- memo() export 패턴
- useUrlQuery hook 사용 방식

---

## Phase 3: 컴포넌트 구현

### 컴포넌트 파일 기본 구조

```typescript
// pageComponents/[feature]/components/[section]/[Feature][Section].tsx
import { memo } from 'react'
// shadcn/ui 우선
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
// rsuite (shadcn에 없는 것만)
import { Table, Pagination } from 'rsuite'
// 훅 import (api-integration에서 생성된 것)
import { use[Feature] } from '../../hooks/use[Feature].hook'

interface I[Feature][Section]Props {
  // planner.md props 섹션 기반
}

const [Feature][Section] = ({ prop1, prop2 }: I[Feature][Section]Props) => {
  // planner.md state 섹션 기반
  const [searchValue, setSearchValue] = useState('')

  // 훅 사용 (leaf 컴포넌트에서 데이터 fetch)
  const { data, isFetching } = use[Feature]({ q: searchValue })

  return (
    <div className="flex flex-col gap-[1rem]">
      {/* 구현 */}
    </div>
  )
}

export default memo([Feature][Section])
```

### URL 상태 연동 (planner.md URL State 섹션 있을 경우)

```typescript
import { useUrlQuery } from '@/hooks/useUrlQuery'

const [Feature]Table = () => {
  const { urlQuery, setUrlQuery } = useUrlQuery({
    page: 1,
    size: 25,
    sortColumn: 'created_at',
    sortType: 'desc',
    q: '',
  })

  const { data, isFetching } = use[Feature](urlQuery)

  const handleSearch = (value: string) => {
    setUrlQuery({ q: value, page: 1 }) // 검색 시 page 리셋
  }

  // ...
}
```

### 로딩/에러/빈 상태 처리 (필수)

```typescript
// 로딩 상태
if (isFetching) {
  return <div className="animate-pulse">...</div> // 또는 Skeleton 컴포넌트
}

// 에러 상태
if (isError) {
  return <div className="text-red-500">데이터를 불러올 수 없습니다.</div>
}

// 빈 상태
if (!data || data.length === 0) {
  return <div className="text-gray-400 text-center py-[2rem]">데이터가 없습니다.</div>
}
```

### RBAC 처리 (planner.md에 권한 정보 있을 경우)

```typescript
import { usePageAuth } from '@/hooks/usePageAuth'

const [Feature]Table = () => {
  const { canCreate, canUpdate, canDelete } = usePageAuth()

  return (
    <>
      {canCreate && (
        <Button onClick={handleCreate}>생성</Button>
      )}
    </>
  )
}
```

---

## Phase 4: 스타일링 규칙

### Tailwind 사용 규칙

```typescript
// rem 단위 사용
<div className="p-[1.5rem] gap-[1rem] mt-[0.5rem]">

// px 단위 금지
<div className="p-[24px] gap-[16px]">

// 표준 Tailwind 클래스 우선
<div className="p-6 gap-4 mt-2">
```

### UI 컴포넌트 우선순위

```typescript
// 1순위: shadcn/ui
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Dialog, DialogContent, DialogHeader } from '@/components/ui/dialog'
import { Select, SelectContent, SelectItem, SelectTrigger } from '@/components/ui/select'

// 2순위: rsuite (shadcn에 없는 것)
import { Table, Column, HeaderCell, Cell } from 'rsuite-table'
import { DateRangePicker } from 'rsuite'
import { Pagination } from 'rsuite'
```

---

## Phase 5: memo() 사용 판단

planner.md의 memo 필드 기준으로 결정:

```typescript
// memo 권장: 안정적인 props, 부모가 자주 리렌더링
export default memo(ComponentName)

// memo 불필요: props가 매번 새로 생성되거나 단순 컴포넌트
export default ComponentName
```

---

## Phase 6: 페이지 파일 생성 (필요 시)

`pages/[route].tsx`가 없으면 생성:

```typescript
// pages/[feature]/index.tsx
import type { NextPage } from 'next'
import [Feature]Container from '@/pageComponents/[feature]/[Feature]Container'

const [Feature]Page: NextPage = () => {
  return <[Feature]Container />
}

export default [Feature]Page
```

---

## Phase 7: 생성 결과 확인

```
UI Builder 완료

생성된 파일:
  pageComponents/[feature]/[Feature]Container.tsx
  pageComponents/[feature]/components/filter/[Feature]Filter.tsx
  pageComponents/[feature]/components/table/[Feature]Table.tsx

pages/:
  pages/[feature]/index.tsx (신규)
```

---

## 주의사항

### DO
- shadcn/ui 우선 사용, 없는 것만 rsuite
- Bottom-up 순서로 구현 (자식 → 부모)
- 데이터 fetch는 leaf 컴포넌트에서 (prop drilling 금지)
- 로딩/에러/빈 상태 항상 처리
- rem 단위 사용 (`p-[1.5rem]` not `p-[24px]`)
- 화살표 함수 + 하단 export default

### DON'T
- `data-testid` 추가 금지 (프로젝트에 없음)
- inline style 금지 → Tailwind 사용
- 중첩 삼항 연산자 금지 → if/else 또는 ts-pattern
- `export default function` 금지 → arrow function 사용
- 이미지/아이콘 직접 임포트 금지 → 빈 div placeholder
