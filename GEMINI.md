# iOS Development Agent

Universal iOS development toolkit with 50+ skills and MCP servers.

## Rules
Follow all rules in `rules/` directory:
- Swift 6, iOS 26+, SwiftUI-first architecture
- No networking (URLSession, Alamofire) — offline only
- AppTheme tokens for all styling (no hardcoded colors/fonts/spacing)
- MVVM with @Observable + Loadable<T> for async state
- 150-line target per file, 200 hard limit

## Skills
Skills in `.agents/skills/` — each has a SKILL.md with instructions.

## MCP Servers
Configure `apple-auth` MCP server from `scripts/apple-auth-mcp-server.py` for Apple Developer Portal and RevenueCat authentication.
