# Changelog

All notable changes to MockSyn are documented in this file.

## 0.4.0 - 2026-07-02

### Added

- Generic method generation with preserved generic parameter and `where` clauses.
- Generic class double generation with mirrored generic parameters and superclass arguments.
- `inout` parameter forwarding for delegating spies.
- Closure and `@escaping` closure signature preservation.
- Variadic method signature generation with non-delegating placeholder behavior for spies.
- Global actor forwarding for type and member actor attributes such as `@MainActor`.
- `Self` return requirement preservation for generated placeholder behavior.
- Diagnostic for protocols with `associatedtype`.
- Documentation for Swift language feature support and limits.

### Notes

- SwiftPM package versioning is provided by the Git tag `0.4.0`.
- Associated types are diagnosed rather than inferred. Type binding for associated-type protocols remains a future feature.

## 0.3.0 - 2026-07-02

### Added

- Member generation for supported protocol and class declarations.
- Generated sync, `throws`, `async`, and `async throws` methods.
- Generated `get` and `get set` properties.
- Generated callable `Void` methods and setters.
- Generated protocol static requirements for methods and properties.
- Generated protocol initializer requirements for mocks and stubs.
- Generated subscript requirements, including labeled and underscored subscripts.
- Spy delegation for supported instance methods, readable properties, and readable protocol subscripts.
- Operator diagnostics for protocol and class members that MockSyn cannot generate yet.
- Documentation for supported members and current Block 3 runtime behavior.

### Notes

- SwiftPM package versioning is provided by the Git tag `0.3.0`.
- Block 3 provides compile-time member conformance and placeholder behavior. Stubbing, verification, and invocation recording remain planned for later blocks.

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
