#!/usr/bin/env bash
#
# Kagerou — nine colour-matched anime themes for Omarchy.
#
# Every theme is installed as 影-<slug>. The 影 mark keeps the pack together at
# the end of the theme list instead of scattering it among the built-in themes:
# en_US collation ignores leading punctuation, so a symbol like "_" or "★" would
# sort as though it were not there, while a CJK character sorts after all Latin.
#
#   ./install.sh                 install every theme
#   ./install.sh --list          show what is in this pack
#   ./install.sh sakura-drift    install just those named
#   ./install.sh --set mizu-lagoon
#
set -euo pipefail

PACK_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DEST="${OMARCHY_THEMES_DEST:-$HOME/.config/omarchy/themes}"
MARK="影"
MARKER_FILE=".kagerou"

SLUGS=(
  sakura-drift yugure-ember kitsune-amber komorebi-gold matcha-yuki
  mizu-lagoon yozora-indigo fuji-lavender akihabara-neon nanairo
)

bold=$'\e[1m'; dim=$'\e[2m'; red=$'\e[31m'; grn=$'\e[32m'; ylw=$'\e[33m'; off=$'\e[0m'
[[ -t 1 ]] || { bold=""; dim=""; red=""; grn=""; ylw=""; off=""; }

say()  { printf '%s\n' "$*"; }
info() { printf '%s==>%s %s\n' "$grn" "$off" "$*"; }
warn() { printf '%s==>%s %s\n' "$ylw" "$off" "$*" >&2; }
die()  { printf '%serror:%s %s\n' "$red" "$off" "$*" >&2; exit 1; }

usage() {
  cat <<'USAGE'
Kagerou theme pack for Omarchy

Usage:
  ./install.sh [options] [theme ...]

Themes may be named bare (sakura-drift) or with the mark (影-sakura-drift).

Options:
  -l, --list           list the themes in this pack and exit
  -s, --set NAME       apply NAME once the install finishes
  -n, --dry-run        print what would happen, change nothing
  -d, --dest DIR       install into DIR instead of ~/.config/omarchy/themes
  -f, --force          overwrite a directory this pack did not create
  -h, --help           this text

With no theme names, every theme in the pack is installed.
To remove them again, use ./uninstall.sh.
USAGE
}

# ── Strip the mark off whatever spelling the user typed ───────────────────
to_slug() {
  local raw="$1"
  raw="${raw#"$MARK"-}"
  raw="${raw#"$MARK" }"
  # accept the display form too: "Sakura Drift" -> "sakura-drift"
  printf '%s' "${raw,,}" | tr ' ' '-'
}

known_slug() {
  local want="$1" slug
  for slug in "${SLUGS[@]}"; do
    [[ $slug == "$want" ]] && return 0
  done
  return 1
}

theme_src()  { printf '%s/%s-%s' "$PACK_DIR" "$MARK" "$1"; }
theme_name() { printf '%s-%s' "$MARK" "$1"; }

# ── Which Omarchy is this? ────────────────────────────────────────────────
# 4.x generates each app's config from colors.toml, so a theme only ships the
# palette. Older releases have no template engine and need the configs
# themselves, which live in each theme's compat/ directory.
omarchy_root() {
  local candidate
  for candidate in "${OMARCHY_PATH:-}" "$HOME/.local/share/omarchy" /usr/share/omarchy; do
    [[ -n $candidate && -d $candidate ]] && { printf '%s' "$candidate"; return 0; }
  done
  return 1
}

omarchy_major() {
  local root version
  root=$(omarchy_root) || { printf '0'; return; }
  version=$(cat "$root/version" 2>/dev/null || true)
  [[ $version =~ ^([0-9]+) ]] && printf '%s' "${BASH_REMATCH[1]}" || printf '0'
}

count_backgrounds() {
  find "$(theme_src "$1")/backgrounds" -maxdepth 1 -type f -iname '*.jpg' 2>/dev/null | wc -l
}

accent_of() {
  sed -n 's/^accent = "\(#[0-9a-fA-F]\{6\}\)"/\1/p' "$(theme_src "$1")/colors.toml" | head -1
}

swatch() {
  local hex="${1#\#}"
  [[ -t 1 ]] || { printf '   '; return; }
  printf '\e[48;2;%d;%d;%dm   \e[0m' "0x${hex:0:2}" "0x${hex:2:2}" "0x${hex:4:2}"
}

