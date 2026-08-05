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

Generated access follows the annotated declaration by default. Swift 5.9 users
must specify `access:` when effective visibility comes only from an
access-modified extension because SwiftSyntax 509 does not expose that context.

## Macros

- `@Mocking` generates strict mocks by default.
- `@Stubbing` generates relaxed stubs by default.
- `@Spying` records calls and delegates to a wrapped implementation.

## Runtime

The runtime records invocations, stores stubs, evaluates matchers, verifies call
counts, verifies order, reports failures, and supports reset scopes. Generated
members include sync, throwing, async, async throwing, static, operator,
effectful property getter, generic subscript, synchronous variadic requirements,
return-type-only overload requirements, `rethrows` requirements, and mirrored class initializer
requirements where Swift subclassing supports them.

Strict non-throwing missing stubs report through `MockSynFailureReporter` and
recover with a registered or built-in default. They terminate only when the
declared return type has no value the runtime can produce. Typed `willRun`
builders support zero through six arguments.

`MockSynRuntime.resetAllGlobalState()` clears static runtimes, custom defaults,
failure reporting, and global ordering at sequential test boundaries.

For selectors visible to the Objective-C runtime, `MockSynObjCInterception`
offers an explicit scoped swizzling API. This is separate from macro-generated
test doubles and is available only when `ObjectiveC.runtime` can be imported.

For construction behavior that can be injected, `MockSynConstructor`,
`MockSynConstructor1`, and `MockSynConstructor2` provide explicit scoped
constructor seams. They do not intercept direct `Type(...)` calls.

## Diagnostics

MockSyn emits compile-time diagnostics for unsupported declarations, pure Swift
final classes, final class members, invalid macro options, unsupported class
operator members, concrete static class members, and visibility issues.

Custom protocol inheritance emits a warning because attached peer macros cannot
discover requirements declared in a parent or compiled external module. Redeclare
the requirements locally; for external/KMP contracts, use an annotated local
mirror and add conformance from the generated double to the external protocol.
Direct `ObservableObject` inheritance generates Combine notifications when
available, but indirect inheritance cannot be detected.
