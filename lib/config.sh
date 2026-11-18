#!/usr/bin/env bash
# shellcheck shell=bash
# ---------------------------------------------------------------------------
#  Termux Banner Advanced :: lib/config.sh
#  Persistent settings + safe, idempotent shell rc management.
# ---------------------------------------------------------------------------

TB_HOME="${TB_HOME:-$HOME/.termux-banner}"
TB_CONFIG_FILE="$TB_HOME/config"

# ---------------------------------------------------------------------------
#  Defaults
# ---------------------------------------------------------------------------
tb_config_defaults() {
    TB_THEME="${TB_THEME:-neon}"
    TB_ART="${TB_ART:-theme}"          # theme | custom | file
    TB_TEXT="${TB_TEXT:-TERMUX}"
    TB_FONT="${TB_FONT:-big}"
    TB_MASCOT="${TB_MASCOT:-builtin}"
    TB_MASCOT_MSG="${TB_MASCOT_MSG:-Hacking in progress}"
    TB_TITLE="${TB_TITLE:-Termux Banner}"
    TB_SUBTITLE="${TB_SUBTITLE:-Built by Faizee Asad}"
    TB_EFFECT="${TB_EFFECT:-auto}"
    TB_DIRECTION="${TB_DIRECTION:-auto}"
    TB_INFO="${TB_INFO:-1}"
    TB_WIDGETS="${TB_WIDGETS:-device,android,uptime,battery,disk,ip}"
    TB_ANIM="${TB_ANIM:-0}"
    TB_SPEED="${TB_SPEED:-1}"
    TB_CLOCK="${TB_CLOCK:-1}"
    TB_BOX="${TB_BOX:-unicode}"         # unicode | ascii
    TB_SHELLS="${TB_SHELLS:-bash}"      # space separated: bash zsh
    TB_ART_FILE="${TB_ART_FILE:-}"
    TB_PROFILE="${TB_PROFILE:-default}"
}

# ---------------------------------------------------------------------------
#  Load / save
# ---------------------------------------------------------------------------
# tb_config_load  (sets TB_CONFIG_LOADED so callers can override values
#                   afterwards without the next render wiping them)
TB_CONFIG_LOADED=0
tb_config_load() {
    tb_config_defaults
    TB_CONFIG_LOADED=1
    [[ -r "$TB_CONFIG_FILE" ]] || return 0
    local line key value
    while IFS= read -r line; do
        line="${line#"${line%%[![:space:]]*}"}"
        [[ -z "$line" ]] && continue
        [[ "${line:0:1}" == "#" ]] && continue
        [[ "$line" != *=* ]] && continue
        key="${line%%=*}"
        value="${line#*=}"
        value="${value%\"}"; value="${value#\"}"
        value="${value%\'}"; value="${value#\'}"
        case "$key" in
            TB_THEME)      TB_THEME="$value" ;;
            TB_ART)        TB_ART="$value" ;;
            TB_TEXT)       TB_TEXT="$value" ;;
            TB_FONT)       TB_FONT="$value" ;;
            TB_MASCOT)     TB_MASCOT="$value" ;;
            TB_MASCOT_MSG) TB_MASCOT_MSG="$value" ;;
            TB_TITLE)      TB_TITLE="$value" ;;
            TB_SUBTITLE)   TB_SUBTITLE="$value" ;;
            TB_EFFECT)     TB_EFFECT="$value" ;;
            TB_DIRECTION)  TB_DIRECTION="$value" ;;
            TB_INFO)       TB_INFO="$value" ;;
            TB_WIDGETS)    TB_WIDGETS="$value" ;;
            TB_ANIM)       TB_ANIM="$value" ;;
            TB_SPEED)      TB_SPEED="$value" ;;
            TB_CLOCK)      TB_CLOCK="$value" ;;
            TB_BOX)        TB_BOX="$value" ;;
            TB_SHELLS)     TB_SHELLS="$value" ;;
            TB_ART_FILE)   TB_ART_FILE="$value" ;;
            TB_PROFILE)    TB_PROFILE="$value" ;;
        esac
    done < "$TB_CONFIG_FILE"
    return 0
}

