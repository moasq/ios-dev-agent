---
name: "consolidate-errors"
description: "Use after errors are resolved to feed fixes back into rules and skills. Reads .claude/errors/errors.md, diagnoses knowledge gaps, and updates the relevant rule or skill to prevent recurrence."
---

# Consolidate Errors

Analyze resolved errors and update rules/skills to prevent recurrence.

## When to Use

Run this after one or more errors have been resolved (marked `[RESOLVED]` in the error ledger). This skill reads the resolutions, checks what existing rules/skills should have prevented the error, and patches the gap.

## Workflow

### 1. Read Resolved Errors

```
Read .claude/errors/errors.md
```

Find entries marked `[RESOLVED]` (not yet `[CONSOLIDATED]`).

### 2. For Each Error, Diagnose the Knowledge Gap

Search existing rules and skills for coverage:

```
Grep .claude/rules/ for keywords from the error
Grep .claude/skills/ for keywords from the error
```

Determine which case applies:

| Case | Situation | Action |
|---|---|---|
| **A** | Rule already covers this exact pattern | No change — mark `[CONSOLIDATED]` with "coverage sufficient" |
| **B** | Rule exists but misses this variant | Add the variant to the existing rule |
| **C** | Skill covers the topic but not this pattern | Add to skill body or create a reference/ file |
| **D** | Skill exists but description doesn't trigger | Update skill description to include error keywords |
| **E** | No coverage anywhere | Add to `/debugging` skill's known crash patterns |
| **F** | Rules/skills contradict each other | Flag for human review — DO NOT auto-fix |

### 3. Apply Updates

For each change:
- Read the target file fully before editing
- Make the **minimal change** — add a warning, extend a table, update keywords
- Never remove existing content
- Trace the change: `<!-- Error ledger: YYYY-MM-DD description -->`

### 4. Update the Ledger

Change `[RESOLVED]` to `[CONSOLIDATED]` and add:
- **Consolidated To:** file path(s) that were updated
- **Change Type:** Case A/B/C/D/E/F

### 5. Report

```
## Consolidation Report

### Processed: [count] resolved errors

| Error | Case | Action | File Updated |
|---|---|---|---|
| [description] | [A-F] | [what was done] | [path or "none"] |

### Coverage Health
- Total errors in ledger: [count]
- Consolidated: [count]
- Unresolved: [count]
- Recurring patterns: [any category appearing 3+ times]
```

## Examples of Good Consolidation

**Case B — Rule variant added:**
Error: UIKit dynamic color provider crashed on AsyncRenderer.
Rule `design-system.md` already bans hardcoded colors, but didn't warn about UIColor closures.
→ Added: "NEVER use `UIColor { traits in }` dynamic providers for theme colors — they crash on AsyncRenderer thread."

**Case D — Skill description updated:**
Error: ForEach identity crash, but `/lists` skill wasn't auto-loaded.
→ Updated lists skill description: added "ForEach crash" and "index out of bounds" keywords.

**Case C — Reference added to skill:**
Error: New SwiftData migration crash pattern.
→ Added `skills/storage/reference/migration-patterns.md` documenting the crash and fix.

**Case A — No change needed:**
Error: Hardcoded `.padding(20)` caught by build review.
Rule `design-system.md` already explicitly bans this exact pattern.
→ Marked `[CONSOLIDATED]` — coverage was sufficient, developer just missed it.

## Rules

- **Never create new rule files** — update existing ones
- **Never remove content** — only add or clarify
- **Minimal changes** — one line is better than a paragraph
- **Flag contradictions** — Case F goes to human, always
- **Trace changes** — every edit links back to the error
