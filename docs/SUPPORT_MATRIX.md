# Support Matrix

MockSyn supports Swift 5.9 and Swift 6. Swift 6 is a first-class target, but the public API must remain usable from Swift 5.9 projects.

## Swift Versions

| Version | Support |
| --- | --- |
| Swift 5.9 | Minimum supported version. Macro APIs must compile. Swift Testing adapter is not required. |
| Swift 5.10 | Supported when available through compatible SwiftSyntax. |
| Swift 6.0-6.3 | First-class support, including language-mode and concurrency validation. |
| Swift 6.4 beta | Supported with the exact SwiftSyntax 604 prerelease pinned by the manifest. |

## Toolchain Dependency

SwiftSyntax versions are tied to Swift toolchains. `Package.swift` selects the
compatible dependency line from the compiler that evaluates the manifest.

Policy:

- Keep SwiftSyntax only in the macro target.
- Keep runtime target free of SwiftSyntax.
- Test supported toolchains in CI.
- Select a SwiftSyntax version line in `Package.swift` based on the compiler version that evaluates the manifest.

| Compiler | SwiftSyntax dependency |
| --- | --- |
| Swift 5.9 | `509.x` |
| Swift 5.10 | `510.x` |
| Swift 6.0 | `600.x` |
| Swift 6.1 | `601.x` |
| Swift 6.2 | `602.x` |
| Swift 6.3 | `603.x` |
| Swift 6.4 beta | `604.0.0-prerelease-2026-06-05` exactly |

The 604 pin is temporary until a compatible stable 604 tag exists.

## Platform Support

Initial platform support:

| Platform | Support |
| --- | --- |
| iOS | Supported |
| macOS | Supported |
| tvOS | Supported |
| watchOS | Supported |
| visionOS | Supported when the selected Xcode supports it |

## Feature Support

| Feature | Swift 5.9 | Swift 6 |
| --- | --- | --- |
| Protocol mocks | Supported | Supported |
| Protocol inheritance syntax | Accepted; custom inheritance emits a warning | Accepted; custom inheritance emits a warning |
| Inherited protocol requirements | Redeclare locally; not discovered semantically by the macro | Redeclare locally; not discovered semantically by the macro |
| Direct `ObservableObject` inheritance | Supported when Combine is available | Supported when Combine is available |
| Non-final class doubles | Supported | Supported |
| Pure Swift final classes and final class members | Diagnostic with fix-it where actionable | Diagnostic with fix-it where actionable |
| `NSObject` subclasses | Supported as subclass generation | Supported as subclass generation |
| Objective-C runtime interception | Supported via explicit `MockSynObjCInterception` API when `ObjectiveC.runtime` is available | Supported via explicit `MockSynObjCInterception` API when `ObjectiveC.runtime` is available |
| Sync members | Supported | Supported |
| `throws` members | Supported | Supported |
| `rethrows` members | Supported with non-throwing stubs and rethrowing spy fallback | Supported with non-throwing stubs and rethrowing spy fallback |
| `async` members | Supported | Supported |
| `async throws` members | Supported | Supported |
| Properties | Supported, including `get async`, `get throws`, and `get async throws` | Supported, including `get async`, `get throws`, and `get async throws` |
| Subscripts | Supported, including generic subscripts | Supported, including generic subscripts |
| Static protocol members | Supported with type-level stubbing/verification | Supported with type-level stubbing/verification |
| Return-type-only overloads | Supported with return-disambiguated DSL names and runtime keys | Supported with return-disambiguated DSL names and runtime keys |
| Concrete static class members | Diagnostic; use protocol static requirements or Objective-C interception for Objective-C class methods | Diagnostic; use protocol static requirements or Objective-C interception for Objective-C class methods |
| Global functions | Diagnostic; wrap behind a protocol or explicit test seam | Diagnostic; wrap behind a protocol or explicit test seam |
| Constructor seams | Supported with factories accepting 0-2 arguments | Supported with factories accepting 0-2 arguments |
| Arbitrary direct constructor interception | Not supported; Swift macros do not rewrite `Type(...)` call sites | Not supported; Swift macros do not rewrite `Type(...)` call sites |
| Protocol initializers | Supported for mocks/stubs | Supported for mocks/stubs |
| Class initializers | Mirrored for non-variadic class initializers; required initializers supported for mocks/stubs | Mirrored for non-variadic class initializers; required initializers supported for mocks/stubs |
| Protocol operator requirements | Supported with named type-level stubbing/verification DSL | Supported with named type-level stubbing/verification DSL |
| Class operator members | Diagnostic | Diagnostic |
| Generic methods | Supported | Supported |
| Generic classes | Supported | Supported |
| `where` clauses | Supported for generated methods/classes | Supported for generated methods/classes |
| `Self` requirements | Supported for generated methods and direct operator parameters/returns | Supported for generated methods and direct operator parameters/returns |
| `inout` parameters | Supported | Supported |
| Variadic parameters | Signature supported; sync spies delegate one variadic parameter up to 8 values | Signature supported; sync spies delegate one variadic parameter up to 8 values |
| Closures / `@escaping` | Supported | Supported |
| Global actors | Supported where syntax is available | Supported |
| Associated types | Supported for generated generic protocol doubles | Supported for generated generic protocol doubles |
| Stubs | Supported | Supported |
| Spies | Supported | Supported |
| XCTest adapter | Supported | Supported |
| Swift Testing adapter | Optional when available | Supported as optional adapter |
| Sendable strictness | Best effort | First-class diagnostics |
| Compile-time fix-its | Supported where actionable | Supported where actionable |
| Optional inspection CLI | Supported outside build flow | Supported outside build flow |
| DocC catalog | Supported | Supported |
| Migration guides | Supported | Supported |

## Swift 5.9 Access Note

Generated access defaults to the annotated declaration's access. With
SwiftSyntax 509, an attached peer macro cannot observe an access modifier written
only on the surrounding extension. In that specific Swift 5.9 shape, pass an
explicit non-widening value such as `@Mocking(access: .public)`.

## Conditional APIs

Swift Testing support must be compiled conditionally:

```swift
#if canImport(Testing)
// Swift Testing adapter
#endif
```

Swift 6-specific behavior must not break Swift 5.9 compilation.
