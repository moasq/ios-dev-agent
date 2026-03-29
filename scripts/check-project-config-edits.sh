#!/bin/bash
# PreToolUse hook: Validates edits to project configuration files.
# Blocks changes that would break build config, add forbidden dependencies,
# or violate platform requirements.

set -euo pipefail

INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
FILE_PATH=""

case "$TOOL_NAME" in
  Edit|Write)
    FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
    ;;
  MultiEdit)
    FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
    ;;
  *)
    exit 0
    ;;
esac

# Only check project config files
case "$FILE_PATH" in
  */project.yml|*/project.yaml|*/.pbxproj|*/Info.plist|*/Package.swift)
    ;;
  *)
    exit 0  # Not a config file, skip
    ;;
esac

CONTENT=""
case "$TOOL_NAME" in
  Write)
    CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // empty')
    ;;
  Edit)
    CONTENT=$(echo "$INPUT" | jq -r '.tool_input.new_string // empty')
    ;;
  MultiEdit)
    CONTENT=$(echo "$INPUT" | jq -r '[.tool_input.edits[]?.new_string // empty] | join("\n")' 2>/dev/null || echo "")
    ;;
esac

ERRORS=""

# Check for forbidden package managers
if echo "$CONTENT" | grep -qiE '(cocoapods|carthage|Podfile|Cartfile)'; then
  ERRORS="${ERRORS}\n- BLOCKED: CocoaPods/Carthage detected. Only SPM is allowed."
fi

# Check deployment target not lowered below iOS 26
if echo "$CONTENT" | grep -qiE 'deploymentTarget.*[0-9]+' ; then
  TARGET_VERSION=$(echo "$CONTENT" | grep -oE 'deploymentTarget[^0-9]*([0-9]+)' | grep -oE '[0-9]+' | head -1)
  if [ -n "$TARGET_VERSION" ] && [ "$TARGET_VERSION" -lt 26 ] 2>/dev/null; then
    ERRORS="${ERRORS}\n- BLOCKED: Deployment target must be iOS 26+, got iOS ${TARGET_VERSION}."
  fi
fi

# Check Swift version stays at 6
if echo "$CONTENT" | grep -qiE 'SWIFT_VERSION.*[0-9]'; then
  SWIFT_VER=$(echo "$CONTENT" | grep -oE 'SWIFT_VERSION[^0-9]*([0-9]+)' | grep -oE '[0-9]+' | head -1)
  if [ -n "$SWIFT_VER" ] && [ "$SWIFT_VER" -lt 6 ] 2>/dev/null; then
    ERRORS="${ERRORS}\n- BLOCKED: Swift version must be 6+, got ${SWIFT_VER}."
  fi
fi

# Check for forbidden frameworks being added
if echo "$CONTENT" | grep -qiE '(Firebase|CloudKit|iCloud)'; then
  ERRORS="${ERRORS}\n- BLOCKED: Firebase/CloudKit/iCloud are forbidden. App must work 100% offline."
fi

if [ -n "$ERRORS" ]; then
  echo -e "Project config validation failed:${ERRORS}" >&2
  exit 2
fi

exit 0
