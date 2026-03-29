#!/bin/bash
# Stop hook: Runs a quick build check when Claude stops.
# Verifies the project still compiles and logs any failures.

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
ERRORS_LEDGER="$PROJECT_DIR/.claude/errors/errors.md"

# Find the Xcode project or workspace
WORKSPACE=$(find "$PROJECT_DIR" -maxdepth 1 -name "*.xcworkspace" -not -path "*/.*" | head -1)
XCODEPROJ=$(find "$PROJECT_DIR" -maxdepth 1 -name "*.xcodeproj" -not -path "*/.*" | head -1)

if [ -z "$WORKSPACE" ] && [ -z "$XCODEPROJ" ]; then
  echo "Build check: No Xcode project found. Skipping." >&2
  exit 0
fi

# Determine scheme
SCHEME=""
if [ -n "$WORKSPACE" ]; then
  SCHEME=$(xcodebuild -workspace "$WORKSPACE" -list 2>/dev/null | grep -A 100 "Schemes:" | tail -n +2 | head -1 | xargs)
  BUILD_TARGET="-workspace $WORKSPACE"
elif [ -n "$XCODEPROJ" ]; then
  SCHEME=$(xcodebuild -project "$XCODEPROJ" -list 2>/dev/null | grep -A 100 "Schemes:" | tail -n +2 | head -1 | xargs)
  BUILD_TARGET="-project $XCODEPROJ"
fi

if [ -z "$SCHEME" ]; then
  echo "Build check: Could not determine scheme. Skipping." >&2
  exit 0
fi

# Find a simulator
SIMULATOR=$(xcrun simctl list devices available -j 2>/dev/null | jq -r '.devices | to_entries[] | select(.key | contains("iOS")) | .value[] | select(.state == "Booted" or .isAvailable == true) | .udid' 2>/dev/null | head -1)
DESTINATION="platform=iOS Simulator,id=${SIMULATOR:-00000000-0000-0000-0000-000000000000}"

# Run build (quick check, no clean)
echo "Build check: Building ${SCHEME}..." >&2
BUILD_OUTPUT=$(xcodebuild $BUILD_TARGET -scheme "$SCHEME" -destination "$DESTINATION" build 2>&1) || {
  BUILD_EXIT=$?

  # Extract errors
  ERRORS=$(echo "$BUILD_OUTPUT" | grep -E "error:" | head -10)
  TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S")

  echo "Build check: BUILD FAILED with exit code ${BUILD_EXIT}" >&2
  echo "$ERRORS" >&2

  # Log to errors ledger if it exists
  if [ -d "$(dirname "$ERRORS_LEDGER")" ]; then
    cat >> "$ERRORS_LEDGER" << ENTRY

---
## Build Error — Stop Hook
**Date:** ${TIMESTAMP}
**Status:** [UNRESOLVED]
**Scheme:** ${SCHEME}
**Exit Code:** ${BUILD_EXIT}

### Errors
\`\`\`
${ERRORS}
\`\`\`
ENTRY
  fi

  exit 0  # Stop hooks should not block
}

echo "Build check: ${SCHEME} builds successfully." >&2

# Check if there are unresolved errors that might now be fixed
if [ -f "$ERRORS_LEDGER" ]; then
  UNRESOLVED=$(grep -c '\[UNRESOLVED\]' "$ERRORS_LEDGER" 2>/dev/null || echo "0")
  if [ "$UNRESOLVED" -gt 0 ]; then
    echo "Build check: Build succeeded but ${UNRESOLVED} error(s) still marked [UNRESOLVED] in ledger. Consider resolving them." >&2
  fi
fi

exit 0
