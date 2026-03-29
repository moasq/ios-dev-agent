---
name: "scaffold"
description: "Use when creating a new iOS project from scratch. Generates directory structure, project.yml, AppTheme, Loadable, and Xcode project via xcodegen."
---

# Scaffold New Project

Creates a complete iOS project from scratch with the standard MVVM architecture.

## Quick Start

```bash
bash "$CLAUDE_PROJECT_DIR/.claude/scripts/scaffold-project.sh" "AppName" "com.company.appname"
```

## What It Creates

```
AppName/
├── App/                → @main entry + ContentView
├── Models/             → Data models with sampleData
├── Features/Common/    → Shared reusable views
├── Theme/              → AppTheme.swift (Colors, Fonts, Spacing)
├── Services/           → Domain services
├── Shared/             → Loadable.swift
└── Resources/          → Assets.xcassets, Info.plist
```

Plus: `project.yml`, `.xcodeproj` (via xcodegen), `.gitignore`, initial git commit.

## Post-Scaffold Steps

1. **Add packages:** Use `mcp__xcodegen__add_package` to add SPM dependencies
2. **Add permissions:** Use `mcp__xcodegen__add_permission` for Info.plist entries
3. **Add entitlements:** Use `mcp__xcodegen__add_entitlement` for capabilities
4. **Customize theme:** Edit `AppName/Theme/AppTheme.swift` with your color palette
5. **Build:** `bash .claude/scripts/xcode-build.sh`

## Project Settings (Xcode 16.3)

The scaffold generates a `project.yml` targeting:
- Swift 6 with strict concurrency
- iOS 26.0 deployment target
- MainActor default isolation
- Approachable concurrency enabled

For settings xcodegen doesn't cover, use:
```
mcp__xcodegen__set_build_setting with key and value
```

## Reference

- [project-template.md](reference/project-template.md) — full project.yml template
- [directory-structure.md](reference/directory-structure.md) — directory conventions
