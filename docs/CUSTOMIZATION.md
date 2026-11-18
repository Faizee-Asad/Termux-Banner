# Customisation

Everything the banner shows can be changed without touching a single line of code.

---

## 1. The configuration file

The whole configuration lives in one plain text file:

```
~/.termux-banner/config
```

```ini
# Termux Banner Advanced v2.0.0 — configuration
# Edit by hand or run: t-ban.sh
TB_THEME="neon"
TB_ART="theme"
TB_TEXT="TERMUX"
TB_FONT="big"
TB_MASCOT="builtin"
TB_MASCOT_MSG="Hacking in progress"
TB_TITLE="Termux Banner Advanced"
TB_SUBTITLE="Security help for ethical hackers"
TB_EFFECT="auto"
TB_DIRECTION="auto"
TB_INFO="1"
TB_WIDGETS="device,android,uptime,battery,disk,ip"
TB_ANIM="0"
TB_SPEED="1"
TB_CLOCK="1"
TB_BOX="unicode"
TB_SHELLS="bash"
TB_ART_FILE=""
TB_PROFILE="default"
```

| Setting | Values | Meaning |
|---|---|---|
| `TB_THEME` | theme id | Theme used for the gradient and the dashboard accent |
| `TB_ART` | `theme` `custom` `file` | Where the banner content comes from |
| `TB_TEXT` | free text | The text rendered when `TB_ART="custom"` |
| `TB_FONT` | font name | ASCII font used for the custom text |
| `TB_MASCOT` | `none` `builtin` `eyes` `tux` … | Mascot character, `cowsay` names work too |
| `TB_MASCOT_MSG` | free text | Text spoken by the mascot |
| `TB_TITLE` | free text | Big line under the art |
| `TB_SUBTITLE` | free text | Small line under the title |
| `TB_EFFECT` | `auto` `plain` `shadow` `chrome` `outline` | Rendering style — `auto` follows the theme |
| `TB_DIRECTION` | `auto` `horizontal` `vertical` `diagonal` | Gradient direction — `auto` follows the theme |
| `TB_INFO` | `0` `1` | Show or hide the dashboard |
| `TB_WIDGETS` | comma list | Which dashboard widgets are shown |
| `TB_CLOCK` | `0` `1` | Show the date/time line |
| `TB_BOX` | `unicode` `ascii` | Box drawing style of the dashboard |
| `TB_SHELLS` | `bash` `zsh` `bash zsh` | Which shells get the banner |
| `TB_ART_FILE` | path | File used when `TB_ART="file"` |

Change a value from the command line:

```bash
tb --set theme=matrix
tb --set widgets=device,uptime,battery
tb --set info=0
```

---

## 2. Your own ASCII logo

Any plain text file works — the renderer paints it with the theme gradient.

```bash
cat > ~/my-logo.txt <<'EOF'
  _______ _______  _______  ______
 /       |       |       | |      \
|   __   |   __  |   __  | |  ___  |
EOF

tb --set art=file
tb --set artfile=$HOME/my-logo.txt
```

Or through the menu: *Change banner content → Load a custom `.txt` ASCII art file*.

> Use ASCII only. Unicode box characters may not line up in every terminal font.

---

## 3. Custom text in any font

The renderer uses `toilet` and `figlet` when they are installed, and falls back to
three bundled fonts (`big`, `block`, `standard`) when they are not.

```bash
tb --list-fonts                       # every font you can use
tb --text "BHAI4YOU" --font block
tb --text "TERMUX" --font slant
```

Set it permanently:

```bash
tb --set art=custom
tb --set text="BHAI4YOU"
tb --set font=block
```

---

## 4. Your own mascot

Without `cowsay` the built-in mascots are used: `builtin` (robot), `eyes`, `ghost`
and `hacker`. With `cowsay` installed every classic character works:

```bash
tb --set mascot=tux
tb --set mascot=eyes
tb --set mascot=none
tb --set message="Hacking in progress"
```

---

## 5. Your own theme

See [`THEMES.md`](THEMES.md). In short: copy a `.conf` file, edit the colours,
drop it into `themes/`.

---

## 6. Hiding the banner temporarily

```bash
# for one session
export TB_SKIP_BANNER=1

# or simply
unalias tb 2>/dev/null
```

To disable it permanently, comment out the managed block in your `.bashrc`:

```
# >>> termux-banner >>>
...
# <<< termux-banner <<<
```

---

## 7. Multiple profiles

A profile is nothing more than a copy of the configuration file.

```bash
cp ~/.termux-banner/config ~/.termux-banner/config.work
cp ~/.termux-banner/config ~/.termux-banner/config.game

# switch
cp ~/.termux-banner/config.work ~/.termux-banner/config
```

---

## 8. Adding a widget

Dashboard widgets live in `lib/sysinfo.sh` inside `tb_sysinfo_widgets()`. Add a
case for your own:

```bash
gpu)
    label="GPU"; value="$(cat /sys/class/kgsl/kgsl-3d0/gpu_busy_percentage 2>/dev/null || echo '-')"
    ;;
```

Then add `gpu` to `TB_WIDGETS`:

```bash
tb --set widgets=device,android,gpu
```
