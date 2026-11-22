# ADR-005 — Human-Friendly Short Member ID Format

**Date:** 2026-11  
**Status:** Accepted  
**Supersedes:** ADR-002 UUID payload format

---

## Context

Originally, member IDs were generated as 128-bit UUIDv4 strings (e.g. `550e8400-e29b-41d4-a716-446655440000`, 36 characters with hyphens). While collision-free, this created significant operational friction for front-desk reception staff:
- Manual entry on mobile keyboards was slow (20–30 seconds) and highly error-prone.
- Visual comparison against member passes or lists was nearly impossible at a glance.
- QR code matrix density was unnecessarily high for a local gym check-in system.

## Decision

**Adopt a 6-character Crockford Base32 identifier grouped as `XXX-XXX` (e.g. `K7X-9M2`).**

### Key Characteristics:
1. **Alphabet (Crockford Base32)**:
   - `0123456789ABCDEFGHJKMNPQRSTVWXYZ` (32 characters).
   - Excludes easily confused characters: `I`, `L` (confused with `1`), `O` (confused with `0`).
   - Excludes `U` to avoid accidental generation of offensive words.
2. **Entropy & Uniqueness**:
   - $32^6 = 1,073,741,824$ (~1.07 billion unique combinations).
   - For gym scale (thousands to tens of thousands of members), the collision probability is negligible ($< 0.005\%$).
3. **Single Source of Truth (`:shared`)**:
   - `MemberIdGenerator` in `commonMain` handles generation, validation, and input normalization across both Android and iOS.
4. **Tolerant Search & Normalization**:
   - Case-insensitive (auto-uppercased).
   - Ignores spaces and hyphens (`k7x9m2`, `K7X-9M2`, `k7x 9m2` all resolve to `K7X-9M2`).
   - Tolerates common substitutions: `o`/`O` $\rightarrow$ `0`, `i`/`I`/`l`/`L` $\rightarrow$ `1`.
5. **Database Reset**:
   - Legacy test databases (containing pre-production UUID records) were reset on both platforms (Room database version 2 with `fallbackToDestructiveMigration(dropAllTables = true)` on Android; legacy JSON record filtering on iOS).

## Consequences

**Benefits**
- **Front-Desk Speed**: Manual typing takes only 2–3 seconds; easily communicated verbally or verified visually.
- **Compact QR Codes**: 7-character payload produces low-density QR codes that scan instantly from wider angles and in low-light conditions.
- **Cross-Platform Uniformity**: Both Android and iOS generate and parse identically via `:shared`.
