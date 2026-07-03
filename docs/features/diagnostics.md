# Diagnostics

Block 11 defines MockSyn's compile-time diagnostic surface. The goal is to fail
early when a macro cannot produce correct Swift and to give the user a concrete
next step.

## Supported Diagnostics

| Case | Status | Behavior |
| --- | --- | --- |
| Unsupported macro target | Supported | Emits a macro-specific error when `@Mocking`, `@Stubbing`, or `@Spying` is used on an unsupported declaration. |
| Pure Swift `final` class | Supported | Emits an error explaining that final Swift classes cannot be mocked by subclass generation. |
| Final-class fix-it | Supported | Offers `Remove 'final'` when subclass generation is acceptable. |
| Final class member | Supported | Emits an error when a method or property cannot be overridden because the member itself is `final`. |
| Invalid `access` option | Supported | Emits the supported access values. |
| Invalid `mode` option | Supported | Emits the supported mode values: `.strict` and `.relaxed`. |
| Visibility widening | Supported | Rejects generated access that is wider than the annotated declaration. |
| Class operator members | Supported | Emits an error because subclass generation does not intercept concrete static operators. |
| Concrete static class members | Supported | Emits an error because Swift macros cannot intercept concrete static dispatch. |
| Variadic class initializers | Supported | Emits an error because Swift cannot forward captured variadic arrays to `super.init`. |
| Required class initializer on spies | Supported | Emits an error because the exact required initializer cannot receive the wrapped spy instance. |

## Invalid Target

```swift
@Mocking
enum UserService {
}
```

Diagnostic:

```text
@Mocking can only be applied to protocols or supported classes
```

## Final Class

```swift
@Mocking
final class UserService {
}
```

Diagnostic:

```text
MockSyn cannot mock a pure Swift final class directly. Extract a protocol and apply @Mocking to the protocol.
```

Fix-it:

```text
Remove 'final'
```

Use the fix-it only when the class is intentionally subclassable in tests.
Otherwise, keep the production class final and extract a protocol:

```swift
@Mocking
protocol UserServicing {
    func loadUser(id: String) async throws -> User
}

final class UserService: UserServicing {
    func loadUser(id: String) async throws -> User {
        fatalError("production implementation")
    }
}
```

## Final Class Member

```swift
@Mocking
class UserService {
    final func loadUser(id: String) -> User {
        fatalError("production implementation")
    }
}
```

Diagnostic:

```text
MockSyn cannot mock final class members by subclass generation. Remove 'final' from the member or extract a protocol.
```

Fix-it:

```text
Remove 'final'
```

This case is separate from a `final class`: the type can be subclassed, but the
specific member cannot be overridden. MockSyn rejects the macro expansion early
so tests do not receive a generated subclass that fails later with an invalid
`override`.

## Invalid Options

```swift
@Mocking(access: .open)
protocol UserService {
}
```

Diagnostic:

```text
MockSyn access must be one of: internal, public, package, fileprivate, private
```

```swift
@Mocking(mode: .lenient)
protocol UserService {
}
```

Diagnostic:

```text
MockSyn mode must be one of: strict, relaxed
```

## Protocol Inheritance

Inherited protocol syntax that is valid Swift is supported:

```swift
@Mocking
protocol AuthenticatedUserService: UserService, Sendable {
}
```

```swift
@Mocking
protocol AuthenticatedUserService: Foundation.Sendable {
}
```

## Unsupported Members

Protocol operator requirements are supported. Class operator members are rejected
because they are concrete static members and cannot be overridden or intercepted
by the generated subclass:

```swift
@Mocking
class ComparableService {
    static func == (lhs: ComparableService, rhs: ComparableService) -> Bool {
        false
    }
}
```

Diagnostic:

```text
MockSyn cannot generate class operator members. Move the operator behind a protocol requirement.
```

Concrete static class members are also rejected:

```swift
@Mocking
class IDFactory {
    static func make() -> String {
        "real"
    }
}
```

Diagnostic:

```text
MockSyn cannot intercept concrete static class members. Move the static member behind a protocol requirement or use Objective-C interception for Objective-C class methods.
```

Protocol static requirements are supported. Concrete `SomeType.staticMethod()`
calls are not rewritten by Swift macros. If the member is an Objective-C class
method, use `MockSynObjCInterception.replaceClassMethod`.

Variadic class initializers are rejected because the macro receives the captured
variadic values as an array, and Swift has no general splat syntax for
forwarding that array to `super.init`:

```swift
@Mocking
class SeededService {
    init(values: Int...) {}
}
```

Diagnostic:

```text
MockSyn cannot mirror variadic class initializers because Swift cannot forward captured variadic arrays to super.init.
```

Class spies also reject `required` class initializers. The exact required
signature must be implemented by the subclass, but MockSyn class spies need a
wrapped instance parameter:

```swift
@Spying
class CacheStore {
    required init(seed: String) {}
}
```

Diagnostic:

```text
MockSyn cannot mirror required class initializers for spies because class spies need a wrapped instance. Prefer a protocol spy or remove the required initializer.
```

## Support Matrix

The complete support matrix lives in [Support Matrix](../SUPPORT_MATRIX.md).
Diagnostics are part of the public behavior and must be covered by macro
expansion tests before new unsupported syntax is added.
