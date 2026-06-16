# Reference — `useUrlQuery` Hook Implementation

`code-writer` Phase 3에서 `hooks/useUrlQuery.ts`가 없을 때 생성하는 canonical 구현이다. 아래 코드를 **그대로** `hooks/useUrlQuery.ts`에 복사한다 (URL ↔ 상태 동기화의 SSOT — Zustand session store 대신 사용, conventions §12).

```typescript
// hooks/useUrlQuery.ts
import { useCallback, useMemo, useRef } from "react";
import { useRouter } from "next/router";

// --- Types ---

type QueryValueType = string | string[];

type SerializerType<T> = {
  serialize: (value: T) => QueryValueType;
  deserialize: (value: QueryValueType) => T;
};

type UrlQueryConfigType<T> = {
  defaultValue: T;
  serializer?: SerializerType<T>;
};

type UrlQuerySchemaType = Record<string, UrlQueryConfigType<any>>;

type UrlQueryValuesType<S extends UrlQuerySchemaType> = {
  [K in keyof S]: S[K]["defaultValue"];
};

/** Passthrough: schema에 없는 키도 primitive 값으로 URL에 쓸 수 있음 */
type PassthroughUpdates = Record<
  string,
  string | number | boolean | string[] | null | undefined
>;

type UrlQueryReturnType<S extends UrlQuerySchemaType> = {
  urlQuery: UrlQueryValuesType<S>;
  setUrlQuery: (
    updates: Partial<UrlQueryValuesType<S>> & PassthroughUpdates
  ) => void;
  resetUrlQuery: () => void;
};

// --- Default Serializers (primitive types) ---

const DEFAULT_SERIALIZERS: Record<string, SerializerType<any>> = {
  string: {
    serialize: (v: string) => v,
    deserialize: (v: QueryValueType) => (Array.isArray(v) ? v[0] ?? "" : v),
  },
  number: {
    serialize: (v: number) => String(v),
    deserialize: (v: QueryValueType) =>
      Number(Array.isArray(v) ? v[0] ?? "0" : v),
  },
  boolean: {
    serialize: (v: boolean) => String(v),
    deserialize: (v: QueryValueType) =>
      (Array.isArray(v) ? v[0] ?? "false" : v) === "true",
  },
};

// --- Array Serializer (repeated query keys: ?key=a&key=b) ---

const getArraySerializer = <T>(defaultValue: T[]): SerializerType<T[]> => {
  const sample = defaultValue[0];
  const itemType = sample !== undefined ? typeof sample : "string";

  if (itemType === "number") {
    return {
      serialize: (v: T[]) => v.map(String),
      deserialize: (v: QueryValueType) =>
        (Array.isArray(v) ? v : [v]).map(Number) as T[],
    };
  }

  // Default: string array
  return {
    serialize: (v: T[]) => v.map(String),
    deserialize: (v: QueryValueType) => (Array.isArray(v) ? v : [v]) as T[],
  };
};

// --- Comma-Separated Serializer (single key: ?key=a,b,c) ---

export const commaSeparatedSerializer = {
  string: {
    serialize: (v: string[]) => v.join(","),
    deserialize: (v: QueryValueType) => {
      const raw = Array.isArray(v) ? v[0] ?? "" : v;
      return raw ? raw.split(",") : [];
    },
  } as SerializerType<string[]>,
  number: {
    serialize: (v: number[]) => v.map(String).join(","),
    deserialize: (v: QueryValueType) => {
      const raw = Array.isArray(v) ? v[0] ?? "" : v;
      return raw ? raw.split(",").map(Number) : [];
    },
  } as SerializerType<number[]>,
};

// --- Serializer Resolution ---

const getSerializer = <T>(
  defaultValue: T,
  custom?: SerializerType<T>
): SerializerType<T> => {
  if (custom) {
    return custom;
  }

  if (Array.isArray(defaultValue)) {
    return getArraySerializer(defaultValue) as unknown as SerializerType<T>;
  }

  const type = typeof defaultValue;
  if (type in DEFAULT_SERIALIZERS) {
    return DEFAULT_SERIALIZERS[type];
  }

  // Fallback: JSON serialization for objects
  return {
    serialize: (v: T) => JSON.stringify(v),
    deserialize: (v: QueryValueType) => {
      const raw = Array.isArray(v) ? v[0] ?? "" : v;
      return JSON.parse(raw) as T;
    },
  };
};

// --- Deep Equality (key-order independent for objects) ---

const isEqual = (a: unknown, b: unknown): boolean => {
  if (a === b) {
    return true;
  }
  if (a == null || b == null) {
    return false;
  }
  if (Array.isArray(a) && Array.isArray(b)) {
    return a.length === b.length && a.every((v, i) => isEqual(v, b[i]));
  }
  if (typeof a === "object" && typeof b === "object") {
    const objA = a as Record<string, unknown>;
    const objB = b as Record<string, unknown>;
    const keysA = Object.keys(objA);
    const keysB = Object.keys(objB);
    if (keysA.length !== keysB.length) {
      return false;
    }
    return keysA.every((key) => key in objB && isEqual(objA[key], objB[key]));
  }
  return false;
};

// --- Passthrough Serializer (schema에 없는 키) ---

const serializePassthrough = (
  value: string | number | boolean | string[]
): QueryValueType => {
  if (Array.isArray(value)) {
    return value.map(String);
  }
  return String(value);
};

// --- Hook ---

export const useUrlQuery = <S extends UrlQuerySchemaType>(
  schema: S
): UrlQueryReturnType<S> => {
  const router = useRouter();

  const schemaRef = useRef(schema);
  schemaRef.current = schema;

  const routerRef = useRef(router);
  routerRef.current = router;

  const pendingQueryRef = useRef<Record<
    string,
    string | string[] | undefined
  > | null>(null);
  const pushCountRef = useRef(0);

  const urlQuery = useMemo(() => {
    const state = {} as UrlQueryValuesType<S>;
    const { query } = router;

    for (const key of Object.keys(schemaRef.current)) {
      const config = schemaRef.current[key];
      const serializer = getSerializer(config.defaultValue, config.serializer);
      const rawValue = query[key];

      if (rawValue !== undefined) {
        try {
          (state as any)[key] = serializer.deserialize(rawValue);
        } catch {
          (state as any)[key] = config.defaultValue;
        }
      } else {
        (state as any)[key] = config.defaultValue;
      }
    }

    return state;
  }, [router.query]);

  const setUrlQuery = useCallback(
    (updates: Partial<UrlQueryValuesType<S>> & PassthroughUpdates) => {
      const currentQuery = {
        ...(pendingQueryRef.current ?? routerRef.current.query),
      };

      for (const key of Object.keys(updates)) {
        const config = schemaRef.current[key];
        const newValue = (updates as any)[key];

        // null/undefined → remove from URL
        if (newValue == null) {
          delete currentQuery[key];
          continue;
        }

        if (!config) {
          // Passthrough: schema에 없는 키는 그대로 직렬화하여 URL에 반영
          currentQuery[key] = serializePassthrough(newValue);
          continue;
        }

        const serializer = getSerializer(
          config.defaultValue,
          config.serializer
        );

        if (isEqual(newValue, config.defaultValue)) {
          delete currentQuery[key];
        } else {
          currentQuery[key] = serializer.serialize(newValue);
        }
      }

      pendingQueryRef.current = currentQuery;
      const currentPushCount = ++pushCountRef.current;

      routerRef.current
        .push(
          { pathname: routerRef.current.pathname, query: currentQuery },
          undefined,
          { shallow: true }
        )
        .then(() => {
          if (pushCountRef.current === currentPushCount) {
            pendingQueryRef.current = null;
          }
        });
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    []
  );

  const resetUrlQuery = useCallback(() => {
    const currentQuery = {
      ...(pendingQueryRef.current ?? routerRef.current.query),
    };

    for (const key of Object.keys(schemaRef.current)) {
      delete currentQuery[key];
    }

    pendingQueryRef.current = currentQuery;
    const currentPushCount = ++pushCountRef.current;

    routerRef.current
      .push(
        { pathname: routerRef.current.pathname, query: currentQuery },
        undefined,
        { shallow: true }
      )
      .then(() => {
        if (pushCountRef.current === currentPushCount) {
          pendingQueryRef.current = null;
        }
      });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return { urlQuery, setUrlQuery, resetUrlQuery };
};
```

**Key capabilities:**
- `string`, `number`, `boolean` — auto-detected from `defaultValue`
- Array (repeated keys: `?key=a&key=b`) — use `defaultValue: [] as string[]`
- Comma-separated (`?key=a,b,c`) — use `serializer: commaSeparatedSerializer.string`
- Passthrough: schema에 없는 키도 `setUrlQuery`로 URL에 직접 쓸 수 있음
- Default values omitted from URL; race-condition-safe writes
