---
name: "crash"
description: "Use when a runtime crash occurs, the app crashes on a specific screen, or the user reports an EXC_BREAKPOINT / signal abort. Runs automated smoke tests first, then investigates with crash logs and backtraces."
---

# Runtime Crash Investigation

Automated crash detection and resolution for iOS apps.

## Quick Start

When the user reports a crash ("the app crashes when...") or you need to verify stability:

1. **Run the smoke walker test** — this walks every screen automatically
2. **If test fails** — you have the exact crash point, skip to Step 4
3. **If test passes** — the crash is flow-specific, investigate manually

## Step 1: Run Automated Smoke Tests

Use Xcode MCP to run the smoke walker:

```
mcp__xcode__RunSomeTests with:
  targetName: "<AppName>UITests"
  testIdentifier: "SmokeWalkerTest"
```

Or run a specific test if you suspect a particular flow:
- `SmokeWalkerTest/testFullLoggingFlow` — full 4-step logging
- `SmokeWalkerTest/testQuickSaveFlow` — quick save from severity
- `SmokeWalkerTest/testStepNavigation` — back/forward between steps
- `SmokeWalkerTest/testMigraineDetailAndEdit` — detail view + edit mode

If the smoke walker test target doesn't exist yet, see the **Setup** section below.

## Step 2: Parse Test Results

If a test fails, the Xcode MCP response includes:
- **Which test method failed** — tells you which screen/flow crashed
- **The assertion message** — tells you what was expected vs what happened
- **If it's a crash** — no assertion, the app terminated unexpectedly

Map the failing test to the screen:
| Test Method | Screen | Flow |
|---|---|---|
| `testHomeScreenLoads` | Home | App launch |
| `testFullLoggingFlow` | LogAttackSheet | Step-by-step logging |
| `testQuickSaveFlow` | LogAttackSheet | Quick save from step 1 |
| `testStepNavigation` | LogAttackSheet | Forward/back navigation |
| `testDismissLogSheet` | LogAttackSheet | Sheet dismiss |
| `testSettingsOpens` | SettingsSheet | Settings display |
| `testHistoryOpens` | HistoryView | History display |
| `testMigraineDetailAndEdit` | MigraineDetailSheet | Detail + edit |

## Step 3: Harvest Crash Logs

After a test crash, check for crash logs:

```bash
find ~/Library/Logs/DiagnosticReports -name "*<AppName>*" -newer /tmp/.last_test_run -type f 2>/dev/null | head -5
```

If found, read the crash log and extract:
1. **Exception type** — EXC_BREAKPOINT, EXC_BAD_ACCESS, SIGABRT
2. **Crashing thread name** — main, AsyncRenderer, background
3. **First app frame** — the first stack frame in YOUR code (not Apple frameworks)

## Step 4: Classify the Crash

| Crashing Thread | First App Frame Pattern | Category |
|---|---|---|
| `AsyncRenderer` | `Color.init`, `AppTheme` | `runtime/async-render` |
| `AsyncRenderer` | `_swift_task_checkIsolatedSwift` | `runtime/actor-isolation` |
| Main thread | Force unwrap, `!` | `runtime/nil-unwrap` |
| Main thread | `Index out of range` | `runtime/index-out-of-bounds` |
| Main thread | `ModelContext` | `runtime/swiftdata-thread` |
| Any | View transition / animation | `runtime/navigation` |
| Any | Observation, `@Observable` | `runtime/observation` |

## Step 5: Log to Error Ledger

Append to `.claude/errors/errors.md`:

```markdown
## [UNRESOLVED] <timestamp> — Runtime Crash: <brief description>

- **Error:** `<exception type + signal>`
- **File:** `<first app frame file:line>`
- **Category:** `runtime/<subcategory>`
- **Symptom:** <what the user saw or which test failed>
- **Crashing Thread:** `<thread name>`
- **First App Frame:** `<symbol>`
- **Root Cause:** _Pending investigation_
- **Fix:** _Pending_
- **Session:** `${CLAUDE_SESSION_ID}`
```

## Step 6: Investigate and Fix

Follow the `/debugging` skill methodology:
1. Read the file at the first app frame
2. Check error ledger history for matching patterns
3. If match → apply known fix
4. If no match → isolate by simplifying the crashing view
5. Fix root cause, rebuild, rerun the failing test
6. Update ledger to `[RESOLVED]`

## Step 7: Verify

Rerun the specific failing test:
```
mcp__xcode__RunSomeTests with:
  testIdentifier: "SmokeWalkerTest/testFullLoggingFlow"
```

Then run ALL smoke tests to ensure no regressions:
```
mcp__xcode__RunSomeTests with:
  testIdentifier: "SmokeWalkerTest"
```

## Setup: Adding Smoke Tests to a New Project

If no UI test target exists:

### 1. Add to `project.yml`

```yaml
  <AppName>UITests:
    type: bundle.ui-testing
    platform: iOS
    supportedDestinations:
      - iOS
    sources:
      - path: <AppName>UITests
        type: syncedFolder
    settings:
      base:
        SWIFT_VERSION: "6.0"
        GENERATE_INFOPLIST_FILE: YES
        PRODUCT_BUNDLE_IDENTIFIER: com.example.uitests
        CODE_SIGN_STYLE: Automatic
        SWIFT_APPROACHABLE_CONCURRENCY: YES
        SWIFT_DEFAULT_ACTOR_ISOLATION: MainActor
    dependencies:
      - target: <AppName>
```

### 2. Create test directory and file

```bash
mkdir -p <AppName>UITests
```

Create `SmokeWalkerTest.swift` that:
- Launches the app with `--uitesting` argument
- Sets `continueAfterFailure = false`
- Walks through every major screen using accessibility identifiers
- Taps interactive elements
- Verifies screens render (elements exist)

### 3. Add accessibility identifiers to views

Add `.accessibilityIdentifier("name")` to key interactive elements:
- Navigation buttons (log, settings, history)
- Form buttons (next, save, back, close)
- List rows (indexed: `row_0`, `row_1`)
- Trigger/selection chips (named: `trigger_stress`)

Naming convention: `<screen>_<element>` in snake_case.

### 4. Regenerate Xcode project

```
mcp__xcodegen__regenerate_project
```

## Rules

- **Always run smoke tests first** — don't guess, let the test find the crash
- **Trust test failure location** — the failing test method IS the crashing screen
- **Log every crash to errors.md** — even if you fix it immediately
- **Rerun tests after fix** — verify no regressions
- **Never skip the ledger** — every crash feeds the learning system
