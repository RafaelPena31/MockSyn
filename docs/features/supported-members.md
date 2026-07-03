# Supported Members

Block 3 added member generation for declarations that MockSyn already accepts.
Block 5 connects generated instance members to the runtime stubbing registry.
Block 6 records invocations and exposes generated verification APIs. Captors are
implemented by later blocks.

## What It Does

| Member | Protocols | Non-final classes | Notes |
| --- | --- | --- | --- |
| Sync methods | Supported | Supported as overrides | Instance members can be configured through `given` / `when`. |
| `throws` methods | Supported | Supported as overrides | Void throwing methods are callable and do nothing for mocks/stubs. |
| `async` methods | Supported | Supported as overrides | Void async methods are callable and do nothing for mocks/stubs. |
| `async throws` methods | Supported | Supported as overrides | Spy instance methods delegate to the wrapped implementation. |
| `Void` methods | Supported | Supported as overrides | Callable immediately and recorded for verification. |
| `get` properties | Supported | Supported as overrides | Instance getters can be configured through generated property stubs. |
| `get set` properties | Supported | Supported as overrides | Setters are callable; getter behavior follows the getter rule. |
| Static requirements | Supported for protocols | Not a class feature in this block | Static methods/properties are generated for protocol conformance. |
| Subscripts | Supported | Supported as overrides | Protocol spies delegate readable subscripts. |
| Initializers | Supported for protocol mocks/stubs | Not generated for class initializers | Spy initializer requirements are not generated in this block. |
| Overloads | Supported when signatures are valid Swift | Supported when overridable | Overload resolution is left to Swift. |
| Operators | Diagnostic | Diagnostic | Operators are intentionally rejected for now. |

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

Generated initializer requirements use the macro's configured mode. They do not
add a custom `mode:` parameter because they must match the protocol requirement.

Class initializer mirroring is not part of Block 3. Class doubles still require
an accessible zero-argument initializer for the generated convenience initializer
that MockSyn provides.

## Operators

Operator requirements are rejected with a diagnostic:

```swift
@Mocking
protocol ComparableService {
    static func == (lhs: ComparableService, rhs: ComparableService) -> Bool
}
```

Diagnostic:

```text
MockSyn cannot generate operator requirements yet. Wrap the operator behind a named method.
```

## Limitations

- Generic methods, generic classes, `Self` requirements, `where` clauses,
  `inout`, variadics, closures, global actors, and common `Sendable` scenarios
  are handled by the Swift language feature block.
- Protocols with associated types are diagnosed until MockSyn has an explicit
  type-binding API.
- Static members are generated for protocol conformance, but spies cannot
  delegate static protocol requirements through an instance wrapper.
- Properties without explicit type annotations are ignored by the member
  generator.
- Verification APIs are available for generated instance methods, properties,
  and subscripts. Static member verification is not generated yet.
