# ADR-006 — iOS-Primary Strategy, Pragmatic KMP Scope & Offline-First Sync Roadmap

**Date:** 2026-11
**Status:** Accepted
**Builds on:** [ADR-001](001-local-only-storage.md), [ADR-004](004-kotlin-multiplatform-shared-domain.md), [ADR-005](005-short-member-id-format.md)

---

## Context

Gym Membership Check-In is a small, production-oriented mobile application and portfolio project operated initially by a single administrator with a limited set of reception screens. Following the initial KMP domain extraction ([ADR-004](004-kotlin-multiplatform-shared-domain.md)) and an architectural review of PR #6, earlier speculative cross-platform commitments (mandatory Android parity, Room KMP migration, Koin DI, Navigation Compose) were found to be disproportionate to the project's actual scope and roadmap:

1. **iOS is the primary and only currently prioritized platform.** Android may never be developed further, or would only resume after the complete iOS implementation.
2. Expanding KMP into shared persistence (Room KMP) or shared presentation would introduce build/interop complexity primarily for a hypothetical Android future.
3. The real upcoming engineering challenges on iOS are **UI responsiveness / main-thread safety**, **clean local persistence**, and **reliable offline-first cloud synchronization** (Firestore or Supabase, provider not yet selected, targeting a free tier).

## Decision

Adopt a pragmatic, **iOS-primary** architecture with explicit **Current**, **Planned**, and **Optional / Only If Needed** boundaries:

1. **Platform Priority — iOS Primary, Android Optional**:
   - Prioritize completing the iOS application with idiomatic Swift, SwiftUI, and Apple platform APIs.
   - Preserve existing Android code (`:app`) as-is without requiring feature parity, simultaneous Android updates, or Android CI success for iOS-only changes.
2. **Pragmatic KMP Boundary (`:shared`)**:
   - Retain existing shared pure domain logic (`Member`, `MembershipPlan`, `MembershipStatus`, `MemberValidation`, `MemberIdGenerator`, `DateUtils`, `GymRepository` contract) in `:shared` (`commonMain`) where it already provides concrete value and `commonTest` coverage.
   - Do **not** mandate migrating persistence (Room KMP) or presentation into `:shared`. Re-evaluate only if Android resumes active development and concrete duplication costs outweigh KMP/Swift interop overhead.
3. **iOS Presentation & Persistence — Simple, Idiomatic & Async**:
   - **Presentation (Planned)**: Lightweight MVVM (`@MainActor` ViewModels + UDF) with SwiftUI `NavigationStack` and simple initializer/factory injection (no third-party DI container unless object graph complexity genuinely requires it).
   - **Persistence (Current → Planned)**: Move iOS storage off the main thread into an actor-isolated async local store (JSON or native SQLite/SwiftData/GRDB when sync outbox and indexing needs warrant it).
   - **Android frameworks (Optional / Only If Needed)**: Do not mandate migrating Android to Koin or Navigation Compose (`NavHost`) unless Android resumes active multi-screen/multi-module development.
4. **Offline-First & Planned Cloud Synchronization**:
   - Local persistence remains the primary source of truth for all UI reads (extending [ADR-001](001-local-only-storage.md)'s offline-first guarantee).
   - Plan provider-agnostic cloud synchronization (**Firestore** or **Supabase**, provider TBD, free tier, single admin) accounting for stable IDs, durable pending-change queuing, idempotent retries with backoff, conflict resolution, soft-delete tombstones, and decoupled photo sync — without prematurely building sync infrastructure or multi-tenant RBAC.
   - Distinguish synchronization from backup: do not apply blanket OS backup blocks before cloud sync provides verified device-replacement recovery.
5. **Mandatory Concurrency, Threading & UI Performance**:
   - Enforce strict main-thread safety, Swift Structured Concurrency (`async/await`, `Task`, actors, `@MainActor` strictly for UI state, cooperative cancellation), dedicated serial queues for `AVCaptureSession`, off-main image downsampling, and Xcode Instruments profiling across all implementations (see [docs/concurrency-and-performance.md](../concurrency-and-performance.md)).

## Consequences

**Benefits**
- Keeps engineering focus on shipping a fast, reliable, well-tested iOS product without speculative cross-platform tax.
- Preserves existing KMP domain value and existing Android code cleanly, leaving a low-friction path if Android ever resumes.
- Prevents premature framework migrations (Room KMP, Koin, NavHost) while defining concrete triggers for when they would be justified.
- Establishes clear non-negotiable standards for concurrency, UI responsiveness, and future offline-first cloud synchronization.

**Trade-offs**
- Android (`:app`) will intentionally lag behind new iOS UI features unless Android development is explicitly resumed later.
- Persistence on iOS and Android remains platform-specific unless/until Android resumes and justifies shared storage.
