#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGE_DIR="$ROOT_DIR/IntegrationTests/ConsumerPackage"
SWIFT_VERSION="auto"

print_help() {
  cat <<'EOF'
Usage: tools/test-consumer-package.sh [--swift-version auto|5|6]

Builds the production ConsumerCore target in release mode, then runs the
external consumer tests. Auto always checks Swift 5 language mode and adds
Swift 6 language mode only when the active compiler supports it.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --swift-version)
      [[ $# -ge 2 ]] || { echo "Missing value for --swift-version" >&2; exit 64; }
      SWIFT_VERSION="$2"
      shift 2
      ;;
    --help|-h)
      print_help
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      print_help >&2
      exit 64
      ;;
  esac
done

case "$SWIFT_VERSION" in
  auto|5|6) ;;
  *)
    echo "Unsupported Swift language mode: $SWIFT_VERSION" >&2
    exit 64
    ;;
esac

compiler_major="$(swiftc --version | sed -nE 's/.*Swift version ([0-9]+).*/\1/p' | head -n 1)"
if [[ -z "$compiler_major" ]]; then
  echo "Unable to determine the active Swift compiler version" >&2
  exit 69
fi

if [[ "$SWIFT_VERSION" == "6" && "$compiler_major" -lt 6 ]]; then
  echo "Swift language mode 6 requires a Swift 6 compiler" >&2
  exit 64
fi

modes=("5")
if [[ "$SWIFT_VERSION" == "6" ]]; then
  modes=("6")
elif [[ "$SWIFT_VERSION" == "auto" && "$compiler_major" -ge 6 ]]; then
  modes+=("6")
fi

cleanup() {
  rm -f "$PACKAGE_DIR/Package.resolved"
}
trap cleanup EXIT

for mode in "${modes[@]}"; do
  scratch_path="$PACKAGE_DIR/.build/swift-$mode"
  echo "Building ConsumerCore release target in Swift $mode language mode"
  MOCKSYN_CONSUMER_LANGUAGE_MODE="$mode" swift build \
    --package-path "$PACKAGE_DIR" \
    --scratch-path "$scratch_path" \
    --configuration release \
    --target ConsumerCore

  echo "Testing ConsumerPackage in Swift $mode language mode"
  MOCKSYN_CONSUMER_LANGUAGE_MODE="$mode" swift test \
    --package-path "$PACKAGE_DIR" \
    --scratch-path "$scratch_path"
done
