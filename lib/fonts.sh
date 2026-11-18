#!/usr/bin/env bash
# shellcheck shell=bash
# ---------------------------------------------------------------------------
#  Termux Banner Advanced :: lib/fonts.sh
#  Font discovery and text -> ASCII art conversion.
#
#  Resolution order for a font name:
#    1. bundled table  (lib/fonts-data.sh)  - always available
#    2. `toilet`       - if installed
#    3. `figlet`       - if installed
#    4. bundled "big"  - final fallback
# ---------------------------------------------------------------------------

TB_FONT_ROWS=0
TB_FONT_WIDTH=0

# tb_bundled_fonts
tb_bundled_fonts() {
    printf 'big\nblock\nstandard\n'
}

# tb_system_fonts  -> fonts provided by the installed toilet / figlet
tb_system_fonts() {
    local d
    for d in "$PREFIX/share/toilet" /data/data/com.termux/files/usr/share/toilet \
             /usr/share/toilet /usr/share/figlet /usr/local/share/figlet; do
        [[ -d "$d" ]] || continue
        local f
        for f in "$d"/*.flf "$d"/*.tlf "$d"/*.flc; do
            [[ -e "$f" ]] || continue
            basename "$f" | sed -E 's/\.(flf|tlf|flc)$//'
        done
    done
}

# tb_font_list -> all usable font names (bundled first)
tb_font_list() {
    local seen="" f
    while IFS= read -r f; do
        [[ -z "$f" ]] && continue
        case " $seen " in *" $f "*) continue ;; esac
        seen="$seen $f"
        printf '%s\n' "$f"
    done < <(tb_bundled_fonts; tb_system_fonts)
}

# tb_font_exists <font>
tb_font_exists() {
    local font="$1"
    [[ -z "$font" ]] && return 1
    case " $(tb_bundled_fonts | tr '\n' ' ') " in
        *" $font "*) return 0 ;;
    esac
    local d
    for d in "$PREFIX/share/toilet" /data/data/com.termux/files/usr/share/toilet \
             /usr/share/toilet /usr/share/figlet /usr/local/share/figlet; do
        [[ -e "$d/$font.flf" || -e "$d/$font.tlf" || -e "$d/$font.flc" ]] && return 0
    done
    return 1
}

# tb_font_is_bundled <font>
tb_font_is_bundled() {
    case " $(tb_bundled_fonts | tr '\n' ' ') " in
        *" $1 "*) return 0 ;;
    esac
    return 1
}

# tb_font_metrics <font> -> sets TB_FONT_ROWS / TB_FONT_WIDTH
tb_font_metrics() {
    local font="$1" art
    TB_FONT_ROWS=0; TB_FONT_WIDTH=0
    art="$(tb_text_to_ascii "A" "$font" 2>/dev/null)"
    [[ -z "$art" ]] && return 1
    local rows=0 w=0 l
    while IFS= read -r l; do
        rows=$(( rows + 1 ))
        (( ${#l} > w )) && w=${#l}
    done <<< "$art"
    TB_FONT_ROWS=$rows
    TB_FONT_WIDTH=$w
    return 0
}

# tb_text_to_ascii <text> <font>
# Prints the rendered ASCII art.
tb_text_to_ascii() {
    local text="$1" font="${2:-big}"

    # 1. live tools win for non bundled fonts
    if ! tb_font_is_bundled "$font"; then
        local out=""
        if tb_has toilet; then
            out="$(toilet -f "$font" -- "$text" 2>/dev/null)"
        fi
        if [[ -z "$out" ]] && tb_has figlet; then
            out="$(figlet -f "$font" "$text" 2>/dev/null)"
        fi
        if [[ -n "$out" ]]; then
            printf '%s\n' "$out"
            return 0
        fi
        font="big"
    fi

    # 2. bundled renderer
    tb_bundled_render "$text" "$font"
}

# tb_bundled_render <text> <font>
tb_bundled_render() {
    local text="$1" font="${2:-big}"
    tb_font_is_bundled "$font" || font="big"

    # measure with a reference glyph
    local ref_rows=0 ref_w=0 ch i rows=() maxrows=0
    local probe
    probe="$(tb_font_block "$font" "A")"
    if [[ -n "$probe" ]]; then
        while IFS= read -r l; do
            ref_rows=$(( ref_rows + 1 ))
            (( ${#l} > ref_w )) && ref_w=${#l}
        done <<< "$probe"
    else
        # 'A' may be missing (punctuation-only fonts) - probe a digit
        probe="$(tb_font_block "$font" "0")"
        while IFS= read -r l; do
            ref_rows=$(( ref_rows + 1 ))
            (( ${#l} > ref_w )) && ref_w=${#l}
        done <<< "$probe"
    fi
    (( ref_rows == 0 )) && ref_rows=6

    # collect glyphs
    local -a glyphs=()
    local -a glyph_rows=()
    local -a glyph_chars=()
    local len=${#text}
    for (( i = 0; i < len; i++ )); do
        ch="${text:i:1}"
        local g
        g="$(tb_font_block "$font" "$ch")"
        local -a gl=()
        mapfile -t gl <<< "$g"
        if [[ -z "$g" ]] || (( ${#gl[@]} == 0 )) || [[ -z "${gl[0]}" && "${#gl[@]}" -le 1 ]]; then
            # space / unsupported glyph -> blank cell of reference width
            local blank=""
            (( ref_w > 0 )) && blank="$(tb_repeat ' ' "$ref_w")"
            gl=()
            local r
            for (( r = 0; r < ref_rows; r++ )); do gl+=("$blank"); done
        fi
        glyphs+=("$(printf '%s\n' "${gl[@]}")")
        glyph_rows+=("${#gl[@]}")
        glyph_chars+=("$ch")
        (( ${#gl[@]} > maxrows )) && maxrows=${#gl[@]}
    done
    (( maxrows == 0 )) && return 1

    # compose
    local r g idx line=""
    for (( r = 0; r < maxrows; r++ )); do
        line=""
        for (( g = 0; g < ${#glyphs[@]}; g++ )); do
            local -a gl=()
            mapfile -t gl <<< "${glyphs[g]}"
            local cell=""
            if (( r < ${#gl[@]} )); then cell="${gl[r]}"; fi
            line+="$cell"
        done
        printf '%s\n' "$(tb_rtrim "$line")"
    done
}

# tb_text_to_ascii_safe <text> <font> -- never fails, always prints something
tb_text_to_ascii_safe() {
    local text="$1" font="${2:-big}" out
    out="$(tb_text_to_ascii "$text" "$font" 2>/dev/null)"
    if [[ -z "$out" ]]; then
        out="$(tb_text_to_ascii "$text" "big" 2>/dev/null)"
    fi
    [[ -z "$out" ]] && out="$text"
    printf '%s\n' "$out"
}
