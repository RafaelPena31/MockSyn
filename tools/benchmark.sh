#!/usr/bin/env bash
set -euo pipefail

print_help() {
  cat <<'EOF'
MockSyn Benchmark

Usage:
  tools/benchmark.sh [--print-plan|--run] [swift-test-arguments]

Commands:
  --print-plan   Print the benchmark fixture plan.
  --run          Run benchmark tests matching MockSynPerformance.
  --help         Show this help.

Default run command:
  swift test --filter MockSynPerformance

Benchmarks are optional local checks. They do not participate in macro
generation and are not run during consumer builds.
EOF
}

print_plan() {
  cat <<'EOF'
MockSynPerformance benchmark plan:
- macro expansion for 1 method;
- macro expansion for 20 methods;
- macro expansion for async throws members;
- macro expansion for properties;
- macro expansion for generic methods;
- 1,000 recorded mock calls;
- 1,000 verifications;
- concurrent async invocations.
EOF
}

case "${1:---print-plan}" in
  --help|-h|help)
    print_help
    ;;
  --print-plan)
    print_plan
    ;;
  --run)
    shift
    exec swift test --filter MockSynPerformance "$@"
    ;;
  *)
    exec swift test --filter MockSynPerformance "$@"
    ;;
esac
