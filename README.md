# Gym Membership Check-In

A lightweight, native prototype for gym reception staff to **register clients** and **verify membership status** using a digital QR pass — no server or internet connection required.

> Built to demonstrate that a fully functional membership workflow can run on a single mobile device in a matter of hours. Useful as a foundation for a production check-in system or as a reference for rapid MVP development.
>
> The entire prototype — Android app, iOS app, unit tests, documentation, and architecture decisions — was built using [Antigravity](https://antigravity.google) by Google DeepMind.

---

## What it does

| Step | Staff action | What happens |
|------|-------------|--------------|
| 1 | Tap **Register member**, enter client name & take photo | App creates a 1-calendar-month pass, links member photo, and generates a unique ID |
| 2 | Tap **Share QR** | A QR image is shared — the client saves it to their phone |
| 3 | Tap **Check membership**, scan / upload QR or enter ID | App shows **Active** / **Expired** status, expiry date, and the **member's photo** to verify identity |

Membership is active **through** the expiry date (inclusive). A pass issued on 2 Feb expires at end of day 2 Mar.

---

## Platforms

| | Android | iOS |
|--|---------|-----|
| Language | Kotlin | Swift |
| UI | Jetpack Compose | SwiftUI |
| Storage | Room (SQLite) | JSON file (FileManager) |
| Camera scanning | CameraX + ZXing | AVFoundation + Vision |
| QR generation | ZXing | CoreImage (CIFilter) |
| Min version | API 26 (Android 8) | iOS 16 |

Both apps share the same QR format and membership rules, so an Android-registered QR can be verified on an iOS device and vice versa.

---

## Quick start

### Android

```bash
# Build debug APK
./gradlew assembleDebug

# Install on connected device / emulator
adb install app/build/outputs/apk/debug/app-debug.apk
```

Requires Android Studio with JDK 17 or 21.

### iOS

```bash
# Build for iOS Simulator
xcodebuild -project ios/GymCheckIn.xcodeproj \
  -scheme GymCheckIn \
  -sdk iphonesimulator \
  -configuration Debug \
  build CODE_SIGNING_ALLOWED=NO
```

For a physical iPhone, open `ios/GymCheckIn.xcodeproj` in Xcode, set your team under **Signing & Capabilities**, and press ⌘R.

---

## Docs

- **[Architecture & design](docs/architecture.md)** — layers, data model, QR format, edge cases, platform comparison.
- **ADRs** — key decisions with context and rationale:
  - [ADR-001 Local-only storage](docs/adr/001-local-only-storage.md)
  - [ADR-002 QR payload format](docs/adr/002-qr-payload-format.md)
  - [ADR-003 Separate native apps per platform](docs/adr/003-native-per-platform.md)

---

## Author

Built by [Yevhen Volboienko](https://www.linkedin.com/in/yevhen-volboienko/) — Senior Android Engineer.
