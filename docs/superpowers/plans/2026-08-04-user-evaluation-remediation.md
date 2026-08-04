# User Evaluation Remediation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Correct the nine findings from the MockSyn 0.30.0 consumer evaluation and prevent them from recurring in internal and external-package tests.

**Architecture:** Keep macro expansion syntax-only and move recoverable behavior into focused runtime APIs. Generated code selects capability-specific builders, directly visible protocol traits, and inherited access; unsupported semantic inheritance receives diagnostics. A nested consumer package validates the public integration boundary independently from implementation tests.

**Tech Stack:** Swift 5.9/6, SwiftPM, SwiftSyntax macros, XCTest, Combine, Quick/Nimble, GitHub Actions, llvm-cov.

---

### Task 1: Safe Non-Throwing Resolution

**Files:**
- Modify: `Sources/MockSyn/Runtime/MockSynRuntime.swift`
- Modify: `Sources/MockSyn/Runtime/MockSynStubBehavior.swift`
- Modify: `Sources/MockSyn/Runtime/MockSynStubRule.swift`
- Modify: `Tests/MockSynTests/MockSynRuntimeResolutionTests.swift`
- Modify: `Tests/MockSynTests/MockSynFailureReporterTests.swift`

- [ ] **Step 1: Replace the crash expectation with failing recovery tests**

Add tests that install a failure handler, resolve an unstubbed strict `String`,
`Int`, optional, and registered domain value, assert the returned default, and
assert one reported failure containing the member and received arguments. Keep
a subprocess test for a domain type without a registered default and assert its
stderr explains both `willReturn` and `MockSynDefaultValueRegistry.register`.

- [ ] **Step 2: Run the focused tests and verify RED**

Run: `swift test --filter MockSynPublicAPITests/testStrictUnstubbed`

Expected: the existing subprocess crash assertion or new recovery assertions
fail because `resolve` still calls `try! resolveThrowing`.

- [ ] **Step 3: Add a non-throwing behavior path**

Represent non-throwing return/run behaviors separately in
`MockSynStubBehavior`, expose `resolveNonThrowing(_:)` through
`MockSynStubRule`, and make `MockSynRuntime.resolve` perform this exact order:
record, matching behavior, fallback, default lookup, strict failure report,
safe default return, and finally an actionable `fatalError` when no value can
exist. Keep `resolveThrowing` throwing `MockSynRuntimeError.missingStub` and
make `resolveRethrowing` use only the non-throwing behavior path.

- [ ] **Step 4: Run focused and full runtime tests and verify GREEN**

Run: `swift test --filter MockSynPublicAPITests`

Expected: all runtime tests pass and safe strict defaults do not terminate the
test process.

- [ ] **Step 5: Commit the runtime correction**

```bash
git add Sources/MockSyn/Runtime Tests/MockSynTests
git commit -m "fix: recover from missing nonthrowing stubs"
```

### Task 2: Capability-Safe Builders And Arity

**Files:**
- Create: `Sources/MockSyn/Runtime/MockSynNonThrowingStubBuilder.swift`
- Create: `Sources/MockSyn/Runtime/MockSynHigherArityStubBuilder.swift`
- Create: `Sources/MockSyn/Runtime/MockSynHigherArityRethrowingStubBuilder.swift`
- Modify: `Sources/MockSyn/Runtime/MockSynStubBuilder.swift`
- Modify: `Sources/MockSynMacros/GeneratedFunction.swift`
- Modify: `Sources/MockSynMacros/GeneratedProperty.swift`
- Modify: `Sources/MockSynMacros/GeneratedSubscript.swift`
- Modify: `Sources/MockSynMacros/MemberGenerator.swift`
- Modify: `Sources/MockSynMacros/MockSynDiagnostics.swift`
- Create: `Tests/MockSynTests/MockSynHigherArityStubBuilderTests.swift`
- Create: `Tests/MockSynMacroTests/MacroStubBuilderCapabilityTests.swift`

- [ ] **Step 1: Add failing builder and expansion tests**

Add runtime tests for `willRun` with three, four, five, and six typed arguments
for normal and `rethrows` builders. Add macro tests asserting non-throwing
members use `MockSynNonThrowingStubBuilderN`, throwing members use
`MockSynStubBuilderN`, and `rethrows` members use
`MockSynRethrowingStubBuilderN`. Assert non-throwing builders have no
`willThrow` by compiling them through the generated integration fixture.

