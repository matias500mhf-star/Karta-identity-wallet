# KARTA 1.0 — Production Readiness Checklist

This is the single release-control checklist for the first personal-product production release. It distinguishes code-complete items from owner/device/Play Console actions. New product features are frozen until this gate is complete.

## 1. Code and release identity
- [x] Stable package identity preserved: `com.karta.identity.karta_wallet`.
- [x] Build 13 remains the signed update baseline.
- [x] Build 14 uses a higher Android versionCode.
- [x] Production signing key remains outside Git/GitHub/CI.
- [x] APK release verifier checks package, version, target SDK, signing certificate and SHA-256.
- [x] AAB release verifier checks JAR signature, signing certificate and SHA-256.
- [ ] Final signed release commit/tag recorded.
- [ ] Final APK and AAB hashes recorded.
- [ ] Cut `1.0.0` only after physical acceptance.

## 2. Android platform readiness
- [x] Target/compile baseline fixed at Android 16 / API 36.
- [x] Cleartext network traffic disabled at Android platform level.
- [x] Device backup disabled to avoid separating encrypted data from secure keys.
- [x] Sensitive screens protected with Android `FLAG_SECURE`.
- [x] File sharing uses a scoped `FileProvider`, not broad filesystem access.
- [x] Temporary shared/PDF material is kept in app cache and cleaned.
- [x] 16 KB APK gate checks AGP, native ELF alignment and zip alignment.
- [ ] Final signed APK passes the 16 KB gate.
- [ ] Final production AAB receives no unresolved compatibility warning in Play Console.
- [ ] Physical/remote 16 KB-device smoke test completed when available.

## 3. Wallet security and recovery
- [x] PIN is not stored in plaintext.
- [x] PIN verification uses PBKDF2 plus attempt throttling/lockout.
- [x] Legacy PIN migration requires successful authentication.
- [x] Biometric unlock uses the OS biometric subsystem.
- [x] Background/idle lock is enforced.
- [x] Document vault uses authenticated encryption.
- [x] Corrupted document index fails closed.
- [x] Corrupted credential index fails closed.
- [x] Interrupted document deletion is recoverable.
- [x] Interrupted backup restore is recoverable.
- [x] Interrupted wallet creation is recoverable.
- [x] Startup/security load failures expose retry instead of indefinite loading.
- [x] Backup export refuses known-corrupt credential metadata.
- [ ] Independent security/privacy review completed with no release blocker.

## 4. Data and privacy
- [x] In-app privacy disclosure exists.
- [x] Public privacy policy prepared in Portuguese and English.
- [x] Optional online account/backup behaviour is disclosed separately from local-only use.
- [x] No advertising SDK, advertising ID integration or behavioural analytics SDK is added to 1.0.
- [x] In-app online account deletion exists when the service is configured.
- [x] External account-deletion web resource prepared.
- [ ] Public privacy URL verified live without authentication.
- [ ] External deletion URL verified live without app access.
- [ ] Production hosting/subprocessors reviewed before final Data Safety submission.
- [ ] Final Data Safety answers reconciled against the exact production binary/backend.

## 5. Functional device acceptance
On the exact candidate that will become 1.0:
- [ ] Clean install succeeds.
- [ ] Create PIN, close/reopen and unlock.
- [ ] Enable/disable biometrics and unlock after background lock.
- [ ] Add profile/local credential.
- [ ] Add document with image/PDF.
- [ ] Open/decrypt PDF and images.
- [ ] Search/filter documents.
- [ ] Issue/expiry dates and validity states behave correctly.
- [ ] QR generation/scanning works for supported payload.
- [ ] File fingerprint comparison works.
- [ ] Share/export opens Android chooser and exported copy is usable.
- [ ] Encrypted backup can be created.
- [ ] Backup restores profile, credentials and documents into a clean app.
- [ ] Delete document and restart without vault inconsistency.
- [ ] Delete local wallet and confirm onboarding returns safely.

## 6. Signed update preservation
- [ ] Start from installed signed Build 13 with representative data.
- [ ] Create and preserve a verified encrypted backup first.
- [ ] Build Build 14 offline using the same permanent certificate.
- [ ] APK verifier returns `RELEASE GATE: PASS`.
- [ ] AAB verifier returns `RELEASE BUNDLE GATE: PASS`.
- [ ] `adb install -r` upgrades Build 13 to Build 14 without uninstall.
- [ ] Existing PIN still unlocks.
- [ ] Profile and credentials survive.
- [ ] Encrypted documents/PDFs survive and open.
- [ ] Biometric preference behaves correctly.
- [ ] QR/share still work.
- [ ] New Build 14 backup restores on a clean install.

## 7. Accessibility and UX
- [x] Existing automated UI coverage includes narrow-phone/large-text layout checks.
- [x] Error states avoid silent destructive recovery.
- [x] Empty, recovery and loading states have actionable copy.
- [ ] Physical test with Android large font/display scaling.
- [ ] Screen-reader smoke test on onboarding, unlock, wallet, document vault and settings.
- [ ] Verify touch targets and contrast on the final release device.

## 8. Google Play listing
- [x] Draft app name, PT/EN short descriptions and full descriptions prepared.
- [x] Support email defined.
- [x] Website, privacy and account-deletion URLs defined.
- [x] Release-note draft prepared.
- [ ] 512×512 production icon prepared from the approved KARTA mark.
- [ ] Feature graphic prepared from approved branding and real product capabilities.
- [ ] Phone screenshots captured from the exact signed release candidate.
- [ ] Content rating questionnaire completed.
- [ ] Target audience selected intentionally.
- [ ] App access/reviewer notes explain local-only use requires no login.
- [ ] Google Play App Signing configured with owner-controlled account recovery.
- [ ] AAB uploaded to internal/closed testing before production.
- [ ] Pre-launch report reviewed; release blockers resolved.

## 9. Repository and ownership controls
- [ ] Repository changed from Public to Private (#25).
- [ ] `main` protected (#27).
- [ ] `release/0.9-rc1` protected (#27).
- [ ] Security/API/Mobile checks required before release-line merge.
- [ ] Force pushes and branch deletion blocked on protected release branches.
- [ ] GitHub/Codex/Vercel access revalidated after repository visibility changes.
- [x] Secret/signing-material repository security gate active.

## 10. Production operations after launch
- [x] No extra telemetry SDK is required for launch; privacy surface stays minimal.
- [ ] Play Android Vitals monitored for crashes/ANRs after rollout.
- [ ] Support mailbox ownership and response process confirmed.
- [ ] Account-deletion requests have an operational handling process.
- [ ] Release hashes, certificate fingerprint and release notes archived.
- [ ] Permanent signing key has at least two encrypted offline backups.
- [ ] Staged rollout used rather than immediate 100% production rollout.
- [ ] Rollback/stop-rollout decision owner identified.

## 11. Release decision

**GO** only when every release-blocking checkbox in sections 1–9 is complete and the independent review has no unresolved high-severity finding.

Anything non-essential discovered after code freeze goes to 1.0.x / 1.1 rather than expanding the 1.0 scope.
