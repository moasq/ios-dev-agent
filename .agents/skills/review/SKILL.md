---
name: "review"
description: "Use when reviewing code quality or auditing accessibility. Covers quality-review workflow, accessibility-audit workflow, structured report output format."
---

# Review Workflow

Use this skill when reviewing generated project quality or running a focused accessibility audit.

Read the relevant guide for your task:
- [quality-review.md](reference/quality-review.md) — project quality gate review workflow
- [accessibility-audit.md](reference/accessibility-audit.md) — code-first accessibility audit workflow
- [output-format.md](reference/output-format.md) — required structured Markdown report format

Scope boundaries:
- This skill is for auditing/reporting, not implementation details.
- For accessibility implementation patterns in SwiftUI, consult the `/accessibility` skill.

## Trigger Cues
Use this skill when requests mention: `review`, `audit`, `accessibility`, `quality`, `findings`.

## Applicability
Primary targets: `ios`, `swiftui`.

## Quick Checklist
1. Read all Swift files in the project
2. Check against the quality-review or accessibility-audit guide
3. Output findings using the structured report format
4. Flag severity levels: critical, major, minor, suggestion
