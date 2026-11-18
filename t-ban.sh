#!/usr/bin/env bash
# shellcheck shell=bash
# ---------------------------------------------------------------------------
#  Termux Banner Advanced :: t-ban.sh
#
#  Interactive banner configurator.
#
#      bash t-ban.sh              interactive menu
#      bash t-ban.sh --quick      ask two questions and apply (legacy flow)
#      bash t-ban.sh --set k=v    non interactive configuration
# ---------------------------------------------------------------------------

TB_BANNER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
export TB_PROJECT_DIR="${TB_PROJECT_DIR:-$TB_BANNER_DIR}"

for tb_f in core render fonts fonts-data sysinfo config loader ui; do
    # shellcheck source=/dev/null
    [ -r "$TB_PROJECT_DIR/lib/$tb_f.sh" ] && . "$TB_PROJECT_DIR/lib/$tb_f.sh"
done
[ -r "$TB_PROJECT_DIR/lib/fonts-data.sh" ] || . "$TB_PROJECT_DIR/lib/fonts-data.sh"

TB_UI_RESET=$'\033[0m'
TB_UI_DIM=$'\033[2;38;5;245m'
TB_UI_ACCENT=$'\033[1;38;2;0;245;255m'

# ---------------------------------------------------------------------------
#  helpers
# ---------------------------------------------------------------------------
tb_current_theme_label() {
    tb_theme_load "$TB_THEME" 2>/dev/null && printf '%s' "$TB_TH_LABEL" || printf '%s' "$TB_THEME"
}

tb_apply() {
    tb_config_save
    tb_install_boot_script "$TB_PROJECT_DIR"
    local sh
    for sh in $TB_SHELLS; do
        local rc; rc="$(tb_rc_path "$sh")"
        [[ -n "$rc" ]] && tb_rc_write_block "$rc"
    done
}

tb_preview() {
    tb_ui_clear
    tb_render_banner
    printf '\n'
}

