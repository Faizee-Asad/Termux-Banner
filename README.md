<div align="center">

# Termux Banner Advanced

<img src="assets/previews/neon.png" alt="Termux Banner Advanced" width="820">

**A next generation Termux banner engine — 14 themes, 24-bit gradients, live system dashboard and a full interactive configurator.**

by **Faizee Asad** · [github.com/Faizee-Asad/Termux-Banner](https://github.com/Faizee-Asad/Termux-Banner)

</div>

---

## 🙏 Credits & Acknowledgements

This project is a **derivative work** and the original author deserves full credit.

| | |
|---|---|
| **Original project** | **Termux Banner** (Evil Eye) |
| **Original author** | **Sutariya Parixit (8h4i)** — aka *BullAnonymous* |
| **Original repository** | [Bhai4You/Termux-Banner](https://github.com/Bhai4You/Termux-Banner) |
| **Original concept** | The "Evil Eye" Termux banner · *Security help for ethical hackers* |
| **Original support** | Telegram [@realbhai4you](https://t.me/realbhai4you) · [blogspot tutorial](https://bhai4you.blogspot.com/2021/12/evileye2.html) |

> The v1 "Evil Eye" script by **Sutariya Parixit (8h4i)** is the base of this
> project — the Evil Eye artwork and the banner concept belong to him and are
> reused here with credit. Everything marked **v2** below (the banner engine,
> theme system, dashboard, CLI, installer and documentation) was written by
> **Faizee Asad** and is released under the same MIT licence.
>
> If you like this project, please **star the original repository** — it is
> where the Evil Eye banner started.

---

## ✨ What is new in v2

The original script simply piped `toilet` + `lolcat` into `.bashrc`. This release replaces that with a real **banner engine**:

| | v1 (classic) | v2 (advanced) |
|---|---|---|
| Styles | 1 | **14 built-in themes** |
| Colours | flat 16 colour | **24-bit truecolor gradients** with 256/16 colour fallback |
| Effects | none | **drop shadow · chrome · outline · plain** |
| Gradient direction | – | **horizontal · vertical · diagonal** |
| System info | – | **live dashboard** (device, Android, kernel, battery, storage, RAM, IP, uptime …) |
| Mascot | one `cowsay` | **built-in ASCII mascots** + every `cowsay` character |
| Configuration | hard coded | **interactive menu** + config file + CLI |
| ASCII art | – | **13 bundled logos**, custom text in **any figlet/toilet font**, or your own `.txt` |
| Animation | – | **live animated mode** (`tb --loop`) |
| Uninstall | overwrote your `.bashrc` | **removes only its own marked block** — nothing else is touched |
| Dependencies | toilet, figlet, cowsay, lolcat | **none required** — three fonts are bundled |

---

## 📸 Theme gallery

<div align="center">

| | | |
|---|---|---|
| ![neon](assets/previews/neon.png) | ![cyberpunk](assets/previews/cyberpunk.png) | ![matrix](assets/previews/matrix.png) |
| **Neon Cyber** | **Cyberpunk** | **Matrix** |
| ![evil-eye](assets/previews/evil-eye.png) | ![sunset](assets/previews/sunset.png) | ![ocean](assets/previews/ocean.png) |
| **Evil Eye** | **Sunset** | **Deep Ocean** |
| ![hacker](assets/previews/hacker.png) | ![gold](assets/previews/gold.png) | ![pride](assets/previews/pride.png) |
| **Hacker** | **Royal Gold** | **Pride** |
| ![crimson](assets/previews/crimson.png) | ![aurora](assets/previews/aurora.png) | ![security](assets/previews/security.png) |
| **Crimson** | **Aurora** | **Security Ops** |
| ![mono](assets/previews/mono.png) | ![terminal](assets/previews/terminal.png) | |
| **Monochrome** | **Amber CRT** | |

</div>

> Every preview above is generated from the real renderer — `python3 tools/gen-previews.py`.

---

## 🚀 Install

### One command (Termux)

```bash
pkg install git -y && git clone https://github.com/Faizee-Asad/Termux-Banner.git && cd Termux-Banner && bash install.sh
```

### Manual

```bash
git clone https://github.com/Faizee-Asad/Termux-Banner.git
cd Termux-Banner
bash install.sh
```

`install.sh`

1. installs the optional extras (`toilet`, `figlet`, `cowsay`, `lolcat`),
2. writes `~/.termux-banner/boot.sh` (the startup hook),
3. adds a **marked block** to `.bashrc` / `.zshrc` — your file is never overwritten,
4. installs the `tb` command into `$PREFIX/bin`.

Start a new shell (or `source ~/.bashrc`) and the banner is live.

> **Nothing to install?** Skip straight to the configurator — the banner works on a bare Termux because three ASCII fonts are bundled with the project.

---

## 🎛️ Configure

```bash
bash t-ban.sh
```

The interactive menu lets you change everything with a live preview:

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ Termux Banner Advanced  v2.0.0                                              │
└──────────────────────────────────────────────────────────────────────────────┘

   Theme                  Neon Cyber
   Content                custom
   Text                   TERMUX
   Font                   big
   Effect                 shadow / horizontal
   Info panel             on  (device,android,uptime,battery,disk,ip)
   Mascot                 builtin
   Shell                  bash

── Main menu
    1) Change theme
    2) Change banner content
    3) Change ASCII font
    4) Change effect / direction
    5) System info panel
    6) Mascot
    7) Title / subtitle / clock
    8) Shell integration
    9) Preview banner
   10) Save and apply to shell
   11) Reset to defaults
   12) Uninstall banner
   13) Exit
