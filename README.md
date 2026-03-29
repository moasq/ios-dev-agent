<p align="center">
  <img src="https://developer.apple.com/assets/elements/icons/swiftui/swiftui-96x96_2x.png" width="80" alt="SwiftUI">
</p>

<h1 align="center">iOS Dev Agent</h1>

<p align="center">
  <strong>Universal iOS development agent for every AI coding tool.</strong><br>
  50+ skills &bull; 8 agents &bull; 7 rules &bull; MCP servers &bull; zero dependencies
</p>

<p align="center">
  <a href="#quick-start">Quick Start</a> &bull;
  <a href="#supported-tools">Supported Tools</a> &bull;
  <a href="#whats-included">What's Included</a> &bull;
  <a href="#mcp-servers">MCP Servers</a>
</p>

---

## Quick Start

```bash
cd ~/my-ios-project
git clone https://github.com/moasq/ios-dev-agent /tmp/ios-dev-agent

# Auto-detects your tool
/tmp/ios-dev-agent/install.sh

# Or pick one
/tmp/ios-dev-agent/install.sh --tool cursor
/tmp/ios-dev-agent/install.sh --tool codex
/tmp/ios-dev-agent/install.sh --tool all
```

Restart your tool. Done.

## Supported Tools

Works with **14 AI coding tools** out of the box:

| | Tool | Skills | Rules | MCP | Install |
|---|---|---|---|---|---|
| <img src="https://claude.ai/favicon.ico" width="16"> | **Claude Code** | `.agents/skills/` | `.claude/rules/` | `.mcp.json` | `./install.sh` |
| <img src="https://cursor.com/favicon.ico" width="16"> | **Cursor** | `.agents/skills/` | `.cursor/rules/` | `.cursor/mcp.json` | `./install.sh --tool cursor` |
| <img src="https://openai.com/favicon.ico" width="16"> | **Codex (OpenAI)** | `.agents/skills/` | `AGENTS.md` | `config.toml` | `./install.sh --tool codex` |
| | **Windsurf** | `.agents/skills/` | `.windsurf/rules/` | `mcp_config.json` | `./install.sh --tool windsurf` |
| | **Antigravity** | `.agents/skills/` | `GEMINI.md` | `mcp_config.json` | `./install.sh --tool antigravity` |
| | **OpenCode** | `.agents/skills/` | `.opencode/rules/` | `opencode.json` | `./install.sh --tool opencode` |
| | **Amp** | `.agents/skills/` | `AGENTS.md` | `settings.json` | `./install.sh --tool amp` |
| | **Junie** | `.agents/skills/` | `AGENTS.md` | `.junie/mcp/` | `./install.sh --tool junie` |
| | **Cline** | `.agents/skills/` | `.clinerules/` | Extension UI | `./install.sh --tool cline` |
| | **Roo Code** | `.agents/skills/` | `.roo/rules/` | `.roo/mcp.json` | `./install.sh --tool roo` |
| | **Continue.dev** | `.agents/skills/` | `.continue/rules/` | YAML config | `./install.sh --tool continue` |
| | **Gemini CLI** | `.agents/skills/` | `GEMINI.md` | `settings.json` | Copy + configure |
| | **Copilot** | `.agents/skills/` | `.github/` | Repo settings | Copy `.agents/` |
| | **Goose** | `.agents/skills/` | `AGENTS.md` | `config.yaml` | Copy + configure |

Skills follow the open **Agent Skills spec** — one `SKILL.md` works everywhere.

## What's Included

### Skills (50+)

<table>
<tr>
<td width="50%">

**SwiftUI & UI**
- `/swiftui` — views, state, layouts
- `/layout` — VStack, HStack, ZStack, Grid
- `/navigation` — NavigationStack, TabView, sheets
- `/animations` — timing curves, transitions, keyframes
- `/forms` — TextField, validation, pickers
- `/lists` — ForEach, swipe actions, pull-to-refresh
- `/scroll-patterns` — parallax, paging, snap
- `/charts` — Swift Charts, BarMark, LineMark
- `/feedback-states` — loading, error, empty states
- `/performance` — redundant updates, task cancellation

</td>
<td width="50%">

