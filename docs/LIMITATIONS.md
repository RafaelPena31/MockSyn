# Limitations

MockSyn is inspired by MockK and Mockito, but Swift does not provide the same runtime interception model as the JVM.

## Not Supported In The Core

| Case | Reason |
| --- | --- |
| Pure Swift final classes | They cannot be subclassed or intercepted. |
| Private methods | Generated code cannot access private implementation details. |
| Global functions | Macros on protocols do not intercept global functions. |
| Concrete static methods | Static calls on concrete types are not dynamically intercepted. |
| Arbitrary constructors | Swift macros do not intercept constructor calls. |
| Runtime bytecode-style interception | Swift does not have a JVM-like bytecode agent model. |
| Fully arbitrary generated peer names | Swift attached peer macros at global scope must declare name patterns. |

## Recommended Workarounds

### Final Class

Instead of:

```swift
final class UserService {
    func fetchUser(id: String) async throws -> User { fatalError() }
}
```

Use:

```swift
@Mocking
protocol UserServicing {
    func fetchUser(id: String) async throws -> User
}

final class UserService: UserServicing {
    func fetchUser(id: String) async throws -> User { fatalError() }
}
```

### Global Function

Wrap global behavior in a protocol:

```swift
@Mocking
protocol DateProviding {
    func now() -> Date
}
```

### Static Concrete Method

Prefer protocol requirements:

```swift
@Mocking
protocol IDFactory {
    static func make() -> UUID
}
```

## Objective-C

Subclassable `NSObject` classes are supported through the same subclass generation
model used for other non-final classes.

Objective-C runtime interception is not part of the core. MockSyn does not swizzle
methods or intercept Objective-C messages. A future optional module may add
Objective-C runtime behavior, but it must remain separate from the Swift
macro-first core.

## Macro Limits

Macros operate on syntax available at the annotated declaration. They do not perform arbitrary semantic analysis across the whole project. This affects complex protocol inheritance, typealiases, overloads, and complex generic constraints.

## Custom Generated Names

MockSyn supports custom generated names that start or end with the relevant macro
affix:

- `Mock` for `@Mocking`;
- `Stub` for `@Stubbing`;
- `Spy` for `@Spying`.

Fully arbitrary generated type names are not supported in the macro-only flow.