- [ ] **Step 2: Run focused tests and verify RED**

Run: `swift test --filter HigherArity`

Expected: compilation fails because builders three through six do not exist.

- [ ] **Step 3: Implement builders zero through six**

Keep throwing, non-throwing, and rethrowing builder families in separate files.
Each typed `willRun` casts exactly the declared argument positions. Add
return-only builders for methods above six arguments so `willReturn` and, for
throwing members, `willThrow` remain available without a misleading zero-arity
closure.

- [ ] **Step 4: Select builders from generated effects and arity**

Update function, property, and subscript generation to choose a builder family
from `throws`/`rethrows`/non-throwing effects and select suffixes `1...6` from
the parameter count. Emit a warning on declarations above six parameters that
typed `willRun` is unavailable while return/throw behavior remains supported.

- [ ] **Step 5: Run macro and runtime suites and verify GREEN**

Run: `swift test --filter MockSynMacroTests`

Run: `swift test --filter MockSynPublicAPITests`

Expected: both suites pass and generated non-throwing APIs cannot configure a
throwing behavior.

- [ ] **Step 6: Commit builder support**

```bash
git add Sources/MockSyn Sources/MockSynMacros Tests/MockSynTests Tests/MockSynMacroTests
git commit -m "feat: add capability-safe stub builders"
```

### Task 3: Actionable Protocol Inheritance

**Files:**
- Modify: `Sources/MockSynMacros/MockSynDiagnostics.swift`
- Modify: `Sources/MockSynMacros/MockSynPeerMacro.swift`
- Modify: `Sources/MockSynMacros/MockSynSyntaxExtensions.swift`
- Modify: `Tests/MockSynMacroTests/MacroDiagnosticTests.swift`
- Modify: `Tests/MockSynTests/MockSynGeneratedTypeIntegrationTests.swift`

- [ ] **Step 1: Add failing inheritance diagnostic tests**

Add macro tests for a custom parent protocol with requirements and assert a
warning stating that inherited requirements are not generated. Add no-warning
tests for `AnyObject`, `Sendable`, `Swift.Sendable`, and directly visible
`ObservableObject`. Keep an integration fixture proving redeclared inherited
requirements compile and can be stubbed.

- [ ] **Step 2: Run diagnostics and verify RED**

Run: `swift test --filter MacroDiagnosticTests`

Expected: the custom inherited protocol expands without the required warning.

- [ ] **Step 3: Implement syntax-only classification**

Inspect each inherited type's terminal identifier. Suppress the warning only
for the documented marker/default-satisfied allowlist. Diagnose all other
inherited protocol names at the attribute without trying to resolve their
declarations. The warning must recommend redeclaration or a local mirror.

- [ ] **Step 4: Run macro and generated integration tests and verify GREEN**

Run: `swift test --filter MockSynMacroTests`

Run: `swift test --filter GeneratedType`

Expected: diagnostics are actionable and known marker inheritance remains
source-compatible.

- [ ] **Step 5: Commit inheritance diagnostics**

```bash
git add Sources/MockSynMacros Tests/MockSynMacroTests Tests/MockSynTests
git commit -m "fix: diagnose inherited protocol requirements"
```

### Task 4: ObservableObject Notifications

**Files:**
- Create: `Sources/MockSyn/Runtime/MockSynObservableObjectPublisher.swift`
- Modify: `Sources/MockSyn/Runtime/MockSynRuntime.swift`
- Modify: `Sources/MockSyn/Runtime/MockSynStubBuilder.swift`
- Modify: `Sources/MockSynMacros/MockSynMacroTarget.swift`
- Modify: `Sources/MockSynMacros/MockSynPeerMacro.swift`
- Modify: `Sources/MockSynMacros/GeneratedProperty.swift`
- Create: `Tests/MockSynTests/GeneratedObservableObjectIntegrationTests.swift`
- Create: `Tests/MockSynMacroTests/MacroObservableObjectGenerationTests.swift`

- [ ] **Step 1: Add failing Combine integration tests**

