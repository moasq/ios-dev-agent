---
name: "screenshots"
description: "Use when capturing simulator screenshots for UI review. Builds the app, installs on simulator, launches, and captures screenshots automatically."
---

# Screenshots

Build, install, launch, and capture simulator screenshots.

## Quick Start

```bash
bash "$CLAUDE_PROJECT_DIR/.claude/scripts/capture-screenshots.sh"
```

## Options

```bash
# Specific device
bash .claude/scripts/capture-screenshots.sh --device "iPhone Air"

# Custom output directory
bash .claude/scripts/capture-screenshots.sh --output ./my-screenshots

# Custom bundle ID
bash .claude/scripts/capture-screenshots.sh --bundle-id com.mohammeds.migrainai

# Longer wait for complex UI
bash .claude/scripts/capture-screenshots.sh --wait 6
```

## Multi-Device Screenshots

```bash
for device in "iPhone 17 Pro" "iPhone Air" "iPad Pro 13-inch (M5)"; do
  bash .claude/scripts/capture-screenshots.sh --device "$device" --output "./screenshots/$device"
done
```

## View Screenshots

Use the Read tool to view captured PNG files — Claude Code displays images directly.

## Troubleshooting

| Issue | Cause | Fix |
|---|---|---|
| Blank screenshot | App didn't render in time | Increase `--wait` to 6-8 seconds |
| App crashes on launch | Runtime error | Check console: `xcrun simctl launch --console UDID bundle.id` |
| Build fails first | Compilation error | Run `/build` first to diagnose |
| Wrong app version | Stale install | `xcrun simctl uninstall UDID bundle.id` then retry |
| Simulator not found | Name mismatch | Check available: `xcrun simctl list devices available` |