tb_config_save() {
    mkdir -p "$TB_HOME" 2>/dev/null || return 1
    cat > "$TB_CONFIG_FILE" <<EOF
# Termux Banner Advanced v${TB_VERSION} — configuration
# Edit by hand or run: t-ban.sh
TB_THEME="${TB_THEME}"
TB_ART="${TB_ART}"
TB_TEXT="${TB_TEXT}"
TB_FONT="${TB_FONT}"
TB_MASCOT="${TB_MASCOT}"
TB_MASCOT_MSG="${TB_MASCOT_MSG}"
TB_TITLE="${TB_TITLE}"
TB_SUBTITLE="${TB_SUBTITLE}"
TB_EFFECT="${TB_EFFECT}"
TB_DIRECTION="${TB_DIRECTION}"
TB_INFO="${TB_INFO}"
TB_WIDGETS="${TB_WIDGETS}"
TB_ANIM="${TB_ANIM}"
TB_SPEED="${TB_SPEED}"
TB_CLOCK="${TB_CLOCK}"
TB_BOX="${TB_BOX}"
TB_SHELLS="${TB_SHELLS}"
TB_ART_FILE="${TB_ART_FILE}"
TB_PROFILE="${TB_PROFILE}"
EOF
    chmod 600 "$TB_CONFIG_FILE" 2>/dev/null
    return 0
}

tb_config_set() {
    local key="$1" value="$2"
    case "$key" in
        theme)     TB_THEME="$value" ;;
        art)       TB_ART="$value" ;;
        text)      TB_TEXT="$value" ;;
        font)      TB_FONT="$value" ;;
        mascot)    TB_MASCOT="$value" ;;
        message)   TB_MASCOT_MSG="$value" ;;
        title)     TB_TITLE="$value" ;;
        subtitle)  TB_SUBTITLE="$value" ;;
        effect)    TB_EFFECT="$value" ;;
        direction) TB_DIRECTION="$value" ;;
        info)      TB_INFO="$value" ;;
        widgets)   TB_WIDGETS="$value" ;;
        anim)      TB_ANIM="$value" ;;
        speed)     TB_SPEED="$value" ;;
        clock)     TB_CLOCK="$value" ;;
        box)       TB_BOX="$value" ;;
        shells)    TB_SHELLS="$value" ;;
        artfile)   TB_ART_FILE="$value" ;;
        profile)   TB_PROFILE="$value" ;;
        *)         return 1 ;;
    esac
    return 0
}

# ---------------------------------------------------------------------------
#  Theme handling
# ---------------------------------------------------------------------------
TB_THEME_DIR="${TB_THEME_DIR:-}"

tb_themes_dir() {
    if [[ -n "$TB_THEME_DIR" && -d "$TB_THEME_DIR" ]]; then printf '%s' "$TB_THEME_DIR"; return 0; fi
    local d
    for d in "$TB_PROJECT_DIR/themes" "$HOME/Termux-Banner/themes" "$HOME/.termux-banner/project/themes"; do
        [[ -d "$d" ]] && { printf '%s' "$d"; return 0; }
    done
    printf '%s' "$TB_PROJECT_DIR/themes"
}

