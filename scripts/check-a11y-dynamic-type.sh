#!/bin/bash
# PostToolUse hook: Validates Dynamic Type compliance.
# Flags hardcoded font sizes that break accessibility text scaling.
# All fonts must come from AppTheme.Fonts.* tokens.

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

BASENAME=$(basename "$FILE_PATH")

# Skip AppTheme.swift itself (that's where tokens are defined)
[[ "$BASENAME" == "AppTheme.swift" ]] && exit 0

WARNINGS=""

# Check for inline .font(.system(size: N)) — breaks Dynamic Type
FIXED_SIZE_LINES=$(grep -n '\.font(\.system(size:' "$FILE_PATH" 2>/dev/null || true)
if [ -n "$FIXED_SIZE_LINES" ]; then
  COUNT=$(echo "$FIXED_SIZE_LINES" | wc -l | tr -d ' ')
  WARNINGS="${WARNINGS}\n- WARNING: ${BASENAME} has ${COUNT} hardcoded .font(.system(size:)) call(s). Use AppTheme.Fonts.* tokens instead."
fi

# Check for raw SwiftUI font styles used directly (should use AppTheme.Fonts.*)
RAW_FONT_LINES=$(grep -nE '\.font\(\.(largeTitle|title|title2|title3|headline|subheadline|body|callout|footnote|caption|caption2)\)' "$FILE_PATH" 2>/dev/null || true)
if [ -n "$RAW_FONT_LINES" ]; then
  COUNT=$(echo "$RAW_FONT_LINES" | wc -l | tr -d ' ')
  WARNINGS="${WARNINGS}\n- WARNING: ${BASENAME} has ${COUNT} raw .font(.style) call(s). Use AppTheme.Fonts.* tokens."
fi

# Check for Font.custom with fixed sizes
CUSTOM_FONT_LINES=$(grep -n 'Font\.custom(' "$FILE_PATH" 2>/dev/null || true)
if [ -n "$CUSTOM_FONT_LINES" ]; then
  COUNT=$(echo "$CUSTOM_FONT_LINES" | wc -l | tr -d ' ')
  WARNINGS="${WARNINGS}\n- WARNING: ${BASENAME} has ${COUNT} Font.custom() call(s). Use system fonts via AppTheme.Fonts.*."
fi

if [ -n "$WARNINGS" ]; then
  echo -e "Dynamic Type check:${WARNINGS}" >&2
fi

exit 0
