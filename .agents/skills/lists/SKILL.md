---
name: "lists"
description: "Use when implementing list-based UI. Covers ForEach identity, swipe actions, pull-to-refresh, custom styling, enumerated sequences."
---

# List Patterns

Use this guide when implementing or modifying list-based UI.

## ForEach Identity (CRITICAL)
Always provide stable identity. Never use `.indices` for dynamic content:
```swift
// CORRECT — stable identity via Identifiable
ForEach(users) { user in
    UserRow(user: user)
}

// CORRECT — stable identity via keypath
ForEach(users, id: \.userId) { user in
    UserRow(user: user)
}

// WRONG — indices create static content, crashes on removal
ForEach(users.indices, id: \.self) { index in
    UserRow(user: users[index])
}
```

## Constant View Count per Element
```swift
// CORRECT — consistent view count
ForEach(items) { item in
    ItemRow(item: item)
}

// WRONG — variable view count breaks identity
ForEach(items) { item in
    if item.isSpecial {
        SpecialRow(item: item)
        DetailRow(item: item)
    } else {
        RegularRow(item: item)
    }
}
```

## Avoid Inline Filtering
```swift
// WRONG — unstable identity
ForEach(items.filter { $0.isEnabled }) { item in ... }

// CORRECT — prefilter via computed property
var enabledItems: [Item] {
    items.filter { $0.isEnabled }
}
ForEach(enabledItems) { item in ... }
```

## No AnyView in Rows
```swift
// WRONG — hides identity
AnyView(item.isSpecial ? SpecialRow(item: item) : RegularRow(item: item))

// CORRECT — unified row view with internal branching
struct ItemRow: View {
    let item: Item
    var body: some View {
        if item.isSpecial { SpecialRow(item: item) }
        else { RegularRow(item: item) }
    }
}
```

## Enumerated Sequences
Always convert to array:
```swift
ForEach(Array(items.enumerated()), id: \.offset) { index, item in
    Text("\(index): \(item)")
}
```

## Pull-to-Refresh
```swift
List(items) { item in
    ItemRow(item: item)
}
.refreshable { await loadItems() }
```

## Custom List Styling
```swift
List(items) { item in
    ItemRow(item: item)
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        .listRowSeparator(.hidden)
}
.listStyle(.plain)
.scrollContentBackground(.hidden)
```
