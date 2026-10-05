# Google Play Data Safety — KARTA 1.0 draft

This is a release-preparation worksheet, not the submitted Play Console form. Confirm the production backend, hosting/subprocessors and final app binary before submission.

## App identity
- App: KARTA Identity Wallet
- Developer: HMATIAS – Prestação de Serviços SU, LDA
- Privacy policy: https://comercialhmatiasps.com/karta-privacidade.html
- Account deletion: available in-app when the optional online account service is configured.

## Current mobile build facts
- Local-first wallet; an online account is optional.
- No ads SDK.
- No advertising ID integration.
- No behavioural analytics SDK in the mobile app.
- HTTPS-only app networking; Android cleartext traffic is explicitly disabled.
- Local document-vault content is encrypted before storage.
- Local backup is password-encrypted on-device.
- Optional online backup uploads the encrypted envelope, not plaintext document content.

## Data types to review for Play Console
### Personal info — Email address
**Collected only if:** user creates/uses the optional online KARTA account.  
**Purpose:** account management, authentication and encrypted-backup service.  
**Required:** no for the local-only wallet; yes for the optional online account flow.  
**Retention/deletion:** account deletion endpoint removes the user and associated records.

### Files and docs / user-provided content
**Local-only by default.** Documents, images, PDFs, profile and local credentials remain on-device unless the user explicitly exports/shares them or includes them in an encrypted backup.

For optional online backup, the server receives an encrypted backup envelope. Confirm with Play Console definitions whether the encrypted payload should be declared under Files and docs for the production deployment; do not omit it merely because the server cannot decrypt it.

### App activity / diagnostics
No mobile analytics or crash-reporting SDK is currently integrated. Before Play submission, confirm that the production API/infrastructure logs do not introduce additional reportable data categories.

### Device or other identifiers
No advertising identifier integration is currently present. Reconfirm the final dependency tree before submission.

## Sharing
No sale of user data. No advertising sharing.

Before selecting "not shared" in Play Console, confirm all production infrastructure/service providers and the exact Google Play definition/exemptions for service providers.

## Security practices
- Data encrypted in transit: yes for online app traffic (HTTPS only).
- Encrypted local document vault: yes.
- Encrypted backup before upload: yes.
- User can request account deletion in-app: yes when online account feature is configured.
- Independent security/privacy review: still a release gate.

## Final pre-submit checks
- [ ] Public privacy URL is live, non-geofenced and readable without login.
- [ ] In-app privacy text matches the public policy.
- [ ] Production backend/subprocessors are confirmed.
- [ ] Final dependency tree checked for analytics/ads/device identifiers.
- [ ] Play Data Safety answers reviewed against the final production binary.
- [ ] Account-deletion flow tested against production/staging backend.
