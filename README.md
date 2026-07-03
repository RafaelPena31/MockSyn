# MockSyn

MockSyn is a Swift macro-first framework for generating mocks, stubs, and spies with an API inspired by MockK and Mockito.

The framework is implemented incrementally by feature block. Version 0.22.0 adds scoped Objective-C runtime interception for selectors visible to `ObjectiveC.runtime`.

## Installation

```swift
.package(url: "https://github.com/RafaelPena31/MockSyn.git", from: "0.22.0")
```

## Core Directives

- Macro-first API. No build tool plugin, source generator, or generated source folder is part of the product flow.
- MockK/Mockito-style test syntax is a product requirement.
- Generated test doubles are guarded by `#if MOCKSYN_ENABLE` by default.
- Swift 5.9 is the minimum supported language version. Swift 6 must be fully supported.
- Documentation is required before implementation: public API doc strings, focused inline comments, and Markdown feature docs.

## Documents

- [Features](docs/FEATURES.md)
- [Documentation Index](docs/README.md)
- [Macros](docs/features/macros.md)
- [Supported Members](docs/features/supported-members.md)
- [Swift Language Features](docs/features/swift-language-features.md)
- [Stubbing](docs/features/stubbing.md)
- [Verification](docs/features/verification.md)
- [Matchers And Captors](docs/features/matchers-and-captors.md)
- [Test Double Modes](docs/features/test-double-modes.md)
- [Runtime Internals](docs/features/runtime-internals.md)
- [Test Integration](docs/features/test-integration.md)
- [Diagnostics](docs/features/diagnostics.md)
- [Objective-C Interception](docs/features/objective-c-interception.md)
- [Tooling](docs/features/tooling.md)
- [Architecture](docs/ARCHITECTURE.md)
- [API Design](docs/API_DESIGN.md)
- [Integration](docs/INTEGRATION.md)
- [Errors](docs/ERRORS.md)
- [Logging](docs/LOGGING.md)
- [Performance](docs/PERFORMANCE.md)
- [Documentation Guide](docs/DOCUMENTATION_GUIDE.md)
- [Support Matrix](docs/SUPPORT_MATRIX.md)
- [Limitations](docs/LIMITATIONS.md)
- [Testing Strategy](docs/TESTING_STRATEGY.md)
- [Migration Guides](docs/migration)
- [Changelog](CHANGELOG.md)
