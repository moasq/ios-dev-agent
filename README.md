<div align="center">

<img src="https://developer.apple.com/assets/elements/icons/swiftui/swiftui-96x96_2x.png" width="100" alt="SwiftUI">

# iOS Dev Agent

**Universal iOS development agent for every AI coding tool.**

50+ skills &bull; 8 agents &bull; 7 rules &bull; MCP servers &bull; zero dependencies

<br>

![Swift](https://img.shields.io/badge/Swift_6-F05138?style=for-the-badge&logo=swift&logoColor=white)
![Xcode](https://img.shields.io/badge/Xcode_26-147EFB?style=for-the-badge&logo=xcode&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)
![Python](https://img.shields.io/badge/Python_3-3776AB?style=for-the-badge&logo=python&logoColor=white)

<br>

### Works with

![Claude Code](https://img.shields.io/badge/Claude_Code-D97757?style=flat-square&logo=claude&logoColor=white)
![Cursor](https://img.shields.io/badge/Cursor-000000?style=flat-square&logo=cursor&logoColor=white)
![Codex](https://img.shields.io/badge/OpenAI_Codex-412991?style=flat-square&logoColor=white)
![Windsurf](https://img.shields.io/badge/Windsurf-0B100F?style=flat-square&logo=windsurf&logoColor=white)
![Antigravity](https://img.shields.io/badge/Antigravity-4285F4?style=flat-square&logo=google&logoColor=white)
![OpenCode](https://img.shields.io/badge/OpenCode-22C55E?style=flat-square&logoColor=white)
![Amp](https://img.shields.io/badge/Amp-FF5543?style=flat-square&logoColor=white)
![Junie](https://img.shields.io/badge/Junie-000000?style=flat-square&logo=jetbrains&logoColor=white)
![Cline](https://img.shields.io/badge/Cline-18181B?style=flat-square&logoColor=white)
![Roo Code](https://img.shields.io/badge/Roo_Code-6366F1?style=flat-square&logoColor=white)
![Continue](https://img.shields.io/badge/Continue-BE1B55?style=flat-square&logoColor=white)
![Gemini CLI](https://img.shields.io/badge/Gemini_CLI-8E75B2?style=flat-square&logo=googlegemini&logoColor=white)
![Copilot](https://img.shields.io/badge/GitHub_Copilot-000000?style=flat-square&logo=githubcopilot&logoColor=white)
![Goose](https://img.shields.io/badge/Goose-000000?style=flat-square&logoColor=white)

</div>

---

## Installation

### 1. Clone

```bash
git clone https://github.com/moasq/ios-dev-agent /tmp/ios-dev-agent
cd ~/my-ios-project
```

### 2. Install for your tool

<details>
<summary><img src="https://cdn.simpleicons.org/claude/D97757" width="14"> <strong>Claude Code</strong></summary>

```bash
/tmp/ios-dev-agent/install.sh --tool claude
```

Or install as a plugin:
```bash
/plugin marketplace add moasq/ios-dev-agent
/plugin install ios-dev-agent
```

Adds: `.claude/` (skills, rules, agents, scripts) + `.mcp.json` (MCP server)
</details>

<details>
<summary><img src="https://cdn.simpleicons.org/cursor/000000" width="14"> <strong>Cursor</strong></summary>

```bash
/tmp/ios-dev-agent/install.sh --tool cursor
```

Adds: `.agents/skills/` + `.cursor/rules/` (`.mdc` format) + `.cursor/mcp.json`
</details>

<details>
<summary><strong>OpenAI Codex</strong></summary>

```bash
/tmp/ios-dev-agent/install.sh --tool codex
```

Then add the MCP server:
```bash
codex mcp add apple-auth -- python3 scripts/apple-auth-mcp-server.py
```

Adds: `.agents/skills/` + `AGENTS.md` + `scripts/`
</details>

<details>
<summary><img src="https://cdn.simpleicons.org/windsurf/0B100F" width="14"> <strong>Windsurf</strong></summary>

```bash
/tmp/ios-dev-agent/install.sh --tool windsurf
```

Then add to `~/.codeium/windsurf/mcp_config.json`:
```json
{
  "mcpServers": {
    "apple-auth": {
      "command": "python3",
      "args": ["scripts/apple-auth-mcp-server.py"]
    }
  }
}
```

Adds: `.agents/skills/` + `.windsurf/rules/`
</details>

<details>
<summary><img src="https://cdn.simpleicons.org/google/4285F4" width="14"> <strong>Antigravity</strong></summary>

```bash
/tmp/ios-dev-agent/install.sh --tool antigravity
```

Then add to `~/.gemini/antigravity/mcp_config.json`:
```json
{
  "mcpServers": {
    "apple-auth": {
      "command": "python3",
      "args": ["scripts/apple-auth-mcp-server.py"]
    }
  }
}
```

Adds: `.agents/skills/` + `GEMINI.md` + `scripts/`
</details>

<details>
<summary><strong>OpenCode</strong></summary>

```bash
/tmp/ios-dev-agent/install.sh --tool opencode
```

Then add to `opencode.json`:
```json
{
  "mcpServers": {
    "apple-auth": {
      "command": "python3",
      "args": ["scripts/apple-auth-mcp-server.py"]
    }
  }
}
```

Adds: `.agents/skills/` + `.opencode/rules/` + `AGENTS.md`
</details>

<details>
<summary><strong>Amp</strong></summary>

```bash
/tmp/ios-dev-agent/install.sh --tool amp
```

Then add MCP to `~/.config/amp/settings.json`.

Adds: `.agents/skills/` + `AGENTS.md`
</details>

<details>
<summary><img src="https://cdn.simpleicons.org/jetbrains/000000" width="14"> <strong>Junie</strong></summary>

```bash
/tmp/ios-dev-agent/install.sh --tool junie
```

Adds: `.agents/skills/` + `AGENTS.md` + `.junie/mcp/mcp.json`
</details>

<details>
<summary><strong>Cline</strong> &bull; <strong>Roo Code</strong> &bull; <strong>Continue.dev</strong></summary>

```bash
/tmp/ios-dev-agent/install.sh --tool cline
/tmp/ios-dev-agent/install.sh --tool roo
/tmp/ios-dev-agent/install.sh --tool continue
```

Each installs `.agents/skills/` + tool-specific rules directory.
</details>

<details>
<summary><img src="https://cdn.simpleicons.org/githubcopilot/000000" width="14"> <strong>GitHub Copilot</strong> &bull; <img src="https://cdn.simpleicons.org/googlegemini/8E75B2" width="14"> <strong>Gemini CLI</strong> &bull; <strong>Goose</strong></summary>

Copy `.agents/` and configure MCP manually:

```bash
cp -r /tmp/ios-dev-agent/.agents/ .agents/
cp /tmp/ios-dev-agent/scripts/apple-auth-mcp-server.py scripts/
cp /tmp/ios-dev-agent/scripts/apple-developer-auth.py scripts/
```

</details>

<details>
<summary><strong>All tools at once</strong></summary>

```bash
/tmp/ios-dev-agent/install.sh --tool all
```

</details>

---

## Skills (50+)

Every skill is a `SKILL.md` following the open [Agent Skills spec](https://agentskills.io/specification) — works across all supported tools.

<table>
<tr>
<td width="50%">

#### SwiftUI & UI
`/swiftui` &bull; `/layout` &bull; `/navigation` &bull; `/animations` &bull; `/forms` &bull; `/lists` &bull; `/scroll-patterns` &bull; `/charts` &bull; `/feedback-states` &bull; `/performance`

#### Apple Frameworks
`/healthkit` &bull; `/foundation-models` &bull; `/notifications` &bull; `/apple-signin` &bull; `/haptics` &bull; `/accessibility` &bull; `/storage`

</td>
<td width="50%">

#### App Store Connect ([asc](https://github.com/rudrankriyam/App-Store-Connect-CLI) CLI)
`/asc` &bull; `/asc-release-flow` &bull; `/asc-testflight-orchestration` &bull; `/asc-metadata-sync` &bull; `/asc-signing-setup` &bull; `/asc-xcode-build` &bull; `/asc-crash-triage` &bull; `/asc-whats-new-writer` &bull; `/asc-ppp-pricing` &bull; +11 more

#### Build, Deploy & Workflow
`/build` &bull; `/scaffold` &bull; `/screenshots` &bull; `/app-store-preflight` &bull; `/revenuecat` &bull; `/review` &bull; `/debugging` &bull; `/fix-error` &bull; `/crash` &bull; `/ui-ux-pro-max`

</td>
</tr>
</table>

## Agents (8)

| Agent | Description |
|---|---|
| **app-validator** | Checks AppTheme usage, MVVM compliance, forbidden patterns |
| **code-cleaner** | Finds dead code, redundancy, oversized files, unused imports |
| **security-auditor** | Audits HealthKit PHI exposure, credential storage, entitlements |
| **test-runner** | Runs Xcode build, analyzes errors and warnings |
| **error-resolver** | Investigates build errors, applies fixes, verifies build |
| **crash-resolver** | Investigates runtime crashes, reads logs, applies fixes |
| **rules-consolidator** | Feeds resolved errors back into rules to prevent recurrence |
| **app-store-preflight** | Scans for App Store Review rejection patterns |

## Rules (7)

Always active. Enforced on every file edit.

| Rule | What it enforces |
|---|---|
| **swift-conventions** | Swift 6, iOS 26+, `@Observable`, `NavigationStack`, `.task {}` |
| **forbidden-patterns** | No networking, no UIKit, no hardcoded styles, SPM only |
| **design-system** | All colors/fonts/spacing via `AppTheme` tokens |
| **mvvm-architecture** | `@Observable` ViewModels + `Loadable<T>` for async state |
| **file-structure** | 150-line target, one type per file, body-as-table-of-contents |
| **components** | Button hierarchy, card patterns, empty states, input fields |
| **scope** | Build minimum functional app — quality over quantity |

## MCP Server

One server, 12 tools. Pure Python 3 stdlib — no pip, no npm, no gems.

### Apple Developer Portal

Sign in to Apple Developer directly from your AI tool. Replicates [Fastlane Spaceship](https://github.com/fastlane/fastlane/tree/master/spaceship)'s SRP-6a + hashcash + 2FA flow — without requiring Fastlane.

| Tool | Description |
|---|---|
| `status` | Live session check — **green** / **yellow** / **red** |
| `login_init` | Start SRP-6a sign-in with Apple ID + password |
| `login_2fa` | Submit 6-digit 2FA code |
| `request_sms` | Send 2FA code via SMS instead |
| `revoke` | Sign out and clear session |
| `list_apps` | List registered bundle IDs |
| `list_certs` | List signing certificates |
| `list_profiles` | List provisioning profiles |
| `register_bundle` | Register a new bundle ID |

### ![RevenueCat](https://img.shields.io/badge/-F2545B?style=flat-square&logo=revenuecat&logoColor=white) RevenueCat

| Tool | Description |
|---|---|
| `rc_status` | Live API key validation — **green** / **yellow** / **red** |
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

Each tool gets its own config directory with **symlinks** back to `rules/` and `.agents/`. One source of truth — every tool stays in sync.

## Credits

| | Project | What we use it for |
|---|---|---|
| <img src="https://cdn.simpleicons.org/swift/F05138" width="14"> | **[asc](https://github.com/rudrankriyam/App-Store-Connect-CLI)** by [@rudrankriyam](https://github.com/rudrankriyam) | App Store Connect CLI — TestFlight, submissions, metadata, signing |
| <img src="https://cdn.simpleicons.org/xcode/147EFB" width="14"> | **[XcodeGen](https://github.com/yonaskolb/XcodeGen)** by [@yonaskolb](https://github.com/yonaskolb) | Generate Xcode projects from `project.yml` |
| <img src="https://cdn.simpleicons.org/fastlane/00F200" width="14"> | **[Fastlane Spaceship](https://github.com/fastlane/fastlane/tree/master/spaceship)** | Auth flow reference — SRP-6a, 2FA, session management |
| <img src="https://cdn.simpleicons.org/revenuecat/F2545B" width="14"> | **[RevenueCat](https://www.revenuecat.com/)** | In-app purchase infrastructure |
| | **[Agent Skills spec](https://agentskills.io/specification)** | Universal skill format for AI coding tools |
| | **[Model Context Protocol](https://modelcontextprotocol.io/)** | Universal tool protocol for AI assistants |
| <img src="https://cdn.simpleicons.org/apple/000000" width="14"> | **[Apple Developer Docs](https://developer.apple.com/documentation/)** | Framework APIs and references |

## Requirements

- **Python 3.8+** (ships with macOS)
- No `pip install` &bull; No `npm install` &bull; No `gem install`
- Zero external dependencies

## License

MIT
