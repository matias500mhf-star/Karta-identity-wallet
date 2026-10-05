#!/usr/bin/env python3
"""Verify a signed KARTA Android App Bundle before Google Play upload.

This gate never reads private signing material. It verifies the AAB JAR
signature, signing certificate fingerprint and SHA-256 using standard JDK tools.
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
    parser.add_argument("aab", type=Path)
    parser.add_argument(
        "--expected-cert-sha256",
        default=(
            "38:DE:6F:30:04:0B:99:83:B8:85:BF:C7:DE:B2:2D:52:"
            "D5:43:4D:7E:D9:03:F0:F4:DC:99:DA:82:34:A5:53:2E"
        ),
    )
    args = parser.parse_args()

    aab = args.aab.resolve()
    if not aab.is_file():
        raise SystemExit(f"AAB not found: {aab}")

    jarsigner = shutil.which("jarsigner")
    keytool = shutil.which("keytool")
    if not jarsigner:
        raise SystemExit("jarsigner was not found in PATH (install a JDK).")
    if not keytool:
        raise SystemExit("keytool was not found in PATH (install a JDK).")

    try:
        verify_output = run(
            [jarsigner, "-verify", "-strict", "-verbose", "-certs", str(aab)]
        )
    except subprocess.CalledProcessError as exc:
        print(exc.stdout or "")
        raise SystemExit("AAB JAR signature verification failed.") from exc

    lower_verify = verify_output.lower()
    if "jar verified" not in lower_verify:
        raise SystemExit("jarsigner did not confirm a verified AAB.")

    cert_output = run([keytool, "-printcert", "-jarfile", str(aab)])
    cert_match = re.search(
        r"SHA256:\s*([0-9A-Fa-f:]{32,})",
        cert_output,
        flags=re.IGNORECASE,
    )
    if not cert_match:
        raise SystemExit("Could not read AAB signing certificate SHA-256.")

    actual_cert = normalize_fingerprint(cert_match.group(1))
    expected_cert = normalize_fingerprint(args.expected_cert_sha256)
    artifact_hash = sha256(aab)

    print(f"AAB: {aab}")
    print(f"Certificate SHA-256: {cert_match.group(1).upper()}")
    print(f"AAB SHA-256: {artifact_hash}")

    if actual_cert != expected_cert:
        print("\nRELEASE BUNDLE GATE: FAIL")
        print(
            "- signing certificate mismatch: AAB is not signed by the "
            "permanent KARTA identity"
        )
        return 1

    print("\nRELEASE BUNDLE GATE: PASS")
    print("AAB signature and permanent KARTA signing certificate are valid.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
