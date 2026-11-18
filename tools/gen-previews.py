#!/usr/bin/env python3
"""Generate the theme preview images used in the README.

For every theme the real renderer is executed, the resulting ANSI output is
converted to HTML and finally screenshotted with a headless Chromium.

    python3 tools/gen-previews.py [--out assets/previews]
"""
import argparse
import html
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

BG = "#0b0b12"
FG = "#d8d8e8"


def ansi_to_html(text: str) -> str:
    out = []
    open_spans = 0
    color = None
    bold = False
    dim = False
    i = 0
    while i < len(text):
        ch = text[i]
        if ch == "\x1b" and i + 1 < len(text) and text[i + 1] == "[":
            j = text.find("m", i)
            if j == -1:
                out.append(html.escape(text[i:]))
                break
            params = text[i + 2:j].split(";")
            nums = [int(p) if p.isdigit() else 0 for p in params] or [0]
            k = 0
            while k < len(nums):
                n = nums[k]
                if n == 0:
                    color = None
                    bold = False
                    dim = False
                elif n == 1:
                    bold = True
                elif n == 2:
                    dim = True
                elif n == 22:
                    bold = False
                    dim = False
                elif n == 39:
                    color = None
                elif n == 38 and k + 1 < len(nums):
                    mode = nums[k + 1]
                    if mode == 2 and k + 4 < len(nums):
                        color = "#%02X%02X%02X" % (nums[k + 2], nums[k + 3], nums[k + 4])
                        k += 4
                    elif mode == 5 and k + 2 < len(nums):
                        color = xterm256(nums[k + 2])
                        k += 2
                k += 1
            # rebuild the span for the next chunk
            if open_spans:
                out.append("</span>")
                open_spans = 0
            style = []
            if color:
                style.append("color:%s" % color)
            if bold:
                style.append("font-weight:700")
            if dim:
                style.append("opacity:.62")
            if style:
                out.append('<span style="%s">' % ";".join(style))
                open_spans = 1
            i = j + 1
            continue
        if ch == "\n":
            out.append("\n")
            i += 1
            continue
        out.append(html.escape(ch))
        i += 1
    if open_spans:
        out.append("</span>")
    return "".join(out)


def xterm256(n: int) -> str:
    if n < 16:
        base = [
            "#000000", "#cd0000", "#00cd00", "#cdcd00", "#0000ee", "#cd00cd", "#00cdcd", "#e5e5e5",
            "#7f7f7f", "#ff0000", "#00ff00", "#ffff00", "#5c5cff", "#ff00ff", "#00ffff", "#ffffff",
        ]
        return base[n]
    if n < 232:
        n -= 16
        levels = [0, 95, 135, 175, 215, 255]
        r = levels[(n // 36) % 6]
        g = levels[(n // 6) % 6]
        b = levels[n % 6]
        return "#%02X%02X%02X" % (r, g, b)
    v = 8 + (n - 232) * 10
    return "#%02X%02X%02X" % (v, v, v)


HTML_TMPL = """<!doctype html>
<html><head><meta charset="utf-8">
<style>
  html,body {{ margin:0; padding:0; background:{bg}; }}
  pre {{
    margin:0; padding:22px 26px;
    background:{bg}; color:{fg};
    font-family:"DejaVu Sans Mono","Noto Sans Mono","Liberation Mono",monospace;
    font-size:13.5px; line-height:1.32; white-space:pre;
    display:inline-block;
  }}
</style></head>
<body><pre>{body}</pre></body></html>
"""


def render_theme(theme: str) -> str:
    env = dict(os.environ)
    env["TB_COLOR_DEPTH"] = "24"
    env["COLUMNS"] = "100"
    env["TB_INFO"] = "1"
    proc = subprocess.run(
        ["bash", os.path.join(ROOT, "bin", "tb"), "--theme", theme],
        capture_output=True, text=True, env=env, cwd=ROOT, timeout=120,
    )
    return proc.stdout


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(ROOT, "assets", "previews"))
    ap.add_argument("--themes", default="")
    args = ap.parse_args()

    os.makedirs(args.out, exist_ok=True)

    if args.themes:
        themes = [t.strip() for t in args.themes.split(",") if t.strip()]
    else:
        conf_dir = os.path.join(ROOT, "themes")
        themes = sorted(
            os.path.splitext(f)[0] for f in os.listdir(conf_dir) if f.endswith(".conf")
        )

    try:
        from playwright.sync_api import sync_playwright
    except ImportError:
        print("playwright is not installed", file=sys.stderr)
        return 1

    with sync_playwright() as p:
        browser = p.chromium.launch(
            executable_path=os.environ.get("CHROMIUM_PATH") or None,
            args=["--no-sandbox", "--font-render-hinting=none"],
        )
        page = browser.new_page(viewport={"width": 1100, "height": 700},
                                device_scale_factor=2)
        for theme in themes:
            ansi = render_theme(theme)
            if not ansi.strip():
                print("  ! empty output for", theme, file=sys.stderr)
                continue
            page.set_content(HTML_TMPL.format(bg=BG, fg=FG, body=ansi_to_html(ansi)))
            page.wait_for_timeout(120)
            out = os.path.join(args.out, "%s.png" % theme)
            page.locator("pre").screenshot(path=out)
            print("  ✓", os.path.relpath(out, ROOT))
        browser.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
