# iOS Development Agent

Universal iOS development toolkit. Skills, agents, rules, and MCP servers.

## Structure
```
.agents/skills/   → 50+ skills (universal Agent Skills spec)
.agents/agents/   → 8 autonomous agents
rules/            → 7 always-loaded rule files
scripts/          → Shell/Python automation scripts
mcp.json          → MCP server config (apple-auth + revenuecat)
```

## Key Rules
- Swift 6 / iOS 26+ / SwiftUI-first
- No networking — apps work 100% offline
- AppTheme tokens for all colors/fonts/spacing
- MVVM with @Observable + Loadable<T>
- 150-line target, 200-line hard limit per file

## MCP Servers
- `apple-auth`: Apple Developer auth (SRP-6a + 2FA), portal operations, RevenueCat credential management
- Run `mcp__apple-auth__status` to check Apple connection
- Run `mcp__apple-auth__rc_status` to check RevenueCat connection
