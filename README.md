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

## Install

One command. Run it from your iOS project directory.

```bash
npx ios-dev-agent            # auto-detects your tool
npx ios-dev-agent claude     # Claude Code
npx ios-dev-agent cursor     # Cursor
npx ios-dev-agent codex      # OpenAI Codex
npx ios-dev-agent windsurf   # Windsurf
npx ios-dev-agent antigravity # Google Antigravity
npx ios-dev-agent opencode   # OpenCode
npx ios-dev-agent amp        # Amp
npx ios-dev-agent junie      # JetBrains Junie
npx ios-dev-agent cline      # Cline
npx ios-dev-agent roo        # Roo Code
npx ios-dev-agent continue   # Continue.dev
npx ios-dev-agent all        # everything
```

Restart your tool. Done.

---

## What gets installed

### <img src="https://cdn.simpleicons.org/claude/D97757" width="16"> Claude Code

```
.claude/skills/     → 50+ skills (symlink to .agents/skills/)
.claude/rules/      → 7 rule files
.claude/agents/     → 8 agents
.claude/scripts/    → MCP server + hook scripts
.mcp.json           → apple-auth MCP server
CLAUDE.md           → project instructions
```

### <img src="https://cdn.simpleicons.org/cursor/000000" width="16"> Cursor

```
.agents/skills/     → 50+ skills
.cursor/rules/      → 7 rules in .mdc format
.cursor/mcp.json    → apple-auth MCP server
```

### OpenAI Codex

```
.agents/skills/     → 50+ skills
AGENTS.md           → project instructions
scripts/            → MCP server scripts
```
Then: `codex mcp add apple-auth -- python3 scripts/apple-auth-mcp-server.py`

### <img src="https://cdn.simpleicons.org/windsurf/0B100F" width="16"> Windsurf

```
.agents/skills/     → 50+ skills
.windsurf/rules/    → 7 rules
scripts/            → MCP server scripts
```
Then add to `~/.codeium/windsurf/mcp_config.json`:
```json
{ "mcpServers": { "apple-auth": { "command": "python3", "args": ["scripts/apple-auth-mcp-server.py"] } } }
```

### <img src="https://cdn.simpleicons.org/google/4285F4" width="16"> Antigravity

```
.agents/skills/     → 50+ skills
GEMINI.md           → project instructions
scripts/            → MCP server scripts
```
Then add to `~/.gemini/antigravity/mcp_config.json`:
```json
{ "mcpServers": { "apple-auth": { "command": "python3", "args": ["scripts/apple-auth-mcp-server.py"] } } }
```

### OpenCode

```
.agents/skills/     → 50+ skills
.opencode/rules/    → 7 rules
AGENTS.md           → project instructions
```
Then add `mcpServers` to `opencode.json`.

### Amp &bull; <img src="https://cdn.simpleicons.org/jetbrains/000000" width="16"> Junie &bull; Cline &bull; Roo Code &bull; Continue.dev

```
.agents/skills/     → 50+ skills
AGENTS.md           → project instructions (Amp, Junie)
.<tool>/rules/      → 7 rules in tool-native format
.<tool>/mcp.json    → MCP config (Junie, Roo Code)
```

### <img src="https://cdn.simpleicons.org/githubcopilot/000000" width="16"> Copilot &bull; <img src="https://cdn.simpleicons.org/googlegemini/8E75B2" width="16"> Gemini CLI &bull; Goose

Copy `.agents/` into your project and configure MCP manually per tool docs.

---

## Skills (50+)

Every skill is a `SKILL.md` following the open [Agent Skills spec](https://agentskills.io/specification).

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

One server, 12 tools. Pure Python 3 — no pip, no npm, no gems.

### Apple Developer Portal

Sign in to Apple Developer directly from your AI tool. Replicates [Fastlane Spaceship](https://github.com/fastlane/fastlane/tree/master/spaceship)'s SRP-6a + hashcash + 2FA flow.

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

## Credits

| | Project | Used for |
|---|---|---|
| <img src="https://cdn.simpleicons.org/swift/F05138" width="14"> | **[asc](https://github.com/rudrankriyam/App-Store-Connect-CLI)** by [@rudrankriyam](https://github.com/rudrankriyam) | App Store Connect CLI |
| <img src="https://cdn.simpleicons.org/xcode/147EFB" width="14"> | **[XcodeGen](https://github.com/yonaskolb/XcodeGen)** by [@yonaskolb](https://github.com/yonaskolb) | Xcode project generation |
| <img src="https://cdn.simpleicons.org/fastlane/00F200" width="14"> | **[Fastlane Spaceship](https://github.com/fastlane/fastlane/tree/master/spaceship)** | SRP-6a auth flow reference |
| <img src="https://cdn.simpleicons.org/revenuecat/F2545B" width="14"> | **[RevenueCat](https://www.revenuecat.com/)** | In-app purchase infrastructure |
| | **[Agent Skills spec](https://agentskills.io/specification)** | Universal skill format |
| | **[Model Context Protocol](https://modelcontextprotocol.io/)** | Universal tool protocol |
| <img src="https://cdn.simpleicons.org/apple/000000" width="14"> | **[Apple Developer Docs](https://developer.apple.com/documentation/)** | Framework references |

## License

MIT
