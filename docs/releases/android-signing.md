# KARTA Android release signing

## Security model

KARTA production releases are signed with one persistent Android signing identity controlled by the project owner.

The permanent private keystore must remain outside:
- Git;
- GitHub Actions secrets;
- CI/CD runners;
- source files;
- issue/PR attachments;
- chat uploads;
- shared drives that are not explicitly owner-controlled and encrypted.

The repository contains only public verification material and release tooling.

## 1. Owner-controlled key

Generate or retain the permanent key only on a trusted owner-controlled computer.

Example for a new project only:

```bash
keytool -genkeypair \
  -v \
  -keystore karta-upload.jks \
  -alias karta-upload \
  -keyalg RSA \
  -keysize 4096 \
  -validity 10000
```

For KARTA, **do not generate a replacement key if the signed Build 13 key already exists**. Android update compatibility depends on signing continuity.

Keep at least two encrypted offline backups of the permanent keystore and recovery material.

## 2. Public certificate fingerprint

The certificate SHA-256 fingerprint is public verification data and may be recorded in release documentation.

```bash
keytool -list -v -keystore /OWNER-CONTROLLED-PATH/karta-upload.jks -alias karta-upload
```

Never publish the private keystore or passwords.

## 3. Build on a trusted owner-controlled machine

From the exact approved release commit:

```bash
cd apps/mobile
flutter create --platforms=android --android-language=kotlin --project-name=karta_wallet --org=com.karta.identity --no-pub .
python3 scripts/install_android.py

export KARTA_KEYSTORE_PATH='/OWNER-CONTROLLED-PATH/karta-upload.jks'
export KARTA_KEY_ALIAS='karta-upload'
export KARTA_KEYSTORE_PASSWORD='...'
export KARTA_KEY_PASSWORD='...'

python3 scripts/configure_release_signing.py
flutter pub get
flutter analyze
flutter test
flutter build apk --release
flutter build appbundle --release
```

Use a trusted shell/session. Avoid leaving signing passwords in shell history, screenshots, logs or release notes.

## 4. Verify before installation or upload

Verify both release artifacts with the repository gates:

```bash
python3 scripts/verify_release_artifact.py \
  build/app/outputs/flutter-apk/app-release.apk

python3 scripts/verify_release_bundle.py \
  build/app/outputs/bundle/release/app-release.aab
```

The APK gate must report `RELEASE GATE: PASS` and confirm:
- package identity;
- version name/code;
- target SDK;
- the permanent KARTA certificate SHA-256;
- APK SHA-256.

The bundle gate must report `RELEASE BUNDLE GATE: PASS` and confirm:
- the AAB JAR signature is valid;
- the permanent KARTA certificate SHA-256 matches;
- AAB SHA-256 is printed for the release record.

Do not install or upload release artifacts unless the corresponding gates pass.

## 5. Build 13 → Build 14 update test

Build 14 must be signed with the **same permanent certificate** used by signed Build 13.

Install it over the existing signed Build 13 without uninstalling:

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

If Android reports a signing/version mismatch, stop. Do not uninstall the data-bearing Build 13 to force the update.

## 6. Google Play custody

For Play Console publication, use Google Play App Signing as the distribution custody layer while preserving owner control of the KARTA upload key and account recovery methods.

Enable strong multi-factor authentication on the Play Console owner account and keep recovery material offline.

## Critical rule

The permanent KARTA private key is never restored into GitHub Actions. The repository workflow named **KARTA Android Release Gate** validates tooling only; it intentionally does not sign production artifacts.
