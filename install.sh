#!/bin/bash
# iOS Dev Agent — Universal installer
# Detects your AI coding tool and sets up skills, rules, and MCP servers.
#
# Usage:
#   ./install.sh                  # Auto-detect tool
#   ./install.sh --tool claude    # Specific tool
#   ./install.sh --tool all       # All tools
#   ./install.sh --list           # Show supported tools

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_DIR="${TARGET_DIR:-$(pwd)}"
TOOL="${1:-auto}"

GREEN='\033[32m'
RED='\033[31m'
DIM='\033[2m'
BOLD='\033[1m'
RESET='\033[0m'

log() { echo -e "  $1"; }
ok() { echo -e "  ${GREEN}+${RESET} $1"; }
skip() { echo -e "  ${DIM}- $1${RESET}"; }

# ── Shared helpers ───────────────────────────────────────────────────────────

install_skills_to() {
  local dest="$1"
  mkdir -p "$dest"
  cp -R "$SCRIPT_DIR/.agents/skills/"* "$dest/"
  ok "Skills ($(ls "$dest" | wc -l | tr -d ' ')) → $dest"
}

install_agents_to() {
  local dest="$1"
  mkdir -p "$dest"
  cp "$SCRIPT_DIR/.agents/agents/"*.md "$dest/"
  ok "Agents ($(ls "$dest" | wc -l | tr -d ' ')) → $dest"
}

install_rules_to() {
  local dest="$1"
  mkdir -p "$dest"
  cp "$SCRIPT_DIR/rules/"*.md "$dest/"
  ok "Rules ($(ls "$dest" | wc -l | tr -d ' ')) → $dest"
}

install_mcp_scripts_to() {
  local dest="$1"
  mkdir -p "$dest"
  cp "$SCRIPT_DIR/scripts/apple-developer-auth.py" "$dest/"
  cp "$SCRIPT_DIR/scripts/apple-auth-mcp-server.py" "$dest/"
  chmod +x "$dest/"*.py 2>/dev/null || true
  ok "MCP scripts → $dest"
}

write_mcp_json() {
  local dest="$1"
  local server_path="$2"
  if [ ! -f "$dest" ]; then
    cat > "$dest" << EOF
{"mcpServers":{"apple-auth":{"command":"python3","args":["${server_path}"]}}}
EOF
    ok "MCP config → $dest"
  else
    skip "$dest already exists"
  fi
}

# ── Detect tool ──────────────────────────────────────────────────────────────

detect_tool() {
  if [ -d "$TARGET_DIR/.claude" ]; then echo "claude"; return; fi
  if [ -d "$TARGET_DIR/.cursor" ]; then echo "cursor"; return; fi
  if [ -d "$TARGET_DIR/.windsurf" ]; then echo "windsurf"; return; fi
  if [ -d "$TARGET_DIR/.opencode" ]; then echo "opencode"; return; fi
  if [ -d "$TARGET_DIR/.roo" ]; then echo "roo"; return; fi
  if [ -d "$TARGET_DIR/.junie" ]; then echo "junie"; return; fi
  if [ -d "$TARGET_DIR/.clinerules" ]; then echo "cline"; return; fi
  if [ -d "$TARGET_DIR/.continue" ]; then echo "continue"; return; fi
  if [ -f "$TARGET_DIR/AGENTS.md" ]; then echo "codex"; return; fi
  echo "claude"  # Default
}

# ── Tool Installers ──────────────────────────────────────────────────────────

