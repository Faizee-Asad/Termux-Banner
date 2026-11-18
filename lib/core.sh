#!/usr/bin/env bash
# shellcheck shell=bash
# ---------------------------------------------------------------------------
#  Termux Banner Advanced :: lib/core.sh
#  Colour depth detection, 24-bit gradient engine, box drawing helpers.
#
#  Everything in this file is written in pure bash + coreutils so that it
#  keeps working on a stock Termux install without extra packages.
# ---------------------------------------------------------------------------

TB_VERSION="${TB_VERSION:-2.0.0}"
TB_TITLE="Termux Banner Advanced"
TB_AUTHOR="Faizee Asad"
TB_MARK_BEGIN="# >>> termux-banner >>>"
TB_MARK_END="# <<< termux-banner <<<"

# ---------------------------------------------------------------------------
#  Terminal capability detection
# ---------------------------------------------------------------------------

# tb_is_utf8 -> 0 when the current locale can handle multi byte characters
tb_is_utf8() {
    local loc="${LC_ALL:-${LC_CTYPE:-${LANG:-}}}"
    case "$loc" in
        *UTF-8*|*utf8*|*UTF8*) return 0 ;;
    esac
    return 1
}

# tb_ensure_utf8 -> switch to a UTF-8 locale when one is available.
# Only touches LC_ALL when the user did not set one explicitly.
tb_ensure_utf8() {
    tb_is_utf8 && return 0
    [[ -n "${LC_ALL:-}" ]] && return 0
    local l
    for l in C.UTF-8 C.utf8 en_US.UTF-8; do
        if locale -a 2>/dev/null | grep -qi "^${l}"; then
            export LC_ALL="$l"
            return 0
        fi
    done
    return 1
}

# tb_color_depth -> 24 | 256 | 16 | 0
tb_color_depth() {
    if [[ -n "${TB_COLOR_DEPTH:-}" ]]; then
        printf '%s' "$TB_COLOR_DEPTH"
        return 0
    fi
    if [[ -n "${NO_COLOR:-}" ]]; then printf '0'; return 0; fi
    if [[ "${TERM:-}" == "dumb" ]]; then printf '0'; return 0; fi
    case "${COLORTERM:-}" in
        truecolor|24bit) printf '24'; return 0 ;;
    esac
    local colors=0
    if command -v tput >/dev/null 2>&1; then
        colors="$(tput colors 2>/dev/null || echo 0)"
    fi
    case "$colors" in
        16777216|truecolor) printf '24'; return 0 ;;
        256|88)            printf '256'; return 0 ;;
        16|32)            printf '16'; return 0 ;;
        8)                printf '8';  return 0 ;;
        0)                printf '0';  return 0 ;;
        *)                printf '16'; return 0 ;;
    esac
}

# tb_supports_color -> 0 when colour output makes no sense
tb_supports_color() {
    local d; d="$(tb_color_depth)"
    [[ "$d" != "0" ]]
}

# tb_term_width -> usable terminal width (clamped between 40 and 160)
tb_term_width() {
    local w="${COLUMNS:-}"
    if [[ -z "$w" ]] && command -v tput >/dev/null 2>&1; then
        w="$(tput cols 2>/dev/null || echo 0)"
    fi
    [[ "$w" =~ ^[0-9]+$ ]] || w=80
    (( w < 40 )) && w=40
    (( w > 160 )) && w=160
    printf '%s' "$w"
}

# tb_term_height
tb_term_height() {
    local h="${LINES:-}"
    [[ -z "$h" ]] && command -v tput >/dev/null 2>&1 && h="$(tput lines 2>/dev/null || echo 24)"
    [[ "$h" =~ ^[0-9]+$ ]] || h=24
    printf '%s' "$h"
}

# ---------------------------------------------------------------------------
#  ANSI helpers
# ---------------------------------------------------------------------------