```

Quick setup (two questions, like the classic script):

```bash
bash t-ban.sh --quick
```

Non interactive (for scripts):

```bash
bash t-ban.sh --set theme=matrix
bash t-ban.sh --set text="FAIZEE" --set font=block
```

---

## ⌨️ The `tb` command

```bash
tb                       # show the configured banner
tb --theme matrix        # preview another theme
tb --text "FAIZEE" --font block
tb --random              # random theme
tb --loop                # animated mode (Ctrl+C to stop)
tb --list-themes         # all themes
tb --list-fonts          # all ASCII fonts
tb --list-art            # all bundled logos
tb --config              # current configuration
tb --doctor              # diagnose the installation
tb --set theme=neon      # change and persist a setting
```

Full option list: `tb --help`.

---

## 🎨 Themes

Each theme is a small `.conf` file in `themes/` — copy one and edit it to make your own:

```ini
name="Neon Cyber"
desc="Cyan to magenta neon sweep"
gradient="#00F5FF #7B2FF7 #FF2E88"   # any number of colour stops
accent="#00F5FF"                     # colour of the labels
direction="horizontal"               # horizontal | vertical | diagonal
effect="shadow"                      # plain | shadow | chrome | outline
art="termux-big"                     # bundled logo (assets/ascii/)
speed="1"
```

| Theme | Gradient | Direction | Effect |
|---|---|---|---|
| `neon` | cyan → violet → pink | horizontal | shadow |
| `cyberpunk` | magenta → yellow → cyan | diagonal | shadow |
| `matrix` | phosphor green | vertical | shadow |
| `evil-eye` | violet → pink → gold | vertical | shadow |
| `hacker` | neon green | horizontal | shadow |
| `sunset` | orange → red → violet | horizontal | chrome |
| `ocean` | cyan → deep blue | horizontal | shadow |
| `aurora` | green → cyan → violet | diagonal | shadow |
| `crimson` | blood red | vertical | shadow |
| `gold` | champagne gold | horizontal | chrome |
| `mono` | white → grey | horizontal | plain |
| `terminal` | amber phosphor | horizontal | plain |
| `security` | operator blue | horizontal | outline |
| `pride` | full spectrum | horizontal | shadow |

See [`docs/THEMES.md`](docs/THEMES.md) for the full theme guide and
[`docs/CUSTOMIZATION.md`](docs/CUSTOMIZATION.md) for creating your own theme, logo, font and mascot.

---

## 🖼️ Bundled ASCII art

```
termux-big      termux-block     termux-digital
faizee-big      faizee-asad-big  faizee-block
banner-big      hacker-big       hacker-block
cyber-slant     security-slant   evil-eye        skull
```

Use your own logo — any plain text file works:

```bash
bash t-ban.sh   #  -> "Change banner content" -> "Load a custom .txt ASCII art file"
```

---

## 🧩 Dashboard widgets

The info panel is built from individual widgets — switch them on and off freely.

`user` · `host` · `device` · `android` · `kernel` · `termux` · `uptime` · `battery` · `disk` · `ram` · `ip` · `cpu` · `shell` · `date` · `time` · `packages`

Battery info needs the optional API addon:

```bash
pkg install termux-api -y && termux-battery-percentage
```

---

## 📁 Project structure

```
Termux-Banner/
├── install.sh              one command installer
├── remove.sh               clean uninstall (removes only its own block)
├── uninstall.sh            alias of remove.sh
├── setup.sh                optional dependency installer
├── requirement.sh          legacy entry point -> setup.sh
├── banner.sh               renders the configured banner
├── t-ban.sh                interactive configurator
├── bin/tb                  command line front end
├── lib/
│   ├── core.sh             colour depth, gradient engine, helpers
│   ├── render.sh           ASCII art renderer, boxes, mascots
│   ├── fonts.sh            font discovery + text -> ASCII
│   ├── fonts-data.sh       bundled fonts (big, block, standard)
│   ├── sysinfo.sh          dashboard widgets
│   ├── config.sh           settings + safe rc management
│   ├── loader.sh           render orchestration
│   └── ui.sh               menus and prompts
├── themes/                 14 theme definitions
├── assets/
│   ├── ascii/              13 bundled logos
│   └── previews/           theme screenshots
├── docs/                   THEMES · CUSTOMIZATION · FAQ · CHANGELOG
├── tools/                  preview + font generators
└── zsh/                    legacy zsh entry points
```

---

## ❓ FAQ

**The banner does not show up.**
Run `tb --doctor`. It prints whether the shell hook is installed and where the project lives.

**How do I remove it?**
`bash remove.sh` — it removes the marked block from your rc files and restores your prompt. Add `--purge` to also delete the configuration.

**Does it overwrite my `.bashrc`?**
No. The installer only adds a block between these markers:

```
# >>> termux-banner >>>
...
# <<< termux-banner <<<
```

Everything else in the file is left untouched, and a `.tbbak` backup is kept.

**Can I use it on zsh?**
Yes — pick *Shell integration → zsh* in `t-ban.sh`, or `bash t-ban.sh --set shells="bash zsh"`.

More answers in [`docs/FAQ.md`](docs/FAQ.md).

---

## 🔄 Upgrading from v1

```bash
cd ~/Termux-Banner && git pull && bash install.sh
```

The old `clear` + `cowsay` lines in your `.bashrc` are removed automatically, because the v1 script wrote them without markers. If a leftover remains, delete the three lines `clear`, the `cowsay ...` line and the `toilet ...` line from your `.bashrc`.

---

## 🤝 Contribution

> 🎨 Calling all creative minds! Contribute to the Termux-Banner project.
>
> Are you a design enthusiast with an eye for creativity? Join us and give it a fresh new look.
> We are on a mission to elevate the visual experience of Termux users, and we need your expertise.

A new theme is only a few lines — drop a `.conf` into `themes/` and a logo into `assets/ascii/`, then open a pull request.

---

## 💬 Support

* Issues & ideas: [GitHub Issues](https://github.com/Faizee-Asad/Termux-Banner/issues)
* Twitter: [@faizee_asad](https://twitter.com/faizee_asad)
* LinkedIn: [faizee-asad](https://linkedin.com/in/faizee-asad-566341200)
* Original project (v1 / Evil Eye): Telegram [@realbhai4you](https://t.me/realbhai4you)

---

## 📄 License

[MIT](LICENSE) — dual copyright, see [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md) and [`SECURITY.md`](SECURITY.md).

*Original concept and Evil Eye artwork by **Sutariya Parixit (8h4i)** — [Bhai4You/Termux-Banner](https://github.com/Bhai4You/Termux-Banner).*
*v2 advanced engine by **Faizee Asad** — [Faizee-Asad/Termux-Banner](https://github.com/Faizee-Asad/Termux-Banner).*
