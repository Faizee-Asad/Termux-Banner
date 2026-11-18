#!/usr/bin/env python3
"""Generate lib/fonts-data.sh — bundled ASCII font tables.

The project must be able to render custom banner text on a bare Termux
install where `toilet` / `figlet` are not present, so a couple of classic
block fonts are baked into the project itself.
"""
import shlex
import subprocess
import sys

FONTS = {
    "big": ("toilet", ["-f", "big"]),
    "block": ("toilet", ["-f", "block"]),
    "standard": ("toilet", ["-f", "standard"]),
}

CHARS = (
    [chr(c) for c in range(ord("A"), ord("Z") + 1)]
    + [chr(c) for c in range(ord("a"), ord("z") + 1)]
    + [chr(c) for c in range(ord("0"), ord("9") + 1)]
    + list(" !@#$%^&*()-_=+[]{}:;'\",.<>/?\\|`~")
)

HEADER = """#!/usr/bin/env bash
# shellcheck shell=bash disable=SC2016
# ---------------------------------------------------------------------------
#  Termux Banner Advanced :: lib/fonts-data.sh   (auto-generated)
#
#  Bundled ASCII font tables so that custom banner text can be rendered even
#  on a bare Termux install without `toilet` or `figlet` installed.
#
#  Regenerate with:  python3 tools/gen-fonts.py
# ---------------------------------------------------------------------------

# tb_font_block <font> <char> -> prints the glyph rows, one per line
tb_font_block() {
    local font="$1" ch="$2"
    case "${font}:${ch}" in
"""


def render(tool, args, text):
    try:
        out = subprocess.run(
            [tool] + args + [text],
            capture_output=True,
            text=True,
            timeout=20,
        )
    except (OSError, subprocess.TimeoutExpired):
        return None
    if out.returncode != 0:
        return None
    lines = [l.rstrip() for l in out.stdout.split("\n")]
    while lines and lines[-1] == "":
        lines.pop()
    return lines


def main():
    out = [HEADER]
    for font, (tool, args) in FONTS.items():
        for ch in CHARS:
            label = ch
            lines = render(tool, args, ch)
            if not lines:
                continue
            key = f"{font}:{label}"
            out.append(f"        {shlex.quote(key)})\n")
            body = []
            for l in lines:
                body.append("            " + shlex.quote(l))
            out.append(
                "            printf '%s\\n' \\\n"
                + " \\\n".join(body)
                + "\n            ;;\n"
            )
    out.append("        *)\n            return 1\n            ;;\n    esac\n}\n")

    sys.stdout.write("".join(out))


if __name__ == "__main__":
    main()
