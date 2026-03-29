---
name: "animations"
description: "Use when implementing or debugging animations. Covers containment, modifier order, GPU transforms, timing curves, transitions, phase/keyframe."
---

# Animation Safety

Use this guide when implementing or debugging animations.

## Containment (CRITICAL)
Animated content inside a container MUST NOT overflow its parent. Apply on the PARENT:
```swift
CardContainer {
    AnimatedContent()
        .transition(.scale.combined(with: .opacity))
}
.compositingGroup()
.clipped()
```

- `.compositingGroup()` flattens child layers into one pass
- `.clipped()` clips to parent frame
- Together they guarantee zero visual overflow during any animation phase
- Do NOT use `.drawingGroup()` — rasterizes via Metal, wastes memory
- Do NOT rely on `.scaleEffect(1)` hack — fragile and undocumented

### When to Apply
- Any view with `.transition()` inside a sized container
- Spring/bouncy animations that may overshoot bounds
- Phase/keyframe animations that scale or offset children
- ScrollView items with animated insertion/removal

### When NOT Needed
- Full-screen views with no parent boundary
- Opacity-only animations
- System navigation transitions

## Modifier Order
```swift
// CORRECT — animation AFTER layout, containment on parent
VStack {
    content
        .offset(y: animating ? -20 : 0)
        .opacity(animating ? 0 : 1)
        .animation(.spring(duration: 0.4), value: animating)
}
.compositingGroup()
.clipped()
```

## Prefer GPU Transforms
Use `.scaleEffect`, `.offset`, `.rotationEffect`, `.opacity` — GPU-accelerated, no layout pass.
Avoid animating `.frame`, `.padding`, `.font` — triggers full layout recalculation.

## Timing Curves
| Curve | Use Case |
|-------|----------|
| `.spring(duration: 0.3)` | Default for most UI |
| `.spring(duration: 0.4, bounce: 0.3)` | Playful emphasis |
| `.easeInOut(duration: 0.25)` | Subtle transitions |
| `.bouncy` | Intentional delight only |

Keep durations under 0.5s for responsive feel.

## Animation Scope
```swift
// CORRECT — scoped to specific value
.animation(.easeInOut(duration: 0.2), value: isSelected)

// WRONG — unscoped, animates everything
.animation(.easeInOut)
```
- Bind `.animation` to a specific value — NEVER use without value parameter
- Use `withAnimation` for user-triggered changes
- Use `.animation(_:value:)` for derived/computed changes

## Transitions
Place `withAnimation` or `.animation` OUTSIDE the conditional:
```swift
withAnimation(.spring(duration: 0.3)) {
    showDetail.toggle()
}
if showDetail {
    DetailView()
        .transition(.opacity.combined(with: .move(edge: .bottom)))
}
```

## Phase and Keyframe (iOS 17+)
```swift
PhaseAnimator([false, true]) { phase in
    Icon()
        .scaleEffect(phase ? 1.1 : 1.0)
        .opacity(phase ? 1.0 : 0.7)
}
.compositingGroup()
.clipped()
```
