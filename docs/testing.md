# Testing & Verification

Read this guide before writing tests, fixing bugs, or running local verification before a commit or PR.

Verification must stay **proportional to the scope of changes** and aligned with active **iOS-primary** development.

---

## 1. Testing priorities

Focus testing investment where defects hurt most:

1. **Core business logic (`:shared` `commonTest`)**:
   - Membership expiration boundaries (`today < endsOnInclusive`, `today == endsOnInclusive` → `ACTIVE`, `today > endsOnInclusive` → `EXPIRED`).
   - `MembershipPlan` durations (`1`, `3`, `6`, `12` months), end-of-month clamping (`31 Jan → 28/29 Feb`, `31 Jan + 3m → 30 Apr`), leap years (`29 Feb + 12m → 28 Feb`), and year rollovers.
   - `MemberValidation` trimming and empty/blank rejection.
   - `MemberIdGenerator` format (`XXX-XXX`), allowed Crockford Base32 alphabet, deterministic generation with injected `Random`, normalization (`O`→`0`, `I`/`L`→`1`, lowercase, spaces/hyphens), and invalid input rejection.
2. **iOS persistence, offline behavior & integration (`ios/GymCheckInTests/`)**:
   - `SharedDomain` Swift interop (`Member`, `MembershipPlan`, `MemberValidation`, `MemberIdGeneratorKt`).
   - Local persistence (load/save, member lookup, photo persistence/cleanup, corrupt-file resilience, offline operation).
   - CoreImage/Vision QR encode/decode round-trips and error states.
3. **Concurrency & planned cloud synchronization tests**:
   - Task cancellation (e.g. superseded lookups or view dismissal), concurrent reads/writes without data races, and main-thread safety.
   - When cloud sync is implemented: durable outbox queuing offline, idempotent retry after reconnect, conflict resolution, deletion tombstone propagation, and eventual consistency.
4. **Android tests (`:app`, dormant / conditional)**:
   - Maintain existing Android unit tests only when `:shared` contracts or `:app` code change. Do not require new Android UI/feature tests for iOS-only work.

### Deterministic vs production ID generation in tests
- Always pass a seeded/fake `Random` (or explicit fixed IDs like `"K7X-9M2"`) in unit tests so tests are 100% deterministic.
- Production ID generation is kept separate (moving to CSPRNG as documented in [Security, Privacy & Data Recovery](security-and-data.md#4-id-generation--data-integrity)) and verified for format, alphabet, and uniqueness properties rather than fixed outputs.

### Regression rule for bugs
- Reproduce bugs with a failing test first where practical, confirm it fails for the expected reason, then implement the minimal fix and verify the test passes.
- Never weaken assertions or lower coverage thresholds without explicit user approval.

---

## 2. Scope-proportional verification commands

Run only the checks relevant to the files you changed:

### iOS-only changes (`ios/`) — Primary workflow
Android builds and Android tests are **not** required for iOS-only changes.

```bash
# 1. SwiftLint (if installed locally)
(cd ios && swiftlint lint --strict)

# 2. Run XCTest on an available simulator (or build-for-testing if no runtime is installed)
SIMULATOR_ID=$(xcrun simctl list devices available iPhone | grep -m1 -oE '[A-F0-9-]{36}' || true)
if [ -n "$SIMULATOR_ID" ]; then
  xcodebuild test \
    -project ios/GymCheckIn.xcodeproj \
    -scheme GymCheckIn \
    -destination "id=$SIMULATOR_ID" \
    CODE_SIGNING_ALLOWED=NO
else
  xcodebuild build-for-testing \
    -project ios/GymCheckIn.xcodeproj \
    -scheme GymCheckIn \
    -destination "generic/platform=iOS Simulator" \
    CODE_SIGNING_ALLOWED=NO
fi
```

### Shared KMP domain changes (`:shared`)
```bash
# 1. Shared unit tests, formatting, static analysis, and Kover coverage (>= 70%)
./gradlew \
  :shared:testDebugUnitTest \
  :shared:ktlintCheck \
  :shared:detekt \
  :shared:koverVerify \
  :shared:koverXmlReportDebug \
  --stacktrace

# 2. Rebuild SharedDomain XCFramework for iOS and run iOS build/tests above
./gradlew :shared:assembleSharedDomainReleaseXCFramework --stacktrace

# 3. If a shared contract used by existing Android code changed, verify existing Android still compiles and passes its tests
./gradlew :app:testDebugUnitTest :app:ktlintCheck :app:detekt --stacktrace
```

### Android changes (`:app`, only when explicitly requested)
```bash
./gradlew :app:testDebugUnitTest :app:lintDebug :app:ktlintCheck :app:detekt --stacktrace
```

### Documentation-only changes (`AGENTS.md`, `README.md`, `docs/`)
```bash
git diff --check
```
Plus verify all relative Markdown links resolve cleanly.

> **macOS `xcode-select` note**: If `xcode-select -p` points to `/Library/Developer/CommandLineTools` instead of Xcode, prefix Gradle XCFramework and `xcodebuild` commands with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`.

---

## 3. CI alignment (Current vs Planned)

- **Current**: `.github/workflows/ci.yml` defines two jobs: `iOS Build, Tests & SwiftLint` (`macos-latest`) and `Android & KMP Shared` (`ubuntu-latest`).
- **Planned / Recommended CI alignment**:
  - Treat **`iOS Build, Tests & SwiftLint`** as the primary required check for iOS PRs.
  - Scope or path-filter Android-specific checks (`:app:*`) so dormant Android tasks do not block iOS-only changes, while keeping `:shared` checks active whenever `shared/` changes.

---

## 4. Performance profiling & verification

- For performance-sensitive changes (startup time, scrolling, camera preview/capture, photo resizing, QR decoding, sync batches), verify using **Xcode Instruments** (**Time Profiler**, **Swift Concurrency**, **Allocations**, **Leaks**) and Xcode's **Main Thread Checker**.

---

## 5. Reporting verification results

- Report **only what was actually executed and its factual outcome** (exact commands and results).
- If a check was not executed locally (for example, no iOS simulator runtime installed, `swiftlint` not installed, or builds skipped for docs-only edits), state that clearly and explain why — **never** include speculative statements about what CI or other tools will do later.

---

## References

- [Apple: XCTest](https://developer.apple.com/documentation/xctest)
- [Apple: Diagnosing Memory, Thread, and Crash Issues Early (Main Thread Checker & TSan)](https://developer.apple.com/documentation/xcode/diagnosing-memory-thread-and-crash-issues-early)
- [Kotlinx Kover Gradle Plugin](https://kotlin.github.io/kotlinx-kover/gradle-plugin/)
- [Android Developers: Testing Apps on Android](https://developer.android.com/training/testing)
