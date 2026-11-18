#!/usr/bin/env bash
# ---------------------------------------------------------------------------
#  Termux Banner Advanced :: requirement.sh
#
#  Kept for backwards compatibility with v1 of this project.
#  It simply delegates to the new setup.sh.
# ---------------------------------------------------------------------------
TB_REQ_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
bash "$TB_REQ_DIR/setup.sh"
