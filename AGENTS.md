# iOS Development Agent

Universal iOS development toolkit with 50+ skills, 8 agents, and MCP servers for Apple Developer authentication and RevenueCat.

## Tech Stack
- **Swift 6** / **iOS 26+** / **SwiftUI-first** / **Xcode 26**
- **SwiftData** for persistence, **WeatherKit**, **HealthKit**, **FoundationModels**
- **MVVM** with `@Observable` + `@MainActor` ViewModels
- **AppTheme** centralized design tokens (Colors, Fonts, Spacing)

## Rules
All rules in `rules/` are always active. Key conventions:
- No networking (URLSession, Alamofire) — apps work 100% offline
- No UIKit unless no SwiftUI equivalent exists
- No hardcoded colors/fonts/spacing — use AppTheme tokens
- SPM only (no CocoaPods/Carthage)
- SwiftData over CoreData
- `Loadable<T>` enum for all async state
- 150-line target per file, 200-line hard limit

## Skills
Skills in `.agents/skills/` provide on-demand expertise. Invoke with `/skill-name`.

## MCP Servers
- **apple-auth**: Apple Developer Portal authentication (SRP-6a + 2FA) + portal operations
- **revenuecat**: RevenueCat API validation + credential management

## Agents
Autonomous specialists in `.agents/agents/`:
- app-validator, code-cleaner, security-auditor, test-runner
- error-resolver, crash-resolver, rules-consolidator, app-store-preflight
