# Frequently asked questions

---

### The banner does not show up when I open a new shell

Run the doctor:

```bash
tb --doctor
```

It prints the project location, the colour depth, and whether the hook is
installed in `.bashrc` / `.zshrc`.

If the hook is missing:

```bash
bash install.sh
```

If it is installed but nothing shows, your shell might not read the file the
installer wrote. Check where your shell reads its configuration from:

```bash
echo $SHELL
ls -la ~/.bashrc ~/.zshrc
```

On Termux the rc files live in `$PREFIX/etc/`, not in `~`:

```bash
echo $PREFIX/etc/bash.bashrc
```

---

### Does the installer overwrite my `.bashrc`?

No. The installer appends a clearly marked block:

```
# >>> termux-banner >>>
# Termux Banner Advanced v2.0.0 — managed block, edit with `t-ban.sh`
[ -r "$HOME/.termux-banner/boot.sh" ] && . "$HOME/.termux-banner/boot.sh"
# <<< termux-banner <<<
```

Everything else stays exactly where it was, and a backup is written to
`<rc file>.tbbak`.

> The **v1** script of this project *did* overwrite your whole `.bashrc` and
> reset your `PS1`. That is fixed in v2.

---

### How do I uninstall?

```bash
bash remove.sh            # remove the hook, the boot script and the tb command
bash remove.sh --purge    # also delete ~/.termux-banner
```

Your `.bashrc` keeps everything except the managed block, so your prompt and
your aliases survive.

---

### The colours look wrong / there are no colours at all

The renderer detects the colour depth of your terminal:

| Depth | Look |
|---|---|
| 24 bit | smooth gradients (recommended) |
| 256 colour | gradients with slightly fewer steps |
| 16 colour | flat, approximate colours |

Terminals that only support 16 colours get a simpler but still coloured
banner. Android's **Termux:API** and most modern terminal apps support true
color.

You can force a depth:

```bash
TB_COLOR_DEPTH=24 tb
TB_COLOR_DEPTH=16 tb
```

---

### The text is shifted / the box is broken

That happens when the terminal is not in a UTF-8 locale — bash then counts the
bytes of a box drawing character instead of one column.

The project automatically switches to `C.UTF-8` when it is available. If your
terminal still misbehaves, use the ASCII box style:

```bash
tb --set box=ascii
```

---

### Can I use it with zsh?

Yes:

```bash
bash t-ban.sh --set shells="bash zsh"
```

or pick *Shell integration → both* in the menu. The `zsh/t-ban.sh` entry point
is kept for backwards compatibility.

---

### Which dependencies do I really need?

**None.** The banner renders with pure bash. The optional extras add more:

| Package | Adds |
|---|---|
| `toilet` | ~40 extra ASCII fonts |
| `figlet` | the classic figlet fonts |
| `cowsay` | the classic mascot characters |
| `lolcat` | rainbow dithering of the final output |
| `termux-api` | battery percentage and charging status |

```bash
bash setup.sh
```

---

### How do I show my own name instead of "TERMUX"?

```bash
tb --text "BHAI4YOU" --font big
```

or permanently:

```bash
tb --set art=custom
tb --set text="BHAI4YOU"
```

---

### The dashboard shows `-` for battery / storage

Those widgets need a little help:

* **Battery** — install the API addon: `pkg install termux-api -y` and grant the
  battery permission once from the Android settings.
* **Storage** — reads `df` of `$PREFIX`; it appears as `-` only when the path
  cannot be read.
* **IP** — shows `offline` when no network interface is up.

---

### How fast is the startup banner?

The banner is rendered by pure bash in a few milliseconds. The dashboard adds
one or two `df` / `free` calls. If you want the fastest possible prompt:

```bash
tb --set info=0
tb --set clock=0
```

---

### Can I use the renderer in my own scripts?

Yes:

```bash
source ~/Termux-Banner/lib/core.sh
source ~/Termux-Banner/lib/render.sh
source ~/Termux-Banner/lib/loader.sh
tb_render_banner
```

Or simply:

```bash
bash ~/Termux-Banner/banner.sh
```

---

### How do I report a bug?

* GitHub: [open an issue](https://github.com/Faizee-Asad/Termux-Banner/issues)
* Twitter: [@faizee_asad](https://twitter.com/faizee_asad)
* The original v1 project (Evil Eye): Telegram [@realbhai4you](https://t.me/realbhai4you)

Please include the output of `tb --doctor`.
