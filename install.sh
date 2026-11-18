#!/usr/bin/env bash
# shellcheck shell=bash
# ---------------------------------------------------------------------------
#  Termux Banner Advanced :: install.sh
#
#  One command installer:
#      bash install.sh
#
#  What it does
#    1. installs the optional dependencies (toilet / figlet / cowsay / lolcat)
#    2. writes ~/.termux-banner/boot.sh  (the shell startup hook)
#    3. adds a managed block to .bashrc and/or .zshrc  (your file is never
#       overwritten - the old block is removed and a backup is kept)
#    4. installs the `tb` command into $PREFIX/bin
# ---------------------------------------------------------------------------

TB_INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
export TB_PROJECT_DIR="$TB_INSTALL_DIR"

for tb_f in core render fonts fonts-data sysinfo config loader ui; do
    [ -r "$TB_INSTALL_DIR/lib/$tb_f.sh" ] && . "$TB_INSTALL_DIR/lib/$tb_f.sh"
done
[ -r "$TB_INSTALL_DIR/lib/fonts-data.sh" ] || . "$TB_INSTALL_DIR/lib/fonts-data.sh"

tb_install_print() { printf '  \033[1;36m▸\033[0m %s\n' "$1"; }
tb_install_ok()    { printf '  \033[1;32m✔\033[0m %s\n' "$1"; }
tb_install_fail()  { printf '  \033[1;31m✖\033[0m %s\n' "$1"; }

printf '\n  \033[1;36mTermux Banner Advanced\033[0m v%s — installer\n\n' "${TB_VERSION:-2.0.0}"

# ---- 1. dependencies --------------------------------------------------------
if [ "${TB_SKIP_DEPS:-0}" != "1" ]; then
    if [ -r "$TB_INSTALL_DIR/setup.sh" ]; then
        bash "$TB_INSTALL_DIR/setup.sh" || true
    fi
else
    tb_install_print "Skipping dependency installation (TB_SKIP_DEPS=1)"
fi

# ---- 2. configuration -------------------------------------------------------
mkdir -p "$TB_HOME" 2>/dev/null
if [ ! -f "$TB_CONFIG_FILE" ]; then
    tb_config_defaults
    tb_config_save && tb_install_ok "Created $TB_CONFIG_FILE"
else
    tb_install_print "Keeping your existing configuration"
fi

# ---- 3. boot script ---------------------------------------------------------
tb_install_boot_script "$TB_INSTALL_DIR" && tb_install_ok "Installed ~/.termux-banner/boot.sh"

# ---- 4. shell hooks ---------------------------------------------------------
tb_config_load
for tb_shell in $TB_SHELLS; do
    tb_rc="$(tb_rc_path "$tb_shell")"
    if [ -z "$tb_rc" ]; then continue; fi
    tb_rc_write_block "$tb_rc"
    tb_install_ok "Hook installed in $tb_rc (backup: $tb_rc.tbbak)"
done

# ---- 5. the tb command ------------------------------------------------------
tb_bin="${PREFIX:-$HOME}/bin"
mkdir -p "$tb_bin" 2>/dev/null
cat > "$tb_bin/tb" <<EOF
#!/usr/bin/env bash
# Termux Banner Advanced - command line entry point (auto generated)
export TB_BANNER_HOME="$TB_INSTALL_DIR"
exec bash "$TB_INSTALL_DIR/bin/tb" "\$@"
EOF
chmod +x "$tb_bin/tb" 2>/dev/null && tb_install_ok "Installed $tb_bin/tb"

# ---- 6. done ----------------------------------------------------------------
printf '\n'
tb_install_ok "Installation complete"
printf '\n  Start a new shell (or run \033[1;36msource ~/.bashrc\033[0m) to see the banner.\n'
printf '  Configure it with \033[1;36mbash t-ban.sh\033[0m   ·   preview with \033[1;36mtb\033[0m\n'
printf '  Remove it again with \033[1;36mbash remove.sh\033[0m\n\n'
