#!/usr/bin/env python3
"""Strip rogue 2nd-color variants so each product is single-color.

Problem
-------
The seed contains 200 products, each named after a single color (matching
`product_images.color_ref`). A historical seed bug bolted a synthetic 2nd
color onto 46 products' `product_variants` (e.g. "Cream Crew Neck Tshirts"
got both cream and navy variants), with no matching navy images.

This script applies "Path 3":
  * Identify each product's TRUE color (the single value in product_images).
  * Drop every variant row whose color != TRUE color (rogue rows).
  * Drop every inventory row referencing a deleted variant_id.
  * Re-derive products[].colors[] in the JSON fixtures.

Run from CFSummit2026Workshop root:
    python kit/seed/scripts/strip_rogue_colors.py [--dry-run]
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
SQL_VARIANTS = ROOT / "StyleMart/db/mysql/seed/05_seed_product_variants.sql"
SQL_INVENTORY = ROOT / "StyleMart/db/mysql/seed/07_seed_inventory.sql"
SQL_IMAGES = ROOT / "StyleMart/db/mysql/seed/06_seed_product_images.sql"
JSON_FIXTURES = [
    ROOT / "kit/seed/json/products.json",
    ROOT / "StyleMart/assets/js/mock/fixtures/products.json",
]


def basename(url: str) -> str:
    return url.replace("\\", "/").rsplit("/", 1)[-1] if url else ""


def true_color_per_product() -> dict[str, str]:
    """Parse 06_seed_product_images.sql and return product_id -> true color.

    The TRUE color is the single distinct color_ref that appears in
    product_images for that product. If a product has 0 or >1 colors in
    images, it's flagged (should not happen for our 200-product set).
    """
    txt = SQL_IMAGES.read_text()
    rows = re.findall(
        r"\(\s*'[^']+',\s*'(prd_[A-Za-z0-9]+)',\s*'[^']*',\s*'[^']*',\s*\d+,\s*'([^']+)'\s*\)",
        txt,
    )
    by_product: dict[str, set[str]] = defaultdict(set)
    for pid, color in rows:
        by_product[pid].add(color)
    out: dict[str, str] = {}
    for pid, colors in by_product.items():
        if len(colors) != 1:
            print(f"!! product {pid} has {len(colors)} colors in images: {colors}", file=sys.stderr)
            continue
        out[pid] = next(iter(colors))
    return out


def rogue_variant_ids(true_colors: dict[str, str]) -> set[str]:
    """Parse 05_seed_product_variants.sql and return rogue variant_ids."""
    txt = SQL_VARIANTS.read_text()
    rows = re.findall(
        r"\(\s*'(var_[A-Za-z0-9_]+)',\s*'(prd_[A-Za-z0-9]+)',\s*'[^']+',\s*'([^']+)',\s*'[^']+'\s*\)",
        txt,
    )
    rogues: set[str] = set()
    for variant_id, product_id, color in rows:
        true_c = true_colors.get(product_id)
        if true_c is None:
            continue
        if color != true_c:
            rogues.add(variant_id)
    return rogues


def strip_sql_rows(path: Path, ids_to_drop: set[str], id_pattern: re.Pattern) -> tuple[int, int]:
    """Remove rows from a multi-row INSERT VALUES statement.

    Each VALUES row is a single line ending in ',' or ';'. We:
      * Drop lines whose first quoted ID is in `ids_to_drop`.
      * Ensure the LAST kept row ends in ';' (not ',').
    Returns (removed, kept).
    """
    src = path.read_text()
    lines = src.splitlines(keepends=True)
    out: list[str] = []
    kept_value_lines: list[int] = []
    removed = 0
    for i, line in enumerate(lines):
        m = id_pattern.match(line)
        if m and m.group(1) in ids_to_drop:
            removed += 1
            continue
        out.append(line)
        if id_pattern.match(line):
            kept_value_lines.append(len(out) - 1)

    # Fix terminator on the very last value row: it must end with ';\n'.
    if kept_value_lines:
        last_idx = kept_value_lines[-1]
        line = out[last_idx]
        # Strip any trailing whitespace and the final ',' or ';' if present.
        rstripped = line.rstrip("\r\n")
        if rstripped.endswith(","):
            rstripped = rstripped[:-1] + ";"
        elif not rstripped.endswith(";"):
            rstripped = rstripped + ";"
        out[last_idx] = rstripped + "\n"

        # Any prior value rows must end with ',' (not ';').
        for j in kept_value_lines[:-1]:
            line = out[j]
            rstripped = line.rstrip("\r\n")
            if rstripped.endswith(";"):
                rstripped = rstripped[:-1] + ","
            elif not rstripped.endswith(","):
                rstripped = rstripped + ","
            out[j] = rstripped + "\n"

    path.write_text("".join(out))
    return removed, len(kept_value_lines)


def fix_json_fixture(path: Path, true_colors: dict[str, str]) -> tuple[int, int]:
    """Filter products[].variants[] to keep only true-color rows;
    re-derive products[].colors[]. Returns (variants_removed, products_touched)."""
    data = json.loads(path.read_text())
    plist = data["products"] if isinstance(data, dict) and "products" in data else data
    removed = 0
    touched = 0
    for prod in plist:
        pid = prod.get("productId") or prod.get("id")
        true_c = true_colors.get(pid)
        if not true_c:
            continue
        before = prod.get("variants") or []
        after = [v for v in before if v.get("color") == true_c]
        if len(after) != len(before):
            touched += 1
            removed += len(before) - len(after)
            prod["variants"] = after
        prod["colors"] = [true_c]
    if isinstance(data, dict) and "products" in data:
        data["products"] = plist
    path.write_text(json.dumps(data, indent=2) + "\n")
    return removed, touched


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--dry-run", action="store_true")
    args = p.parse_args()

    true_colors = true_color_per_product()
    print(f"Resolved true color for {len(true_colors)} products.")

    rogues = rogue_variant_ids(true_colors)
    print(f"Identified {len(rogues)} rogue variant_ids to drop.")
    if not rogues:
        print("Nothing to do.")
        return 0

    if args.dry_run:
        print("(dry-run) skipping writes")
        for v in sorted(rogues)[:10]:
            print(f"   {v}")
        return 0

    var_pattern = re.compile(r"^\s*\(\s*'(var_[A-Za-z0-9_]+)'")
    inv_pattern = re.compile(r"^\s*\(\s*'(var_[A-Za-z0-9_]+)'")

    rem_v, kept_v = strip_sql_rows(SQL_VARIANTS, rogues, var_pattern)
    print(f"05_seed_product_variants.sql:  -{rem_v} rows  (kept {kept_v})")

    rem_i, kept_i = strip_sql_rows(SQL_INVENTORY, rogues, inv_pattern)
    print(f"07_seed_inventory.sql:        -{rem_i} rows  (kept {kept_i})")

    for path in JSON_FIXTURES:
        rem_j, touched = fix_json_fixture(path, true_colors)
        rel = path.relative_to(ROOT)
        print(f"{rel}:  -{rem_j} variants  ({touched} products touched)")

    return 0


if __name__ == "__main__":
    sys.exit(main())
