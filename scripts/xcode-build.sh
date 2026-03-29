#!/bin/bash
# Builds the Xcode project for iOS Simulator.
# Usage: xcode-build.sh [--clean] [--scheme NAME] [--device "iPhone 17 Pro"] [--project-dir PATH]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLEAN=false
SCHEME=""
DEVICE_NAME=""
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --clean) CLEAN=true; shift ;;
    --scheme) SCHEME="$2"; shift 2 ;;
    --device) DEVICE_NAME="$2"; shift 2 ;;
    --project-dir) PROJECT_DIR="$2"; shift 2 ;;
    *) echo "Unknown flag: $1" >&2; exit 1 ;;
  esac
done

cd "$PROJECT_DIR"

# Auto-detect .xcodeproj
XCODEPROJ=$(find . -maxdepth 1 -name "*.xcodeproj" -type d | head -1)
if [ -z "$XCODEPROJ" ]; then
  echo "ERROR: No .xcodeproj found in $PROJECT_DIR" >&2
  echo "Run /scaffold to create a project first, or run 'xcodegen generate'." >&2
  exit 1
fi

# Auto-detect scheme (use project name without .xcodeproj)
if [ -z "$SCHEME" ]; then
  SCHEME=$(basename "$XCODEPROJ" .xcodeproj)
fi

# Get simulator UDID
FIND_SIM_ARGS=()
if [ -n "$DEVICE_NAME" ]; then
  FIND_SIM_ARGS+=(--name "$DEVICE_NAME")
fi

UDID=$("$SCRIPT_DIR/find-simulator.sh" "${FIND_SIM_ARGS[@]}")

echo "Building $SCHEME on simulator $UDID..."

# Build command
BUILD_ACTION="build"
if [ "$CLEAN" = true ]; then
  BUILD_ACTION="clean build"
fi

xcodebuild \
  -project "$XCODEPROJ" \
  -scheme "$SCHEME" \
  -destination "platform=iOS Simulator,id=$UDID" \
  -quiet \
  $BUILD_ACTION \
  CODE_SIGNING_ALLOWED=NO \
  2>&1

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  echo "BUILD SUCCEEDED"
else
  echo "BUILD FAILED (exit code: $EXIT_CODE)" >&2
fi

exit $EXIT_CODE
