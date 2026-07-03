# Supported Members

Block 3 added member generation for declarations that MockSyn already accepts.
Block 5 connects generated instance members to the runtime stubbing registry.
Block 6 records invocations and exposes generated verification APIs. Block 7
adds richer matchers and captors that plug into those generated member APIs.

## What It Does

| Member | Protocols | Non-final classes | Notes |
| --- | --- | --- | --- |
| Sync methods | Supported | Supported as overrides | Instance members can be configured through `given` / `when`. |
| `throws` methods | Supported | Supported as overrides | Void throwing methods are callable and do nothing for mocks/stubs. |
| `async` methods | Supported | Supported as overrides | Void async methods are callable and do nothing for mocks/stubs. |
| `async throws` methods | Supported | Supported as overrides | Spy instance methods delegate to the wrapped implementation. |
| `Void` methods | Supported | Supported as overrides | Callable immediately and recorded for verification. |
| `get` properties | Supported | Supported as overrides | Instance getters can be configured through generated property stubs. Effectful getters preserve `async`, `throws`, and `async throws`. |
| `get set` properties | Supported | Supported as overrides | Setters are callable; getter behavior follows the getter rule. |
| Static requirements | Supported for protocols | Not a class feature in this block | Static methods/properties are generated for protocol conformance. |
| Subscripts | Supported | Supported as overrides | Protocol spies delegate readable subscripts. Generic parameter and `where` clauses are preserved. |
| Initializers | Supported for protocol mocks/stubs | Mirrored for non-variadic class initializers | Required class initializers are supported for mocks/stubs. Class spies diagnose required initializers. |
| Overloads | Supported when signatures are valid Swift | Supported when overridable | Overload resolution is left to Swift. |
| Operators | Supported for protocol requirements | Diagnostic | Protocol operators generate real static operators and named DSL aliases. |

## Runtime Behavior

Instance methods, properties, and subscripts generated for mocks, stubs, and
spies now route through `MockSynRuntime`. Strict mocks fail on unstubbed non-void
calls. Relaxed mocks and stubs return supported defaults when possible.

```swift
@Mocking
protocol UserService {
    func load(id: String) -> String
    func refresh()
}

#if MOCKSYN_ENABLE
let service = UserServiceMock()
service.refresh()
service.given.load(id: .value("1")).willReturn("Rafael")
service.load(id: "1")
#endif
```

`Void` methods and setters are callable because they do not need a return value.
Unstubbed non-void getters, subscripts, and methods fail in strict mode with a
clear runtime message.

## Effectful Property Getters

Swift property requirements can include effectful getter accessors:

```swift
@Mocking
protocol ProfileService {
    var remoteName: String { get async throws }
}

#if MOCKSYN_ENABLE
let service = ProfileServiceMock()
service.given.remoteName.get.willReturn("Rafael")

let name = try await service.remoteName
try service.verify.remoteName.get.once()
#endif
```

Mocks and stubs preserve the getter effects and route throwing getters through
the throwing runtime path. Static protocol properties use the generated
type-level runtime:

```swift
IDFactoryMock.given.remoteVersion.get.willReturn("1.0")
let version = try await IDFactoryMock.remoteVersion
```

Spies with async property getters record the getter invocation and delegate
directly to the wrapped implementation. Because Swift async getters cannot be
called from a synchronous fallback closure, async spy property stubs are not
applied before delegation in this release.

## Spy Delegation

Protocol and class spies store a wrapped implementation. Instance methods and
properties delegate to it when the generated code can do so without extra
runtime support.

```swift
@Spying
protocol CacheStore {
    var count: Int { get }
    func load(id: String) -> String
}

struct RealCacheStore: CacheStore {
    let count = 1

    func load(id: String) -> String {
        "cached-\(id)"
    }
}

#if MOCKSYN_ENABLE
let spy = CacheStoreSpy(wrapping: RealCacheStore())
spy.count
spy.load(id: "user")
#endif
```

Protocol spy setters are intentionally no-op in this block because assigning
through an existential `let` wrapper is not generally valid Swift. Calls routed
through generated members are recorded for verification.

## Initializers

