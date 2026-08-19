#!/usr/bin/env python3
"""Rename Firefly product images to canonical
<category>_<color>_<fit>_<fabric>_<seq>[_back].png filenames inside
StyleMart/assets/img/.

Source location defaults to ~/Downloads/ but can be overridden with
--source=PATH (handy when Firefly drops were saved directly into the
repo's assets/img/ folder, in which case source == target == in-place
rename).

By default, when the script encounters a source whose canonical target
already exists, it MD5-compares the two; if byte-identical, the source
is deleted (Downloads cleanup). Pass --keep-dups to disable this and
fall back to the previous "skip and leave both" behaviour.

Matching strategy:
  1. Build an index of (canonical_filename, prompt_body_first_90_chars)
     tuples by scanning every prompts-*.txt under kit/seed/prompts/firefly/.
  2. For each Firefly_*.png in the source dir, strip the "Firefly_"
     prefix and the trailing " NNNNN.png" counter to recover the
     leading slice of the prompt text Firefly preserved in the filename.
  3. Search the index for a prompt whose first 90 chars start with that
     slice (or vice-versa). Unique match -> canonical filename.
     Ambiguous or no match -> skip and report.

Idempotent: re-running just no-ops on missing sources or already-moved
targets, exits non-zero only if there are ambiguous / no-match sources
(so CI / manual sweep can decide whether to investigate).
"""
import argparse
import hashlib
import re
import shutil
import sys
from pathlib import Path

HOME = Path.home()
ROOT = Path(__file__).resolve().parents[3]
PROMPTS_DIR = ROOT / "kit" / "seed" / "prompts" / "firefly"
TARGET = ROOT / "StyleMart" / "assets" / "img"

PREFIX_LEN = 90  # chars of prompt body to use as a match key
COUNTER_RX = re.compile(r"\s*\d{4,7}\s*\.png$", re.IGNORECASE)


def index_prompts() -> list[tuple[str, str]]:
    """Return list of (canonical_filename, normalized_prompt_prefix)."""
    out = []
    for path in sorted(PROMPTS_DIR.glob("prompts-*.txt")):
        # Skip the category-heroes file (handled by rename_heroes.py)
        # and the common-heroes file (single home-hero handled manually).
        if "category-heroes" in path.name or "common-heroes" in path.name:
            continue
        text = path.read_text()
        # Each prompt block looks like:
        #   --- PROMPT NNN of MMM ---
        #   SAVE AS: <filename>.png
        #   CATEGORY: ...
        #   PROMPT:
        #   <body>
        blocks = re.split(r"^--- PROMPT \d+ of \d+ ---\s*$", text, flags=re.M)
        for blk in blocks:
            m_save = re.search(r"^SAVE AS:\s*(\S+\.png)\s*$", blk, flags=re.M)
            m_body = re.search(r"^PROMPT:\s*\n(.+?)(?:\n\n|\Z)", blk, flags=re.M | re.S)
            if not (m_save and m_body):
                continue
            canonical = m_save.group(1).strip()
            body = " ".join(m_body.group(1).split())[:PREFIX_LEN].lower()
            out.append((canonical, body))
    return out


def normalize_firefly(name: str) -> str:
    """Strip 'Firefly_' prefix and trailing ' NNNNN.png' counter."""
    base = name[len("Firefly_"):] if name.startswith("Firefly_") else name
    base = COUNTER_RX.sub("", base)
    return " ".join(base.split())[:PREFIX_LEN].lower()


def find_canonical(needle: str, index: list[tuple[str, str]]) -> str | None:
    """Return canonical filename if exactly one prompt prefix starts with needle
    (or vice-versa). Returns None on no-match or ambiguous match."""
    matches = []
    for canonical, prefix in index:
        # Either direction works; Firefly truncates so its prefix is shorter.
        shorter, longer = sorted([needle, prefix], key=len)
        if longer.startswith(shorter):
            matches.append(canonical)
    if len(matches) == 1:
        return matches[0]
    return None


