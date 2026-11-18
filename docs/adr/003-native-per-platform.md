# ADR-003 — Separate native apps per platform

**Date:** 2026-11  
**Status:** Accepted

---

## Context

The prototype targets both Android and iOS. Options considered for the technology stack:

| Option | Approach |
|--------|----------|
| A | Cross-platform (React Native, Flutter, or Kotlin Multiplatform) |
| B | Separate native app per platform (Kotlin + Jetpack Compose / Swift + SwiftUI) |

## Decision

**Option B — separate native implementations.**

- Android: Kotlin, Jetpack Compose, Room, CameraX, ZXing
- iOS: Swift, SwiftUI, AVFoundation, Vision, CoreImage

Both apps implement the same product requirements independently. The shared contract is the QR payload format (see [ADR-002](002-qr-payload-format.md)) and the membership expiry rule.

## Consequences

**Benefits**
- Each app uses idiomatic platform APIs. Camera scanning (`CameraX` vs `AVFoundation`) and QR generation (`ZXing` vs `CIFilter`) are handled with libraries that are well-tested on their respective platforms.
- No shared runtime or bridge; each app can be built, tested, and distributed entirely independently.
- The prototype demonstrates the full native development workflow on both platforms — useful as a reference for teams evaluating Android-first vs iOS-first vs cross-platform.
- UI code reflects platform conventions: Material 3 on Android, SF Symbols and native sheet on iOS.

**Trade-offs**
- Business logic (expiry calculation, status check) is duplicated in Kotlin and Swift. Any rule change must be applied in both codebases.
- Two separate build systems (Gradle and Xcode) to maintain.

**Mitigation path for production**
Extract shared business logic into a Kotlin Multiplatform (KMP) module consumed by both apps. The UI layers remain fully native, while `Member`, `MembershipStatus`, and the expiry calculation live in a single shared module.
