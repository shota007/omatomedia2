"""
Stool image color scorer for colitis symptom assessment.

Scores each image on:
  - Brown score: indicates healthy/recovering stool
  - Red score:   indicates bleeding/active inflammation

Usage:
    python3 stool_color_scorer.py <image_dir>
    python3 stool_color_scorer.py ./images
    python3 stool_color_scorer.py image1.jpg image2.jpg ...
"""

import sys
import os
import csv
import cv2
import numpy as np
from pathlib import Path


# ── Color ranges in HSV ───────────────────────────────────────────────────────
# HSV: H in [0,179], S in [0,255], V in [0,255] (OpenCV convention)

# Brown: warm hue (orange-ish), moderate-low saturation, moderate value
BROWN_RANGES = [
    (np.array([5,  40,  30]),  np.array([22, 230, 200])),
]

# Red: wraps around hue=0 in HSV, so we need two ranges
RED_RANGES = [
    (np.array([0,  80, 40]),   np.array([8,  255, 255])),   # lower red
    (np.array([170, 80, 40]),  np.array([179, 255, 255])),  # upper red
]

# Ignore very dark pixels (shadow/background) and very bright pixels (overexposure)
MIN_VALUE = 30
MAX_VALUE = 240
MIN_SATURATION = 30  # ignore near-gray pixels


def build_valid_mask(hsv: np.ndarray) -> np.ndarray:
    """Mask out background-like pixels (very dark, very bright, or near-gray)."""
    v = hsv[:, :, 2]
    s = hsv[:, :, 1]
    return (
        (v >= MIN_VALUE) &
        (v <= MAX_VALUE) &
        (s >= MIN_SATURATION)
    ).astype(np.uint8) * 255


def score_color(hsv: np.ndarray, ranges: list, valid_mask: np.ndarray) -> float:
    """Return fraction of valid pixels matching any of the given HSV ranges."""
    combined = np.zeros(hsv.shape[:2], dtype=np.uint8)
    for lo, hi in ranges:
        combined |= cv2.inRange(hsv, lo, hi)

    combined &= valid_mask

    valid_px = np.count_nonzero(valid_mask)
    if valid_px == 0:
        return 0.0
    matched = np.count_nonzero(combined)
    return round(matched / valid_px * 100, 2)


def analyze_image(path: str) -> dict:
    img_bgr = cv2.imread(path)
    if img_bgr is None:
        return {"file": os.path.basename(path), "error": "Cannot read image"}

    hsv = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2HSV)
    valid_mask = build_valid_mask(hsv)

    brown = score_color(hsv, BROWN_RANGES, valid_mask)
    red   = score_color(hsv, RED_RANGES,   valid_mask)

    # Symptom severity heuristic (0–10)
    # More red → higher severity; more brown → lower severity
    severity = round(min(10, (red * 0.8 - brown * 0.2 + 50) / 10), 1)
    severity = max(0, severity)

    return {
        "file":          os.path.basename(path),
        "brown_score_%": brown,
        "red_score_%":   red,
        "severity_0_10": severity,
        "note": _note(brown, red),
    }


def _note(brown: float, red: float) -> str:
    if red > 20:
        return "High red → possible active bleeding/inflammation"
    if red > 10:
        return "Moderate red → monitor closely"
    if brown > 40:
        return "Predominantly brown → appears more normal"
    if brown > 20:
        return "Moderate brown → mild coloring"
    return "Low brown & red → possible yellow/pale stool or insufficient color data"


def collect_paths(args: list) -> list:
    paths = []
    image_exts = {".jpg", ".jpeg", ".png", ".bmp", ".tiff", ".tif", ".webp"}
    for arg in args:
        p = Path(arg)
        if p.is_dir():
            for f in sorted(p.iterdir()):
                if f.suffix.lower() in image_exts:
                    paths.append(str(f))
        elif p.suffix.lower() in image_exts:
            paths.append(str(p))
    return paths


def main():
    args = sys.argv[1:]
    if not args:
        print(__doc__)
        sys.exit(1)

    paths = collect_paths(args)
    if not paths:
        print("No image files found. Provide a directory or image file paths.")
        sys.exit(1)

    results = [analyze_image(p) for p in paths]

    # ── Print table ───────────────────────────────────────────────────────────
    header = f"{'File':<35} {'Brown%':>8} {'Red%':>7} {'Severity':>9}  Note"
    print("\n" + "=" * 100)
    print(header)
    print("-" * 100)
    for r in results:
        if "error" in r:
            print(f"{r['file']:<35}  ERROR: {r['error']}")
        else:
            print(
                f"{r['file']:<35}"
                f" {r['brown_score_%']:>8}"
                f" {r['red_score_%']:>7}"
                f" {r['severity_0_10']:>9}"
                f"  {r['note']}"
            )
    print("=" * 100)

    # ── Save CSV ──────────────────────────────────────────────────────────────
    out_csv = "stool_scores.csv"
    with open(out_csv, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=["file", "brown_score_%", "red_score_%", "severity_0_10", "note"])
        writer.writeheader()
        for r in results:
            if "error" not in r:
                writer.writerow(r)
    print(f"\nResults saved to {out_csv}\n")


if __name__ == "__main__":
    main()
