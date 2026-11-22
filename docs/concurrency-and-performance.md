# Concurrency, Threading & UI Performance

**Mandatory standard.** Read this guide before writing or modifying any UI, persistence, photo/image, camera, QR, or synchronization code.

These rules apply to all current and future implementations. Keep architecture proportional to the app's size, without compromising correctness, thread safety, or UI responsiveness.

---

## 1. Non-negotiable core principles

- **Keep the main/UI thread strictly for UI work**: Never perform blocking disk I/O, database queries/writes, JSON encoding/decoding, network requests, image resizing/compression, QR decoding, or camera session control on the main thread.
- **Keep UI rendering and interaction handlers lightweight**: View rendering (`body` in SwiftUI, `@Composable` in Compose) and tap/input handlers must be fast, side-effect-free, and free of disk reads or heavy allocations.
- **Never assume `async/await` or coroutines automatically mean non-blocking**:
  - In Swift, an `async` function isolated to `@MainActor` runs its synchronous body **on the main thread** until it suspends at an `await` on a different executor.
  - In Kotlin, a `suspend` function runs on the caller's dispatcher (often `Dispatchers.Main`) unless it explicitly switches context with `withContext(Dispatchers.IO)` or `withContext(Dispatchers.Default)`.
- **Prevent concurrency hazards**: Eliminate data races, deadlocks, priority inversions, and unnecessary context switching.

---

## 2. iOS / Swift Structured Concurrency standards

Follow Apple's Swift Structured Concurrency model ([The Swift Programming Language — Concurrency](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)):

### Actor isolation & `@MainActor`
- Annotate UI-bound ViewModels and UI state updates with `@MainActor`.
- **Never** run expensive synchronous CPU or I/O work inside a `@MainActor` method. Offload file I/O, JSON/SQLite access, image processing, and Vision/CoreImage QR decoding to a dedicated `actor` or `nonisolated` `async` function executing off the main actor.
- Use Swift `actor`s to protect mutable shared persistence or synchronization state (for example, local store access, sync queue/outbox state, and photo storage) instead of ad-hoc locks or unsynchronized mutable arrays.
- Watch for **actor reentrancy**: never assume actor state before an `await` is unchanged after the `await` resumes. Re-validate preconditions after suspension points.

### Structured tasks & cancellation
- Tie UI-triggered asynchronous work to SwiftUI's lifecycle using `.task` or `.task(id:)` so tasks cancel automatically when a view disappears or inputs change.
- For manually stored tasks inside a ViewModel (e.g. search or refresh), store the `Task` handle, cancel superseded tasks before starting a new one, and cancel on teardown.
- Check cancellation cooperatively (`try Task.checkCancellation()` or `guard !Task.isCancelled else { return }`) inside loops, multi-step image pipelines, and sync batches.
- **Avoid unstructured & detached concurrency**:
  - Do not use `Task.detached` unless there is a documented need to opt out of inherited priority, task-local values, and actor context.
  - Do not spawn fire-and-forget background `Task`s without clear ownership and error handling.
  - Bound parallelism (e.g. photo uploads or sync batches) instead of spawning unbounded concurrent tasks.

### Camera, CoreImage & image pipelines (iOS)
- **AVFoundation (`AVCaptureSession`)**: Run `startRunning()`, `stopRunning()`, and session reconfiguration (`beginConfiguration()`/`commitConfiguration()`) on a **single dedicated serial `DispatchQueue`**, never synchronously in `viewWillDisappear` or on the main thread.
- **CoreImage (`CIContext`)**: Reuse a shared `CIContext` instance rather than allocating a new GPU/Metal context per QR code.
- **Photos & thumbnails**:
  - Downsample captured or imported images off the main thread using `CGImageSourceCreateThumbnailAtIndex` or `UIGraphicsImageRenderer` (avoid deprecated `UIGraphicsBeginImageContextWithOptions` on full-resolution 12MP+ photos).
  - Never call `UIImage(contentsOfFile:)` directly inside SwiftUI `body`. Load thumbnails asynchronously and cache them in an `NSCache`.

