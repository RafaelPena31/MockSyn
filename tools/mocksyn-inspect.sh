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
  docc              Print DocC commands or validate the DocC catalog.
  doctor            Validate the local MockSyn inspection environment.
  version           Print the latest documented MockSyn version.
  help              Show this help.

This CLI is optional. It is not a SwiftPM build tool plugin and does not run
during consumer builds or tests unless called explicitly.
EOF
}

latest_version() {
  awk '/^## [0-9]+\.[0-9]+\.[0-9]+/ { print $2; exit }' "$ROOT_DIR/CHANGELOG.md"
}

print_ok() {
  printf 'OK %s\n' "$1"
}

require_file() {
  local path="$1"
  local label="$2"

  if [[ ! -f "$path" ]]; then
    printf 'Missing %s: %s\n' "$label" "$path" >&2
    exit 66
  fi

  print_ok "$label"
}

require_executable() {
  local path="$1"
  local label="$2"

  if [[ ! -x "$path" ]]; then
    printf 'Missing executable %s: %s\n' "$label" "$path" >&2
    exit 66
  fi

  print_ok "$label"
}

require_command() {
  local name="$1"
  local label="$2"

  if ! command -v "$name" >/dev/null 2>&1; then
    printf 'Missing command %s\n' "$name" >&2
    exit 69
  fi

  print_ok "$label"
}

print_docc_help() {
  cat <<'EOF'
DocC

Commands:
  tools/mocksyn-inspect.sh docc
  tools/mocksyn-inspect.sh docc --validate

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
}

validate_docc() {
  local output_dir
  output_dir="$(mktemp -d "${TMPDIR:-/tmp}/mocksyn-docc.XXXXXX")"

  if xcrun docc convert "$ROOT_DIR/Sources/MockSyn/MockSyn.docc" \
    --fallback-display-name MockSyn \
    --fallback-bundle-identifier com.mocksyn.docs \
    --fallback-bundle-version "$(latest_version)" \
    --output-path "$output_dir"; then
    rm -rf "$output_dir"
    echo "DocC validation passed"
  else
    local status=$?
    rm -rf "$output_dir"
    return "$status"
  fi
}

run_doctor() {
  echo "MockSyn Inspector Doctor"
  require_file "$ROOT_DIR/Package.swift" "Package.swift"
  require_file "$ROOT_DIR/CHANGELOG.md" "CHANGELOG.md"
  require_file "$ROOT_DIR/docs/SUPPORT_MATRIX.md" "support matrix"
  require_file "$ROOT_DIR/Sources/MockSyn/MockSyn.docc/MockSyn.md" "DocC catalog"
  require_executable "$ROOT_DIR/tools/benchmark.sh" "benchmark tool"
  require_executable "$ROOT_DIR/tools/export-macro-expansion.sh" "macro expansion tool"
  require_command swift "swift command"
  require_command xcrun "xcrun command"
  printf 'OK latest version %s\n' "$(latest_version)"
}

case "${1:-help}" in
  help|--help|-h)
    print_help
    ;;
  version)
    printf 'MockSyn version %s\n' "$(latest_version)"
    ;;
  doctor)
    run_doctor
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
    shift
    case "${1:-}" in
      --validate)
        validate_docc
        ;;
      --help|-h)
        print_docc_help
        ;;
      "")
        print_docc_help
        ;;
      *)
        echo "Unknown MockSyn Inspector docc option: $1" >&2
        print_docc_help >&2
        exit 64
        ;;
    esac
    ;;
  *)
    echo "Unknown MockSyn Inspector command: $1" >&2
    print_help >&2
    exit 64
    ;;
esac
