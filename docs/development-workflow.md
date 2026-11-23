# Development Workflow & Version Control

Read this guide before creating branches, committing changes, pushing to GitHub, or preparing Pull Requests.

---

## 1. Branching strategy

`main` is protected. Never commit or push directly to `main`. Always sync `main` first and branch off it for every new task:

```bash
git fetch origin
git checkout main
git merge --ff-only origin/main
git checkout -b <type>/<short-description>
```

### Branch naming

Format: `<type>/<short-description>` — lowercase words separated by hyphens (`kebab-case`). The change type is the only prefix.

| Prefix | Use for | Example |
| --- | --- | --- |
| `feat/` | New user-facing or domain feature | `feat/membership-tariff-plans` |
| `fix/` | Bug fix or UI/concurrency fix | `fix/ios-ui-and-focus-responsiveness` |
| `refactor/` | Code restructuring without behavior change | `refactor/ios-async-repository` |
| `docs/` | Documentation and agent instructions | `docs/agents-and-engineering-guidelines` |
| `test/` | Adding or improving tests only | `test/sync-retry-and-cancellation` |
| `ci/` | CI/CD workflows, linters, build tooling | `ci/setup-github-actions-ci` |
| `chore/` | Dependency updates, housekeeping | `chore/update-kotlin-deps` |

- Keep unrelated work (for example, UI bug fixes and new features) in **separate branches and separate PRs**.
- Before committing, verify `git branch --show-current` matches the task.
- Push using the same branch name on the remote (`git push -u origin <branch>`).

---

## 2. Commit guidelines

Follow [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/):

```text
<type>(<optional-scope>): <lowercase imperative summary>
```

- **Types**: `feat`, `fix`, `refactor`, `docs`, `test`, `ci`, `chore`, `perf`, `build`.
- **Scopes** (optional, use when focused on one area): `ios`, `shared`, `kmp`, `sync`, `android`, `ci`, `docs`.
- **Single-line concise subject**: Imperative mood, lowercase start, no trailing period, <= 72 characters.
  - Good: `feat(ios): add actor-isolated async member repository`
  - Good: `fix(ios): move AVCaptureSession teardown off main thread`
  - Bad: `Fixed stuff.` / `WIP` / `Updated files`
- **Commit granularity**:
  - Split distinct independent fixes into separate atomic commits when they address separate responsibilities.
  - Keep a single cohesive feature (e.g. shared rule + iOS caller + tests + docs) in one logical commit rather than fragmenting it artificially.

---

## 3. Pre-push verification checklist (scope-proportional)

Run checks matching what actually changed (see [Testing & Verification](testing.md) for exact commands):

1. **iOS-only changes (`ios/`)**:
   - Run `SwiftLint` (`(cd ios && swiftlint lint --strict)`) if installed locally.
   - Run `xcodebuild test` (or `xcodebuild build-for-testing` if no simulator runtime is available locally).
   - Android checks are **not** required for iOS-only changes.
2. **Shared KMP changes (`:shared`)**:
   - Run `./gradlew :shared:testDebugUnitTest :shared:ktlintCheck :shared:detekt :shared:koverVerify`.
   - Rebuild `SharedDomain.xcframework` (`./gradlew :shared:assembleSharedDomainReleaseXCFramework`) and run the iOS verification above.
   - If a shared contract consumed by `:app` changed, verify `:app:testDebugUnitTest :app:ktlintCheck :app:detekt` still pass without expanding Android features.
3. **Android changes (`:app`, only when explicitly requested)**:
   - Run `./gradlew :app:testDebugUnitTest :app:lintDebug :app:ktlintCheck :app:detekt`.
4. **Documentation-only changes**:
   - Verify relative Markdown links and run `git diff --check`.

---

## 4. Pull Request workflow & PR description

1. Push your branch to `origin` only after local verification passes (and when explicitly asked to push).
2. Never merge directly to `main`.
3. **Mandatory chat PR description**: After every successful push of a feature, bug fix, refactor, or documentation update, output a ready-to-paste **PR description** in chat in English formatted in GitHub-flavored Markdown using `##` headings, bullet lists (`- `), **bold** for UI labels, and backticks for identifiers, file paths, and commands:

```markdown
## Summary

<1–2 concise sentences stating what changed and why.>

## Changes

- <Concrete code, config, or doc change using `backticks` for symbols/paths.>
- <Another concrete change.>

## Testing

- <What new or existing tests cover this change and what behavior they verify.>
- <Reference test classes or files in `backticks`.>

## Verification

- <Exact checks/commands executed locally (including tool versions/results).>
- <Explicitly note any checks not executed locally and why. Report only completed facts — do not include future promises.>
```

### Reference example

```markdown
## Summary

Move `GymRepository` file I/O and photo resizing off the main thread using a Swift `actor` to eliminate UI stalls on launch and registration.

## Changes

- Convert `GymRepository` disk persistence and photo downsampling in `ios/GymCheckIn/Storage/GymRepository.swift` to `async` actor-isolated operations.
- Add `@MainActor` `RegisterMemberViewModel` to coordinate form state and task cancellation via SwiftUI `.task`.
- Cache loaded member thumbnails in `NSCache` instead of reading from disk in `CheckMembershipView.body`.

## Testing

- Added concurrent registration and cancellation tests in `ios/GymCheckInTests/MembershipTests.swift`.
- Verified existing photo persistence and `SharedDomain` integration tests pass.

## Verification

- Ran `xcodebuild test -project ios/GymCheckIn.xcodeproj -scheme GymCheckIn` with all unit tests passing.
- Checked main-thread safety with Xcode Main Thread Checker during launch, registration, and check-in.
- `swiftlint` was not run locally because it is not installed in this environment.
```

---

## References

- [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/)
- [GitHub Docs: About pull requests](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/about-pull-requests)
- [GitHub Docs: Managing a branch protection rule](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)
