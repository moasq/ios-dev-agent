---
name: "fix-error"
description: "Use when a build fails or there are unresolved errors. Reads .claude/errors/errors.md, investigates root cause, applies fix, verifies build, and logs the resolution."
---

# Fix Error

Investigate and resolve unresolved build errors from the error ledger.

## Quick Start

1. Read `.claude/errors/errors.md` — find `[UNRESOLVED]` entries
2. If no unresolved entries, check the latest build output for errors
3. For each error, follow the resolution workflow below

## Resolution Workflow

### 1. Check History First

Read the error ledger for past `[RESOLVED]` and `[CONSOLIDATED]` entries with similar patterns:
- Same file or module?
- Same error type (type mismatch, concurrency, missing reference)?
- Same crash signature?

If a match exists, **apply the known fix pattern** — don't reinvestigate.

### 2. Investigate

If no prior match:
- Read the failing file at the reported line
- Read imports, type definitions, related files
- Classify the error by category
- Identify root cause (not just the error message — the actual WHY)

### 3. Fix

- Edit the failing file(s)
- Fix the root cause, not the symptom
- If multiple files need changes, make all changes before rebuilding

### 4. Verify

Run the build. If it fails again:
- Is it the same error? (fix didn't work — try another approach)
- Is it a new error? (fix introduced a regression — fix that too)
- Max 3 attempts. If still failing, report findings and stop.

### 5. Update the Ledger

In `.claude/errors/errors.md`, change the entry from `[UNRESOLVED]` to `[RESOLVED]` and fill in:

```markdown
## [RESOLVED] <timestamp> — <brief description>

- **Error:** `<error message>`
- **File:** `<file:line>`
- **Category:** `<category from classification>`
- **Symptom:** <what it looked like>
- **Root Cause:** <what actually caused it>
- **Misleading Signal:** <what made this confusing, if applicable>
- **Fix:** <what was changed and why>
- **Files Changed:** <list of modified files>
- **Key Diagnostic:** <the single most important clue>
- **Prevention Rule:** <one-sentence rule that would prevent this>
```

### 6. Suggest Consolidation

After resolving, mention: "Run `/consolidate-errors` to feed this fix back into rules/skills."

## Error Categories

| Category | Pattern | Common Root Cause |
|---|---|---|
| `concurrency/async-render` | EXC_BREAKPOINT + AsyncRenderer | UIKit code on wrong thread |
| `concurrency/isolation` | Actor-isolated property error | Swift 6 Sendable violation |
| `type-mismatch` | Cannot convert value of type | Wrong type, missing conformance |
| `missing-reference` | Use of unresolved identifier | Missing import, typo, deleted symbol |
| `missing-type` | Cannot find type in scope | Missing import or undeclared type |
| `ambiguous-type` | Ambiguous use of | Duplicate type declarations |
| `api-mismatch` | Has no member | Deprecated or wrong API |
| `file-structure` | File > 200 lines | Needs splitting |
| `swiftdata` | ModelContext thread crash | Wrong actor for context |
| `theme` | Hardcoded color/font/spacing | AppTheme token not used |

## If You Can't Fix It

Report what you found:
```
## Error Investigation (Unresolved)
- **Error:** [description]
- **Investigated:** [what you checked]
- **Hypotheses:** [possible causes ranked by likelihood]
- **Blocked By:** [what prevented the fix]
- **Suggested Next Step:** [what a human should try]
```
