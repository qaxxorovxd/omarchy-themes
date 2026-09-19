# omarchy-themes — Kagerou

Ten Omarchy themes. Nine are built one per colour, each carrying its own set of
18 anime wallpapers: the wallpapers are not decoration bolted on afterwards —
every theme's palette and its backgrounds were chosen against the same hue, so
the desktop, the terminal and the picture behind them read as one piece.

The tenth, **影 Nanairo**, inverts that. Its palette is deliberately
colourless so the wallpaper supplies the colour instead, and its 63
backgrounds are 63 different moods rather than one.

225 wallpapers in total. All dark. All landscape, 1920px wide at the least,
many of them 4K.

## The themes

| slug | menu name | accent | hue | backgrounds | |
| --- | --- | --- | --- | --- | --- |
| `影-sakura-drift` | **影 Sakura Drift** | `#ed92b5` | 337° | 18 | Petal-soft rose over deep plum night |
| `影-yugure-ember` | **影 Yugure Ember** | `#ee8a83` | 4° | 18 | Dusk crimson, warm ash and ember glow |
| `影-kitsune-amber` | **影 Kitsune Amber** | `#eea265` | 27° | 18 | Fox-fire amber on scorched charcoal |
| `影-komorebi-gold` | **影 Komorebi Gold** | `#ebcc5e` | 47° | 18 | Sunlight leaking through summer leaves |
| `影-matcha-yuki` | **影 Matcha Yuki** | `#86d469` | 104° | 18 | Matcha green resting under quiet snow |
| `影-mizu-lagoon` | **影 Mizu Lagoon** | `#6cdad3` | 176° | 18 | Shallow lagoon teal, glass and salt air |
| `影-yozora-indigo` | **影 Yozora Indigo** | `#76a3ea` | 217° | 18 | Night-sky indigo with starlight blue |
| `影-fuji-lavender` | **影 Fuji Lavender** | `#ba9bed` | 263° | 18 | Wisteria lavender drifting over dusk |
| `影-akihabara-neon` | **影 Akihabara Neon** | `#ef89ea` | 303° | 18 | Arcade magenta burning through the rain |
| `影-nanairo` | **影 Nanairo** | `#c9ced6` | — | 63 | Neutral ink · the wallpaper picks the colour |

### 影 Nanairo — the one that works backwards

Every other theme in the pack decides a hue and then goes looking for wallpapers
that already live near it. Nanairo does the opposite: the accent is a silver, the
greys carry almost no hue, the ANSI colours are left untinted, and the
wallpapers are **not** colour-graded at all. Each keeps the palette it was drawn
with, so cycling backgrounds recolours the desk and leaves the UI alone.

Its 63 wallpapers were picked for a clean, focused composition — one
subject, little clutter, a calm background, measured as low edge density plus
high background uniformity — and no two share a colour vibe, where a vibe is a
hue sector crossed with a lightness band. Subjects: 20 anime, 12 nature, 9 minimal, 8 tech, 7 place, 5 arch, 2 other.

### Why the 影 mark

Every theme is installed as `影-<slug>`, so all ten sort together at the end
of the theme list instead of scattering among the built-ins. A plain symbol will
not do this: under `en_US.UTF-8` collation `sort` ignores leading punctuation, so
`_sakura-drift` and `★-sakura-drift` both collate as `sakuradrift` and land under
S, between the stock themes. A CJK character sorts after all Latin text, which
puts the pack in one block at the bottom — and Omarchy's own name handling passes
it through untouched, so `omarchy-theme-set "影 Sakura Drift"` still resolves
to `影-sakura-drift`.

## Install

```bash
git clone https://github.com/<you>/omarchy-themes.git
cd omarchy-themes
./install.sh                       # all nine
```

```bash
./install.sh --list                # see what is in the pack
./install.sh sakura-drift nanairo  # just these (the mark is optional)
./install.sh --set mizu-lagoon     # install everything, then switch to this one
./install.sh --dry-run             # show what would happen, change nothing
./uninstall.sh                     # take them back out
./uninstall.sh --list              # what of this pack is installed right now
```

Themes land in `~/.config/omarchy/themes/`. Switch between them with
`omarchy-theme-set 影-<slug>` or the theme menu
(`Super + Ctrl + Shift + Space`); cycle the backgrounds inside a theme with the
background switcher.

`uninstall.sh` only deletes directories carrying the marker file the installer
wrote, so a theme of your own that shares a name is left alone. If the theme you
are currently using is one of the removed ones, it switches you to a stock theme
rather than leaving Omarchy pointing at a directory that no longer exists.

This is a pack of nine themes, not a single theme, so `omarchy theme install
<git-url>` is not the entry point — that command clones one repo as one theme.
Clone it and run `./install.sh`.

## Omarchy versions

The installer checks which Omarchy it is talking to. On 4.x a theme only needs
`colors.toml` — Omarchy renders Alacritty, Ghostty, kitty, foot, btop, Waybar,
Neovim, VS Code, Helix and the shell from it, so the palette stays the single
source of truth. On 2.x and 3.x there is no template engine, so the installer
also copies the ready-made per-app configs each theme keeps in `compat/`.

## How the nine colour themes were matched

1. ~30,000 `rating:safe` posts were pulled from Konachan's API and filtered down
   to landscape art at 1920px or wider, dropping anything suggestive, any
   watermark or logo tag, and anything with a low community score.
2. Each surviving candidate was reduced to a weighted hue histogram — colour
   energy per 5° bucket, weighted by saturation and brightness so a large flat
   grey sky cannot outvote a small vivid subject.
3. Every image was scored against all nine theme hues, then assigned to the one
   it matched best, with near-duplicate palettes and repeat characters rejected.
4. The shortlist was reviewed by eye, and the survivors were graded: a duotone
   pass anchors each wallpaper's black point to the theme's `darker_background`
   and its highlights to `light_foreground`. Images that already sat on the theme
   hue are barely touched; the further one drifts, the harder it is pulled back.

Measured on the finished files — the share of each theme's colour energy landing
within ±30° of its hue: yozora 98%, kitsune 97%, komorebi 96%, yugure 93%,
sakura 90%, mizu 87%, fuji 80%, akihabara 66%, matcha 64%. Mean hue lands within
1–9° of target for every theme.

That last step is why the set hangs together — switch wallpapers inside a theme
and the window borders, the bar and the terminal never stop matching.

## Per-theme layout

```
影-<slug>/
├── colors.toml        palette (Omarchy 4.x reads this and generates the rest)
├── icons.theme        matching Yaru icon set
├── preview.png        card shown in the theme switcher
├── README.md          palette table and background list
├── backgrounds/       18 graded wallpapers (63 ungraded for 影-nanairo)
└── compat/            per-app configs for Omarchy 2.x / 3.x
```

## Credits

Wallpaper art is by its original artists, collected via
[Konachan](https://konachan.net) under `rating:safe`. Nothing here is redrawn —
only resized and colour-graded. If you are an artist and want a piece pulled,
open an issue, or delete the file from `影-<slug>/backgrounds/` and reinstall.

The theme configuration and the selection/grading pipeline are MIT licensed; the
artwork is not covered by that licence and remains its authors'.
