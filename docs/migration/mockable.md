# Migrating From Mockable

Mockable and MockSyn both use macros, so this is the closest migration path.
The main difference is syntax and runtime style: MockSyn exposes MockK/Mockito
inspired `given`, `when`, and `verify` APIs on generated doubles.

## Before

```swift
@Mockable
protocol UserService {
    func loadUser(id: String) async throws -> User
}
```

## After

```swift
import MockSyn

@Mocking
protocol UserService {
    func loadUser(id: String) async throws -> User
}
```

```swift
let service = UserServiceMock()
service.given.loadUser(id: .any).willReturn(user)
let result = try await service.loadUser(id: "42")
try service.verify.loadUser(id: .value("42")).once()
```

## Migration Notes

- Keep annotations on protocols or supported non-final classes.
- Replace Mockable expectation syntax with MockSyn `given` / `when` and
  `verify`.
- Enable `MOCKSYN_ENABLE` only in the target configuration used by tests.
- Final Swift classes still need a protocol boundary or a non-final wrapper.
