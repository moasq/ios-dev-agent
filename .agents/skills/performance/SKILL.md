---
name: "performance"
description: "Use when optimizing or debugging performance. Covers redundant state updates, POD views, task cancellation, view extraction, layout thrash."
---

# Performance Optimization

Use this guide when optimizing or debugging performance issues.

## Avoid Redundant State Updates
```swift
// WRONG — triggers update even if value unchanged
.onReceive(publisher) { value in
    self.currentValue = value
}

// CORRECT — only update when different
.onReceive(publisher) { value in
    if self.currentValue != value {
        self.currentValue = value
    }
}
```

## Pass Only What Views Need
```swift
// CORRECT — narrow dependency
struct ItemRow: View {
    let item: Item
    let themeColor: Color
    var body: some View {
        Text(item.name).foregroundStyle(themeColor)
    }
}
```

## POD Views for Fast Diffing
POD (Plain Old Data) views use `memcmp` for fastest diffing — only simple value types, no property wrappers:
```swift
struct FastView: View {
    let title: String
    let count: Int
    var body: some View { Text("\(title): \(count)") }
}
```

## Task Cancellation
```swift
List(data) { item in Text(item.name) }
.task {
    data = await fetchData()  // Auto-cancelled on disappear
}
```

## AsyncImage Best Practices
```swift
AsyncImage(url: imageURL) { phase in
    switch phase {
    case .empty: ProgressView()
    case .success(let image):
        image.resizable().aspectRatio(contentMode: .fit)
    case .failure:
        Image(systemName: "photo").foregroundStyle(.secondary)
    @unknown default: EmptyView()
    }
}
.frame(width: 200, height: 200)
```

## Layout Performance
- Avoid deep nesting — flatten view hierarchies
- Minimize `GeometryReader` — use `containerRelativeFrame` on iOS 17+
- Gate frequent geometry updates by threshold:
```swift
.onPreferenceChange(ViewSizeKey.self) { size in
    let diff = abs(size.width - currentSize.width)
    if diff > 10 { currentSize = size }
}
```

## View Extraction
Extract subviews as **separate structs**, not `@ViewBuilder` computed properties:
```swift
// CORRECT — body SKIPPED when inputs don't change
struct ComplexSection: View {
    var body: some View { ... }
}

// WRONG — re-executes on every parent state change
@ViewBuilder func complexSection() -> some View { ... }
```
