# MockSyn Documentation

This folder contains the required design and feature documentation for MockSyn.

## Required Reading Order

1. [Architecture](ARCHITECTURE.md)
2. [API Design](API_DESIGN.md)
3. [Integration](INTEGRATION.md)
4. [Support Matrix](SUPPORT_MATRIX.md)
5. [Errors](ERRORS.md)
6. [Logging](LOGGING.md)
7. [Performance](PERFORMANCE.md)
8. [Documentation Guide](DOCUMENTATION_GUIDE.md)
9. [Limitations](LIMITATIONS.md)
10. [Testing Strategy](TESTING_STRATEGY.md)

## Feature Docs

- [Macros](features/macros.md)
- [Supported Types](features/supported-types.md)
- [Supported Members](features/supported-members.md)
- [Swift Language Features](features/swift-language-features.md)
- [Stubbing](features/stubbing.md)
- [Verification](features/verification.md)

## Non-Negotiable Product Decisions

- MockSyn is a macro-first framework.
- No build tool plugin or external source generator is part of the product flow.
- The user-facing API should feel close to MockK and Mockito.
- Generated mocks, stubs, and spies are protected by `MOCKSYN_ENABLE` by default.
- Release builds should not contain generated test doubles unless the consumer explicitly enables `MOCKSYN_ENABLE`.
- The target containing the macro annotation pays the macro expansion cost. MockSyn reduces that cost but does not claim it is zero.
- Swift 5.9 is the minimum version. Swift 6 is a first-class target.
