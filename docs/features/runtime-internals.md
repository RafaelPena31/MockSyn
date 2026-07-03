# Runtime Internals

Block 9 exposes the runtime pieces that tests and later adapters need without
turning MockSyn into a source generator or plugin-based framework.

## What It Does

| Feature | Status | Notes |
| --- | --- | --- |
| Call store | Supported | `MockSynRuntime` records invocations for generated doubles and manual fakes. |
| Stub registry | Supported | Stub builders register matcher/behavior rules per member. |
| Invocation model | Supported | Runtime stores member name, boxed arguments, verification state, and global call order. |
| Argument boxing | Supported | Arguments are stored as `[Any]`, matched through type-erased `MockSynAnyMatcher`, and rendered through the diagnostic argument renderer. |
| Thread safety | Supported | Runtime state is protected by `NSRecursiveLock`. |
| Reset | Supported | Clear invocations, stubs, or both with `MockSynResetScope`. |
| Failure reporter | Supported | Runtime failures are sent through `MockSynFailureReporter` before being thrown. |

## Runtime State

Every generated double owns a runtime:

```swift
let service = UserServiceMock()

service.__mockSyn.kind // .mock
service.__mockSyn.mode // .strict
```

Generated code uses the runtime to record calls, resolve stubs, verify
interactions, check unused stubs, and reset state.

## Reset

Generated doubles expose `reset(_:)` when they have generated stubbing or
verification APIs.

```swift
service.given.name(id: .any).willReturn("Rafael")

_ = service.name(id: "42")

service.reset(.invocations) // keeps stubs
service.reset(.stubs)       // keeps invocations
service.reset()             // clears both
```

Manual fakes that adopt `MockSynFake` use the prefixed helper:

```swift
fake.mockSynReset(.invocations)
```

## Failure Reporter

`MockSynFailureReporter` is a process-wide reporting channel. The default handler
is no-op. Runtime failure paths report before throwing.

```swift
MockSynFailureReporter.setHandler { failure in
    print(failure.message)
}

defer { MockSynFailureReporter.reset() }
```

Reported failures currently include missing stubs, verification count failures,
unverified invocations, unnecessary stubs, and order verification failures.

Testing-framework-specific adapters are handled by the test integration block.
This block only creates the shared runtime channel that those adapters can use.

## Thread Safety

`MockSynRuntime`, captors, the default value registry, and the failure reporter
protect mutable state with locks. This keeps normal concurrent test execution
deterministic without adding work to macro expansion.

## Current Limits

- Public verification APIs forward file/line metadata. Generated non-throwing
  production-style calls still report from the generated runtime path.
- Invocation arguments are boxed as `[Any]`; diagnostic rendering is best-effort
  and does not change matching semantics.
- The global call-order clock is not reset by per-double reset because order can
  span multiple doubles.
