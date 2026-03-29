---
name: "skill-authoring"
description: "Use when creating, editing, or reviewing skills in .claude/skills/. Covers Anthropic SKILL.md format, frontmatter rules, reference/ subdirectories, validation."
---

# Skill Authoring Guide

## Anthropic Skill Format

Every skill is a directory containing `SKILL.md` with YAML frontmatter:

```yaml
---
name: my-skill-name
description: "Use when [specific trigger condition]. [What this skill provides]."
---

# Skill Body

Instructions and rules here...
```

## Frontmatter Rules

- **name**: kebab-case, `^[a-z0-9-]{1,64}$`, must not contain "anthropic" or "claude"
- **description**: 1–1024 characters, must include "Use when" clause, no XML/HTML markup
- **Only `name` and `description`** are required in frontmatter

### Optional Frontmatter Fields

| Field | Type | Purpose |
|-------|------|---------|
| `disable-model-invocation` | boolean | If true, only user can invoke (Claude cannot auto-load) |
| `user-invocable` | boolean | If false, hidden from `/` menu (background knowledge only) |
| `allowed-tools` | string | Comma-separated tools Claude can use: `"Read, Grep, Glob"` |
| `model` | string | Override model: `"opus"`, `"sonnet"` |
| `effort` | string | Override effort: `"low"`, `"medium"`, `"high"`, `"max"` |
| `context` | string | `"fork"` to run in isolated subagent context |
| `agent` | string | Subagent type when `context: fork`: `"Explore"`, `"Plan"`, custom |
| `hooks` | object | Hooks scoped to this skill's lifecycle |

## Body Rules

- Body must be < 500 lines
- No empty skill bodies
- Reference files go in `reference/` subdirectory (one level only)
- References > 100 lines should include a TOC/Contents heading in the first 30 lines

## Directory Structure

```
skills/
  <skill-name>/
    SKILL.md           # Required: entry point with frontmatter
    reference/          # Optional: detailed guides
      guide-1.md
      guide-2.md
```

Reference files are plain markdown — no frontmatter needed.

## String Substitutions

Use these variables in SKILL.md content:

| Variable | Description |
|----------|-------------|
| `$ARGUMENTS` | All arguments passed when invoking skill |
| `$ARGUMENTS[N]` | Nth argument by 0-based index |
| `${CLAUDE_SESSION_ID}` | Current session ID |
| `${CLAUDE_SKILL_DIR}` | Absolute path to skill's directory |

## Dynamic Context Injection

Use `` !`<command>` `` to run shell commands before Claude sees the content:

```yaml
---
name: pr-summary
---
## Context
- PR diff: !`gh pr diff`
- Changed files: !`gh pr diff --name-only`
```

## Invocation Modes

| Setting | User invoke | Claude invoke |
|---------|-------------|---------------|
| (default) | Yes | Yes |
| `disable-model-invocation: true` | Yes | No |
| `user-invocable: false` | No | Yes |

## Creating a New Skill

1. Create `skills/<skill-name>/SKILL.md`
2. Add YAML frontmatter with `name` and `description`
3. Write body (< 500 lines)
4. Add `reference/` subdirectory for supporting content if needed
5. Invoke via `/<skill-name>` to verify

## Scope Priority

Skills are discovered at multiple levels (highest priority first):
1. Enterprise (managed settings)
2. Personal (`~/.claude/skills/`)
3. Project (`.claude/skills/`)
4. Plugin (namespaced as `plugin-name:skill-name`)

Skills take precedence over legacy `.claude/commands/` files with the same name.
