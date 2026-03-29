---
name: "storage"
description: "Use when implementing data storage. Covers in-memory with sample data, @AppStorage, SwiftData persistence patterns."
---

# Storage Patterns

Use this guide when implementing or modifying data persistence.

## Default: In-Memory with Sample Data
Unless explicitly requested, use in-memory data with rich dummy data:

| Data Type | Storage | API |
|-----------|---------|-----|
| App data (items, records) | In-memory (DEFAULT) | Plain `struct`, `@Observable` arrays |
| Simple flags/settings | UserDefaults | `@AppStorage` |
| Transient UI state | In-memory | `@State` |

## In-Memory Models (Default)
```swift
struct Note: Identifiable {
    let id: UUID
    var title: String
    var content: String

    init(title: String, content: String = "") {
        self.id = UUID()
        self.title = title
        self.content = content
    }

    static let sampleData: [Note] = [
        Note(title: "Meeting Notes", content: "Discuss Q2 roadmap"),
        Note(title: "Recipe", content: "Eggs, pecorino, guanciale"),
    ]
}
```

## In-Memory ViewModel (Default)
```swift
@Observable @MainActor
class NotesViewModel {
    var notes: [Note] = Note.sampleData

    func addNote(title: String) {
        notes.insert(Note(title: title), at: 0)
    }

    func deleteNote(_ note: Note) {
        notes.removeAll { $0.id == note.id }
    }
}
```

## @AppStorage
```swift
@AppStorage("sortOrder") private var sortOrder = "date"
@AppStorage("showCompleted") private var showCompleted = true
```

## SwiftData (ONLY when user explicitly requests persistence)
Use `@Model`, `@Query`, `.modelContainer` ONLY if user says "save", "persist", "database", or "SwiftData":

```swift
import SwiftData

@Model
class Note {
    var title: String
    var content: String
    var createdAt: Date

    init(title: String, content: String = "") {
        self.title = title
        self.content = content
        self.createdAt = Date()
    }
}
```

App entry with container:
```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
        .modelContainer(for: Note.self)
    }
}
```
