#!/bin/bash
# PostToolUse hook — detects UI test failures and logs runtime crashes to error ledger
# Fires after mcp__xcode__RunSomeTests or mcp__xcode__RunAllTests

set -euo pipefail

INPUT=$(cat)

# Extract tool name
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Only process test-related tools
case "$TOOL_NAME" in
  mcp__xcode__RunSomeTests|mcp__xcode__RunAllTests)
    ;;
  *)
    exit 0
    ;;
esac

# Extract response
RESPONSE=$(echo "$INPUT" | jq -r '.tool_response // empty')

# Check if tests passed (look for failure indicators)
if echo "$RESPONSE" | grep -qi "passed\|succeeded\|all tests passed"; then
  # Tests passed — check for unresolved runtime errors that may now be fixed
  LEDGER="$CLAUDE_PROJECT_DIR/.claude/errors/errors.md"
  if [ -f "$LEDGER" ] && grep -q '\[UNRESOLVED\].*Runtime Crash' "$LEDGER" 2>/dev/null; then
    echo "All tests passed. There are unresolved runtime crash entries in the error ledger — consider marking them [RESOLVED]." >&2
  fi
  exit 0
fi

# Tests failed — check for crash indicators
if echo "$RESPONSE" | grep -qiE "crash|EXC_|SIGABRT|signal|terminated|failed"; then
  SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
  TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S")
  LEDGER="$CLAUDE_PROJECT_DIR/.claude/errors/errors.md"

  if [ ! -f "$LEDGER" ]; then
    exit 0
  fi

  # Extract failing test info
  FAILING_TESTS=$(echo "$RESPONSE" | grep -oE 'test[A-Za-z]+' | head -3 | tr '\n' ', ' || echo "unknown")
  ERROR_MSG=$(echo "$RESPONSE" | grep -iE "crash|EXC_|SIGABRT|failed|error" | head -3 | tr '\n' ' ' || echo "Test failure detected")

  cat >> "$LEDGER" << ENTRY

## [UNRESOLVED] ${TIMESTAMP} — Runtime Crash: Test Failure

- **Error:** \`${ERROR_MSG}\`
- **File:** \`test: ${FAILING_TESTS}\`
- **Category:** \`runtime/uncategorized\`
- **Symptom:** Smoke walker test failed — possible runtime crash detected.
- **Root Cause:** _Pending investigation_
- **Fix:** _Pending_
- **Session:** \`${SESSION_ID}\`

---
ENTRY

  echo "Test failure detected and logged to error ledger. Use /crash to investigate." >&2
fi

exit 0
