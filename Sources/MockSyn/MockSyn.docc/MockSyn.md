# MockSyn

MockSyn is a Swift macro-first framework for generating mocks, stubs, and spies
with syntax inspired by MockK and Mockito.

## Overview

Use MockSyn by annotating protocols or supported non-final classes:

```swift
import MockSyn

@Mocking
protocol UserService {
    func loadUser(id: String) async throws -> User
}
```

Generated doubles are protected by `#if MOCKSYN_ENABLE`, so consumers control
where mocks exist through Active Compilation Conditions.

## Macros

- `@Mocking` generates strict mocks by default.
- `@Stubbing` generates relaxed stubs by default.
- `@Spying` records calls and delegates to a wrapped implementation.

## Runtime

The runtime records invocations, stores stubs, evaluates matchers, verifies call
counts, verifies order, reports failures, and supports reset scopes. Generated
members include sync, throwing, async, async throwing, static, operator,
effectful property getter, and generic subscript requirements.

## Diagnostics

MockSyn emits compile-time diagnostics for unsupported declarations, pure Swift
final classes, invalid macro options, unsupported class operator members, and
visibility issues.
