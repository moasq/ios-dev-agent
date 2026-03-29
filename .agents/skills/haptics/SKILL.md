---
name: "haptics"
description: "Use when adding tactile feedback. Covers UIImpactFeedbackGenerator, UINotificationFeedbackGenerator, CoreHaptics custom patterns."
---

# Haptic Feedback

Use this guide when adding tactile feedback to interactions.

## Quick Reference

### Impact Feedback (taps, collisions)
```swift
UIImpactFeedbackGenerator(style: .medium).impactOccurred()
```
Styles: `.light`, `.medium`, `.heavy`, `.soft`, `.rigid`

### Notification Feedback (outcomes)
```swift
UINotificationFeedbackGenerator().notificationOccurred(.success)
```
Types: `.success`, `.warning`, `.error`

### Selection Feedback (picker changes)
```swift
UISelectionFeedbackGenerator().selectionChanged()
```

## Best Practices
- Call `generator.prepare()` before use for lower latency
- Check hardware support: `CHHapticEngine.capabilitiesForHardware().supportsHaptics`
- Use `.light` for subtle confirmations, `.medium` for standard taps, `.heavy` for emphasis
- Use `.success` for completed actions, `.warning` for caution, `.error` for failures

## CoreHaptics (Custom Patterns)
```swift
import CoreHaptics

let engine = try CHHapticEngine()
try engine.start()

let event = CHHapticEvent(
    eventType: .hapticTransient,
    parameters: [
        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
    ],
    relativeTime: 0
)

let pattern = try CHHapticPattern(events: [event], parameters: [])
let player = try engine.makePlayer(with: pattern)
try player.start(atTime: 0)
```

## When to Use
| Action | Haptic |
|--------|--------|
| Button tap | `.light` impact |
| Toggle switch | Selection changed |
| Delete action | `.warning` notification |
| Save success | `.success` notification |
| Slider snap | Selection changed |
| Error state | `.error` notification |
