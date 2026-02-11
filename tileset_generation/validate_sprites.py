#!/usr/bin/env python3
"""
Sprite Quality Gate — Per-Sprite Validation for Art Pipeline
Runs INLINE during sprite processing, BEFORE tileset integration.
Validates individual sprite PNGs and blocks bad sprites from entering the tileset.

Usage:
    # Validate a single sprite
    python validate_sprites.py path/to/sprite.png

    # Validate a batch (directory)
    python validate_sprites.py path/to/sprites/

    # Validate with strict mode (fails on MEDIUM too)
    python validate_sprites.py --strict path/to/sprites/

    # Output JSON report instead of text
    python validate_sprites.py --json path/to/sprites/

    # Importable: use in other pipeline scripts
    from validate_sprites import validate_sprite, validate_batch

Exit codes:
    0 = all sprites pass
    1 = one or more sprites have HIGH severity issues
    2 = --strict mode and MEDIUM+ issues found
"""

import argparse
import colorsys
import json
import sys
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image

# ─── Thresholds (matched to audit_tile_damage.py) ───

# Interior holes: transparent pixel with >= N opaque 8-neighbors
HOLE_NEIGHBOR_MIN = 6
HOLE_HIGH = 50
HOLE_MEDIUM = 15
HOLE_LOW = 5

# Excessive transparency (% of total pixels that are transparent)
TRANSPARENCY_HIGH = 0.85
TRANSPARENCY_MEDIUM = 0.70

# Fragmentation (disconnected opaque regions via 4-connectivity BFS)
FRAGMENT_HIGH = 10
FRAGMENT_MEDIUM = 5

# Magenta contamination (% of opaque pixels in magenta HSV zone)
MAGENTA_HIGH = 0.05
MAGENTA_MEDIUM = 0.02
# HSV zone: hue 280-340 deg (0.778-0.944 normalized), sat > 0.3, val > 0.3
MAGENTA_HUE_MIN = 0.778
MAGENTA_HUE_MAX = 0.944
MAGENTA_SAT_MIN = 0.3
MAGENTA_VAL_MIN = 0.3

# Green contamination (% of opaque pixels in green HSV zone)
GREEN_HIGH = 0.05
GREEN_MEDIUM = 0.02
# HSV zone: hue 80-160 deg (0.222-0.444 normalized), sat > 0.3, val > 0.3
GREEN_HUE_MIN = 0.222
GREEN_HUE_MAX = 0.444
GREEN_SAT_MIN = 0.3
GREEN_VAL_MIN = 0.3

# Edge thinning (bounding box of opaque pixels)
THIN_HIGH = 12
THIN_MEDIUM = 20

# Empty sprite threshold
EMPTY_THRESHOLD = 10

# Expected output dimensions
EXPECTED_SIZE = 64

# Color destruction: if mean saturation of opaque pixels < threshold,
# sprite may have been desaturated by bad color correction
DESATURATION_THRESHOLD = 0.08
# Minimum opaque pixels to run desaturation check (skip near-empty)
DESAT_MIN_OPAQUE = 200


# ─── Check Functions ───

def check_dimensions(img: Image.Image) -> list:
    """Verify sprite is expected dimensions."""
    issues = []
    w, h = img.size
    if w != EXPECTED_SIZE or h != EXPECTED_SIZE:
        sev = "HIGH" if (w > EXPECTED_SIZE * 2 or h > EXPECTED_SIZE * 2) else "MEDIUM"
        issues.append(("Wrong dimensions", sev, f"{w}x{h} (expected {EXPECTED_SIZE}x{EXPECTED_SIZE})"))
    return issues


def check_has_content(alpha: np.ndarray) -> tuple:
    """Check sprite isn't empty. Returns (opaque_count, issues)."""
    opaque_count = int(np.sum(alpha > 0))
    issues = []
    if opaque_count < EMPTY_THRESHOLD:
        issues.append(("Empty sprite", "HIGH", f"{opaque_count} opaque pixels"))
    return opaque_count, issues


