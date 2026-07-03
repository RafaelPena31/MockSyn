# Supported Members

Block 3 adds member generation for declarations that MockSyn already accepts.
The goal of this block is compile-time conformance and predictable placeholder
behavior. Stubbing, verification, invocation storage, relaxed defaults, and
argument matching are implemented by later blocks.

## What It Does

| Member | Protocols | Non-final classes | Notes |
| --- | --- | --- | --- |
| Sync methods | Supported | Supported as overrides | Non-void mocks and stubs fail until configured by future stubbing APIs. |
| `throws` methods | Supported | Supported as overrides | Void throwing methods are callable and do nothing for mocks/stubs. |
| `async` methods | Supported | Supported as overrides | Void async methods are callable and do nothing for mocks/stubs. |
| `async throws` methods | Supported | Supported as overrides | Spy instance methods delegate to the wrapped implementation. |
| `Void` methods | Supported | Supported as overrides | Callable immediately; recording comes in the runtime block. |
| `get` properties | Supported | Supported as overrides | Non-spy getters fail until stubbing exists. |
| `get set` properties | Supported | Supported as overrides | Setters are callable; getter behavior follows the getter rule. |
| Static requirements | Supported for protocols | Not a class feature in this block | Static methods/properties are generated for protocol conformance. |
| Subscripts | Supported | Supported as overrides | Protocol spies delegate readable subscripts. |
| Initializers | Supported for protocol mocks/stubs | Not generated for class initializers | Spy initializer requirements are not generated in this block. |
| Overloads | Supported when signatures are valid Swift | Supported when overridable | Overload resolution is left to Swift. |
| Operators | Diagnostic | Diagnostic | Operators are intentionally rejected for now. |

## Runtime Behavior In This Block

Mocks and stubs generated in Block 3 are structurally complete, but they do not
yet have a call store or stub registry.

```swift
@Mocking
protocol UserService {
    func load(id: String) -> String
    func refresh()
}

#if MOCKSYN_ENABLE
let service = UserServiceMock()
service.refresh()
service.load(id: "1") // fatalError until stubbing is implemented.
#endif
```

`Void` methods and setters are callable because they do not need a return value.
Non-void getters, subscripts, and methods fail with a clear placeholder message
until the stubbing block provides configured returns.

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
through an existential `let` wrapper is not generally valid Swift. Recording and
setter verification are handled later by the runtime and verification blocks.

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
- Stubbing and verification APIs are not available in this block.
