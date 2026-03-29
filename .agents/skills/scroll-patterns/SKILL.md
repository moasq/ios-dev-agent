---
name: "scroll-patterns"
description: "Use when implementing scroll-based UI. Covers programmatic scrolling, position tracking, visual effects, parallax, paging, snap-to-item."
---

# ScrollView Patterns

Use this guide when implementing or modifying scroll-based UI.

## Scroll Indicators
```swift
// CORRECT — modifier
ScrollView { content }
    .scrollIndicators(.hidden)

// AVOID — legacy initializer
ScrollView(showsIndicators: false) { content }
```

## ScrollViewReader (Programmatic Scrolling)
```swift
ScrollViewReader { proxy in
    ScrollView {
        LazyVStack {
            ForEach(messages) { message in
                MessageRow(message: message).id(message.id)
            }
            Color.clear.frame(height: 1).id("bottom")
        }
    }
    .onChange(of: messages.count) { _, _ in
        withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
    }
}
```

## Scroll Position Tracking
Gate by threshold to avoid excessive re-renders:
```swift
.onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
    if value < -100 { startAnimation = true }
    else { startAnimation = false }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
```

## Scroll-Based Visual Effects (iOS 17+)
```swift
ItemCard(item: item)
    .visualEffect { content, geometry in
        let frame = geometry.frame(in: .scrollView)
        let distance = min(0, frame.minY)
        return content.opacity(1 + distance / 200)
    }
```

## Parallax Effect
```swift
Image("hero")
    .resizable()
    .aspectRatio(contentMode: .fill)
    .frame(height: 300)
    .visualEffect { content, geometry in
        let offset = geometry.frame(in: .scrollView).minY
        return content.offset(y: offset > 0 ? -offset * 0.5 : 0)
    }
    .clipped()
```

## Paging (iOS 17+)
```swift
ScrollView(.horizontal) {
    LazyHStack(spacing: 0) {
        ForEach(pages) { page in
            PageView(page: page).containerRelativeFrame(.horizontal)
        }
    }
    .scrollTargetLayout()
}
.scrollTargetBehavior(.paging)
```

## Snap to Items
```swift
ScrollView(.horizontal) {
    LazyHStack(spacing: 16) {
        ForEach(items) { item in
            ItemCard(item: item).frame(width: 280)
        }
    }
    .scrollTargetLayout()
}
.scrollTargetBehavior(.viewAligned)
.contentMargins(.horizontal, 20)
```
