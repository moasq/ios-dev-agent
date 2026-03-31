#!/bin/bash
# PostToolUse hook — detects successful build after a failure was logged
# If there's an UNRESOLVED entry in errors.md, notifies Claude to update it

set -euo pipefail

INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Only trigger on build tools
case "$TOOL_NAME" in
  Bash)
    COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
    if [[ "$COMMAND" != *"xcodebuild"* ]] && [[ "$COMMAND" != *"swift build"* ]] && [[ "$COMMAND" != *"xcode-build.sh"* ]]; then
      exit 0
    fi
    ;;
  *)
    exit 0
    ;;
esac

# Check if there are unresolved errors
LEDGER="$CLAUDE_PROJECT_DIR/.claude/errors/errors.md"
if [ ! -f "$LEDGER" ]; then
  exit 0
fi

UNRESOLVED_COUNT=$(grep -c '^\## \[UNRESOLVED\]' "$LEDGER" 2>/dev/null || echo "0")

if [ "$UNRESOLVED_COUNT" -gt 0 ]; then
  echo "Build succeeded. There are $UNRESOLVED_COUNT unresolved error(s) in .claude/errors/errors.md that may now be fixed. Consider updating their status to [RESOLVED] with root cause and fix details." >&2
fi

exit 0
