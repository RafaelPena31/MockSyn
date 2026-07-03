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
| Invalid `access` option | Supported | Emits the supported access values. |
| Invalid `mode` option | Supported | Emits the supported mode values: `.strict` and `.relaxed`. |
| Visibility widening | Supported | Rejects generated access that is wider than the annotated declaration. |
| Class operator members | Supported | Emits an error because subclass generation does not intercept concrete static operators. |

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

## Support Matrix

The complete support matrix lives in [Support Matrix](../SUPPORT_MATRIX.md).
Diagnostics are part of the public behavior and must be covered by macro
expansion tests before new unsupported syntax is added.
