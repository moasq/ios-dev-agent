# iOS Dev Agent

Universal iOS development agent — 50+ skills, 8 agents, 7 rules, and MCP servers for Apple Developer auth and RevenueCat. Works with every major AI coding tool.

## Supported Tools

| Tool | Skills | Rules | MCP | Install |
|---|---|---|---|---|
| Claude Code | `.agents/skills/` | `.claude/rules/` | `.mcp.json` | `./install.sh` |
| Codex (OpenAI) | `.agents/skills/` | `AGENTS.md` | `codex mcp add` | `./install.sh --tool codex` |
| Cursor | `.agents/skills/` | `.cursor/rules/` | `.cursor/mcp.json` | `./install.sh --tool cursor` |
| Windsurf | `.agents/skills/` | `.windsurf/rules/` | `mcp_config.json` | `./install.sh --tool windsurf` |
| Antigravity | `.agents/skills/` | `GEMINI.md` | `mcp_config.json` | `./install.sh --tool antigravity` |
| OpenCode | `.agents/skills/` | `.opencode/rules/` | `opencode.json` | `./install.sh --tool opencode` |
| Amp | `.agents/skills/` | `AGENTS.md` | `settings.json` | `./install.sh --tool amp` |
| Junie | `.agents/skills/` | `AGENTS.md` | `.junie/mcp/mcp.json` | `./install.sh --tool junie` |
| Cline | `.agents/skills/` | `.clinerules/` | Extension settings | `./install.sh --tool cline` |
| Roo Code | `.agents/skills/` | `.roo/rules/` | `.roo/mcp.json` | `./install.sh --tool roo` |
| Continue.dev | `.agents/skills/` | `.continue/rules/` | `.continue/mcpServers/` | `./install.sh --tool continue` |
| Gemini CLI | `.agents/skills/` | `GEMINI.md` | `settings.json` | Copy + `gemini mcp add` |
| Copilot | `.agents/skills/` | `.github/copilot-instructions.md` | Repo settings | Copy `.agents/` |
| Goose | `.agents/skills/` | `AGENTS.md` | `goose/config.yaml` | Copy + configure |

## Quick Start

```bash
cd ~/my-ios-project
git clone https://github.com/moasq/ios-dev-agent /tmp/ios-dev-agent
/tmp/ios-dev-agent/install.sh                    # Auto-detect tool
/tmp/ios-dev-agent/install.sh --tool cursor      # Or specify
/tmp/ios-dev-agent/install.sh --tool all         # Everything
```

## What's Included

### 50+ Skills
SwiftUI, HealthKit, App Store Connect, RevenueCat, build/deploy, debugging, and more. Each skill is a `SKILL.md` following the open Agent Skills spec.

### 8 Agents
app-validator, code-cleaner, security-auditor, test-runner, error-resolver, crash-resolver, rules-consolidator, app-store-preflight.

### 7 Rules (always active)
Swift 6/iOS 26+ conventions, forbidden patterns, AppTheme design system, MVVM architecture, file structure, component patterns, scope control.

### MCP Server (12 tools)
**Apple Developer:** SRP-6a authentication, 2FA, portal operations (list apps/certs/profiles, register bundles).
**RevenueCat:** API key validation, credential management.

## Requirements

- Python 3.8+ (ships with macOS)
- No external dependencies

## License

MIT