def check_interior_holes(alpha: np.ndarray) -> tuple:
    """Count transparent pixels surrounded by opaque pixels."""
    opaque = (alpha > 0).astype(np.int32)
    h, w = opaque.shape
    padded = np.pad(opaque, 1, mode='constant', constant_values=0)

    neighbor_count = np.zeros_like(opaque, dtype=np.int32)
    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            if dy == 0 and dx == 0:
                continue
            neighbor_count += padded[1 + dy:h + 1 + dy, 1 + dx:w + 1 + dx]

    transparent = (alpha == 0)
    holes = int(np.sum(transparent & (neighbor_count >= HOLE_NEIGHBOR_MIN)))

    issues = []
    if holes > HOLE_HIGH:
        issues.append(("Interior holes", "HIGH", f"{holes} holes"))
    elif holes > HOLE_MEDIUM:
        issues.append(("Interior holes", "MEDIUM", f"{holes} holes"))
    elif holes > HOLE_LOW:
        issues.append(("Interior holes", "LOW", f"{holes} holes"))
    return holes, issues


def check_transparency(alpha: np.ndarray, opaque_count: int) -> tuple:
    """Check for excessive transparency (over-aggressive BG removal)."""
    total = alpha.shape[0] * alpha.shape[1]
    transparency = 1.0 - (opaque_count / total)
    pct = round(transparency * 100, 1)

    issues = []
    if transparency > TRANSPARENCY_HIGH:
        issues.append(("Excessive transparency", "HIGH", f"{pct}%"))
    elif transparency > TRANSPARENCY_MEDIUM:
        issues.append(("Excessive transparency", "MEDIUM", f"{pct}%"))
    return pct, issues


def check_fragments(alpha: np.ndarray) -> tuple:
    """Count disconnected opaque regions (4-connectivity BFS)."""
    opaque = (alpha > 0)
    h, w = opaque.shape
    visited = np.zeros_like(opaque, dtype=bool)
    count = 0

    for y in range(h):
        for x in range(w):
            if opaque[y, x] and not visited[y, x]:
                count += 1
                queue = deque()
                queue.append((y, x))
                visited[y, x] = True
                while queue:
                    cy, cx = queue.popleft()
                    for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1)):
                        ny, nx = cy + dy, cx + dx
                        if 0 <= ny < h and 0 <= nx < w and opaque[ny, nx] and not visited[ny, nx]:
                            visited[ny, nx] = True
                            queue.append((ny, nx))

    issues = []
    if count > FRAGMENT_HIGH:
        issues.append(("Fragmented sprite", "HIGH", f"{count} regions"))
    elif count > FRAGMENT_MEDIUM:
        issues.append(("Fragmented sprite", "MEDIUM", f"{count} regions"))
    return count, issues


def check_magenta(rgba: np.ndarray, opaque_count: int) -> tuple:
    """Check for residual magenta contamination in opaque pixels using vectorized HSV."""
    if opaque_count == 0:
        return 0.0, []

    # Extract opaque pixels only
    alpha = rgba[:, :, 3]
    mask = alpha > 0
    rgb_opaque = rgba[mask][:, :3].astype(np.float64) / 255.0

    # Vectorized RGB to HSV
    r, g, b = rgb_opaque[:, 0], rgb_opaque[:, 1], rgb_opaque[:, 2]
    maxc = np.maximum(np.maximum(r, g), b)
    minc = np.minimum(np.minimum(r, g), b)
    diff = maxc - minc

    # Value and saturation
    val = maxc
    sat = np.where(maxc > 0, diff / maxc, 0.0)

    # Hue calculation
    hue = np.zeros_like(maxc)
    mask_r = (maxc == r) & (diff > 0)
    mask_g = (maxc == g) & (diff > 0)
    mask_b = (maxc == b) & (diff > 0)
    hue[mask_r] = ((g[mask_r] - b[mask_r]) / diff[mask_r]) % 6.0
    hue[mask_g] = ((b[mask_g] - r[mask_g]) / diff[mask_g]) + 2.0
    hue[mask_b] = ((r[mask_b] - g[mask_b]) / diff[mask_b]) + 4.0
    hue = hue / 6.0  # Normalize to 0-1

    # Magenta zone check
    in_magenta = (
        (hue >= MAGENTA_HUE_MIN) & (hue <= MAGENTA_HUE_MAX) &
        (sat > MAGENTA_SAT_MIN) & (val > MAGENTA_VAL_MIN)
    )
    magenta_count = int(np.sum(in_magenta))
    magenta_pct = round((magenta_count / opaque_count) * 100, 2)

    issues = []
    if magenta_count / opaque_count > MAGENTA_HIGH:
        issues.append(("Magenta contamination", "HIGH", f"{magenta_pct}%"))
    elif magenta_count / opaque_count > MAGENTA_MEDIUM:
        issues.append(("Magenta contamination", "MEDIUM", f"{magenta_pct}%"))
    return magenta_pct, issues


