# Migrating From SwiftyMocky

SwiftyMocky typically relies on generated `Mock.generated.swift` files and
Given/Verify helpers. MockSyn keeps the familiar test shape but generates the
double through Swift macros.

## Before

```swift
// Mock.generated.swift is produced by the generator.
let service = UserServiceMock()
Given(service, .loadUser(id: .any, willReturn: user))
Verify(service, .loadUser(id: .value("42")))
```

## After

```swift
import MockSyn

@Mocking
protocol UserService {
    func loadUser(id: String) -> User
}
```

```swift
let service = UserServiceMock()
service.given.loadUser(id: .any).willReturn(user)
_ = service.loadUser(id: "42")
try service.verify.loadUser(id: .value("42")).once()
```

## Migration Notes

- Replace SwiftyMocky annotations/templates with MockSyn macros.
- Remove generated `Mock.generated.swift` artifacts once the macro-generated
  doubles compile.
- Map `Given` to `given` or `when`.
- Map `Verify` to the generated `verify` API.
- Bind associated-type protocols through the generated generic mock, stub, or
  spy type parameters.
