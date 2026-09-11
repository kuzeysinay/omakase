#!/bin/bash
set -e

# ==============================================================================
# Sweetpad-equivalent Build & Run (Launch) script for Omakase iOS
# Builds the iOS project, installs it onto the connected physical device (or simulator),
# and immediately launches the app.
# ==============================================================================

WORKSPACE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$WORKSPACE_ROOT/omakase"

# 1. Detect target physical device UUID, fallback to paired iPhone if not parsed
DEVICE_ID=$(xcrun devicectl list devices 2>/dev/null | grep -E -o '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}' | head -n 1)
if [ -z "$DEVICE_ID" ]; then
    DEVICE_ID="ADFC2ADA-EA3F-51A7-9C82-E2554869B97D"
fi

echo "🚀 Target Device: $DEVICE_ID"
echo "🔨 Building Omakase scheme..."
xcodebuild -scheme omakase -destination "id=$DEVICE_ID" build -quiet

# 2. Find built .app in Xcode DerivedData
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/omakase-*/Build/Products/Debug-iphoneos/omakase.app -maxdepth 0 2>/dev/null | head -n 1)

if [ -z "$APP_PATH" ] || [ ! -d "$APP_PATH" ]; then
    echo "❌ Built omakase.app not found in DerivedData"
    exit 1
fi

echo "📦 Installing app onto device: $APP_PATH"
xcrun devicectl device install app --device "$DEVICE_ID" "$APP_PATH"

echo "✨ Launching kuzeysinay.omakase on device..."
xcrun devicectl device process launch --device "$DEVICE_ID" kuzeysinay.omakase

echo "🎉 Build & Run (Launch) completed successfully!"
