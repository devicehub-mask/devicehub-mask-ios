# DeviceHub Mask for iOS

Native iOS client for connecting to a `devicehub-headless` server. The app uses only Apple frameworks:

- SwiftUI for the app shell and device workflow.
- `URLSession` and `URLSessionWebSocketTask` for authenticated HTTP/WebSocket transport.
- Foundation Bonjour discovery for `_devicehub._tcp.local.`.
- AVFoundation/CoreMedia for native HEVC sample-buffer rendering and PCM audio.
- Security Keychain for the saved server token.

The client does not connect to an iPhone over USB. The existing DeviceHub Mask desktop/headless host keeps ownership of CoreDevice, usbmuxd, Developer Disk Image, and device services. This app is the remote iPhone/iPad controller for that host.

## Features

- Bonjour discovery plus manual server entry.
- Up to 20 recent servers with one-tap reconnect; access tokens remain in the device Keychain.
- Native HEVC video, PCM audio, multi-touch, hardware buttons, app switching, and rotation.
- Automatic discovery, automatic reconnect, audio, and stream-metric preferences.
- An in-app About page with the installed version and build number.

## Requirements

- Xcode 26.2 or newer.
- iOS 26.0 or newer.
- A running DeviceHub Mask headless host with LAN access enabled.
- A valid access token from the headless host.

## Build

```sh
xcodebuild -project DeviceHubMask.xcodeproj \
  -scheme DeviceHubMask \
  -sdk iphonesimulator \
  -configuration Debug \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Run the core protocol tests with Swift Package Manager:

```sh
swift test
```

## Sideload and SideStore

The repository includes a LiveContainer-style GitHub Actions pipeline in `.github/workflows/build.yml`.

- Pull requests and branch pushes archive an iOS device build without Apple signing.
- Pushes to the default branch publish `DeviceHubMask.ipa` to the `nightly` Release.
- Tags matching `v*` publish a versioned GitHub Release.
- Each IPA is accompanied by a SHA-256 checksum.

Add the following source to SideStore or AltStore:

```text
https://raw.githubusercontent.com/boa-z/devicehub-mask-ios/main/.github/apps.json
```

The feed points to an unsigned IPA. SideStore or AltStore applies the user's signing identity during installation; the GitHub Action does not contain or use a certificate.

To package a local archive:

```sh
xcodebuild archive \
  -project DeviceHubMask.xcodeproj \
  -scheme DeviceHubMask \
  -sdk iphoneos \
  -configuration Release \
  -archivePath /tmp/DeviceHubMask.xcarchive \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  DEVELOPMENT_TEAM=""

scripts/build_unsigned_ipa.sh \
  /tmp/DeviceHubMask.xcarchive \
  /tmp/DeviceHubMask.ipa
```

## Connection flow

1. Start the headless server with `--listen 0.0.0.0:8080 --allow-lan` and a protected token.
2. Allow Local Network access when iOS asks.
3. Select a Bonjour-discovered server or enter its address manually.
4. Paste the access token, or paste the complete URL printed by the server.
5. Pair/connect a device, then open its control surface.

The WebSocket client negotiates protocol version 1, `DHV2` HEVC, `DHA1` PCM audio, multi-touch, and hardware-button input. Video ingress is acknowledged with `browser_frame_accepted` to preserve the server's bounded frame pipeline.

Control is protected by a device-scoped lease. The first WebSocket client connected to a device receives control; additional clients remain view-only and take over automatically after the current controller disconnects.

## Repository layout

```text
DeviceHubMask/Core/       Shared protocol, HTTP, WebSocket, packet, and touch logic
DeviceHubMask/App/        App state, Bonjour discovery, and session orchestration
DeviceHubMask/Media/      AVFoundation/CoreMedia native media sinks
DeviceHubMask/Views/      SwiftUI screens and UIKit touch bridge
Tests/                    Swift Package protocol and geometry tests
```