Under `#if canImport(Combine)`, annotate a directly inheriting
`ObservableObject` protocol. Assert one emission when a getter stub is
configured, one emission when a generated setter is called, and no emission
for a property read or ordinary method stub. Add expansion coverage for the
publisher property and initializer callback.

- [ ] **Step 2: Run focused tests and verify RED**

Run: `swift test --filter ObservableObject`

Expected: emission counts remain zero and expansion lacks an owned publisher.

- [ ] **Step 3: Implement the publisher and generated wiring**

Create a Combine-backed `MockSynObservableObjectPublisher` conforming to
`Publisher` with `Output == Void` and `Failure == Never`. Give
`MockSynRuntime` an optional locked change callback. Property getter builders
request notification on registration, and generated setters notify before
recording. Direct `ObservableObject` targets initialize and expose the
publisher with the target's resolved access.

- [ ] **Step 4: Run focused and full tests and verify GREEN**

Run: `swift test --filter ObservableObject`

Run: `swift test`

Expected: exact emission counts pass without changing non-observable doubles.

- [ ] **Step 5: Commit observable support**

```bash
git add Sources/MockSyn Sources/MockSynMacros Tests/MockSynTests Tests/MockSynMacroTests
git commit -m "feat: notify observable test doubles"
```

### Task 5: Rich Verification Errors And Global Reset

**Files:**
- Create: `Sources/MockSyn/Runtime/MockSynGlobalRuntimeRegistry.swift`
- Modify: `Sources/MockSyn/Runtime/MockSynRuntime.swift`
- Modify: `Sources/MockSyn/Runtime/MockSynVerification.swift`
- Modify: `Sources/MockSyn/Runtime/MockSynDefaultValueRegistry.swift`
- Modify: `Sources/MockSyn/Runtime/MockSynFailureReporter.swift`
- Modify: `Sources/MockSyn/Runtime/MockSynInvocation.swift`
- Modify: `Sources/MockSynMacros/MockSynMacroTarget.swift`
- Modify: `Tests/MockSynTests/MockSynRuntimeVerificationTests.swift`
- Create: `Tests/MockSynTests/MockSynGlobalStateTests.swift`

- [ ] **Step 1: Add failing diagnostic and reset tests**

Verify that a mismatched argument error includes the received rendered value.
Create two generated types with static members, configure both plus a custom
default and failure handler, call `MockSynRuntime.resetAllGlobalState()`, and
assert static stubs, defaults, reporter, and invocation ordering are reset.

- [ ] **Step 2: Run focused tests and verify RED**

Run: `swift test --filter MockSynGlobalStateTests`

Run: `swift test --filter testRuntimeVerificationSupportsAtLeast`

Expected: reset API is missing and thrown verification text lacks recorded
calls.

- [ ] **Step 3: Implement detailed errors**

Add `recordedCalls: [String] = []` to the expected verification error and append
them to `description`. Build one recorded-call snapshot in `verify` and pass the
same data to the thrown error and failure reporter.

- [ ] **Step 4: Implement registered static runtime cleanup**

Add a locked weak registry and a `MockSynRuntime.global(kind:mode:)` factory.
Generated static runtimes use that factory. The public reset entrypoint resets
registered runtimes, default values, reporter, and the invocation clock without
holding the registry lock while calling individual runtimes.

- [ ] **Step 5: Run focused and full tests and verify GREEN**

Run: `swift test --filter MockSynGlobalStateTests`

Run: `swift test`

Expected: one cleanup call restores all process-wide MockSyn state and errors
include received calls.

- [ ] **Step 6: Commit diagnostics and cleanup**

```bash
git add Sources/MockSyn Sources/MockSynMacros Tests/MockSynTests
git commit -m "feat: improve verification and global cleanup"
```

### Task 6: Inherited Access And Swift 6 Compatibility

**Files:**
- Modify: `Sources/MockSyn/Configuration/MockSynAccess.swift`
- Modify: `Sources/MockSyn/MockSyn.swift`
- Modify: `Sources/MockSynMacros/MockSynMacroOptions.swift`
- Modify: `Sources/MockSynMacros/MockSynPeerMacro.swift`
- Modify: `Sources/MockSyn/Runtime/MockSynDefaultValueRegistry.swift`
- Modify: `Sources/MockSyn/Runtime/MockSynFailureReporter.swift`
- Modify: `Sources/MockSyn/Runtime/MockSynInvocation.swift`
- Modify: `Sources/MockSyn/Runtime/MockSynVerification.swift`
- Modify: `Package.swift`
- Modify: `Tests/MockSynMacroTests/MacroPluginConfigurationTests.swift`
- Modify: `Tests/MockSynTests/MockSynPublicAPITests.swift`

