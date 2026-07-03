# Tooling

Block 12 defines optional tools for inspecting MockSyn locally. These tools do
not participate in the macro generation path, do not run during consumer builds,
and do not write generated mocks into the project.

## Feature Summary

| Feature | Status | Behavior |
| --- | --- | --- |
| Export de macro expansion | Supported | `tools/export-macro-expansion.sh` runs SwiftPM with macro expansion dumping enabled. |
| CLI de inspecao | Supported as optional shell CLI | `tools/mocksyn-inspect.sh` groups local inspection commands. |
| DocC | Supported | `Sources/MockSyn/MockSyn.docc` documents the public package surface. |
| Guias de migracao | Supported | Migration guides cover Mockable, Cuckoo, and SwiftyMocky. |
| Benchmarks | Supported as optional local harness | `tools/benchmark.sh` defines the benchmark plan and run command. |

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
```

It is intentionally a shell CLI instead of a SwiftPM plugin, so it has no impact
on normal package resolution, app builds, or test execution.

## DocC

Generate DocC locally:

```bash
swift package generate-documentation --target MockSyn
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

Benchmark fixtures should cover macro expansion size/time and runtime operations
listed in [Performance](../PERFORMANCE.md).
