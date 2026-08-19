#!/usr/bin/env python3
"""Rename Firefly category hero banners from ~/Downloads/ to the canonical
cat-<slug>.png filenames inside StyleMart/assets/img/.

Matching is by the unique opening phrase that Firefly preserved in the
filename. The phrase comes verbatim from prompts-14-category-heroes.txt.

Idempotent: re-running just no-ops on missing sources.
"""
import os
import shutil
import sys
from pathlib import Path

HOME = Path.home()
DOWNLOADS = HOME / "Downloads"
TARGET = Path(__file__).resolve().parents[3] / "StyleMart" / "assets" / "img"

# (canonical_filename, unique opening phrase from the prompt)
HEROES = [
    ("cat-tshirts.png",      "An oak side table with a neat stack of three folded t-shirts"),
    ("cat-shirts.png",       "An open oak shelving unit with three neatly folded button-down shirts"),
    ("cat-jeans.png",        "A simple oak wooden chair with a folded pair of indigo denim jeans"),
    ("cat-pants.png",        "A wooden valet stand with a neatly folded pair of stone chinos"),
    ("cat-jackets.png",      "A rustic oak coat rack with three blazers hung in earthy tones"),
    ("cat-dresses.png",      "A bright dressing-area corner with a sage-green silk a-line dress"),
    ("cat-sweaters.png",     "A round oak coffee table with three folded knitwear pieces"),
    ("cat-raincoats.png",    "A foyer scene with a beige trench coat hung from a wall hook"),
    ("cat-sneakers.png",     "A polished oak sideboard with two pairs of premium leather sneakers"),
    ("cat-formal-shoes.png", "A classic oak shoeshine bench with two pairs of polished leather shoes"),
    ("cat-backpacks.png",    "A wooden hallway bench with a structured leather commuter backpack"),
    ("cat-sunglasses.png",   "An oak desk surface with three pairs of sunglasses arranged diagonally"),
    ("cat-accessories.png",  "A circular oak tray with assorted small leather goods"),
    ("cat-menswear.png",     "A sunlit walk-in closet corner with a row of neatly hung shirts"),
    ("cat-womenswear.png",   "A bright open dressing-area corner with hung silk blouses"),
]


def find_match(phrase: str) -> Path | None:
    """Return the first Downloads/Firefly_*.png whose filename starts with phrase."""
    needle = phrase.replace(",", "").lower()
    for src in sorted(DOWNLOADS.glob("Firefly_*.png")):
        haystack = src.name.replace(",", "").lower()
        if needle in haystack:
            return src
    return None


def main() -> int:
    if not DOWNLOADS.is_dir():
        print(f"FATAL: Downloads dir not found at {DOWNLOADS}", file=sys.stderr)
        return 2
    TARGET.mkdir(parents=True, exist_ok=True)

    moved, missing, skipped = [], [], []
    for canonical, phrase in HEROES:
        dst = TARGET / canonical
        src = find_match(phrase)
        if src is None:
            missing.append(canonical)
            continue
        if dst.exists():
            skipped.append((src.name, canonical))
            continue
        shutil.move(str(src), str(dst))
        moved.append((src.name, canonical))

    print("MOVED:")
    for src, dst in moved:
        print(f"  {src}\n    -> {dst}")
    if skipped:
        print("\nSKIPPED (target already exists):")
        for src, dst in skipped:
            print(f"  {dst} (source was {src})")
    if missing:
        print("\nMISSING (no matching Firefly file in Downloads):", file=sys.stderr)
        for dst in missing:
            print(f"  {dst}", file=sys.stderr)
        return 1
    print(f"\nDone. {len(moved)} moved, {len(skipped)} skipped, {len(missing)} missing.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