# ---------------------------------------------------------------------------
#  sub menus
# ---------------------------------------------------------------------------
menu_theme() {
    while :; do
        tb_ui_clear
        tb_ui_header "THEME  —  current: $(tb_current_theme_label)"
        local -a names=() labels=() descs=()
        local t
        while IFS= read -r t; do
            [ -z "$t" ] && continue
            tb_theme_load "$t" 2>/dev/null || continue
            names+=("$t")
            labels+=("$TB_TH_LABEL")
            descs+=("$TB_TH_DESC")
        done < <(tb_theme_list)

        local i
        for (( i = 0; i < ${#names[@]}; i++ )); do
            printf '   %s%2d%s) %-16s %s%s%s\n' \
                "$TB_UI_DIM" $(( i + 1 )) "$TB_UI_RESET" "${labels[i]}" "$TB_UI_DIM" "${descs[i]}" "$TB_UI_RESET"
        done
        printf '\n'
        read -r -p "   Theme number (Enter = back): " pick
        [ -z "$pick" ] && return 0
        if [[ "$pick" =~ ^[0-9]+$ ]] && (( pick >= 1 && pick <= ${#names[@]} )); then
            TB_THEME="${names[$(( pick - 1 ))]}"
            tb_theme_load "$TB_THEME"
            tb_ui_set_accent "$TB_TH_ACCENT"
            TB_GRADIENT="$TB_TH_GRADIENT"
            TB_DIRECTION="$TB_TH_DIRECTION"
            TB_EFFECT="$TB_TH_EFFECT"
            tb_ui_clear
            tb_render_preview "$TB_THEME"
            printf '\n'
            if tb_ui_yesno "   Use this theme?" "y"; then
                tb_config_save
                tb_ui_ok "Theme set to $TB_THEME"
                tb_ui_pause
            fi
        else
            tb_ui_error "Invalid selection"
        fi
    done
}

menu_art() {
    while :; do
        tb_ui_clear
        tb_ui_header "BANNER CONTENT"
        printf '   current mode : %s\n' "$TB_ART"
        printf '   current text : %s\n' "$TB_TEXT"
        printf '\n'
        tb_ui_menu "Source" \
            "Use the theme's built-in ASCII art" \
            "Custom text rendered with an ASCII font" \
            "Load a custom .txt ASCII art file" \
            "Back"
        case "$TB_UI_CHOICE" in
            1) TB_ART="theme"; tb_config_save; tb_ui_ok "Using theme art"; tb_ui_pause ;;
            2) TB_ART="custom"
               tb_ui_input "Banner text" "$TB_TEXT"
               TB_TEXT="$TB_INPUT"
               tb_config_save
               tb_ui_ok "Custom text set"; tb_ui_pause ;;
            3) TB_ART="file"
               tb_ui_input "Path to ASCII art file" "$TB_ART_FILE"
               TB_ART_FILE="$TB_INPUT"
               tb_config_save
               tb_ui_ok "Custom file set"; tb_ui_pause ;;
            4|0) return 0 ;;
        esac
    done
}

menu_font() {
    while :; do
        tb_ui_clear
        tb_ui_header "ASCII FONT  —  current: $TB_FONT"
        local -a fonts=()
        local f
        while IFS= read -r f; do [ -n "$f" ] && fonts+=("$f"); done < <(tb_font_list)
        local i
        for (( i = 0; i < ${#fonts[@]} && i < 40; i++ )); do
            printf '   %s%2d%s) %s\n' "$TB_UI_DIM" $(( i + 1 )) "$TB_UI_RESET" "${fonts[i]}"
        done
        printf '\n'
        read -r -p "   Font number (Enter = back): " pick
        [ -z "$pick" ] && return 0
        if [[ "$pick" =~ ^[0-9]+$ ]] && (( pick >= 1 && pick <= ${#fonts[@]} )); then
            TB_FONT="${fonts[$(( pick - 1 ))]}"
            TB_ART="${TB_ART:-custom}"
            tb_config_save
            tb_ui_clear
            printf '\n'
            tb_render_art "$(tb_text_to_ascii_safe "Faizee" "$TB_FONT")" "horizontal" "shadow"
            printf '\n'
            tb_ui_pause
        fi
    done
}

menu_effect() {
    while :; do
        tb_ui_clear
        tb_ui_header "EFFECT & DIRECTION"
        printf '   effect    : %s\n' "$TB_EFFECT"
        printf '   direction : %s\n' "$TB_DIRECTION"
        printf '\n'
        tb_ui_menu "Effect style" \
            "auto     (follow the theme)" \
            "plain    (clean gradient, no shadow)" \
            "shadow   (drop shadow behind the art)" \
            "chrome   (metallic vertical chrome)" \
            "outline  (outlined stroke around the art)" \
            "Back"
        case "$TB_UI_CHOICE" in
            1) TB_EFFECT="auto" ;;
            2) TB_EFFECT="plain" ;;
            3) TB_EFFECT="shadow" ;;
            4) TB_EFFECT="chrome" ;;
            5) TB_EFFECT="outline" ;;
            6|0) return 0 ;;
        esac
        tb_ui_menu "Gradient direction" \
            "auto       (follow the theme)" \
            "horizontal (left to right)" \
            "vertical   (top to bottom)" \
            "diagonal   (corner to corner)" \
            "Back"
        case "$TB_UI_CHOICE" in
            1) TB_DIRECTION="auto" ;;
            2) TB_DIRECTION="horizontal" ;;
            3) TB_DIRECTION="vertical" ;;
            4) TB_DIRECTION="diagonal" ;;
            5|0) ;;
        esac
        tb_config_save
    done
}

