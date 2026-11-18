# Changelog

All notable changes to **Termux Banner Advanced**.

> **Credits** — the v1 "Evil Eye" banner below was written by
> **Sutariya Parixit (8h4i)** ([Bhai4You/Termux-Banner](https://github.com/Bhai4You/Termux-Banner)).
> Everything in v2 was written by **Faizee Asad**.

---

## v2.0.0 — Advanced banner engine  ·  *Faizee Asad*

The complete rewrite of the classic Evil Eye banner script.

### Added

- **Theme engine** with 14 shipped themes (`neon`, `cyberpunk`, `matrix`,
  `evil-eye`, `hacker`, `sunset`, `ocean`, `aurora`, `crimson`, `gold`, `mono`,
  `terminal`, `security`, `pride`).
- **24-bit truecolor gradients** with automatic fallback to 256 and 16 colours.
- **Rendering effects**: `plain`, `shadow` (drop shadow), `chrome`, `outline`.
- **Gradient directions**: horizontal, vertical, diagonal.
- **Live system dashboard** with 16 switchable widgets (device, Android, kernel,
  Termux version, uptime, battery, storage, RAM, IP, CPU, shell, date, time,
  packages, user, host).
- **Interactive configurator** `t-ban.sh` with live preview of every theme.
- **Command line front end** `tb` (`--theme`, `--text`, `--font`, `--mascot`,
  `--effect`, `--direction`, `--random`, `--loop`, `--list-*`, `--config`,
  `--doctor`, `--set`).
- **13 bundled ASCII logos** in `assets/ascii/`.
- **Three bundled ASCII fonts** (`big`, `block`, `standard`) — the banner no
  longer requires `toilet` or `figlet` to render custom text.
- **Built-in ASCII mascots** (robot, eyes, ghost, hacker) for when `cowsay` is
  not installed.
- **Animated mode** (`tb --loop`) with a cycling gradient.
- **Safe shell integration**: the `.bashrc` / `.zshrc` block is delimited by
  markers, is idempotent and never overwrites the rest of the file. A `.tbbak`
  backup is written on every install.
- **UTF-8 awareness**: the renderer switches to a UTF-8 locale when available
  and falls back to ASCII box drawing otherwise.
- **Documentation**: `README.md`, `docs/THEMES.md`, `docs/CUSTOMIZATION.md`,
  `docs/FAQ.md`.
- **Tooling**: `tools/gen-previews.py` (real renderer → HTML → screenshot) and
  `tools/gen-fonts.py` (regenerates the bundled font tables).

### Changed

- `requirement.sh` now delegates to the new `setup.sh`.
- `remove.sh` only removes the managed block instead of overwriting the whole
  `.bashrc` and resetting `PS1`.
- `zsh/t-ban.sh` is kept as a compatibility wrapper around the new
  configurator.

### Fixed

- The classic script left `clear`, `cowsay` and `toilet` commands scattered
  through the rc file. Those are now replaced by a single managed block.

---

## v1.0 — Evil Eye banner  ·  *Sutariya Parixit (8h4i)*

Original release by **Sutariya Parixit (8h4i)** —
[Bhai4You/Termux-Banner](https://github.com/Bhai4You/Termux-Banner).

- `figlet` / `toilet` + `lolcat` banner.
- Interactive banner name and cowsay name.
- Writes `clear`, `cowsay` and `toilet` commands into `.bashrc`.
- `remove.sh` restored the original prompt.