def check_green(rgba: np.ndarray, opaque_count: int) -> tuple:
    """Check for residual green contamination in opaque pixels using vectorized HSV."""
    if opaque_count == 0:
        return 0.0, []

    alpha = rgba[:, :, 3]
    mask = alpha > 0
    rgb_opaque = rgba[mask][:, :3].astype(np.float64) / 255.0

    r, g, b = rgb_opaque[:, 0], rgb_opaque[:, 1], rgb_opaque[:, 2]
    maxc = np.maximum(np.maximum(r, g), b)
    minc = np.minimum(np.minimum(r, g), b)
    diff = maxc - minc

    val = maxc
    sat = np.where(maxc > 0, diff / maxc, 0.0)

    hue = np.zeros_like(maxc)
    mask_r = (maxc == r) & (diff > 0)
    mask_g = (maxc == g) & (diff > 0)
    mask_b = (maxc == b) & (diff > 0)
    hue[mask_r] = ((g[mask_r] - b[mask_r]) / diff[mask_r]) % 6.0
    hue[mask_g] = ((b[mask_g] - r[mask_g]) / diff[mask_g]) + 2.0
    hue[mask_b] = ((r[mask_b] - g[mask_b]) / diff[mask_b]) + 4.0
    hue = hue / 6.0

    in_green = (
        (hue >= GREEN_HUE_MIN) & (hue <= GREEN_HUE_MAX) &
        (sat > GREEN_SAT_MIN) & (val > GREEN_VAL_MIN)
    )
    green_count = int(np.sum(in_green))
    green_pct = round((green_count / opaque_count) * 100, 2)

    issues = []
    if green_count / opaque_count > GREEN_HIGH:
        issues.append(("Green contamination", "HIGH", f"{green_pct}%"))
    elif green_count / opaque_count > GREEN_MEDIUM:
        issues.append(("Green contamination", "MEDIUM", f"{green_pct}%"))
    return green_pct, issues


def check_bounding_box(alpha: np.ndarray) -> tuple:
    """Check for edge thinning via bounding box of opaque pixels."""
    opaque_coords = np.argwhere(alpha > 0)
    if len(opaque_coords) == 0:
        return 0, 0, []

    min_y, min_x = opaque_coords.min(axis=0)
    max_y, max_x = opaque_coords.max(axis=0)
    bbox_w = int(max_x - min_x + 1)
    bbox_h = int(max_y - min_y + 1)
    min_dim = min(bbox_w, bbox_h)

    issues = []
    if min_dim < THIN_HIGH:
        issues.append(("Edge thinning", "HIGH", f"bbox {bbox_w}x{bbox_h}"))
    elif min_dim < THIN_MEDIUM:
        issues.append(("Edge thinning", "MEDIUM", f"bbox {bbox_w}x{bbox_h}"))
    return bbox_w, bbox_h, issues


def check_desaturation(rgba: np.ndarray, opaque_count: int) -> tuple:
    """
    Detect color destruction from bad color correction.
    If mean saturation of opaque pixels is very low, the sprite was likely
    desaturated by a broken pipeline pass.
    """
    if opaque_count < DESAT_MIN_OPAQUE:
        return -1.0, []

    alpha = rgba[:, :, 3]
    mask = alpha > 0
    rgb_opaque = rgba[mask][:, :3].astype(np.float64) / 255.0

    r, g, b = rgb_opaque[:, 0], rgb_opaque[:, 1], rgb_opaque[:, 2]
    maxc = np.maximum(np.maximum(r, g), b)
    minc = np.minimum(np.minimum(r, g), b)
    sat = np.where(maxc > 0, (maxc - minc) / maxc, 0.0)

    mean_sat = float(np.mean(sat))

    issues = []
    if mean_sat < DESATURATION_THRESHOLD:
        issues.append(("Color destruction", "HIGH",
                        f"mean saturation {mean_sat:.3f} (threshold {DESATURATION_THRESHOLD})"))
    return round(mean_sat, 4), issues