**Apple Frameworks**
- `/healthkit` — authorization, queries, sleep analysis
- `/foundation-models` — on-device AI, @Generable
- `/notifications` — permissions, scheduling, badges
- `/apple-signin` — AuthenticationServices, credential state
- `/haptics` — impact, notification, custom patterns
- `/accessibility` — VoiceOver, Dynamic Type, contrast
- `/storage` — @AppStorage, SwiftData patterns
- `/apple-developer-auth` — portal sign-in + 2FA

</td>
</tr>
<tr>
<td>

**App Store Connect (asc CLI)**
- `/asc` — CLI setup, auth, operations
- `/asc-release-flow` — submission workflow
- `/asc-testflight-orchestration` — beta distribution
- `/asc-metadata-sync` — localizations, descriptions
- `/asc-signing-setup` — certs, profiles, bundle IDs
- `/asc-xcode-build` — archive, export, upload
- `/asc-crash-triage` — TestFlight crash reports
- `/asc-whats-new-writer` — release notes generation
- `/asc-ppp-pricing` — territory pricing
- + 11 more asc skills

</td>
<td>

**Build, Deploy & Workflow**
- `/build` — xcodebuild, simulators, diagnostics
- `/scaffold` — new project from scratch
- `/screenshots` — simulator capture automation
- `/app-store-preflight` — rejection pattern scanner
- `/revenuecat` — IAP setup, catalog management
- `/review` — code quality, accessibility audit
- `/debugging` — crash investigation, LLDB
- `/fix-error` — auto-fix build errors
- `/crash` — runtime crash resolution
- `/ui-ux-pro-max` — design intelligence

</td>
</tr>
</table>

### Agents (8)

| Agent | What it does |
|---|---|
| `app-validator` | Checks AppTheme usage, MVVM compliance, forbidden patterns |
| `code-cleaner` | Finds dead code, redundancy, oversized files, unused imports |
| `security-auditor` | Audits HealthKit PHI exposure, credential storage, entitlements |
| `test-runner` | Runs Xcode build, analyzes errors and warnings |
| `error-resolver` | Investigates unresolved build errors, applies fixes, verifies |
| `crash-resolver` | Investigates runtime crashes, reads logs, applies fixes |
| `rules-consolidator` | Feeds resolved errors back into rules to prevent recurrence |
| `app-store-preflight` | Scans for App Store Review rejection patterns |

### Rules (7 &mdash; always active)

| Rule | Enforces |
|---|---|
| `swift-conventions` | Swift 6, iOS 26+, modern APIs, concurrency safety |
| `forbidden-patterns` | No networking, no UIKit, no hardcoded styles, SPM only |
| `design-system` | All colors/fonts/spacing from AppTheme tokens |
| `mvvm-architecture` | @Observable ViewModels, Loadable&lt;T&gt; for async state |
| `file-structure` | 150-line target, one type per file, body-as-TOC |
| `components` | Button hierarchy, card patterns, empty states |
| `scope` | Build minimum functional app, quality over quantity |

## MCP Servers

One MCP server, 12 tools. Pure Python 3 — no external dependencies.

### Apple Developer Portal

Authenticate to Apple's Developer Portal directly from your AI tool. Replicates Fastlane Spaceship's SRP-6a + hashcash + 2FA flow.

| Tool | Description |
|---|---|
| `status` | Live session validation &mdash; green / yellow / red |
| `login_init` | Start SRP-6a sign-in (Apple ID + password) |
| `login_2fa` | Submit 2FA verification code |
| `request_sms` | Send 2FA code via SMS |
| `revoke` | Sign out, clear session |
| `list_apps` | List registered bundle IDs |
| `list_certs` | List signing certificates |
| `list_profiles` | List provisioning profiles |
| `register_bundle` | Register a new bundle ID |

### RevenueCat

| Tool | Description |
|---|---|
| `rc_status` | Live API key validation &mdash; green / yellow / red |
| `rc_setup` | Configure + validate API key and project ID |
| `rc_revoke` | Remove stored credentials |

## How It Works

```
.agents/skills/     Universal skills (Agent Skills spec)
.agents/agents/     Autonomous agents
rules/              Shared rules (markdown)
scripts/            MCP servers + automation scripts
install.sh          One-command setup for any tool
```

Each tool gets its own config directory (`.claude/`, `.cursor/`, `.opencode/`, etc.) with symlinks pointing back to the shared `rules/` and `.agents/` directories. One source of truth, every tool stays in sync.

## Requirements

- Python 3.8+ (ships with macOS)
- No `pip install`, no `npm install`, no `gem install`
- Zero external dependencies

## License

MIT
