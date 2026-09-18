# KARTA 0.9 RC1 — release gate

Current branch: `release/0.9-rc1`

Current mobile version: `0.9.0-rc.1+13`

## Completed

- Alpha 0.9 feature line consolidated for RC1.
- Physical-device validation of the principal wallet, document and security flows reported complete by the owner.
- Flutter analysis and automated tests passed on the release line.
- Android release APK and AAB builds passed in CI.
- API build, Prisma migration validation and automated tests passed in CI.
- Stale-device overwrite protection is included for the optional online backup beta.
- Proprietary `LICENSE` and `OWNERSHIP.md` are present on the RC1 branch.
- `release/**` branches are covered by CI.
- A persistent owner-controlled Android signing identity has been created and kept outside the repository.
- RC1 APKs are signed offline with APK Signature Scheme v2 and v3 and the certificate fingerprint is verified.
- RC1 AABs are signed offline and their JAR signatures are verified.
- The signing keystore and passwords are not committed to GitHub or injected into the public unsigned-build workflow.
- Branded Build 13 completed Flutter analysis, automated tests, Android APK/AAB build and branding verification in CI from application source commit `b3dfb7e88f8af65b8b056c5e95424bd39eb073be`.

## Stable signing identity

The permanent signing certificate SHA-256 fingerprint is:

`38:DE:6F:30:04:0B:99:83:B8:85:BF:C7:DE:B2:2D:52:D5:43:4D:7E:D9:03:F0:F4:DC:99:DA:82:34:A5:53:2E`

Original signed RC1 artifact hashes (Build 12):

- APK SHA-256: `c6a31b5a27da3fd1373c2eeeb85f96598a0988deac7e21a5c042a292880c41cd`
- AAB SHA-256: `e1a84ee79c83d864f86c1555ea996e65ea581eb574488d8f1ad8879d519563f5`

Latest branded signed RC1 artifact hashes (Build 13):

- APK SHA-256: `f9769786bb90d258feafc1e38333dc7dbe80fc5814977bb4a7972e80359fc23a`
- AAB SHA-256: `0f0e0db2e93296b6f7082e94c0701e8c9acf1a8257ad4a43995ec6a15f53cf48`

The private keystore and recovery credentials must remain in owner-controlled offline custody. They are not part of this repository.

The repository also contains a secret-based signed-release workflow for a future controlled CI setup, but RC builds are deliberately signed offline so the private signing material does not need to enter the current GitHub repository configuration.

See `docs/releases/android-signing.md` for the owner-controlled key procedure.

## Pre-release migration warning

Earlier development APKs were signed with ephemeral debug certificates. The new permanent owner-controlled key establishes the stable signing identity for future public releases but cannot update a previously installed APK that uses the same package ID and a different certificate.

Before replacing any existing test wallet that contains valuable data:

1. create an encrypted KARTA backup;
2. verify that the backup is readable and the password is known;
3. preserve the previous APK/build record if available;
4. install the stable signed build only after backup verification;
5. restore through the supported fresh-install restore flow if the previous certificate is incompatible;
6. verify profile, documents, PIN and security state after restore.

Never uninstall a data-bearing test wallet merely to bypass an Android signature mismatch unless a verified backup exists.

## Remaining gates before KARTA 1.0 / Google Play

1. Validate the permanent-key APK on a clean Android device/profile and confirm the migration/restore path from an earlier debug-signed test wallet where applicable.
2. Perform a deliberate update-preservation test between two builds signed with the permanent KARTA key before public release.
3. Complete the Phase 1 product-polish work tracked in issue #18, including search/filtering and expiry/attention metadata without changing encryption semantics.
4. Complete an independent security and privacy review and resolve release-blocking findings.
5. Complete Play Console App Signing, privacy policy, Data safety, store listing, screenshots and production-release configuration.
6. Confirm production backend scope and deployment separately; the signed RC1 does not imply that an online production service is active.
7. Cut `1.0.0`, remove Alpha/RC user-facing language and merge/publish only after the remaining gates are accepted.
