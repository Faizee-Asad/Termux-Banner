#!/usr/bin/env bash
# shellcheck shell=bash
# ---------------------------------------------------------------------------
#  Termux Banner Advanced :: banner.sh
#
#  Renders the configured banner.  Safe to source from .bashrc / .zshrc.
#
#      bash banner.sh              render once
#      . banner.sh                 source it (no exit)
# ---------------------------------------------------------------------------

TB_BANNER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
export TB_PROJECT_DIR="${TB_PROJECT_DIR:-$TB_BANNER_DIR}"

# shellcheck source=lib/core.sh
[ -r "$TB_PROJECT_DIR/lib/core.sh" ]     && . "$TB_PROJECT_DIR/lib/core.sh"
# shellcheck source=lib/render.sh
[ -r "$TB_PROJECT_DIR/lib/render.sh" ]    && . "$TB_PROJECT_DIR/lib/render.sh"
# shellcheck source=lib/fonts.sh
[ -r "$TB_PROJECT_DIR/lib/fonts.sh" ]     && . "$TB_PROJECT_DIR/lib/fonts.sh"
# shellcheck source=lib/fonts-data.sh
[ -r "$TB_PROJECT_DIR/lib/fonts-data.sh" ] && . "$TB_PROJECT_DIR/lib/fonts-data.sh"
# shellcheck source=lib/sysinfo.sh
[ -r "$TB_PROJECT_DIR/lib/sysinfo.sh" ]   && . "$TB_PROJECT_DIR/lib/sysinfo.sh"
# shellcheck source=lib/config.sh
[ -r "$TB_PROJECT_DIR/lib/config.sh" ]    && . "$TB_PROJECT_DIR/lib/config.sh"
# shellcheck source=lib/loader.sh
[ -r "$TB_PROJECT_DIR/lib/loader.sh" ]    && . "$TB_PROJECT_DIR/lib/loader.sh"

tb_render_banner
