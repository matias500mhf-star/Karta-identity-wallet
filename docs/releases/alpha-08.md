# KARTA Alpha 0.8 — Android acceptance and production work

## Implemented

- System Android chooser for document copies and QR PNGs. A confirmation explains that a recipient's copy cannot be revoked. Chooser opening does not mean delivery.
- Temporary share files use a non-exported FileProvider restricted to the sharing directory, read-only URI grants, and one-hour cleanup while running or on the next launch. No broad external storage access.
- External QR text/HTTP URLs are displayed separately from KARTA payloads. No automatic URL launch and no assertion of identity authenticity. Invalid KARTA versions remain rejected.
- Optional OS biometric session unlock. Enrollment changes require the app PIN; Android needs supported, enrolled biometrics. No iOS package is shipped.
- Existing PINs migrate after successful entry to PBKDF2-HMAC-SHA256 (600,000 iterations, random 16-byte salt). Failed attempts persist, with escalating cooldown after five failures. Existing document keys/files are preserved.
- Lock overlay covers every route after backgrounding or five minutes without pointer interaction. Native FLAG_SECURE blocks screenshots and recent-app previews.
- Password-encrypted manual backup (AES-256-GCM; PBKDF2-HMAC-SHA256, 600,000 iterations) includes profile, credentials, original PIN record and document ciphertext/key. Limit: 16 MiB encrypted document files. It does not include biometric enrollment.
- Restore requires a fresh, empty installation, authenticates document ciphertext before writes, and journals interrupted restoration. Users need the backup password AND original wallet PIN.

## Required physical-device acceptance

Use fictitious identity data. Keep the existing wallet installed.

1. Update Alpha 0.7 in place; check existing profile and open/export a saved PDF.
2. Generate a QR with accented test text. Read it on a second phone and from an image. Read an external HTTPS QR and an unsupported KARTA version.
3. Share a test PDF and QR PNG to WhatsApp and email. Confirm the recipient can open/read them; test cancel and no supported receiving app.
4. Enable biometrics with PIN confirmation. Test successful authentication, cancel, wrong finger, OS lockout, unavailable hardware, and disabling biometrics. PIN must remain usable subject to its cooldown.
5. Background the app from wallet, document, QR and backup screens. Return from camera, picker and sharesheet; require unlock and preserve the pending flow.
6. Create a backup; on a SECOND empty test installation restore and verify original files byte-for-byte and original PIN. Test wrong password, modified/truncated archive and interrupted restoration. Never uninstall the only copy to test recovery.

## Production blockers and concrete next work

This is a debug Alpha, not a commercial release or an independent security audit.

- Hardware-bound key access: the biometric prompt currently gates the session UI. The existing FlutterSecureStorage vault key is not newly bound to each biometric operation. Design and test a recoverable Keystore migration, including enrollment changes, before stronger claims.
- Independent security review, including PIN brute-force model, OS/device backup behavior, memory/resource limits, decrypted temporary files, corrupted indices and concurrent storage updates.
- Validate backup size/performance on target phones and introduce scalable streaming backup if needed. Confirm successful restore before marketing recovery guarantees.
- Stable HMATIAS-controlled release/upload signing key and Play App Signing enrollment. Never commit signing secrets or create disposable replacement keys for installed users.
- Release AAB, target-SDK/dependency review, software licenses, privacy policy/contact approved for publication, Play Data safety declaration, store listing and testing tracks.
- Play Console organization identity verification and payment/merchant eligibility for the actual business country. Production access/testing requirements depend on account type.
- Choose paid download or paid features only after launch scope/pricing is decided; implement purchase validation/restoration if using in-app purchases. No payments or subscriptions are active.
- Backend files exist but the mobile Alpha uses local storage. Online accounts, synced recovery and expiring/revocable links require deployed, audited infrastructure and operations.
- Face ID/Touch ID require the separate iOS build, entitlements/configuration and Apple-device testing. No official identity, NFC payment or Google Wallet pass issuance is implied.

Official references:
- https://developer.android.com/identity/sign-in/biometric-auth
- https://pub.dev/packages/local_auth
- https://support.google.com/googleplay/android-developer/answer/10787469
- https://support.google.com/googleplay/android-developer/answer/14151465
- https://developer.android.com/google/play/billing/getting-ready