tb_theme_list() {
    local dir; dir="$(tb_themes_dir)"
    [[ -d "$dir" ]] || return 1
    local f
    for f in "$dir"/*.conf; do
        [[ -e "$f" ]] || continue
        basename "$f" .conf
    done
}

tb_theme_file() {
    local dir; dir="$(tb_themes_dir)"
    printf '%s/%s.conf' "$dir" "$1"
}

# tb_theme_load <name>  -> fills TB_TH_* variables
tb_theme_load() {
    local name="$1" file
    file="$(tb_theme_file "$name")"
    [[ -r "$file" ]] || return 1

    TB_TH_NAME="$name"
    TB_TH_LABEL="$name"
    TB_TH_DESC=""
    TB_TH_GRADIENT=""
    TB_TH_ACCENT=""
    TB_TH_DIRECTION="horizontal"
    TB_TH_EFFECT="shadow"
    TB_TH_ART=""
    TB_TH_SPEED="1"
    TB_TH_MASCOT=""
    TB_TH_BOX="unicode"

    local line key value
    while IFS= read -r line; do
        line="${line#"${line%%[![:space:]]*}"}"
        [[ -z "$line" ]] && continue
        [[ "${line:0:1}" == "#" ]] && continue
        [[ "$line" != *=* ]] && continue
        key="${line%%=*}"
        value="${line#*=}"
        value="${value%\"}"; value="${value#\"}"
        value="${value%\'}"; value="${value#\'}"
        case "$key" in
            name)       TB_TH_LABEL="$value" ;;
            label)      TB_TH_LABEL="$value" ;;
            desc)       TB_TH_DESC="$value" ;;
            gradient)   TB_TH_GRADIENT="$value" ;;
            accent)     TB_TH_ACCENT="$value" ;;
            direction)  TB_TH_DIRECTION="$value" ;;
            effect)     TB_TH_EFFECT="$value" ;;
            art)        TB_TH_ART="$value" ;;
            speed)      TB_TH_SPEED="$value" ;;
            mascot)     TB_TH_MASCOT="$value" ;;
            box)        TB_TH_BOX="$value" ;;
        esac
    done < "$file"
    return 0
}

# ---------------------------------------------------------------------------
#  Shell rc management (marker based - never destroys an existing file)
# ---------------------------------------------------------------------------
tb_rc_path() {
    case "$1" in
        bash) printf '%s' "${PREFIX:-$HOME}/etc/bash.bashrc" ;;
        zsh)  printf '%s' "${PREFIX:-$HOME}/etc/zshrc" ;;
        *)    printf '' ;;
    esac
}

tb_rc_installed() {
    local shell="$1" file; file="$(tb_rc_path "$shell")"
    [[ -f "$file" ]] && grep -qF "$TB_MARK_BEGIN" "$file" 2>/dev/null
}

tb_rc_backup() {
    local file="$1"
    [[ -f "$file" ]] || return 0
    cp -f "$file" "$file.tbbak" 2>/dev/null
}

tb_rc_remove_block() {
    local file="$1"
    [[ -f "$file" ]] || return 0
    local -a kept=()
    local line skip=0
    while IFS= read -r line || [[ -n "$line" ]]; do
        if (( skip )); then
            [[ "$line" == "$TB_MARK_END" ]] && skip=0
            continue
        fi
        if [[ "$line" == "$TB_MARK_BEGIN" ]]; then
            skip=1
            continue
        fi
        kept+=("$line")
    done < "$file"
    if (( ${#kept[@]} == 0 )); then
        : > "$file"
    else
        printf '%s\n' "${kept[@]}" > "$file"
    fi
}

tb_rc_write_block() {
    local file="$1"
    mkdir -p "$(dirname "$file")" 2>/dev/null
    tb_rc_backup "$file"
    tb_rc_remove_block "$file"
    {
        printf '%s\n' "$TB_MARK_BEGIN"
        printf '# %s v%s — managed block, edit with `t-ban.sh`\n' "$TB_TITLE" "$TB_VERSION"
        printf '[ -r "$HOME/.termux-banner/boot.sh" ] && . "$HOME/.termux-banner/boot.sh"\n'
        printf '%s\n' "$TB_MARK_END"
    } >> "$file"
}

tb_rc_uninstall() {
    local shell
    for shell in bash zsh; do
        local file; file="$(tb_rc_path "$shell")"
        tb_rc_remove_block "$file"
    done
}

# ---------------------------------------------------------------------------
#  Boot script (installed into ~/.termux-banner/boot.sh)
# ---------------------------------------------------------------------------
tb_install_boot_script() {
    local project_dir="$1"
    mkdir -p "$TB_HOME" 2>/dev/null || return 1
    cat > "$TB_HOME/boot.sh" <<EOF
#!/usr/bin/env bash
# Termux Banner Advanced v${TB_VERSION} — shell startup hook (auto generated)
TB_PROJECT_DIR="\${TB_PROJECT_DIR:-$project_dir}"
if [ ! -r "\$TB_PROJECT_DIR/lib/render.sh" ]; then
  for _d in "\$HOME/Termux-Banner" "\$HOME/.termux-banner/project" "\$HOME/termux-banner"; do
    if [ -r "\$_d/lib/render.sh" ]; then TB_PROJECT_DIR="\$_d"; break; fi
  done
fi
if [ -r "\$TB_PROJECT_DIR/lib/core.sh" ]; then
  . "\$TB_PROJECT_DIR/lib/core.sh"
  . "\$TB_PROJECT_DIR/lib/render.sh"
  . "\$TB_PROJECT_DIR/lib/fonts.sh"
  . "\$TB_PROJECT_DIR/lib/sysinfo.sh"
  . "\$TB_PROJECT_DIR/lib/config.sh"
  . "\$TB_PROJECT_DIR/lib/loader.sh" 2>/dev/null
  tb_render_banner 2>/dev/null
fi
unset _d
EOF
    chmod +x "$TB_HOME/boot.sh" 2>/dev/null
    return 0
}
