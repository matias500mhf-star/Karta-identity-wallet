#!/usr/bin/env python3
"""Regression test for the deterministic KARTA 1.0 release cut."""

from __future__ import annotations

import subprocess
import sys
import tempfile
from pathlib import Path


def main() -> int:
    script = Path(__file__).with_name("prepare_1_0_release.py").resolve()

    with tempfile.TemporaryDirectory(prefix="karta-1-0-cut-") as temp:
        root = Path(temp)
        (root / "lib").mkdir()
        (root / "test").mkdir()

        (root / "pubspec.yaml").write_text(
            "name: karta_wallet\nversion: 0.9.0-rc.1+14\n",
            encoding="utf-8",
        )
        (root / "lib" / "main.dart").write_text(
            "const a = 'KARTA Alpha 0.9 · HMATIAS';\n"
            "const b = 'KARTA Alpha 0.9';\n",
            encoding="utf-8",
        )
        (root / "test" / "onboarding_wallet_creation_test.dart").write_text(
            "const description = "
            "'onboarding remains explicitly Alpha while using production-grade local wording';\n"
            "const label = 'KARTA Alpha 0.9 · HMATIAS';\n",
            encoding="utf-8",
        )

        subprocess.run(
            [sys.executable, str(script), "--root", str(root)],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )

        assert "version: 1.0.0+15" in (root / "pubspec.yaml").read_text()
        assert "KARTA 1.0 · HMATIAS" in (root / "lib" / "main.dart").read_text()
        assert "KARTA Alpha 0.9" not in (root / "lib" / "main.dart").read_text()
        test_text = (root / "test" / "onboarding_wallet_creation_test.dart").read_text()
        assert "onboarding exposes final 1.0 release wording" in test_text
        assert "KARTA 1.0 · HMATIAS" in test_text

    print("prepare_1_0_release regression: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