Protocol initializer requirements are generated for mocks and stubs:

```swift
@Mocking
protocol SeededService {
    init(seed: String)
}

#if MOCKSYN_ENABLE
let service = SeededServiceMock(seed: "test")
#endif
```

Generated protocol initializer requirements use the macro's configured mode.
They do not add a custom `mode:` parameter because they must match the protocol
requirement.

Class doubles mirror non-variadic class initializers and forward parameters to
the matching superclass initializer:

```swift
@Mocking
class SeededService {
    init(seed: String) {}
}

#if MOCKSYN_ENABLE
let service = SeededServiceMock(seed: "test", mode: .relaxed)
#endif
```

Mocks and stubs support `required` class initializers by generating the exact
required initializer plus a configurable initializer that accepts `mode:`.
Class spies require a wrapped instance, so required class initializers on spies
emit a diagnostic. Variadic class initializers also emit a diagnostic because
Swift cannot forward captured variadic arrays to `super.init`.

## Operators

Protocol operator requirements generate static operator implementations for
conformance and named entries on the type-level `given`, `when`, and `verify`
APIs:

```swift
@Mocking
protocol ComparableService {
    static func == (lhs: Self, rhs: Self) -> Bool
    static func + (lhs: Self, rhs: Self) -> Self
}

#if MOCKSYN_ENABLE
let lhs = ComparableServiceMock()
let rhs = ComparableServiceMock()

ComparableServiceMock.given.equalTo(lhs: .any, rhs: .any).willReturn(true)
ComparableServiceMock.given.plus(lhs: .any, rhs: .any).willReturn(lhs)

lhs == rhs
lhs + rhs

try ComparableServiceMock.verify.equalTo(lhs: .any, rhs: .any).once()
#endif
```

Common operators use readable aliases such as `equalTo`, `notEqualTo`,
`lessThan`, `plus`, `minus`, `multiply`, `divide`, and `remainder`. Custom
operators use a deterministic fallback name based on Unicode scalar values, for
example `<~>` becomes `operator_u3c_u7e_u3e`.

Class operator members are still rejected because MockSyn does not intercept
concrete static dispatch through subclass generation.

## Generic Subscripts

Generic subscripts preserve their generic parameter clause and generic `where`
clause in the generated member and in the generated `given`, `when`, and
`verify` APIs:

```swift
@Mocking
protocol GenericLookup {
    subscript<Value: Sendable>(key: String, default defaultValue: Value) -> Value { get set }
    subscript<Value>(optional key: String) -> Value? where Value: Equatable { get }
}

#if MOCKSYN_ENABLE
let lookup = GenericLookupMock()

lookup.given.subscript(key: .value("name"), default: .value("fallback")).get.willReturn("Rafael")

let value: String = lookup["name", default: "fallback"]

try lookup.verify.subscript(key: .value("name"), default: .value("fallback")).get.once()
#endif
```

MockSyn includes the generic clause and `where` clause in the internal member
key for generic subscripts. That keeps otherwise-identical generic subscript
requirements from sharing the same runtime stubs or verification records.

## Limitations

- Generic methods, generic classes, `Self` requirements, `where` clauses,
  `inout`, variadics, closures, global actors, and common `Sendable` scenarios
  are handled by the Swift language feature block.
- Protocols with associated types generate generic mocks, stubs, and spies.
- Static protocol members generate type-level stubbing and verification APIs.
  Spies cannot delegate static protocol requirements through an instance wrapper.
- Async spy property getters delegate directly after recording; targeted
  property stubs for those async getters are not applied before delegation.
- Generic subscripts are supported for generated members and generated DSL APIs.
- Variadic spy delegation supports one synchronous variadic parameter with 0
  through 8 forwarded values. Async variadic methods and methods with multiple
  variadic parameters remain stub-driven.
- Class initializer mirroring supports non-variadic class initializers. Required
  class initializers are supported for mocks and stubs; class spies diagnose
  required initializers because the exact required signature cannot receive the
  wrapped instance.
- Properties without explicit type annotations are ignored by the member
  generator.
- Verification APIs are available for generated instance and static methods,
  properties, and subscripts.
