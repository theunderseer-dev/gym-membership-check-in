# Architecture

## Overview

Gym Membership Check-In is a **single-device, offline** prototype. All membership data lives on the device that runs the app. There is no backend, no sync, and no account system — by design (see [ADR-001](adr/001-local-only-storage.md)).

```
┌──────────────────────────────────────────────────────────┐
│                       Presentation                       │
│   iOS:     HomeView · RegisterMemberView                 │
│            RegistrationSuccessView · CheckMembershipView │
│   Android: HomeScreen · RegisterMemberScreen             │
│            SuccessScreen · CheckMembershipScreen         │
└─────────────────────────┬────────────────────────────────┘
                          │ calls
┌─────────────────────────▼────────────────────────────────┐
│                         Domain                           │
│   Member (model)              MembershipStatus (enum)    │
│   expiry rule: today ≤ endsOnInclusive                   │
└─────────────────────────┬────────────────────────────────┘
                          │ persisted by
┌─────────────────────────▼────────────────────────────────┐
│                         Storage                          │
│   Android: Room (SQLite)                                 │
│   iOS:     JSON file via FileManager                     │
└─────────────────────────────────────────────────────┘
```

---

## Data model

```
Member
  id              String   — UUID, primary key, encoded in QR
  name            String   — client's display name
  startsOn        Date     — calendar date of registration
  endsOnInclusive Date     — startsOn + 1 calendar month
  createdAt       Date     — wall-clock timestamp of registration
```

**Expiry calculation** — one calendar month added using the platform's calendar API (`Calendar.add(Calendar.MONTH, 1)` on Android; `Calendar.date(byAdding: .month, value: 1)` on iOS). Edge case: 31 Jan → 28/29 Feb (last day of the month), matching the standard calendar behaviour on both platforms.

**Active status** — `today ≤ endsOnInclusive` (day granularity, time ignored).

---

## QR format

See [ADR-002](adr/002-qr-payload-format.md). The QR encodes only the **member ID** (a UUID string). Example payload:

```
550e8400-e29b-41d4-a716-446655440000
```

The ID is looked up in local storage on scan. No personal data is stored in the QR.

---

## User flow

```
App launch
    │
    ▼
Home screen
    ├─► Register member
    │       │
    │       ▼
    │   Enter name ──► [empty] shows validation error
    │       │
    │       ▼
    │   Registration success
    │       • Unique ID generated (UUID)
    │       • endsOnInclusive = today + 1 month
    │       • Record saved to local storage
    │       • QR rendered from member ID
    │       ├─► Share QR (system share sheet)
    │       └─► Done → Home screen
    │
    └─► Check membership
            │
            ├─► Scan QR (rear camera)
            ├─► Scan QR from saved image (photo library / file)
            └─► Enter member ID manually
                    │
                    ▼
                Look up ID in local storage
                    │
                    ├─ Found ──► Show name, expiry, ACTIVE / EXPIRED badge
                    │               ├─► Check Another Member → back to scanner
                    │               └─► To Main Screen → Home screen
                    └─ Not found ──► "NOT FOUND" with searched ID
```

### Edge cases and expected behaviour

| Situation | Expected behaviour |
|-----------|-------------------|
| Name field empty or whitespace-only | Validation error; registration blocked |
| QR image has no QR code | "No QR code found" message |
| QR image unreadable (corrupt file) | "Could not read image" message |
| Camera permission denied | Scanner replaced by "Camera Unavailable" message; photo and manual input still work |
| ID not in local storage | "NOT FOUND" result screen |
| Membership expiry = today | Status is **Active** (inclusive) |
| Membership expiry = yesterday | Status is **Expired** |
| Registration on 31 Jan | endsOnInclusive = 28 Feb (non-leap) or 29 Feb (leap year) |

---

## Platform comparison

| Concern | Android | iOS |
|---------|---------|-----|
| Navigation | `NavHost` with typed routes | `NavigationStack` with `AppRoute` enum |
| State management | `ViewModel` + `StateFlow` | `@StateObject` / `@ObservedObject` |
| Local storage | Room (DAO + Entity) | JSON encoded to `Documents/members.json` |
| QR generation | ZXing `QRCodeWriter` → `Bitmap` | `CIFilter("CIQRCodeGenerator")` → `UIImage` |
| QR decoding | ZXing `QRCodeReader` on `Bitmap` | Vision `VNDetectBarcodesRequest` on `CIImage` |
| Camera | CameraX `ImageAnalysis` | AVFoundation `AVCaptureMetadataOutput` |
| Photo input | `ActivityResultContracts.OpenDocument` | `PhotosPickerItem` (PhotosUI) |
| Share QR | `FileProvider` + `ACTION_SEND` intent | `UIActivityViewController` (ShareSheet) |
| Min OS | Android 8 (API 26) | iOS 16 |
| Tests | JUnit 4 unit tests | XCTest unit tests |

---

## Project layout

```
gym-check-in/
├── app/                            # Android app module
│   └── src/main/java/…/
│       ├── data/                   # Room DB, DAO, entities
│       ├── domain/                 # Member model, membership rules
│       └── ui/                     # Compose screens
├── ios/
│   ├── GymCheckIn.xcodeproj/       # Xcode project
│   ├── GymCheckIn/
│   │   ├── Models/Member.swift     # Data model + status logic
│   │   ├── Storage/GymRepository.swift  # JSON persistence
│   │   ├── Utilities/              # QRCodeHelper, ShareSheet
│   │   └── Views/                  # SwiftUI screens
│   └── GymCheckInTests/            # Unit tests
├── docs/
│   ├── architecture.md             # This file
│   └── adr/                        # Architecture Decision Records
├── gradle/wrapper/
├── .gitignore
└── README.md
```
