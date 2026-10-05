# Android 16 KB page-size compatibility — KARTA

KARTA targets Android 16 / API 36. Flutter and several mobile plugins include native libraries, so 16 KB compatibility is treated as a release-quality requirement rather than assumed.

## Automated gate

`apps/mobile/scripts/check_android_16kb.sh` verifies:

1. the generated Android Gradle Plugin is at least 8.5.1;
2. every `arm64-v8a` and `x86_64` shared library in the APK has LOAD segment alignment of at least 16 KB;
3. Android `zipalign -P 16` succeeds on the built APK.

The gate runs in Mobile CI and in the unsigned Android release workflow.

## Device acceptance

Before the first production rollout, also run the final signed release on a 16 KB Android environment when available.

Confirm the test environment:

```bash
adb shell getconf PAGE_SIZE
```

Expected result:

```
16384
```

Then execute the same functional acceptance used for the normal Build 14 device gate, with particular attention to startup, biometrics, camera/image import, PDF rendering, QR scanning, sharing/export and encrypted backup/restore.

## Google Play

For the final AAB, review the Play Console compatibility result before production rollout. Do not suppress or override a 16 KB incompatibility warning without resolving the affected native library.
