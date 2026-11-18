#!/usr/bin/env bash
# shellcheck shell=bash
# ---------------------------------------------------------------------------
#  Termux Banner Advanced :: lib/render.sh
#  ASCII art renderer with gradients, drop shadows and framed info panels.
# ---------------------------------------------------------------------------

# Globals used by the renderer
TB_RENDER_SHADOW_SHIFT=2
TB_RENDER_GLOBAL_OFFSET=0

# ---------------------------------------------------------------------------
#  tb_render_art <art-block> [direction] [effect] [shadow-hex]
#
#  direction : horizontal | vertical | diagonal
#  effect    : plain | shadow | chrome | outline
#
#  Prints the art straight to stdout.
# ---------------------------------------------------------------------------
tb_render_art() {
    local block="$1"
    local direction="${2:-horizontal}"
    local effect="${3:-plain}"
    local shadow_hex="${4:-0B0B18}"

    local -a lines=()
    mapfile -t lines <<< "$block"
    local rows=${#lines[@]}
    (( rows == 0 )) && return 0

    local maxw=0 li l
    for (( li = 0; li < rows; li++ )); do
        l="${lines[li]}"
        (( ${#l} > maxw )) && maxw=${#l}
    done
    (( maxw == 0 )) && return 0

    local shadow_code="" line ch sh cidx last_code="" out
    if [[ "$effect" == "shadow" || "$effect" == "chrome" || "$effect" == "outline" ]]; then
        shadow_code="$(tb_rgb 11 11 24)"
    fi

    for (( li = 0; li < rows; li++ )); do
        line="${lines[li]}"
        out=""
        last_code=""
        for (( c = 0; c < maxw; c++ )); do
            ch="${line:c:1}"
            [[ -z "$ch" ]] && ch=" "

            # gradient index for this cell
            case "$direction" in
                vertical)
                    (( rows > 1 )) && cidx=$(( li * 255 / (rows - 1) )) || cidx=0
                    ;;
                diagonal)
                    (( maxw + rows > 2 )) && cidx=$(( (c + li) * 255 / (maxw + rows - 2) )) || cidx=0
                    ;;
                *)
                    (( maxw > 1 )) && cidx=$(( c * 255 / (maxw - 1) )) || cidx=0
                    ;;
            esac
            cidx=$(( (cidx + TB_RENDER_GLOBAL_OFFSET) % 256 ))

            local code="${TB_GRAD[cidx]}"
            local glyph="$ch"

            if [[ "$effect" == "shadow" || "$effect" == "chrome" ]]; then
                if [[ "$ch" == " " ]]; then
                    if (( c >= TB_RENDER_SHADOW_SHIFT )); then
                        sh="${line:c-TB_RENDER_SHADOW_SHIFT:1}"
                        [[ "$sh" == " " || -z "$sh" ]] && sh=""
                    else
                        sh=""
                    fi
                    if [[ -n "$sh" ]]; then
                        glyph="$sh"
                        code="$shadow_code"
                    fi
                fi
            elif [[ "$effect" == "outline" ]]; then
                if [[ "$ch" == " " ]]; then
                    local up="" dn="" lft="" rgt=""
                    (( li > 0 ))        && up="${lines[li-1]:c:1}"
                    (( li < rows - 1 )) && dn="${lines[li+1]:c:1}"
                    (( c > 0 ))         && lft="${line:c-1:1}"
                    (( c < maxw - 1 ))  && rgt="${line:c+1:1}"
                    if [[ "$up" != " " && -n "$up" ]]; then glyph="$up"
                    elif [[ "$dn" != " " && -n "$dn" ]]; then glyph="$dn"
                    elif [[ "$lft" != " " && -n "$lft" ]]; then glyph="$lft"
                    elif [[ "$rgt" != " " && -n "$rgt" ]]; then glyph="$rgt"
                    else glyph=""
                    fi
                    [[ -n "$glyph" ]] && code="$shadow_code"
                fi
            fi

            if [[ "$code" != "$last_code" ]]; then
                out+="$code"
                last_code="$code"
            fi
            out+="$glyph"
        done
        printf '%s\n' "$(tb_rtrim "$out")"
    done
}

# ---------------------------------------------------------------------------
#  tb_render_solid <text> <hex> [bold]
# ---------------------------------------------------------------------------
tb_render_solid() {
    local text="$1" hex="${2:-FFFFFF}" bold="${3:-0}"
    local r g b
    read -r r g b <<< "$(tb_hex_to_rgb "$hex")"
    [[ "$bold" == "1" ]] && printf '\033[1m'
    tb_rgb "$r" "$g" "$b"
    printf '%s' "$text"
    tb_reset
}

# ---------------------------------------------------------------------------
#  tb_render_gradient_text <text> [stops]
#  Short one-liner (taglines, titles) painted with the active gradient.
# ---------------------------------------------------------------------------
tb_render_gradient_text() {
    local text="$1" stops="${2:-}"
    local -a chars=()
    local i c len=${#text} out="" idx last=""
    for (( i = 0; i < len; i++ )); do
        c="${text:i:1}"
        (( len > 1 )) && idx=$(( i * 255 / (len - 1) )) || idx=0
        local code="${TB_GRAD[idx]}"
        if [[ "$code" != "$last" ]]; then out+="$code"; last="$code"; fi
        out+="$c"
    done
    printf '%s' "$out"
}

# ---------------------------------------------------------------------------
#  Box drawing helpers
# ---------------------------------------------------------------------------
TB_BOX_STYLE="${TB_BOX_STYLE:-unicode}"

# tb_box_chars -> fills the individual box drawing characters.
# They are kept in separate variables on purpose: slicing a multi byte
# string by index breaks when the locale is not UTF-8.
tb_box_chars() {
    if [[ "$TB_BOX_STYLE" == "ascii" ]] || ! tb_is_utf8; then
        TB_BX_TL="+"; TB_BX_HM="-"; TB_BX_TR="+"; TB_BX_VM="|"
        TB_BX_BL="+"; TB_BX_BM="-"; TB_BX_BR="+"
        TB_BX_ML="+"; TB_BX_MR="+"
        TB_BOX_STYLE="ascii"
    else
        TB_BX_TL="┌"; TB_BX_HM="─"; TB_BX_TR="┐"; TB_BX_VM="│"
        TB_BX_BL="└"; TB_BX_BM="─"; TB_BX_BR="┘"
        TB_BX_ML="├"; TB_BX_MR="┤"
    fi
}

# tb_box_line <inner-width> -> horizontal rule
tb_box_rule() {
    local w="$1"
    tb_box_chars
    tb_repeat "$TB_BX_HM" "$w"
}

tb_box_top() {
    local w="$1" title="${2:-}"
    tb_box_chars
    if [[ -n "$title" ]]; then
        local rest=$(( w - ${#title} - 3 ))
        (( rest < 0 )) && rest=0
        printf '%s%s %s %s%s\n' "$TB_BX_TL" "$TB_BX_HM" "$title" "$(tb_repeat "$TB_BX_HM" "$rest")" "$TB_BX_TR"
    else
        printf '%s%s%s\n' "$TB_BX_TL" "$(tb_repeat "$TB_BX_HM" "$w")" "$TB_BX_TR"
    fi
}

tb_box_bottom() {
    local w="$1"
    tb_box_chars
    printf '%s%s%s\n' "$TB_BX_BL" "$(tb_repeat "$TB_BX_BM" "$w")" "$TB_BX_BR"
}

tb_box_mid() {
    local w="$1"
    tb_box_chars
    printf '%s%s%s\n' "$TB_BX_ML" "$(tb_repeat "$TB_BX_HM" "$w")" "$TB_BX_MR"
}

tb_box_row() {
    local content="$1" w="$2"
    tb_box_chars
    printf '%s %s %s\n' "$TB_BX_VM" "$(tb_pad "$content" "$w")" "$TB_BX_VM"
}

# ---------------------------------------------------------------------------
#  tb_render_panel <title> <body-block> [width]
#  Draws a framed panel around a block of text.
# ---------------------------------------------------------------------------
tb_render_panel() {
    local title="$1" body="$2" width="${3:-$(tb_term_width)}"
    local inner=$(( width - 4 ))
    (( inner < 20 )) && inner=20

    tb_box_top $(( inner + 2 )) "$title"
    local -a rows=()
    mapfile -t rows <<< "$body"
    local r
    for r in "${rows[@]}"; do
        tb_box_row "$r" "$inner"
    done
    tb_box_bottom $(( inner + 2 ))
}

# ---------------------------------------------------------------------------
#  Built-in mascots (used when cowsay is not installed)
# ---------------------------------------------------------------------------
tb_mascot_builtin() {
    case "$1" in
        builtin|robot)
            cat <<'EOF'
      .-----------.
      |  o     o   |
      |     ^     |
      |  '-----'  |
      |   |   |   |
      '-----------'
EOF
            ;;
        eyes)
            cat <<'EOF'
        .-------.
      .'  o   o  '.
     (      __      )
      '.  /  \  .'
        '------'
EOF
            ;;
        ghost)
            cat <<'EOF'
           .-""-.
          / o   o \
         |    __    |
         |   (__)   |
          \        /
           '-.__.-'
EOF
            ;;
        hacker)
            cat <<'EOF'
        .-====-.
       /  o  o  \
      |   /|\    |
      |  / | \   |
       \  |_|  /
        '-.__.-'
EOF
            ;;
        *)
            cat <<'EOF'
        .-------.
        |  >__<  |
        |  (oo)  |
        '-------'
EOF
            ;;
    esac
}

# tb_render_mascot <name> <message>
tb_render_mascot() {
    local name="$1" msg="$2"
    if tb_has cowsay && [[ "$name" != "builtin" ]]; then
        local out
        out="$(cowsay -f "$name" "$msg" 2>/dev/null)" && [[ -n "$out" ]] && { printf '%s\n' "$out"; return 0; }
    fi
    local art
    art="$(tb_mascot_builtin "$name")"
    printf '%s\n' "$art"
    printf ' %s\n' "$msg"
}

# ---------------------------------------------------------------------------
#  tb_rule [width] [char] [hex]
# ---------------------------------------------------------------------------
tb_rule() {
    local width="${1:-$(tb_term_width)}" ch="${2:-─}" hex="${3:-333355}"
    local r g b
    read -r r g b <<< "$(tb_hex_to_rgb "$hex")"
    tb_rgb "$r" "$g" "$b"
    tb_repeat "$ch" "$width"
    tb_reset
    printf '\n'
}