tb_reset()  { printf '\033[0m'; }
tb_bold()   { printf '\033[1m'; }
tb_dim()    { printf '\033[2m'; }
tb_italic() { printf '\033[3m'; }
tb_rev()    { printf '\033[7m'; }

# tb_rgb <r> <g> <b>  -> 24 bit foreground
tb_rgb() {
    local d; d="$(tb_color_depth)"
    case "$d" in
        24)  printf '\033[38;2;%d;%d;%dm' "$1" "$2" "$3" ;;
        256) printf '\033[38;5;%dm' "$(tb_rgb_to_256 "$1" "$2" "$3")" ;;
        16|8) printf '\033[%dm' "$(tb_rgb_to_ansi16 "$1" "$2" "$3")" ;;
        *)   printf '' ;;
    esac
}

tb_bg_rgb() {
    local d; d="$(tb_color_depth)"
    case "$d" in
        24)  printf '\033[48;2;%d;%d;%dm' "$1" "$2" "$3" ;;
        256) printf '\033[48;5;%dm' "$(tb_rgb_to_256 "$1" "$2" "$3")" ;;
        *)   printf '' ;;
    esac
}

# tb_rgb_to_256 <r> <g> <b>
tb_rgb_to_256() {
    local r="$1" g="$2" b="$3"
    if (( r == g && g == b )); then
        if (( r < 8 )); then printf '16'; return 0; fi
        if (( r > 248 )); then printf '231'; return 0; fi
        printf '%d' $(( 232 + ((r - 8) * 24 / 247) ))
        return 0
    fi
    printf '%d' $(( 16 + (r * 5 / 255) * 36 + (g * 5 / 255) * 6 + (b * 5 / 255) ))
}

# tb_rgb_to_ansi16 <r> <g> <b> -> 30-37 / 90-97
tb_rgb_to_ansi16() {
    local r="$1" g="$2" b="$3" bright=0
    (( r > 150 || g > 150 || b > 150 )) && bright=1
    if (( r >= g && r >= b )); then
        (( bright )) && { printf '91'; return 0; } || { printf '31'; return 0; }
    elif (( g >= b )); then
        (( bright )) && { printf '92'; return 0; } || { printf '32'; return 0; }
    else
        (( bright )) && { printf '94'; return 0; } || { printf '34'; return 0; }
    fi
}

