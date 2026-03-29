<div align="center">

<img src="https://developer.apple.com/assets/elements/icons/swiftui/swiftui-96x96_2x.png" width="100" alt="SwiftUI">

# iOS Dev Agent

**End-to-end iOS development kit for AI coding tools.**

Build, ship, and manage App Store apps — from first line of code to App Store review.

[![npm version](https://img.shields.io/npm/v/ios-dev-agent?style=for-the-badge&color=CB3837&logo=npm&logoColor=white)](https://www.npmjs.com/package/ios-dev-agent)
[![npm downloads](https://img.shields.io/npm/dt/ios-dev-agent?style=for-the-badge&color=CB3837&logo=npm&logoColor=white)](https://www.npmjs.com/package/ios-dev-agent)
[![GitHub stars](https://img.shields.io/github/stars/moasq/ios-dev-agent?style=for-the-badge&logo=github)](https://github.com/moasq/ios-dev-agent)
[![License](https://img.shields.io/github/license/moasq/ios-dev-agent?style=for-the-badge)](LICENSE)

![Swift](https://img.shields.io/badge/Swift_6-F05138?style=flat-square&logo=swift&logoColor=white)
![Xcode](https://img.shields.io/badge/Xcode_26-147EFB?style=flat-square&logo=xcode&logoColor=white)
![Python](https://img.shields.io/badge/Python_3-3776AB?style=flat-square&logo=python&logoColor=white)
![iOS](https://img.shields.io/badge/iOS_26+-000000?style=flat-square&logo=apple&logoColor=white)

</div>

---

## The Problem

AI coding tools are powerful, but they don't know iOS. They generate deprecated APIs, break build rules, hardcode colors, skip accessibility, mix up architectures, and produce code that looks right but won't pass App Store review. You spend more time fixing the AI's output than writing code yourself.

## What This Solves

iOS Dev Agent gives your AI tool **deep iOS expertise** — the same knowledge a senior iOS engineer carries in their head:

- **Your code actually builds.** 7 always-active rules enforce Swift 6 concurrency, SwiftUI-first architecture, AppTheme design tokens, and MVVM with `@Observable`. The AI can't generate `UIKit` storyboards, hardcoded colors, or deprecated APIs — it's blocked before the code is written.

- **Your app is ready for the App Store.** Skills cover the full lifecycle: scaffold a project with [XcodeGen](https://github.com/yonaskolb/XcodeGen), build with `xcodebuild`, manage signing certificates, submit via [asc](https://github.com/rudrankriyam/App-Store-Connect-CLI) CLI, handle TestFlight, localize metadata, and preflight for App Store Review rejection patterns.

- **Your subscriptions just work.** [RevenueCat](https://www.revenuecat.com/) integration with live API validation — configure products, entitlements, offerings, and sync your catalog between App Store Connect and RevenueCat without touching a dashboard.

- **Your Apple account is connected.** Sign in to Apple Developer Portal directly from your AI tool — SRP-6a authentication with 2FA, register bundle IDs, manage certificates and provisioning profiles. No browser needed.

- **Your AI catches its own mistakes.** 8 autonomous agents validate code quality, audit security, resolve build errors, investigate crashes, and feed lessons back into the rules so the same mistake never happens twice.

**50+ skills · 8 agents · 7 rules · 12 MCP tools · works with 14 AI coding tools · zero dependencies.**

---

## Install

Run from your iOS project directory:

```bash
npx ios-dev-agent
```

That's it. Auto-detects your tool, installs everything, done.

---

## Per-Tool Install

### <img src="https://cdn.simpleicons.org/claude/D97757" width="18"> Claude Code

```bash
npx ios-dev-agent claude
```

Installs `.claude/` with skills, rules, agents, scripts, hooks + `.mcp.json` with Apple auth MCP server.

### <img src="https://cdn.simpleicons.org/cursor/000000" width="18"> Cursor

```bash
npx ios-dev-agent cursor
```

Installs `.agents/skills/` + `.cursor/rules/` in `.mdc` format + `.cursor/mcp.json`.

### OpenAI Codex

```bash
npx ios-dev-agent codex
```

Installs `.agents/skills/` + `AGENTS.md` + `scripts/`. Then run:
```bash
codex mcp add apple-auth -- python3 scripts/apple-auth-mcp-server.py
```

### <img src="https://cdn.simpleicons.org/windsurf/0B100F" width="18"> Windsurf

```bash
npx ios-dev-agent windsurf
```

Installs `.agents/skills/` + `.windsurf/rules/` + `scripts/`. Then add to `~/.codeium/windsurf/mcp_config.json`:
```json
{ "mcpServers": { "apple-auth": { "command": "python3", "args": ["scripts/apple-auth-mcp-server.py"] } } }
```

### <img src="https://cdn.simpleicons.org/google/4285F4" width="18"> Google Antigravity

```bash
npx ios-dev-agent antigravity
```

Installs `.agents/skills/` + `GEMINI.md` + `scripts/`. Then add MCP to `~/.gemini/antigravity/mcp_config.json`.

### OpenCode

```bash
npx ios-dev-agent opencode
```

Installs `.agents/skills/` + `.opencode/rules/` + `AGENTS.md`. Then add `mcpServers` to `opencode.json`.

### Amp

```bash
npx ios-dev-agent amp
```

Installs `.agents/skills/` + `AGENTS.md`. Then add MCP to `~/.config/amp/settings.json`.

### <img src="https://cdn.simpleicons.org/jetbrains/000000" width="18"> JetBrains Junie

```bash
npx ios-dev-agent junie
```

Installs `.agents/skills/` + `AGENTS.md` + `.junie/mcp/mcp.json`.

### Cline

```bash
npx ios-dev-agent cline
```

Installs `.agents/skills/` + `.clinerules/`. Add MCP via the Cline extension settings UI.

### Roo Code

```bash
npx ios-dev-agent roo
```

Installs `.agents/skills/` + `.roo/rules/` + `.roo/mcp.json`.

### Continue.dev

```bash
npx ios-dev-agent continue
```

Installs `.agents/skills/` + `.continue/rules/`. Add MCP to `.continue/mcpServers/`.

### <img src="https://cdn.simpleicons.org/githubcopilot/000000" width="18"> GitHub Copilot · <img src="https://cdn.simpleicons.org/googlegemini/8E75B2" width="18"> Gemini CLI · Goose

Copy `.agents/` into your project and configure MCP per your tool's docs.

### All tools

```bash
npx ios-dev-agent all
```

---

## What's Included

### Skills (50+)

Every skill is a `SKILL.md` following the open [Agent Skills spec](https://agentskills.io/specification) — works across all 14 supported tools.

<table>
<tr>
<td width="50%">

**SwiftUI & UI**

`/swiftui` · `/layout` · `/navigation` · `/animations` · `/forms` · `/lists` · `/scroll-patterns` · `/charts` · `/feedback-states` · `/performance`

**Apple Frameworks**

`/healthkit` · `/foundation-models` · `/notifications` · `/apple-signin` · `/haptics` · `/accessibility` · `/storage`

</td>
<td width="50%">

**App Store Connect** ([asc](https://github.com/rudrankriyam/App-Store-Connect-CLI) CLI)

`/asc` · `/asc-release-flow` · `/asc-testflight-orchestration` · `/asc-metadata-sync` · `/asc-signing-setup` · `/asc-xcode-build` · `/asc-crash-triage` · `/asc-whats-new-writer` · `/asc-ppp-pricing` · +11 more

**Build, Deploy & Workflow**

`/build` · `/scaffold` · `/screenshots` · `/app-store-preflight` · `/revenuecat` · `/review` · `/debugging` · `/fix-error` · `/crash` · `/ui-ux-pro-max`

</td>
</tr>
</table>

### Agents (8)

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

### Rules (7)

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

---

## MCP Server

One server, 12 tools. Pure Python 3 — no pip, no npm, no gems.

### Apple Developer Portal

Sign in to Apple Developer directly from your AI tool. Replicates [Fastlane Spaceship](https://github.com/fastlane/fastlane/tree/master/spaceship)'s SRP-6a + hashcash + 2FA flow.

| Tool | Description |
|---|---|
| `status` | Live session check — **green** · **yellow** · **red** |
| `login_init` | Start SRP-6a sign-in with Apple ID + password |
| `login_2fa` | Submit 6-digit 2FA code |
| `request_sms` | Send 2FA code via SMS instead |
| `revoke` | Sign out and clear session |
| `list_apps` | List registered bundle IDs |
| `list_certs` | List signing certificates |
| `list_profiles` | List provisioning profiles |
| `register_bundle` | Register a new bundle ID |

### <img src="https://cdn.simpleicons.org/revenuecat/F2545B" width="16"> RevenueCat

| Tool | Description |
|---|---|
| `rc_status` | Live API key validation — **green** · **yellow** · **red** |
| `rc_setup` | Configure + validate API key and project ID |
| `rc_revoke` | Remove stored credentials |

---

## Security

Credentials are stored locally with `chmod 600` permissions and never leave your machine. See [SECURITY.md](SECURITY.md) for details.

| File | Contents |
|---|---|
| `~/.apple-developer-auth/cookies.txt` | Apple session cookies |
| `~/.apple-developer-auth/revenuecat.json` | RevenueCat API key |

Use `revoke` / `rc_revoke` to clear credentials at any time.

---

## Credits

Built on top of excellent open-source projects:

| | Project | Used for |
|---|---|---|
| <img src="https://cdn.simpleicons.org/swift/F05138" width="14"> | **[asc](https://github.com/rudrankriyam/App-Store-Connect-CLI)** by [@rudrankriyam](https://github.com/rudrankriyam) | App Store Connect CLI |
| <img src="https://cdn.simpleicons.org/xcode/147EFB" width="14"> | **[XcodeGen](https://github.com/yonaskolb/XcodeGen)** by [@yonaskolb](https://github.com/yonaskolb) | Xcode project generation |
| <img src="https://cdn.simpleicons.org/fastlane/00F200" width="14"> | **[Fastlane Spaceship](https://github.com/fastlane/fastlane/tree/master/spaceship)** | SRP-6a auth flow reference |
| <img src="https://cdn.simpleicons.org/revenuecat/F2545B" width="14"> | **[RevenueCat](https://www.revenuecat.com/)** | In-app purchase infrastructure |
| | **[Agent Skills spec](https://agentskills.io/specification)** | Universal skill format for AI coding tools |
| | **[Model Context Protocol](https://modelcontextprotocol.io/)** | Universal tool protocol for AI assistants |
| <img src="https://cdn.simpleicons.org/apple/000000" width="14"> | **[Apple Developer Docs](https://developer.apple.com/documentation/)** | Framework APIs and references |

## Contributing

Contributions welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

[MIT](LICENSE)
