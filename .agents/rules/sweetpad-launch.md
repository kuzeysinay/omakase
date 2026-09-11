# Auto Build & Run (Sweetpad Launch) Rule

After making any modifications, bug fixes, or UI changes to the iOS project (`omakase/`):

1. **Auto-Execute Build & Run (Sweetpad Launch):**
   - Automatically run `/Users/kuzey/projects/omakase/scripts/launch-ios.sh` via `run_command`.
   - This script executes the exact Sweetpad "Build and run (Launch)" sequence:
     1. Automatically identifies the connected physical iPhone (`ADFC2ADA-EA3F-51A7-9C82-E2554869B97D` / `Kuzey iPhone’u`).
     2. Runs `xcodebuild -scheme omakase -destination "id=$DEVICE_ID" build -quiet`.
     3. Installs the updated bundle onto the physical device using `xcrun devicectl device install app`.
     4. Immediately launches `kuzeysinay.omakase` on the device using `xcrun devicectl device process launch`.

2. **Verification:**
   - Confirm that the build succeeded and the app was launched on the device.
   - Inform the user that the app has been built, installed, and launched on their iPhone.