# tb_hex_to_rgb <#RRGGBB> -> "R G B"
tb_hex_to_rgb() {
    local h="${1#\#}"; h="${h// /}"
    [[ ${#h} -eq 3 ]] && h="${h:0:1}${h:0:1}${h:1:1}${h:1:1}${h:2:1}${h:2:1}"
    [[ ${#h} -eq 8 ]] && h="${h:2:2}${h:4:2}${h:6:2}"
    if [[ ! "$h" =~ ^[0-9a-fA-F]{6}$ ]]; then printf '255 255 255'; return 0; fi
    printf '%d %d %d' "$((16#${h:0:2}))" "$((16#${h:2:2}))" "$((16#${h:4:2}))"
}

# ---------------------------------------------------------------------------
#  Gradient engine
#
#  A 256 entry lookup table is built once per render, then each character
#  simply picks its colour out of the table.  That keeps the whole renderer
#  fast even for large ASCII art.
# ---------------------------------------------------------------------------

# tb_build_gradient <hex hex ...> [shift 0-255]
# Populates the global array TB_GRAD (256 ANSI escapes) and TB_GRAD_HEX.
tb_build_gradient() {
    local stops="$1" shift="${2:-0}"
    local -a rgbs=() hexes=()
    local h rgb
    for h in $stops; do
        hexes+=("${h#\#}")
        rgb="$(tb_hex_to_rgb "$h")"
        rgbs+=("$rgb")
    done
    local n=${#rgbs[@]}
    (( n == 0 )) && { hexes=("FFFFFF"); rgbs=("255 255 255"); n=1; }
    local -a R=() G=() B=()
    local i
    for (( i = 0; i < n; i++ )); do
        read -r R[i] G[i] B[i] <<< "${rgbs[i]}"
    done

    TB_GRAD=(); TB_GRAD_HEX=()
    local k idx frac scaled r g b r2 g2 b2
    for (( k = 0; k < 256; k++ )); do
        if (( n == 1 )); then
            r="${R[0]}"; g="${G[0]}"; b="${B[0]}"
        else
            scaled=$(( k * (n - 1) ))
            idx=$(( scaled / 255 ))
            frac=$(( scaled % 255 ))
            if (( idx > n - 2 )); then idx=$(( n - 2 )); frac=255; fi
            r="${R[idx]}"; g="${G[idx]}"; b="${B[idx]}"
            r2="${R[idx+1]}"; g2="${G[idx+1]}"; b2="${B[idx+1]}"
            r=$(( r + (r2 - r) * frac / 255 ))
            g=$(( g + (g2 - g) * frac / 255 ))
            b=$(( b + (b2 - b) * frac / 255 ))
        fi
        TB_GRAD+=("$(tb_rgb "$r" "$g" "$b")")
        TB_GRAD_HEX+=("$(printf '#%02X%02X%02X' "$r" "$g" "$b")")
    done
    return 0
}

# tb_grad_color <index 0-255> -> ANSI escape for that gradient entry
tb_grad_color() {
    local idx="${1:-0}"
    (( idx < 0 )) && idx=0
    (( idx > 255 )) && idx=255
    printf '%s' "${TB_GRAD[idx]}"
}

# tb_grad_rgb <index> -> "R G B"
tb_grad_rgb() {
    local idx="${1:-0}" hex r g b
    (( idx < 0 )) && idx=0
    (( idx > 255 )) && idx=255
    hex="${TB_GRAD_HEX[idx]}"
    read -r r g b <<< "$(tb_hex_to_rgb "$hex")"
    printf '%s %d %d %d' "$hex" "$r" "$g" "$b"
}

# tb_grad_hex <index> -> "#RRGGBB"
tb_grad_hex() {
    local idx="${1:-0}"
    (( idx < 0 )) && idx=0
    (( idx > 255 )) && idx=255
    printf '%s' "${TB_GRAD_HEX[idx]}"
}

# tb_hue_rgb <hue 0-359> <sat 0-100> <val 0-100> -> "R G B"
tb_hue_rgb() {
    local h=$(( $1 % 360 )) s=$2 v=$3
    local c x m r g b
    c=$(( v * s / 100 ))
    x=$(( c * ( 60 - (h % 60) ) ) / 60 )
    m=$(( v - c ))
    case $(( h / 60 )) in
        0) r=$c; g=$x; b=0 ;;
        1) r=$x; g=$c; b=0 ;;
        2) r=0; g=$c; b=$x ;;
        3) r=0; g=x; b=$c ;;
        4) r=$x; g=0; b=$c ;;
        *) r=$c; g=0; b=$x ;;
    esac
    printf '%d %d %d' $(( r + m )) $(( g + m )) $(( b + m ))
}

# tb_build_hue_gradient <hue0> <sat> <val> [shift]
tb_build_hue_gradient() {
    local hue0="$1" sat="$2" val="$3" shift="${4:-0}"
    local i r g b rgb
    TB_GRAD=(); TB_GRAD_HEX=()
    for (( i = 0; i < 256; i++ )); do
        rgb="$(tb_hue_rgb $(( (hue0 + i * 360 / 256 + shift) % 360 )) "$sat" "$val")"
        read -r r g b <<< "$rgb"
        TB_GRAD+=("$(tb_rgb "$r" "$g" "$b")")
        TB_GRAD_HEX+=("$(printf '#%02X%02X%02X' "$r" "$g" "$b")")
    done
}

# tb_build_solid_gradient <hex>  -> single colour table
tb_build_solid_gradient() {
    tb_build_gradient "$1" 0
}

# ---------------------------------------------------------------------------
#  Text helpers
# ---------------------------------------------------------------------------

# tb_strip_ansi <text>
tb_strip_ansi() {
    local s="$1"
    local out="" i=0 len ch
    len=${#s}
    while (( i < len )); do
        ch="${s:i:1}"
        if [[ "$ch" == $'\033' ]]; then
            (( i++ ))
            while (( i < len )); do
                ch="${s:i:1}"
                (( i++ ))
                [[ "$ch" =~ [a-zA-Z] ]] && break
            done
        else
            out+="$ch"
            (( i++ ))
        fi
    done
    printf '%s' "$out"
}

# tb_visible_len <text>  -> length without ANSI escapes
tb_visible_len() {
    local s; s="$(tb_strip_ansi "$1")"
    printf '%s' "${#s}"
}

# tb_repeat <char> <count>
tb_repeat() {
    local c="$1" n="$2" out=""
    while (( n > 0 )); do out+="$c"; (( n-- )); done
    printf '%s' "$out"
}

# tb_pad <text> <width> [align left|center|right]
tb_pad() {
    local text="$1" width="$2" align="${3:-left}"
    local len; len="$(tb_visible_len "$text")"
    (( len >= width )) && { printf '%s' "$text"; return 0; }
    local pad=$(( width - len ))
    case "$align" in
        center)
            local l=$(( pad / 2 ))
            printf '%s%s%s' "$(tb_repeat ' ' "$l")" "$text" "$(tb_repeat ' ' $(( pad - l )))"
            ;;
        right)
            printf '%s%s' "$(tb_repeat ' ' "$pad")" "$text"
            ;;
        *)
            printf '%s%s' "$text" "$(tb_repeat ' ' "$pad")"
            ;;
    esac
}

