#!/usr/bin/env python3
"""Turn flat white backgrounds on character art into real transparency.

Naive "every white pixel becomes transparent" eats the whites *inside* the
sprite too (eyes, teeth, shirt highlights). So the background is found by
flood-filling inward from the image border and keeping only the white region
that is connected to the edge; enclosed whites survive untouched.

Anti-aliased outlines are a blend of sprite colour and white. Those get a
partial alpha plus an un-blend of the white they picked up, which is what
kills the pale halo you would otherwise see against a dark scene.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

IMAGE_SUFFIXES = {".png", ".jpg", ".jpeg", ".webp", ".bmp"}


def find_targets(roots: list[Path], prefix: str) -> list[Path]:
    """Every image whose *file name* starts with `prefix`, case-insensitively."""
    found: set[Path] = set()
    for root in roots:
        if root.is_file():
            if root.suffix.lower() in IMAGE_SUFFIXES and root.stem.lower().startswith(prefix):
                found.add(root)
            continue
        for path in root.rglob("*"):
            if not path.is_file() or path.suffix.lower() not in IMAGE_SUFFIXES:
                continue
            if path.stem.lower().startswith(prefix):
                found.add(path)
    return sorted(found)


def background_mask(
    rgb: np.ndarray,
    white_at: int,
    already_clear: np.ndarray | None = None,
) -> np.ndarray:
    """White pixels reachable from the border, 4-connected."""
    near_white = rgb.min(axis=2) >= white_at
    if already_clear is not None:
        # Pixels that are already transparent are background too. Including them
        # keeps the flood fill connected on art that was partly cut before.
        near_white |= already_clear
    labels, count = ndimage.label(near_white)
    if count == 0:
        return np.zeros(near_white.shape, dtype=bool)
    edge = np.concatenate([labels[0], labels[-1], labels[:, 0], labels[:, -1]])
    border_ids = np.unique(edge[edge > 0])
    return np.isin(labels, border_ids)


def cut_background(
    im: Image.Image,
    white_at: int = 244,
    soft_at: int = 200,
    unblend: bool = True,
) -> tuple[Image.Image, dict]:
    """Return an RGBA copy with the edge-connected white background removed."""
    rgba = np.array(im.convert("RGBA"))
    rgb = rgba[:, :, :3].astype(np.int16)
    alpha = rgba[:, :, 3].astype(np.float32)

    already_clear = alpha < 8
    solid_bg = background_mask(rgb, white_at, already_clear)

    # Anti-aliased rim: bright-but-not-white pixels touching the background.
    grown = ndimage.binary_dilation(solid_bg, iterations=2)
    brightness = rgb.min(axis=2)
    rim = grown & ~solid_bg & ~already_clear & (brightness >= soft_at)

    new_alpha = alpha.copy()
    new_alpha[solid_bg] = 0.0

    if rim.any():
        # brightness soft_at -> keep fully, white_at -> drop fully.
        span = max(white_at - soft_at, 1)
        keep = 1.0 - (brightness[rim].astype(np.float32) - soft_at) / span
        keep = np.clip(keep, 0.0, 1.0)
        new_alpha[rim] = alpha[rim] * keep

        if unblend:
            # observed = sprite*a + white*(1-a)  ->  sprite = (observed - 255*(1-a)) / a
            a = np.clip(keep, 0.15, 1.0)[:, None]
            src = rgb[rim].astype(np.float32)
            rgb[rim] = np.clip((src - 255.0 * (1.0 - a)) / a, 0, 255).astype(np.int16)

    out_alpha = np.clip(new_alpha, 0, 255).astype(np.uint8)
    out = np.dstack([rgb.astype(np.uint8), out_alpha])
    # Only count pixels that actually became more transparent. White RGB sitting
    # under alpha=0 is not work to be done, so already-cut art reports 0 here and
    # --check stays quiet instead of committing on every run.
    stats = {
        "cleared": int(((out_alpha < rgba[:, :, 3]) & ~already_clear).sum()),
        "softened": int(rim.sum()),
        "pixels": int(solid_bg.size),
    }
    return Image.fromarray(out), stats


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("roots", nargs="*", default=["."], type=Path)
    ap.add_argument("--prefix", default="character")
    ap.add_argument("--white-at", type=int, default=244)
    ap.add_argument("--soft-at", type=int, default=200)
    ap.add_argument("--no-unblend", action="store_true")
    ap.add_argument("--min-cleared", type=float, default=0.02,
                    help="skip files where less than this fraction was background")
    ap.add_argument("--check", action="store_true",
                    help="report what would change, write nothing, exit 1 if work remains")
    args = ap.parse_args(argv)

    targets = find_targets(args.roots or [Path(".")], args.prefix.lower())
    if not targets:
        print(f"no images with basename starting with {args.prefix!r}")
        return 0

    pending = []
    for path in targets:
        try:
            with Image.open(path) as im:
                converted, stats = cut_background(
                    im, args.white_at, args.soft_at, not args.no_unblend
                )
        except Exception as exc:  # noqa: BLE001 - report and keep going
            print(f"!! {path}: {exc}", file=sys.stderr)
            continue

        share = stats["cleared"] / stats["pixels"]
        if share < args.min_cleared:
            print(f"-- {path}: only {share:.1%} edge-white, already transparent, skipped")
            continue

        out_path = path.with_suffix(".png")
        pending.append(path)
        if args.check:
            print(f"?? {path}: would clear {share:.1%} (+{stats['softened']} soft px)")
            continue

        converted.save(out_path)
        if out_path != path:
            path.unlink()
            print(f"OK {path} -> {out_path}: cleared {share:.1%} (+{stats['softened']} soft px)")
        else:
            print(f"OK {path}: cleared {share:.1%} (+{stats['softened']} soft px)")

    if args.check and pending:
        print(f"\n{len(pending)} file(s) still have a white background")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
