---
name: "feedback-states"
description: "Use when implementing loading, error, empty, or success states. Covers Loadable switch handling, mutation buttons, loading indicators."
---

# Feedback States

Use this guide when implementing loading, error, empty, and success states.

## MANDATORY: Handle All 4 Loadable States
Every view displaying async data MUST `switch` on `Loadable<T>`:
```swift
switch viewModel.items {
case .notInitiated, .loading:
    ProgressView("Loading...")
case .success(let items) where items.isEmpty:
    ContentUnavailableView("No Items Yet", systemImage: "tray",
        description: Text("Tap + to create your first item"))
case .success(let items):
    List(items) { item in ItemRow(item: item) }
case .failure(let error):
    ContentUnavailableView {
        Label("Load Failed", systemImage: "exclamationmark.triangle")
    } description: {
        Text(error.localizedDescription)
    } actions: {
        Button("Retry") { Task { await viewModel.loadItems() } }
    }
}
```
NEVER use `if let` to unwrap only success — all 4 states must be handled.

## Mutation Button Pattern
Every mutation button (save, delete) MUST disable while loading and show inline spinner:
```swift
Button {
    Task { await viewModel.save() }
} label: {
    if viewModel.saveState.isLoading {
        ProgressView().controlSize(.small)
    } else {
        Text("Save")
    }
}
.disabled(viewModel.saveState.isLoading)
```

## Loading Patterns
| Pattern | Use Case | Code |
|---------|----------|------|
| Inline spinner | Button action | `ProgressView().controlSize(.small)` |
| Full-screen | Initial load | `ProgressView("Loading...")` |
| Pull-to-refresh | List refresh | `.refreshable { await refresh() }` |
| Skeleton | Content placeholder | `.redacted(reason: .placeholder)` |
| Overlay | Blocking operation | `.overlay { if loading { ProgressView() } }` |

## Error Handling UI
1. **Inline validation** — show immediately below form fields
2. **Alert** — for blocking errors (network failure, permission denied)
3. **Banner** — for non-critical errors (sync failed, partial data)

Always provide a retry path — never leave users stuck.

## Success Feedback
- Haptic: `UINotificationFeedbackGenerator().notificationOccurred(.success)`
- Visual: brief animation (checkmark, scale bounce)
- NEVER use modal alert for success — too disruptive

## Disabled State
- `.disabled(condition)` — SwiftUI auto-handles opacity
- Always explain WHY disabled (caption text below button)
- Don't hide actions — show them disabled with explanation

## Rules
- Show indicator for operations > 300ms
- ALWAYS disable triggering button while loading
- Never block entire UI for partial operation — use inline spinner
- Use `Loadable<T>` for all async state — never `var isLoading: Bool`
