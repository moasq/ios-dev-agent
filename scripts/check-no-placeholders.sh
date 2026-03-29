#!/bin/bash
# PostToolUse hook: Detects placeholder/stub code left in Swift files.
# Flags TODO, FIXME, placeholder strings, empty implementations, and Xcode template markers.

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

WARNINGS=""
BASENAME=$(basename "$FILE_PATH")

# Check for TODO/FIXME/XXX comments (excluding legitimate documentation)
TODO_LINES=$(grep -n '//\s*\(TODO\|FIXME\|XXX\|HACK\)\b' "$FILE_PATH" 2>/dev/null || true)
if [ -n "$TODO_LINES" ]; then
  COUNT=$(echo "$TODO_LINES" | wc -l | tr -d ' ')
  WARNINGS="${WARNINGS}\n- WARNING: ${BASENAME} has ${COUNT} TODO/FIXME comment(s). Complete the implementation."
fi

# Check for Xcode placeholder tokens <#...#>
PLACEHOLDER_LINES=$(grep -n '<#.*#>' "$FILE_PATH" 2>/dev/null || true)
if [ -n "$PLACEHOLDER_LINES" ]; then
  COUNT=$(echo "$PLACEHOLDER_LINES" | wc -l | tr -d ' ')
  WARNINGS="${WARNINGS}\n- WARNING: ${BASENAME} has ${COUNT} Xcode placeholder token(s) (<#...#>). Replace with real values."
fi

# Check for "Coming soon" / "Not implemented" placeholder strings
STUB_LINES=$(grep -niE '"(coming soon|not implemented|placeholder|lorem ipsum|sample text)"' "$FILE_PATH" 2>/dev/null || true)
if [ -n "$STUB_LINES" ]; then
  COUNT=$(echo "$STUB_LINES" | wc -l | tr -d ' ')
  WARNINGS="${WARNINGS}\n- WARNING: ${BASENAME} has ${COUNT} placeholder string(s). Replace with real content."
fi

# Check for fatalError("not implemented") patterns
FATAL_LINES=$(grep -n 'fatalError.*not implemented\|fatalError.*TODO\|fatalError.*stub' "$FILE_PATH" 2>/dev/null || true)
if [ -n "$FATAL_LINES" ]; then
  COUNT=$(echo "$FATAL_LINES" | wc -l | tr -d ' ')
  WARNINGS="${WARNINGS}\n- WARNING: ${BASENAME} has ${COUNT} fatalError stub(s). Implement the methods."
fi

if [ -n "$WARNINGS" ]; then
  echo -e "Placeholder check:${WARNINGS}" >&2
fi

exit 0
