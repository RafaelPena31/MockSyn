# Performance

MockSyn must be designed so that macro expansion, build time, and test runtime overhead stay predictable.

## Build-Time Principles

- Macro expansion must be syntax-only.
- No cross-file scanning.
- No build tool plugin.
- No external process.
- No generated file writing.
- SwiftSyntax stays in `MockSynMacros`, never in the runtime target.
- Generated code is wrapped in `#if MOCKSYN_ENABLE` by default.

## Release Build Impact

If a target contains `@Mocking`, the compiler still loads and expands the macro. MockSyn cannot make that cost zero. The framework promises:

- generated mock/stub/spy declarations are not compiled into Release when `MOCKSYN_ENABLE` is absent;
- generated runtime references are inside the inactive compilation region;
- macro implementation stays small and deterministic;
- performance budgets are measured and enforced.

## Runtime Principles

- Invocation recording must be O(1) amortized per call.
- Stub lookup should be linear only over stubs registered for the same member.
- Verification should avoid scanning unrelated members.
- Lock scope should be minimal.
- Argument boxing should avoid unnecessary allocations where possible.

## Initial Budgets

Budgets are project targets, not guarantees for every consumer codebase.

| Area | Target |
| --- | --- |
| Macro expansion | Under 1 ms per simple member in benchmark fixtures. |
| Generated code size | Linear with protocol member count. |
| Mock call overhead | Small constant overhead over a hand-written mock. |
| Stub lookup | Linear in stubs for the same member, not all stubs. |
| Verify lookup | Linear in calls for the same member, not all calls. |

## Benchmark Fixtures

MockSyn should benchmark:

- protocol with 1 method;
- protocol with 20 methods;
- protocol with async throws methods;
- protocol with properties;
- protocol with generic methods;
- 1,000 calls to a simple mock;
- 1,000 verifications;
- concurrent async invocations.

Print the benchmark plan with:

```bash
tools/benchmark.sh --print-plan
```

Run benchmark tests:

```bash
tools/benchmark.sh --run
```

The command sets `MOCKSYN_RUN_BENCHMARKS=1`, runs
`swift test --filter MockSynPerformance`, and wraps the SwiftPM invocation with
`/usr/bin/time -p` so the output includes real elapsed build/test time. The
`MockSynPerformanceTests` target contains macro-expanded fixtures for simple,
large, async throwing, property, and generic protocols plus measured runtime
recording and verification loops.

Plain `swift test` still compiles the benchmark target as part of package
validation, but the measured bodies skip unless `MOCKSYN_RUN_BENCHMARKS=1` is
present.

## Regression Policy

A change should not be accepted if it creates a significant unexplained increase in:

- macro expansion time;
- generated code size;
- runtime allocation count;
- invocation recording cost;
- verification cost.

Performance regressions require either a fix or an explicit documented tradeoff.
