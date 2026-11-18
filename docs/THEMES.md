# Theme guide

A theme is a single `.conf` file inside `themes/`. The file name (without `.conf`)
is the theme id used by `tb --theme <id>` and `bash t-ban.sh --set theme=<id>`.

---

## Anatomy of a theme file

```ini
name="Neon Cyber"                          # label shown in the menu
desc="Cyan to magenta neon sweep"          # one line description
gradient="#00F5FF #7B2FF7 #FF2E88"         # 1..N colour stops (hex)
accent="#00F5FF"                           # colour of labels and the subtitle
direction="horizontal"                      # horizontal | vertical | diagonal
effect="shadow"                            # plain | shadow | chrome | outline
art="termux-big"                           # logo in assets/ascii/<art>.txt
speed="1"                                  # reserved for the animation speed
```

| Key | Values | Meaning |
|---|---|---|
| `name` | free text | Label displayed in the theme picker |
| `desc` | free text | Short description under the label |
| `gradient` | `#RRGGBB` list | The colours the art is painted with. 1 stop = flat colour, 3 stops = smooth sweep |
| `accent` | `#RRGGBB` | Colour of the dashboard labels, subtitle and clock |
| `direction` | `horizontal` `vertical` `diagonal` | Direction the gradient travels (used when the user keeps `auto`) |
| `effect` | `plain` `shadow` `chrome` `outline` | Rendering style of the ASCII art (used when the user keeps `auto`) |
| `art` | file name | Logo used when the banner content is set to *theme art* |

---

## The four effects

| Effect | Look |
|---|---|
| `plain` | The art is painted with the gradient, nothing else. Cleanest and fastest |
| `shadow` | A dark drop shadow is composited behind the art (offset 2 columns to the right) |
| `chrome` | Same as `shadow`, but the gradient runs vertically so the art looks metallic |
| `outline` | The empty cells next to the art are filled with the neighbouring character, producing a stroked outline |

---

## The three directions

* `horizontal` — the gradient sweeps from the left edge of the art to the right edge
* `vertical` — the gradient sweeps from the first line of the art to the last
* `diagonal` — the gradient sweeps from the top left corner to the bottom right corner

---

## Shipped themes

| Id | Label | Gradient | Direction | Effect | Art |
|---|---|---|---|---|---|
| `neon` | Neon Cyber | `#00F5FF #7B2FF7 #FF2E88` | horizontal | shadow | termux-big |
| `cyberpunk` | Cyberpunk | `#FF2E88 #FFD300 #00E5FF` | diagonal | shadow | cyber-slant |
| `matrix` | Matrix | `#00FF41 #00C853 #0AFF9D` | vertical | shadow | hacker-block |
| `evil-eye` | Evil Eye | `#8E2DE2 #FF2E88 #FFD300` | vertical | shadow | evil-eye |
| `hacker` | Hacker | `#00FF41 #BFFF00 #00FF41` | horizontal | shadow | hacker-big |
| `sunset` | Sunset | `#FF9A3C #FF4E50 #8E2DE2` | horizontal | chrome | termux-big |
| `ocean` | Deep Ocean | `#00E5FF #0077B6 #03045E` | horizontal | shadow | termux-big |
| `aurora` | Aurora | `#00F5A0 #00D9F5 #9D4EDD` | diagonal | shadow | faizee-big |
| `crimson` | Crimson | `#FF0000 #8B0000 #FF6B6B` | vertical | shadow | skull |
| `gold` | Royal Gold | `#FFD700 #FFA500 #C9A227` | horizontal | chrome | banner-big |
| `mono` | Monochrome | `#FFFFFF #C8C8C8 #6E6E6E` | horizontal | plain | termux-block |
| `terminal` | Amber CRT | `#FFB000 #FF7A00 #FFD700` | horizontal | plain | termux-digital |
| `security` | Security Ops | `#00B3FF #0055FF #00FFD5` | horizontal | outline | security-slant |
| `pride` | Pride | `#FF0000 … #FF0000` | horizontal | shadow | faizee-big |

---

## Creating your own theme

```bash
cp themes/neon.conf themes/my-theme.conf
nano themes/my-theme.conf
bash t-ban.sh          # pick "Change theme" -> "my-theme"
```

A theme is picked up automatically — no registration step is needed.

### Tips

* Three colour stops usually look the best; more than five starts to look noisy.
* Keep `accent` close to the first stop of the gradient so the dashboard matches the art.
* Use `vertical` for tall logos (skull, evil eye) and `horizontal` for wide ones (wordmarks).
* `plain` is the safest effect if your logo is very dense.
* The theme only provides the *default* effect and direction. As soon as you pick
  one yourself in `t-ban.sh` (or with `tb --effect`), your choice wins.

---

## Previewing themes

```bash
tb --list-themes      # table of all themes with their gradients
tb --theme matrix     # render one theme
```

To regenerate the screenshots in `assets/previews/`:

```bash
python3 tools/gen-previews.py
```

The script runs the real renderer, converts the ANSI output to HTML and takes a
screenshot with a headless Chromium — the previews are never hand drawn.
