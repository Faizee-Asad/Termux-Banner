#!/usr/bin/env bash
# shellcheck shell=bash
# ---------------------------------------------------------------------------
#  Termux Banner Advanced :: setup.sh
#
#  Installs the optional dependencies used by the fancy renderer:
#    toilet / figlet  -> extra ASCII fonts
#    cowsay          -> mascot characters
#    lolcat          -> rainbow dithering on the final output
#
#  The banner itself works without any of these - they only add extras.
# ---------------------------------------------------------------------------

TB_SETUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"

printf '\n  \033[1;36mTermux Banner Advanced\033[0m — dependency setup\n\n'

tb_setup_pkg_install() {
    local pkgs=("$@")
    if command -v pkg >/dev/null 2>&1; then
        printf '  \033[1;33m▸\033[0m Installing: %s\n' "${pkgs[*]}"
        pkg update -y >/dev/null 2>&1
        pkg install -y "${pkgs[@]}" >/dev/null 2>&1
        return $?
    fi
    if command -v apt-get >/dev/null 2>&1; then
        printf '  \033[1;33m▸\033[0m Installing: %s\n' "${pkgs[*]}"
        if [ "$(id -u)" = "0" ]; then
            apt-get update -y >/dev/null 2>&1
            apt-get install -y "${pkgs[@]}" >/dev/null 2>&1
        else
            sudo apt-get update -y >/dev/null 2>&1
            sudo apt-get install -y "${pkgs[@]}" >/dev/null 2>&1
        fi
        return $?
    fi
    if command -v brew >/dev/null 2>&1; then
        printf '  \033[1;33m▸\033[0m Installing: %s\n' "${pkgs[*]}"
        brew install "${pkgs[@]}" >/dev/null 2>&1
        return $?
    fi
    printf '  \033[1;31m✖\033[0m No supported package manager found (pkg / apt-get / brew)\n'
    return 1
}

tb_setup_gem_install() {
    if command -v gem >/dev/null 2>&1; then
        printf '  \033[1;33m▸\033[0m Installing: lolcat (gem)\n'
        gem install lolcat >/dev/null 2>&1 && return 0
    fi
    return 1
}

# ---- fonts -----------------------------------------------------------------
tb_setup_pkg_install toilet figlet || true

# ---- mascot ----------------------------------------------------------------
tb_setup_pkg_install cowsay || true

# ---- colour dither ---------------------------------------------------------
if command -v lolcat >/dev/null 2>&1; then
    printf '  \033[1;32m✔\033[0m lolcat already installed\n'
else
    tb_setup_gem_install || tb_setup_pkg_install ruby || true
fi

printf '\n'
for tool in toilet figlet cowsay lolcat; do
    if command -v "$tool" >/dev/null 2>&1; then
        printf '  \033[1;32m✔\033[0m %-10s %s\n' "$tool" "$(command -v "$tool")"
    else
        printf '  \033[1;33m!\033[0m %-10s not installed (optional)\n' "$tool"
    fi
done

printf '\n  \033[1;32mSetup complete.\033[0m Run: \033[1;36mbash t-ban.sh\033[0m\n\n'
