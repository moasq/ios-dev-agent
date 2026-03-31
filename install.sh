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
CYAN='\033[36m'
DIM='\033[2m'
BOLD='\033[1m'
RESET='\033[0m'

log() { echo -e "  $1"; }
ok() { echo -e "  ${GREEN}+${RESET} $1"; }
skip() { echo -e "  ${DIM}- $1${RESET}"; }

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

# ── Installers ───────────────────────────────────────────────────────────────

install_agents_skills() {
  mkdir -p "$TARGET_DIR/.agents"
  cp -R "$SCRIPT_DIR/.agents/skills" "$TARGET_DIR/.agents/"
  cp -R "$SCRIPT_DIR/.agents/agents" "$TARGET_DIR/.agents/" 2>/dev/null || true
  ok "Installed .agents/skills/ ($(ls "$TARGET_DIR/.agents/skills/" | wc -l | tr -d ' ') skills)"
}

install_scripts() {
  mkdir -p "$TARGET_DIR/scripts"
  cp "$SCRIPT_DIR/scripts/apple-developer-auth.py" "$TARGET_DIR/scripts/"
  cp "$SCRIPT_DIR/scripts/apple-auth-mcp-server.py" "$TARGET_DIR/scripts/"
  chmod +x "$TARGET_DIR/scripts/"*.py
  ok "Installed MCP server scripts"
}

install_rules() {
  local dest="$1"
  mkdir -p "$dest"
  cp "$SCRIPT_DIR/rules/"*.md "$dest/"
  ok "Installed rules to $dest"
}

install_claude() {
  log "${BOLD}Claude Code${RESET}"
  # Claude gets a self-contained .claude/ — no .agents/, no symlinks
  mkdir -p "$TARGET_DIR/.claude"
  cp -R "$SCRIPT_DIR/.agents/skills" "$TARGET_DIR/.claude/skills"
  ok "Installed .claude/skills/ ($(ls "$TARGET_DIR/.claude/skills/" | wc -l | tr -d ' ') skills)"
  cp -R "$SCRIPT_DIR/.agents/agents" "$TARGET_DIR/.claude/agents" 2>/dev/null || true
  ok "Installed .claude/agents/"
  install_rules "$TARGET_DIR/.claude/rules"
  # Scripts go inside .claude/scripts
  mkdir -p "$TARGET_DIR/.claude/scripts"
  cp "$SCRIPT_DIR/scripts/"* "$TARGET_DIR/.claude/scripts/"
  chmod +x "$TARGET_DIR/.claude/scripts/"*.py "$TARGET_DIR/.claude/scripts/"*.sh 2>/dev/null || true
  ok "Installed .claude/scripts/"
  # Hooks — copy hook scripts into .claude/hooks
  mkdir -p "$TARGET_DIR/.claude/hooks"
  cp "$SCRIPT_DIR/scripts/log-build-error.sh" "$TARGET_DIR/.claude/hooks/" 2>/dev/null || true
  cp "$SCRIPT_DIR/scripts/log-build-resolution.sh" "$TARGET_DIR/.claude/hooks/" 2>/dev/null || true
  cp "$SCRIPT_DIR/scripts/log-test-failure.sh" "$TARGET_DIR/.claude/hooks/" 2>/dev/null || true
  cp "$SCRIPT_DIR/scripts/on-build-success.sh" "$TARGET_DIR/.claude/hooks/" 2>/dev/null || true
  chmod +x "$TARGET_DIR/.claude/hooks/"*.sh 2>/dev/null || true
  ok "Installed .claude/hooks/"
  # Error ledger
  mkdir -p "$TARGET_DIR/.claude/errors"
  cp "$SCRIPT_DIR/errors/errors.md" "$TARGET_DIR/.claude/errors/" 2>/dev/null || true
  ok "Installed .claude/errors/errors.md"
  # Settings template
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
        "hooks": [
          {
            "type": "command",
            "command": "./.claude/scripts/check-project-config-edits.sh"
          }
        ]
      },
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "./.claude/scripts/check-bash-safety.sh"
          }
        ]
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
        "hooks": [
          { "type": "command", "command": "./.claude/hooks/log-build-error.sh" }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          { "type": "command", "command": "./.claude/hooks/on-build-success.sh" }
        ]
      }
    ]
  }
}
SETTINGS
    ok "Created .claude/settings.json"
  else
    skip ".claude/settings.json already exists"
  fi
  # CLAUDE.md
  cp "$SCRIPT_DIR/CLAUDE.md" "$TARGET_DIR/" 2>/dev/null || true
  ok "Installed CLAUDE.md"
  # MCP config — paths relative to .claude/scripts
  if [ ! -f "$TARGET_DIR/.mcp.json" ]; then
    echo '{"mcpServers":{"apple-auth":{"command":"python3","args":[".claude/scripts/apple-auth-mcp-server.py"]}}}' > "$TARGET_DIR/.mcp.json"
    ok "Created .mcp.json"
  else
    skip ".mcp.json already exists — add apple-auth MCP manually"
  fi
  ok "Claude Code setup complete"
}

