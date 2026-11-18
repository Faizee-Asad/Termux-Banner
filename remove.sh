#!/usr/bin/env bash
# shellcheck shell=bash
# ---------------------------------------------------------------------------
#  Termux Banner Advanced :: remove.sh
#
#  Clean uninstall.
#
#    * removes the managed block from .bashrc / .zshrc (your file is kept!)
#    * restores the prompt when the backup is still available
#    * removes ~/.termux-banner/boot.sh and the `tb` command
#
#  NOTE: the original v1 script of this project overwrote your whole .bashrc.
#  This version only touches the block it owns, so nothing else is lost.
# ---------------------------------------------------------------------------

TB_REMOVE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
export TB_PROJECT_DIR="$TB_REMOVE_DIR"

for tb_f in core config; do
    [ -r "$TB_REMOVE_DIR/lib/$tb_f.sh" ] && . "$TB_REMOVE_DIR/lib/$tb_f.sh"
done

tb_rm_print() { printf '  \033[1;36m▸\033[0m %s\n' "$1"; }
tb_rm_ok()    { printf '  \033[1;32m✔\033[0m %s\n' "$1"; }
tb_rm_warn()  { printf '  \033[1;33m!\033[0m %s\n' "$1"; }

printf '\n  \033[1;36mTermux Banner Advanced\033[0m — remover\n\n'

# ---- 1. shell hooks ---------------------------------------------------------
for tb_shell in bash zsh; do
    tb_rc="$(tb_rc_path "$tb_shell")"
    [ -z "$tb_rc" ] && continue
    [ -f "$tb_rc" ] || continue
    if grep -qF "$TB_MARK_BEGIN" "$tb_rc" 2>/dev/null; then
        tb_rc_remove_block "$tb_rc"
        tb_rm_ok "Removed the banner block from $tb_rc"
    else
        tb_rm_print "No banner block in $tb_rc"
    fi
    if [ -f "$tb_rc.tbbak" ]; then
        tb_rm_print "Backup kept at $tb_rc.tbbak"
    fi
done

# ---- 2. boot script + config ------------------------------------------------
if [ -f "$TB_HOME/boot.sh" ]; then
    rm -f "$TB_HOME/boot.sh"
    tb_rm_ok "Removed ~/.termux-banner/boot.sh"
fi

# ---- 3. tb command ----------------------------------------------------------
tb_bin="${PREFIX:-$HOME}/bin/tb"
if [ -f "$tb_bin" ]; then
    rm -f "$tb_bin"
    tb_rm_ok "Removed $tb_bin"
fi

# ---- 4. configuration -------------------------------------------------------
if [ -f "$TB_CONFIG_FILE" ]; then
    if [ "${1:-}" = "--purge" ]; then
        rm -rf "$TB_HOME"
        tb_rm_ok "Purged ~/.termux-banner"
    else
        tb_rm_print "Configuration kept in $TB_CONFIG_FILE (use --purge to delete)"
    fi
fi

printf '\n  \033[1;32mDone.\033[0m Open a new shell to see the original prompt.\n\n'
