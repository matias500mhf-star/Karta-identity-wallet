#!/usr/bin/env python3
"""Regression test for external KARTA release-keystore configuration."""

from __future__ import annotations

import os
import subprocess
import sys
import tempfile
from pathlib import Path


def main() -> int:
    script = Path(__file__).with_name("configure_release_signing.py").resolve()

    with tempfile.TemporaryDirectory(prefix="karta-signing-test-") as temp:
        root = Path(temp)
        gradle = root / "android" / "app" / "build.gradle.kts"
        gradle.parent.mkdir(parents=True)
        gradle.write_text(
            """android {
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}
""",
            encoding="utf-8",
        )

        keystore = root / "owner-controlled.jks"
        keystore.write_bytes(b"test-only-placeholder")

        env = os.environ.copy()
        env.update(
            {
                "KARTA_KEYSTORE_PATH": str(keystore),
                "KARTA_KEY_ALIAS": "karta-upload",
                "KARTA_KEYSTORE_PASSWORD": "test-keystore-password",
                "KARTA_KEY_PASSWORD": "test-key-password",
            }
        )

        subprocess.run(
            [sys.executable, str(script)],
            cwd=root,
            env=env,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )

        updated = gradle.read_text(encoding="utf-8")
        assert 'storeFile = file(System.getenv("KARTA_KEYSTORE_PATH"))' in updated
        assert 'signingConfig = signingConfigs.getByName("release")' in updated
        assert "karta-upload.jks" not in updated
        assert str(keystore) not in updated

    print("configure_release_signing external-keystore regression: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
