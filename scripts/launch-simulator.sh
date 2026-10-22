#!/bin/bash
set -e

# ==============================================================================
# Build & Run (Launch) script for Omakase iOS on iOS Simulator
# ==============================================================================

WORKSPACE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$WORKSPACE_ROOT/omakase"

# 1. Ensure a simulator is booted, if none booted pick iPhone 17
BOOTED_ID=$(xcrun simctl list devices | grep -E "Booted" | grep -E -o '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}' | head -n 1)

if [ -z "$BOOTED_ID" ]; then
    BOOTED_ID="45BCCBC2-5804-4E7A-BF2C-8E3FE4C47134"
    echo "📱 Booting simulator: $BOOTED_ID..."
    xcrun simctl boot "$BOOTED_ID" || true
fi

open -a Simulator

echo "🚀 Target Simulator: $BOOTED_ID"
echo "🔨 Building Omakase scheme for Simulator..."
xcodebuild -scheme omakase -configuration Debug -destination "id=$BOOTED_ID" build -quiet

APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/omakase-*/Build/Products/Debug-iphonesimulator/omakase.app -maxdepth 0 2>/dev/null | head -n 1)

if [ -z "$APP_PATH" ] || [ ! -d "$APP_PATH" ]; then
    echo "❌ Built omakase.app not found in DerivedData"
    exit 1
fi

echo "📦 Installing app onto simulator: $APP_PATH"
xcrun simctl install "$BOOTED_ID" "$APP_PATH"

echo "✨ Launching kuzeysinay.omakase on simulator..."
xcrun simctl launch "$BOOTED_ID" kuzeysinay.omakase

echo "🎉 Build & Run on Simulator completed successfully!"
