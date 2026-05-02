#!/usr/bin/env python3
"""
generate.py
───────────
Template-based PPTX + Markdown generator.

Usage
─────
  python generate.py content/my-presentation.yaml
  python generate.py content/my-presentation.yaml --theme dark
  python generate.py content/my-presentation.yaml --out ./output --no-md

The YAML file drives everything: meta, theme, slide list.
Outputs are written to --out (default: ./output next to this script).

Supported slide types
─────────────────────
  title             Cover slide with pills + sidebar
  agenda            Two-column agenda
  section_intro     Section divider with label pill + learn bullets
  two_column        Left/right problem-solution or comparison panels
  bullets           Header + multi-paragraph bullet content
  pain_cards        Three pain cards with solutions row
  comparison_table  Row/column comparison grid
  stats_banner      Metrics banner + before/after story
  key_takeaways     Numbered takeaway points
  closing           Thank-you / contact slide
"""

import argparse
import os
import sys

import yaml
from pptx import Presentation
from pptx.util import Inches

# Allow running from any working directory
sys.path.insert(0, os.path.dirname(__file__))

from builder.theme  import get_theme
from builder.slides import render_slide
from builder.md_builder import build_markdown


# ── Defaults ──────────────────────────────────────────────────────────────────

DEFAULT_OUT = os.path.join(os.path.dirname(__file__), "output")


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Generate a PPTX and Markdown file from a YAML content definition."
    )
    parser.add_argument("content",
                        help="Path to the YAML content file")
    parser.add_argument("--theme",
                        choices=["light", "dark"],
                        default=None,
                        help="Override the theme (default: value from YAML meta, else 'light')")
    parser.add_argument("--out",
                        default=None,
                        help=f"Output directory (default: {DEFAULT_OUT})")
    parser.add_argument("--no-md",
                        action="store_true",
                        help="Skip generating the Markdown file")
    parser.add_argument("--no-pptx",
                        action="store_true",
                        help="Skip generating the PPTX file")
    args = parser.parse_args()

    # ── Load YAML ──────────────────────────────────────────────────────────────
    content_path = os.path.abspath(args.content)
    if not os.path.isfile(content_path):
        sys.exit(f"ERROR: content file not found: {content_path}")

    with open(content_path, encoding="utf-8") as f:
        doc = yaml.safe_load(f)

    meta   = doc.get("meta", {})
    slides = doc.get("slides", [])

    if not slides:
        sys.exit("ERROR: no slides defined in YAML file.")

    # ── Resolve theme ──────────────────────────────────────────────────────────
    theme_name = args.theme or meta.get("theme", "light")
    T = get_theme(theme_name)

    # ── Resolve output directory & file stem ──────────────────────────────────
    out_dir = os.path.abspath(args.out or DEFAULT_OUT)
    os.makedirs(out_dir, exist_ok=True)

    stem = meta.get("output", os.path.splitext(os.path.basename(content_path))[0])

    pptx_path = os.path.join(out_dir, f"{stem}.pptx")
    md_path   = os.path.join(out_dir, f"{stem}.md")

    # ── Build PPTX ─────────────────────────────────────────────────────────────
    if not args.no_pptx:
        prs = Presentation()
        prs.slide_width  = Inches(13.33)
        prs.slide_height = Inches(7.50)

        for i, slide_cfg in enumerate(slides, 1):
            try:
                render_slide(prs, T, slide_cfg, meta)
            except Exception as exc:
                print(f"  WARNING: slide {i} (type={slide_cfg.get('type','?')}) failed: {exc}")

        prs.save(pptx_path)
        print(f"  PPTX → {pptx_path}")

    # ── Build Markdown ─────────────────────────────────────────────────────────
    if not args.no_md:
        md_content = build_markdown(meta, slides)
        with open(md_path, "w", encoding="utf-8") as f:
            f.write(md_content)
        print(f"  MD   → {md_path}")

    print("Done.")


if __name__ == "__main__":
    main()
