#!/usr/bin/env bash
set -euo pipefail

print_help() {
  cat <<'EOF'
Export MockSyn Macro Expansion

Usage:
  tools/export-macro-expansion.sh [swift-build-arguments]

Default command:
  swift build -Xswiftc -Xfrontend -Xswiftc -dump-macro-expansions

Examples:
  tools/export-macro-expansion.sh
  tools/export-macro-expansion.sh --target AppCore
  tools/export-macro-expansion.sh --configuration debug

The generated mocks, stubs, and spies are compiler macro expansion output.
MockSyn does not write generated Swift files to the project.
EOF
}

case "${1:-}" in
  --help|-h|help)
    print_help
    exit 0
    ;;
esac

exec swift build -Xswiftc -Xfrontend -Xswiftc -dump-macro-expansions "$@"
