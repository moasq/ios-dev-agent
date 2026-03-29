# ASC Workflows

## TestFlight Distribution

```bash
# 1. Build archive
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

# 3. Upload
asc testflight builds add --ipa-path ./build/MigrainAI.ipa

# 4. Check processing status
asc builds list --output json | jq '.[] | select(.processingState != "VALID")'

# 5. Add testers
asc testflight beta-testers add --email "tester@example.com" --first-name "Test" --last-name "User"
```

## App Store Submission

```bash
# 1. Create new version
asc versions create --app-id APP_ID --version "1.0.0" --platform iOS

# 2. Upload build (same as TestFlight)
asc testflight builds add --ipa-path ./build/MigrainAI.ipa

# 3. Select build for version
asc versions set-build --app-id APP_ID --build-id BUILD_ID

# 4. Submit for review
asc versions submit --app-id APP_ID
```

## Code Signing Management

```bash
# List certificates
asc certificates list

# List provisioning profiles
asc provisioning-profiles list

# List registered bundle IDs
asc bundle-ids list

# Register new bundle ID
asc bundle-ids register --name "MigrainAI" --identifier "com.mohammeds.migrainai"

# Register test device
asc devices register --name "My iPhone" --udid "00001111-..."
```

## ExportOptions.plist

Create this file for IPA export:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>destination</key>
    <string>upload</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
</dict>
</plist>
```