# tb_center <text> [width]
tb_center() {
    local text="$1" width="${2:-$(tb_term_width)}"
    tb_pad "$text" "$width" center
}

# tb_center_block <block> [width] -> centres every line of a block
tb_center_block() {
    local block="$1" width="${2:-$(tb_term_width)}"
    local -a lines=()
    mapfile -t lines <<< "$block"
    local l
    for l in "${lines[@]}"; do
        printf '%s\n' "$(tb_center "$l" "$width")"
    done
}

# tb_block_width <block> -> width of the widest line
tb_block_width() {
    local block="$1" max=0 l len
    local -a lines=()
    mapfile -t lines <<< "$block"
    for l in "${lines[@]}"; do
        len="${#l}"
        (( len > max )) && max=$len
    done
    printf '%s' "$max"
}

# tb_rtrim <text>  -> text without trailing whitespace
tb_rtrim() {
    local s="$1"
    s="${s%"${s##*[![:space:]]}"}"
    printf '%s' "$s"
}

# ---------------------------------------------------------------------------
#  Misc
# ---------------------------------------------------------------------------

# tb_has <command>
tb_has() { command -v "$1" >/dev/null 2>&1; }

# tb_random <start> <end>
tb_random() {
    local a="$1" b="$2"
    if (( b <= a )); then printf '%s' "$a"; return 0; fi
    local span=$(( b - a + 1 ))
    printf '%s' $(( a + (RANDOM % span) ))
}

# tb_mktemp_dir
tb_mktemp_dir() {
    local d
    d="$(mktemp -d 2>/dev/null || echo "/tmp/tb.$$.${RANDOM}")"
    printf '%s' "$d"
}

# tb_abs_path <path>
tb_abs_path() {
    local p="$1"
    if [[ -d "$p" ]]; then
        (cd "$p" && pwd)
    else
        printf '%s' "$p"
    fi
}

# tb_sleep <seconds>  (supports fractional)
tb_sleep() { sleep "$1" 2>/dev/null || sleep 1; }

# Make sure a UTF-8 locale is active whenever one is available.
tb_ensure_utf8