- [ ] **Step 1: Add failing inherited-access tests**

Assert omitted access generates `public`, `package`, `internal`, and
`fileprivate` doubles matching the source declaration. Assert explicit
`.internal` still narrows a public protocol and `.public` still fails for an
internal protocol.

- [ ] **Step 2: Run access tests and verify RED**

Run: `swift test --filter MacroPluginConfigurationTests`

Expected: omitted access remains `internal` for public declarations.

- [ ] **Step 3: Implement `.inherited`**

Add the public enum case, make it the macro declaration default, parse it as the
target's effective access, and keep the existing rank validation for explicit
values.

- [ ] **Step 4: Add Swift 6 annotations and manifest support**

Use compiler-conditional `nonisolated(unsafe)` declarations for each
lock-protected mutable static. Add `Sendable` to verification count/error types,
declare Swift 5 and Swift 6 language versions, and pin SwiftSyntax 604 to the
exact available prerelease on compiler 6.4.

- [ ] **Step 5: Verify both language modes**

Run: `swift test -Xswiftc -swift-version -Xswiftc 5`

Run: `swift test -Xswiftc -swift-version -Xswiftc 6`

Expected: both commands pass without MockSyn concurrency warnings.

- [ ] **Step 6: Commit compatibility changes**

```bash
git add Package.swift Sources Tests
git commit -m "feat: inherit access and support Swift 6"
```

### Task 7: External Consumer And CI Proof

**Files:**
- Create: `IntegrationTests/ConsumerPackage/Package.swift`
- Create: `IntegrationTests/ConsumerPackage/Sources/ExternalContracts/ExternalContracts.swift`
- Create: `IntegrationTests/ConsumerPackage/Sources/ConsumerCore/ConsumerCore.swift`
- Create: `IntegrationTests/ConsumerPackage/Tests/ConsumerCoreTests/MockSynConsumerTests.swift`
- Create: `IntegrationTests/ConsumerPackage/Tests/ConsumerCoreTests/MockSynQuickSpec.swift`
- Create: `tools/test-consumer-package.sh`
- Create: `.github/workflows/ci.yml`

- [ ] **Step 1: Create the external consumer fixture**

The nested package depends on MockSyn by local path and Quick/Nimble only in its
test target. Put an external protocol in `ExternalContracts`, a mirrored local
protocol in `ConsumerCore`, and tests for public generated visibility, strict
safe recovery, rich errors, reset, mirror conformance, and Quick failure
reporting.

- [ ] **Step 2: Run the consumer fixture as a black-box regression check**

Run: `tools/test-consumer-package.sh`

Expected: public visibility, safe strict recovery, rich diagnostics, mirrored
external conformance, and Quick integration pass through only public APIs.

- [ ] **Step 3: Add repeatable consumer and CI commands**

The shell wrapper runs the nested package in Swift 5 and Swift 6 language modes.
CI runs root tests, macro tests, consumer tests, documentation validation, and
coverage. A Swift 5.9 toolchain job and a stable Swift 6 job validate compiler
compatibility; macOS runs Combine-specific integration.

- [ ] **Step 4: Run the fixture and workflow-equivalent commands**

Run: `tools/test-consumer-package.sh`

Run: `tools/mocksyn-inspect.sh docc --validate`

Expected: all consumer and documentation checks pass.

- [ ] **Step 5: Commit external proof**

```bash
git add IntegrationTests tools/test-consumer-package.sh .github/workflows/ci.yml
git commit -m "test: add external consumer compatibility suite"
```

### Task 8: Documentation And Migration

