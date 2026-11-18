# Architecture

## Overview

Gym Membership Check-In is a **single-device, offline** prototype. All membership data lives on the device that runs the app. There is no backend, no sync, and no account system — by design (see [ADR-001](adr/001-local-only-storage.md)).

```
┌──────────────────────────────────────────────────────────┐
│                       Presentation                       │
│   iOS:     HomeView · RegisterMemberView                 │
│            RegistrationSuccessView · CheckMembershipView │
│            MemberPhotoCaptureView                        │
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
│   iOS:     JSON file via FileManager + local photos      │
└──────────────────────────────────────────────────────────┘
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
  photoFileName   String?  — local photo filename (<id>.jpg) for identity verification
```

**Expiry calculation** — one calendar month added using the platform's calendar API (`Calendar.add(Calendar.MONTH, 1)` on Android; `Calendar.date(byAdding: .month, value: 1)` on iOS). Edge case: 31 Jan → 28/29 Feb (last day of the month), matching the standard calendar behaviour on both platforms.

**Active status** — `today ≤ endsOnInclusive` (day granularity, time ignored).

---

## Visual Identity Verification (Anti-Fraud Pass Protection)

A common challenge for gym reception check-in systems is **pass sharing** — a member taking a screenshot of their QR code and forwarding it to friends or family members.

To solve this without complex biometric backends:
1. **Photo capture during registration**: Reception staff take a photo of the new member directly via the device camera (`MemberPhotoCaptureView`).
2. **Review & Confirm**: After capturing, staff can inspect the picture with **Retake Photo** (reopens camera) or **Continue** (saves photo, creates member pass, and opens the QR card screen).
3. **Optimized local storage**: Photos are normalized to portrait orientation and stored as compressed JPEGs (`photos/<member-id>.jpg`) in app storage, keeping the JSON database lightweight.
4. **Visual check-in matching**: When a QR code is scanned or member ID is entered, the app displays the **member's stored identity photo** alongside their name, membership status (`ACTIVE` / `EXPIRED`), and expiration date.
5. **Staff verification**: Staff can verify pass ownership with a 1-second visual comparison between the person standing at reception and the photo on screen.

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
    │       ├─ Enter name
    │       ├─ Take Member Photo ──► Camera opens (AVFoundation)
    │       │                           │
    │       │                           ▼
    │       │                       Snap photo
    │       │                           │
    │       │                           ├─► Retake Photo ──► Back to live camera
    │       │                           └─► Continue / Done
    │       │                                   │
    │       ▼                                   ▼
    │   Registration success ◄──────────────────┘
    │       • Unique ID generated (UUID)
    │       • endsOnInclusive = today + 1 month
    │       • Photo saved to local photos directory (<id>.jpg)
    │       • Member record saved to local storage
    │       • QR rendered from member ID + Photo preview
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
                    ├─ Found ──► Show ACTIVE / EXPIRED badge
                    │            Show stored Member Identity Photo
                    │            Show client name, valid until date, ID
                    │               ├─► Check Another Member → back to scanner
                    │               └─► To Main Screen → Home screen
                    └─ Not found ──► "NOT FOUND" with searched ID
```

### Edge cases and expected behaviour

| Situation | Expected behaviour |
|-----------|-------------------|
| Name field empty or whitespace-only | Validation error; registration blocked |
| Tap "Take Member Photo" with empty name | Inline prompt asking for client name first |
| Photo captured, user taps "Retake Photo" | Photo discarded, live camera restarts immediately |
| Photo captured, user taps "Continue" | Photo confirmed, member registered, QR screen presented |
| Client refuses photo / camera broken | "Register without Photo" allows registration with placeholder |
| Camera permission denied for photo capture | Clear message guiding to iOS Settings; fallback photo library option |
| Running in iOS Simulator | Friendly fallback UI with sample avatar generator and photo picker |
| QR image has no QR code | "No QR code found" message |
| QR image unreadable (corrupt file) | "Could not read image" message |
| Camera permission denied for QR scanning | Scanner replaced by "Camera Unavailable" message; photo and manual input still work |
| ID not in local storage | "NOT FOUND" result screen |
| Member has no photo on file | Displays clean placeholder avatar with "No photo on record" |
| Membership expiry = today | Status is **Active** (inclusive) |
| Membership expiry = yesterday | Status is **Expired** |
| Registration on 31 Jan | endsOnInclusive = 28 Feb (non-leap) or 29 Feb (leap year) |

---

## Platform comparison

| Concern | Android | iOS |
|---------|---------|-----|
| Navigation | `NavHost` with typed routes | `NavigationStack` with `AppRoute` enum |
| State management | `ViewModel` + `StateFlow` | `@StateObject` / `@ObservedObject` |
| Local storage | Room (DAO + Entity) | JSON encoded to `members.json` + `photos/<id>.jpg` |
| Member photo capture | Manual or camera input | `AVCapturePhotoOutput` with Retake/Continue flow |
| Photo verification | Name & date display | Photo avatar + status color border & badge |
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
│   │   ├── Models/Member.swift     # Data model + status logic + photoFileName
│   │   ├── Storage/GymRepository.swift  # JSON persistence + photo storage
│   │   ├── Utilities/              # QRCodeHelper, ShareSheet
│   │   └── Views/                  # SwiftUI screens (Home, Register, Check, PhotoCapture)
│   └── GymCheckInTests/            # Unit tests
├── docs/
│   ├── architecture.md             # This file
│   └── adr/                        # Architecture Decision Records
├── gradle/wrapper/
├── .gitignore
└── README.md
```
