#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

print_help() {
  cat <<'EOF'
MockSyn Inspector

Usage:
  tools/mocksyn-inspect.sh <command> [options]

Commands:
  support-matrix    Print the documented MockSyn support matrix.
  macro-expansion   Run Export MockSyn Macro Expansion helper.
  benchmarks        Run MockSyn Benchmark helper.
  docc              Print the DocC generation command.
  help              Show this help.

This CLI is optional. It is not a SwiftPM build tool plugin and does not run
during consumer builds or tests unless called explicitly.
EOF
}

case "${1:-help}" in
  help|--help|-h)
    print_help
    ;;
  support-matrix)
    cat "$ROOT_DIR/docs/SUPPORT_MATRIX.md"
    ;;
  macro-expansion)
    shift
    exec "$ROOT_DIR/tools/export-macro-expansion.sh" "$@"
    ;;
  benchmarks)
    shift
    exec "$ROOT_DIR/tools/benchmark.sh" "$@"
    ;;
  docc)
    cat <<'EOF'
DocC

Run:
  swift package generate-documentation --target MockSyn

For static hosting:
  swift package --allow-writing-to-directory ./docs/docc-output \
    generate-documentation --target MockSyn \
    --disable-indexing \
    --transform-for-static-hosting \
    --hosting-base-path MockSyn \
    --output-path ./docs/docc-output
EOF
    ;;
  *)
    echo "Unknown MockSyn Inspector command: $1" >&2
    print_help >&2
    exit 64
    ;;
esac
