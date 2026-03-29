#!/bin/bash
# Discovers a simulator UDID, boots it if needed, and prints the UDID.
# Usage: find-simulator.sh [--name "iPhone 17 Pro"] [--runtime "iOS-26"]
set -euo pipefail

DEVICE_NAME="iPhone 17 Pro"
RUNTIME_PREFIX="iOS-26"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name) DEVICE_NAME="$2"; shift 2 ;;
    --runtime) RUNTIME_PREFIX="$2"; shift 2 ;;
    *) echo "Unknown flag: $1" >&2; exit 1 ;;
  esac
done

# Check jq
if ! command -v jq &>/dev/null; then
  echo "ERROR: jq is required. Install with: brew install jq" >&2
  exit 1
fi

# Get simulator list as JSON
DEVICES_JSON=$(xcrun simctl list devices available -j 2>/dev/null)

# Find matching device — try exact name first, then partial match
UDID=$(echo "$DEVICES_JSON" | jq -r --arg name "$DEVICE_NAME" --arg prefix "$RUNTIME_PREFIX" '
  .devices
  | to_entries[]
  | select(.key | contains($prefix))
  | .value[]
  | select(.name == $name and .isAvailable == true)
  | .udid
' | head -1)

# If no exact match, try partial name match
if [ -z "$UDID" ]; then
  UDID=$(echo "$DEVICES_JSON" | jq -r --arg name "$DEVICE_NAME" --arg prefix "$RUNTIME_PREFIX" '
    .devices
    | to_entries[]
    | select(.key | contains($prefix))
    | .value[]
    | select(.name | contains($name) and .isAvailable == true)
    | .udid
  ' | head -1)
fi

# If still no match, pick any available iOS simulator
if [ -z "$UDID" ]; then
  UDID=$(echo "$DEVICES_JSON" | jq -r --arg prefix "$RUNTIME_PREFIX" '
    .devices
    | to_entries[]
    | select(.key | contains($prefix))
    | .value[]
    | select(.isAvailable == true)
    | .udid
  ' | head -1)
fi

if [ -z "$UDID" ]; then
  echo "ERROR: No available simulator found matching name='$DEVICE_NAME' runtime='$RUNTIME_PREFIX'" >&2
  echo "Available simulators:" >&2
  xcrun simctl list devices available | grep -i "iphone\|ipad" >&2
  exit 1
fi

# Boot if shutdown
STATE=$(echo "$DEVICES_JSON" | jq -r --arg udid "$UDID" '
  .devices[][] | select(.udid == $udid) | .state
')

if [ "$STATE" = "Shutdown" ]; then
  xcrun simctl boot "$UDID" 2>/dev/null || true
  # Wait for boot
  sleep 2
fi

echo "$UDID"
