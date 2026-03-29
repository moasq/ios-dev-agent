---
name: "accessibility"
description: "Use when implementing or auditing accessibility. Covers VoiceOver labels, Dynamic Type, Reduce Motion, color contrast, focus management."
---

# Accessibility

Use this guide when implementing or auditing accessibility features.

## Reduce Motion
```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.3)) {
    // state change
}
.transition(reduceMotion ? .opacity : .slide)
```
When enabled: replace `.spring()` with `.easeInOut(duration: 0.2)`, replace slide transitions with `.opacity`, disable auto-playing animations, keep functional animations (progress bars).

## Reduce Transparency
```swift
@Environment(\.accessibilityReduceTransparency) var reduceTransparency

.background(reduceTransparency ? Color(AppTheme.Colors.surface) : .ultraThinMaterial)
```

## VoiceOver Labels
- All interactive elements: `.accessibilityLabel("descriptive text")`
- Non-obvious actions: `.accessibilityHint("Double tap to delete this item")`
- Decorative images: `.accessibilityHidden(true)`
- Informative images: `.accessibilityLabel("Profile photo of John")`
- Icon-only buttons MUST have `.accessibilityLabel()`
```swift
Button(action: addItem) {
    Image(systemName: "plus")
}
.accessibilityLabel("Add new item")
```

## Grouping & Combining
```swift
HStack {
    Image(systemName: "heart.fill")
    Text("Favorites")
    Spacer()
    Text("12")
}
.accessibilityElement(children: .combine)
```
- Related content (icon + label + value): `.accessibilityElement(children: .combine)`
- Custom read order: `.accessibilityElement(children: .ignore)` + manual `.accessibilityLabel`

## Accessibility Traits
- Section headers: `.accessibilityAddTraits(.isHeader)`
- Media playback: `.accessibilityAddTraits(.startsMediaSession)`
- Summary values: `.accessibilityAddTraits(.isSummaryElement)`
- Selected items: `.accessibilityAddTraits(.isSelected)`

## Focus Management
```swift
enum Field: Hashable { case name, email, password }
@FocusState private var focusedField: Field?

TextField("Name", text: $name)
    .focused($focusedField, equals: .name)
    .submitLabel(.next)
    .onSubmit { focusedField = .email }
```

## Dynamic Type
- System text styles (`.body`, `.headline`) scale automatically
- NEVER use `.font(.system(size:))` — opts out of Dynamic Type
- Use `.minimumScaleFactor(0.8)` only as last resort for layout overflow
- Wrap in `ScrollView` for content that may overflow at large sizes

## Color & Contrast
- Don't use color alone for status — always pair with icon + text
- Minimum 4.5:1 contrast for normal text, 3:1 for large text
- Use `.foregroundStyle(.secondary)` for de-emphasized text (maintains adaptive contrast)

## Custom Controls
- Custom sliders/steppers: `.accessibilityValue()`, `.accessibilityAdjustableAction()`
- Custom toggles: `.accessibilityAddTraits(.isToggle)`, `.accessibilityValue(isOn ? "on" : "off")`
- Progress indicators: `.accessibilityValue("\(Int(progress * 100)) percent")`
