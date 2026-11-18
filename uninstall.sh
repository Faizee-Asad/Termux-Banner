#!/usr/bin/env bash
# ---------------------------------------------------------------------------
#  Termux Banner Advanced :: uninstall.sh
#  Alias of remove.sh
# ---------------------------------------------------------------------------
TB_UN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
bash "$TB_UN_DIR/remove.sh" "$@"
