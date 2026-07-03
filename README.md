# MockSyn

MockSyn is a Swift macro-first framework for generating mocks, stubs, and spies with an API inspired by MockK and Mockito.

The framework is implemented incrementally by feature block. Block 1 covers the public macro surface and generated type declaration model.

## Installation

```swift
.package(url: "https://github.com/RafaelPena31/MockSyn.git", from: "0.1.0")
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
- [Changelog](CHANGELOG.md)
