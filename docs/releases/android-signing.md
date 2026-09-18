# KARTA Android release signing

## Objective

KARTA production releases must be signed with one persistent Android upload/release key controlled by the project owner. The private key must never be committed to Git, copied into source files, embedded in documentation, or shared through pull requests/issues.

## 1. Create the owner-controlled key locally

Run this on a trusted computer under the owner's control:

```bash
keytool -genkeypair \
  -v \
  -keystore karta-upload.jks \
  -alias karta-upload \
  -keyalg RSA \
  -keysize 4096 \
  -validity 10000
```

Choose a strong unique keystore password and key password. Store the original `karta-upload.jks` offline in at least two encrypted backups controlled by the owner.

Do not commit the `.jks` file. The repository `.gitignore` already blocks `*.jks`.

## 2. Record the public certificate fingerprint

```bash
keytool -list -v -keystore karta-upload.jks -alias karta-upload
```

Record the SHA-256 certificate fingerprint in the release records. The fingerprint is public verification data; the private key is not.

## 3. Encode the keystore for GitHub Actions

Linux/macOS:

```bash
base64 < karta-upload.jks | tr -d '\n' > karta-upload.jks.b64
```

PowerShell:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes('karta-upload.jks')) | Set-Content -NoNewline karta-upload.jks.b64
```

Treat the Base64 value as a secret because it is the private keystore in encoded form.

## 4. Configure repository Actions secrets

In the KARTA GitHub repository, create exactly these Actions secrets:

- `KARTA_ANDROID_KEYSTORE_B64` — full Base64 content of `karta-upload.jks`
- `KARTA_KEYSTORE_PASSWORD` — keystore password
- `KARTA_KEY_ALIAS` — normally `karta-upload`
- `KARTA_KEY_PASSWORD` — key password

Never place these values in source code, workflow YAML, README, issues, pull requests or chat logs.

## 5. Produce the signed RC1 build

Open GitHub Actions → **KARTA Android Signed Release** → **Run workflow** and select `release/0.9-rc1`.

The workflow will:

1. verify that all signing secrets exist;
2. recreate the Android scaffold;
3. restore the private keystore only inside the ephemeral job;
4. configure release signing without committing secrets;
5. print the public SHA-256 certificate fingerprint;
6. run `flutter analyze` and all Flutter tests;
7. build a signed release APK;
8. build a signed release AAB;
9. generate SHA-256 hashes for both outputs;
10. upload short-lived signed artifacts.

## 6. Google Play custody

For Play Console publication, enable Google Play App Signing. Keep the KARTA upload key and Play Console access under accounts controlled by the project owner or an expressly authorised legal entity. Enable multi-factor authentication and preserve recovery methods offline.

## Critical rule

Do not create a new production signing key for each release. Android updates require continuity of signing identity. Loss of the private upload/release key can disrupt the update path and ownership control.
