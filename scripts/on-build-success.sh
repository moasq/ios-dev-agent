#!/bin/bash
# PostToolUse hook — fires after successful Bash commands
# Detects xcodebuild success and prompts screenshot/preview validation
set -euo pipefail

INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Only process Bash tool
if [ "$TOOL_NAME" != "Bash" ]; then
  exit 0
fi

# Check if this was a build command
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
if [[ "$COMMAND" != *"xcodebuild"* ]] && [[ "$COMMAND" != *"xcode-build.sh"* ]]; then
  exit 0
fi

# Check if build succeeded (PostToolUse only fires on success, but verify output)
RESPONSE=$(echo "$INPUT" | jq -r '.tool_response // empty')

# Look for BUILD SUCCEEDED in output
if echo "$RESPONSE" | grep -q "BUILD SUCCEEDED\|Build Succeeded\|build succeeded"; then
  # Return additional context to Claude
  cat << 'HOOK_OUTPUT'
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "Build succeeded. You can now:\n1. Use the Xcode MCP (mcp__xcode__*) to render previews and inspect the UI\n2. Run screenshots: bash .claude/scripts/capture-screenshots.sh\n3. Check for runtime issues by launching in simulator with console output\n\nIf there are unresolved errors in .claude/errors/errors.md, consider marking them [RESOLVED]."
  }
}
HOOK_OUTPUT
  exit 0
fi

# If we got here, the command succeeded but wasn't clearly a build success
# (could be xcodebuild with a non-build action like clean)
exit 0
