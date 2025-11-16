# HeyCyan Demo App

Quick demo app I built to integrate the HeyCyan Smart Glasses SDK. It's a simple SwiftUI app that shows how to connect to the glasses and do basic stuff like getting version info, checking battery, and triggering photo mode.

## What it does

The app has buttons for:
- Scanning for nearby HeyCyan glasses via Bluetooth
- Connecting to a discovered device
- Getting device version (hardware/firmware info)
- Checking battery level
- Setting the device to photo mode

Everything gets logged on screen so you can see what's happening in real-time.

## How it's built

I used SwiftUI for the UI and put all the SDK interaction logic in a ViewModel (`GlassesViewModel`). The SDK is Objective-C based, so I had to set up a bridging header to use it from Swift.

The main files:
- `ContentView.swift` - the UI
- `ViewModels/GlassesViewModel.swift` - handles all the SDK calls
- `QCCentralManager.h/.m` - the Bluetooth manager (copied from the SDK examples)
- `HeyCyanDemoApp-Bridging-Header.h` - lets Swift talk to the Objective-C SDK

## Setup

You'll need:
- iOS 15.6 or later
- Xcode 14+
- A physical iPhone/iPad (Bluetooth doesn't work in simulator)

To run it:
1. Make sure you have the HeyCyanSmartGlassesSDK repo cloned at `../HeyCyanSmartGlassesSDK/` (relative to this project)
2. Open `HeyCyanDemoApp.xcodeproj`
3. Build and run on a real device

## Testing

Honestly, you can't really test the full functionality without actual HeyCyan glasses. Without the hardware, you can at least verify:
- The app builds and runs
- The UI looks right
- Error messages show up when there are no devices (like "No devices found" when scanning)

Once you have the glasses, just tap the buttons and watch the log to see what happens.

## Notes

The SDK uses Objective-C delegates for callbacks, so I wrapped those in `Task { @MainActor in }` blocks to make sure UI updates happen on the main thread. The app handles errors gracefully and logs everything so it's easy to debug.

If you run into any issues building it, make sure the QCSDK.framework path is correct and the bridging header is set up properly in the build settings.
