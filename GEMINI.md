# Workspace Rules for Omakase

## iOS Development & Sweetpad Launch Workflow

Whenever code changes, bug fixes, or UI updates are made in the iOS app (`omakase/`):

1. **Auto-Run Build & Launch (Sweetpad Equivalent):**
   - Automatically execute `/Users/kuzey/projects/omakase/scripts/launch-ios.sh` using `run_command`.
   - This script runs the exact workflow triggered by Sweetpad's `SweetPad: Build & Run (Launch)`:
     - Automatically targets the connected physical iPhone (`ADFC2ADA-EA3F-51A7-9C82-E2554869B97D`).
     - Builds the Xcode project (`xcodebuild`).
     - Installs the application bundle via `xcrun devicectl device install app`.
     - Automatically launches `kuzeysinay.omakase` on the device via `xcrun devicectl device process launch`.
2. Ensure the build and device launch exit with code 0 before concluding the task.
