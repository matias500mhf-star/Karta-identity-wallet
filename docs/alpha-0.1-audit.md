# KARTA Alpha 0.1 — Technical Audit & Hardening Plan

## Current baseline

KARTA already has a meaningful foundation: Flutter mobile, NestJS API, Prisma/PostgreSQL, authentication, identity profiles, documents, document versions, document sharing, and audit logs.

## Findings

### Mobile
- `ApiService` supports register, login, `/me`, and document listing.
- Default Android emulator API URL is `http://10.0.2.2:3000`.
- Access token is held in memory by `ApiService`; production persistence/session restoration needs a secure storage strategy.
- QR verification is planned but not yet a complete end-to-end feature.
- The mobile UI is currently concentrated in `main.dart`; it should be progressively split into screens, models, state, and services.

### API
- NestJS 11 and Prisma 6 are configured.
- Authentication is separated into controllers/services/guard/token/password components.
- Database schema contains users, identity profiles, documents, document versions, shares, and audit logs.
- Document versions already model AES-256-GCM metadata (`algorithm`, `iv`, `authTag`, `contentHash`), but actual upload/download encryption flow must be verified end-to-end before Alpha release.
- PostgreSQL connection is environment-driven through `DATABASE_URL`.

## Alpha 0.1 acceptance criteria

1. User can register.
2. User can log in and receive a valid access token.
3. User session can be restored securely after app restart.
4. Authenticated `/me` returns the current identity.
5. User can create/update an identity profile.
6. User can add a document using a test fixture.
7. Document metadata is stored against the authenticated user only.
8. Document content is encrypted before persistent storage.
9. User can list and open only their own documents.
10. Document versions and hashes are recorded.
11. Audit events are generated for security-sensitive actions.
12. Share links are short-lived, revocable, and do not expose raw bearer secrets in storage.
13. API rejects unauthenticated access to protected resources.
14. Mobile displays useful error states instead of silently failing.
15. Production configuration contains no hard-coded secrets.
16. QR verification remains disabled until the signed verification protocol is implemented.

## Hardening priorities

- Add secure token storage and session lifecycle on mobile.
- Verify password hashing parameters and login throttling/rate limiting.
- Verify JWT signing configuration and refresh-token rotation/revocation.
- Add DTO validation consistently to all write endpoints.
- Enforce user ownership at service/repository level for every document operation.
- Complete encrypted object-storage flow and key-management boundaries.
- Add tests for authentication, authorization, document isolation, sharing expiry/revocation, and audit logging.
- Split the Flutter application into maintainable feature modules.
- Add CI checks for Flutter analysis/tests, TypeScript build/tests, and Prisma validation.

## Product direction

KARTA is being developed as a digital identity wallet, not merely a document folder. The architecture should therefore preserve a clear separation between:

- identity data;
- document metadata;
- encrypted document content;
- verification credentials/proofs;
- sharing/consent;
- audit/security events.

Future OCR/MRZ, selective disclosure, QR verification, KARTA Verify, and Business Verification API features must build on these boundaries rather than bypass them.
