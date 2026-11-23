# Architecture

Read this guide before designing features, refactoring modules, evolving persistence, or planning cloud synchronization.

Every architectural choice below is explicitly marked as **Current**, **Planned**, or **Optional / Only If Needed** so the documentation matches the real scope of the project without premature commitments (see [ADR-006](adr/006-target-architecture-standards.md)).

---

## 1. Platform strategy & scope

Gym Membership Check-In is a small, production-oriented mobile app and portfolio project with a focused set of reception screens, operated initially by a single administrator.

- **iOS is the primary and only currently prioritized platform.** All active product development focuses on delivering a complete, reliable, high-craft iOS application first.
- **Android (`:app`) is optional / dormant.** Existing Android code is preserved without imposing feature parity, simultaneous UI development, or Android CI gates on iOS changes. If Android resumes, it happens only after iOS is complete.
- **Pragmatic Kotlin Multiplatform (`:shared`).** `:shared` is kept where it already provides concrete value (shared pure domain models, validation, date math, short ID generation/normalization). It is **not** expanded solely to anticipate hypothetical future Android development.

---

## 2. Layered architecture overview

```text
┌────────────────────────────────────────────────────────────────┐
│                  Presentation Layer (iOS Primary)              │
│  iOS:     SwiftUI Views + lightweight @MainActor ViewModels    │
│           (Current: Views → Repository; Planned: MVVM / UDF)   │
│  Android: Preserved Jetpack Compose + GymViewModel (optional)  │
└───────────────┬────────────────────────────────┬───────────────┘
                │ SharedDomain.xcframework       │ project(":shared")
┌───────────────▼────────────────────────────────▼───────────────┐
│                Shared Domain Layer (:shared)                   │
│  Current: Member, MembershipPlan (1/3/6/12m), MembershipStatus │
│           MemberValidation, MemberIdGenerator, DateUtils       │
│           GymRepository contract (zero UI or OS dependencies)  │
└───────────────┬────────────────────────────────┬───────────────┘
                │                                │
┌───────────────▼──────────────────┐  ┌──────────▼───────────────┐
│   iOS Data & Platform Adapters   │  │  Android Data (Dormant)  │
│  Current: Local JSON + photos    │  │  Preserved Room (SQLite) │
│           AVFoundation, Vision,  │  │  + CameraX / ZXing       │
│           CoreImage, PhotosUI    │  └──────────────────────────┘
│  Planned: Actor-isolated local   │
│           store + offline-first  │
│           cloud sync engine      │
│           (Firestore / Supabase) │
└──────────────────────────────────┘
```

### Core separation of concerns
- **Presentation**: Renders state and forwards user actions. Heavy I/O, image processing, camera lifecycle, and sync never run in SwiftUI `body` or on the main thread (see [Concurrency, Threading & UI Performance](concurrency-and-performance.md)).
- **Domain (`:shared` `commonMain`)**: Pure business models and rules with zero UI, database, or OS dependencies.
- **Data & Platform Adapters**: Local persistence, photo file storage, QR imaging, camera capture, and (planned) cloud sync.

---

## 3. Architectural decisions: Current vs Planned vs Optional

| Area | Current (on `main`) | Planned (for iOS product roadmap) | Optional / Only If Needed (explicit triggers) |
| --- | --- | --- | --- |
| **Platform focus** | iOS active; Android compiles & passes unit tests | Complete iOS app (UI polish, async persistence, cloud sync) | Resume Android only after iOS is complete |
| **KMP `:shared`** | Pure domain models, plans, validation, IDs, date math | Retain existing domain logic in `:shared`; add CSPRNG production ID source | Expand `:shared` to persistence or presentation **only if** Android resumes and duplication cost clearly exceeds KMP/Swift interop overhead |
| **iOS Presentation** | SwiftUI Views calling `GymRepository` directly | Lightweight **MVVM**: `@MainActor` ViewModel per screen + UDF, keeping Views thin and testable | Coordinator/Router module only if navigation grows beyond a handful of screens |
| **iOS Persistence** | `GymRepository.swift` (`members.json` + JPEG `photos/`) | Actor-isolated async local storage (SQLite / SwiftData / GRDB or indexed store) supporting offline-first sync metadata | **Room KMP** only if Android resumes active development and shared SQLite schema/queries justify the KMP Room/Swift interop cost |
| **Cloud Sync** | Local-only (offline, single device) | Offline-first sync with **Firestore or Supabase** (provider TBD, free tier), single admin | Multi-admin roles, RBAC, or multi-tenant isolation only if product scope explicitly changes |
| **iOS DI & Navigation** | Initializer injection + `NavigationStack` (`AppRoute`) | Keep lightweight initializer/factory injection + `NavigationStack` | Third-party DI container only if object graph becomes genuinely complex |
| **Android DI & Navigation** | Manual `AppContainer` + `AppScreen` enum | Preserve as-is (no migration required) | **Koin** / **Navigation Compose (`NavHost`)** only if Android resumes active multi-screen/multi-module development |

