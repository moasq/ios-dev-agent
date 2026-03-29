---
name: "debugging"
description: "Use when diagnosing runtime crashes, SwiftUI render errors, concurrency violations, or unexpected behavior. Covers crash investigation methodology, Xcode debugging tools, LLDB debugging via XcodeBuildMCP, common iOS crash patterns, and the async renderer color crash."
---

# iOS Debugging & Crash Investigation

Use this guide when diagnosing runtime crashes, render errors, or unexpected behavior.

## MCP Debugging Tools (Unified Interface)

Two MCP servers provide debugging capabilities. Use whichever is available:

### XcodeBuildMCP (preferred for runtime debugging)
If `mcp__XcodeBuildMCP__*` tools are available, use them for LLDB:

```
1. Build:      mcp__XcodeBuildMCP__simulator__build
2. Launch:     mcp__XcodeBuildMCP__simulator__build_and_run
3. Attach:     mcp__XcodeBuildMCP__debugging__attach
4. Breakpoint: mcp__XcodeBuildMCP__debugging__breakpoint (set by file:line or function)
5. Inspect:    mcp__XcodeBuildMCP__debugging__evaluate (evaluate LLDB expressions)
6. Screenshot: mcp__XcodeBuildMCP__simulator__screenshot
7. Logs:       mcp__XcodeBuildMCP__simulator__logs
```

### Apple Xcode MCP (always available)
If only `mcp__xcode__*` tools are available:
```
1. Build:      mcp__xcode__BuildProject
2. Preview:    mcp__xcode__RenderPreview
3. Test:       mcp__xcode__RunSomeTests / RunAllTests
4. Issues:     mcp__xcode__XcodeListNavigatorIssues
5. Build log:  mcp__xcode__GetBuildLog
```

### Decision logic
- **Runtime crash?** → Use XcodeBuildMCP (LLDB attach + breakpoint + inspect)
- **Build error?** → Use either (both can build)
- **UI rendering issue?** → Use Apple MCP (RenderPreview)
- **Test failures?** → Use Apple MCP (RunSomeTests) or XcodeBuildMCP (simulator__test)

## Crash Investigation Methodology

Follow this exact sequence for any SwiftUI crash:

### Step 1: Add Strategic Logs
```swift
import OSLog
let logger = Logger(subsystem: "com.app.name", category: "debugging")

// Navigation transitions
logger.debug("goNext: step \(oldStep) → \(newStep)")

// View lifecycle
.onAppear { logger.debug("Displayed: \(viewName)") }

// State changes
logger.debug("State changed: \(String(describing: newValue))")
```

### Step 2: Prove WHERE It Crashes
- Navigation succeeded? Log shows the next step/screen was reached.
- Crash during render? `.onAppear` fires but view content fails to resolve.
- Crash in action handler? Log shows the button/action was triggered.

### Step 3: Get the Symbolic Backtrace
**From the actual crashing thread** — not Thread 1 (main).

In Xcode:
1. When crash occurs, check the Debug Navigator (left panel)
2. Select the crashing thread (often `com.apple.SwiftUI.AsyncRenderer`)
3. Read the stack frames from bottom to top
4. Find the **first app frame** — that's your root cause

### Step 4: Trust the First App Frame
The first frame in YOUR code (not Apple/system frames) is where the bug lives.

### Step 5: Simplify or Remove That Code Path
- Strip the suspected code to bare minimum
- If crash persists with minimal code, the issue is in initialization/resolution, not logic
- If crash disappears, add code back incrementally

## Known Crash Patterns

### AsyncRenderer Color Crash (CRITICAL)
See [reference/async-renderer-crash.md](reference/async-renderer-crash.md) for the full investigation.

**Pattern:** `EXC_BREAKPOINT` on `com.apple.SwiftUI.AsyncRenderer` with `_dispatch_assert_queue_fail`
**Cause:** UIKit dynamic color providers (`UIColor { traits in ... }`) resolved off main queue
**Fix:** Use static `Color(hex:)` instead of `Color(light:dark:)` with UIColor provider
**Key frame:** `UIDynamicProviderColor _resolvedColorWithTraitCollection`

### Swift 6 Concurrency Violations
**Pattern:** `EXC_BREAKPOINT` with `_swift_task_checkIsolatedSwift`
**Cause:** `@MainActor`-isolated code accessed from non-isolated context
**Fix:** Ensure all UI-bound state is `@MainActor`. Snapshot values before crossing isolation boundaries.

### SwiftData Thread Safety
**Pattern:** Crash on `ModelContext` access from background thread
**Cause:** `ModelContext` is not Sendable — must be used on the actor it was created on
**Fix:** Use `@ModelActor` for background contexts, `@MainActor` for UI contexts.

### ForEach Identity Crash
**Pattern:** Index out of bounds during list mutation
**Cause:** Using `.indices` or unstable identity with `ForEach`
**Fix:** Use `Identifiable` conformance or stable `id:` keypath.

## Xcode Debugging Tools

### Breakpoints
- **Exception Breakpoint**: Add in Breakpoint Navigator → catches all runtime exceptions
- **Symbolic Breakpoint**: `_dispatch_assert_queue_fail` — catches queue violations
- **Swift Error Breakpoint**: Catches all thrown Swift errors

### Instruments
- **SwiftUI template**: View body evaluation count, update triggers
- **Time Profiler**: CPU hotspots, main thread blocking
- **Allocations**: Memory leaks, zombie objects
- **Thread Sanitizer (TSan)**: Data race detection (enable in scheme → Diagnostics)

### Runtime Sanitizers (Scheme → Diagnostics)
| Sanitizer | Detects | Performance Cost |
|-----------|---------|-----------------|
| Thread Sanitizer | Data races, thread safety | 2-5x slowdown |
| Address Sanitizer | Buffer overflows, use-after-free | 2-3x slowdown |
| Undefined Behavior | Integer overflow, null deref | Minimal |
| Main Thread Checker | UIKit calls from background | Minimal |

**Always enable Main Thread Checker** — it catches exactly the kind of crash we hit with AsyncRenderer.

### Console & Logging
```swift
// Structured logging with OSLog
import OSLog

extension Logger {
    static let ui = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "ui")
    static let data = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "data")
    static let health = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "health")
}

// Usage
Logger.ui.debug("Rendering step \(step)")
Logger.data.error("Failed to save: \(error)")
```

Filter in Console.app: `subsystem:com.app.name category:ui`

## Debugging Without Xcode (CLI)

### Xcode build with sanitizers
```bash
xcodebuild test \
  -scheme MigrainAI \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -enableThreadSanitizer YES \
  -enableAddressSanitizer YES \
  2>&1 | xcbeautify
```

### Crash log symbolication
```bash
# Find crash logs
find ~/Library/Logs/DiagnosticReports -name "MigrainAI*" -type f

# Symbolicate
atos -arch arm64 -o MigrainAI.app/MigrainAI -l 0x100000000 0x100012345
```

### Simctl for simulator debugging
```bash
# Boot simulator
xcrun simctl boot "iPhone 16"

# Install app
xcrun simctl install booted MigrainAI.app

# Launch with console output
xcrun simctl launch --console booted com.app.MigrainAI

# Get crash logs from simulator
xcrun simctl diagnose
```

## Rules
- Always check the **crashing thread**, not main thread
- Trust the **first app frame** in the backtrace
- Enable **Main Thread Checker** as default
- Use `OSLog` (not `print()`) for production-safe debugging
- Simplify iteratively — remove code until crash stops, then add back
