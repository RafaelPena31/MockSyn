# Testing Strategy

MockSyn must test the macro layer, runtime layer, public DSL, documentation examples, and performance characteristics.

## Test Layers

| Layer | Purpose |
| --- | --- |
| Macro expansion tests | Validate generated code for representative inputs. |
| Diagnostic tests | Validate compiler diagnostics for unsupported constructs. |
| Runtime unit tests | Validate invocation recording, stubbing, matching, captors, and reset. |
| DSL tests | Validate user-facing `given` and `verify` behavior. |
| Integration examples | Validate real package usage with XCTest, Swift Testing adapters, Quick, and Nimble. |
| External consumer package | Validate only public APIs across SwiftPM module boundaries and language modes. |
| Concurrency tests | Validate async calls and thread-safe runtime state. |
| Performance tests | Validate build-time and runtime budgets. |

## Macro Expansion Tests

Each supported syntax family needs expansion coverage:

- simple method;
- throwing method;
- async method;
- async throwing method;
- void method;
- get property;
- get-set property;
- overloads;
- generics;
- associated types;
- global actor annotations;
- static protocol requirements;
- subscripts.

## Diagnostic Tests

Diagnostic tests should cover:

- final classes;
- invalid macro target;
- unsupported member;
- invalid access control;
- unsupported inheritance case;
- unsupported generic case.

## Runtime Tests

Runtime tests should cover:

- strict mode missing stub;
- relaxed mode default;
- return value;
- thrown error;
- closure behavior;
- sequential returns;
- argument matching;
- captors;
- verify counts;
- order verification;
- `confirmVerified`;
- `checkUnnecessaryStubs`;
- reset.
- process-wide reset, including static runtimes, defaults, reporter, and order;
- strict non-throwing recovery with and without a producible default;
- typed stub builders through six arguments.

## Documentation Examples

Every public Markdown feature example should be compiled in at least one example target or test fixture.

## CI Matrix

CI should run:

- Swift 5.9 toolchain;
- stable Swift 6 toolchain;
- Release build without `MOCKSYN_ENABLE`;
- test build with `MOCKSYN_ENABLE`;
- macro expansion tests;
- runtime tests;
- documentation example tests.

The Release check must inspect the consumer target's symbols and fail if a
generated mock, stub, or spy is present. The external fixture must keep Quick
examples independent so randomized test order cannot hide leaked global state.

The Swift 5.9 Linux job compiles and executes every portable macro and runtime
test. The Swift 6.3 Linux job compiles and links all source and test targets in
Swift 6 language mode, without launching the XCTest runner: Swift 6.3.1 XCTest
on Linux aborts during generated test discovery while casting `@Sendable` test
methods, before any MockSyn test can execute.

The macOS job executes the complete Swift 6 suite and additionally owns tests
that require Apple tooling: DocC, the inspector's `doctor` command, Combine, and
fatal-error subprocess assertions that launch `xctest` through `xcrun`.
