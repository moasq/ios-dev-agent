#!/bin/bash
# PostToolUse hook: Validates Swift file structure after edits.
# Checks line count, one-type-per-file, naming conventions, and directory placement.

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
BASENAME=$(basename "$FILE_PATH" .swift)

# --- Line count check ---
LINE_COUNT=$(wc -l < "$FILE_PATH" | tr -d ' ')
if [ "$LINE_COUNT" -gt 200 ]; then
  WARNINGS="${WARNINGS}\n- WARNING: ${BASENAME}.swift is ${LINE_COUNT} lines (hard limit: 200). Split into extensions."
elif [ "$LINE_COUNT" -gt 150 ]; then
  WARNINGS="${WARNINGS}\n- NOTE: ${BASENAME}.swift is ${LINE_COUNT} lines (target: 150). Consider splitting."
fi

# --- One type per file (primary types only) ---
# Count struct/class/enum/@Observable declarations at the top level (not nested)
TYPE_COUNT=$(grep -cE '^\s*(public |private |internal |open |fileprivate )?(struct|class|enum|actor) [A-Z]' "$FILE_PATH" 2>/dev/null || echo "0")
# Subtract extension declarations
EXTENSION_COUNT=$(grep -cE '^\s*(public |private |internal |open |fileprivate )?extension ' "$FILE_PATH" 2>/dev/null || echo "0")
PRIMARY_TYPES=$((TYPE_COUNT))

if [ "$PRIMARY_TYPES" -gt 1 ] && [ "$EXTENSION_COUNT" -eq 0 ]; then
  WARNINGS="${WARNINGS}\n- WARNING: ${BASENAME}.swift has ${PRIMARY_TYPES} primary type declarations. One type per file."
fi

# --- Naming convention checks ---
# View files should end in View
if grep -qE 'var body:\s*some View' "$FILE_PATH" 2>/dev/null; then
  if [[ "$BASENAME" != *View ]] && [[ "$BASENAME" != *View+* ]] && [[ "$BASENAME" != *App ]]; then
    # Allow extensions and App entry point
    if ! grep -qE '^\s*extension\s' "$FILE_PATH" 2>/dev/null; then
      WARNINGS="${WARNINGS}\n- NOTE: ${BASENAME}.swift contains a View but filename doesn't end with 'View'."
    fi
  fi
fi

# ViewModel files should end in ViewModel
if grep -qE '@Observable' "$FILE_PATH" 2>/dev/null && grep -qE 'class.*ViewModel' "$FILE_PATH" 2>/dev/null; then
  if [[ "$BASENAME" != *ViewModel ]]; then
    WARNINGS="${WARNINGS}\n- NOTE: ${BASENAME}.swift contains a ViewModel but filename doesn't end with 'ViewModel'."
  fi
fi

# --- Directory placement checks ---
if [[ "$FILE_PATH" == */Views/* ]] || [[ "$FILE_PATH" == */ViewModels/* ]] || [[ "$FILE_PATH" == */Components/* ]]; then
  WARNINGS="${WARNINGS}\n- WARNING: Flat Views/ViewModels/Components/ directories are forbidden. Use Features/<Name>/."
fi

if [ -n "$WARNINGS" ]; then
  echo -e "Swift structure check:${WARNINGS}" >&2
fi

exit 0