install_claude() {
  log "${BOLD}Claude Code${RESET}"
  # Self-contained .claude/ — no .agents/, no symlinks
  install_skills_to "$TARGET_DIR/.claude/skills"
  install_agents_to "$TARGET_DIR/.claude/agents"
  install_rules_to "$TARGET_DIR/.claude/rules"
  # All scripts (MCP + hooks + build tools)
  mkdir -p "$TARGET_DIR/.claude/scripts"
  cp "$SCRIPT_DIR/scripts/"* "$TARGET_DIR/.claude/scripts/"
  chmod +x "$TARGET_DIR/.claude/scripts/"*.py "$TARGET_DIR/.claude/scripts/"*.sh 2>/dev/null || true
  ok "Scripts ($(ls "$TARGET_DIR/.claude/scripts/" | wc -l | tr -d ' ')) → .claude/scripts/"
  # Hook scripts
  mkdir -p "$TARGET_DIR/.claude/hooks"
  cp "$SCRIPT_DIR/scripts/log-build-error.sh" "$TARGET_DIR/.claude/hooks/"
  cp "$SCRIPT_DIR/scripts/log-build-resolution.sh" "$TARGET_DIR/.claude/hooks/"
  cp "$SCRIPT_DIR/scripts/log-test-failure.sh" "$TARGET_DIR/.claude/hooks/"
  cp "$SCRIPT_DIR/scripts/on-build-success.sh" "$TARGET_DIR/.claude/hooks/"
  chmod +x "$TARGET_DIR/.claude/hooks/"*.sh 2>/dev/null || true
  ok "Hooks (4) → .claude/hooks/"
  # Error ledger
  mkdir -p "$TARGET_DIR/.claude/errors"
  cp "$SCRIPT_DIR/errors/errors.md" "$TARGET_DIR/.claude/errors/"
  ok "Error ledger → .claude/errors/"
  # Settings
  if [ ! -f "$TARGET_DIR/.claude/settings.json" ]; then
    cat > "$TARGET_DIR/.claude/settings.json" << 'SETTINGS'
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "permissions": {
    "allow": [
      "mcp__apple-auth__status",
      "mcp__apple-auth__login_init",
      "mcp__apple-auth__login_2fa",
      "mcp__apple-auth__request_sms",
      "mcp__apple-auth__revoke",
      "mcp__apple-auth__list_apps",
      "mcp__apple-auth__list_certs",
      "mcp__apple-auth__list_profiles",
      "mcp__apple-auth__register_bundle",
      "mcp__apple-auth__rc_status",
      "mcp__apple-auth__rc_setup",
      "mcp__apple-auth__rc_revoke",
      "WebFetch",
      "WebSearch"
    ],
    "deny": [
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(./secrets/**)"
    ]
  },
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [{ "type": "command", "command": "./.claude/scripts/check-project-config-edits.sh" }]
      },
      {
        "matcher": "Bash",
        "hooks": [{ "type": "command", "command": "./.claude/scripts/check-bash-safety.sh" }]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          { "type": "command", "command": "./.claude/scripts/check-swift-structure.sh" },
          { "type": "command", "command": "./.claude/scripts/check-no-placeholders.sh --hook" },
          { "type": "command", "command": "./.claude/scripts/check-previews.sh --hook" },
          { "type": "command", "command": "./.claude/scripts/check-a11y-dynamic-type.sh --hook" },
          { "type": "command", "command": "./.claude/scripts/check-a11y-icon-buttons.sh --hook" }
        ]
      }
    ],
    "PostToolUseFailure": [
      {
        "matcher": "Bash",
        "hooks": [{ "type": "command", "command": "./.claude/hooks/log-build-error.sh" }]
      }
    ],
    "Stop": [
      {
        "hooks": [{ "type": "command", "command": "./.claude/hooks/on-build-success.sh" }]
      }
    ]
  }
}
SETTINGS
    ok "Settings → .claude/settings.json"
  else
    skip ".claude/settings.json already exists"
  fi
  # CLAUDE.md + .mcp.json
  cp "$SCRIPT_DIR/CLAUDE.md" "$TARGET_DIR/" 2>/dev/null || true
  ok "CLAUDE.md"
  write_mcp_json "$TARGET_DIR/.mcp.json" ".claude/scripts/apple-auth-mcp-server.py"
}

install_cursor() {
  log "${BOLD}Cursor${RESET}"
  install_skills_to "$TARGET_DIR/.agents/skills"
  install_agents_to "$TARGET_DIR/.agents/agents"
  # Cursor rules in .mdc format
  mkdir -p "$TARGET_DIR/.cursor/rules"
  cp "$SCRIPT_DIR/.cursor/rules/"*.mdc "$TARGET_DIR/.cursor/rules/"
  ok "Rules (.mdc) → .cursor/rules/"
  install_mcp_scripts_to "$TARGET_DIR/scripts"
  write_mcp_json "$TARGET_DIR/.cursor/mcp.json" "scripts/apple-auth-mcp-server.py"
  cp "$SCRIPT_DIR/AGENTS.md" "$TARGET_DIR/" 2>/dev/null || true
  ok "AGENTS.md"
}

install_codex() {
  log "${BOLD}Codex (OpenAI)${RESET}"
  install_skills_to "$TARGET_DIR/.agents/skills"
  install_agents_to "$TARGET_DIR/.agents/agents"
  install_rules_to "$TARGET_DIR/.agents/rules"
  install_mcp_scripts_to "$TARGET_DIR/scripts"
  cp "$SCRIPT_DIR/AGENTS.md" "$TARGET_DIR/" 2>/dev/null || true
  ok "AGENTS.md"
  log "${DIM}  Run: codex mcp add apple-auth -- python3 scripts/apple-auth-mcp-server.py${RESET}"
}

install_windsurf() {
  log "${BOLD}Windsurf${RESET}"
  install_skills_to "$TARGET_DIR/.agents/skills"
  install_agents_to "$TARGET_DIR/.agents/agents"
  install_rules_to "$TARGET_DIR/.windsurf/rules"
  install_mcp_scripts_to "$TARGET_DIR/scripts"
  cp "$SCRIPT_DIR/AGENTS.md" "$TARGET_DIR/" 2>/dev/null || true
  ok "AGENTS.md"
  log "${DIM}  Add to ~/.codeium/windsurf/mcp_config.json:${RESET}"
  log "${DIM}  {\"mcpServers\":{\"apple-auth\":{\"command\":\"python3\",\"args\":[\"scripts/apple-auth-mcp-server.py\"]}}}${RESET}"
}

install_antigravity() {
  log "${BOLD}Antigravity (Google)${RESET}"
  install_skills_to "$TARGET_DIR/.agents/skills"
  install_agents_to "$TARGET_DIR/.agents/agents"
  install_rules_to "$TARGET_DIR/.agent/rules"
  install_mcp_scripts_to "$TARGET_DIR/scripts"
  cp "$SCRIPT_DIR/GEMINI.md" "$TARGET_DIR/" 2>/dev/null || true
  ok "GEMINI.md"
  log "${DIM}  Add to ~/.gemini/antigravity/mcp_config.json:${RESET}"
  log "${DIM}  {\"mcpServers\":{\"apple-auth\":{\"command\":\"python3\",\"args\":[\"scripts/apple-auth-mcp-server.py\"]}}}${RESET}"
}

install_opencode() {
  log "${BOLD}OpenCode${RESET}"
  install_skills_to "$TARGET_DIR/.opencode/skills"
  install_agents_to "$TARGET_DIR/.opencode/agents"
  install_rules_to "$TARGET_DIR/.opencode/rules"
  install_mcp_scripts_to "$TARGET_DIR/scripts"
  cp "$SCRIPT_DIR/AGENTS.md" "$TARGET_DIR/" 2>/dev/null || true
  ok "AGENTS.md"
  log "${DIM}  Add mcpServers to opencode.json:${RESET}"
  log "${DIM}  {\"mcpServers\":{\"apple-auth\":{\"command\":\"python3\",\"args\":[\"scripts/apple-auth-mcp-server.py\"]}}}${RESET}"
}

install_amp() {
  log "${BOLD}Amp (Sourcegraph)${RESET}"
  install_skills_to "$TARGET_DIR/.agents/skills"
  install_agents_to "$TARGET_DIR/.agents/agents"
  install_rules_to "$TARGET_DIR/.agents/rules"
  install_mcp_scripts_to "$TARGET_DIR/scripts"
  cp "$SCRIPT_DIR/AGENTS.md" "$TARGET_DIR/" 2>/dev/null || true
  ok "AGENTS.md"
  log "${DIM}  Add MCP to ~/.config/amp/settings.json${RESET}"
}

install_junie() {
  log "${BOLD}Junie (JetBrains)${RESET}"
  install_skills_to "$TARGET_DIR/.agents/skills"
  install_agents_to "$TARGET_DIR/.agents/agents"
  install_rules_to "$TARGET_DIR/.agents/rules"
  install_mcp_scripts_to "$TARGET_DIR/scripts"
  mkdir -p "$TARGET_DIR/.junie/mcp"
  write_mcp_json "$TARGET_DIR/.junie/mcp/mcp.json" "scripts/apple-auth-mcp-server.py"
  cp "$SCRIPT_DIR/AGENTS.md" "$TARGET_DIR/" 2>/dev/null || true
  ok "AGENTS.md"
}

install_cline() {
  log "${BOLD}Cline${RESET}"
  install_skills_to "$TARGET_DIR/.agents/skills"
  install_agents_to "$TARGET_DIR/.agents/agents"
  install_rules_to "$TARGET_DIR/.clinerules"
  install_mcp_scripts_to "$TARGET_DIR/scripts"
  cp "$SCRIPT_DIR/AGENTS.md" "$TARGET_DIR/" 2>/dev/null || true
  ok "AGENTS.md"
  log "${DIM}  Add MCP via Cline extension settings UI${RESET}"
}

install_roo() {
  log "${BOLD}Roo Code${RESET}"
  install_skills_to "$TARGET_DIR/.agents/skills"
  install_agents_to "$TARGET_DIR/.agents/agents"
  install_rules_to "$TARGET_DIR/.roo/rules"
  install_mcp_scripts_to "$TARGET_DIR/scripts"
  write_mcp_json "$TARGET_DIR/.roo/mcp.json" "scripts/apple-auth-mcp-server.py"
  cp "$SCRIPT_DIR/AGENTS.md" "$TARGET_DIR/" 2>/dev/null || true
  ok "AGENTS.md"
}

install_continue() {
  log "${BOLD}Continue.dev${RESET}"
  install_skills_to "$TARGET_DIR/.agents/skills"
  install_agents_to "$TARGET_DIR/.agents/agents"
  install_rules_to "$TARGET_DIR/.continue/rules"
  install_mcp_scripts_to "$TARGET_DIR/scripts"
  cp "$SCRIPT_DIR/AGENTS.md" "$TARGET_DIR/" 2>/dev/null || true
  ok "AGENTS.md"
  log "${DIM}  Add MCP to .continue/mcpServers/ as YAML${RESET}"
}

install_copilot() {
  log "${BOLD}GitHub Copilot${RESET}"
  install_skills_to "$TARGET_DIR/.agents/skills"
  install_agents_to "$TARGET_DIR/.agents/agents"
  install_mcp_scripts_to "$TARGET_DIR/scripts"
  # Copilot instructions
  mkdir -p "$TARGET_DIR/.github"
  cp "$SCRIPT_DIR/AGENTS.md" "$TARGET_DIR/.github/copilot-instructions.md" 2>/dev/null || true
  ok "Copilot instructions → .github/copilot-instructions.md"
  cp "$SCRIPT_DIR/AGENTS.md" "$TARGET_DIR/" 2>/dev/null || true
  ok "AGENTS.md"
  log "${DIM}  Configure MCP in GitHub repo settings${RESET}"
}

install_gemini() {
  log "${BOLD}Gemini CLI${RESET}"
  install_skills_to "$TARGET_DIR/.agents/skills"
  install_agents_to "$TARGET_DIR/.agents/agents"
  install_rules_to "$TARGET_DIR/.agents/rules"
  install_mcp_scripts_to "$TARGET_DIR/scripts"
  cp "$SCRIPT_DIR/GEMINI.md" "$TARGET_DIR/" 2>/dev/null || true
  ok "GEMINI.md"
  log "${DIM}  Run: gemini mcp add apple-auth -- python3 scripts/apple-auth-mcp-server.py${RESET}"
}

install_goose() {
  log "${BOLD}Goose (Block)${RESET}"
  install_skills_to "$TARGET_DIR/.agents/skills"
  install_agents_to "$TARGET_DIR/.agents/agents"
  install_rules_to "$TARGET_DIR/.agents/rules"
  install_mcp_scripts_to "$TARGET_DIR/scripts"
  cp "$SCRIPT_DIR/AGENTS.md" "$TARGET_DIR/" 2>/dev/null || true
  ok "AGENTS.md"
  log "${DIM}  Add MCP to goose/config.yaml${RESET}"
}

install_all() {
  install_claude;       echo
  install_cursor;       echo
  install_codex;        echo
  install_windsurf;     echo
  install_antigravity;  echo
  install_opencode;     echo
  install_amp;          echo
  install_junie;        echo
  install_cline;        echo
  install_roo;          echo
  install_continue;     echo
  install_copilot;      echo
  install_gemini;       echo
  install_goose
}

# ── Main ─────────────────────────────────────────────────────────────────────

echo
echo -e "${BOLD}  iOS Dev Agent — Installer${RESET}"
echo -e "  ========================="
echo

if [ "$TOOL" = "--list" ]; then
  echo "  Supported tools:"
  echo "    claude, cursor, codex, windsurf, antigravity, opencode,"
  echo "    amp, junie, cline, roo, continue, copilot, gemini, goose, all"
  exit 0
fi

if [ "$TOOL" = "--tool" ] && [ -n "${2:-}" ]; then
  TOOL="$2"
fi

if [ "$TOOL" = "auto" ]; then
  TOOL=$(detect_tool)
  log "${DIM}Auto-detected: ${TOOL}${RESET}"
  echo
fi

case "$TOOL" in
  claude)       install_claude ;;
  cursor)       install_cursor ;;
  codex)        install_codex ;;
  windsurf)     install_windsurf ;;
  antigravity)  install_antigravity ;;
  opencode)     install_opencode ;;
  amp)          install_amp ;;
  junie)        install_junie ;;
  cline)        install_cline ;;
  roo)          install_roo ;;
  continue)     install_continue ;;
  copilot)      install_copilot ;;
  gemini)       install_gemini ;;
  goose)        install_goose ;;
  all)          install_all ;;
  *)
    echo -e "  ${RED}Unknown tool: $TOOL${RESET}"
    echo "  Run: ./install.sh --list"
    exit 1
    ;;
esac

echo
echo -e "  ${GREEN}${BOLD}Done!${RESET} Restart your tool to activate."
echo
