#!/usr/bin/env python3
"""Verify a signed KARTA Android App Bundle before Play upload.

This tool does not read private key material. It verifies the JAR signature,
the permanent KARTA certificate fingerprint and records the AAB SHA-256.
APK package/version identity remains verified separately by
verify_release_artifact.py.
"""

from __future__ import annotations

import argparse
import hashlib
import re
import shutil
import subprocess
from pathlib import Path


DEFAULT_CERT = (
    "38:DE:6F:30:04:0B:99:83:B8:85:BF:C7:DE:B2:2D:52:"
    "D5:43:4D:7E:D9:03:F0:F4:DC:99:DA:82:34:A5:53:2E"
)


def run(command: list[str]) -> str:
    completed = subprocess.run(
        command,
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )
    return completed.stdout


def digest(path: Path) -> str:
    value = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            value.update(chunk)
    return value.hexdigest()


def normalize(value: str) -> str:
    return re.sub(r"[^0-9A-Fa-f]", "", value).upper()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("aab", type=Path)
    parser.add_argument("--expected-cert-sha256", default=DEFAULT_CERT)
    args = parser.parse_args()

    aab = args.aab.resolve()
    if not aab.is_file():
        raise SystemExit(f"AAB not found: {aab}")

    jarsigner = shutil.which("jarsigner")
    keytool = shutil.which("keytool")
    if not jarsigner or not keytool:
        raise SystemExit("jarsigner/keytool were not found in PATH (install a JDK).")

    run([jarsigner, "-verify", "-strict", str(aab)])
    certificate = run([keytool, "-printcert", "-jarfile", str(aab)])
    match = re.search(r"SHA256:\s*([0-9A-Fa-f:]+)", certificate)
    if not match:
        raise SystemExit("Could not read the AAB signing certificate SHA-256.")

    actual = normalize(match.group(1))
    expected = normalize(args.expected_cert_sha256)
    artifact_hash = digest(aab)

    print(f"AAB: {aab}")
    print(f"Certificate SHA-256: {match.group(1).upper()}")
    print(f"AAB SHA-256: {artifact_hash}")

    if actual != expected:
        print("\nRELEASE GATE: FAIL")
        print("- signing certificate mismatch: AAB is not signed by the permanent KARTA identity")
        return 1

    print("\nRELEASE GATE: PASS")
    print("AAB signature and permanent signing certificate match the expected release gate.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
