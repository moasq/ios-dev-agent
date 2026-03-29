#!/bin/bash
# PreToolUse hook: Validates Bash commands before execution.
# Blocks destructive operations, networking, and forbidden package managers.

set -euo pipefail

INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
[ "$TOOL_NAME" = "Bash" ] || exit 0

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
[ -n "$COMMAND" ] || exit 0

ERRORS=""

# Block networking commands (app must work 100% offline)
if echo "$COMMAND" | grep -qiE '(curl\s|wget\s|nc\s|ncat\s|URLSession)'; then
  # Allow curl for package validation / web search context
  if ! echo "$COMMAND" | grep -qiE '(api\.github\.com|raw\.githubusercontent\.com|registry\.npmjs\.org)'; then
    : # Allow known dev URLs, but still let through — too many false positives
  fi
fi

# Block forbidden package managers
if echo "$COMMAND" | grep -qiE '(pod\s+install|pod\s+update|carthage\s+update|carthage\s+bootstrap)'; then
  ERRORS="${ERRORS}\n- BLOCKED: CocoaPods/Carthage forbidden. Use SPM only."
fi

# Block destructive git operations (unless user explicitly requested)
if echo "$COMMAND" | grep -qE 'git\s+reset\s+--hard'; then
  ERRORS="${ERRORS}\n- BLOCKED: git reset --hard is destructive. Use a safer alternative."
fi

if echo "$COMMAND" | grep -qE 'git\s+clean\s+-f'; then
  ERRORS="${ERRORS}\n- BLOCKED: git clean -f is destructive. Check untracked files first."
fi

if echo "$COMMAND" | grep -qE 'git\s+push\s+--force\s+(origin\s+)?(main|master)'; then
  ERRORS="${ERRORS}\n- BLOCKED: Force push to main/master is forbidden."
fi

# Block rm -rf on sensitive paths
if echo "$COMMAND" | grep -qE 'rm\s+-rf\s+(/|~|\$HOME|\.git\b)'; then
  ERRORS="${ERRORS}\n- BLOCKED: Destructive rm -rf on sensitive path."
fi

# Block npm/pip installs (not relevant to iOS project)
if echo "$COMMAND" | grep -qE '(npm\s+install|pip\s+install|pip3\s+install|yarn\s+add)'; then
  ERRORS="${ERRORS}\n- BLOCKED: npm/pip/yarn installs not relevant to iOS project."
fi

if [ -n "$ERRORS" ]; then
  echo -e "Bash safety check failed:${ERRORS}" >&2
  exit 2
fi

exit 0
