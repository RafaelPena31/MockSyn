# Swift Language Features

Block 4 preserves common Swift language features in generated mocks, stubs, and
spies. The goal is to keep generated declarations valid Swift while staying
inside the macro-only architecture.

## What It Does

| Feature | Status | Notes |
| --- | --- | --- |
| Generic methods | Supported | Generic parameter clauses are preserved. |
| Generic classes | Supported | Generated subclasses mirror generic parameters and `where` clauses. |
| `where` clauses | Supported | Preserved on generated generic classes and methods. |
| `Self` requirements | Supported for placeholder behavior | Mocks/stubs compile by using placeholder bodies. |
| `inout` parameters | Supported | Spies delegate with `&` when the method is otherwise delegatable. |
| Variadic parameters | Signature supported with sync spy delegation | Spies delegate one variadic parameter up to 8 values. Async and multiple-variadic methods remain stub-driven. |
| Closures | Supported | Closure parameter signatures are preserved. |
| `@escaping` closures | Supported | Attributes inside parameter clauses are preserved by SwiftSyntax. |
| Global actors | Supported for actor attributes ending in `Actor` | Type and member actor attributes are forwarded. |
| `Sendable` inheritance | Supported where Swift accepts the generated type | `MockSynRuntime` is `@unchecked Sendable`. |
| Associated types | Supported | Protocol associated types become generic parameters on generated doubles. |
| Effectful property getters | Supported | Preserves `get async`, `get throws`, and `get async throws`. |
| Generic subscripts | Supported | Preserves generic parameter clauses and generic `where` clauses. |

## Generic Methods

```swift
@Mocking
protocol Processor {
    func map<Value>(_ value: Value) -> Value where Value: Sendable
}
```

Generated member:

```swift
func map<Value>(_ value: Value) -> Value where Value: Sendable
```

Non-void mocks and stubs still use placeholder `fatalError` bodies until the
stubbing block provides configured return values.

## Generic Subscripts

Generic subscripts preserve the same syntax as generic methods:

```swift
@Mocking
protocol GenericLookup {
    subscript<Value: Sendable>(key: String, default defaultValue: Value) -> Value { get set }
    subscript<Value>(optional key: String) -> Value? where Value: Equatable { get }
}
```

The generated subscript and generated DSL methods keep `<Value: Sendable>` and
`where Value: Equatable`, so stubbing and verification remain type-checked by
Swift.

## Generic Classes

```swift
@Mocking
class Box<Value> where Value: Sendable {
    func load(_ value: Value) -> Value {
        value
    }
}
```

Generated class shape:

```swift
final class BoxMock<Value>: Box<Value> where Value: Sendable
```

Class doubles mirror non-variadic class initializers and forward arguments to
the matching `super.init`.

## Inout And Closures

`inout` and closure signatures are preserved. Spies delegate `inout` arguments
with `&` when the method is otherwise safe to call.

```swift
@Spying
protocol Counter {
    func update(_ value: inout Int)
    func handle(_ action: @escaping (String) -> Void)
}
```

## Variadics

Variadic signatures are generated, so mocks, stubs, and spies can conform to
protocols that use them.

```swift
@Spying
protocol Scores {
    func total(_ values: Int...) -> Int
}
```

Swift does not provide a general array splat for forwarding a captured variadic
parameter into another variadic call. For the common synchronous case with one
variadic parameter, MockSyn emits finite forwarding cases for 0 through 8 values
and uses the wrapped implementation as the spy fallback:

```swift
let spy = ScoresSpy(wrapping: RealScores(), mode: .relaxed)

XCTAssertEqual(spy.total(1, 2, 3), 6)
try spy.verify.total(.value([1, 2, 3])).once()
```

Async variadic methods and methods with multiple variadic parameters remain
stub-driven because there is no general Swift syntax for safe arbitrary
forwarding from captured arrays.

## Global Actors

Global actor attributes such as `@MainActor` are forwarded to generated types and
members.

```swift
@Mocking
@MainActor
protocol MainService {
    func refresh()
}
```

Generated type:

```swift
@MainActor final class MainServiceMock: MainService
```

## Effectful Property Getters

Effectful property accessor syntax is preserved on generated mocks, stubs, and
spies:

```swift
@Mocking
protocol ProfileService {
    var remoteName: String { get async throws }
}
```

Generated mocks and stubs keep the same accessor shape and use the matching
runtime path:

```swift
var remoteName: String {
    get async throws
}
```

Spies record async getter access and then delegate directly to the wrapped
implementation.

## Associated Types

Protocols with `associatedtype` generate generic doubles:

```swift
@Mocking
protocol Repository {
    associatedtype Entity
    func load() -> Entity
}
```

Generated shape:

```swift
final class RepositoryMock<Entity>: Repository {
    typealias Entity = Entity

    func load() -> Entity
}
```

Constraints are preserved as generic constraints:

```swift
@Stubbing
protocol Lookup {
    associatedtype ID: Hashable
    associatedtype Entity: Sendable where Entity: Equatable
    func load(id: ID) -> Entity
}
```

Generated shape:

```swift
final class LookupStub<ID: Hashable, Entity: Sendable>: Lookup where Entity: Equatable
```

Spies add one extra generic parameter for the wrapped concrete implementation:

```swift
final class RepositorySpy<Entity, __MockSynWrapped: Repository>: Repository where __MockSynWrapped.Entity == Entity
```

This keeps delegation type-safe without storing an existential that loses the
associated type binding.
