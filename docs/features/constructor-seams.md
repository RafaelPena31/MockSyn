# Constructor Seams

MockSyn cannot intercept arbitrary `Type(...)` constructor call sites. Swift
macros do not rewrite call sites, and Swift does not provide a JVM-style runtime
agent for constructor interception.

For code that can receive a factory dependency, MockSyn provides explicit
constructor seams:

- `MockSynConstructor<Output>` for zero arguments;
- `MockSynConstructor1<Argument, Output>` for one argument;
- `MockSynConstructor2<FirstArgument, SecondArgument, Output>` for two arguments.

## When To Use

Use constructor seams when:

- production code can accept a factory dependency;
- a test needs to replace object construction for a scoped block;
- protocol extraction would be heavier than a small factory seam;
- the constructor behavior should be restored automatically after the test.

Do not use constructor seams as proof that direct `UserService(...)` calls are
intercepted. They are not. Code must call the seam.

## Zero Arguments

```swift
struct UserSession {
    let id: String
}

let sessionConstructor = MockSynConstructor {
    UserSession(id: UUID().uuidString)
}

let interception = sessionConstructor.replace {
    UserSession(id: "test")
}

XCTAssertEqual(sessionConstructor().id, "test")

interception.restore()
```

## One Argument

```swift
let userConstructor = MockSynConstructor1<String, User> { id in
    User(id: id, name: "Production")
}

let interception = userConstructor.replace { id in
    User(id: id, name: "Test")
}

XCTAssertEqual(userConstructor("42").name, "Test")
interception.restore()
```

## Two Arguments

```swift
let userConstructor = MockSynConstructor2<String, String, User> { id, name in
    User(id: id, name: name)
}

let interception = userConstructor.replace { id, name in
    User(id: "mock-\(id)", name: name.uppercased())
}

XCTAssertEqual(userConstructor("42", "Rafa").id, "mock-42")
interception.restore()
```

## Restoration

`replace` returns a `MockSynConstructorInterception` token. MockSyn restores the
previous constructor implementation when:

- `restore()` is called;
- the token is released.

`restore()` is idempotent. Nested replacements restore to the implementation
that was active before each replacement.

## Integration Shape

Production code should depend on the seam instead of constructing directly:

```swift
final class UserFlow {
    private let makeUser: MockSynConstructor1<String, User>

    init(makeUser: MockSynConstructor1<String, User>) {
        self.makeUser = makeUser
    }

    func start(id: String) -> User {
        makeUser(id)
    }
}
```

Tests can then replace construction without rewriting call sites:

```swift
let makeUser = MockSynConstructor1<String, User> { User(id: $0, name: "Real") }
let flow = UserFlow(makeUser: makeUser)

let interception = makeUser.replace { User(id: $0, name: "Stub") }

XCTAssertEqual(flow.start(id: "42").name, "Stub")
interception.restore()
```

## Limits

- Direct `Type(...)` calls are not intercepted.
- Initializer bodies are not swizzled.
- Global allocation behavior is not changed.
- For Objective-C factory methods, use `MockSynObjCInterception`.
- For pure Swift construction in app code, prefer protocol factories or these
  explicit constructor seams.
