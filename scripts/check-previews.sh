#!/bin/bash
# PostToolUse hook: Ensures every SwiftUI View file includes a #Preview block.
# Views without previews break the development workflow and violate MVVM rules.

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

# Only check Swift files
[[ "$FILE_PATH" == *.swift ]] || exit 0
[ -f "$FILE_PATH" ] || exit 0

BASENAME=$(basename "$FILE_PATH" .swift)

# Skip non-view files: ViewModels, Models, Theme, Services, extensions, App entry
[[ "$BASENAME" == *ViewModel ]] && exit 0
[[ "$BASENAME" == *+* ]] && exit 0  # Extension files like View+Sections.swift
[[ "$BASENAME" == *App ]] && exit 0
[[ "$BASENAME" == AppTheme ]] && exit 0
[[ "$BASENAME" == Loadable ]] && exit 0

# Skip files in non-view directories
case "$FILE_PATH" in
  */Models/*|*/Services/*|*/Theme/*|*/Shared/*|*/Config/*|*/Repositories/*) exit 0 ;;
esac

# Check if this file actually contains a View (has `var body: some View`)
if ! grep -qE 'var body:\s*some View' "$FILE_PATH" 2>/dev/null; then
  exit 0  # Not a View file
fi

# Check for #Preview
if ! grep -qE '#Preview' "$FILE_PATH" 2>/dev/null; then
  echo "Preview check: WARNING: ${BASENAME}.swift is a View but has no #Preview block. Every View must include #Preview." >&2
fi

exit 0