def check_magenta_background(rgba: np.ndarray) -> list:
    """
    Check if the sprite still has a solid magenta background (pre-removal).
    Samples corner pixels — if 3+ corners are magenta, BG removal hasn't run.
    """
    corners = [
        rgba[0, 0], rgba[0, -1],
        rgba[-1, 0], rgba[-1, -1]
    ]
    magenta_corners = 0
    for px in corners:
        r, g, b, a = int(px[0]), int(px[1]), int(px[2]), int(px[3])
        if a > 200 and r > 180 and g < 80 and b > 180:
            magenta_corners += 1

    issues = []
    if magenta_corners >= 3:
        issues.append(("Magenta BG present", "HIGH",
                        f"{magenta_corners}/4 corners are magenta — BG removal not run"))
    return issues


def check_green_background(rgba: np.ndarray) -> list:
    """
    Check if the sprite still has a solid green background (pre-removal).
    Samples corner pixels — if 3+ corners are green, BG removal hasn't run.
    """
    corners = [
        rgba[0, 0], rgba[0, -1],
        rgba[-1, 0], rgba[-1, -1]
    ]
    green_corners = 0
    for px in corners:
        r, g, b, a = int(px[0]), int(px[1]), int(px[2]), int(px[3])
        if a > 200 and g > 180 and r < 80 and b < 80:
            green_corners += 1

    issues = []
    if green_corners >= 3:
        issues.append(("Green BG present", "HIGH",
                        f"{green_corners}/4 corners are green — BG removal not run"))
    return issues


# ─── Main Validator ───

def validate_sprite(path: Path) -> dict:
    """
    Validate a single sprite PNG. Returns a result dict:
    {
        "file": str,
        "status": "PASS" | "WARN" | "FAIL",
        "severity": "HIGH" | "MEDIUM" | "LOW" | None,
        "issues": [(name, severity, detail), ...],
        "metrics": { ... }
    }
    """
    img = Image.open(path).convert("RGBA")
    rgba = np.array(img)
    alpha = rgba[:, :, 3]

    all_issues = []
    metrics = {}

    # 1. Dimensions
    all_issues.extend(check_dimensions(img))
    metrics["dimensions"] = f"{img.size[0]}x{img.size[1]}"

    # 2. Content check
    opaque_count, issues = check_has_content(alpha)
    all_issues.extend(issues)
    metrics["opaque_pixels"] = opaque_count
    if opaque_count < EMPTY_THRESHOLD:
        return {
            "file": str(path),
            "status": "FAIL",
            "severity": "HIGH",
            "issues": all_issues,
            "metrics": metrics,
        }

    # 3. Background still present (pre-removal check)
    all_issues.extend(check_magenta_background(rgba))
    all_issues.extend(check_green_background(rgba))

    # 4. Interior holes
    holes, issues = check_interior_holes(alpha)
    all_issues.extend(issues)
    metrics["interior_holes"] = holes

    # 5. Excessive transparency
    transp_pct, issues = check_transparency(alpha, opaque_count)
    all_issues.extend(issues)
    metrics["transparency_pct"] = transp_pct

    # 6. Fragmentation
    fragments, issues = check_fragments(alpha)
    all_issues.extend(issues)
    metrics["fragments"] = fragments

    # 7. Magenta contamination
    magenta_pct, issues = check_magenta(rgba, opaque_count)
    all_issues.extend(issues)
    metrics["magenta_pct"] = magenta_pct

    # 7b. Green contamination
    green_pct, issues = check_green(rgba, opaque_count)
    all_issues.extend(issues)
    metrics["green_pct"] = green_pct

    # 8. Bounding box / edge thinning
    bbox_w, bbox_h, issues = check_bounding_box(alpha)
    all_issues.extend(issues)
    metrics["bbox"] = f"{bbox_w}x{bbox_h}"

    # 9. Color destruction (desaturation)
    mean_sat, issues = check_desaturation(rgba, opaque_count)
    all_issues.extend(issues)
    if mean_sat >= 0:
        metrics["mean_saturation"] = mean_sat

    # Determine overall result
    severities = [sev for _, sev, _ in all_issues]
    if "HIGH" in severities:
        status = "FAIL"
        severity = "HIGH"
    elif "MEDIUM" in severities:
        status = "WARN"
        severity = "MEDIUM"
    elif "LOW" in severities:
        status = "PASS"
        severity = "LOW"
    else:
        status = "PASS"
        severity = None

    return {
        "file": str(path),
        "status": status,
        "severity": severity,
        "issues": all_issues,
        "metrics": metrics,
    }


