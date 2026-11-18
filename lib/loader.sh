#!/usr/bin/env bash
# shellcheck shell=bash
# ---------------------------------------------------------------------------
#  Termux Banner Advanced :: lib/loader.sh
#  Orchestrates the whole banner: art + gradient + info panel + mascot.
# ---------------------------------------------------------------------------

TB_PROJECT_DIR="${TB_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." 2>/dev/null && pwd)}"

# tb_art_path <name> -> path of a bundled ASCII art file
tb_art_path() {
    local name="$1"
    [[ -z "$name" ]] && return 1
    printf '%s/assets/ascii/%s.txt' "$TB_PROJECT_DIR" "$name"
}

# tb_art_files -> names of every bundled ASCII art
tb_art_files() {
    local dir="$TB_PROJECT_DIR/assets/ascii"
    [[ -d "$dir" ]] || return 1
    local f
    for f in "$dir"/*.txt; do
        [[ -e "$f" ]] || continue
        basename "$f" .txt
    done
}

# backwards compatible alias
tb_list_art() { tb_art_files; }

# tb_resolve_art -> prints the raw ASCII art for the current settings
tb_resolve_art() {
    case "$TB_ART" in
        custom)
            tb_text_to_ascii_safe "$TB_TEXT" "$TB_FONT"
            ;;
        file)
            if [[ -r "$TB_ART_FILE" ]]; then
                cat "$TB_ART_FILE"
            else
                tb_text_to_ascii_safe "$TB_TEXT" "$TB_FONT"
            fi
            ;;
        theme|*)
            local p; p="$(tb_art_path "$TB_TH_ART")"
            if [[ -r "$p" ]]; then
                cat "$p"
            else
                tb_text_to_ascii_safe "$TB_TEXT" "$TB_FONT"
            fi
            ;;
    esac
}

# tb_resolve_art_for <theme> -> art for an arbitrary theme (preview)
tb_resolve_art_for() {
    local th="$1" saved_art="$TB_ART" saved_text="$TB_TEXT" saved_font="$TB_FONT" saved_file="$TB_ART_FILE"
    TB_ART="theme"; TB_TEXT="$TB_TITLE"; TB_FONT="big"; TB_ART_FILE=""
    tb_theme_load "$th" 2>/dev/null
    tb_resolve_art
    TB_ART="$saved_art"; TB_TEXT="$saved_text"; TB_FONT="$saved_font"; TB_ART_FILE="$saved_file"
}

# ---------------------------------------------------------------------------
#  tb_build_info_body <widgets> -> two column body block
# ---------------------------------------------------------------------------
TB_INFO_WIDTH=40
TB_INFO_BODY=""
tb_build_info_body() {
    local widgets="${1:-$TB_WIDGETS}"
    local -a pairs=()
    local line label value
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        label="${line%%|*}"
        value="${line#*|}"
        pairs+=("$label|$value")
    done < <(tb_sysinfo_widgets "$widgets")

    local n=${#pairs[@]}
    (( n == 0 )) && { TB_INFO_BODY=""; return 0; }

    # dynamic column widths
    local labw=0 valw=0 p
    for p in "${pairs[@]}"; do
        label="${p%%|*}"; value="${p#*|}"
        (( ${#label} > labw )) && labw=${#label}
        (( ${#value} > valw )) && valw=${#value}
    done
    (( labw > 12 )) && labw=12
    (( labw < 8 ))  && labw=8
    (( valw > 22 )) && valw=22
    (( valw < 12 )) && valw=12

    local left=$(( (n + 1) / 2 )) right=$(( n - left ))
    local i cell plain
    TB_INFO_BODY=""

    for (( i = 0; i < left; i++ )); do
        label="${pairs[i]%%|*}"; value="${pairs[i]#*|}"
        cell="$(tb_render_solid "$(tb_pad "$label" "$labw")" "$TB_TH_ACCENT" 1)$(tb_pad "$value" "$valw")  "
        if (( i < right )); then
            label="${pairs[left+i]%%|*}"; value="${pairs[left+i]#*|}"
            cell+="$(tb_render_solid "$(tb_pad "$label" "$labw")" "$TB_TH_ACCENT" 1)$(tb_pad "$value" "$valw")  "
        fi
        plain="$(tb_strip_ansi "$cell")"
        (( ${#plain} > TB_INFO_WIDTH )) && TB_INFO_WIDTH=${#plain}
        TB_INFO_BODY+="$(tb_rtrim "$cell")"$'\n'
    done
    TB_INFO_BODY="${TB_INFO_BODY%$'\n'}"
    return 0
}

# ---------------------------------------------------------------------------
#  tb_render_banner  — the main entry point
# ---------------------------------------------------------------------------
tb_render_banner() {
    local width="${1:-$(tb_term_width)}"

    [[ "${TB_SKIP_BANNER:-0}" == "1" ]] && return 0

    # only load the configuration once - a caller may have applied overrides
    [[ "${TB_CONFIG_LOADED:-0}" == "1" ]] || tb_config_load
    tb_theme_load "$TB_THEME" 2>/dev/null || {
        tb_theme_load "neon" 2>/dev/null || true
    }

    # the theme provides the defaults - an explicit user choice always wins
    local gradient="$TB_TH_GRADIENT"
    local effect="$TB_EFFECT"
    local direction="$TB_DIRECTION"
    [[ -z "$gradient" ]] && gradient="$TB_TH_GRADIENT"
    [[ "$effect" == "auto" || -z "$effect" ]] && effect="$TB_TH_EFFECT"
    [[ "$direction" == "auto" || -z "$direction" ]] && direction="$TB_TH_DIRECTION"

    tb_build_gradient "$gradient"

    local art
    art="$(tb_resolve_art)"

    # the composition is centred on the art, not on the whole terminal
    local cw; cw="$(tb_block_width "$art")"
    (( cw < 40 )) && cw=40
    (( cw > width )) && cw="$width"

    # 1. the art itself
    tb_render_art "$art" "$direction" "$effect" "10102A"

    # 2. title + subtitle
    if [[ -n "$TB_TITLE" ]]; then
        printf '\n'
        tb_render_gradient_text "$(tb_center "$TB_TITLE" "$cw")"
        printf '\n'
    fi
    if [[ -n "$TB_SUBTITLE" ]]; then
        tb_render_solid "$(tb_center "$TB_SUBTITLE" "$cw")" "$TB_TH_ACCENT" 1
        printf '\n'
    fi

    # 3. info panel
    if [[ "$TB_INFO" == "1" ]]; then
        TB_INFO_WIDTH=40
        tb_build_info_body "$TB_WIDGETS"
        if [[ -n "$TB_INFO_BODY" ]]; then
            local pw=$(( TB_INFO_WIDTH + 4 ))
            (( pw > width )) && pw="$width"
            (( pw < 44 )) && pw=44
            printf '\n'
            tb_render_panel "SYSTEM PROFILE" "$TB_INFO_BODY" "$pw"
        fi
    fi

    # 4. mascot
    local mascot="$TB_MASCOT"
    [[ -z "$mascot" ]] && mascot="$TB_TH_MASCOT"
    if [[ -n "$mascot" && "$mascot" != "none" ]]; then
        printf '\n'
        tb_center_block "$(tb_render_mascot "$mascot" "$TB_MASCOT_MSG")" "$cw"
    fi

    # 5. clock
    if [[ "$TB_CLOCK" == "1" ]]; then
        printf '\n'
        tb_render_solid "$(tb_center "$(date '+%H:%M:%S  |  %a %d %b %Y' 2>/dev/null)" "$cw")" "$TB_TH_ACCENT" 0
    fi
}

# ---------------------------------------------------------------------------
#  tb_render_animated <theme> — cycling animation for the `tb --loop` mode
# ---------------------------------------------------------------------------
tb_render_animated() {
    local frames="${1:-24}" delay="${2:-0.12}"
    local i
    for (( i = 0; i < frames; i++ )); do
        printf '\033[H\033[2J'
        TB_RENDER_GLOBAL_OFFSET=$(( (i * 6) % 256 ))
        tb_render_banner
        tb_sleep "$delay"
    done
    TB_RENDER_GLOBAL_OFFSET=0
}

# ---------------------------------------------------------------------------
#  tb_render_preview <theme> [width]
#  Compact preview used by the interactive menu.
# ---------------------------------------------------------------------------
tb_render_preview() {
    local th="${1:-$TB_THEME}" width="${2:-$(tb_term_width)}"
    local saved_theme="$TB_THEME"
    tb_theme_load "$th" 2>/dev/null || { TB_THEME="$saved_theme"; return 1; }
    tb_build_gradient "$TB_TH_GRADIENT"
    local art
    art="$(tb_resolve_art_for "$th")"
    tb_render_art "$art" "$TB_TH_DIRECTION" "$TB_TH_EFFECT" "10102A"
    printf '\n'
    tb_render_gradient_text "$(tb_center "$TB_TH_LABEL - $TB_TH_DESC" "$width")"
    printf '\n'
    TB_THEME="$saved_theme"
}
