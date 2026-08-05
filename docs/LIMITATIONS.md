# Limitations

MockSyn is inspired by MockK and Mockito, but Swift does not provide the same runtime interception model as the JVM.

## Not Supported In The Core

| Case | Reason |
| --- | --- |
| Pure Swift final classes | They cannot be subclassed or intercepted. |
| Final methods and properties on classes | Subclass generation cannot override final members. |
| Private methods | Generated code cannot access private implementation details. |
| Global functions | Macros on protocols do not intercept global functions. |
| Concrete static methods | Static calls on concrete types are not dynamically intercepted. |
| Arbitrary constructors | Swift macros do not intercept direct constructor calls. Use explicit constructor seams when factory injection is possible. |
| Class operator members | Class operator overriding is not part of the subclass-generation model. |
| Runtime bytecode-style interception | Swift does not have a JVM-like bytecode agent model. |
| Fully arbitrary generated peer names | Swift attached peer macros at global scope must declare name patterns. |
| Inherited protocol requirements | Peer macros receive the annotated declaration's syntax, not a semantic expansion of parent protocols. |
| Declarations from compiled modules | A macro cannot attach retroactively to source that is not being compiled. |

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

The same rule applies to `final` methods or properties inside a non-final class.
If the member must stay final in production, put the test-facing contract behind
a protocol and annotate that protocol instead.

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

### Operators

Protocol operator requirements are supported through generated static operators
and named DSL aliases:

```swift
@Mocking
protocol ComparableService {
    static func == (lhs: Self, rhs: Self) -> Bool
}

#if MOCKSYN_ENABLE
ComparableServiceMock.given.equalTo(lhs: .any, rhs: .any).willReturn(true)
#endif
```

Class operator members and other concrete static class members produce a
diagnostic because MockSyn does not intercept concrete static dispatch on
subclasses.

For pure Swift global functions, wrap the behavior in a protocol. For
Objective-C class methods, use `MockSynObjCInterception.replaceClassMethod`.

## Objective-C

Subclassable `NSObject` classes are supported through the same subclass generation
model used for other non-final classes.

Objective-C runtime interception is available through the explicit
`MockSynObjCInterception` API when `ObjectiveC.runtime` can be imported. It is
not automatic macro generation: tests must name the class, selector, and
replacement block, and must keep the returned token alive for the interception
scope.

Only selectors visible to the Objective-C runtime can be intercepted. Pure Swift
methods, Swift-only final dispatch, global functions, and arbitrary constructor
calls are still outside this model.

## Constructors

MockSyn supports explicit constructor seams through `MockSynConstructor`,
`MockSynConstructor1`, and `MockSynConstructor2`. These APIs let tests replace a
factory dependency for a scoped block.

They do not intercept direct `Type(...)` calls. Code must receive and call the
constructor seam for the replacement to take effect.

## Macro Limits

Macros operate on syntax available at the annotated declaration. They do not
perform arbitrary semantic analysis across the whole project. This affects
typealiases, inherited protocol requirements, and some initializer scenarios.
Custom protocol inheritance emits a warning. Redeclare the required members in
the annotated child protocol so the macro can generate them; marker protocols
such as `AnyObject` and `Sendable` do not emit that warning.

For an external or KMP protocol, declare an annotated local mirror with the same
requirements and add conformance from the generated double to the external
protocol. The compiler then detects signature drift at the conformance
extension, but MockSyn cannot read the binary module and create the mirror.

`ObservableObject` publishing is generated only when the annotated declaration
directly inherits `ObservableObject`. Indirect inheritance is subject to the
same syntax-only limitation.

Variadic class initializers are
diagnosed because Swift cannot forward captured variadic arrays to `super.init`,
and required class initializers are diagnosed for class spies because the exact
required signature cannot receive the wrapped spy instance.

On Swift 5.9, SwiftSyntax 509 does not expose an enclosing extension's access
modifier to an attached peer macro. A declaration whose effective visibility
comes only from such an extension must pass `access:` explicitly.

## Custom Generated Names

MockSyn supports custom generated names that start or end with the relevant macro
affix:

- `Mock` for `@Mocking`;
- `Stub` for `@Stubbing`;
- `Spy` for `@Spying`.

Fully arbitrary generated type names are not supported in the macro-only flow.
