#!/usr/bin/env python3
"""Prepare the approved KARTA Build 14 tree for the final 1.0 cut.

This script is intentionally narrow. Run it only after the physical clean-install
and signed Build 13 -> Build 14 update-preservation gates pass.
"""

from __future__ import annotations

import argparse
from pathlib import Path


REPLACEMENTS = {
    "pubspec.yaml": [
        ("version: 0.9.0-rc.1+14", "version: 1.0.0+15"),
    ],
    "lib/main.dart": [
        ("KARTA Alpha 0.9 · HMATIAS", "KARTA 1.0 · HMATIAS"),
        ("KARTA Alpha 0.9", "KARTA 1.0"),
    ],
    "test/onboarding_wallet_creation_test.dart": [
        (
            "onboarding remains explicitly Alpha while using production-grade local wording",
            "onboarding exposes final 1.0 release wording",
        ),
        ("KARTA Alpha 0.9 · HMATIAS", "KARTA 1.0 · HMATIAS"),
    ],
}


def prepare(root: Path) -> None:
    for relative, replacements in REPLACEMENTS.items():
        path = root / relative
        text = path.read_text(encoding="utf-8")
        for old, new in replacements:
            count = text.count(old)
            if count != 1:
                raise SystemExit(
                    f"Expected exactly one release-cut anchor in {relative}: "
                    f"{old!r}; found {count}."
                )
            text = text.replace(old, new, 1)
        path.write_text(text, encoding="utf-8")

    remaining = []
    for relative in ("lib/main.dart", "test/onboarding_wallet_creation_test.dart"):
        text = (root / relative).read_text(encoding="utf-8")
        if "KARTA Alpha 0.9" in text:
            remaining.append(relative)
    if remaining:
        raise SystemExit(
            "Final release wording still contains Alpha 0.9 in: "
            + ", ".join(remaining)
        )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--root",
        type=Path,
        default=Path(__file__).resolve().parents[1],
        help="apps/mobile root; defaults to the script's mobile project",
    )
    args = parser.parse_args()
    prepare(args.root.resolve())
    print("KARTA 1.0 release cut prepared: version 1.0.0+15")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
