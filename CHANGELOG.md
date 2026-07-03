# Changelog

All notable changes to MockSyn are documented in this file.

## 0.18.0 - 2026-07-03

### Added

- Generic subscript generation for protocol and class doubles.
- Preservation of subscript generic parameter clauses such as `<Value: Sendable>`.
- Preservation of subscript generic `where` clauses on generated members and generated `given`, `when`, and `verify` APIs.
- Runtime-backed stubbing and verification coverage for generic subscript getters and setters.
- Macro expansion and integration tests proving generic subscripts compile and route through `MockSynRuntime`.

### Changed

- Generic subscript runtime member keys now include generic clauses and `where` clauses to avoid collisions between otherwise-identical generic subscript requirements.
- Documentation and support matrix now describe generic subscripts as supported.

### Notes

- SwiftPM package versioning is provided by the Git tag `0.18.0`.
- When a generic type appears only in a subscript return type, tests can bind the generated `MockSynSubscriptStubber` or `MockSynSubscriptVerification` type explicitly.

## 0.17.0 - 2026-07-03

### Added

- Effectful property getter generation for `get async`, `get throws`, and `get async throws` requirements.
- Runtime-backed stubbing and verification for effectful property getters on mocks and stubs.
- Static protocol property support for effectful getters through the generated type-level runtime.
- Spy support for async effectful property getters by recording the getter access and delegating to the wrapped implementation.
- Macro expansion and integration tests proving effectful getters compile, preserve accessor effects, support stubbing and verification, and delegate through spies.

### Changed

- Generated property accessors now preserve getter effect specifiers instead of emitting only synchronous getters.
- Documentation and support matrix now describe effectful property getter support and the async spy delegation limit.

### Notes

- SwiftPM package versioning is provided by the Git tag `0.17.0`.
- Async spy property getters delegate directly after recording because Swift async getters cannot be called from the existing synchronous fallback closure.

## 0.16.0 - 2026-07-03

### Added

- Protocol operator requirement generation for static operators such as `==`, `+`, and custom operator symbols.
- Named operator DSL entries for generated type-level `given`, `when`, and `verify` APIs, including common aliases like `equalTo` and `plus`.
- Deterministic fallback names for custom operators using Unicode scalar encoding, for example `operator_u3c_u7e_u3e`.
- Macro expansion and integration tests proving generated operators compile, route through `MockSynRuntime`, support stubbing, and support verification.

### Changed

- Protocol operator requirements are no longer rejected with a compile-time diagnostic.
- Generated stubbing builders now resolve direct `Self` return types to the generated double type inside nested DSL structs, avoiding accidental use of the nested `Self`.
- Documentation and support matrix now describe protocol operators as supported and class operator members as diagnostic-only.

### Notes

- SwiftPM package versioning is provided by the Git tag `0.16.0`.
- Operator APIs are named in the DSL because Swift does not allow expressions such as `mock.given.==(...)`.

## 0.15.0 - 2026-07-03

### Added

- Support for qualified and complex protocol inheritance syntax on annotated protocols.
- Macro expansion coverage for inherited types such as `Foundation.Sendable`.
- Integration coverage proving generated mocks compile for protocols inheriting `Swift.Sendable`.

### Changed

- MockSyn no longer rejects protocol inheritance clauses that contain qualified inherited types.
- Documentation and support matrix now describe complex protocol inheritance syntax as supported.

### Notes

- SwiftPM package versioning is provided by the Git tag `0.15.0`.
- Generated doubles still conform to the annotated protocol itself; inherited requirements must be visible through normal Swift protocol conformance.

## 0.14.0 - 2026-07-03

### Added

- Static protocol member stubbing and verification through type-level `given`, `when`, and `verify` APIs.
- Generated static runtime state per double type for static properties and methods.
- Generated `resetStatic`, `confirmStaticVerified`, and `checkUnnecessaryStaticStubs` helpers.
- Macro expansion and integration tests covering static property get/set stubbing, static method stubbing, and static verification.

### Changed

- Static protocol members now resolve through MockSyn runtime instead of placeholder `fatalError` or empty bodies.
- Documentation and support matrix now describe static member stubbing and verification as supported.

### Notes

- SwiftPM package versioning is provided by the Git tag `0.14.0`.
- Static APIs are configured on the generated type, for example `UserServiceMock.given.make().willReturn(value)`.

## 0.13.0 - 2026-07-03

### Added

- Associated-type protocol support for generated mocks, stubs, and spies.
- Generated generic parameters for protocol `associatedtype` requirements.
- Preservation of associated-type inheritance constraints and `where` requirements.
- Type-safe spy wrapping for associated-type protocols through a generated wrapped implementation generic.
- Macro expansion and integration tests covering associated-type stubbing, verification, and spy delegation.

### Changed

- Associated-type protocols are no longer diagnosed as unsupported when their bindings can be represented as generated generic parameters.
- Documentation and support matrix now describe associated-type generic binding as supported.

### Notes

- SwiftPM package versioning is provided by the Git tag `0.13.0`.
- Associated types with constraints are supported in the macro-only flow without source generation or build plugins.

## 0.12.0 - 2026-07-03

### Added

- Optional `tools/mocksyn-inspect.sh` CLI for local support-matrix, macro expansion, benchmark, and DocC commands.
- `tools/export-macro-expansion.sh` helper for compiler macro expansion inspection.
- `tools/benchmark.sh` helper with the MockSyn benchmark plan and optional run command.
- DocC catalog for the `MockSyn` target.
- Migration guides for Mockable, Cuckoo, and SwiftyMocky.
- Documentation for the optional tooling feature block.

