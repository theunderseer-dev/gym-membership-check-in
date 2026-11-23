# Code Review Rules

Read this guide before reviewing a Pull Request, auditing existing code, or doing a self-review before pushing.

---

## 1. Review priority order

Focus review feedback on real, observable risk in descending order of severity:

1. **Correctness & data integrity**: Silent data loss, ID collisions/overwrites, broken persistence upgrades/migrations, incorrect membership expiry math, crashes on malformed input or corrupt images.
2. **Concurrency, threading & main-thread safety (Mandatory)** — see [Concurrency, Threading & UI Performance](concurrency-and-performance.md):
   - Blocking disk I/O, JSON/SQLite access, network requests, image resizing, Vision/QR decoding, or `AVCaptureSession.startRunning()`/`stopRunning()` executed on the main thread.
   - Expensive synchronous work placed inside `@MainActor` methods or SwiftUI `body`.
   - Missing task cancellation on view disappear or superseded operations; unnecessary `Task.detached` or fire-and-forget unstructured tasks.
   - Actor reentrancy bugs, data races, deadlocks, priority inversions, or swallowed `CancellationException` in Kotlin coroutines.
3. **UI responsiveness & memory**:
   - Unresponsive tap targets (e.g. `.padding()` dead zones on plain `TextField`), conflicting `NavigationStack` destination modifiers, keyboard clipping.
   - Repeated disk image decodes inside SwiftUI `body` without caching, full-resolution 12MP+ bitmap/UIImage allocations without downsampling, redundant `@Published` / state emissions, missing debounce/backpressure on high-frequency events.
4. **Security, privacy & recovery**: Leaked secrets/credentials, PII in logs/fixtures, unprotected member files/photos on disk, insecure remote payload handling, backup/recovery regressions.
5. **Scope & pragmatic architecture**:
   - Unnecessary abstractions, premature framework migrations, or speculative Android parity work that slows down iOS delivery.
   - Duplicating business rules that already live in `:shared`, broken Swift interop (`@Throws` missing on throwing Kotlin APIs), or stale `SharedDomain.xcframework` after `:shared` edits.
6. **Tests, style & documentation**: Missing regression tests, missing concurrency/edge-case coverage, linter failures (`SwiftLint`, `ktlint`, `detekt`), or docs contradicting actual behavior.

---

## 2. Platform-specific review checklists

### iOS (`ios/`, primary)
- [ ] No disk I/O (`Data(contentsOf:)`, `UIImage(contentsOfFile:)`, file writes), JSON/SQLite work, QR decoding, or image resizing runs on the main thread or inside SwiftUI `body`.
- [ ] `@MainActor` is used for UI state, while heavy work runs off the main actor (e.g. dedicated `actor` or `nonisolated async` helper).
- [ ] View-scoped async work uses `.task` / `.task(id:)` or cancels superseded `Task` handles cleanly; no unnecessary `Task.detached`.
- [ ] `AVCaptureSession` start/stop/reconfiguration runs on a dedicated serial background queue; `CIContext` is reused; photos are downsampled off-main.
- [ ] `NavigationStack(path:)` is not mixed with conflicting `.navigationDestination(isPresented:)` modifiers inside pushed views.
- [ ] Inputs have full-box hit targets and scroll smoothly with the keyboard open.

### Shared KMP (`:shared`, when modified)
- [ ] Domain logic has zero UI, database, or OS dependencies in `commonMain`.
- [ ] Public throwing functions exposed to Swift are annotated with `@Throws(...)`.
- [ ] `api` / XCFramework `export(...)` is used only for types exposed in public signatures.
- [ ] `commonTest` covers boundaries and edge cases; `:shared:koverVerify` passes; `SharedDomain.xcframework` is rebuilt and verified against iOS.

### Android (`:app`, review only when `:shared` contracts or `:app` changed)
- [ ] Do not request Android feature parity for iOS-only PRs.
- [ ] When `:app` is modified: verify compilation, existing tests, no main-thread `ImageAnalysis.Analyzer` or bitmap decoding, and `CancellationException` propagation.

---

## 3. How to write review feedback

- Cite the **exact file, line, and triggering scenario** for every defect.
- For unconfirmed concurrency or performance risks, explain how to reproduce or profile them (e.g. Xcode Instruments / Main Thread Checker).
- Propose concrete, minimal fixes proportional to the app's size — avoid nitpicking style already enforced by linters.
