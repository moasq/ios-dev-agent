---
name: "foundation-models"
description: "Use when implementing on-device AI features. Covers FoundationModels availability, text generation, streaming, @Generable structured output."
---

# Foundation Models (On-Device AI)

Use this guide when implementing or modifying on-device AI features.

## Framework
`import FoundationModels` — iOS 26+ only

## Availability Check (MANDATORY)
The model may not be available on all devices. Always check first:
```swift
guard SystemLanguageModel.default.isAvailable else {
    // Show "This feature requires Apple Intelligence" message
    return
}
```

## Basic Text Generation
```swift
let session = LanguageModelSession()
let response = try await session.respond(to: "Summarize this text: \(userText)")
print(response.content)  // String
```

## With System Instructions
```swift
let session = LanguageModelSession(
    instructions: "You are a helpful health assistant. Keep responses concise and empathetic."
)
let response = try await session.respond(to: prompt)
```

## Streaming Generation
```swift
let stream = session.streamResponse(to: prompt)
for try await partial in stream {
    displayText += partial.text
}
```

## Structured Output with @Generable
```swift
@Generable
struct RecipeSuggestion {
    @Guide(description: "Name of the dish") var name: String
    @Guide(description: "Estimated prep time in minutes") var prepTime: Int
    @Guide(description: "Main ingredients") var ingredients: [String]
}

let session = LanguageModelSession()
let recipe: RecipeSuggestion = try await session.respond(
    to: "Suggest a quick pasta dish",
    generating: RecipeSuggestion.self
)
```

## Guardrails
- Model output is filtered by Apple's safety system — some prompts may be refused
- No internet required — fully on-device
- Context window is limited (~4K tokens) — keep prompts concise
- Use `session.respond()` for single turns; keep `session` alive for multi-turn conversations
- Wrap in do/catch — generation can fail for safety or resource reasons

## Service Pattern
```swift
@MainActor @Observable
final class AIService {
    var isAvailable: Bool { SystemLanguageModel.default.isAvailable }

    func generate(prompt: String) async -> String? {
        guard isAvailable else { return nil }
        do {
            let session = LanguageModelSession(instructions: "...")
            let response = try await session.respond(to: prompt)
            return response.content
        } catch {
            return nil
        }
    }
}
```