menu_info() {
    while :; do
        tb_ui_clear
        tb_ui_header "SYSTEM INFO PANEL"
        printf '   enabled : %s\n' "$TB_INFO"
        printf '   widgets : %s\n' "$TB_WIDGETS"
        printf '\n'
        tb_ui_menu "Info panel" \
            "Enable / disable the system info panel" \
            "Choose the widgets to show" \
            "Back"
        case "$TB_UI_CHOICE" in
            1)
                if tb_ui_yesno "   Show the system info panel?" "$( [[ "$TB_INFO" == "1" ]] && echo y || echo n )"; then
                    TB_INFO="1"; else TB_INFO="0"; fi
                tb_config_save ;;
            2)
                local -a all=() avail=(user host device android kernel termux uptime battery disk ram ip cpu shell date time packages)
                local w
                for w in "${avail[@]}"; do
                    case " $TB_WIDGETS " in *" $w "*) all+=("[x] $w") ;; *) all+=("[ ] $w") ;; esac
                done
                tb_ui_menu "Available widgets" "${all[@]}" "Back"
                if [[ "$TB_UI_CHOICE" =~ ^[0-9]+$ ]] && (( TB_UI_CHOICE <= ${#avail[@]} )); then
                    local chosen="${avail[$(( TB_UI_CHOICE - 1 ))]}"
                    case " $TB_WIDGETS " in
                        *" $chosen "*) TB_WIDGETS="${TB_WIDGETS// $chosen / }" ;;
                        *) TB_WIDGETS="$TB_WIDGETS,$chosen" ;;
                    esac
                    TB_WIDGETS="${TB_WIDGETS#,}"; TB_WIDGETS="${TB_WIDGETS%,}"
                    tb_config_save
                fi ;;
            3|0) return 0 ;;
        esac
    done
}

menu_mascot() {
    while :; do
        tb_ui_clear
        tb_ui_header "MASCOT"
        printf '   mascot : %s\n' "$TB_MASCOT"
        printf '   message: %s\n' "$TB_MASCOT_MSG"
        printf '\n'
        tb_ui_menu "Mascot" \
            "none   (no mascot)" \
            "builtin (built-in ASCII mascots)" \
            "eyes   (cowsay)" \
            "tux    (cowsay)" \
            "custom message" \
            "Back"
        case "$TB_UI_CHOICE" in
            1) TB_MASCOT="none" ;;
            2) TB_MASCOT="builtin" ;;
            3) TB_MASCOT="eyes" ;;
            4) TB_MASCOT="tux" ;;
            5) tb_ui_input "Mascot message" "$TB_MASCOT_MSG"; TB_MASCOT_MSG="$TB_INPUT" ;;
            6|0) return 0 ;;
        esac
        tb_config_save
    done
}

menu_text() {
    tb_ui_clear
    tb_ui_header "TITLE & SUBTITLE"
    tb_ui_input "Title" "$TB_TITLE";     TB_TITLE="$TB_INPUT"
    tb_ui_input "Subtitle" "$TB_SUBTITLE"; TB_SUBTITLE="$TB_INPUT"
    tb_ui_input "Clock line (y/n)" "$( [[ "$TB_CLOCK" == "1" ]] && echo y || echo n )"
    if [[ "$TB_INPUT" =~ ^[Yy]$ ]]; then TB_CLOCK="1"; else TB_CLOCK="0"; fi
    tb_config_save
    tb_ui_ok "Saved"
}

menu_shell() {
    tb_ui_clear
    tb_ui_header "SHELL INTEGRATION"
    printf '   installed for: %s\n' "$TB_SHELLS"
    printf '\n'
    tb_ui_menu "Shell" \
            "bash  (.bashrc)" \
            "zsh   (.zshrc)" \
            "both" \
            "Back"
    case "$TB_UI_CHOICE" in
        1) TB_SHELLS="bash" ;;
        2) TB_SHELLS="zsh" ;;
        3) TB_SHELLS="bash zsh" ;;
        4|0) return 0 ;;
    esac
    tb_config_save
}

menu_reset() {
    tb_ui_clear
    tb_ui_header "RESET"
    tb_ui_menu "Reset" \
        "Reset the configuration to defaults" \
        "Back"
    if [[ "$TB_UI_CHOICE" == "1" ]]; then
        TB_THEME="neon"; TB_ART="theme"; TB_TEXT="TERMUX"; TB_FONT="big"
        TB_MASCOT="builtin"; TB_MASCOT_MSG="Hacking in progress"
        TB_TITLE="Termux Banner"; TB_SUBTITLE="Security help for ethical hackers"
        TB_EFFECT="shadow"; TB_DIRECTION="horizontal"
        TB_INFO="1"; TB_WIDGETS="device,android,uptime,battery,disk,ip"
        TB_CLOCK="1"; TB_BOX="unicode"
        tb_config_save
        tb_ui_ok "Configuration reset"
        tb_ui_pause
    fi
}