def validate_batch(paths: list, strict: bool = False) -> dict:
    """
    Validate multiple sprite PNGs. Returns a summary dict:
    {
        "total": int,
        "pass": int,
        "warn": int,
        "fail": int,
        "results": [result, ...],
        "exit_code": 0 | 1 | 2
    }
    """
    results = []
    for p in sorted(paths):
        try:
            result = validate_sprite(p)
            results.append(result)
        except Exception as e:
            results.append({
                "file": str(p),
                "status": "FAIL",
                "severity": "HIGH",
                "issues": [("File error", "HIGH", str(e))],
                "metrics": {},
            })

    pass_count = sum(1 for r in results if r["status"] == "PASS")
    warn_count = sum(1 for r in results if r["status"] == "WARN")
    fail_count = sum(1 for r in results if r["status"] == "FAIL")

    if fail_count > 0:
        exit_code = 1
    elif strict and warn_count > 0:
        exit_code = 2
    else:
        exit_code = 0

    return {
        "total": len(results),
        "pass": pass_count,
        "warn": warn_count,
        "fail": fail_count,
        "results": results,
        "exit_code": exit_code,
    }


# ─── CLI ───

def print_result(result: dict) -> None:
    """Pretty-print a single sprite result."""
    icon = {"PASS": "OK", "WARN": "!!", "FAIL": "XX"}[result["status"]]
    name = Path(result["file"]).name
    print(f"  [{icon}] {name}", end="")

    if result["issues"]:
        issue_strs = [f"{n}[{s}]:{d}" for n, s, d in result["issues"]]
        print(f"  — {', '.join(issue_strs)}")
    else:
        print()


def main():
    parser = argparse.ArgumentParser(description="Sprite Quality Gate")
    parser.add_argument("path", help="Sprite PNG file or directory of PNGs")
    parser.add_argument("--strict", action="store_true",
                        help="Fail on MEDIUM severity too (exit code 2)")
    parser.add_argument("--json", action="store_true",
                        help="Output JSON report instead of text")
    parser.add_argument("--quiet", action="store_true",
                        help="Only show failures (suppress PASS)")
    args = parser.parse_args()

    target = Path(args.path)
    if target.is_file():
        paths = [target]
    elif target.is_dir():
        paths = list(target.glob("*.png"))
        if not paths:
            print(f"No .png files found in {target}")
            sys.exit(1)
    else:
        print(f"Path not found: {target}")
        sys.exit(1)

    summary = validate_batch(paths, strict=args.strict)

    if args.json:
        # Convert tuples to dicts for JSON
        for r in summary["results"]:
            r["issues"] = [{"name": n, "severity": s, "detail": d} for n, s, d in r["issues"]]
        print(json.dumps(summary, indent=2))
    else:
        print(f"\nSprite Quality Gate — {summary['total']} sprites")
        print("=" * 60)

        for r in summary["results"]:
            if args.quiet and r["status"] == "PASS" and not r["issues"]:
                continue
            print_result(r)

        print("=" * 60)
        print(f"PASS: {summary['pass']}  WARN: {summary['warn']}  FAIL: {summary['fail']}")

        if summary["exit_code"] == 0:
            print("Result: ALL CLEAR — safe to integrate into tileset")
        elif summary["exit_code"] == 2:
            print("Result: BLOCKED (strict mode) — fix MEDIUM+ issues before integration")
        else:
            print("Result: BLOCKED — fix HIGH severity issues before integration")

    sys.exit(summary["exit_code"])


if __name__ == "__main__":
    main()
