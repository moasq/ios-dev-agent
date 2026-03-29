#!/bin/bash
# PostToolUse hook: Validates accessibility labels on icon-only buttons.
# Icon buttons without labels are invisible to VoiceOver users.

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

# Skip non-view files
[[ "$BASENAME" == *ViewModel* ]] && exit 0
[[ "$BASENAME" == "AppTheme.swift" ]] && exit 0
[[ "$BASENAME" == "Loadable.swift" ]] && exit 0

# Skip files without views
grep -qE 'var body:\s*some View' "$FILE_PATH" 2>/dev/null || exit 0

WARNINGS=""

# Find Button blocks that contain only an Image (icon-only buttons)
# This is a heuristic: look for Button { ... } { Image(systemName:) } patterns
# where no Text() or Label() sibling exists nearby

# Strategy: Find lines with Image(systemName:) and check if they're inside a Button
# without a nearby Text or Label providing context

CONTENT=$(cat "$FILE_PATH")

# Check for .onTapGesture on Image without accessibilityLabel
TAP_GESTURE_IMAGES=$(grep -n 'Image(systemName:.*\.onTapGesture' "$FILE_PATH" 2>/dev/null || true)
if [ -n "$TAP_GESTURE_IMAGES" ]; then
  COUNT=$(echo "$TAP_GESTURE_IMAGES" | wc -l | tr -d ' ')
  WARNINGS="${WARNINGS}\n- WARNING: ${BASENAME} has ${COUNT} Image with .onTapGesture. Use Button instead and add .accessibilityLabel()."
fi

# Check for toolbar items with just an Image (common pattern that needs labels)
# Look for Image(systemName:) inside Button without .accessibilityLabel nearby
# This is a simplified check — catches the most common pattern
ICON_BUTTONS=$(grep -cE 'Button.*\{[^}]*Image\(systemName:' "$FILE_PATH" 2>/dev/null || echo "0")
A11Y_LABELS=$(grep -cE '\.accessibilityLabel\(' "$FILE_PATH" 2>/dev/null || echo "0")

if [ "$ICON_BUTTONS" -gt 0 ] && [ "$A11Y_LABELS" -lt "$ICON_BUTTONS" ]; then
  MISSING=$((ICON_BUTTONS - A11Y_LABELS))
  if [ "$MISSING" -gt 0 ]; then
    WARNINGS="${WARNINGS}\n- NOTE: ${BASENAME} has ${ICON_BUTTONS} icon button(s) but only ${A11Y_LABELS} .accessibilityLabel(). Ensure all icon-only buttons have labels."
  fi
fi

if [ -n "$WARNINGS" ]; then
  echo -e "Accessibility check:${WARNINGS}" >&2
fi

exit 0
