# Supported Types

MockSyn macros support declaration types incrementally. Block 2 defines which
declarations can receive `@Mocking`, `@Stubbing`, or `@Spying`; member generation
is handled by later blocks.

## What It Does

| Type | Status | Generation model |
| --- | --- | --- |
| Protocols | Supported | Generates a final class conforming to the protocol. |
| Protocols with simple inheritance | Supported | Generates a final class conforming to the child protocol. |
| Non-final classes | Supported | Generates a final subclass of the annotated class. |
| `NSObject` classes | Supported as non-final classes | Generates a final subclass. |
| `@objc dynamic` members | Type accepted when class is subclassable | Existing members are inherited; runtime interception is not implemented. |
| Final classes | Not supported | Emits a compile-time diagnostic. |

## Protocols

Protocols are the primary MockSyn target.

```swift
@Mocking
protocol UserService {
}

#if MOCKSYN_ENABLE
let service = UserServiceMock()
#endif
```

With simple inheritance:

```swift
protocol Service {
}

@Mocking
protocol AdminService: Service {
}

#if MOCKSYN_ENABLE
let admin = AdminServiceMock()
let service: Service = admin
#endif
```

## Non-Final Classes

Non-final classes are supported through subclass generation.

```swift
@Mocking
class UserService {
}

#if MOCKSYN_ENABLE
let service = UserServiceMock()
let base: UserService = service
#endif
```

Generated class doubles call `super.init()` from their generated initializer. This
means Block 2 supports classes that have an accessible zero-argument initializer.
Initializer customization is part of the member/initializer feature blocks.

## Spies For Classes

Class spies subclass the annotated class and store the wrapped implementation.

```swift
@Spying
class CacheStore {
}

#if MOCKSYN_ENABLE
let real = CacheStore()
let spy = CacheStoreSpy(wrapping: real)
#endif
```

Delegating specific methods to the wrapped implementation requires member
generation and is implemented in later blocks.

## NSObject And @objc Dynamic

`NSObject`-backed classes are supported when they are subclassable.

```swift
@Mocking
class LegacyService: NSObject {
    @objc dynamic func ping() -> String {
        "real"
    }
}

#if MOCKSYN_ENABLE
let service = LegacyServiceMock()
#endif
```

MockSyn does not use Objective-C runtime method swizzling or message
interception. The generated type is a Swift subclass. Until member generation is
implemented, inherited `@objc dynamic` members keep their original behavior.

## Final Classes

Final classes are rejected.

```swift
@Mocking
final class UserService {
}
```

Diagnostic:

```text
MockSyn cannot mock a pure Swift final class directly. Extract a protocol and apply @Mocking to the protocol.
```

## Access Control

Generated visibility cannot be wider than the annotated declaration.

```swift
@Mocking(access: .public)
class UserService {
}
```

Diagnostic:

```text
MockSyn cannot generate a public double for an internal declaration
```

`open` classes are treated as declarations that can receive `public` generated
doubles. MockSyn does not generate `open` test doubles.

## Limitations

- Protocol and class members are not generated in Block 2.
- Classes must be subclassable and have an accessible zero-argument initializer.
- Final classes are not mocked directly.
- Objective-C runtime interception is not part of the core macro-only flow.
- Complex protocol inheritance constraints are deferred to later language-feature blocks.

## Compatibility Notes

The supported-type behavior is syntax-only. MockSyn does not scan other files or
resolve semantic type information during macro expansion.