menu_uninstall() {
    tb_ui_clear
    tb_ui_header "UNINSTALL"
    tb_ui_info "This removes the banner hooks from .bashrc / .zshrc"
    tb_ui_info "and restores your original prompt."
    printf '\n'
    if tb_ui_yesno "   Continue?" "n"; then
        tb_rc_uninstall
        tb_ui_ok "Banner removed from shell rc files"
    else
        tb_ui_info "Cancelled"
    fi
    tb_ui_pause
}

# ---------------------------------------------------------------------------
#  quick (legacy) mode
# ---------------------------------------------------------------------------
quick_mode() {
    tb_ui_clear
    tb_ui_header "QUICK SETUP"
    tb_ui_input "Banner text" "TERMUX"
    TB_TEXT="$TB_INPUT"
    TB_ART="custom"
    tb_ui_input "Mascot message" "Hacking in progress"
    TB_MASCOT_MSG="$TB_INPUT"
    tb_config_save
    tb_apply
    tb_ui_clear
    tb_render_banner
    printf '\n'
    tb_ui_ok "Banner installed — open a new shell to see it."
}

# ---------------------------------------------------------------------------
#  main menu
# ---------------------------------------------------------------------------
main_menu() {
    while :; do
        tb_ui_clear
        tb_ui_header "$TB_TITLE  v$TB_VERSION"
        printf '   %-22s %s\n' "Theme" "$(tb_current_theme_label)"
        printf '   %-22s %s\n' "Content" "$TB_ART"
        printf '   %-22s %s\n' "Text" "$TB_TEXT"
        printf '   %-22s %s\n' "Font" "$TB_FONT"
        printf '   %-22s %s\n' "Effect" "$TB_EFFECT / $TB_DIRECTION"
        printf '   %-22s %s\n' "Info panel" "$( [[ "$TB_INFO" == "1" ]] && echo "on  ($TB_WIDGETS)" || echo off )"
        printf '   %-22s %s\n' "Mascot" "$TB_MASCOT"
        printf '   %-22s %s\n' "Shell" "$TB_SHELLS"
        printf '\n'
        tb_ui_menu "Main menu" \
            "Change theme" \
            "Change banner content" \
            "Change ASCII font" \
            "Change effect / direction" \
            "System info panel" \
            "Mascot" \
            "Title / subtitle / clock" \
            "Shell integration" \
            "Preview banner" \
            "Save and apply to shell" \
            "Reset to defaults" \
            "Uninstall banner" \
            "Exit"
        case "$TB_UI_CHOICE" in
            1)  menu_theme ;;
            2)  menu_art ;;
            3)  menu_font ;;
            4)  menu_effect ;;
            5)  menu_info ;;
            6)  menu_mascot ;;
            7)  menu_text ;;
            8)  menu_shell ;;
            9)  tb_preview ;;
            10) tb_apply
                tb_ui_clear
                tb_render_banner
                printf '\n'
                tb_ui_ok "Saved and applied to: $TB_SHELLS"
                tb_ui_pause ;;
            11) menu_reset ;;
            12) menu_uninstall ;;
            13|0) tb_ui_info "Bye!"; return 0 ;;
        esac
    done
}

# ---------------------------------------------------------------------------
#  entry point
# ---------------------------------------------------------------------------
tb_config_load
tb_theme_load "$TB_THEME" 2>/dev/null && tb_ui_set_accent "$TB_TH_ACCENT"

case "${1:-}" in
    --quick|-q)
        quick_mode ;;
    --set)
        key="${2%%=*}"; val="${2#*=}"
        if tb_config_set "$key" "$val"; then
            tb_config_save
            printf 'saved: %s=%s\n' "$key" "$val"
        else
            printf 'unknown setting: %s\n' "$key" >&2
            exit 1
        fi ;;
    --help|-h)
        sed -n '2,20p' "$0" ;;
    --version|-v)
        printf '%s v%s\n' "$TB_TITLE" "$TB_VERSION" ;;
    *)
        if [ ! -t 0 ]; then
            printf 't-ban.sh: no terminal detected.\n'
            printf 'Use: bash t-ban.sh --quick   or   bash t-ban.sh --set theme=neon\n'
            exit 0
        fi
        main_menu ;;
esac
