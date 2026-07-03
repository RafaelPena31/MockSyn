# Tooling

Block 12 defines optional tools for inspecting MockSyn locally. These tools do
not participate in the macro generation path, do not run during consumer builds,
and do not write generated mocks into the project.

## Feature Summary

| Feature | Status | Behavior |
| --- | --- | --- |
| Export de macro expansion | Supported | `tools/export-macro-expansion.sh` runs SwiftPM with macro expansion dumping enabled. |
| CLI de inspecao | Supported as optional shell CLI | `tools/mocksyn-inspect.sh` groups local inspection commands and validates the local inspection environment. |
| DocC | Supported | `Sources/MockSyn/MockSyn.docc` documents the public package surface. |
| Guias de migracao | Supported | Migration guides cover Mockable, Cuckoo, and SwiftyMocky. |
| Benchmarks | Supported as optional local harness | `tools/benchmark.sh --run` enables `MockSynPerformanceTests` with `MOCKSYN_RUN_BENCHMARKS=1` and reports SwiftPM elapsed time. |

## Export de macro expansion

Use this command when you need to inspect compiler-expanded code:

```bash
tools/export-macro-expansion.sh
```

Target a specific package target:

```bash
tools/export-macro-expansion.sh --target AppCore
```

The helper runs:

```bash
swift build -Xswiftc -Xfrontend -Xswiftc -dump-macro-expansions
```

The output is emitted by the compiler. MockSyn still does not create or manage a
generated source folder.

## CLI de inspecao

The optional inspector groups local commands:

```bash
tools/mocksyn-inspect.sh --help
tools/mocksyn-inspect.sh support-matrix
tools/mocksyn-inspect.sh macro-expansion --target AppCore
tools/mocksyn-inspect.sh benchmarks --print-plan
tools/mocksyn-inspect.sh docc
tools/mocksyn-inspect.sh docc --validate
tools/mocksyn-inspect.sh doctor
tools/mocksyn-inspect.sh version
```

It is intentionally a shell CLI instead of a SwiftPM plugin, so it has no impact
on normal package resolution, app builds, or test execution.

`doctor` checks the local repository shape and command availability:

```bash
tools/mocksyn-inspect.sh doctor
```

The command verifies `Package.swift`, `CHANGELOG.md`, support matrix docs, the
DocC catalog, executable optional tooling scripts, `swift`, and `xcrun`.

`version` prints the latest documented version from `CHANGELOG.md`:

```bash
tools/mocksyn-inspect.sh version
```

## DocC

Generate DocC locally:

```bash
swift package generate-documentation --target MockSyn
```

Validate the DocC catalog without writing permanent artifacts:

```bash
tools/mocksyn-inspect.sh docc --validate
```

For static hosting:

```bash
swift package --allow-writing-to-directory ./docs/docc-output \
  generate-documentation --target MockSyn \
  --disable-indexing \
  --transform-for-static-hosting \
  --hosting-base-path MockSyn \
  --output-path ./docs/docc-output
```

## Guias de migracao

Migration docs are intentionally separate from API docs:

- [Mockable](../migration/mockable.md)
- [Cuckoo](../migration/cuckoo.md)
- [SwiftyMocky](../migration/swiftymocky.md)

Each guide maps the previous framework workflow to MockSyn's macro-first model.

## Benchmarks

Print the benchmark plan:

```bash
tools/benchmark.sh --print-plan
```

Run benchmark tests when a `MockSynPerformance` test suite exists:

```bash
tools/benchmark.sh --run
```

The command runs real XCTest performance measurements and macro-expanded
fixtures from `Tests/MockSynPerformanceTests`. Plain `swift test` compiles the
target, but measured benchmark bodies skip unless `MOCKSYN_RUN_BENCHMARKS=1` is
set by the script.

Benchmark fixtures cover macro expansion size/time through SwiftPM build work
and runtime operations listed in [Performance](../PERFORMANCE.md).
