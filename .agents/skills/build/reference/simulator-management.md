# Simulator Management

## List Available Simulators

```bash
xcrun simctl list devices available
# JSON format (for parsing):
xcrun simctl list devices available -j
```

## Boot / Shutdown

```bash
xcrun simctl boot UDID
xcrun simctl shutdown UDID
xcrun simctl shutdown all    # Shutdown all running sims
```

## Install & Launch

```bash
xcrun simctl install UDID /path/to/App.app
xcrun simctl launch UDID com.bundle.id
xcrun simctl launch --console UDID com.bundle.id  # With stdout
```

## Screenshots

```bash
xcrun simctl io UDID screenshot /path/to/output.png
```

## Reset / Erase

```bash
xcrun simctl erase UDID       # Factory reset one sim
xcrun simctl erase all         # Factory reset all sims
```

## Open URL in Simulator

```bash
xcrun simctl openurl UDID "https://example.com"
xcrun simctl openurl UDID "myapp://deeplink"
```

## Privacy Permissions (for testing)

```bash
# Grant location permission
xcrun simctl privacy UDID grant location com.bundle.id

# Grant health permission
xcrun simctl privacy UDID grant health com.bundle.id

# Reset all permissions
xcrun simctl privacy UDID reset all com.bundle.id
```

## Diagnostics

```bash
xcrun simctl diagnose         # Full diagnostic bundle
xcrun simctl get_app_container UDID com.bundle.id  # App sandbox path
```
