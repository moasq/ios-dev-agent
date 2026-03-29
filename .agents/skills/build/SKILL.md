---
name: "build"
description: "Use when building the Xcode project, managing simulators, or diagnosing build failures. Covers xcodebuild commands, simulator selection, clean builds, and build flag reference."
---

# Build

Build the project for iOS Simulator.

## Quick Start

```bash
bash "$CLAUDE_PROJECT_DIR/.claude/scripts/xcode-build.sh"
```

## Options

```bash
# Clean build
bash .claude/scripts/xcode-build.sh --clean

# Specific device
bash .claude/scripts/xcode-build.sh --device "iPhone Air"

# Specific scheme
bash .claude/scripts/xcode-build.sh --scheme "MigrainAI"
```

## Available Simulators (iOS 26.4)

| Device | UDID |
|---|---|
| iPhone 17 Pro | BCDEE28F-9718-42CC-A78D-1F890D421702 |
| iPhone 17 Pro Max | 4497F487-B57E-4492-B7D9-CD59D5640DA3 |
| iPhone Air | F96B54FE-3D32-4EBF-B122-23A0CCDBF373 |
| iPhone 17 | A94318CF-7CCC-4C56-8EC9-3335BCA4B081 |
| iPhone 17e | 1596C7FE-DE81-4C51-B608-7F3123F5D03A |

## Common Build Failures

| Error | Cause | Fix |
|---|---|---|
| No .xcodeproj found | Project not generated | Run `xcodegen generate` |
| Cannot find type in scope | Missing import | Add `import Framework` |
| Actor-isolated property | Swift 6 concurrency | Add `@MainActor` or snapshot values |
| Ambiguous use of | Duplicate type | Remove duplicate declaration |
| Value of type has no member | Deprecated API | Check `/swiftui` reference |

## Error Integration

Build failures are automatically logged to `.claude/errors/errors.md` via hook.
Run `/fix-error` to investigate and resolve. Run `/consolidate-errors` to feed fixes back.

## Reference

- [build-flags.md](reference/build-flags.md) — xcodebuild flags and settings
- [simulator-management.md](reference/simulator-management.md) — simctl commands
