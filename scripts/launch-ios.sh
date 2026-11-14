#!/bin/bash
set -e

# ==============================================================================
# Sweetpad-equivalent Build & Run (Launch) script for Omakase iOS
# Builds the iOS project, installs it onto the connected physical device (or simulator),
# and immediately launches the app.
# ==============================================================================

WORKSPACE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$WORKSPACE_ROOT/omakase"

# 1. Target physical iPhone (Kuzey iPhone'u)
DEVICE_ID="ADFC2ADA-EA3F-51A7-9C82-E2554869B97D"

echo "🚀 Target Device: $DEVICE_ID"
echo "🔨 Building Omakase scheme..."
xcodebuild -scheme omakase -configuration Debug -destination "generic/platform=iOS" -allowProvisioningUpdates build -quiet

# 2. Find built .app in Xcode DerivedData
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/omakase-*/Build/Products/Debug-iphoneos/omakase.app -maxdepth 0 2>/dev/null | head -n 1)

if [ -z "$APP_PATH" ] || [ ! -d "$APP_PATH" ]; then
    echo "❌ Built omakase.app not found in DerivedData"
    exit 1
fi

echo "📦 Installing app onto device: $APP_PATH"
for attempt in 1 2 3; do
    if xcrun devicectl device install app --device "$DEVICE_ID" "$APP_PATH"; then
        break
    fi
    if [ "$attempt" -eq 3 ]; then
        echo "❌ Failed to install app onto device after 3 attempts."
        exit 1
    fi
    echo "⚠️ Transient device connection reset (attempt $attempt/3); retrying install..."
    sleep 1
done

echo "✨ Launching kuzeysinay.omakase on device..."
if LAUNCH_OUT=$(xcrun devicectl device process launch --device "$DEVICE_ID" kuzeysinay.omakase 2>&1); then
    echo "$LAUNCH_OUT"
    echo "🎉 Build & Run (Launch) completed successfully!"
else
    if echo "$LAUNCH_OUT" | grep -q "Locked"; then
        echo "ℹ️ App built and installed on device ($DEVICE_ID). Device screen is currently locked; unlock your iPhone to open Omakase."
        exit 0
    fi
    echo "$LAUNCH_OUT" >&2
    exit 1
fi