### Guiding rule on framework migrations
Prefer simple, maintainable native code over speculative framework migrations. Do not introduce Koin, Room KMP, or Navigation Compose unless their documented trigger condition is actually met.

---

## 4. KMP boundary & code placement

When deciding where code belongs:

| Code category | Owner | Notes |
| --- | --- | --- |
| Existing shared domain rules (`Member`, `MembershipPlan`, `MembershipStatus`, `MemberValidation`, `MemberIdGenerator`, `DateUtils`) | `:shared` (`commonMain`) | Single source of truth; always covered in `commonTest`. Annotate expected exceptions with `@Throws(...)` for Swift interop. |
| Small OS primitive needed by `:shared` (e.g. CSPRNG) | `:shared` (`iosMain` / `androidMain`) | Narrow `expect`/`actual` or injected interface. |
| iOS UI, `@MainActor` ViewModels, local persistence/sync engine, AVFoundation, Vision, CoreImage, PhotosUI, ShareSheet | `ios/GymCheckIn/` | Keep 100% idiomatic Swift / SwiftUI. |
| Preserved Android UI, Room DB, CameraX, ZXing | `:app` | Do not modify unless `:shared` contract changes require compilation alignment or Android work is explicitly requested. |

- Use `implementation` by default in Gradle; use `api` (and `export(...)` in XCFramework) only for types exposed in `:shared`'s public signatures (`kotlinx-datetime`).
- Always rebuild `SharedDomain.xcframework` after any `:shared` change (`./gradlew :shared:assembleSharedDomainReleaseXCFramework`).

---

## 5. Offline-first & planned cloud synchronization

**Status: Planned** (backend provider **not selected yet** — evaluating **Firestore** vs **Supabase** within free-tier limits; single administrator initially).

The app must always remain usable with zero or intermittent connectivity:

1. **Local store is the primary UI read source**:
   - All check-in lookups, registration confirmations, and photo displays read from local storage immediately (sub-second reception UX).
   - Writes (member registration, edits, deletions) commit locally first and return immediately to the UI without waiting for the network.
2. **Provider-agnostic sync contract**:
   - Isolate remote sync behind a narrow protocol/adapter so Firestore or Supabase can be plugged in without rewriting UI or domain logic.
3. **Core synchronization invariants (to implement when sync begins)**:
   - **Stable IDs**: Every synced record has an immutable, stable identifier (`id`) generated locally at creation time.
   - **Durable pending-changes queue (outbox)**: Local mutations record pending sync state durably on disk so unsynced changes survive app termination and offline periods.
   - **Reliable retries with backoff**: Resume syncing automatically on connectivity restoration with exponential backoff; distinguish transient network failures from permanent errors.
   - **Idempotency**: Remote writes are idempotent (keyed by stable ID + mutation/revision token) so retried requests never create duplicate members.
   - **Conflict resolution**: Define an explicit, deterministic conflict policy (e.g. revision/timestamp Last-Write-Wins for single-admin multi-device/reinstall scenarios, while preserving active membership terms and never silently dropping local unacknowledged edits).
   - **Deletion propagation**: Represent deletions with soft-delete tombstones (`deletedAt`) during sync rather than immediate hard deletes so deletions propagate reliably across reconnects.
   - **Eventual consistency & decoupled photo sync**: Synchronize lightweight member metadata independently from binary identity photos (upload/download photos in bounded background tasks with retry; member check-in works immediately even before a remote photo finishes downloading).
   - **Non-blocking execution**: All sync work runs off the main actor/UI thread and coalesces state updates (see [Concurrency, Threading & UI Performance](concurrency-and-performance.md)).

