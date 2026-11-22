# ADR-002 — QR payload format

**Date:** 2026-11  
**Status:** Accepted

---

## Context

The QR code on a member's pass must carry enough information for the app to look up the member record. Options considered:

| Option | Payload |
|--------|---------|
| A | Full member record (name, dates) encoded as JSON |
| B | Member ID only (UUID) |
| C | Signed token with embedded expiry |

## Decision

**Option B — member ID only.**

The QR encodes a single member ID string (originally UUIDv4, updated to a 6-character Crockford Base32 key in [ADR-005](005-short-member-id-format.md)), e.g.:

```
K7X-9M2
```

The app looks up the ID in local storage and reads the current membership data at scan time.

## Consequences

**Benefits**
- QR size is minimal — fast to scan and reliably decoded even from a small print or low-resolution photo.
- Membership data (name, expiry) is always read from storage, so it reflects any edits without reissuing the QR.
- No personal data is embedded in the QR itself, reducing privacy exposure if the image is shared.
- Format is cross-platform: an Android-generated QR is decoded identically on iOS.

**Trade-offs**
- The QR is meaningless without access to the local database on the same device. This is acceptable for a single-device MVP.
- No offline cryptographic verification is possible (the QR cannot be validated without a database lookup).

**Mitigation path for production**
If the system scales to multiple devices, the UUID becomes a key in a shared database, and the lookup moves to a network call. Alternatively, include a short-lived HMAC signature in the payload for offline verification.