install_cursor() {
  log "${BOLD}Cursor${RESET}"
  install_agents_skills
  mkdir -p "$TARGET_DIR/.cursor/rules"
  cp "$SCRIPT_DIR/.cursor/rules/"*.mdc "$TARGET_DIR/.cursor/rules/"
  ok "Installed .cursor/rules/ (.mdc format)"
  install_scripts
  if [ ! -f "$TARGET_DIR/.cursor/mcp.json" ]; then
    cp "$SCRIPT_DIR/.cursor/mcp.json" "$TARGET_DIR/.cursor/mcp.json"
    ok "Created .cursor/mcp.json"
  else
    skip ".cursor/mcp.json already exists"
  fi
  ok "Cursor setup complete"
}

install_codex() {
  log "${BOLD}Codex${RESET}"
  install_agents_skills
  install_scripts
  cp "$SCRIPT_DIR/AGENTS.md" "$TARGET_DIR/" 2>/dev/null || true
  ok "Installed AGENTS.md"
  ok "Codex setup complete — run: codex mcp add apple-auth -- python3 scripts/apple-auth-mcp-server.py"
}

install_windsurf() {
  log "${BOLD}Windsurf${RESET}"
  install_agents_skills
  install_rules "$TARGET_DIR/.windsurf/rules"
  install_scripts
  ok "Windsurf setup complete — add MCP to ~/.codeium/windsurf/mcp_config.json"
}

install_opencode() {
  log "${BOLD}OpenCode${RESET}"
  install_agents_skills
  install_rules "$TARGET_DIR/.opencode/rules"
  install_scripts
  mkdir -p "$TARGET_DIR/.opencode/skills"
  ln -sf ../../.agents/skills "$TARGET_DIR/.opencode/skills" 2>/dev/null || true
  cp "$SCRIPT_DIR/AGENTS.md" "$TARGET_DIR/" 2>/dev/null || true
  ok "OpenCode setup complete — add MCP to opencode.json"
}

install_antigravity() {
  log "${BOLD}Antigravity${RESET}"
  install_agents_skills
  install_scripts
  cp "$SCRIPT_DIR/GEMINI.md" "$TARGET_DIR/" 2>/dev/null || true
  ok "Installed GEMINI.md"
  ok "Antigravity setup complete — add MCP to ~/.gemini/antigravity/mcp_config.json"
}

install_amp() {
  log "${BOLD}Amp${RESET}"
  install_agents_skills
  install_scripts
  cp "$SCRIPT_DIR/AGENTS.md" "$TARGET_DIR/" 2>/dev/null || true
  ok "Amp setup complete — add MCP to ~/.config/amp/settings.json"
}

install_junie() {
  log "${BOLD}Junie${RESET}"
  install_agents_skills
  install_scripts
  mkdir -p "$TARGET_DIR/.junie/mcp"
  cp "$SCRIPT_DIR/.junie/mcp/mcp.json" "$TARGET_DIR/.junie/mcp/"
  cp "$SCRIPT_DIR/AGENTS.md" "$TARGET_DIR/" 2>/dev/null || true
  ok "Junie setup complete"
}

install_cline() {
  log "${BOLD}Cline${RESET}"
  install_agents_skills
  install_rules "$TARGET_DIR/.clinerules"
  install_scripts
  ok "Cline setup complete — add MCP via Cline extension settings"
}

install_roo() {
  log "${BOLD}Roo Code${RESET}"
  install_agents_skills
  install_rules "$TARGET_DIR/.roo/rules"
  install_scripts
  cp "$SCRIPT_DIR/.roo/mcp.json" "$TARGET_DIR/.roo/"
  ok "Roo Code setup complete"
}

install_continue() {
  log "${BOLD}Continue.dev${RESET}"
  install_agents_skills
  install_rules "$TARGET_DIR/.continue/rules"
  install_scripts
  ok "Continue setup complete — add MCP to .continue/mcpServers/"
}

install_all() {
  install_claude
  echo
  install_cursor
  echo
  install_codex
  echo
  install_windsurf
  echo
  install_opencode
  echo
  install_antigravity
  echo
  install_amp
  echo
  install_junie
  echo
  install_cline
  echo
  install_roo
  echo
  install_continue
}

# ── Main ─────────────────────────────────────────────────────────────────────

echo
echo -e "${BOLD}  iOS Dev Agent — Installer${RESET}"
echo -e "  ========================="
echo

if [ "$TOOL" = "--list" ]; then
  echo "  Supported tools:"
  echo "    claude, cursor, codex, windsurf, opencode,"
  echo "    antigravity, amp, junie, cline, roo, continue, all"
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
  opencode)     install_opencode ;;
  antigravity)  install_antigravity ;;
  amp)          install_amp ;;
  junie)        install_junie ;;
  cline)        install_cline ;;
  roo)          install_roo ;;
  continue)     install_continue ;;
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