### Notes

- SwiftPM package versioning is provided by the Git tag `0.12.0`.
- Optional tools are scripts, not SwiftPM plugins, and do not run during consumer builds.

## 0.11.0 - 2026-07-03

### Added

- Compile-time diagnostic for invalid `mode` macro options.
- Compile-time diagnostic for complex protocol inheritance that MockSyn cannot expand reliably.
- Fix-it suggestion for pure Swift `final` classes.
- Diagnostics feature documentation and support-matrix updates.

### Notes

- SwiftPM package versioning is provided by the Git tag `0.11.0`.
- The final-class fix-it only removes `final`; protocol extraction remains the recommended design for production types that should stay final.

## 0.10.0 - 2026-07-03

### Added

- XCTest-style failure adapter through `MockSynFailureReporter.useXCTest`.
- Swift Testing-style failure adapter through `MockSynFailureReporter.useSwiftTesting`.
- File/line forwarding on verification count APIs and order verification.
- Detailed reporter messages for verification failures with recorded calls.
- Runtime failure reports with message, file, and line.
- Documentation for the test integration feature block.

### Notes

- SwiftPM package versioning is provided by the Git tag `0.10.0`.
- Direct framework imports for XCTest/Swift Testing remain intentionally outside the runtime target to keep production targets lightweight.

## 0.9.0 - 2026-07-03

### Added

- Public `MockSynResetScope` with `.invocations`, `.stubs`, and `.all`.
- `MockSynRuntime.reset(_:)` for clearing calls, stubs, or both.
- Generated `reset(_:)` API on mocks, stubs, and spies that have generated member DSLs.
- `mockSynReset(_:)` for hand-written fakes adopting `MockSynFake`.
- `MockSynFailure` and `MockSynFailureReporter` as the runtime failure reporting channel.
- Failure reporting integration for missing stubs, verification count failures, unverified calls, unnecessary stubs, and order failures.
- Documentation for the runtime internals feature block.

### Notes

- SwiftPM package versioning is provided by the Git tag `0.9.0`.
- XCTest and Swift Testing adapters are still planned for the test integration block.

## 0.8.0 - 2026-07-03

### Added

- Explicit test double mode documentation for strict mocks, relaxed mocks, stubs, spies, partial spies, and hand-written fakes.
- `MockSynDoubleKind.fake` for manual fakes that reuse MockSyn runtime state.
- `MockSynFake` helper protocol with recording, verification, `confirmVerified`, and unnecessary-stub checks for hand-written fakes.
- Integration tests proving generated mocks, stubs, and spies can override mode per instance.

### Changed

- Strict stubs now respect `mode: .strict` for non-void unstubbed calls instead of always returning relaxed defaults because the double kind is `.stub`.

### Notes

- SwiftPM package versioning is provided by the Git tag `0.8.0`.
- Testing-framework failure adapters, static member stubbing/verification, and associated-type binding remain planned for later blocks.

## 0.7.0 - 2026-07-03

### Added

- Optional matchers with `.nil` and `.notNil`.
- Collection matchers for empty collections, arrays, sets, and dictionaries.
- Matcher composition with `.not`, `.all`, and `.anyOf`.
- `MockSynArgumentCaptor` for capturing matched arguments during stubbing or verification.
- `MockSynClosureCaptor` alias for capturing closure arguments and invoking them in tests.
- Generated mock integration tests proving captors work through macro-generated `given` and `verify` APIs.
- Documentation for the matchers and captors feature block.

### Notes

- SwiftPM package versioning is provided by the Git tag `0.7.0`.
- Testing-framework failure adapters, static member stubbing/verification, and associated-type binding remain planned for later blocks.

## 0.6.0 - 2026-07-03

### Added

- Runtime invocation store for generated mocks, stubs, and spies.
- Generated `verify` APIs for instance methods, properties, and subscripts.
- Verification counts: `.once`, `.never`, `.times`, `.atLeast`, and `.atMost`.
- Argument-specific verification using existing typed matchers.
- `confirmVerified()` to detect unverified recorded calls.
- `checkUnnecessaryStubs()` to detect configured stubs that were never used.
- Cross-mock order verification with `MockSynVerifier.verifyOrder`.
- Timeout verification with async `wasCalled(_:timeout:)`.
- Explicit recording for spy methods with `inout` parameters before delegation.
- Documentation for the verification feature block.

### Notes

- SwiftPM package versioning is provided by the Git tag `0.6.0`.
- Testing-framework failure adapters remain planned for later blocks.

## 0.5.0 - 2026-07-02

### Added

- Runtime stub registry shared by generated mocks, stubs, and spies.
- Generated `given` and `when` APIs for instance methods, properties, and subscripts.
- `willReturn`, `willThrow`, and `willRun` stubbing builders.
- Sequential return values with last-value reuse after the configured sequence is exhausted.
- Argument-specific stubs using `.any`, `.value`, and `.matching` typed matchers.
- Property getter and setter stubbing.
- Subscript getter and setter stubbing, including labeled and underscored subscripts.
- Partial spy behavior where matching stubs override wrapped implementation delegation.
- Relaxed default value resolution for stubs and relaxed mocks.
- `MockSynDefaultValueRegistry` for custom domain defaults.
- Documentation for the stubbing feature block and updated support/limitations docs.

### Notes

- SwiftPM package versioning is provided by the Git tag `0.5.0`.
- Static member stubbing, verification, captors, and invocation order assertions remain planned for later blocks.

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
