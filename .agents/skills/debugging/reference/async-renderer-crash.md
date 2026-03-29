# AsyncRenderer Color Crash — Full Investigation

## What We Saw

The user flow:
- step 0 → 1 worked
- step 1 → 2 worked
- step 2 → 3 crashed after tapping Next on gender

Logs proved `goNext()` itself was not failing:
- `goNext: step 2 → 3`
- `Displayed onboarding step 3 (frequency)`
- `Frequency step appeared with selection: nil`

This meant:
- Navigation state changed successfully
- The frequency screen started rendering
- The crash happened during or just after render, not in the button tap handler

## Why It Was Confusing

The exception was:
```
com.apple.SwiftUI.AsyncRenderer: EXC_BREAKPOINT
libdispatch.dylib `_dispatch_assert_queue_fail`
```

This kind of crash often looks unrelated to the actual UI screen because SwiftUI renders parts of the view tree on its async renderer thread. The visible symptom was "gender step crashes on next," but the real fault was something the frequency screen caused SwiftUI to resolve during rendering.

## How We Investigated

We narrowed it down in stages:

1. Added logs around onboarding navigation and rendering
2. Logs showed the crash happened after step 3 was already active
3. Simplified the frequency screen aggressively (removed animation, complex styling, reduced to basic list)
4. The crash still happened — issue was NOT the business logic
5. Captured the symbolic backtrace from the actual crashing thread (`com.apple.SwiftUI.AsyncRenderer`)

The critical frames were:
```
_dispatch_assert_queue_fail
_swift_task_checkIsolatedSwift
closure #1 in Color.init(... dark="3A3A3C", light="EBEBEB")
AppTheme.swift
UIDynamicProviderColor _resolvedColorWithTraitCollection
SwiftUI Color._apply(to:)
```

## Actual Root Cause

The app theme defined colors using a custom dynamic UIKit-backed provider:

```swift
init(light: String, dark: String) {
    self.init(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(Color(hex: dark)) : UIColor(Color(hex: light))
    })
}
```

Several theme colors depended on it: `background`, `surface`, `surfaceLight`.

The theme also used UIKit semantic colors: `Color(.label)`, `Color(.secondaryLabel)`, `Color(.tertiaryLabel)`.

When SwiftUI rendered the frequency step on `com.apple.SwiftUI.AsyncRenderer`, it tried to resolve one of those dynamic colors off the main/UI queue. That resolution path touched UIKit/concurrency isolation in a way that triggered `_dispatch_assert_queue_fail`.

## Fixes We Tried Before Finding the Root Cause

- Simplified onboarding transitions from slide+opacity to opacity
- Removed nested `withAnimation` calls
- Added render-level step logging
- Removed `@Bindable` model usage from step boundary, passed plain values/callbacks

These were reasonable stabilizing changes but did NOT solve the core crash.

## The Real Fix

Changed the theme to use plain SwiftUI-safe static colors:

**Before (UNSAFE):**
```swift
static let background = Color(light: "FFFFFF", dark: "1C1C1E")
static let textPrimary = Color(.label)
static let textSecondary = Color(.secondaryLabel)
```

**After (SAFE):**
```swift
static let background = Color(hex: "FFFFFF")
static let textPrimary = Color(hex: "111111")
static let textSecondary = Color(hex: "6B7280")
```

Also changed `Color.init(light:dark:)` so it no longer builds a dynamic UIColor provider.

## Why That Fixed It

SwiftUI no longer had to execute a UIKit dynamic color closure during async rendering. The renderer only applied plain SwiftUI color values, which is safe on the async renderer path.

## Key Diagnostic Signal

The single most important clue was this stack line:
```
closure #1 in Color.init(... dark="3A3A3C", light="EBEBEB") — AppTheme.swift
```

## Lesson

This was a misleading SwiftUI runtime failure:
- **Symptom:** onboarding crashes after gender step
- **Apparent suspect:** navigation or state model
- **Actual cause:** theme color resolution during async render

The reliable diagnostic path:
1. Add logs → prove where in the flow it crashes
2. Get the symbolic stack from the **actual crashing thread**
3. Trust the **first app frame** in the backtrace
4. Simplify or remove that code path
