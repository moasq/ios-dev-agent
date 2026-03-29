# Build Flags Reference

## xcodebuild Command

```bash
xcodebuild \
  -project App.xcodeproj \
  -scheme App \
  -destination "platform=iOS Simulator,id=UDID" \
  -quiet \
  build \
  CODE_SIGNING_ALLOWED=NO
```

## Key Flags

| Flag | Purpose |
|---|---|
| `-project` | Path to .xcodeproj |
| `-scheme` | Build scheme name |
| `-destination` | Target device/simulator |
| `-quiet` | Minimal output (errors only) |
| `-derivedDataPath` | Custom build artifacts location |
| `CODE_SIGNING_ALLOWED=NO` | Skip code signing for simulator |

## Destination Formats

```bash
# Simulator by UDID (most reliable)
-destination "platform=iOS Simulator,id=BCDEE28F-9718-42CC-A78D-1F890D421702"

# Simulator by name
-destination "platform=iOS Simulator,name=iPhone 17 Pro"

# Generic (for archiving)
-destination "generic/platform=iOS"
```

## Build Actions

| Action | Purpose |
|---|---|
| `build` | Compile for debugging |
| `clean build` | Delete artifacts then build |
| `test` | Run unit/UI tests |
| `archive` | Build release archive |

## Build with Sanitizers (for debugging)

```bash
xcodebuild test \
  -scheme App \
  -destination "platform=iOS Simulator,id=UDID" \
  -enableThreadSanitizer YES \
  -enableAddressSanitizer YES
```

## Project Build Settings

| Setting | Value | Purpose |
|---|---|---|
| SWIFT_VERSION | 6 | Swift 6 strict mode |
| SWIFT_STRICT_CONCURRENCY | complete | Data races are compile errors |
| SWIFT_APPROACHABLE_CONCURRENCY | YES | Better concurrency diagnostics |
| SWIFT_DEFAULT_ACTOR_ISOLATION | MainActor | Default to @MainActor |