### UI responsiveness & backpressure (iOS)
- Avoid unnecessary `@Published` / observable property mutations that cause broad SwiftUI view invalidations; pass non-observed dependencies when a view does not render their changing state.
- Ensure custom input containers (such as padded `.plain` `TextField`s) have full-area hit targets and do not conflict with `NavigationStack` destination modifiers.
- Apply simple debouncing/throttling where appropriate (e.g. camera QR frame handling, manual search, or sync triggers) without introducing reactive framework overhead.

---

## 3. Kotlin / KMP concurrency standards (when touching `:shared` or `:app`)

Follow official [Kotlin Coroutines](https://kotlinlang.org/docs/coroutines-guide.html) and [Android Developers Coroutines Best Practices](https://developer.android.com/kotlin/coroutines/coroutines-best-practices):

- **Structured concurrency**: Scope coroutines to a well-defined owner (`viewModelScope`, `coroutineScope`). Never use `GlobalScope`.
- **Main-safety & dispatchers**: Make `suspend` functions main-safe by switching to `Dispatchers.IO` for blocking I/O and `Dispatchers.Default` for CPU-bound work (`withContext(...)`). Inject dispatchers in testable classes rather than hardcoding them when testing concurrency.
- **Cancellation propagation**: Always rethrow `CancellationException` when catching `Exception`/`Throwable` around `suspend` calls (`catch (e: CancellationException) { throw e }`).
- **Camera & bitmap work (Android)**: Run `ImageAnalysis.Analyzer` on a dedicated single-thread background executor (never `ContextCompat.getMainExecutor`), shut down executors on dispose, reuse frame byte buffers to prevent GC churn, and downsample gallery bitmaps (`inSampleSize`) before decoding QR codes.
- **Avoid redundant recompositions**: Keep Compose state immutable, use `remember` with accurate keys, and avoid triggering I/O or allocations inside `@Composable` bodies.

---

## 4. Synchronization & background work impact

When cloud synchronization is implemented (planned):
- Local persistence writes must remain non-blocking to the UI and reflect immediately without waiting for network completion.
- Sync execution must run off the main actor/UI thread with bounded batch sizes and retry backoff so background sync never degrades scanning, photo capture, or scrolling smoothness.
- Reconciled remote updates must coalesce UI state updates rather than emitting per-row churn on the main thread.

---

## 5. Verification, testing & profiling

- **Mandatory code review criterion**: Every PR touching UI, storage, camera, images, or sync must be checked for main-thread safety, cancellation, actor/thread isolation, and allocation hotspots (see [Code Review Rules](code-review.md)).
- **Focused concurrency tests**: Where applicable, add tests covering task cancellation, concurrent mutations, race conditions, and out-of-order sync/search completions.
- **Measure with platform tools**: Do not guess performance regressions. Use **Xcode Instruments** (**Time Profiler**, **Swift Concurrency**, **Allocations**, **Leaks**, and Xcode's **Main Thread Checker**) when investigating lag, memory spikes, or background work on iOS (and Android Profiler / `StrictMode` if touching Android).

---

## References

- [Swift Documentation: Concurrency](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)
- [Apple: Main Thread Checker](https://developer.apple.com/documentation/xcode/diagnosing-memory-thread-and-crash-issues-early)
- [Apple: Improving Your App's Performance (Instruments)](https://developer.apple.com/documentation/xcode/improving-your-app-s-performance)
- [Apple: WWDC — Explore Structured Concurrency & Swift Concurrency Behind the Scenes](https://developer.apple.com/videos/play/wwdc2021/10254/)
- [Android Developers: Best practices for coroutines in Android](https://developer.android.com/kotlin/coroutines/coroutines-best-practices)
- [Kotlin Docs: Coroutines Guide](https://kotlinlang.org/docs/coroutines-guide.html)
