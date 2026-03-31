#!/bin/bash
# PostToolUseFailure hook — logs build errors to .claude/errors/errors.md
# Receives JSON on stdin with tool_name, tool_input, tool_response

set -euo pipefail

INPUT=$(cat)

# Extract fields from hook input
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S")

# Only process build-related tool failures
case "$TOOL_NAME" in
  Bash)
    ;;
  *)
    exit 0
    ;;
esac

# For Bash tool, only log if it looks like a build command
if [ "$TOOL_NAME" = "Bash" ]; then
  COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
  if [[ "$COMMAND" != *"xcodebuild"* ]] && [[ "$COMMAND" != *"swift build"* ]]; then
    exit 0
  fi
fi

# Extract error content from tool response
ERROR_CONTENT=$(echo "$INPUT" | jq -r '.tool_response // empty' | head -200)

# If no meaningful error content, skip
if [ -z "$ERROR_CONTENT" ] || [ "$ERROR_CONTENT" = "null" ]; then
  exit 0
fi

# Extract file:line references from error (common Swift error format)
ERROR_FILES=$(echo "$ERROR_CONTENT" | grep -oE '[A-Za-z0-9_/]+\.swift:[0-9]+' | head -5 | tr '\n' ', ' || true)

# Find the errors ledger
LEDGER="$CLAUDE_PROJECT_DIR/.claude/errors/errors.md"
if [ ! -f "$LEDGER" ]; then
  exit 0
fi

# Append the error entry
cat >> "$LEDGER" << ENTRY

## [UNRESOLVED] ${TIMESTAMP} — Build Error

- **Error:** \`$(echo "$ERROR_CONTENT" | grep -E "error:|fatal error:|EXC_" | head -3 | tr '\n' ' ' || echo "Build failed")\`
- **File:** \`${ERROR_FILES:-unknown}\`
- **Category:** \`uncategorized\`
- **Symptom:** Build failed during development session.
- **Root Cause:** _Pending investigation_
- **Fix:** _Pending_
- **Session:** \`${SESSION_ID}\`
- **Raw Output (first 50 lines):**
\`\`\`
$(echo "$ERROR_CONTENT" | head -50)
\`\`\`

---
ENTRY

# Provide feedback to Claude
echo "Build error logged to .claude/errors/errors.md. Use /fix-error to investigate and resolve." >&2
exit 0
