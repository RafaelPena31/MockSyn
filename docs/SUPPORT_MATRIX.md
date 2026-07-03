# Support Matrix

MockSyn supports Swift 5.9 and Swift 6. Swift 6 is a first-class target, but the public API must remain usable from Swift 5.9 projects.

## Swift Versions

| Version | Support |
| --- | --- |
| Swift 5.9 | Minimum supported version. Macro APIs must compile. Swift Testing adapter is not required. |
| Swift 5.10 | Supported when available through compatible SwiftSyntax. |
| Swift 6 | First-class support, including concurrency diagnostics and stricter Sendable behavior. |

## Toolchain Dependency

SwiftSyntax versions are tied to Swift toolchains. MockSyn must define a package strategy that maps supported Swift versions to compatible SwiftSyntax versions.

Policy:

- Keep SwiftSyntax only in the macro target.
- Keep runtime target free of SwiftSyntax.
- Test supported toolchains in CI.
- Select a SwiftSyntax version line in `Package.swift` based on the compiler version that evaluates the manifest.

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
| Simple protocol inheritance | Supported | Supported |
| Complex protocol inheritance | Supported for valid Swift inherited type syntax | Supported for valid Swift inherited type syntax |
| Non-final class doubles | Supported | Supported |
| `NSObject` subclasses | Supported as subclass generation | Supported as subclass generation |
| Objective-C runtime interception | Not supported in core | Not supported in core |
| Sync members | Supported | Supported |
| `throws` members | Supported | Supported |
| `async` members | Supported | Supported |
| `async throws` members | Supported | Supported |
| Properties | Supported, including `get async`, `get throws`, and `get async throws` | Supported, including `get async`, `get throws`, and `get async throws` |
| Subscripts | Supported, including generic subscripts | Supported, including generic subscripts |
| Static protocol members | Supported with type-level stubbing/verification | Supported with type-level stubbing/verification |
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

## Conditional APIs

Swift Testing support must be compiled conditionally:

```swift
#if canImport(Testing)
// Swift Testing adapter
#endif
```

Swift 6-specific behavior must not break Swift 5.9 compilation.
