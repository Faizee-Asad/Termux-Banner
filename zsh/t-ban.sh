#!/usr/bin/env bash
# ---------------------------------------------------------------------------
#  Termux Banner Advanced :: zsh/t-ban.sh
#
#  Backwards compatible zsh entry point.  The new version installs the same
#  banner for bash and zsh, so this simply calls the main configurator with
#  the zsh shell pre-selected.
#
#      bash zsh/t-ban.sh
# ---------------------------------------------------------------------------
TB_Z_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
TB_PROJECT_DIR="$(cd "$TB_Z_DIR/.." 2>/dev/null && pwd)"
export TB_PROJECT_DIR

[ -r "$TB_PROJECT_DIR/lib/config.sh" ] && . "$TB_PROJECT_DIR/lib/config.sh"
tb_config_load 2>/dev/null
case " $TB_SHELLS " in
    *zsh*) ;;
    *) TB_SHELLS="$TB_SHELLS zsh"; tb_config_save 2>/dev/null ;;
esac

exec bash "$TB_PROJECT_DIR/t-ban.sh" "$@"
