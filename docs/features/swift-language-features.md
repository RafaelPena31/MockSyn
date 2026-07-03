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
| Variadic parameters | Signature supported | Spies do not delegate variadic calls in this block. |
| Closures | Supported | Closure parameter signatures are preserved. |
| `@escaping` closures | Supported | Attributes inside parameter clauses are preserved by SwiftSyntax. |
| Global actors | Supported for actor attributes ending in `Actor` | Type and member actor attributes are forwarded. |
| `Sendable` inheritance | Supported where Swift accepts the generated type | `MockSynRuntime` is `@unchecked Sendable`. |
| Associated types | Diagnostic | Use type erasure or concrete wrappers for now. |

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

Class doubles still require an accessible zero-argument initializer.

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

Variadic signatures are generated, so mocks and stubs can conform to protocols
that use them.

```swift
@Mocking
protocol Scores {
    func total(_ values: Int...) -> Int
}
```

Swift does not provide a general array splat for forwarding a captured variadic
parameter into another variadic call. Because of that, spies keep placeholder
behavior for variadic methods in this block.

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

## Associated Types

Protocols with `associatedtype` are rejected in this block:

```swift
@Mocking
protocol Repository {
    associatedtype Entity
    func load() -> Entity
}
```

Diagnostic:

```text
MockSyn cannot generate protocols with associated types yet. Use a type-erased protocol or concrete wrapper.
```

Associated type support needs a deliberate API for type binding and generated
generic doubles. It is not inferred implicitly in Block 4.