list_themes() {
  local slug accent total=0
  for slug in "${SLUGS[@]}"; do
    total=$((total + $(count_backgrounds "$slug")))
  done
  printf '%s%s%s\n\n' "$bold" "Kagerou — ${#SLUGS[@]} themes, $total wallpapers" "$off"
  for slug in "${SLUGS[@]}"; do
    accent=$(accent_of "$slug")
    printf '  %s  %-20s %s%-9s%s %s%s backgrounds%s\n' \
      "$(swatch "$accent")" "$(theme_name "$slug")" "$dim" "$accent" "$off" \
      "$dim" "$(count_backgrounds "$slug")" "$off"
  done
  printf '\n'
}

# ── Argument parsing ──────────────────────────────────────────────────────
selected=(); do_list=0; dry=0; force=0; set_theme=""

while (( $# )); do
  case "$1" in
    -l|--list)    do_list=1 ;;
    -n|--dry-run) dry=1 ;;
    -f|--force)   force=1 ;;
    -h|--help)    usage; exit 0 ;;
    -s|--set)     [[ $# -ge 2 ]] || die "--set needs a theme name"; set_theme="$2"; shift ;;
    -d|--dest)    [[ $# -ge 2 ]] || die "--dest needs a directory"; DEST="$2"; shift ;;
    -*)           die "unknown option: $1 (try --help)" ;;
    *)            slug=$(to_slug "$1")
                  known_slug "$slug" || die "no theme named '$1' in this pack (try --list)"
                  selected+=("$slug") ;;
  esac
  shift
done

(( do_list )) && { list_themes; exit 0; }
(( ${#selected[@]} )) || selected=("${SLUGS[@]}")

if [[ -n $set_theme ]]; then
  set_theme=$(to_slug "$set_theme")
  known_slug "$set_theme" || die "cannot apply '$set_theme': not in this pack"
fi

run() { (( dry )) && { printf '%s  would run:%s %s\n' "$dim" "$off" "$*"; return 0; }; "$@"; }

# ── Install ───────────────────────────────────────────────────────────────
major=$(omarchy_major)
if (( major == 0 )); then
  warn "Omarchy not detected — installing anyway into $DEST"
  legacy=1
elif (( major >= 4 )); then
  legacy=0
else
  legacy=1
fi

info "Omarchy $( (( major == 0 )) && echo "not found" || echo "v$major" ) · destination $DEST"
(( legacy )) && info "using the pre-4.0 layout (shipping per-app configs)" \
             || info "using the 4.x layout (colors.toml drives every app)"

run mkdir -p -- "$DEST"
installed=0

for slug in "${selected[@]}"; do
  src=$(theme_src "$slug")
  name=$(theme_name "$slug")
  target="$DEST/$name"

  [[ -f $src/colors.toml ]] || die "pack is incomplete: $src/colors.toml is missing"

  if [[ -e $target && ! -f $target/$MARKER_FILE ]] && (( ! force )); then
    warn "skipping $name: $target already exists and is not ours (use --force)"
    continue
  fi

  printf '  %s  %-20s %s%s backgrounds%s\n' \
    "$(swatch "$(accent_of "$slug")")" "$name" "$dim" "$(count_backgrounds "$slug")" "$off"

  run rm -rf -- "$target"
  run mkdir -p -- "$target"
  run cp -r -- "$src/backgrounds" "$target/backgrounds"
  run cp -- "$src/colors.toml" "$src/icons.theme" "$src/preview.png" "$src/README.md" "$target/"

  if (( legacy )); then
    # Flatten compat/ into the theme root; that is where old Omarchy looks.
    for file in "$src/compat/"*; do
      [[ -f $file ]] && run cp -- "$file" "$target/$(basename -- "$file")"
    done
  fi

  run touch -- "$target/$MARKER_FILE"
  installed=$((installed + 1))
done

printf '\n'
info "installed $installed theme(s) into $DEST"
(( dry )) && exit 0

if [[ -n $set_theme ]]; then
  if command -v omarchy-theme-set >/dev/null 2>&1; then
    info "applying $(theme_name "$set_theme")"
    omarchy-theme-set "$(theme_name "$set_theme")"
  else
    warn "omarchy-theme-set not on PATH; apply it from the theme menu instead"
  fi
else
  say ""
  say "  Apply one with:   ${bold}omarchy-theme-set $(theme_name "${selected[0]}")${off}"
  say "  Or open the menu: ${bold}Super + Ctrl + Shift + Space${off}"
  say "  ${dim}All ten sit together at the end of the list, under 影.${off}"
  say ""
fi
