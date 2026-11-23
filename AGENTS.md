# Gym Membership Check-In — Agent Instructions

These instructions apply to AI coding agents and contributors working in the **Gym Membership Check-In** repository.

## Project overview

Gym Membership Check-In is a small, production-oriented **iOS-primary** mobile application (and engineering portfolio project) for gym front-desk reception operated initially by a single administrator. It supports member registration with selectable tariff plans (1, 3, 6, 12 months), short human-readable Crockford Base32 IDs (`XXX-XXX`), scannable QR passes, member identity photos for visual anti-fraud verification, and instant offline check-in.

### Platform strategy & roadmap
- **iOS is the primary and only currently prioritized platform.** Complete the full, polished iOS application first.
- **Android (`:app`) is optional / dormant.** Preserve existing Android code without unnecessary edits, parity obligations, or simultaneous feature delivery. Only touch `:app` if a `:shared` contract change requires minimal compilation alignment or the user explicitly asks for Android work.
- **Kotlin Multiplatform (`:shared`) is pragmatic.** Retain `:shared` where it already delivers concrete value (domain models, validation, date math, short ID generation/normalization). Do **not** expand KMP (e.g. shared persistence or shared ViewModels) solely for hypothetical future Android work.
- **Offline-first with planned cloud sync.** Local persistence is always the primary read source for the UI. Cloud sync (Firestore or Supabase — provider not selected yet, targeting free tier) is planned for later; multi-role RBAC and multi-tenant enterprise architecture are out of scope.

### Current tech stack (verify exact versions in Xcode / Gradle files)
- **iOS (`ios/`, primary)**: Swift, SwiftUI, AVFoundation, Vision, CoreImage, PhotosUI, local JSON + JPEG photo storage, Min iOS 16, `SwiftLint`.
- **Shared domain (`:shared`)**: Kotlin Multiplatform `2.1.20`, `kotlinx-datetime 0.6.1`, packaged for iOS as static `SharedDomain.xcframework`, tested in `commonTest` with `Kover`, `ktlint`, and `detekt`.
- **Android (`:app`, preserved / optional)**: Kotlin, Jetpack Compose (Material 3), Room (SQLite, KSP), CameraX, ZXing, Min SDK 26 / Compile SDK 35, JVM 17.
- **CI**: GitHub Actions (`.github/workflows/ci.yml`).

## How to start working

Follow these steps in order for every task:

1. **Inspect workspace & branch**: Check `git status`, current branch, and latest `main`. Preserve uncommitted user edits. Never work directly on `main` — create a branch following [Development Workflow](docs/development-workflow.md#1-branching-strategy).
2. **Read relevant documentation**: Use the documentation index below before designing or editing code. Locate the entry point, callers, and nearest tests.
3. **Define behavior & edge cases**: Clarify expected behavior, concurrency/threading boundaries, and edge cases. For bugs, reproduce first with a failing test where practical.
4. **Make the smallest complete change**: Keep edits strictly scoped. For iOS-only tasks, work in `ios/` without adding Android work. When changing a shared contract in `:shared`, rebuild `SharedDomain.xcframework`, update iOS callers and `commonTest`, and keep existing Android compiling with minimal adapter updates if needed.
5. **Verify proportionally before committing**: Run the verification commands matching the scope of your change in [Testing & Verification](docs/testing.md).
6. **Commit, push, and provide PR description**: Use Conventional Commits, push when requested, and output a GitHub Markdown **PR description** (`## Summary`, `## Changes`, `## Testing`, `## Verification`) reporting only factual checks actually executed (see [Development Workflow](docs/development-workflow.md#4-pull-request-workflow--pr-description)).

## Core constraints and boundaries

- **Protected `main` branch**: Never push directly to `main`. All changes go through Pull Requests.
- **iOS-primary, no forced Android parity**: Never block iOS progress on Android feature parity, Android UI changes, or unnecessary Android maintenance.
- **Keep architecture proportional**: Prefer simple, maintainable native iOS solutions over premature framework migrations (no mandatory Room KMP, Koin, or Navigation Compose migrations without explicit triggers).
- **Single source of truth for existing shared rules**: Do not duplicate domain rules that already live in `:shared` (expiry math, `MembershipPlan`, `MemberValidation`, `MemberIdGenerator`).
- **Mandatory concurrency & UI responsiveness**: Never run blocking I/O, database/file reads, network sync, image processing, QR decoding, or camera session control on the main/UI thread. Follow [Concurrency, Threading & UI Performance](docs/concurrency-and-performance.md) on every change.
- **Offline-first & privacy-conscious**: UI always reads from local storage; keep member PII and photos protected; never commit secrets, credentials, or PII in logs/fixtures.
- **Documentation & tests stay in sync**: Update `docs/` and ADRs when architecture or behavior changes. Never weaken tests or coverage thresholds without explicit user approval.

## Documentation index (when to read what)

Read the relevant guide **before** starting work in that area:

| When to read | Document | Covers |
| --- | --- | --- |
| Before creating a branch, committing, pushing, or opening a PR | [docs/development-workflow.md](docs/development-workflow.md) | Branch naming, Conventional Commits, scope-proportional pre-push checks, GitHub Markdown PR description format |
| Before designing features, refactoring, or planning sync/persistence | [docs/architecture.md](docs/architecture.md) | iOS-primary strategy, Current vs Planned vs Optional decisions, KMP boundary, offline-first + planned cloud sync architecture, business rules |
| Before writing any async, I/O, camera, image, DB, sync, or UI code | [docs/concurrency-and-performance.md](docs/concurrency-and-performance.md) | Mandatory main-thread safety, Swift Structured Concurrency (`@MainActor`, actors, cancellation), Kotlin coroutines, UI & memory performance, profiling |
| Before writing, updating, or running tests and CI checks | [docs/testing.md](docs/testing.md) | Test priorities, deterministic vs production IDs, scope-proportional verification commands, CI alignment, factual reporting |
| Before touching storage, backups, photos, IDs, sync, or permissions | [docs/security-and-data.md](docs/security-and-data.md) | Sync vs backup distinction, PII & photo protection, device recovery, secure IDs, schema migrations, secret hygiene |
| Before reviewing a PR or auditing existing code | [docs/code-review.md](docs/code-review.md) | Defect priorities, mandatory concurrency/main-thread review criteria, iOS-primary & KMP boundary checks |
| Before changing a foundational product or technical decision | [docs/adr/](docs/adr/) | Architecture Decision Records (`001`–`006`) preserving decision history |
