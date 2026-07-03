# Migrating From Cuckoo

Cuckoo uses generated files, often named `GeneratedMocks.swift`, produced by a
separate generation step. MockSyn uses Swift macros and does not require a
generated source folder.

## Before

```swift
// GeneratedMocks.swift is produced before tests compile.
let service = MockUserService()
stub(service) { stub in
    when(stub.loadUser(id: any())).thenReturn(user)
}
```

## After

```swift
import MockSyn

@Mocking
protocol UserService {
    func loadUser(id: String) throws -> User
}
```

```swift
let service = UserServiceMock()
service.given.loadUser(id: .any).willReturn(user)
_ = try service.loadUser(id: "42")
try service.verify.loadUser(id: .value("42")).once()
```

## Migration Notes

- Remove generated mock files from the project after replacing the annotated
  surface with `@Mocking`, `@Stubbing`, or `@Spying`.
- Remove generator build phases or scripts that only existed for Cuckoo.
- Keep `MOCKSYN_ENABLE` out of Release configurations.
- Use protocol extraction for final classes instead of runtime interception.