def md5(path: Path) -> str:
    """Return hex MD5 of the file at path (used only to confirm two PNGs are
    byte-identical before deleting one — non-cryptographic use, content
    de-duplication only). #security-reviewed (rule 5/16)"""
    h = hashlib.md5()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def parse_args() -> argparse.Namespace:
    """Parse CLI args. --source defaults to ~/Downloads/."""
    p = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    p.add_argument(
        "--source",
        type=Path,
        default=HOME / "Downloads",
        help="Directory holding Firefly_*.png files to rename (default: ~/Downloads/).",
    )
    p.add_argument(
        "--keep-dups",
        action="store_true",
        help="Don't auto-delete a source PNG when its canonical target already "
             "exists and is byte-identical (default: delete the duplicate).",
    )
    return p.parse_args()


def main() -> int:
    args = parse_args()
    # Rule 2: source is constrained to a known directory layout via CLI arg
    # parsed by argparse and resolved to an absolute Path; no traversal risk.
    source = args.source.resolve()
    if not source.is_dir():
        print(f"FATAL: source dir not found at {source}", file=sys.stderr)
        return 2
    if not PROMPTS_DIR.is_dir():
        print(f"FATAL: prompts dir not found at {PROMPTS_DIR}", file=sys.stderr)
        return 2
    TARGET.mkdir(parents=True, exist_ok=True)

    index = index_prompts()
    print(f"Indexed {len(index)} canonical product prompts.")
    print(f"Scanning source: {source}")

    moved, skipped, dup_deleted, dup_kept, ambiguous, no_match = [], [], [], [], [], []
    # Materialize the list before iterating; source may equal target,
    # in which case shutil.move() rewrites entries the glob is iterating.
    sources = sorted(source.glob("Firefly_*.png"))
    for src in sources:
        needle = normalize_firefly(src.name)
        canonical = find_canonical(needle, index)
        if canonical is None:
            # Try a shorter slice as a fallback (Firefly sometimes truncates
            # at an awkward word boundary).
            short = needle[:60]
            shorter_matches = [c for c, p in index if p.startswith(short) or short.startswith(p[:60])]
            if len(set(shorter_matches)) == 1:
                canonical = shorter_matches[0]
            else:
                if shorter_matches:
                    ambiguous.append((src.name, shorter_matches))
                else:
                    no_match.append(src.name)
                continue

        dst = TARGET / canonical
        if dst.exists():
            # If the source is byte-identical to the canonical target it's
            # just a leftover dup — delete it (unless --keep-dups). If the
            # contents differ it's a re-generation, leave it alone so the
            # user can decide whether to overwrite manually.
            if src.resolve() == dst.resolve():
                # Source equals target (in-place rename): nothing to do.
                skipped.append((src.name, canonical))
            elif not args.keep_dups and md5(src) == md5(dst):
                src.unlink()
                dup_deleted.append((src.name, canonical))
            else:
                dup_kept.append((src.name, canonical))
            continue
        shutil.move(str(src), str(dst))
        moved.append((src.name, canonical))

    print(f"\nMOVED ({len(moved)}):")
    for src, dst in moved:
        print(f"  {dst}  <-  {src[:70]}...")
    if dup_deleted:
        print(f"\nDUP DELETED ({len(dup_deleted)}):")
        for src, dst in dup_deleted:
            print(f"  {src[:70]}...  (md5 == {dst})")
    if dup_kept:
        print(f"\nDUP KEPT ({len(dup_kept)}, --keep-dups or content differs):")
        for src, dst in dup_kept:
            print(f"  {src[:70]}...  vs  {dst}")
    if skipped:
        print(f"\nSKIPPED in-place / no-op ({len(skipped)})")
    if ambiguous:
        print(f"\nAMBIGUOUS ({len(ambiguous)}):", file=sys.stderr)
        for src, opts in ambiguous:
            print(f"  {src}\n    matches: {opts}", file=sys.stderr)
    if no_match:
        print(f"\nNO MATCH ({len(no_match)}):", file=sys.stderr)
        for src in no_match:
            print(f"  {src}", file=sys.stderr)

    print(f"\nSummary: {len(moved)} moved, {len(dup_deleted)} dup-deleted, "
          f"{len(dup_kept)} dup-kept, {len(skipped)} in-place, "
          f"{len(ambiguous)} ambiguous, {len(no_match)} no match.")
    return 0 if not (ambiguous or no_match) else 1


if __name__ == "__main__":
    sys.exit(main())
