# Integration

MockSyn integrates as a normal Swift Package dependency. The user annotates protocols or supported types with macros and enables `MOCKSYN_ENABLE` only in build configurations where generated test doubles should exist.

## Xcode Integration

1. Add MockSyn with Swift Package Manager.
2. Add `MockSyn` to the target that contains annotated protocols.
3. Import `MockSyn` where the macros are used.
4. Add `MOCKSYN_ENABLE` to Active Compilation Conditions for the build configuration used by tests.
5. Do not define `MOCKSYN_ENABLE` for Release.

Example:

```swift
import MockSyn

@Mocking
protocol UserService {
    func fetchUser(id: String) async throws -> User
}
```

Test:

```swift
let service = UserServiceMock()
service.given.fetchUser(id: .any).willReturn(user)
```

## Active Compilation Conditions

The flag must be active in the target where the macro annotation is compiled.

| Target containing `@Mocking` | Where `MOCKSYN_ENABLE` must be set |
| --- | --- |
| App target | App target build settings |
| Framework target | Framework target build settings |
| Test target | Test target build settings |

## Recommended Build Configurations

### Convenient Profile

Use `MOCKSYN_ENABLE` in Debug.

| Configuration | Flags |
| --- | --- |
| Debug | `DEBUG MOCKSYN_ENABLE` |
| Release | Release flags only |

This is simple, but mocks also exist when running the app locally in Debug.

### Rigorous Profile

Create a separate `Testing` configuration and use it only for the Test action of the scheme.

| Configuration | Flags |
| --- | --- |
| Debug | `DEBUG` |
| Testing | `DEBUG MOCKSYN_ENABLE` |
| Release | Release flags only |

This prevents generated mocks from existing in normal Debug app runs.

## SwiftPM Consumer Integration

```swift
.package(url: "https://github.com/RafaelPena31/MockSyn.git", from: "0.7.0")
```

In the target containing annotations:

```swift
.target(
    name: "AppCore",
    dependencies: [
        .product(name: "MockSyn", package: "MockSyn")
    ],
    swiftSettings: [
        .define("MOCKSYN_ENABLE", .when(configuration: .debug))
    ]
)
```

## CI Integration

CI should have separate jobs:

- Build Release without `MOCKSYN_ENABLE`.
- Run tests with `MOCKSYN_ENABLE`.
- Run macro expansion tests for MockSyn itself.
- Run performance checks for macro expansion and runtime overhead.

## Import Policy

The target containing `@Mocking`, `@Stubbing`, or `@Spying` imports `MockSyn`.

The runtime APIs used by generated code are referenced only inside `#if MOCKSYN_ENABLE`. The package dependency still exists for the annotated target, but generated test double declarations do not compile into Release when the flag is absent.

## Generated Artifact Location

Generated types are not written to a project folder. They exist as compiler macro expansion output. Xcode and SwiftPM may cache build artifacts in DerivedData or `.build`, but MockSyn does not manage those caches.
