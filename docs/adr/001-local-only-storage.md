# ADR-001 — Local-only storage

**Date:** 2026-11
**Status:** Accepted (offline-first local persistence retained; "no cloud sync" superseded by planned sync roadmap in [ADR-006](006-target-architecture-standards.md))

---

## Context

The prototype needs to store member records and retrieve them in under a second during busy check-in periods. The app targets a single reception device (a tablet or staff phone) used in a gym with no guaranteed internet connection.

## Decision

All data is stored **on-device only**:
- Android: Room (SQLite) via a single DAO
- iOS: JSON file in the app's `Documents` directory

There is no backend API, no cloud sync, and no account system.

## Consequences

**Benefits**
- Zero network latency on lookup — instant QR verification.
- Works fully offline; no dependency on Wi-Fi or mobile data.
- No server infrastructure to build, host, or maintain at the prototype stage.
- No authentication or data-privacy surface to worry about at MVP.

**Trade-offs**
- Data exists only on the device it was entered on. If the device is replaced or wiped, member records are lost.
- Multiple reception desks cannot share the same member database without a sync layer.
- Backups rely on the user (iCloud / Android backup) rather than a managed service.

**Mitigation path for production**
Add a lightweight REST backend (e.g. Cloud Firestore, Supabase) and replace the local DAO/repository with a remote data source. The domain layer (Member model, expiry rules) requires no changes.