---

## 6. Domain model & business rules

```text
Member
  id              String    — 6-char Crockford Base32 key (XXX-XXX, e.g. "K7X-9M2"), primary key, encoded in QR
  name            String    — trimmed display name
  startsOn        LocalDate — calendar date of registration (kotlinx-datetime)
  endsOnInclusive LocalDate — startsOn + selected MembershipPlan months (1, 3, 6, or 12)
  photoFileName   String?   — local photo filename (<id>.jpg) for visual identity verification

MembershipPlan (enum)
  ONE_MONTH(1) | THREE_MONTHS(3) | SIX_MONTHS(6) | TWELVE_MONTHS(12)

MembershipStatus (enum)
  ACTIVE | EXPIRED
```

### Clarified business rules (current behavior preserved)
- **Membership expiration semantics (Current)**:
  - `endsOnInclusive` is calculated by adding `plan.months` calendar months to `startsOn` via `kotlinx-datetime` (`DateTimeUnit.MONTH`), clamping end-of-month dates to the last valid day of the target month (e.g. `31 Jan + 1 month → 28 Feb` non-leap / `29 Feb` leap year; `29 Feb 2024 + 12 months → 28 Feb 2025`).
  - Status is **inclusive at day granularity** in the device's local time zone: `today <= endsOnInclusive` → `ACTIVE`; `today > endsOnInclusive` → `EXPIRED`.
  - Existing behavior is intentionally preserved; future changes (such as renewal/extension stacking, explicit gym time-zone anchoring, or grace periods) must be specified explicitly before changing domain code.
- **Member IDs (Current → Planned hardening)**:
  - 6-character Crockford Base32 key formatted `XXX-XXX` (`0123456789ABCDEFGHJKMNPQRSTVWXYZ`, excluding `I`, `L`, `O`, `U`, `32^6 > 1B` combinations; see [ADR-005](adr/005-short-member-id-format.md)).
  - `normalizeMemberId` trims whitespace, uppercases, strips spaces/hyphens, and maps `O`→`0`, `I`/`L`→`1`.
  - **Current**: `MemberIdGenerator.generate(random)` defaults to `Random.Default` and accepts an injectable `Random` for deterministic tests.
  - **Planned**: Keep injectable deterministic random for tests, while switching the production default to platform CSPRNG (`SecRandomCopyBytes` / `SecureRandom`) plus collision-check retry before persistence.
- **Name validation (Current)**:
  - `MemberValidation.validateName(name)` trims whitespace and throws `IllegalArgumentException` (`@Throws`) on empty/blank input.

---

## 7. Visual identity verification & user flows

### Anti-fraud photo verification (iOS)
1. **Capture during registration**: Staff capture a photo via `MemberPhotoCaptureView` (camera on device; photo library / sample avatar fallback on simulator).
2. **Review & confirm**: **Retake Photo** discards and restarts capture; **Continue** saves the normalized, resized JPEG (`maxDimension <= 800px`, `photos/<id>.jpg`) and advances to the QR pass screen.
3. **Check-in comparison**: `CheckMembershipView` displays the stored member photo alongside name, `ACTIVE`/`EXPIRED` badge, expiration date, and `"Verify person matches photo on record"`.

### QR format
See [ADR-002](adr/002-qr-payload-format.md) and [ADR-005](adr/005-short-member-id-format.md). The QR encodes **only** the short member ID (e.g. `K7X-9M2`).

