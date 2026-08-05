#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGE_DIR="$ROOT_DIR/IntegrationTests/ConsumerPackage"
RESOLVED_FILE="$PACKAGE_DIR/Package.resolved"
STATE_DIR="$PACKAGE_DIR/.build/script-state"
SWIFT_VERSION="auto"
RESOLVED_EXISTED=0
RESOLVED_BACKUP=""

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

preserve_resolved_file() {
  mkdir -p "$STATE_DIR"
  if [[ -f "$RESOLVED_FILE" ]]; then
    RESOLVED_EXISTED=1
    RESOLVED_BACKUP="$STATE_DIR/Package.resolved.$$"
    cp -p "$RESOLVED_FILE" "$RESOLVED_BACKUP"
  fi
}

cleanup() {
  if [[ "$RESOLVED_EXISTED" -eq 1 ]]; then
    cp -p "$RESOLVED_BACKUP" "$RESOLVED_FILE"
    rm -f "$RESOLVED_BACKUP"
  else
    rm -f "$RESOLVED_FILE"
  fi
}

verify_release_artifacts() {
  local scratch_path="$1"
  local artifact_list="$scratch_path/consumer-release-artifacts.txt"
  local artifact
  local artifact_count=0
  local forbidden_symbols="PublicUserLoadingMock|MirroredExternalUserLoadingMock|PublicBuildInformationMock"

  command -v nm >/dev/null 2>&1 || { echo "nm is required to inspect release artifacts" >&2; return 69; }

  find "$scratch_path" -type f \( \
    -path "*/release/ConsumerCore.build/*.o" -o \
    -path "*/Release/ConsumerCore.build/*.o" -o \
    -path "*/release/ConsumerCore-t.build/*.o" -o \
    -path "*/Release/ConsumerCore-t.build/*.o" -o \
    -path "*/Products/release/ConsumerCore.o" -o \
    -path "*/Products/Release/ConsumerCore.o" -o \
    -path "*/release/libConsumerCore.a" -o \
    -path "*/release/libConsumerCore.so" -o \
    -path "*/Release/libConsumerCore.a" -o \
    -path "*/Release/libConsumerCore.dylib" \
  \) -print > "$artifact_list"

  while IFS= read -r artifact; do
    [[ -n "$artifact" ]] || continue
    artifact_count=$((artifact_count + 1))
    if nm "$artifact" 2>/dev/null | grep -E "$forbidden_symbols" >/dev/null; then
      echo "Generated mock symbol found in release ConsumerCore artifact: $artifact" >&2
      return 1
    fi
  done < "$artifact_list"

  if [[ "$artifact_count" -eq 0 ]]; then
    echo "No release ConsumerCore objects or libraries were found under $scratch_path" >&2
    return 66
  fi
}

preserve_resolved_file
trap cleanup EXIT

for mode in "${modes[@]}"; do
  scratch_path="$PACKAGE_DIR/.build/swift-$mode"
  echo "Building ConsumerCore release target in Swift $mode language mode"
  MOCKSYN_CONSUMER_LANGUAGE_MODE="$mode" swift build \
    --package-path "$PACKAGE_DIR" \
    --scratch-path "$scratch_path" \
    --configuration release \
    --target ConsumerCore
  verify_release_artifacts "$scratch_path"

  echo "Testing ConsumerPackage in Swift $mode language mode"
  MOCKSYN_CONSUMER_LANGUAGE_MODE="$mode" swift test \
    --package-path "$PACKAGE_DIR" \
    --scratch-path "$scratch_path"
done
