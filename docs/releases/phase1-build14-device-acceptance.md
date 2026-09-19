# KARTA Phase 1 — Build 14 device acceptance

Candidate: `0.9.0-rc.1+14`

Baseline for update preservation: signed Build 13 (`0.9.0-rc.1+13`).

Current validated tooling head: `a4ef91726963359ca1163b0b9730c80c0b35fca7`.

## Purpose

This gate proves two different things separately:

1. the Build 14 candidate works correctly on a clean Android install;
2. a Build 14 APK signed with the same permanent KARTA certificate can update signed Build 13 without losing wallet data.

A debug APK may be used for the clean-install functional pass. It must **not** be used as evidence of update compatibility with signed Build 13 because Android signing identities differ.

## CI status for this gate

At tooling head `a4ef91726963359ca1163b0b9730c80c0b35fca7`:

- KARTA API CI passed;
- release helper scripts passed Python syntax validation;
- Flutter analyze passed;
- full Flutter tests passed;
- Android debug APK build passed;
- Build 14 debug artifact upload passed;
- external Vercel status passed.

GitHub Actions artifact digest for this head:

`sha256:9cd83655923ff66d0be672e3dc2a1fe480d1ca0f808c4ddc90dddbf7c0e48e52`

## A. Clean-install functional pass

Use the CI-produced Build 14 debug APK on a disposable Android device/profile.

Verify:

- [ ] KARTA installs and opens without crash.
- [ ] Create a six-digit PIN and unlock again after relaunch.
- [ ] Enable biometrics, lock the app and unlock with biometrics.
- [ ] Add a document with issue date and expiry date.
- [ ] Confirm the correct validity badge: valid / expiring / expired / unknown.
- [ ] Add front/back images and an attached PDF or image.
- [ ] Open/read the stored document/PDF successfully.
- [ ] QR generation/scanning works for the supported payload.
- [ ] Share/export flow opens the Android share sheet and the shared copy is usable.
- [ ] Background/idle locking works as expected.
- [ ] Create an encrypted backup.
- [ ] Restore that backup on a clean app state and verify profile, credentials and documents.
- [ ] Delete a test document and verify the vault remains consistent after restart.

Record device model, Android version, candidate commit, APK SHA-256 and any failure before changing code.

## B. Offline signed Build 14 preparation

Build 13 was signed offline with the permanent owner-controlled key. Keep that same model for the Build 14 update-preservation test. Do not upload the permanent `.jks`, its Base64 representation or its passwords to GitHub, issues, pull requests or chat.

From the approved Build 14 commit:

```bash
cd apps/mobile
flutter create --platforms=android --android-language=kotlin --project-name=karta_wallet --org=com.karta.identity --no-pub .
python3 scripts/install_android.py
cp /OWNER-CONTROLLED-PATH/karta-upload.jks android/app/karta-upload.jks
export KARTA_KEY_ALIAS='karta-upload'
export KARTA_KEYSTORE_PASSWORD='...'
export KARTA_KEY_PASSWORD='...'
python3 scripts/configure_release_signing.py
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

Use a trusted shell/session and avoid storing the three secret environment-variable values in screenshots, release notes or logs.

## C. Verify the signed artifact before installation

Run:

```bash
python3 scripts/verify_release_artifact.py \
  build/app/outputs/flutter-apk/app-release.apk
```

The verifier must return `RELEASE GATE: PASS` and confirm:

- package: `com.karta.identity.karta_wallet`;
- versionName: `0.9.0-rc.1`;
- versionCode: `14`;
- certificate SHA-256 matches the permanent KARTA certificate recorded in `rc1.md`;
- a fresh APK SHA-256 is printed for the release record.

If the certificate fingerprint does not match, **do not install the APK over Build 13**.

## D. Signed update-preservation test

Before installing Build 14 over Build 13:

- [ ] Keep signed Build 13 installed on the device.
- [ ] Create a new encrypted backup from Build 13.
- [ ] Verify the backup password and preserve a copy outside the phone.
- [ ] Record Build 13 APK/certificate reference and the Build 14 APK hash.
- [ ] Add test data to Build 13: profile, credential, image/PDF document, QR/share scenario and biometric setting.

Install the verified signed Build 14 as an Android update, without uninstalling Build 13:

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

If Android reports a signature/version incompatibility, stop. Do not uninstall the data-bearing Build 13 merely to force installation.

After successful update verify:

- [ ] Existing PIN still unlocks the wallet.
- [ ] Existing profile and credentials remain present.
- [ ] Existing documents/images/PDFs decrypt and open.
- [ ] Existing backup/restore capability remains available.
- [ ] Biometric setting behaves correctly after update.
- [ ] QR and share/export still work.
- [ ] New issue/expiry fields can be added to new documents.
- [ ] Legacy documents without issue/expiry metadata still open normally.
- [ ] New Build 14 backup restores successfully on a clean install.

## E. Phase 1 acceptance rule

Do not mark PR #19 ready for merge and do not cut `1.0.0` until both the clean-install pass and the signed Build 13 → Build 14 update-preservation pass are complete with no release-blocking data-loss, security, document, PDF, QR/share or authentication failures.