### Reception user flow
```text
App launch
    │
    ▼
Home screen
    ├─► Register member
    │       ├─ Enter client name
    │       ├─ Select Membership Plan (1, 3, 6, or 12 months) + live expiration date preview
    │       ├─ Tap "Take Photo & Register" ──► Camera ──► Retake Photo / Continue
    │       ▼ (or "Register without Photo")
    │   Registration success
    │       • Short ID generated via SharedDomain (XXX-XXX)
    │       • endsOnInclusive = today + plan months (SharedDomain)
    │       • Photo saved locally (<id>.jpg) & member stored locally
    │       • QR rendered from member ID
    │       ├─► Share QR (system share sheet)
    │       └─► Done → Home screen
    │
    └─► Check membership
            ├─► Scan QR (rear camera)
            ├─► Scan QR from saved image (photo library)
            └─► Enter member ID manually (case / hyphen / Crockford tolerant)
                    │
                    ▼
                Look up normalized ID in local storage
                    ├─ Found ──► Status via SharedDomain Member.status(today)
                    │            ACTIVE / EXPIRED badge + Photo + Name + Expiry + ID
                    └─ Not found ──► "NOT FOUND" with searched ID
```

### Edge cases & expected behavior

| Situation | Expected behavior |
| --- | --- |
| Name empty or whitespace-only | Validation error; registration blocked |
| Photo captured → "Retake Photo" / "Continue" | Discards and reopens camera / saves and shows QR screen |
| Client declines photo / camera denied / Simulator | "Register without Photo", Settings guidance, or photo library / sample fallback |
| QR image has no QR or is unreadable | `"No QR code found"` / `"Could not read image"` |
| Manual ID typed lowercase, without hyphen, or with `O`/`I`/`L` | Normalized to `XXX-XXX` (`O`→`0`, `I`/`L`→`1`) before lookup |
| Member has no photo on file | Placeholder avatar with `"No photo on record"` |
| `today == endsOnInclusive` / `today > endsOnInclusive` | **Active** (inclusive) / **Expired** |
| Registration on 31 Jan (1 month) | 28 Feb (non-leap) or 29 Feb (leap year) |

---

## 8. Project layout

```text
gym-check-in/
├── AGENTS.md                         # Agent entry point & documentation index
├── .editorconfig                     # Shared formatting rules (Kotlin/YAML)
├── .github/workflows/ci.yml          # GitHub Actions CI
├── config/detekt/detekt.yml          # Kotlin static analysis config
├── ios/                              # Primary platform (iOS Swift / SwiftUI)
│   ├── .swiftlint.yml                # SwiftLint config
│   ├── GymCheckIn.xcodeproj/         # Xcode project linking SharedDomain.xcframework
│   ├── GymCheckIn/                   # Models, Storage, Utilities, Views (+ planned ViewModels/Sync)
│   └── GymCheckInTests/              # iOS unit & SharedDomain integration tests
├── shared/                           # KMP shared domain module
│   ├── build.gradle.kts              # Targets, XCFramework, Kover verification
│   └── src/
│       ├── commonMain/kotlin/...     # Member, MembershipPlan, Validation, IdGenerator, GymRepository
│       ├── commonTest/kotlin/...     # Shared domain unit tests
│       ├── androidMain/kotlin/...    # Android actuals
│       └── iosMain/kotlin/...        # iOS actuals
├── app/                              # Preserved / optional Android app module
│   ├── schemas/                      # Exported Room schemas
│   └── src/
│       ├── main/java/...             # Room DB, ZXing QR, Compose screens, GymViewModel
│       └── test/java/...             # Android unit tests
└── docs/
    ├── architecture.md               # This file
    ├── concurrency-and-performance.md# Mandatory concurrency, threading & UI performance rules
    ├── development-workflow.md       # Branching, commits, verification, PR description format
    ├── testing.md                    # Testing priorities, commands, CI alignment
    ├── security-and-data.md          # Privacy, sync vs backup, recovery, IDs, migrations
    ├── code-review.md                # Review priorities & concurrency/iOS/KMP checklists
    └── adr/                          # Architecture Decision Records (001–006)
```

---

## References

- [Apple: SwiftUI Documentation & Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [Swift Documentation: Concurrency](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)
- [JetBrains: Kotlin Multiplatform Project Structure](https://kotlinlang.org/docs/multiplatform/multiplatform-project-recommended-structure.html)
- [JetBrains: Expected and Actual Declarations](https://kotlinlang.org/docs/multiplatform/multiplatform-expect-actual.html)
- [Android Developers: Guide to App Architecture](https://developer.android.com/topic/architecture/recommendations)
