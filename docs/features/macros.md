# Macros

MockSyn exposes three attached peer macros: `@Mocking`, `@Stubbing`, and `@Spying`.
They generate test double peer types for annotated protocols and wrap the generated
types in `#if MOCKSYN_ENABLE` by default.

## What It Does

| Macro | Generated type | Default mode | Purpose |
| --- | --- | --- | --- |
| `@Mocking` | `<ProtocolName>Mock` | `.strict` | Verification-oriented mock. |
| `@Stubbing` | `<ProtocolName>Stub` | `.relaxed` | Response-oriented stub. |
| `@Spying` | `<ProtocolName>Spy` | `.strict` | Spy that stores a wrapped real implementation. |

The generated type inherits the annotated declaration's access by default. Its
name, access level, and behavior mode can be configured on each macro:

```swift
@Mocking(name: "MockUserService", access: .public, mode: .relaxed)
public protocol UserService {
}
```

## When To Use

Use these macros on protocols that define dependencies used by production code.
This keeps the production code typed against an abstraction while MockSyn creates
test-only peer types for tests.

Use `@Mocking` when tests need verification behavior, `@Stubbing` when tests mostly
need fixed responses, and `@Spying` when tests need a double that can delegate to a
real implementation.

## When Not To Use

Do not use these macros directly on pure Swift final classes. Swift macros cannot
intercept or replace final method dispatch. Extract a protocol and annotate that
protocol instead.

Do not enable `MOCKSYN_ENABLE` for Release builds unless generated test doubles are
intentionally part of that build.

## Setup Requirements

The target containing the annotated protocol must:

- depend on the `MockSyn` product;
- import `MockSyn`;
- define `MOCKSYN_ENABLE` for test builds or a dedicated testing configuration.

Example SwiftPM target setting:

```swift
.target(
    name: "AppCore",
    dependencies: [
        .product(name: "MockSyn", package: "MockSyn")
    ],
    swiftSettings: [
        .define("MOCKSYN_ENABLE", .when(configuration: .debug))
    ]
)
```

## Basic Examples

Mock:

```swift
import MockSyn

@Mocking
protocol UserService {
}

#if MOCKSYN_ENABLE
let service = UserServiceMock()
#endif
```

Stub:

```swift
import MockSyn

@Stubbing
protocol AnalyticsService {
}

#if MOCKSYN_ENABLE
let analytics = AnalyticsServiceStub()
#endif
```

Spy:

```swift
import MockSyn

@Spying
protocol CacheStore {
}

struct InMemoryCacheStore: CacheStore {
}

#if MOCKSYN_ENABLE
let spy = CacheStoreSpy(wrapping: InMemoryCacheStore())
#endif
```

## Advanced Options

Custom generated name:

```swift
@Mocking(name: "MockUserService")
protocol UserService {
}
```

Swift requires attached peer macros at global scope to declare the names they may
introduce. For that reason, custom names must start or end with the macro affix:

| Macro | Valid custom names |
| --- | --- |
| `@Mocking` | starts with `Mock` or ends with `Mock` |
| `@Stubbing` | starts with `Stub` or ends with `Stub` |
| `@Spying` | starts with `Spy` or ends with `Spy` |

Custom access:

```swift
@Mocking(access: .public)
public protocol UserService {
}
```

Custom mode:

```swift
@Mocking(mode: .relaxed)
protocol UserService {
}
```

Available access values:

- `.inherited` (default)
- `.internal`
- `.public`
- `.package`
- `.fileprivate`
- `.private`

Available mode values:

- `.strict`
- `.relaxed`

## Expected Failure Behavior

MockSyn emits compile-time diagnostics for unsupported macro usage.

Unsupported declaration:

```text
@Mocking can only be applied to protocols or supported classes
```

Final class:

```text
MockSyn cannot mock a pure Swift final class directly. Extract a protocol and apply @Mocking to the protocol.
```

Final class member:

```text
MockSyn cannot mock final class members by subclass generation. Remove 'final' from the member or extract a protocol.
```

Invalid access option:

```text
MockSyn access must be one of: internal, public, package, fileprivate, private
```

Invalid generated name:

```text
MockSyn generated name for @Mocking must start with Mock or end with Mock
```

Wider generated visibility than the annotated declaration:

```text
MockSyn cannot generate a public double for an internal declaration
```

## Current Limitations

Blocks 1 through 12 implement the macro surface, option parsing, generated type
declarations, supported declaration types, supported member generation, and
common Swift language features used by those members, plus runtime stubbing for
instance methods, properties, subscripts, verification for recorded calls,
optional and collection matchers, matcher composition, captors, explicit
test-double modes, partial spies, helper APIs for hand-written fakes, reset, and
failure reporting with test integration adapters.

Block 11 adds explicit diagnostics, a fix-it for pure Swift `final` classes, and
support-matrix documentation. Block 12 adds optional inspection tooling, DocC,
migration guides, and benchmark helpers outside the generation path.

Peer macros cannot discover requirements declared only in a custom inherited
protocol. MockSyn accepts the inheritance syntax but emits a warning asking the
consumer to redeclare those requirements in the annotated declaration. Direct
marker inheritance such as `AnyObject`, `Sendable`, and `ObservableObject` is
recognized; `ObservableObject` publishing is direct-only.

Custom names are constrained to the declared peer macro name patterns. Fully
arbitrary peer type names are not supported by Swift macros at global scope.

## Compatibility Notes

The public package manifest uses Swift tools 5.9. SwiftSyntax is selected by
compiler version in `Package.swift` so Swift 5.9 and Swift 6 toolchains can use a
matching SwiftSyntax line.

The mapping is 509 for Swift 5.9, 510 for Swift 5.10, 600-603 for the matching
Swift 6.0-6.3 compiler, and exact
`604.0.0-prerelease-2026-06-05` for Swift 6.4 beta. On SwiftSyntax 509, access
written only on a surrounding extension is not visible to the macro; specify
`access:` explicitly for that declaration shape.

SwiftSyntax remains isolated to the `MockSynMacros` target. The `MockSyn` runtime
target does not depend on SwiftSyntax.
