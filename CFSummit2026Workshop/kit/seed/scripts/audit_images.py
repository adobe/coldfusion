#!/usr/bin/env python3
"""Audit StyleMart product images vs. seed JSON contract.

Reports:
  * Primaries referenced in JSON but missing on disk (these break PLP/PDP rendering).
  * Secondaries referenced but missing (cosmetic — onerror falls back to SVG).
  * Files on disk that are not referenced anywhere (potential cruft).
  * Disk files whose suffix doesn't match what JSON expects for the same stem.

Run from CFSummit2026Workshop root:
    python kit/seed/scripts/audit_images.py
"""
from __future__ import annotations

import json
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
SEED = ROOT / "kit" / "seed" / "json"
IMG = ROOT / "StyleMart" / "assets" / "img"
SUFFIX_RE = re.compile(r"_(back|detail|front|side|alt)\.png$")
INTENTIONAL_UNREFERENCED = {"home-hero.png", "logo.png"}


def basename(url: str) -> str:
    return url.replace("\\", "/").rsplit("/", 1)[-1] if url else ""


def collect_refs():
    primaries: set[str] = set()
    secondaries: dict[str, set[str]] = defaultdict(set)
    other_refs: set[str] = set()
    products = json.loads((SEED / "products.json").read_text())
    plist = (
        products["products"]
        if isinstance(products, dict) and "products" in products
        else products
    )
    for p in plist:
        prim = basename(p.get("imageUrl") or "")
        if prim:
            primaries.add(prim)
        for key in ("images", "gallery", "product_images", "additional_images"):
            for img in p.get(key) or []:
                url = img.get("url") if isinstance(img, dict) else img
                name = basename(url)
                if name and name != prim:
                    secondaries[prim].add(name)

    def walk(obj):
        if isinstance(obj, dict):
            for v in obj.values():
                if isinstance(v, str) and v.endswith(".png"):
                    other_refs.add(basename(v))
                else:
                    walk(v)
        elif isinstance(obj, list):
            for v in obj:
                walk(v)

    for extra in ("categories.json", "promotions.json", "coupons.json"):
        path = SEED / extra
        if path.exists():
            walk(json.loads(path.read_text()))

    return primaries, secondaries, other_refs, len(plist)


def main() -> int:
    if not IMG.exists():
        print(f"!! {IMG} does not exist", file=sys.stderr)
        return 2
    primaries, secondaries, other_refs, n_products = collect_refs()
    on_disk = {p.name for p in IMG.glob("*.png")}

    all_secondaries = {s for ss in secondaries.values() for s in ss}
    referenced = primaries | all_secondaries | other_refs

    missing_primaries = sorted(primaries - on_disk)
    missing_secondaries = sorted(all_secondaries - on_disk)
    stranded = sorted(on_disk - referenced - INTENTIONAL_UNREFERENCED)

    suffix_violations: list[tuple[str, str]] = []
    for name in on_disk:
        m = SUFFIX_RE.search(name)
        if not m:
            continue
        primary_form = SUFFIX_RE.sub(".png", name)
        expected = secondaries.get(primary_form, set())
        if expected and name not in expected:
            suffix_violations.append((name, ", ".join(sorted(expected))))

    print(f"Products in seed:                      {n_products}")
    print(f"Unique primaries referenced:           {len(primaries)}")
    print(f"Unique secondaries referenced:         {len(all_secondaries)}")
    print(f"PNGs on disk (excl. brand/hero/logo):  {len(on_disk - INTENTIONAL_UNREFERENCED)}")
    print()

    print(f"[CRITICAL] Primaries missing on disk:  {len(missing_primaries)}")
    for n in missing_primaries:
        print(f"   - {n}")

    print()
    print(f"[INFO] Secondaries missing on disk:    {len(missing_secondaries)}")
    by_cat: Counter[str] = Counter()
    for n in missing_secondaries:
        by_cat[n.split("_", 1)[0]] += 1
    for cat, count in sorted(by_cat.items()):
        print(f"   - {cat}: {count}")

    print()
    print(f"[INFO] Stranded files on disk:         {len(stranded)}")
    for n in stranded:
        print(f"   - {n}")

    print()
    print(f"[WARN] Suffix mismatches:              {len(suffix_violations)}")
    for disk, expected in suffix_violations:
        print(f"   - on disk: {disk}")
        print(f"     expected secondary: {expected}")

    return 1 if missing_primaries or suffix_violations else 0


if __name__ == "__main__":
    sys.exit(main())
