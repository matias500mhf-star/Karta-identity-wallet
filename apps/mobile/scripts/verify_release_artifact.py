#!/usr/bin/env python3
"""Verify a KARTA Android APK before an on-device release/update test.

This script does not sign artifacts and never reads private key material. It
verifies the APK identity, version, signing certificate and SHA-256 digest using
Android SDK command-line tools already installed on the trusted workstation.
"""

from __future__ import annotations

import argparse
import hashlib
import re
import shutil
import subprocess
from pathlib import Path


def run(command: list[str]) -> str:
    completed = subprocess.run(
        command,
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )
    return completed.stdout


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def normalize_fingerprint(value: str) -> str:
    return re.sub(r"[^0-9A-Fa-f]", "", value).upper()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("apk", type=Path)
    parser.add_argument(
        "--expected-package",
        default="com.karta.identity.karta_wallet",
    )
    parser.add_argument("--expected-version-code", default="14")
    parser.add_argument("--expected-version-name", default="0.9.0-rc.1")
    parser.add_argument(
        "--expected-cert-sha256",
        default=(
            "38:DE:6F:30:04:0B:99:83:B8:85:BF:C7:DE:B2:2D:52:"
            "D5:43:4D:7E:D9:03:F0:F4:DC:99:DA:82:34:A5:53:2E"
        ),
    )
    args = parser.parse_args()

    apk = args.apk.resolve()
    if not apk.is_file():
        raise SystemExit(f"APK not found: {apk}")

    aapt = shutil.which("aapt")
    apksigner = shutil.which("apksigner")
    if not aapt:
        raise SystemExit("aapt was not found in PATH (install Android SDK Build Tools).")
    if not apksigner:
        raise SystemExit(
            "apksigner was not found in PATH (install Android SDK Build Tools)."
        )

    badging = run([aapt, "dump", "badging", str(apk)])
    match = re.search(
        r"package: name='([^']+)' versionCode='([^']+)' versionName='([^']+)'",
        badging,
    )
    if not match:
        raise SystemExit("Could not parse APK package/version metadata from aapt.")

    package_name, version_code, version_name = match.groups()
    failures: list[str] = []
    if package_name != args.expected_package:
        failures.append(
            f"package mismatch: expected {args.expected_package}, got {package_name}"
        )
    if version_code != str(args.expected_version_code):
        failures.append(
            f"versionCode mismatch: expected {args.expected_version_code}, got {version_code}"
        )
    if version_name != args.expected_version_name:
        failures.append(
            f"versionName mismatch: expected {args.expected_version_name}, got {version_name}"
        )

    signer_output = run([apksigner, "verify", "--verbose", "--print-certs", str(apk)])
    cert_match = re.search(
        r"Signer #1 certificate SHA-256 digest:\s*([0-9A-Fa-f:]+)",
        signer_output,
    )
    if not cert_match:
        raise SystemExit("Could not read the APK signing certificate SHA-256 digest.")

    actual_cert = normalize_fingerprint(cert_match.group(1))
    expected_cert = normalize_fingerprint(args.expected_cert_sha256)
    if actual_cert != expected_cert:
        failures.append(
            "signing certificate mismatch: APK is not signed by the permanent KARTA identity"
        )

    artifact_hash = sha256(apk)

    print(f"APK: {apk}")
    print(f"Package: {package_name}")
    print(f"Version: {version_name} ({version_code})")
    print(f"Certificate SHA-256: {cert_match.group(1).upper()}")
    print(f"APK SHA-256: {artifact_hash}")

    if failures:
        print("\nRELEASE GATE: FAIL")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("\nRELEASE GATE: PASS")
    print("Identity, version and permanent signing certificate match the expected Build 14 gate.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
