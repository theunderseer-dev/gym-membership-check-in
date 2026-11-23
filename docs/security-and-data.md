# Security, Privacy & Data Recovery

Read this guide before modifying persistence, backups, photos, member ID generation, cloud sync, or permissions.

Keep security proportional to the project scope: a small reception app operated initially by a **single administrator** with offline-first local storage and **planned** cloud sync (Firestore or Supabase, provider TBD). Speculative multi-tenant isolation, RBAC, and enterprise IAM are out of scope.

---

## 1. Synchronization vs Backup (explicit distinction)

Do not conflate **synchronization** with **backup** — they solve different problems:

| Mechanism | Purpose | What it protects against | Limitations |
| --- | --- | --- | --- |
| **Cloud synchronization** *(Planned)* | Replicates active operational state across sessions, reinstalls, and replacement devices (eventual consistency) | Device loss/replacement when operational cloud state is healthy | Replicates accidental deletions and overwrites too; does not replace point-in-time recovery |
| **OS / device backup** *(Current interim recovery)* | Restores local app data on device replacement or OS restore | Accidental local loss **before** cloud sync exists | Restoring an old backup *after* cloud sync is live can introduce stale local state that sync must reconcile |

### Backup & recovery policy

- **Current (pre-sync)**: Do **not** blindly disable all OS backups while local storage is the only copy of gym members — doing so leaves zero recovery path if the reception iPhone/iPad is lost or wiped. Rely on encrypted OS backups (iCloud / encrypted device backup) for interim disaster recovery while protecting files at rest with iOS Data Protection.
- **Planned (once cloud sync is live)**:
  - Treat cloud sync as the primary mechanism for device replacement and reinstall recovery.
  - Exclude transient sync caches, temporary staging directories, and re-downloadable media caches from OS backup (`URLResourceValues.isExcludedFromBackup = true`).
  - Re-evaluate excluding the local SQLite replica from OS backup **only after** cloud sync recovery is verified end-to-end, or ensure sync safely reconciles a restored backup snapshot without overwriting newer remote records.
- **Android (`:app`, dormant)**: If Android resumes active development later, align `allowBackup` / `backup_rules.xml` with the same recovery strategy rather than applying a blanket restriction without a recovery mechanism.

---

## 2. Member PII & photo protection

Member names and identity photos are personal data (PII):

- **Minimal QR payload**: QR codes encode **only** the 6-character member ID (`XXX-XXX`), never names, expiry dates, or photos (see [ADR-002](adr/002-qr-payload-format.md), [ADR-005](adr/005-short-member-id-format.md)).
- **On-disk protection (iOS)**:
  - Write member store files and JPEG photos atomically (`.atomic`) with iOS Data Protection (e.g. `.completeFileProtectionUntilFirstUserAuthentication` so background sync can still run after first unlock, or `.completeFileProtection` if access is strictly foreground-only).
  - Downsample and normalize member photos before writing (`maxDimension <= 800px`, JPEG quality `0.8`) off the main thread.
- **Logging & fixtures hygiene**: Never log real client names, photo paths containing sensitive context, tokens, or credentials. Use synthetic/de-identified data in all tests and sample avatars.
- **Repository secret hygiene**: Never commit API keys, backend credentials, service-account JSONs, `.jks`/`.keystore` files, or `keystore.properties`. For public repos, move Apple signing config (`DEVELOPMENT_TEAM`) to an untracked local `.xcconfig` when convenient.

---

## 3. Planned cloud sync security (single-admin scope)

When Firestore or Supabase is selected and implemented (planned):
- Use simple single-administrator authentication (no multi-role RBAC or multi-tenant architecture unless requirements explicitly expand).
- Enforce backend access rules (Firestore Security Rules or Supabase RLS) so unauthenticated clients cannot read or write member records or photos — never rely on client-side checks alone.
- Keep all transport over HTTPS with system TLS verification.
- Store auth tokens/session credentials in **iOS Keychain** (never `UserDefaults` or plaintext files).
- Validate external payloads at trust boundaries (never force-unwrap `!` / `!!` remote payloads or corrupt files).

---

## 4. ID generation & data integrity

- **Deterministic test IDs vs secure production IDs**:
  - **Current**: `MemberIdGenerator.generate(random)` in `:shared` accepts an injectable `kotlin.random.Random` (used for deterministic tests) and defaults to `Random.Default`.
  - **Planned**: Keep the injectable deterministic generator strictly for tests, and back production ID generation with a platform CSPRNG (`SecRandomCopyBytes` on iOS / `java.security.SecureRandom` on Android) so member IDs are unpredictable.
- **Collision protection**: Before persisting a newly generated short ID (`XXX-XXX`), verify uniqueness with a bounded retry loop (e.g. up to 5 attempts) rather than silently overwriting an existing member record.
- **Schema & data preservation**:
  - Once real member data exists, never use destructive migrations (`fallbackToDestructiveMigration`) or silently drop records on format upgrades.
  - Provide explicit, tested migrations (and preserve exported schemas if Android Room is modified).

---

## 5. Permissions & graceful degradation

- Request camera permission (`NSCameraUsageDescription`) and photo library access (`NSPhotoLibraryUsageDescription`) only at the point of use.
- Degrade gracefully to photo library selection, simulator sample photo, or manual ID entry when camera permission is denied or hardware is unavailable.

---

## References

- [Apple: Encrypting Your App's Files (Data Protection)](https://developer.apple.com/documentation/uikit/protecting-the-user-s-privacy/encrypting-your-app-s-files)
- [Apple: Keychain Services](https://developer.apple.com/documentation/security/keychain-services)
- [Apple: Excluding Files from Backups](https://developer.apple.com/documentation/foundation/urlresourcevalues/isexcludedfrombackup)
- [Android Developers: Security Best Practices](https://developer.android.com/privacy-and-security/security-tips)
