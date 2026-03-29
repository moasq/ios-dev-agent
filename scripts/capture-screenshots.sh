#!/bin/bash
# Builds, installs, launches app on simulator, and captures screenshots.
# Usage: capture-screenshots.sh [--device "iPhone 17 Pro"] [--output ./screenshots] [--bundle-id com.app.id]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
DEVICE_NAME=""
OUTPUT_DIR="$PROJECT_DIR/screenshots"
BUNDLE_ID=""
WAIT_SECONDS=4

while [[ $# -gt 0 ]]; do
  case "$1" in
    --device) DEVICE_NAME="$2"; shift 2 ;;
    --output) OUTPUT_DIR="$2"; shift 2 ;;
    --bundle-id) BUNDLE_ID="$2"; shift 2 ;;
    --wait) WAIT_SECONDS="$2"; shift 2 ;;
    *) echo "Unknown flag: $1" >&2; exit 1 ;;
  esac
done

cd "$PROJECT_DIR"

# Auto-detect bundle ID from project_config.json or project.yml
if [ -z "$BUNDLE_ID" ]; then
  if [ -f "project_config.json" ]; then
    BUNDLE_ID=$(jq -r '.bundle_id // empty' project_config.json 2>/dev/null || true)
  fi
  if [ -z "$BUNDLE_ID" ] && [ -f "project.yml" ]; then
    BUNDLE_ID=$(grep -A1 'PRODUCT_BUNDLE_IDENTIFIER' project.yml | tail -1 | tr -d ' "' || true)
  fi
  if [ -z "$BUNDLE_ID" ]; then
    echo "ERROR: Could not detect bundle ID. Use --bundle-id flag." >&2
    exit 1
  fi
fi

# Get simulator UDID
FIND_SIM_ARGS=()
if [ -n "$DEVICE_NAME" ]; then
  FIND_SIM_ARGS+=(--name "$DEVICE_NAME")
fi
UDID=$("$SCRIPT_DIR/find-simulator.sh" "${FIND_SIM_ARGS[@]}")

echo "Target simulator: $UDID"
echo "Bundle ID: $BUNDLE_ID"

# Build
echo "Building..."
"$SCRIPT_DIR/xcode-build.sh" --device "${DEVICE_NAME:-iPhone 17 Pro}" --project-dir "$PROJECT_DIR"

# Find the built .app
SCHEME=$(find . -maxdepth 1 -name "*.xcodeproj" -type d | head -1 | xargs basename | sed 's/.xcodeproj//')
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "${SCHEME}.app" -path "*/Build/Products/Debug-iphonesimulator/*" -type d 2>/dev/null | head -1)

if [ -z "$APP_PATH" ]; then
  echo "ERROR: Could not find built .app in DerivedData" >&2
  exit 1
fi

echo "Found app: $APP_PATH"

# Install
echo "Installing on simulator..."
xcrun simctl install "$UDID" "$APP_PATH"

# Launch
echo "Launching..."
xcrun simctl launch "$UDID" "$BUNDLE_ID" 2>/dev/null || true

# Wait for rendering
echo "Waiting ${WAIT_SECONDS}s for app to render..."
sleep "$WAIT_SECONDS"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Capture screenshot
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SCREENSHOT_PATH="$OUTPUT_DIR/screenshot_${TIMESTAMP}.png"
xcrun simctl io "$UDID" screenshot "$SCREENSHOT_PATH"

echo "Screenshot captured: $SCREENSHOT_PATH"
