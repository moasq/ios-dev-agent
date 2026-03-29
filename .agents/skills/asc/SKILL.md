---
name: "asc"
description: "Use when managing App Store Connect operations. Covers asc CLI setup, TestFlight distribution, app submission, signing profiles, and build management."
---

# App Store Connect

Manage App Store Connect via the `asc` CLI tool.

## Install

```bash
brew install asc
```

## Authenticate

```bash
asc auth login \
  --name "MigrainAI" \
  --key-id "$ASC_KEY_ID" \
  --issuer-id "$ASC_ISSUER_ID" \
  --private-key "$ASC_KEY_PATH"
```

Credentials are stored in macOS Keychain after first login.

## Install Claude Code Skills (optional)

```bash
asc install-skills
```

Adds 13+ pre-built ASC skills for Claude Code.

## Common Operations

```bash
# List your apps
asc apps list

# List builds
asc builds list

# Upload IPA to TestFlight
asc testflight builds add --ipa-path ./MigrainAI.ipa

# List TestFlight testers
asc testflight beta-testers list

# Submit for App Store review
asc versions submit --app-id APP_ID

# Manage signing
asc certificates list
asc provisioning-profiles list
asc bundle-ids list

# Register a test device
asc devices register --name "My iPhone" --udid "DEVICE_UDID"
```

## Archive + Upload Workflow

```bash
# 1. Archive
xcodebuild archive \
  -project MigrainAI.xcodeproj \
  -scheme MigrainAI \
  -archivePath ./build/MigrainAI.xcarchive \
  -destination "generic/platform=iOS"

# 2. Export IPA
xcodebuild -exportArchive \
  -archivePath ./build/MigrainAI.xcarchive \
  -exportPath ./build \
  -exportOptionsPlist ExportOptions.plist

# 3. Upload to TestFlight
asc testflight builds add --ipa-path ./build/MigrainAI.ipa
```

## Reference

- [setup-guide.md](reference/setup-guide.md) — API key generation, credential setup
- [workflows.md](reference/workflows.md) — full submission workflow
