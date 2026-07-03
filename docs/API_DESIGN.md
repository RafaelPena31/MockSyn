# API Design

MockSyn's public API should feel close to MockK and Mockito while staying idiomatic for Swift macros.

## Macro API

```swift
import MockSyn

@Mocking
protocol UserService {
    var baseURL: URL { get set }
    func fetchUser(id: String) async throws -> User
    func save(_ user: User) throws
}
```

Generated default:

```swift
#if MOCKSYN_ENABLE
internal final class UserServiceMock: UserService {
    // Generated implementation.
}
#endif
```

## Macro Options

The common path should require no parameters.

```swift
@Mocking
protocol UserService { }
```

Advanced options:

```swift
@Mocking(name: "MockUserService", access: .public, mode: .strict)
protocol UserService { }
```

Supported options:

| Option | Meaning |
| --- | --- |
| `name` | Overrides the generated type name. |
| `access` | Controls generated type access when valid. |
| `mode` | Selects strict or relaxed default behavior. |

Swift attached peer macros cannot introduce fully arbitrary global names. Custom
names must match the macro name pattern: `@Mocking` names start or end with
`Mock`, `@Stubbing` names start or end with `Stub`, and `@Spying` names start or
end with `Spy`.

The generated condition is not normally configured per macro. It defaults to `MOCKSYN_ENABLE`.

## Mocking

```swift
let service = UserServiceMock()

service.given.fetchUser(id: .value("123")).willReturn(user)

let result = try await sut.loadUser(id: "123")

service.verify.fetchUser(id: .value("123")).called(.once)
```

## Stubbing

```swift
@Stubbing
protocol AnalyticsService {
    func currentSession() -> Session
}

let analytics = AnalyticsServiceStub()
analytics.given.currentSession().willReturn(session)
```

Stubs focus on responses. They may still record calls, but verification is not their main purpose.

## Spying

```swift
@Spying
protocol CacheStore {
    func readUser(id: String) -> User?
    func saveUser(_ user: User)
}

let real = InMemoryCacheStore()
let spy = CacheStoreSpy(wrapping: real)

spy.saveUser(user)

spy.verify.saveUser(.value(user)).called(.once)
```

## Partial Spy

```swift
let spy = UserServiceSpy(wrapping: realService)

spy.given.fetchUser(id: .value("offline")).willThrow(NetworkError.offline)

_ = try await spy.fetchUser(id: "123")       // Delegates to real service.
_ = try await spy.fetchUser(id: "offline")   // Uses stubbed behavior.
```

## Stubbing DSL

```swift
service.given.fetchUser(id: .any).willReturn(user)
service.given.fetchUser(id: .value("404")).willThrow(UserError.notFound)
service.given.fetchUser(id: .matching { $0.hasPrefix("admin") }).willRun { id in
    User(id: id, name: "Admin")
}
```

Sequential values:

```swift
service.given.fetchUser(id: .any).willReturn(firstUser, secondUser, thirdUser)
```

## Properties

```swift
service.given.baseURL.get.willReturn(URL(string: "https://api.test")!)

service.baseURL = URL(string: "https://new.test")!

service.verify.baseURL.get.called(.once)
service.verify.baseURL.set(.any).called(.once)
```

## Verification DSL

```swift
service.verify.fetchUser(id: .value("123")).called(.once)
service.verify.save(.any).called(.never)
service.verify.fetchUser(id: .any).called(.times(2))
service.verify.fetchUser(id: .any).called(.atLeast(1))
service.verify.fetchUser(id: .any).called(.atMost(3))
```

## Order Verification

```swift
MockSyn.verifyInOrder {
    cache.verify.readUser(id: .value("123"))
    service.verify.fetchUser(id: .value("123"))
    cache.verify.saveUser(.any)
}
```

Cross-mock order:

```swift
MockSyn.verifyInOrder {
    analytics.verify.track(.value("screen_opened"))
    service.verify.fetchUser(id: .any)
    analytics.verify.track(.value("user_loaded"))
}
```

## Captors

```swift
let idCaptor = MockSynArgumentCaptor<String>()

try service.verify.fetchUser(id: idCaptor.capture()).once()

#expect(idCaptor.value == "123")
```

Closure captor:

```swift
let completion = MockSynClosureCaptor<(Result<User, Error>) -> Void>()

try service.verify.loadUser(completion: completion.capture()).once()
```

## Strict And Relaxed Modes

```swift
let strict = UserServiceMock(mode: .strict)
let relaxed = UserServiceMock(mode: .relaxed)
```

Strict mode fails when an unstubbed non-void call is executed. Relaxed mode returns configured default values when possible.

## Global APIs

```swift
MockSyn.confirmVerified(service)
MockSyn.checkUnnecessaryStubs(service)
MockSyn.reset(service)
```

## Async Timeout Verify

```swift
Task {
    _ = try await service.fetchUser(id: "123")
}

await service.verify.fetchUser(id: .value("123")).called(.once, timeout: .seconds(1))
```

## Static Requirements

```swift
@Mocking
protocol IDFactory {
    static func make() -> UUID
}

IDFactoryMock.given.make().willReturn(fixedID)
let id = IDFactoryMock.make()
IDFactoryMock.verify.make().called(.once)
```

## Subscripts

```swift
@Mocking
protocol SettingsStore {
    subscript(key: String) -> String? { get set }
}

let store = SettingsStoreMock()

store.given.subscript(.value("theme")).get.willReturn("dark")

_ = store["theme"]
store["theme"] = "light"

store.verify.subscript(.value("theme")).get.called(.once)
store.verify.subscript(.value("theme")).set(.value("light")).called(.once)
```

## Final Class Diagnostic

```swift
@Mocking
final class UserService {
    func fetchUser(id: String) async throws -> User { fatalError() }
}
```

Expected diagnostic:

```text
MockSyn cannot mock a pure Swift final class directly. Extract a protocol and apply @Mocking to the protocol.
```
