# ADR-004 — Kotlin Multiplatform (KMP) Shared Domain Module

**Date:** 2026-11  
**Status:** Accepted  
**Supersedes:** ADR-003 trade-off mitigation path

---

## Context

In [ADR-003](003-native-per-platform.md), separate native applications (Jetpack Compose on Android and SwiftUI on iOS) were chosen to maximize idiomatic platform feel and camera/scanner integration. However, the trade-off noted was that core business logic, domain models (`Member`, `MembershipStatus`), validation rules, and date arithmetic (such as 1-month addition, leap year boundaries, and inclusive expiration rules) were duplicated between Kotlin and Swift.

To eliminate duplication while preserving native UI conventions, a single source of truth for the domain layer was required following Android Developers best practices.

## Decision

**Extract domain layer logic into a Kotlin Multiplatform (`:shared`) module.**

### Architecture & Layering

Following the recommended Android & KMP architecture:

1. **Shared Domain Layer (`:shared/src/commonMain`)**:
   - **Domain Models**: `Member` data class with status evaluation, `MembershipStatus` enum (`ACTIVE`, `EXPIRED`).
   - **Validation Rules**: `MemberValidation` for client display name trimming and non-empty requirement.
   - **Repository Contract**: `GymRepository` interface defining `registerMember` and `getMemberById`.
   - **Shared Utilities**: Date arithmetic using `kotlinx-datetime` (`currentDate()`, `currentDatePlusMonths()`) and platform expect/actual for UUID generation (`generateUuid()`).

2. **Integration on Android (`:app`)**:
   - Added `implementation(project(":shared"))`.
   - `DefaultGymRepository` implements the shared `GymRepository` contract.
   - ViewModels and Compose screens consume shared models (`com.theunderseer.gymcheckin.domain.model.Member`).

3. **Integration on iOS (`ios/`)**:
   - `:shared` compiles a static XCFramework (`SharedDomain.xcframework`).
   - Xcode project links `SharedDomain.xcframework`.
   - Native Swift models and repository delegate business calculations, name validation, date math, and status evaluation to `SharedDomain`.
   - SwiftUI views and navigation (`HomeView`, `RegisterMemberView`, `CheckMembershipView`, etc.) remain fully native Swift.

4. **Testing (`:shared/src/commonTest`)**:
   - Comprehensive unit tests (`MemberTest`, `MemberValidationTest`) verify expiration boundaries, leap year calculations, status transitions, and input validation once for all platforms.

## Consequences

**Benefits**
- **Single Source of Truth**: Business rules, membership duration, and status logic are defined once in Kotlin and shared across Android and iOS.
- **Zero UI Compromise**: Jetpack Compose and SwiftUI remain native, retaining platform design conventions (Material 3 and iOS Human Interface Guidelines).
- **Type Safety**: Domain models and repository interfaces are strictly typed and shared.
- **Maintainability**: New business logic or validation rules are written and unit-tested once in `commonTest`.

**Trade-offs & Mitigations**
- Building iOS artifacts requires generating the XCFramework via Gradle (`./gradlew :shared:assembleSharedDomainReleaseXCFramework`), which is automated in the build pipeline.
