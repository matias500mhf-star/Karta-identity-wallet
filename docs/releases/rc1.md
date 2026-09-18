# KARTA 0.9 RC1 — release gate

Current branch: `release/0.9-rc1`

Current mobile version: `0.9.0-rc.1+12`

## Completed

- Alpha 0.9 feature line consolidated for RC1.
- Physical-device validation of the principal wallet, document and security flows reported complete by the owner.
- Flutter analysis and automated tests passed on the release line.
- Android debug APK build passed in CI.
- API build, Prisma migration validation and automated tests passed in CI.
- Stale-device overwrite protection is included for the optional online backup beta.
- Proprietary `LICENSE` and `OWNERSHIP.md` are present on the RC1 branch.
- `release/**` branches are covered by CI.
- A manual signed-release workflow is present to produce APK and AAB artifacts without committing the private signing key.

## Stable signing identity

Public Android distribution must use one persistent signing identity controlled by the project owner.

The signed-release workflow requires these repository Actions secrets:

- `KARTA_ANDROID_KEYSTORE_B64`
- `KARTA_KEYSTORE_PASSWORD`
- `KARTA_KEY_ALIAS`
- `KARTA_KEY_PASSWORD`

See `docs/releases/android-signing.md` for the owner-controlled key procedure.

## Pre-release migration warning

Earlier development APKs were signed with ephemeral debug certificates. A new permanent owner-controlled key establishes the stable signing identity for future public releases but cannot update a previously installed APK that uses the same package ID and a different certificate.

Before replacing any existing test wallet that contains valuable data:

1. create an encrypted KARTA backup;
2. verify that the backup is readable and the password is known;
3. preserve the previous APK/build record if available;
4. install the stable signed build only after backup verification;
5. restore through the supported fresh-install restore flow;
6. verify profile, documents, PIN and security state after restore.

Never uninstall a data-bearing test wallet merely to bypass an Android signature mismatch unless a verified backup exists.

## Remaining gates before Google Play

1. Create and securely custody the persistent owner-controlled Android upload/release key.
2. Configure the four GitHub Actions secrets.
3. Run `KARTA Android Signed Release` on `release/0.9-rc1`.
4. Record the public signing certificate SHA-256 fingerprint and APK/AAB hashes.
5. Validate the signed APK on a clean device/profile and validate backup restoration where migration from a pre-release wallet is required.
6. Complete an independent security review.
7. Complete Play Console App Signing, privacy policy, Data safety, store listing, screenshots and production-release configuration.
8. Merge/publish only after these gates are accepted.
