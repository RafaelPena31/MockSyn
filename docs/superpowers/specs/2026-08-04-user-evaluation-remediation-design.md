# User Evaluation Remediation Design

## Context

MockSyn 0.30.0 was evaluated from a real consumer package using Swift 6.4,
separate modules, Quick/Nimble, and process-isolated crash probes. The report
identified nine behavioral or documentation gaps. Independent inspection of
the repository reproduced the Swift 6 failure and confirmed the runtime and
macro causes described for the other findings.

## Goals

- Keep a missing non-throwing stub from terminating the test process whenever
  MockSyn can produce a valid recovery value.
- Make unsupported inherited requirements fail with an actionable macro
  diagnostic instead of an opaque generated-conformance error.
- Compile cleanly in Swift 5 language mode and Swift 6 language mode.
- Make directly declared `ObservableObject` doubles notify observers when test
  property state changes.
- Improve verification diagnostics, global cleanup, `willRun` arity, and
  generated access defaults.
- Prove behavior from a separate consumer package as well as the package's
  internal test targets.
- Keep the macro-only integration model. No SwiftPM build-tool plugin or source
  generation step will be introduced.

## Non-Goals

- Runtime interception of pure Swift final classes, global functions, or
  arbitrary constructors.
- Semantic discovery of declarations from another file, module, XCFramework,
  Objective-C header, or KMP binary.
- Automatic generation of requirements from an unannotated inherited
  protocol. Swift peer macros receive syntax, not a compiler symbol-resolution
  API.
- A production dependency on Quick or Nimble. They belong only to the nested
  consumer fixture.

## Runtime Resolution

Throwing and non-throwing resolution will no longer share a `try!` bridge.
The non-throwing path will record the invocation, resolve a matching stub, use
a spy fallback when present, and then inspect the default-value registry.

For strict doubles, using a default after a missing stub still reports a test
failure through `MockSynFailureReporter`. The default only allows the process
to continue. Relaxed doubles return the same default without reporting. If no
valid value exists, MockSyn reports the failure and terminates with a message
that names the return type and explains `willReturn` and
`MockSynDefaultValueRegistry.register`.

Generated APIs for non-throwing members will return non-throwing stub builders
that do not expose `willThrow`. Throwing members retain builders with
`willThrow`. `rethrows` members continue to expose only non-throwing behavior.
The `try!` in the rethrowing resolution path will be removed by using a
non-throwing stub-behavior path.

## Protocol Inheritance

MockSyn cannot inspect the declaration represented by an inherited type name.
It will therefore emit a warning on inherited protocols whose conformance is
not known to be satisfied without generated members. The diagnostic will state
that only requirements declared in the annotated body are generated and will
recommend redeclaring requirements or introducing a local mirror protocol.

Known marker or default-satisfied protocols such as `AnyObject`, `Sendable`,
and directly visible `ObservableObject` will not produce the generic warning.
Compiler conformance checking remains authoritative. Supporting fully
cooperative annotated hierarchies is deferred because it requires a separate
public DSL and generated-support-artifact design; the current correction must
not silently invent that API.

## ObservableObject

When the annotated protocol directly inherits `ObservableObject`, generated
doubles will own a `MockSynObservableObjectPublisher`. The runtime target will
provide this public Combine-backed alias conditionally when Combine is
available, so generated code does not require a new import in consumer files.

The generated runtime receives a change callback. Configuring a property getter
stub and invoking a generated property setter will call that callback. Ordinary
method stubs and property reads will not emit. Direct inheritance is required;
transitive inheritance cannot be discovered by a syntax-only macro and will be
documented.

## Verification Diagnostics

`MockSynVerificationError.expected` will carry recorded-call descriptions.
Its textual representation and the failure reporter will use the same details,
including rendered argument values. Existing construction without recorded
calls remains supported through a default associated value.

## Global State

Generated type-level runtimes will register weakly in a locked process-wide
registry. Instance runtimes will not pay this registration cost.
`MockSynRuntime.resetAllGlobalState()` will reset registered static runtimes,
custom defaults, the failure reporter, and the invocation clock. The API is
intended for suite boundaries and sequential teardown. Documentation will
explicitly warn that process-wide reset is incompatible with concurrently
executing tests that are still using MockSyn state.

## Stub Arity

Throwing, non-throwing, and rethrowing typed builders will support zero through
six arguments. Generated functions select the matching builder by arity. A
function with more than six parameters remains usable with `willReturn`, but
the macro will emit an actionable diagnostic when a typed `willRun` builder
cannot be generated instead of silently selecting the zero-argument builder.

## Access Control

`MockSynAccess` will gain `.inherited`, which becomes the default for all three
macros. The generated declaration adopts the annotated declaration's effective
access. Explicit `.private`, `.fileprivate`, `.internal`, `.package`, and
`.public` values continue to override the default and remain subject to the
existing no-wider-than-source validation.

## Swift Compatibility And Dependency Policy

Lock-protected mutable static state will use conditional
`nonisolated(unsafe)` declarations when the compiler supports them.
Public error/count types used across concurrency boundaries will conform to
`Sendable`. The manifest will declare Swift 5 and Swift 6 language support, and
CI will exercise both modes.

SwiftSyntax 604 has no stable tag at design time. The Swift 6.4 branch will pin
the exact compatible prerelease instead of accepting a moving range. The
support documentation will identify the beta-toolchain exception and require a
move to stable 604 when it becomes available.

## External And KMP Types

The limitations and integration guides will include a complete mirror-protocol
pattern. A local annotated protocol repeats the external requirements, and the
generated double adopts the external protocol in an empty extension. The guide
will explain why this works, how signature drift becomes a compile error, and
why macros cannot annotate declarations inside compiled dependencies.

## Test Strategy

Each behavior change starts with a failing focused XCTest or macro-expansion
test. Runtime tests cover safe strict recovery, unrecoverable diagnostics,
throwing-builder availability, detailed verification failures, global reset,
and all builder arities. Macro tests cover inheritance warnings,
`ObservableObject`, access inheritance, throwing/non-throwing builder selection,
and arity diagnostics.

A nested SwiftPM consumer fixture will validate public visibility, separate
module boundaries, external mirrored protocols, Quick/Nimble reporting, and
the Swift 5/6 build modes. Final validation includes the full suite with code
coverage, source coverage reporting, documentation validation, `git diff
--check`, file-size checks, and the existing performance benchmark.

## Release

The changes will ship as 0.31.0 because they add public API and intentionally
change default generated visibility. The changelog and migration notes will
call out `.inherited`, richer verification errors, strict non-throwing recovery,
and the limits of protocol inheritance.