**Files:**
- Modify: `README.md`
- Modify: `CHANGELOG.md`
- Modify: `docs/SUPPORT_MATRIX.md`
- Modify: `docs/LIMITATIONS.md`
- Modify: `docs/INTEGRATION.md`
- Modify: `docs/ERRORS.md`
- Modify: `docs/TESTING_STRATEGY.md`
- Modify: `docs/features/macros.md`
- Modify: `docs/features/stubbing.md`
- Modify: `docs/features/supported-types.md`
- Modify: `docs/features/test-double-modes.md`
- Modify: `docs/features/test-integration.md`
- Modify: `docs/features/verification.md`
- Modify: `docs/features/runtime-internals.md`
- Modify: `Sources/MockSyn/MockSyn.docc/MockSyn.md`
- Modify: public API docstrings in changed Swift files

- [ ] **Step 1: Correct every overstated support claim**

State that inherited syntax is accepted but inherited requirements are not
semantically discovered. Document the warning, redeclaration workaround,
direct-only `ObservableObject` support, safe strict recovery, and unavoidable
fatal behavior for types without defaults.

- [ ] **Step 2: Document external/KMP mirroring and cleanup**

Add a complete mirror-protocol example with an external conformance extension,
explain compile-time drift detection, and provide XCTest, Swift Testing, and
Quick teardown examples using `resetAllGlobalState()` with the parallel-test
warning.

- [ ] **Step 3: Document API changes and SwiftSyntax policy**

Explain `.inherited`, explicit narrowing, builder arity six, rich errors, Swift
5.9/6 validation, and the exact 604 prerelease required only for Swift 6.4 beta
until a stable tag exists.

- [ ] **Step 4: Validate documentation and links**

Run: `tools/mocksyn-inspect.sh docc --validate`

Run: `rg -n "Complex protocol inheritance.*Supported|zero, one, and two|access: MockSynAccess = \.internal" README.md docs Sources`

Expected: validation passes and no stale support wording remains.

- [ ] **Step 5: Commit documentation**

```bash
git add README.md CHANGELOG.md docs Sources/MockSyn
git commit -m "docs: document evaluation remediation behavior"
```

### Task 9: Final Quality, Performance, And Release 0.31.0

**Files:**
- Modify: `README.md`
- Modify: `docs/INTEGRATION.md`
- Modify: `Tests/MockSynTests/MockSynToolingTests.swift`
- Modify: `CHANGELOG.md`

- [ ] **Step 1: Run the complete coverage suite**

Run: `swift test --enable-code-coverage`

Run: `xcrun llvm-cov report .build/out/Products/Debug/MockSynTests.xctest/Contents/MacOS/MockSynTests .build/out/Products/Debug/MockSynMacroTests.xctest/Contents/MacOS/MockSynMacroTests .build/out/Products/Debug/MockSynPerformanceTests.xctest/Contents/MacOS/MockSynPerformanceTests -instr-profile .build/out/Products/Debug/codecov/default.profdata -ignore-filename-regex='.build|Tests|checkouts|DerivedSources|/Applications/' Sources/MockSyn Sources/MockSynMacros`

Expected: all tests pass and changed production code has 100% line, function,
and region coverage.

- [ ] **Step 2: Run performance and repository checks**

Run: `tools/benchmark.sh --run`

Run: `find Sources Tests -name '*.swift' -print0 | xargs -0 wc -l | awk '$2 != "total" && $1 > 500 { print }'`

Run: `git diff --check 0.30.0..HEAD`

Expected: benchmark completes without material regression, no Swift file is
over 500 lines, and the diff has no whitespace errors.

- [ ] **Step 3: Perform spec and code-quality review**

Compare every F1-F9 acceptance criterion against implementation and tests,
then review the complete `0.30.0..HEAD` diff for regressions, source
compatibility, concurrency, diagnostics, documentation, and performance.

- [ ] **Step 4: Set release version 0.31.0**

Update installation examples and tooling assertions to 0.31.0. Add the final
dated changelog entry covering fixes, additions, behavior changes, and known
macro limitations.

- [ ] **Step 5: Commit, tag, push, and publish**

```bash
git add README.md CHANGELOG.md docs/INTEGRATION.md Tests/MockSynTests/MockSynToolingTests.swift
git commit -m "chore: release 0.31.0"
git switch main
git merge --ff-only codex/fix-user-evaluation
git push origin main
git tag -a 0.31.0 -m "Release 0.31.0"
git push origin 0.31.0
```

Create the GitHub release from the 0.31.0 changelog and verify the remote tag,
release URL, and clean branch state.
