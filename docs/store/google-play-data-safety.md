# KARTA — Google Play Data Safety working sheet

Status: release-preparation working document for the Phase 1 personal app.

This sheet describes the current code path. Reconcile it against the exact final APK/AAB and every SDK included in that build before submitting the Play Console form.

## Product model

KARTA is local-first. Users can use the wallet without an online account. The optional online component is currently a beta/invite flow and stores a client-encrypted backup envelope.

## Data handled locally

Depending on user input, local storage may contain:
- name and nationality;
- credential type, issuer/origin and reference/number;
- document title/type and issue/expiry dates;
- selected document images, PDFs and files;
- application security state such as PIN verifier, lockout counters and biometric-enabled preference.

Local vault document files are encrypted using AES-GCM. Android secure storage is used for security metadata/key material.

## Optional online account

When the online service is configured and the user creates an account:
- email address is transmitted to the KARTA API;
- the account password is transmitted over HTTPS for authentication and stored server-side only as a password hash;
- authentication sessions are stored with bounded expiry;
- an encrypted backup envelope may be uploaded at the user's explicit request;
- the backup password itself is not sent to the server;
- the server stores backup ciphertext/envelope, size, digest and update timestamp.

## Sharing

KARTA does not contain an advertising SDK in the current mobile dependency set.

User-initiated export/share can pass a selected copy or QR image to the Android system chooser or another app selected by the user. That is user-directed sharing and must be considered when answering Play's Data Safety questions.

## Camera / photos / files

QR scanning and user-selected document capture/import can invoke Android camera/image/file-picker surfaces. The user initiates these actions.

## Biometrics

Biometric authentication is delegated to Android through local_auth. KARTA does not receive or store biometric templates.

## Account deletion

In-app:
- Account and online backup → delete online account.
- API deletion removes the User row; related sessions and online backup are cascade-deleted.

External request resource:
- https://comercialhmatiasps.com/karta-eliminar-conta.html

Privacy policy:
- https://comercialhmatiasps.com/karta-privacidade.html

## Data Safety review before submission

Confirm against the final binary:
- [ ] no analytics/advertising/crash SDK was added after this review;
- [ ] exact data types declared in Play match optional online-account behavior;
- [ ] user-directed system sharing is described consistently;
- [ ] encryption-in-transit declaration matches production HTTPS configuration;
- [ ] account-deletion URL is live and functional;
- [ ] privacy-policy URL is live and matches in-app disclosure;
- [ ] any production logging excludes passwords, PINs, backup passwords, identity-document content and access tokens;
- [ ] final third-party SDK data practices are reviewed from their current documentation.

Do not submit this working sheet verbatim as a legal statement. Use it to answer the Play Console Data Safety form accurately for the final signed build.
