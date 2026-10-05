# KARTA Mobile

Flutter Android client for the KARTA Identity Wallet.

Current Phase 1 release candidate: `0.9.0-rc.1+14` (Build 14).

## Product model

KARTA is local-first:
- PIN-protected wallet with optional Android biometric unlock;
- encrypted local document vault;
- local identity profile and local, non-issuer-verified credentials;
- PDF/image handling, QR and user-directed sharing/export;
- password-encrypted backup and clean-state restore;
- optional invite-only online account and encrypted-backup beta.

KARTA does not claim that a locally created credential is a government-issued or issuer-verified identity document.

## Android debug validation

```sh
flutter create --platforms=android --android-language=kotlin --project-name=karta_wallet --org=com.karta.identity --no-pub .
python3 scripts/install_android.py
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

The Android release patch enforces:
- minSdk >= 24;
- compileSdk >= 36;
- targetSdk >= 36;
- `android:allowBackup="false"`;
- `android:usesCleartextTraffic="false"`;
- KARTA launcher/brand;
- `FLAG_SECURE` at runtime;
- private FileProvider paths for user-directed temporary sharing.

## Production signing

Production signing is **offline only** with the owner-controlled permanent KARTA certificate.

Do not upload the permanent keystore or signing passwords to GitHub Actions, issues, pull requests, chat, or source files.

See:
- `docs/releases/android-signing.md`
- `docs/releases/phase1-build14-device-acceptance.md`

## Privacy / Play

In-app privacy disclosure is available from KARTA Settings.

Public policy:
- https://comercialhmatiasps.com/karta-privacidade.html

External account-deletion resource:
- https://comercialhmatiasps.com/karta-eliminar-conta.html

Play Data Safety working sheet:
- `docs/store/google-play-data-safety.md`

## PDF and export security

PDF viewing uses Android `PdfRenderer` and an app-private temporary file whose pathname is removed once the renderer opens it.

Share uses a private FileProvider cache path with temporary read permission. Export uses the Android document destination picker after explicit user action.

Password-protected PDFs are not supported in this release and fail safely.
