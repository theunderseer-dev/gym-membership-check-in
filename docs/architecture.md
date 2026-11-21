# Architecture

## Overview

Gym Membership Check-In is a **single-device, offline** prototype with a **Kotlin Multiplatform (KMP) shared domain layer**. All membership data lives on the device that runs the app. There is no backend, no sync, and no account system — by design (see [ADR-001](adr/001-local-only-storage.md) and [ADR-004](adr/004-kotlin-multiplatform-shared-domain.md)).

```
┌──────────────────────────────────────────────────────────┐
│              Presentation (Native UI)                    │
│   iOS:     SwiftUI (HomeView, RegisterMemberView,        │
│            RegistrationSuccessView, CheckMembershipView, │
│            MemberPhotoCaptureView)                       │
│   Android: Jetpack Compose (HomeScreen,                  │
│            RegisterMemberScreen, SuccessScreen,          │
│            CheckMembershipScreen)                        │
└─────────────┬──────────────────────────────┬─────────────┘
              │ links SharedDomain.xcframework│ gradle project(":shared")
┌─────────────▼──────────────────────────────▼─────────────┐
│          Shared Domain Layer (Kotlin Multiplatform)      │
│   :shared (commonMain)                                   │
│   • Member (domain model & status logic)                 │
│   • MembershipStatus (ACTIVE, EXPIRED)                   │
│   • MemberValidation (client name rules)                 │
│   • GymRepository (shared repository interface)          │
│   • Date & UUID arithmetic (kotlinx-datetime)            │
│   Single source of truth (ADR-004)                       │
└─────────────┬──────────────────────────────┬─────────────┘
              │ implemented by               │ implemented by
┌─────────────▼────────────┐   ┌─────────────▼─────────────┐
│       Android Storage    │   │         iOS Storage       │
│   Room (SQLite DAO)      │   │   JSON via FileManager    │
│   DefaultGymRepository   │   │   + local photos dir      │
└──────────────────────────┘   └───────────────────────────┘
```

---

## Data model

```
Member
  id              String   — UUID, primary key, encoded in QR
  name            String   — client's display name
  startsOn        LocalDate— calendar date of registration (kotlinx-datetime)
  endsOnInclusive LocalDate— startsOn + 1 calendar month
  photoFileName   String?  — local photo filename (<id>.jpg) for identity verification
```

**Shared Domain Single Source of Truth**:
- **Expiry calculation**: `currentDatePlusMonths(startsOn, 1)` implemented once in `commonMain` using `kotlinx-datetime`. Edge case: 31 Jan → 28/29 Feb (last day of the month), uniformly calculated on all platforms.
- **Active status rule**: `today <= endsOnInclusive` (day granularity, inclusive boundary).
- **Validation**: `MemberValidation.validateName(name)` enforces non-empty names and trims whitespace.

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
    │       ├─ Tap "Take Photo & Register" ──► Camera opens (AVFoundation)
    │       │                                      │
    │       │                                      ▼
    │       │                                  Snap photo
    │       │                                      │
    │       │                                      ├─► Retake Photo ──► Back to live camera
    │       │                                      └─► Continue / Done
    │       │                                              │
    │       ▼ (or "Register without Photo")                ▼
    │   Registration success ◄─────────────────────────────┘
    │       • Unique ID generated via SharedDomain UUID
    │       • endsOnInclusive = today + 1 month (SharedDomain)
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
                    ├─ Found ──► Status evaluated via SharedDomain Member.status(today)
                    │            Show ACTIVE / EXPIRED badge
                    │            Show stored Member Identity Photo
                    │            Show client name, valid until date, ID
                    │               ├─► Check Another Member → back to scanner
                    │               └─► To Main Screen → Home screen
                    └─ Not found ──► "NOT FOUND" with searched ID
```

### Edge cases and expected behaviour

| Situation | Expected behaviour |
|-----------|-------------------|
| Name field empty or whitespace-only | Shared `MemberValidation` throws; registration blocked |
| Tap "Take Photo & Register" with empty name | Validation error: "Client name cannot be empty" |
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
| Membership expiry = today | Status is **Active** (inclusive, verified in `commonTest`) |
| Membership expiry = yesterday | Status is **Expired** (verified in `commonTest`) |
| Registration on 31 Jan | endsOnInclusive = 28 Feb (non-leap) or 29 Feb (leap year) via SharedDomain |

---

## Platform comparison

| Concern | Android | iOS |
|---------|---------|-----|
| Domain layer | `:shared` (KMP `commonMain`) | `:shared` (`SharedDomain.xcframework`) |
| Domain tests | `commonTest` (JUnit / kotlin.test) | `commonTest` + `MembershipTests.swift` |
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

---

## Project layout

```
gym-check-in/
├── shared/                         # Kotlin Multiplatform (KMP) shared module
│   ├── build.gradle.kts            # KMP config (Android target + iOS targets -> XCFramework)
│   └── src/
│       ├── commonMain/kotlin/…/    # Member, MembershipStatus, MemberValidation, GymRepository
│       ├── commonTest/kotlin/…/    # Shared domain unit tests
│       ├── androidMain/kotlin/…/   # Android actuals (UUID)
│       └── iosMain/kotlin/…/       # iOS actuals (UUID via NSUUID)
├── app/                            # Android app module (depends on :shared)
│   └── src/main/java/…/
│       ├── data/                   # Room DB, DAO, DefaultGymRepository
│       └── ui/                     # Jetpack Compose screens & GymViewModel
├── ios/
│   ├── GymCheckIn.xcodeproj/       # Xcode project (links SharedDomain.xcframework)
│   ├── GymCheckIn/
│   │   ├── Models/Member.swift     # Member model bridging to SharedDomain
│   │   ├── Storage/GymRepository.swift # JSON persistence + photo storage (uses SharedDomain)
│   │   ├── Utilities/              # QRCodeHelper, ShareSheet
│   │   └── Views/                  # SwiftUI screens (Home, Register, Check, PhotoCapture)
│   └── GymCheckInTests/            # Unit tests (including SharedDomain integration)
├── docs/
│   ├── architecture.md             # This file
│   └── adr/                        # Architecture Decision Records (001-004)
├── gradle/wrapper/
├── .gitignore
└── README.md
```
