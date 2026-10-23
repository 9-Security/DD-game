#!/usr/bin/env python3
"""Subset a font to the characters the project actually displays.

The web build cannot rely on system fonts, so the game ships an embedded
Traditional Chinese font. Shipping the full font is several megabytes, so this
script keeps only the glyphs used by the project's text sources.

Re-run this script whenever new in-game text introduces characters that the
current subset does not contain. Characters outside the subset render as boxes.

Usage:
    python3 tools/asset-pipeline/subset_font.py \
        --source /path/to/NotoSansTC_400Regular.ttf \
        --output assets/fonts/NotoSansTC-Subset.ttf

Requires: fonttools (pip install fonttools brotli)
"""

import argparse
import os
import sys

from fontTools import subset
from fontTools.ttLib import TTFont

# File types that contain player-visible text.
TEXT_EXTENSIONS = (".gd", ".tscn", ".json")

# Directories scanned for player-visible text, relative to the project root.
SCAN_ROOTS = ("src", "assets/data")

# Printable ASCII is always included so numbers and Latin labels render.
ASCII_RANGE = range(0x20, 0x7F)


def project_root() -> str:
    """Returns the repository root (two levels above this script)."""
    return os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))


def collect_characters(root: str) -> set:
    """Collects every non-ASCII character found in the scanned text files."""
    characters = set()
    for scan_root in SCAN_ROOTS:
        base = os.path.join(root, scan_root)
        if not os.path.isdir(base):
            print(f"warning: scan root not found, skipped: {base}", file=sys.stderr)
            continue
        for dirpath, _, filenames in os.walk(base):
            for filename in filenames:
                if not filename.endswith(TEXT_EXTENSIONS):
                    continue
                path = os.path.join(dirpath, filename)
                with open(path, encoding="utf-8") as handle:
                    characters.update(ch for ch in handle.read() if ord(ch) > 0x7F)
    return characters


def build_subset(source: str, output: str, characters: set) -> None:
    """Writes a subset of the source font containing only the given characters."""
    options = subset.Options()
    options.layout_features = ["*"]
    options.name_IDs = ["*"]
    options.name_languages = ["*"]
    options.notdef_outline = True

    font = TTFont(source)
    subsetter = subset.Subsetter(options=options)
    codepoints = set(ASCII_RANGE) | {ord(ch) for ch in characters}
    subsetter.populate(unicodes=codepoints)
    subsetter.subset(font)

    os.makedirs(os.path.dirname(output), exist_ok=True)
    font.flavor = None
    font.save(output)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[1])
    parser.add_argument("--source", required=True, help="Path to the full TTF/OTF font")
    parser.add_argument("--output", required=True, help="Path to write the subset font")
    args = parser.parse_args()

    root = project_root()
    characters = collect_characters(root)
    if not characters:
        print("error: no non-ASCII characters found; refusing to write an empty subset", file=sys.stderr)
        return 1

    build_subset(args.source, os.path.join(root, args.output), characters)
    print(f"subset written: {args.output} ({len(characters)} non-ASCII characters)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
