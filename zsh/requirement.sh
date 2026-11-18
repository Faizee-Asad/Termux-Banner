#!/usr/bin/env bash
# ---------------------------------------------------------------------------
#  Termux Banner Advanced :: zsh/requirement.sh
#  Backwards compatible entry point - delegates to ../setup.sh
# ---------------------------------------------------------------------------
TB_REQ_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." 2>/dev/null && pwd)"
bash "$TB_REQ_DIR/setup.sh"
