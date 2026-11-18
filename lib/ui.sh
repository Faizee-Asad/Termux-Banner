#!/usr/bin/env bash
# shellcheck shell=bash
# ---------------------------------------------------------------------------
#  Termux Banner Advanced :: lib/ui.sh
#  Menus, prompts and small terminal helpers used by the interactive tools.
# ---------------------------------------------------------------------------

TB_UI_RESET="${TB_UI_RESET:-$'\033[0m'}"
TB_UI_DIM="${TB_UI_DIM:-$'\033[2;38;5;245m'}"
TB_UI_ACCENT="${TB_UI_ACCENT:-$'\033[1;38;2;0;245;255m'}"

# tb_ui_set_accent <#RRGGBB> -> switch the accent colour of the menus
tb_ui_set_accent() {
    local hex="$1" r g b
    [[ -z "$hex" ]] && return 0
    read -r r g b <<< "$(tb_hex_to_rgb "$hex")"
    TB_UI_ACCENT=$'\033[1m'"$(tb_rgb "$r" "$g" "$b")"
    return 0
}

tb_ui_accent() { printf '%s%s%s' "$TB_UI_ACCENT" "$1" "$TB_UI_RESET"; }
tb_ui_dim()    { printf '%s%s%s' "$TB_UI_DIM" "$1" "$TB_UI_RESET"; }

tb_ui_header() {
    local title="$1" width="${2:-$(tb_term_width)}"
    local line
    line="$(tb_repeat '─' $(( width - 2 )) )"
    printf '\n'
    printf '%s┌%s┐%s\n' "$TB_UI_DIM" "$line" "$TB_UI_RESET"
    printf '%s│ %s │%s\n' "$TB_UI_ACCENT" "$(tb_pad "$title" $(( width - 4 )) )" "$TB_UI_RESET"
    printf '%s└%s┘%s\n' "$TB_UI_DIM" "$line" "$TB_UI_RESET"
    printf '\n'
}

tb_ui_section() {
    printf '\n'
    printf '%s── %s%s\n' "$TB_UI_DIM" "$1" "$TB_UI_RESET"
}

tb_ui_info()  { printf '  %s▸ %s%s\n' "$TB_UI_DIM" "$1" "$TB_UI_RESET"; }
tb_ui_ok()    { printf '  %s✔ %s%s\n' "$TB_UI_ACCENT" "$1" "$TB_UI_RESET"; }
tb_ui_warn()  { printf '  %s! %s%s\n' "$TB_UI_DIM" "$1" "$TB_UI_RESET"; }
tb_ui_error() { printf '  %s✖ %s%s\n' "$'\033[1;31m'" "$1" "$TB_UI_RESET"; }

# tb_ui_menu <title> <item>...
# Prints the menu and stores the chosen number in TB_UI_CHOICE.
tb_ui_menu() {
    local title="$1"; shift
    local -a items=("$@")
    local i
    tb_ui_section "$title"
    for (( i = 0; i < ${#items[@]}; i++ )); do
        printf '   %s%2d%s) %s\n' "$TB_UI_DIM" $(( i + 1 )) "$TB_UI_RESET" "${items[i]}"
    done
    printf '\n'
    local choice=""
    read -r -p "   Select [1-${#items[@]}]: " choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#items[@]} )); then
        TB_UI_CHOICE="$choice"
        return 0
    fi
    TB_UI_CHOICE=0
    return 1
}

# tb_ui_select <prompt> <item>...
# Single line picker, stores the chosen item in TB_UI_PICK.
tb_ui_select() {
    local prompt="$1"; shift
    local -a items=("$@")
    local i choice=""
    printf '\n'
    for (( i = 0; i < ${#items[@]}; i++ )); do
        printf '   %s%2d%s) %s\n' "$TB_UI_DIM" $(( i + 1 )) "$TB_UI_RESET" "${items[i]}"
    done
    read -r -p "   $prompt [1-${#items[@]}]: " choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#items[@]} )); then
        TB_UI_PICK="${items[$(( choice - 1 ))]}"
        return 0
    fi
    return 1
}

# tb_ui_yesno <question> [default y|n]
tb_ui_yesno() {
    local q="$1" def="${2:-y}" ans=""
    if [[ "$def" == "y" ]]; then read -r -p "   $q [Y/n]: " ans; else read -r -p "   $q [y/N]: " ans; fi
    ans="${ans:-$def}"
    [[ "$ans" =~ ^[Yy]$ ]]
}

# tb_ui_input <prompt> [default]  -> result in TB_INPUT
tb_ui_input() {
    local p="$1" def="${2:-}" ans=""
    read -r -p "   $p${def:+ [$def]}: " ans
    TB_INPUT="${ans:-$def}"
}

tb_ui_pause() {
    local msg="${1:-Press Enter to continue}"
    printf '\n'
    read -r -p "   $msg... " _ || true
}

tb_ui_clear() { printf '\033[2J\033[H'; }

# tb_ui_progress_bar <done> <total> [width]
tb_ui_progress_bar() {
    local done="$1" total="$2" width="${3:-28}"
    local pct=0 filled=0
    (( total > 0 )) && pct=$(( done * 100 / total ))
    filled=$(( pct * width / 100 ))
    local bar="" i
    for (( i = 0; i < width; i++ )); do
        if (( i < filled )); then bar+="█"; else bar+="░"; fi
    done
    printf '   %s %3d%%\n' "$bar" "$pct"
}
