# Stubbing

Block 5 adds runtime stubbing for generated mocks, stubs, and spies. Generated
types expose `given` and `when` entrypoints so tests can configure behavior
without a source generator or generated file cache.

## What It Does

| Feature | Status | Notes |
| --- | --- | --- |
| `given` / `when` | Supported | `when` is an alias for teams that prefer Mockito naming. |
| `willReturn` | Supported | Accepts one or more values. Multiple values are returned sequentially. |
| `willThrow` | Supported | Exposed only by generated `throws` members. Non-throwing and `rethrows` builders do not offer it. |
| `willRun` | Supported | Typed for zero through six method arguments, property setters, and subscript setters. |
| `rethrows` stubs | Supported | Generated `rethrows` APIs use dedicated builders with `willReturn` and non-throwing `willRun`; they do not expose `willThrow`. |
| Argument-specific stubs | Supported | Uses typed matchers such as `.any`, `.value`, `.matching`, optional, collection, composed, and captor matchers. |
| Property getter stubs | Supported | `mock.given.name.get.willReturn("value")`. |
| Property setter stubs | Supported | `mock.given.name.set(.any).willRun { value in ... }`. |
| Subscript getter stubs | Supported | `mock.given.subscript(key: .value("theme")).get.willReturn("dark")`. |
| Subscript setter stubs | Supported | Setter closures receive the assigned value. |
| Relaxed defaults | Supported | Stubs default to relaxed mode. Relaxed mocks can also use built-in defaults. Strict stubs require explicit stubs for non-void calls. |
| Custom default values | Supported | Use `MockSynDefaultValueRegistry.register(_:for:)`. |

## When To Use

Use stubbing when a test needs a dependency to return deterministic data,
throw a deterministic error, or execute a small custom closure.

Use `@Stubbing` when the double mostly returns values and should use relaxed
defaults. Use `@Mocking(mode: .relaxed)` when a mock also needs relaxed defaults.
Use `@Spying` when the default behavior should delegate to a real implementation,
but a few calls need to be overridden.

## Basic Example

```swift
import MockSyn

@Mocking
protocol UserService {
    func name(id: String) -> String
}

#if MOCKSYN_ENABLE
let service = UserServiceMock()

service.given.name(id: .value("42")).willReturn("Arthur")
service.given.name(id: .any).willReturn("Unknown")

service.name(id: "42") // "Arthur"
service.name(id: "7")  // "Unknown"
#endif
```

## Sequential Returns

`willReturn` accepts multiple values. After the configured sequence is exhausted,
MockSyn keeps returning the last value.

```swift
counter.given.next().willReturn(1, 2, 3)

counter.next() // 1
counter.next() // 2
counter.next() // 3
counter.next() // 3
```

## Throwing And Custom Closures

```swift
service.given.load(id: .value("offline")).willThrow(NetworkError.offline)

service.given.doubled(.any).willRun { value in
    value * 2
}
```

`willRun` is typed for generated members with zero through six parameters.
Members with more than six parameters use a return-only builder: non-throwing
members expose `willReturn`, while throwing members expose `willReturn` and
`willThrow`. The macro emits a warning when typed `willRun` is unavailable.

## Rethrows

Generated `rethrows` members preserve the original signature, but their stubbing
surface is intentionally narrower than `throws`. A `rethrows` implementation may
only throw through one of its throwing function parameters, so MockSyn generates
`MockSynRethrowingStubBuilder` variants that do not provide `willThrow`.

```swift
@Mocking
protocol TransactionRunner {
    func run(_ operation: @escaping () throws -> String) rethrows -> String
}

#if MOCKSYN_ENABLE
let runner = TransactionRunnerMock()
runner.given.run(.any).willReturn("cached")
runner.given.run(.any).willRun { _ in
    "computed"
}
#endif
```

Use `willReturn` for deterministic values and non-throwing `willRun` for custom
behavior. If the test needs the call itself to throw, let the closure parameter
throw and use a spy or real implementation path that invokes that closure.

## Properties

```swift
profile.given.displayName.get.willReturn("Rafael")

profile.given.displayName.set(.any).willRun { newValue in
    assignedName = newValue
}
```

Getter and setter stubs are stored separately. A getter stub does not configure
the setter, and a setter stub does not configure the getter.

Effectful getters use the same generated property stubber:

```swift
service.given.remoteName.get.willReturn("Rafael")

let name = try await service.remoteName
```

For `get throws` and `get async throws`, `willThrow` configures the error raised
by the generated getter:

```swift
service.given.remoteName.get.willThrow(NetworkError.offline)

try await service.remoteName
```

## Subscripts

```swift
settings.given.subscript(key: .value("theme")).get.willReturn("dark")

settings.given.subscript(key: .any).set(.any).willRun { value in
    assignedTheme = value
}
```

Generated subscript stubs preserve external and local labels. For a requirement
like `subscript(label key: String)`, the DSL is:

```swift
settings.given.subscript(label: .value("theme")).get.willReturn("dark")
```

Generic subscripts keep their generic constraints on the generated DSL method:

```swift
lookup.given.subscript(key: .value("name"), default: .value("fallback")).get.willReturn("Rafael")

let value: String = lookup["name", default: "fallback"]
```

When a generic type appears only in the return type, bind the generated builder
explicitly:

```swift
let stub: MockSynSubscriptStubber<Int?> = lookup.given.subscript(optional: .value("score"))
stub.get.willReturn(42)
```

## Relaxed Defaults

Stubs default to `.relaxed`, so unstubbed supported return types can return a
default value. A stub constructed with `mode: .strict` requires explicit stubs
for non-void calls.

```swift
@Stubbing
protocol FeatureFlags {
    func enabled() -> Bool
    func title() -> String
}

#if MOCKSYN_ENABLE
let flags = FeatureFlagsStub()
flags.enabled() // false
flags.title()   // ""
#endif
```

Built-in defaults currently include `String`, `Int`, `Bool`, `Double`, `Float`,
`Void`, and `Optional.none`.

Custom defaults can be registered for domain types:

```swift
MockSynDefaultValueRegistry.register(User(id: "test"), for: User.self)
defer { MockSynDefaultValueRegistry.reset() }
```

## Spies

Spies delegate to the wrapped implementation when no matching stub exists.
When a matching stub exists, the stub wins.

```swift
let spy = UserServiceSpy(wrapping: realService)

spy.given.name(id: .value("offline")).willReturn("Cached")

spy.name(id: "42")      // delegates
spy.name(id: "offline") // returns "Cached"
```

## Static Members

Static protocol requirements are configured on the generated type, not on an
instance:

```swift
@Mocking
protocol IDFactory {
    static var version: String { get set }
    static func make(id: String) -> String
}

IDFactoryMock.given.version.get.willReturn("1.0")
IDFactoryMock.given.make(id: .value("primary")).willReturn("generated")

_ = IDFactoryMock.version
_ = IDFactoryMock.make(id: "primary")
```

Use `resetStatic(_:)`, `confirmStaticVerified()`, and
`checkUnnecessaryStaticStubs()` for the static runtime state.

## Current Limits

- `willRun` has typed overloads for zero through six method arguments. Higher
  arities retain deterministic return or throw behavior without a typed closure.
- Associated-type protocols generate generic doubles, so stubbing is available
  after the test binds the associated types through the generated generic
  parameters.
- Verification, order checks, captors, and richer matcher composition are
  available.
