#!/usr/bin/env python3
"""Compare matching FPGA and VICE screenshots, allowing a small offset."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from PIL import Image, ImageChops, UnidentifiedImageError


FPGA_PREFIX = "fpga_"
VICE_PREFIX = "vice_"
SCREENSHOT_SUFFIX = ".prg.png"
GREEN = "\033[32m"
RED = "\033[31m"
RESET = "\033[0m"


def overlap_crops(
    fpga: Image.Image, vice: Image.Image, dx: int, dy: int
) -> tuple[Image.Image, Image.Image]:
    """Return equally sized overlap crops for the given FPGA displacement."""
    fpga_left = max(0, dx)
    vice_left = max(0, -dx)
    fpga_top = max(0, dy)
    vice_top = max(0, -dy)

    width = min(fpga.width - fpga_left, vice.width - vice_left)
    height = min(fpga.height - fpga_top, vice.height - vice_top)
    if width <= 0 or height <= 0:
        raise ValueError("offset leaves no overlapping pixels")

    fpga_box = (fpga_left, fpga_top, fpga_left + width, fpga_top + height)
    vice_box = (vice_left, vice_top, vice_left + width, vice_top + height)
    return fpga.crop(fpga_box), vice.crop(vice_box)


def matching_pixels(first: Image.Image, second: Image.Image) -> int:
    """Count pixels whose complete RGBA values are identical."""
    difference = ImageChops.difference(first, second)
    bands = difference.split()
    changed = bands[0]
    for band in bands[1:]:
        changed = ImageChops.lighter(changed, band)
    return changed.histogram()[0]


def compare_pair(
    fpga_path: Path, vice_path: Path, max_offset: int
) -> tuple[float, int, int, int, int]:
    """Return the best likeness, offset, match count, and overlap size."""
    with Image.open(fpga_path) as source:
        fpga = source.convert("RGBA")
    with Image.open(vice_path) as source:
        vice = source.convert("RGBA")

    if fpga.size != vice.size:
        raise ValueError(
            f"image dimensions differ ({fpga.width}x{fpga.height} versus "
            f"{vice.width}x{vice.height})"
        )

    best: tuple[float, int, int, int, int] | None = None
    for dy in range(-max_offset, max_offset + 1):
        for dx in range(-max_offset, max_offset + 1):
            fpga_crop, vice_crop = overlap_crops(fpga, vice, dx, dy)
            total = fpga_crop.width * fpga_crop.height
            matches = matching_pixels(fpga_crop, vice_crop)
            likeness = 100.0 * matches / total
            candidate = (likeness, dx, dy, matches, total)

            # On equal scores, prefer the smallest adjustment and then a
            # stable top-to-bottom, left-to-right ordering.
            if best is None or likeness > best[0] or (
                likeness == best[0]
                and (abs(dx) + abs(dy), abs(dy), abs(dx), dy, dx)
                < (
                    abs(best[1]) + abs(best[2]),
                    abs(best[2]),
                    abs(best[1]),
                    best[2],
                    best[1],
                )
            ):
                best = candidate

    assert best is not None
    return best

def removeprefix(s, prefix):
    if s.startswith(prefix):
        return s[len(prefix):]
    return s

def counterpart(path: Path, old_prefix: str, new_prefix: str) -> Path:
    return path.with_name(new_prefix + removeprefix(path.name, old_prefix))


def select_program(
    paths: list[Path], root: Path, prefix: str, prg: Path
) -> list[Path]:
    """Keep only the screenshots belonging to the given program file."""
    name = prg.name
    if name.endswith(".png"):
        name = name[: -len(".png")]
    wanted = f"{prefix}{name}.png"

    # A bare filename can live in any subdirectory; a qualified path (for
    # example simple/simple.prg) restricts the search to that location.
    if prg.parent == Path("."):
        return [path for path in paths if path.name == wanted]
    expected = prg.parent / wanted
    if prg.is_absolute():
        return [path for path in paths if path.resolve() == expected.resolve()]
    return [path for path in paths if path.relative_to(root) == expected]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Recursively compare fpga_*.prg.png screenshots with their "
            "vice_*.prg.png counterparts."
        )
    )
    parser.add_argument(
        "root",
        nargs="?",
        type=Path,
        default=Path(__file__).resolve().parent,
        help="directory to search (default: directory containing this program)",
    )
    parser.add_argument(
        "--prg",
        type=Path,
        metavar="FILE",
        help=(
            "only compare the screenshots for this program file, for example "
            "simple.prg (default: compare every program)"
        ),
    )
    parser.add_argument(
        "--max-offset",
        type=int,
        default=4,
        metavar="PIXELS",
        help="maximum horizontal and vertical offset to try (default: 4)",
    )
    args = parser.parse_args()
    if args.max_offset < 0:
        parser.error("--max-offset cannot be negative")
    return args


def main() -> int:
    args = parse_args()
    root = args.root.resolve()
    if not root.is_dir():
        print(f"error: not a directory: {root}", file=sys.stderr)
        return 2

    fpga_paths = sorted(root.rglob(f"{FPGA_PREFIX}*{SCREENSHOT_SUFFIX}"))
    vice_paths = sorted(root.rglob(f"{VICE_PREFIX}*{SCREENSHOT_SUFFIX}"))
    if args.prg is not None:
        fpga_paths = select_program(fpga_paths, root, FPGA_PREFIX, args.prg)
        vice_paths = select_program(vice_paths, root, VICE_PREFIX, args.prg)
    vice_set = set(vice_paths)
    paired_vice: set[Path] = set()
    errors = 0

    for fpga_path in fpga_paths:
        vice_path = counterpart(fpga_path, FPGA_PREFIX, VICE_PREFIX)
        relative_fpga = fpga_path.relative_to(root)
        relative_vice = vice_path.relative_to(root)
        if vice_path not in vice_set:
            print(f"MISSING: {relative_fpga} has no {relative_vice}", file=sys.stderr)
            errors += 1
            continue

        paired_vice.add(vice_path)
        try:
            likeness, _, _, _, _ = compare_pair(
                fpga_path, vice_path, args.max_offset
            )
        except (OSError, UnidentifiedImageError, ValueError) as error:
            print(
                f"ERROR: {relative_fpga} <-> {relative_vice}: {error}",
                file=sys.stderr,
            )
            errors += 1
            continue

        filename = removeprefix(relative_fpga.name,FPGA_PREFIX)
        color = GREEN if likeness == 100.0 else RED
        print(f"{filename} {color}{likeness:.6f}%{RESET}")

    for vice_path in vice_paths:
        if vice_path not in paired_vice:
            fpga_path = counterpart(vice_path, VICE_PREFIX, FPGA_PREFIX)
            print(
                f"MISSING: {vice_path.relative_to(root)} has no "
                f"{fpga_path.relative_to(root)}",
                file=sys.stderr,
            )
            errors += 1

    if not fpga_paths and not vice_paths:
        if args.prg is not None:
            print(
                f"error: no screenshots found for {args.prg} beneath {root}",
                file=sys.stderr,
            )
        else:
            print(f"error: no screenshots found beneath {root}", file=sys.stderr)
        return 1
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
