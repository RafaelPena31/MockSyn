# Changelog

All notable changes to MockSyn are documented in this file.

## 0.2.0 - 2026-07-02

### Added

- Supported type generation for simple protocol inheritance.
- Supported subclass generation for non-final classes.
- Supported subclass generation for subclassable `NSObject` and `@objc dynamic` class scenarios.
- Diagnostics coverage for final classes across `@Mocking`, `@Stubbing`, and `@Spying`.
- Documentation for supported declaration types and Objective-C runtime limitations.

### Notes

- SwiftPM package versioning is provided by the Git tag `0.2.0`.
- Block 2 defines supported declaration types. Member generation remains planned for later feature blocks.

## 0.1.0 - 2026-07-02

### Added

- Initial SwiftPM package setup for MockSyn.
- Public macro declarations for `@Mocking`, `@Stubbing`, and `@Spying`.
- Macro option support for generated `name`, `access`, and `mode`.
- Generated test double declarations guarded by `#if MOCKSYN_ENABLE`.
- Runtime metadata types: `MockSynRuntime`, `MockSynMode`, `MockSynAccess`, and `MockSynDoubleKind`.
- Macro diagnostics for unsupported declarations, final classes, invalid access values, invalid generated names, and visibility widening.
- Macro expansion, integration, runtime, and coverage tests for Block 1.
- Documentation for architecture, integration, limitations, testing strategy, and Block 1 macros.

### Notes

- SwiftPM package versioning is provided by the Git tag `0.1.0`.
- Block 1 supports protocols with no requirements. Protocol members are planned for later feature blocks.
