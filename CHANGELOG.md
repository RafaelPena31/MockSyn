# Changelog

All notable changes to MockSyn are documented in this file.

## 0.26.0 - 2026-07-03

### Added

- Faithful `rethrows` preservation for generated instance protocol methods.
- Faithful `rethrows` preservation for generated static protocol methods.
- `MockSynRethrowingStubBuilder`, `MockSynRethrowingStubBuilder1`, and `MockSynRethrowingStubBuilder2` for generated `rethrows` stubbing APIs.
- Runtime `resolveRethrowing` and `resolveVoidRethrowing` paths so spies can use non-throwing stubs while delegating fallback calls that may rethrow from the passed closure.
- Macro expansion, runtime, and generated integration tests proving mocks, static mocks, and spies compile and execute with `rethrows`.

### Changed

- Generated `rethrows` stubbing APIs intentionally do not expose `willThrow`; Swift only allows `rethrows` implementations to throw through their throwing function parameters.
- Documentation now distinguishes throwing stubs from `rethrows` stubs.

### Notes

- SwiftPM package versioning is provided by the Git tag `0.26.0`.
- Strict missing-stub failures for generated `rethrows` mocks still use the non-throwing resolution path, matching Swift's restriction that a `rethrows` function cannot throw an independent framework error.

## 0.25.0 - 2026-07-03

### Added

- Return-type-only overload disambiguation for generated instance method DSLs.
- Return-type-only overload disambiguation for generated static method DSLs.
- Runtime member keys that include the return type when otherwise identical overload signatures would collide.
- Stable `Overload2`, `Overload3`, etc. DSL suffixes when complex return types sanitize to the same generated method name.
- Macro expansion and integration tests proving separate stubbing and verification for `load() -> String` and `load() -> Int` style requirements.

### Changed

- Overload documentation now calls out return-type-only overloads and the generated `methodReturningType` DSL shape.

### Notes

- SwiftPM package versioning is provided by the Git tag `0.25.0`.
- Non-ambiguous members keep their existing DSL names and runtime keys.

## 0.24.0 - 2026-07-03

### Added

- Explicit constructor seam APIs for zero, one, and two constructor arguments.
- Scoped replacement token for constructor seams, restoring the previous constructor on `restore()` or deinit.
- Runtime tests proving original constructor execution, scoped replacement, idempotent restore, deinit restore, and argument forwarding.

### Changed

- Constructor interception documentation now distinguishes injectable constructor seams from unsupported arbitrary `Type(...)` call-site interception.
- Support matrix now describes constructor seams as supported and arbitrary direct constructor interception as unsupported.

### Notes

- SwiftPM package versioning is provided by the Git tag `0.24.0`.
- MockSyn still cannot rewrite arbitrary constructor call sites. Consumers must inject `MockSynConstructor`, `MockSynConstructor1`, or `MockSynConstructor2` where constructor behavior needs to be replaceable in tests.

## 0.23.0 - 2026-07-03

### Added

- Compile-time diagnostic for applying `@Mocking` to global functions.
- Compile-time diagnostic for concrete `static` methods declared inside annotated classes.
- Compile-time diagnostic for concrete `static` properties declared inside annotated classes.
- Macro expansion tests proving MockSyn does not generate misleading static APIs for concrete class members that Swift cannot intercept.

### Changed

- Static member documentation now distinguishes supported protocol static requirements from unsupported concrete static dispatch.
- Limitation docs now point concrete Objective-C class methods to `MockSynObjCInterception` and pure Swift static/global behavior to protocol extraction.

### Notes

- SwiftPM package versioning is provided by the Git tag `0.23.0`.
- MockSyn still cannot intercept pure Swift global functions or `SomeConcreteType.staticMethod()` calls. Swift macros do not rewrite call sites or install a JVM-style runtime agent.

## 0.22.0 - 2026-07-03

### Added

- Optional Objective-C runtime interception API for replacing instance methods with block implementations.
- Optional Objective-C runtime interception API for replacing class methods with block implementations.
- Scoped restoration token that restores the original Objective-C implementation on `restore()` or deinit.
- Errors for missing Objective-C instance and class methods.
- Runtime tests covering instance method swizzling, class method swizzling, automatic restoration, idempotent restoration, and missing selector errors.

### Changed

- Documentation now distinguishes generated Swift subclass doubles from explicit Objective-C runtime swizzling.
- Support matrix now marks Objective-C runtime interception as supported only through the explicit `MockSynObjCInterception` API when `ObjectiveC.runtime` is available.

### Notes

- SwiftPM package versioning is provided by the Git tag `0.22.0`.
- Objective-C interception is not automatic macro generation and does not make pure Swift methods interceptable. It only applies to selectors visible to the Objective-C runtime.

## 0.21.0 - 2026-07-03

### Added

- Compile-time diagnostics for `final` methods and properties declared inside subclassable classes.
- Fix-it support to remove `final` from unsupported class members when subclass generation is acceptable.
- Macro expansion tests proving MockSyn does not emit invalid overrides for final class members.

### Changed

- Final Swift class support is now documented as a complete macro-only limitation: final types and final members are rejected early with actionable diagnostics instead of relying on later Swift compiler failures.
- Documentation now distinguishes pure Swift `final class` diagnostics from `final` member diagnostics on otherwise subclassable classes.

### Notes

- SwiftPM package versioning is provided by the Git tag `0.21.0`.
- MockSyn still does not mock pure Swift final classes directly. Swift macros cannot make final classes subclassable or intercept their statically dispatched members.

## 0.20.0 - 2026-07-03

### Added

- Class initializer mirroring for generated mocks, stubs, and supported class spies.
- Generated class initializer overloads that forward parameters to the matching `super.init(...)`.
- Per-instance `mode:` overrides on mirrored class mock/stub initializers.
- Support for `required` class initializers on mocks and stubs through an exact required initializer plus a configurable convenience-shaped initializer.
- Compile-time diagnostics for variadic class initializers and required class initializers on spies.
- Macro expansion and integration tests proving parameterized class initializers compile, call the superclass initializer, and preserve runtime mode selection.

### Changed

- Class doubles no longer require an accessible zero-argument initializer when the annotated class declares non-variadic initializers that MockSyn can mirror.
- Documentation and support matrix now describe class initializer mirroring and its remaining Swift language limits.

### Notes

- SwiftPM package versioning is provided by the Git tag `0.20.0`.
- Variadic class initializers remain unsupported because Swift cannot forward captured variadic arrays to `super.init`. Class spies with `required init` remain unsupported because their required exact initializer cannot receive the wrapped instance required by the spy model.

## 0.19.0 - 2026-07-03

### Added

- Spy delegation for synchronous variadic protocol methods with one variadic parameter.
- Generated fallback forwarding for 0 through 8 variadic values, including unlabeled and labeled variadic parameters.
- Macro expansion coverage for return-value variadic spies, `Void` variadic spies, async variadic fallback exclusion, and multiple-variadic fallback exclusion.
- Integration coverage proving variadic spies delegate to the wrapped implementation and still record calls for verification.

### Changed

- Variadic spy methods now use the wrapped implementation as fallback when Swift can represent the forwarded call without array splatting.
- Documentation and support matrix now describe the supported variadic spy delegation shape and remaining Swift language limits.

### Notes

- SwiftPM package versioning is provided by the Git tag `0.19.0`.
- Swift has no general array splat syntax for forwarding arbitrary captured variadic arrays. MockSyn emits finite forwarding cases for one synchronous variadic parameter and leaves async or multiple-variadic signatures stub-driven.

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
